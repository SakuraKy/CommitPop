//
//  CommitPopApp.swift
//  CommitPop
//
//  应用入口，配置为纯菜单栏应用（LSUIElement = YES）
//

import SwiftUI

@main
struct CommitPopApp: App {
    
    // AppDelegate for notification handling
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // Menu bar controller - 使用静态变量确保在整个应用生命周期内存在
    static let menuBarController = MenuBarController()
    
    init() {
        // 在应用启动时初始化菜单栏控制器
        // 注意:这里不需要赋值,因为是静态变量
        _ = CommitPopApp.menuBarController
    }
    
    var body: some Scene {
        // Settings 场景，用于 Cmd+, 快捷键
        Settings {
            PreferencesTabView()
                .frame(minWidth: 620, minHeight: 480)
        }
    }
}

// MARK: - Preferences UI

/// 首选项主视图
struct PreferencesTabView: View {
    var body: some View {
        TabView {
            GeneralTabView()
                .tabItem {
                    Label("登录", systemImage: "person.crop.circle")
                }
                .tag(0)
            
            NotificationsTabView()
                .tabItem {
                    Label("通知", systemImage: "bell")
                }
                .tag(1)
            
            StartupTabView()
                .tabItem {
                    Label("启动项", systemImage: "power")
                }
                .tag(2)
            
            AdvancedTabView()
                .tabItem {
                    Label("高级", systemImage: "gearshape.2")
                }
                .tag(3)
        }
        .padding(20)
    }
}

