//
//  SettingsStore.swift
//  CommitPop
//
//  用户设置存储（基于 UserDefaults）
//

import Foundation
import Combine

/// 用户设置存储
final class SettingsStore: ObservableObject {
    
    static let shared = SettingsStore()
    
    private let defaults = UserDefaults.standard
    
    // MARK: - Published Properties
    
    /// 轮询间隔（分钟）
    @Published var pollingInterval: Int {
        didSet {
            defaults.set(pollingInterval, forKey: Constants.UserDefaultsKeys.pollingInterval)
        }
    }
    
    /// 是否仅参与的通知
    @Published var participatingOnly: Bool {
        didSet {
            defaults.set(participatingOnly, forKey: Constants.UserDefaultsKeys.participatingOnly)
        }
    }
    
    /// 是否启用通知声音
    @Published var notificationSoundEnabled: Bool {
        didSet {
            defaults.set(notificationSoundEnabled, forKey: Constants.UserDefaultsKeys.notificationSoundEnabled)
        }
    }
    
    /// 是否开机自启
    @Published var launchAtLogin: Bool {
        didSet {
            defaults.set(launchAtLogin, forKey: Constants.UserDefaultsKeys.launchAtLogin)
            updateLaunchAtLoginStatus()
        }
    }
    
    /// GitHub Client ID
    @Published var githubClientID: String {
        didSet {
            defaults.set(githubClientID, forKey: Constants.UserDefaultsKeys.githubClientID)
        }
    }
    
    /// 是否暂停通知
    @Published var notificationsPaused: Bool {
        didSet {
            defaults.set(notificationsPaused, forKey: Constants.UserDefaultsKeys.notificationsPaused)
        }
    }
    
    /// 选定的仓库列表
    @Published var selectedRepositories: [String] {
        didSet {
            defaults.set(selectedRepositories, forKey: Constants.UserDefaultsKeys.selectedRepositories)
        }
    }
    
    // MARK: - Initialization
    
    private init() {
        // 加载设置，提供默认值
        self.pollingInterval = defaults.object(forKey: Constants.UserDefaultsKeys.pollingInterval) as? Int
            ?? Constants.Defaults.pollingInterval
        
        self.participatingOnly = defaults.object(forKey: Constants.UserDefaultsKeys.participatingOnly) as? Bool
            ?? true
        
        self.notificationSoundEnabled = defaults.object(forKey: Constants.UserDefaultsKeys.notificationSoundEnabled) as? Bool
            ?? true
        
        self.launchAtLogin = defaults.object(forKey: Constants.UserDefaultsKeys.launchAtLogin) as? Bool
            ?? false
        
        self.githubClientID = defaults.string(forKey: Constants.UserDefaultsKeys.githubClientID)
            ?? ""
        
        self.notificationsPaused = defaults.object(forKey: Constants.UserDefaultsKeys.notificationsPaused) as? Bool
            ?? false
        
        self.selectedRepositories = defaults.stringArray(forKey: Constants.UserDefaultsKeys.selectedRepositories)
            ?? []
    }
    
    // MARK: - Methods
    
    /// 重置所有设置
    func resetToDefaults() {
        pollingInterval = Constants.Defaults.pollingInterval
        participatingOnly = true
        notificationSoundEnabled = true
        launchAtLogin = false
        notificationsPaused = false
        selectedRepositories = []
        // 不重置 githubClientID
    }
    
    /// 更新开机自启状态
    private func updateLaunchAtLoginStatus() {
        // 使用 SMAppService 设置登录项
        if #available(macOS 13.0, *) {
            let service = SMAppService.mainApp
            do {
                if launchAtLogin {
                    try service.register()
                    print("✅ 已启用开机自启")
                } else {
                    try service.unregister()
                    print("✅ 已禁用开机自启")
                }
            } catch {
                print("❌ 设置开机自启失败: \(error)")
            }
        } else {
            print("⚠️ 开机自启需要 macOS 13.0 或更高版本")
        }
    }
}

// MARK: - ServiceManagement Import

import ServiceManagement
