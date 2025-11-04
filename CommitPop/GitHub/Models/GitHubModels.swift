//
//  GitHubModels.swift
//  CommitPop
//
//  GitHub API 数据模型
//

import Foundation

// MARK: - Notification Thread

/// GitHub 通知线程
struct GitHubNotificationThread: Codable, Identifiable {
    let id: String
    let repository: Repository
    let subject: Subject
    let reason: String
    let unread: Bool
    let updatedAt: String
    let lastReadAt: String?
    let url: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case repository
        case subject
        case reason
        case unread
        case updatedAt = "updated_at"
        case lastReadAt = "last_read_at"
        case url
    }
    
    struct Repository: Codable {
        let id: Int
        let name: String
        let fullName: String
        let owner: Owner
        let htmlUrl: String
        let description: String?
        let isPrivate: Bool
        
        enum CodingKeys: String, CodingKey {
            case id
            case name
            case fullName = "full_name"
            case owner
            case htmlUrl = "html_url"
            case description
            case isPrivate = "private"
        }
        
        struct Owner: Codable {
            let login: String
            let avatarUrl: String?
            
            enum CodingKeys: String, CodingKey {
                case login
                case avatarUrl = "avatar_url"
            }
        }
    }
    
    struct Subject: Codable {
        let title: String
        let url: String?
        let latestCommentUrl: String?
        let type: String
        
        enum CodingKeys: String, CodingKey {
            case title
            case url
            case latestCommentUrl = "latest_comment_url"
            case type
        }
    }
}

// MARK: - Rate Limit

/// GitHub API 速率限制信息
struct RateLimit: Codable {
    let limit: Int
    let remaining: Int
    let reset: Int
    let used: Int
}

struct RateLimitResponse: Codable {
    let resources: Resources
    
    struct Resources: Codable {
        let core: RateLimit
    }
}

// MARK: - Error Response

/// GitHub API 错误响应
struct GitHubErrorResponse: Codable {
    let message: String
    let documentationUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case message
        case documentationUrl = "documentation_url"
    }
}
