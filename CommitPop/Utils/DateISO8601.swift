//
//  DateISO8601.swift
//  CommitPop
//
//  ISO 8601 日期格式化工具
//

import Foundation

/// ISO 8601 日期工具
struct DateISO8601 {
    
    private static let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    private static let iso8601FormatterNoFractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
    
    /// 将 Date 转换为 ISO 8601 字符串
    /// - Parameter date: Date 对象
    /// - Returns: ISO 8601 格式的字符串
    static func string(from date: Date) -> String {
        return iso8601Formatter.string(from: date)
    }
    
    /// 将 ISO 8601 字符串转换为 Date
    /// - Parameter string: ISO 8601 格式的字符串
    /// - Returns: Date 对象，如果解析失败返回 nil
    static func date(from string: String) -> Date? {
        // 尝试带小数秒的格式
        if let date = iso8601Formatter.date(from: string) {
            return date
        }
        
        // 尝试不带小数秒的格式
        if let date = iso8601FormatterNoFractional.date(from: string) {
            return date
        }
        
        return nil
    }
    
    /// 获取相对时间描述（例如："5 分钟前"）
    /// - Parameter date: Date 对象
    /// - Returns: 相对时间字符串
    static func relativeString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
