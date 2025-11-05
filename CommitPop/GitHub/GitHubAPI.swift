//
//  GitHubAPI.swift
//  CommitPop
//
//  GitHub API 通用请求封装（URLSession，速率限制处理）
//

import Foundation
import Combine

/// GitHub API 错误
enum GitHubAPIError: Error, LocalizedError {
    case unauthorized
    case notFound
    case rateLimitExceeded(resetDate: Date)
    case serverError(statusCode: Int)
    case networkError(Error)
    case decodingError(Error)
    case notModified
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "未授权，请重新登录"
        case .notFound:
            return "请求的资源不存在"
        case .rateLimitExceeded(let resetDate):
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return "API 请求次数超限，将在 \(formatter.string(from: resetDate)) 后重置"
        case .serverError(let statusCode):
            return "服务器错误 (\(statusCode))"
        case .networkError(let error):
            return "网络错误: \(error.localizedDescription)"
        case .decodingError(let error):
            return "数据解析错误: \(error.localizedDescription)"
        case .notModified:
            return "内容未修改"
        case .unknown(let message):
            return "未知错误: \(message)"
        }
    }
}

/// GitHub API 响应
struct GitHubAPIResponse<T> {
    let data: T
    let rateLimit: RateLimit?
    let lastModified: String?
    let etag: String?
}

/// GitHub API 客户端
final class GitHubAPI {
    
    static let shared = GitHubAPI()
    
    private let session: URLSession
    private let keychainStore = KeychainStore.shared
    
    /// 当前速率限制信息
    @Published private(set) var currentRateLimit: RateLimit?
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Public Methods
    
    /// 通用 GET 请求
    /// - Parameters:
    ///   - endpoint: API 端点路径
    ///   - queryItems: 查询参数
    ///   - ifModifiedSince: If-Modified-Since 头（可选）
    ///   - etag: If-None-Match 头（可选）
    /// - Returns: 解码后的数据和响应头信息
    func get<T: Decodable>(
        endpoint: String,
        queryItems: [URLQueryItem]? = nil,
        ifModifiedSince: String? = nil,
        etag: String? = nil
    ) async throws -> GitHubAPIResponse<T> {
        
        // 构建 URL
        var urlComponents = URLComponents(string: Constants.GitHub.apiBaseURL + endpoint)
        urlComponents?.queryItems = queryItems
        
        guard let url = urlComponents?.url else {
            throw GitHubAPIError.unknown("无效的 URL")
        }
        
        // 构建请求
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        
        // 添加授权头
        if let token = try? keychainStore.retrieveAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // 添加条件请求头
        if let ifModifiedSince = ifModifiedSince {
            request.setValue(ifModifiedSince, forHTTPHeaderField: "If-Modified-Since")
        }
        if let etag = etag {
            request.setValue(etag, forHTTPHeaderField: "If-None-Match")
        }
        
        // 发送请求
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw GitHubAPIError.unknown("无效的响应")
            }
            
            // 解析速率限制信息
            let rateLimit = parseRateLimit(from: httpResponse)
            self.currentRateLimit = rateLimit
            
            // 处理状态码
            switch httpResponse.statusCode {
            case 200:
                // 成功
                let decodedData = try JSONDecoder().decode(T.self, from: data)
                let lastModified = httpResponse.value(forHTTPHeaderField: "Last-Modified")
                let etag = httpResponse.value(forHTTPHeaderField: "ETag")
                
                return GitHubAPIResponse(
                    data: decodedData,
                    rateLimit: rateLimit,
                    lastModified: lastModified,
                    etag: etag
                )
                
            case 304:
                // 未修改
                throw GitHubAPIError.notModified
                
            case 401, 403:
                if httpResponse.statusCode == 403,
                   let remaining = rateLimit?.remaining,
                   remaining == 0,
                   let reset = rateLimit?.reset {
                    // 速率限制
                    let resetDate = Date(timeIntervalSince1970: TimeInterval(reset))
                    throw GitHubAPIError.rateLimitExceeded(resetDate: resetDate)
                }
                throw GitHubAPIError.unauthorized
                
            case 404:
                throw GitHubAPIError.notFound
                
            case 500...599:
                throw GitHubAPIError.serverError(statusCode: httpResponse.statusCode)
                
            default:
                // 尝试解析错误信息
                if let errorResponse = try? JSONDecoder().decode(GitHubErrorResponse.self, from: data) {
                    throw GitHubAPIError.unknown(errorResponse.message)
                }
                throw GitHubAPIError.unknown("HTTP \(httpResponse.statusCode)")
            }
            
        } catch let error as GitHubAPIError {
            throw error
        } catch {
            throw GitHubAPIError.networkError(error)
        }
    }
    
    /// 获取当前用户信息
    func getCurrentUser() async throws -> AccountModel {
        let response: GitHubAPIResponse<AccountModel> = try await get(endpoint: "/user")
        return response.data
    }
    
    // MARK: - Private Methods
    
    /// 从响应头解析速率限制信息
    private func parseRateLimit(from response: HTTPURLResponse) -> RateLimit? {
        guard let limitStr = response.value(forHTTPHeaderField: "X-RateLimit-Limit"),
              let remainingStr = response.value(forHTTPHeaderField: "X-RateLimit-Remaining"),
              let resetStr = response.value(forHTTPHeaderField: "X-RateLimit-Reset"),
              let usedStr = response.value(forHTTPHeaderField: "X-RateLimit-Used"),
              let limit = Int(limitStr),
              let remaining = Int(remainingStr),
              let reset = Int(resetStr),
              let used = Int(usedStr) else {
            return nil
        }
        
        return RateLimit(limit: limit, remaining: remaining, reset: reset, used: used)
    }
}
