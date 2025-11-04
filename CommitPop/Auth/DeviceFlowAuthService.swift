//
//  DeviceFlowAuthService.swift
//  CommitPop
//
//  GitHub OAuth 2.0 设备码授权流程实现
//  参考：https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/authorizing-oauth-apps#device-flow
//

import Foundation
import Combine

/// 设备码授权错误
enum DeviceFlowAuthError: Error, LocalizedError {
    case invalidClientID
    case networkError(Error)
    case invalidResponse
    case authorizationPending
    case slowDown
    case expiredToken
    case accessDenied
    case incorrectDeviceCode
    case unsupportedGrantType
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidClientID:
            return "Client ID 无效"
        case .networkError(let error):
            return "网络错误: \(error.localizedDescription)"
        case .invalidResponse:
            return "服务器返回了无效的响应"
        case .authorizationPending:
            return "等待用户授权中..."
        case .slowDown:
            return "请求过于频繁，请稍后重试"
        case .expiredToken:
            return "设备码已过期，请重新开始授权"
        case .accessDenied:
            return "用户拒绝了授权"
        case .incorrectDeviceCode:
            return "设备码不正确"
        case .unsupportedGrantType:
            return "不支持的授权类型"
        case .unknown(let message):
            return "未知错误: \(message)"
        }
    }
}

/// 设备码响应
struct DeviceCodeResponse: Codable {
    let deviceCode: String
    let userCode: String
    let verificationUri: String
    let expiresIn: Int
    let interval: Int
    
    enum CodingKeys: String, CodingKey {
        case deviceCode = "device_code"
        case userCode = "user_code"
        case verificationUri = "verification_uri"
        case expiresIn = "expires_in"
        case interval
    }
}

/// 访问令牌响应
struct AccessTokenResponse: Codable {
    let accessToken: String?
    let tokenType: String?
    let scope: String?
    let error: String?
    let errorDescription: String?
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case scope
        case error
        case errorDescription = "error_description"
    }
}

/// 设备码授权服务
@MainActor
final class DeviceFlowAuthService: ObservableObject {
    
    @Published var isAuthenticating = false
    @Published var deviceCode: DeviceCodeResponse?
    @Published var authError: DeviceFlowAuthError?
    
    private var pollingTask: Task<Void, Never>?
    private let keychainStore = KeychainStore.shared
    
    // MARK: - Public Methods
    
    /// 开始设备码授权流程
    /// - Parameters:
    ///   - clientID: GitHub OAuth App Client ID
    ///   - scope: 请求的权限范围
    func startDeviceFlow(clientID: String, scope: String = Constants.GitHub.defaultScope) async throws -> DeviceCodeResponse {
        guard !clientID.isEmpty else {
            throw DeviceFlowAuthError.invalidClientID
        }
        
        isAuthenticating = true
        authError = nil
        
        // 1. 请求设备码
        let deviceCodeResponse = try await requestDeviceCode(clientID: clientID, scope: scope)
        self.deviceCode = deviceCodeResponse
        
        return deviceCodeResponse
    }
    
    /// 开始轮询访问令牌
    /// - Parameter clientID: GitHub OAuth App Client ID
    func startPollingForAccessToken(clientID: String) {
        guard let deviceCode = deviceCode else { return }
        
        // 取消之前的轮询任务
        pollingTask?.cancel()
        
        pollingTask = Task {
            var interval = deviceCode.interval
            let maxAttempts = deviceCode.expiresIn / interval
            
            for _ in 0..<maxAttempts {
                // 检查任务是否被取消
                if Task.isCancelled {
                    break
                }
                
                do {
                    // 等待指定间隔
                    try await Task.sleep(nanoseconds: UInt64(interval) * 1_000_000_000)
                    
                    // 请求访问令牌
                    let token = try await requestAccessToken(
                        clientID: clientID,
                        deviceCode: deviceCode.deviceCode
                    )
                    
                    // 成功获取令牌
                    try keychainStore.saveAccessToken(token)
                    
                    await MainActor.run {
                        self.isAuthenticating = false
                        self.deviceCode = nil
                        NotificationCenter.default.post(name: Constants.NotificationNames.userDidLogin, object: nil)
                    }
                    
                    return
                    
                } catch DeviceFlowAuthError.authorizationPending {
                    // 继续等待
                    continue
                    
                } catch DeviceFlowAuthError.slowDown {
                    // 增加轮询间隔
                    interval += 5
                    continue
                    
                } catch {
                    // 其他错误，停止轮询
                    await MainActor.run {
                        self.authError = error as? DeviceFlowAuthError ?? .unknown(error.localizedDescription)
                        self.isAuthenticating = false
                    }
                    return
                }
            }
            
            // 超时
            await MainActor.run {
                self.authError = .expiredToken
                self.isAuthenticating = false
            }
        }
    }
    
    /// 取消授权流程
    func cancelAuth() {
        pollingTask?.cancel()
        isAuthenticating = false
        deviceCode = nil
        authError = nil
    }
    
    /// 注销（删除令牌）
    func logout() throws {
        try keychainStore.deleteAccessToken()
        NotificationCenter.default.post(name: Constants.NotificationNames.userDidLogout, object: nil)
    }
    
    // MARK: - Private Methods
    
    /// 请求设备码
    private func requestDeviceCode(clientID: String, scope: String) async throws -> DeviceCodeResponse {
        var request = URLRequest(url: Constants.GitHub.deviceCodeURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = [
            "client_id": clientID,
            "scope": scope
        ]
        request.httpBody = try JSONEncoder().encode(body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw DeviceFlowAuthError.invalidResponse
            }
            
            let deviceCodeResponse = try JSONDecoder().decode(DeviceCodeResponse.self, from: data)
            return deviceCodeResponse
            
        } catch {
            throw DeviceFlowAuthError.networkError(error)
        }
    }
    
    /// 请求访问令牌
    private func requestAccessToken(clientID: String, deviceCode: String) async throws -> String {
        var request = URLRequest(url: Constants.GitHub.accessTokenURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = [
            "client_id": clientID,
            "device_code": deviceCode,
            "grant_type": "urn:ietf:params:oauth:grant-type:device_code"
        ]
        request.httpBody = try JSONEncoder().encode(body)
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let tokenResponse = try JSONDecoder().decode(AccessTokenResponse.self, from: data)
            
            // 检查是否有错误
            if let error = tokenResponse.error {
                throw parseTokenError(error)
            }
            
            guard let accessToken = tokenResponse.accessToken else {
                throw DeviceFlowAuthError.invalidResponse
            }
            
            return accessToken
            
        } catch let error as DeviceFlowAuthError {
            throw error
        } catch {
            throw DeviceFlowAuthError.networkError(error)
        }
    }
    
    /// 解析令牌错误
    private func parseTokenError(_ error: String) -> DeviceFlowAuthError {
        switch error {
        case "authorization_pending":
            return .authorizationPending
        case "slow_down":
            return .slowDown
        case "expired_token":
            return .expiredToken
        case "access_denied":
            return .accessDenied
        case "incorrect_device_code":
            return .incorrectDeviceCode
        case "unsupported_grant_type":
            return .unsupportedGrantType
        default:
            return .unknown(error)
        }
    }
}
