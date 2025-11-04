//
//  Notifier.swift
//  CommitPop
//
//  将业务事件转换为系统通知
//

import Foundation

/// 通知发送器
final class Notifier {
    
    static let shared = Notifier()
    
    private let notificationManager = NotificationCenterManager.shared
    private let settingsStore = SettingsStore.shared
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// 发送 GitHub 通知
    /// - Parameter thread: GitHub 通知线程
    func notifyGitHubThread(_ thread: GitHubNotificationThread) async {
        // 检查是否暂停通知
        guard !settingsStore.notificationsPaused else {
            print("⏸️ 通知已暂停")
            return
        }
        
        let title = formatTitle(for: thread)
        let body = formatBody(for: thread)
        let url = extractURL(from: thread)
        let soundEnabled = settingsStore.notificationSoundEnabled
        
        await notificationManager.sendNotification(
            title: title,
            body: body,
            identifier: thread.id,
            url: url,
            soundEnabled: soundEnabled
        )
    }
    
    /// 批量发送通知
    /// - Parameter threads: GitHub 通知线程数组
    func notifyMultipleThreads(_ threads: [GitHubNotificationThread]) async {
        for thread in threads {
            await notifyGitHubThread(thread)
        }
    }
    
    // MARK: - Private Methods
    
    /// 格式化通知标题
    private func formatTitle(for thread: GitHubNotificationThread) -> String {
        let emoji = emojiForReason(thread.reason)
        let repoName = thread.repository.fullName
        return "\(emoji) \(repoName)"
    }
    
    /// 格式化通知内容
    private func formatBody(for thread: GitHubNotificationThread) -> String {
        let typeDescription = descriptionForType(thread.subject.type)
        return "\(typeDescription): \(thread.subject.title)"
    }
    
    /// 提取可打开的 URL
    private func extractURL(from thread: GitHubNotificationThread) -> String? {
        // 优先使用 latest_comment_url（如果有新评论）
        if let commentUrl = thread.subject.latestCommentUrl {
            // 转换为 HTML URL
            return convertAPIUrlToHtml(commentUrl)
        }
        
        // 其次使用 subject.url
        if let subjectUrl = thread.subject.url {
            return convertAPIUrlToHtml(subjectUrl)
        }
        
        // 最后使用仓库 URL
        return thread.repository.htmlUrl
    }
    
    /// 将 API URL 转换为 HTML URL
    private func convertAPIUrlToHtml(_ apiUrl: String) -> String {
        // GitHub API URL 格式: https://api.github.com/repos/{owner}/{repo}/issues/{number}
        // HTML URL 格式: https://github.com/{owner}/{repo}/issues/{number}
        
        let htmlUrl = apiUrl
            .replacingOccurrences(of: "https://api.github.com/repos/", with: "https://github.com/")
            .replacingOccurrences(of: "/pulls/", with: "/pull/")
        
        return htmlUrl
    }
    
    /// 根据原因返回 emoji
    private func emojiForReason(_ reason: String) -> String {
        switch reason {
        case "mention":
            return "👤"
        case "assign":
            return "📌"
        case "author":
            return "✍️"
        case "comment":
            return "💬"
        case "review_requested":
            return "👀"
        case "state_change":
            return "🔄"
        case "subscribed":
            return "🔔"
        default:
            return "📬"
        }
    }
    
    /// 根据类型返回描述
    private func descriptionForType(_ type: String) -> String {
        switch type {
        case "Issue":
            return "Issue"
        case "PullRequest":
            return "Pull Request"
        case "Commit":
            return "Commit"
        case "Release":
            return "Release"
        case "Discussion":
            return "Discussion"
        default:
            return type
        }
    }
}
