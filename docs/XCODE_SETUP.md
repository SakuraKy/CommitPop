# Xcode 项目配置清单

完成 CommitPop 项目配置需要在 Xcode 中进行以下设置：

## 1. 基本信息 (General)

- **Display Name**: CommitPop
- **Bundle Identifier**: com.commitpop.app（或你的自定义标识）
- **Version**: 1.0.0
- **Build**: 1
- **Deployment Target**: macOS 13.0

## 2. Signing & Capabilities

### Signing

- ✅ 选择你的开发团队
- ✅ 自动管理签名（或手动配置）

### Capabilities

- ✅ **App Sandbox**
  - [x] **Outgoing Connections (Client)** - 必需，用于访问 GitHub API
  - [x] **Incoming Connections (Server)** - 可选
- ✅ **Hardened Runtime**（如果需要公证）

## 3. Info.plist 配置

在 Xcode 中，打开项目设置 → Info 标签页，添加以下键值对：

### 必需配置

| Key                                   | Type    | Value                                        | 说明                         |
| ------------------------------------- | ------- | -------------------------------------------- | ---------------------------- |
| `Application is agent (UIElement)`    | Boolean | `YES`                                        | 隐藏 Dock 图标，仅显示菜单栏 |
| `NSUserNotificationsUsageDescription` | String  | `CommitPop 需要通知权限来提醒您 GitHub 动态` | 通知权限说明                 |

### 可选配置

| Key                        | Type   | Value                                     | 说明         |
| -------------------------- | ------ | ----------------------------------------- | ------------ |
| `CFBundleName`             | String | `CommitPop`                               | 应用名称     |
| `CFBundleDisplayName`      | String | `CommitPop`                               | 显示名称     |
| `LSMinimumSystemVersion`   | String | `13.0`                                    | 最低系统版本 |
| `NSHumanReadableCopyright` | String | `Copyright © 2025 CommitPop Contributors` | 版权信息     |

### Info.plist 原始格式（可直接编辑）

如果需要手动编辑 Info.plist（右键 → Open As → Source Code）：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- 基本信息 -->
    <key>CFBundleDevelopmentRegion</key>
    <string>$(DEVELOPMENT_LANGUAGE)</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$(PRODUCT_NAME)</string>
    <key>CFBundlePackageType</key>
    <string>$(PRODUCT_BUNDLE_PACKAGE_TYPE)</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>

    <!-- 菜单栏应用配置（必需） -->
    <key>LSUIElement</key>
    <true/>

    <!-- 通知权限说明（必需） -->
    <key>NSUserNotificationsUsageDescription</key>
    <string>CommitPop 需要通知权限来提醒您 GitHub 动态</string>

    <!-- 最低系统版本 -->
    <key>LSMinimumSystemVersion</key>
    <string>$(MACOSX_DEPLOYMENT_TARGET)</string>

    <!-- 版权信息 -->
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2025 CommitPop Contributors</string>

    <!-- 主要场景（SwiftUI） -->
    <key>NSMainStoryboardFile</key>
    <string></string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
```

## 4. Build Settings

### 搜索 "Swift Language Version"

- 设置为 **Swift 5** 或更高

### 搜索 "Deployment"

- **macOS Deployment Target**: 13.0

## 5. Asset Catalog 配置

确保 `Assets.xcassets` 中包含：

- ✅ **AppIcon** - 应用图标（1024x1024 及各种尺寸）
- ✅ **MenuIcon** - 菜单栏图标（Template Image）
  - 推荐尺寸：18x18 @ 1x, 36x36 @ 2x
  - 设置为 **Template Image**（单色，自动适配主题）

### MenuIcon 配置步骤：

1. 在 Assets.xcassets 中选择 MenuIcon
2. 在右侧 Attributes Inspector 中
3. **Render As** 选择 **Template Image**
4. 提供黑色图标即可（系统会自动反色）

## 6. 项目文件包含

确保以下文件已添加到 Xcode 项目的 Target：

### Sources (Compile Sources)

- [x] CommitPopApp.swift
- [x] AppDelegate.swift
- [x] Constants.swift
- [x] Auth/\*.swift (3 个文件)
- [x] GitHub/_.swift + Models/_.swift (3 个文件)
- [x] MenuBar/\*.swift (2 个文件)
- [x] Notifications/\*.swift (2 个文件)
- [x] Scheduler/\*.swift (1 个文件)
- [x] Persistence/\*.swift (2 个文件)
- [x] PreferencesUI/\*.swift (4 个文件)
- [x] Utils/\*.swift (2 个文件)

### Resources

- [x] Assets.xcassets

## 7. 框架依赖

项目使用的都是系统框架，无需添加第三方依赖：

- Foundation
- AppKit
- SwiftUI
- UserNotifications
- Security
- Combine
- ServiceManagement

## 8. 构建和运行

### 首次构建

1. 选择 Target: CommitPop
2. 选择 My Mac（或你的 Mac）
3. 按 `Cmd + B` 构建
4. 按 `Cmd + R` 运行

### 常见构建问题

**问题：找不到某些 Swift 文件**

- 解决：确保所有 .swift 文件都已添加到 Target Membership

**问题：无法访问网络**

- 解决：检查 Sandbox 是否启用了 Outgoing Connections (Client)

**问题：通知不显示**

- 解决：检查 Info.plist 中是否添加了 NSUserNotificationsUsageDescription

**问题：菜单栏图标不显示**

- 解决：确保 MenuIcon 存在于 Assets.xcassets 且设置为 Template Image

## 9. 调试技巧

### 查看控制台日志

- 运行时打开 Xcode → View → Debug Area → Show Debug Area
- 或按 `Cmd + Shift + Y`

### 启用详细日志

在 Scheme → Run → Arguments 中添加环境变量：

- `OS_ACTIVITY_MODE` = `disable` （禁用系统日志干扰）

### 调试通知

- 在 NotificationsTabView 中点击"发送测试通知"
- 检查系统通知中心是否允许 CommitPop 发送通知

## 10. 分发准备（可选）

### Archive 和导出

1. Product → Archive
2. 选择 Export
3. 根据需要选择导出方式（开发者 ID 签名等）

### 公证（Notarization）

如果要分发给其他用户，需要公证：

1. 使用开发者 ID 签名
2. 提交到 Apple 进行公证
3. 将公证票据附加到应用

---

## 快速检查清单

在运行前，确保：

- [ ] LSUIElement = YES（Info.plist）
- [ ] 通知权限说明已添加
- [ ] App Sandbox 已启用
- [ ] Outgoing Connections 已勾选
- [ ] MenuIcon 存在且设置为 Template
- [ ] 所有 Swift 文件已添加到 Target
- [ ] Deployment Target = macOS 13.0
- [ ] 开发团队已选择

完成以上配置后，CommitPop 应该可以正常编译和运行了！
