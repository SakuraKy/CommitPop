//
//  Constants.swift
//  CommitPop
//
//  集中管理应用内所有常量字符串，便于维护和本地化
//

import Foundation

struct Constants {
    // MARK: - Bundle Identifiers
    struct BundleIdentifiers {
        static let app = "com.commitpop.app"
    }
    
    // MARK: - Keychain
    struct Keychain {
        /// Keychain 服务标识符
        static let service = "com.commitpop.github.token"
        /// 存储 GitHub access_token 的账户名
        static let accountName = "github_access_token"
    }
    
    // MARK: - GitHub OAuth URLs
    struct GitHub {
        /// 设备码请求端点
        static let deviceCodeURL = URL(string: "https://github.com/login/device/code")!
        /// 访问令牌请求端点
        static let accessTokenURL = URL(string: "https://github.com/login/oauth/access_token")!
        /// 用户验证页面
        static let verificationURL = URL(string: "https://github.com/login/device")!
        
        /// GitHub API 基础 URL
        static let apiBaseURL = "https://api.github.com"
        
        /// 默认 OAuth Scope
        static let defaultScope = "notifications repo"
    }
    
    // MARK: - Notification Keys
    struct NotificationNames {
        static let userDidLogin = Notification.Name("com.commitpop.notification.userDidLogin")
        static let userDidLogout = Notification.Name("com.commitpop.notification.userDidLogout")
        static let syncDidComplete = Notification.Name("com.commitpop.notification.syncDidComplete")
        static let syncDidFail = Notification.Name("com.commitpop.notification.syncDidFail")
    }
    
    // MARK: - UserDefaults Keys
    struct UserDefaultsKeys {
        /// 轮询间隔（分钟）
        static let pollingInterval = "pollingInterval"
        /// 是否仅参与的通知
        static let participatingOnly = "participatingOnly"
        /// 是否启用通知声音
        static let notificationSoundEnabled = "notificationSoundEnabled"
        /// 是否开机自启
        static let launchAtLogin = "launchAtLogin"
        /// GitHub Client ID
        static let githubClientID = "githubClientID"
        /// 是否暂停通知
        static let notificationsPaused = "notificationsPaused"
        /// 选定的仓库列表
        static let selectedRepositories = "selectedRepositories"
    }
    
    // MARK: - Cache
    struct Cache {
        /// 缓存文件目录
        static let directoryName = "CommitPopCache"
        /// Last-Modified 缓存文件
        static let lastModifiedFile = "last_modified.json"
        /// 线程去重信息缓存文件
        static let threadsFile = "threads.json"
    }
    
    // MARK: - App Name & Info
    static let appName = "CommitPop"
    static let appVersion = "1.0.0"
    
    // MARK: - Defaults
    struct Defaults {
        /// 默认轮询间隔（分钟）
        static let pollingInterval = 5
        /// 最小轮询间隔（分钟）
        static let minPollingInterval = 1
        /// 最大轮询间隔（分钟）
        static let maxPollingInterval = 30
        /// 最近事件显示数量
        static let recentEventsCount = 5
    }
    
    // MARK: - Menu Bar
    struct MenuBar {
        static let menuIconName = "MenuIcon"
        static let statusItemLength: CGFloat = -1 // NSStatusItem.variableLength
    }
}
