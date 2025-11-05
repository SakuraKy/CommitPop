//
//  MenuBarController.swift
//  CommitPop
//
//  菜单栏控制器，管理 NSStatusItem 和菜单
//

import AppKit
import Combine
import SwiftUI

/// 菜单栏控制器
@MainActor
final class MenuBarController: NSObject, ObservableObject {
    
    // MARK: - Properties
    
    private var statusItem: NSStatusItem?
    private let scheduler = PollingScheduler()
    private let settingsStore = SettingsStore.shared
    private let keychainStore = KeychainStore.shared
    private let cacheStore = CacheStore.shared
    
    private var cancellables = Set<AnyCancellable>()
    
    // 设置窗口 - 使用 weak 引用避免内存泄漏
    private weak var preferencesWindow: NSWindow?
    private var preferencesWindowDelegate: PreferencesWindowDelegate?
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        setupStatusItem()
        setupObservers()
        startScheduler()
    }
    
    // MARK: - Setup
    
    /// 设置状态栏项
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        guard let button = statusItem?.button else {
            print("❌ 无法创建状态栏按钮")
            return
        }
        
        // 设置图标
        button.image = MenuIconProvider.getMenuIcon()
        button.imagePosition = .imageLeft
        
        // 设置菜单
        updateMenu()
        
        print("✅ 菜单栏项已创建")
    }
    
    /// 设置观察者
    private func setupObservers() {
        // 监听登录/登出
        NotificationCenter.default.publisher(for: Constants.NotificationNames.userDidLogin)
            .sink { [weak self] _ in
                self?.updateMenu()
                self?.startScheduler()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: Constants.NotificationNames.userDidLogout)
            .sink { [weak self] _ in
                self?.updateMenu()
                self?.scheduler.stop()
            }
            .store(in: &cancellables)
        
        // 监听同步完成
        NotificationCenter.default.publisher(for: Constants.NotificationNames.syncDidComplete)
            .sink { [weak self] _ in
                self?.updateMenu()
            }
            .store(in: &cancellables)
        
        // 监听通知暂停状态
        settingsStore.$notificationsPaused
            .sink { [weak self] _ in
                self?.updateMenu()
            }
            .store(in: &cancellables)
    }
    
    /// 启动调度器
    private func startScheduler() {
        guard keychainStore.hasAccessToken() else {
            print("⚠️ 未登录，不启动调度器")
            return
        }
        
        scheduler.start()
    }
    
    // MARK: - Menu Construction
    
    /// 更新菜单
    private func updateMenu() {
        let menu = NSMenu()
        
        // 登录状态
        let isLoggedIn = keychainStore.hasAccessToken()
        let loginStatusItem = NSMenuItem(title: isLoggedIn ? "已登录" : "未登录", action: nil, keyEquivalent: "")
        loginStatusItem.isEnabled = false
        menu.addItem(loginStatusItem)
        
        // 上次同步时间
        if let lastSync = cacheStore.getLastSyncDate() {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .abbreviated
            let timeString = formatter.localizedString(for: lastSync, relativeTo: Date())
            let syncItem = NSMenuItem(title: "上次同步: \(timeString)", action: nil, keyEquivalent: "")
            syncItem.isEnabled = false
            menu.addItem(syncItem)
        }
        
        // 速率限制信息
        if let rateLimit = GitHubAPI.shared.currentRateLimit {
            let rateLimitItem = NSMenuItem(
                title: "API 配额: \(rateLimit.remaining)/\(rateLimit.limit)",
                action: nil,
                keyEquivalent: ""
            )
            rateLimitItem.isEnabled = false
            menu.addItem(rateLimitItem)
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // 立即同步
        if isLoggedIn {
            let syncItem = NSMenuItem(
                title: "立即同步",
                action: #selector(syncNow),
                keyEquivalent: "r"
            )
            syncItem.target = self
            menu.addItem(syncItem)
        }
        
        // 暂停/恢复通知
        if isLoggedIn {
            let pauseTitle = settingsStore.notificationsPaused ? "恢复通知" : "暂停通知"
            let pauseItem = NSMenuItem(
                title: pauseTitle,
                action: #selector(togglePause),
                keyEquivalent: "p"
            )
            pauseItem.target = self
            menu.addItem(pauseItem)
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // 最近 5 条事件
        if !scheduler.recentThreads.isEmpty {
            let recentTitle = NSMenuItem(title: "最近事件", action: nil, keyEquivalent: "")
            recentTitle.isEnabled = false
            menu.addItem(recentTitle)
            
            for thread in scheduler.recentThreads {
                let title = "\(thread.repository.name): \(thread.subject.title)"
                let truncatedTitle = String(title.prefix(50)) + (title.count > 50 ? "..." : "")
                let item = NSMenuItem(
                    title: truncatedTitle,
                    action: #selector(openThread(_:)),
                    keyEquivalent: ""
                )
                item.target = self
                item.representedObject = thread
                menu.addItem(item)
            }
            
            menu.addItem(NSMenuItem.separator())
        }
        
        // 打开首选项
        let prefsItem = NSMenuItem(
            title: "打开首选项...",
            action: #selector(openPreferences),
            keyEquivalent: ","
        )
        prefsItem.target = self
        menu.addItem(prefsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 退出
        let quitItem = NSMenuItem(
            title: "退出 CommitPop",
            action: #selector(quit),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
    }
    
    // MARK: - Actions
    
    @objc private func syncNow() {
        Task {
            await scheduler.syncNow()
        }
    }
    
    @objc private func togglePause() {
        settingsStore.notificationsPaused.toggle()
        let status = settingsStore.notificationsPaused ? "已暂停" : "已恢复"
        print("🔔 通知\(status)")
    }
    
    @objc private func openThread(_ sender: NSMenuItem) {
        guard let thread = sender.representedObject as? GitHubNotificationThread else {
            return
        }
        
        // 提取 URL
        var urlString: String?
        if let commentUrl = thread.subject.latestCommentUrl {
            urlString = convertAPIUrlToHtml(commentUrl)
        } else if let subjectUrl = thread.subject.url {
            urlString = convertAPIUrlToHtml(subjectUrl)
        } else {
            urlString = thread.repository.htmlUrl
        }
        
        if let urlString = urlString, let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
    
    @objc private func openPreferences() {
        // 如果窗口已存在且可见,直接显示
        if let window = preferencesWindow, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        // 创建 SwiftUI 视图
        let contentView = PreferencesTabView()
            .frame(minWidth: 620, minHeight: 480)
        
        // 创建窗口
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 620, height: 480),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "CommitPop 首选项"
        window.contentView = NSHostingView(rootView: contentView)
        window.center()
        window.setFrameAutosaveName("PreferencesWindow")
        
        // 关键修复: 不要自动释放窗口,防止应用退出
        window.isReleasedWhenClosed = false
        
        // 创建并设置窗口委托
        let delegate = PreferencesWindowDelegate()
        window.delegate = delegate
        self.preferencesWindowDelegate = delegate
        
        // 保存弱引用
        self.preferencesWindow = window
        
        // 显示窗口并激活应用
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        print("✅ 首选项窗口已打开")
    }
    
    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
    
    // MARK: - Helper Methods
    
    /// 将 API URL 转换为 HTML URL
    private func convertAPIUrlToHtml(_ apiUrl: String) -> String {
        return apiUrl
            .replacingOccurrences(of: "https://api.github.com/repos/", with: "https://github.com/")
            .replacingOccurrences(of: "/pulls/", with: "/pull/")
    }
}

// MARK: - Window Delegate

/// 首选项窗口委托,处理窗口关闭事件
class PreferencesWindowDelegate: NSObject, NSWindowDelegate {
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        // 隐藏窗口而不是关闭,保持窗口对象存在
        sender.orderOut(nil)
        print("✅ 首选项窗口已隐藏")
        return false
    }
}
