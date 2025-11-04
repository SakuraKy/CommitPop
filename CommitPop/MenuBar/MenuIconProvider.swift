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
        guard let image = NSImage(named: Constants.MenuBar.menuIconName) else {
            print("⚠️ 无法加载菜单栏图标: \(Constants.MenuBar.menuIconName)")
            // 创建一个默认图标
            return createDefaultIcon()
        }
        
        // 设置为模板图标（自动适配明暗主题）
        image.isTemplate = true
        
        return image
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
