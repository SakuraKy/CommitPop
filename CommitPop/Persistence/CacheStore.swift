//
//  CacheStore.swift
//  CommitPop
//
//  缓存存储（Last-Modified、线程去重信息等）
//

import Foundation

/// 缓存存储
final class CacheStore {
    
    static let shared = CacheStore()
    
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    // MARK: - Cache Models
    
    /// Last-Modified 缓存
    struct LastModifiedCache: Codable {
        var notificationsLastModified: String?
        var lastSyncDate: Date?
    }
    
    /// 线程缓存（用于去重）
    struct ThreadCache: Codable {
        var seenThreads: [String: ThreadInfo] = [:]
        
        struct ThreadInfo: Codable {
            let id: String
            let updatedAt: String
            let lastNotifiedAt: Date
        }
    }
    
    // MARK: - Initialization
    
    private init() {
        // 获取应用支持目录
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let bundleID = Bundle.main.bundleIdentifier ?? "com.commitpop.app"
        cacheDirectory = appSupport.appendingPathComponent(bundleID).appendingPathComponent(Constants.Cache.directoryName)
        
        // 创建缓存目录
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    // MARK: - Last-Modified Cache
    
    /// 保存 Last-Modified 信息
    func saveLastModified(_ lastModified: String?) {
        var cache = loadLastModifiedCache()
        cache.notificationsLastModified = lastModified
        cache.lastSyncDate = Date() // 每次调用都更新同步时间
        
        let fileURL = cacheDirectory.appendingPathComponent(Constants.Cache.lastModifiedFile)
        
        do {
            let data = try JSONEncoder().encode(cache)
            try data.write(to: fileURL)
        } catch {
            print("❌ 保存同步时间失败: \(error)")
        }
    }
    
    /// 加载 Last-Modified 信息
    func loadLastModifiedCache() -> LastModifiedCache {
        let fileURL = cacheDirectory.appendingPathComponent(Constants.Cache.lastModifiedFile)
        
        guard fileManager.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL),
              let cache = try? JSONDecoder().decode(LastModifiedCache.self, from: data) else {
            return LastModifiedCache()
        }
        
        return cache
    }
    
    /// 获取 Last-Modified 字符串
    func getLastModified() -> String? {
        return loadLastModifiedCache().notificationsLastModified
    }
    
    /// 获取上次同步时间
    func getLastSyncDate() -> Date? {
        return loadLastModifiedCache().lastSyncDate
    }
    
    // MARK: - Thread Cache (Deduplication)
    
    /// 检查线程是否需要通知
    /// - Parameter thread: GitHub 通知线程
    /// - Returns: 是否需要发送通知
    func shouldNotifyThread(_ thread: GitHubNotificationThread) -> Bool {
        var cache = loadThreadCache()
        
        // 检查是否已见过此线程
        if let seenInfo = cache.seenThreads[thread.id] {
            // 如果 updatedAt 没有变化，不通知
            if seenInfo.updatedAt == thread.updatedAt {
                return false
            }
            
            // 如果 updatedAt 有变化，且距离上次通知超过 1 分钟，可以通知
            let timeSinceLastNotification = Date().timeIntervalSince(seenInfo.lastNotifiedAt)
            if timeSinceLastNotification < 60 {
                return false
            }
        }
        
        // 标记为已通知
        cache.seenThreads[thread.id] = ThreadCache.ThreadInfo(
            id: thread.id,
            updatedAt: thread.updatedAt,
            lastNotifiedAt: Date()
        )
        
        saveThreadCache(cache)
        return true
    }
    
    /// 加载线程缓存
    private func loadThreadCache() -> ThreadCache {
        let fileURL = cacheDirectory.appendingPathComponent(Constants.Cache.threadsFile)
        
        guard fileManager.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL),
              let cache = try? JSONDecoder().decode(ThreadCache.self, from: data) else {
            return ThreadCache()
        }
        
        return cache
    }
    
    /// 保存线程缓存
    private func saveThreadCache(_ cache: ThreadCache) {
        let fileURL = cacheDirectory.appendingPathComponent(Constants.Cache.threadsFile)
        
        do {
            let data = try JSONEncoder().encode(cache)
            try data.write(to: fileURL)
        } catch {
            print("❌ 保存线程缓存失败: \(error)")
        }
    }
    
    // MARK: - Clear Cache
    
    /// 清除所有缓存
    func clearAllCache() {
        do {
            let contents = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            for fileURL in contents {
                try fileManager.removeItem(at: fileURL)
            }
            print("✅ 已清除所有缓存")
        } catch {
            print("❌ 清除缓存失败: \(error)")
        }
    }
    
    /// 导出缓存数据
    func exportCache() -> String? {
        let lastModified = loadLastModifiedCache()
        let threads = loadThreadCache()
        
        let export: [String: Any] = [
            "lastModified": [
                "notificationsLastModified": lastModified.notificationsLastModified ?? "",
                "lastSyncDate": lastModified.lastSyncDate?.description ?? ""
            ],
            "threadsCount": threads.seenThreads.count
        ]
        
        guard let data = try? JSONSerialization.data(withJSONObject: export, options: .prettyPrinted),
              let json = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return json
    }
}
