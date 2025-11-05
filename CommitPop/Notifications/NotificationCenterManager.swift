//
//  NotificationCenterManager.swift
//  CommitPop
//
//  封装 UNUserNotificationCenter，负责授权和发送系统通知
//

import Foundation
import UserNotifications
import AppKit

/// 通知管理器
final class NotificationCenterManager: NSObject {
    
    static let shared = NotificationCenterManager()
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private var isAuthorized = false
    
    private override init() {
        super.init()
        notificationCenter.delegate = self
    }
    
    // MARK: - Authorization
    
    /// 请求通知权限
    /// - Returns: 是否授权成功
    @discardableResult
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            isAuthorized = granted
            
            if granted {
                print("✅ 通知权限已授予")
            } else {
                print("❌ 用户拒绝了通知权限")
            }
            
            return granted
        } catch {
            print("❌ 请求通知权限失败: \(error)")
            return false
        }
    }
    
    /// 检查当前授权状态
    func checkAuthorizationStatus() async -> Bool {
        let settings = await notificationCenter.notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
        return isAuthorized
    }
    
    // MARK: - Send Notification
    
    /// 发送本地通知
    /// - Parameters:
    ///   - title: 标题
    ///   - body: 内容
    ///   - identifier: 唯一标识符（用于去重和更新）
    ///   - url: 点击通知后打开的 URL
    ///   - soundEnabled: 是否播放声音
    func sendNotification(
        title: String,
        body: String,
        identifier: String,
        url: String? = nil,
        soundEnabled: Bool = true
    ) async {
        guard isAuthorized else {
            print("⚠️ 通知未授权，无法发送")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.threadIdentifier = identifier
        
        if soundEnabled {
            content.sound = .default
        }
        
        // 保存 URL 到 userInfo，用于点击后打开
        if let url = url {
            content.userInfo = ["url": url]
        }
        
        // 立即触发
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        do {
            try await notificationCenter.add(request)
            print("📬 已发送通知: \(title)")
        } catch {
            print("❌ 发送通知失败: \(error)")
        }
    }
    
    /// 移除指定通知
    /// - Parameter identifier: 通知标识符
    func removeNotification(identifier: String) {
        notificationCenter.removeDeliveredNotifications(withIdentifiers: [identifier])
    }
    
    /// 移除所有通知
    func removeAllNotifications() {
        notificationCenter.removeAllDeliveredNotifications()
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationCenterManager: UNUserNotificationCenterDelegate {
    
    /// 在前台也显示通知
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
    
    /// 处理通知点击
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        // 如果有 URL，在默认浏览器中打开
        if let urlString = userInfo["url"] as? String,
           let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
            print("🌐 打开 URL: \(urlString)")
        }
        
        completionHandler()
    }
}
