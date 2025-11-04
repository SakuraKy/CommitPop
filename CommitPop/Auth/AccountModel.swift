//
//  AccountModel.swift
//  CommitPop
//
//  用户账户模型
//

import Foundation

/// GitHub 账户信息
struct AccountModel: Codable {
    let login: String
    let id: Int
    let avatarUrl: String?
    let htmlUrl: String?
    let name: String?
    let email: String?
    
    enum CodingKeys: String, CodingKey {
        case login
        case id
        case avatarUrl = "avatar_url"
        case htmlUrl = "html_url"
        case name
        case email
    }
}

/// 账户状态
enum AccountStatus {
    case loggedOut
    case loggingIn
    case loggedIn(AccountModel)
    case error(Error)
    
    var isLoggedIn: Bool {
        if case .loggedIn = self {
            return true
        }
        return false
    }
}
