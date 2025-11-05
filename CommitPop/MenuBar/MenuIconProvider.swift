//
//  MenuIconProvider.swift
//  CommitPop
//
//  菜单栏图标提供器
//

import AppKit

/// 菜单图标提供器
final class MenuIconProvider {
    
    /// 获取菜单栏图标
    static func getMenuIcon() -> NSImage? {
        // 先尝试加载自定义图标
        if let image = NSImage(named: Constants.MenuBar.menuIconName) {
            // 设置为模板图标（自动适配明暗主题）
            image.isTemplate = true
            
            // 设置图标大小 - 标准菜单栏图标大小
            let size = NSSize(width: 18, height: 18)
            image.size = size
            
            return image
        }
        
        // 如果自定义图标加载失败,使用 SF Symbols
        print("⚠️ 无法加载自定义菜单栏图标,使用 SF Symbol")
        return createSFSymbolIcon()
    }
    
    /// 创建 SF Symbol 图标
    private static func createSFSymbolIcon() -> NSImage? {
        // 使用 bell.badge 或 app.badge 作为替代图标
        let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .regular)
        
        if let image = NSImage(systemSymbolName: "bell.badge", accessibilityDescription: "CommitPop") {
            let resizedImage = image.withSymbolConfiguration(config)
            resizedImage?.isTemplate = true
            return resizedImage
        }
        
        // 最后的备选方案
        return createDefaultIcon()
    }
    
    /// 创建默认图标（如果资源加载失败）
    private static func createDefaultIcon() -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size)
        
        image.lockFocus()
        
        // 绘制一个简单的圆形图标
        let circlePath = NSBezierPath(ovalIn: NSRect(x: 4, y: 4, width: 10, height: 10))
        NSColor.labelColor.setFill()
        circlePath.fill()
        
        image.unlockFocus()
        image.isTemplate = true
        
        return image
    }
}
