//
//  GitHubNotificationsAPI.swift
//  CommitPop
//
//  GitHub 通知 API 封装，支持 Last-Modified / If-Modified-Since 优化
//

import Foundation

/// 通知查询参数
struct NotificationsQuery {
    var participating: Bool = true
    var all: Bool = false
    var since: String? = nil
    var before: String? = nil
    var perPage: Int = 50
}

/// GitHub 通知 API
final class GitHubNotificationsAPI {
    
    static let shared = GitHubNotificationsAPI()
    private let api = GitHubAPI.shared
    
    private init() {}
    
    /// 获取通知列表
    /// - Parameters:
    ///   - query: 查询参数
    ///   - ifModifiedSince: If-Modified-Since 头（可选）
    /// - Returns: 通知线程列表和响应头信息
    func getNotifications(
        query: NotificationsQuery = NotificationsQuery(),
        ifModifiedSince: String? = nil
    ) async throws -> GitHubAPIResponse<[GitHubNotificationThread]> {
        
        var queryItems: [URLQueryItem] = []
        
        if query.participating {
            queryItems.append(URLQueryItem(name: "participating", value: "true"))
        }
        
        if query.all {
            queryItems.append(URLQueryItem(name: "all", value: "true"))
        }
        
        if let since = query.since {
            queryItems.append(URLQueryItem(name: "since", value: since))
        }
        
        if let before = query.before {
            queryItems.append(URLQueryItem(name: "before", value: before))
        }
        
        queryItems.append(URLQueryItem(name: "per_page", value: "\(query.perPage)"))
        
        do {
            let response: GitHubAPIResponse<[GitHubNotificationThread]> = try await api.get(
                endpoint: "/notifications",
                queryItems: queryItems,
                ifModifiedSince: ifModifiedSince
            )
            return response
            
        } catch GitHubAPIError.notModified {
            // 304: 未修改，返回空数组但保留错误信息传递
            throw GitHubAPIError.notModified
        } catch {
            throw error
        }
    }
    
    /// 标记通知为已读
    /// - Parameter threadId: 线程 ID
    func markThreadAsRead(threadId: String) async throws {
        var urlComponents = URLComponents(string: Constants.GitHub.apiBaseURL + "/notifications/threads/\(threadId)")
        guard let url = urlComponents?.url else {
            throw GitHubAPIError.unknown("无效的 URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        
        // 添加授权头
        if let token = try? KeychainStore.shared.retrieveAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw GitHubAPIError.unknown("标记已读失败")
        }
    }
}
