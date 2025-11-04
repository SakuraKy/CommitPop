//
//  KeychainStore.swift
//  CommitPop
//
//  Keychain 封装，用于安全存储 GitHub access_token
//

import Foundation
import Security

/// Keychain 存储错误类型
enum KeychainError: Error, LocalizedError {
    case unableToStore
    case unableToRetrieve
    case unableToDelete
    case itemNotFound
    case unexpectedData
    
    var errorDescription: String? {
        switch self {
        case .unableToStore:
            return "无法存储到 Keychain"
        case .unableToRetrieve:
            return "无法从 Keychain 读取"
        case .unableToDelete:
            return "无法从 Keychain 删除"
        case .itemNotFound:
            return "Keychain 中未找到该项"
        case .unexpectedData:
            return "Keychain 返回了意外的数据格式"
        }
    }
}

/// Keychain 操作封装
final class KeychainStore {
    
    /// 单例
    static let shared = KeychainStore()
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// 存储 access_token 到 Keychain
    /// - Parameter token: GitHub access token
    /// - Throws: KeychainError
    func saveAccessToken(_ token: String) throws {
        guard let data = token.data(using: .utf8) else {
            throw KeychainError.unexpectedData
        }
        
        // 先尝试删除旧的
        try? deleteAccessToken()
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Constants.Keychain.service,
            kSecAttrAccount as String: Constants.Keychain.accountName,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.unableToStore
        }
    }
    
    /// 从 Keychain 读取 access_token
    /// - Returns: GitHub access token，如果不存在返回 nil
    /// - Throws: KeychainError
    func retrieveAccessToken() throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Constants.Keychain.service,
            kSecAttrAccount as String: Constants.Keychain.accountName,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecItemNotFound {
            return nil
        }
        
        guard status == errSecSuccess else {
            throw KeychainError.unableToRetrieve
        }
        
        guard let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            throw KeychainError.unexpectedData
        }
        
        return token
    }
    
    /// 从 Keychain 删除 access_token
    /// - Throws: KeychainError
    func deleteAccessToken() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Constants.Keychain.service,
            kSecAttrAccount as String: Constants.Keychain.accountName
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unableToDelete
        }
    }
    
    /// 检查是否已存储 token
    /// - Returns: 是否存在 token
    func hasAccessToken() -> Bool {
        return (try? retrieveAccessToken()) != nil
    }
}
