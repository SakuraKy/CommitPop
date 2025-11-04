//
//  OpenURL.swift
//  CommitPop
//
//  打开 URL 的工具类
//

import AppKit

/// URL 打开工具
struct OpenURL {
    
    /// 在默认浏览器中打开 URL
    /// - Parameter urlString: URL 字符串
    /// - Returns: 是否成功打开
    @discardableResult
    static func open(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString) else {
            print("❌ 无效的 URL: \(urlString)")
            return false
        }
        
        return open(url)
    }
    
    /// 在默认浏览器中打开 URL
    /// - Parameter url: URL 对象
    /// - Returns: 是否成功打开
    @discardableResult
    static func open(_ url: URL) -> Bool {
        let opened = NSWorkspace.shared.open(url)
        
        if opened {
            print("🌐 已打开 URL: \(url.absoluteString)")
        } else {
            print("❌ 无法打开 URL: \(url.absoluteString)")
        }
        
        return opened
    }
    
    /// 在浏览器中打开 GitHub 通知验证页面
    /// - Parameter userCode: 用户码（可选，用于自动填充）
    static func openGitHubDeviceVerification(userCode: String? = nil) {
        open(Constants.GitHub.verificationURL)
    }
}
