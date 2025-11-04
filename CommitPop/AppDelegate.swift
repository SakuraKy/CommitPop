//
//  AppDelegate.swift
//  CommitPop
//
//  应用委托，处理通知委托和应用生命周期
//

import Cocoa
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        print("✅ CommitPop 已启动")
        
        // 请求通知权限
        Task {
            await NotificationCenterManager.shared.requestAuthorization()
        }
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        print("👋 CommitPop 即将退出")
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}

