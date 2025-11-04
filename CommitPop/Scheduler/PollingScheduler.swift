//
//  PollingScheduler.swift
//  CommitPop
//
//  定时拉取 GitHub 通知的调度器
//

import Foundation
import Combine

/// 调度器状态
enum SchedulerStatus {
    case idle
    case syncing
    case paused
    case error(Error)
}

/// 轮询调度器
@MainActor
final class PollingScheduler: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var status: SchedulerStatus = .idle
    @Published private(set) var lastSyncDate: Date?
    @Published private(set) var recentThreads: [GitHubNotificationThread] = []
    
    // MARK: - Dependencies
    
    private let notificationsAPI = GitHubNotificationsAPI.shared
    private let cacheStore = CacheStore.shared
    private let settingsStore = SettingsStore.shared
    private let notifier = Notifier.shared
    
    // MARK: - Timer
    
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        // 监听设置变化
        settingsStore.$pollingInterval
            .sink { [weak self] _ in
                self?.restartTimer()
            }
            .store(in: &cancellables)
        
        settingsStore.$notificationsPaused
            .sink { [weak self] paused in
                if paused {
                    self?.status = .paused
                } else {
                    self?.status = .idle
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// 启动调度器
    func start() {
        print("🚀 启动调度器")
        restartTimer()
        
        // 立即执行一次同步
        Task {
            await syncNow()
        }
    }
    
    /// 停止调度器
    func stop() {
        print("⏹️ 停止调度器")
        timer?.invalidate()
        timer = nil
    }
    
    /// 立即同步
    func syncNow() async {
        guard !settingsStore.notificationsPaused else {
            print("⏸️ 通知已暂停，跳过同步")
            return
        }
        
        guard status != .syncing else {
            print("⚠️ 正在同步中，跳过本次请求")
            return
        }
        
        status = .syncing
        
        do {
            // 构建查询参数
            let query = NotificationsQuery(
                participating: settingsStore.participatingOnly,
                all: !settingsStore.participatingOnly
            )
            
            // 获取 Last-Modified
            let lastModified = cacheStore.getLastModified()
            
            // 请求通知
            let response = try await notificationsAPI.getNotifications(
                query: query,
                ifModifiedSince: lastModified
            )
            
            // 保存 Last-Modified
            if let newLastModified = response.lastModified {
                cacheStore.saveLastModified(newLastModified)
            }
            
            // 处理新通知
            await processNewThreads(response.data)
            
            // 更新状态
            lastSyncDate = Date()
            status = .idle
            
            // 发送通知
            NotificationCenter.default.post(name: Constants.NotificationNames.syncDidComplete, object: nil)
            
            print("✅ 同步完成，获取到 \(response.data.count) 条通知")
            
        } catch GitHubAPIError.notModified {
            // 304: 未修改
            lastSyncDate = Date()
            status = .idle
            print("✅ 同步完成，内容未修改")
            
        } catch {
            status = .error(error)
            print("❌ 同步失败: \(error.localizedDescription)")
            
            // 发送错误通知
            NotificationCenter.default.post(
                name: Constants.NotificationNames.syncDidFail,
                object: nil,
                userInfo: ["error": error]
            )
            
            // 如果是速率限制错误，进入指数退避
            if case GitHubAPIError.rateLimitExceeded = error {
                handleRateLimitExceeded()
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// 重启定时器
    private func restartTimer() {
        timer?.invalidate()
        
        let interval = TimeInterval(settingsStore.pollingInterval * 60)
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.syncNow()
            }
        }
        
        print("⏰ 定时器已重启，间隔: \(settingsStore.pollingInterval) 分钟")
    }
    
    /// 处理新通知线程
    private func processNewThreads(_ threads: [GitHubNotificationThread]) async {
        var newThreads: [GitHubNotificationThread] = []
        
        for thread in threads {
            // 只处理未读通知
            guard thread.unread else { continue }
            
            // 检查是否需要通知（去重）
            if cacheStore.shouldNotifyThread(thread) {
                newThreads.append(thread)
            }
        }
        
        // 更新最近通知列表
        recentThreads = Array(threads.prefix(Constants.Defaults.recentEventsCount))
        
        // 发送系统通知
        if !newThreads.isEmpty {
            print("📬 发现 \(newThreads.count) 条新通知")
            await notifier.notifyMultipleThreads(newThreads)
        }
    }
    
    /// 处理速率限制超限
    private func handleRateLimitExceeded() {
        // 暂停调度器，直到速率限制重置
        stop()
        
        // 可以在这里实现指数退避策略
        // 例如：延长轮询间隔
        print("⚠️ 速率限制超限，调度器已暂停")
    }
}
