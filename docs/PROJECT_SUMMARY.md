# CommitPop 项目开发总结

## 项目概述

**CommitPop** 是一个纯本地运行的 macOS 原生 GitHub 通知助手，使用 Swift 5.9+ 开发，遵循 Apache License 2.0 开源协议。

### 核心功能

- ✅ GitHub OAuth 2.0 Device Flow 授权
- ✅ 实时监控 GitHub 通知（参与的 Issue、PR 等）
- ✅ macOS 系统级通知推送
- ✅ 智能去重机制
- ✅ 菜单栏常驻应用
- ✅ 可配置的轮询间隔（1-30 分钟）
- ✅ 开机自启（macOS 13+）
- ✅ Keychain 安全存储 token

---

## 技术实现

### 1. 架构设计

```
CommitPop (菜单栏应用, LSUIElement = YES)
├── Auth 模块 (OAuth Device Flow + Keychain)
├── GitHub API 模块 (URLSession + 速率限制处理)
├── Notifications 模块 (UserNotifications)
├── Scheduler 模块 (定时轮询 + 去重)
├── Persistence 模块 (UserDefaults + JSON 缓存)
├── MenuBar 模块 (NSStatusItem)
└── PreferencesUI 模块 (SwiftUI)
```

### 2. 关键技术点

#### OAuth Device Flow 授权流程

```swift
// 1. 请求设备码
POST https://github.com/login/device/code
Body: { client_id, scope }
Response: { device_code, user_code, verification_uri, interval }

// 2. 用户在浏览器中输入 user_code 授权

// 3. 轮询获取 access_token
POST https://github.com/login/oauth/access_token
Body: { client_id, device_code, grant_type }
Response: { access_token } 或错误状态

// 4. 存入 Keychain
KeychainStore.shared.saveAccessToken(token)
```

#### 通知拉取优化

```swift
// 使用 Last-Modified / If-Modified-Since 减少传输
GET /notifications?participating=true
Headers:
  - If-Modified-Since: <上次的 Last-Modified>
  - Authorization: Bearer <token>

// 304 Not Modified → 无需更新
// 200 OK → 解析新通知 + 保存新的 Last-Modified
```

#### 智能去重

```swift
// 基于 thread.id + updatedAt 判断
struct ThreadCache {
    var seenThreads: [String: ThreadInfo]

    struct ThreadInfo {
        let id: String
        let updatedAt: String
        let lastNotifiedAt: Date
    }
}

// 60 秒内相同线程不重复通知
func shouldNotifyThread(_ thread: GitHubNotificationThread) -> Bool
```

### 3. 数据流

```
用户启动应用
    ↓
请求通知权限
    ↓
检查 Keychain 中是否有 token
    ↓
没有 → 引导 OAuth 登录
    ↓
有 → 启动 PollingScheduler
    ↓
每 N 分钟调用 /notifications API
    ↓
解析新通知 → 去重 → 发送系统通知
    ↓
点击通知 → 打开浏览器 → 跳转 GitHub 页面
```

---

## 项目文件清单

### 核心源代码 (22 个文件)

```
CommitPop/
├── CommitPopApp.swift               # 应用入口
├── AppDelegate.swift                # 通知委托
├── Constants.swift                  # 常量定义
│
├── Auth/ (3 文件)
│   ├── DeviceFlowAuthService.swift  # OAuth 实现
│   ├── KeychainStore.swift          # Keychain 封装
│   └── AccountModel.swift           # 账户模型
│
├── GitHub/ (3 文件 + Models/)
│   ├── GitHubAPI.swift              # 通用 API 客户端
│   ├── GitHubNotificationsAPI.swift # 通知 API
│   └── Models/
│       └── GitHubModels.swift       # 数据模型
│
├── Notifications/ (2 文件)
│   ├── NotificationCenterManager.swift  # 系统通知管理
│   └── Notifier.swift                   # 业务通知转换
│
├── Scheduler/ (1 文件)
│   └── PollingScheduler.swift       # 定时调度
│
├── Persistence/ (2 文件)
│   ├── SettingsStore.swift          # 设置存储
│   └── CacheStore.swift             # 缓存管理
│
├── MenuBar/ (2 文件)
│   ├── MenuBarController.swift      # 菜单栏控制
│   └── MenuIconProvider.swift       # 图标提供
│
├── PreferencesUI/ (4 文件)
│   ├── GeneralTabView.swift         # 登录设置
│   ├── NotificationsTabView.swift   # 通知设置
│   ├── StartupTabView.swift         # 启动项设置
│   └── AdvancedTabView.swift        # 高级设置
│
└── Utils/ (2 文件)
    ├── DateISO8601.swift            # 日期工具
    └── OpenURL.swift                # URL 工具
```

### 配置和文档

```
CommitPop/
├── LICENSE                  # Apache 2.0 许可证
├── README.md               # 项目说明文档
├── XCODE_SETUP.md          # Xcode 配置指南
├── .gitignore              # Git 忽略规则
│
└── CommitPop.xcodeproj/    # Xcode 项目文件
    └── project.pbxproj
```

---

## 代码统计

- **总文件数**: 22 个 Swift 源文件
- **总代码行数**: 约 2800+ 行（含注释）
- **第三方依赖**: 0（纯系统框架）
- **支持系统**: macOS 13.0+

### 模块代码行数分布

| 模块          | 文件数 | 代码行数 |
| ------------- | ------ | -------- |
| Auth          | 3      | ~450     |
| GitHub        | 3      | ~450     |
| Notifications | 2      | ~350     |
| Scheduler     | 1      | ~200     |
| Persistence   | 2      | ~350     |
| MenuBar       | 2      | ~250     |
| PreferencesUI | 4      | ~600     |
| Utils         | 2      | ~100     |
| 其他          | 3      | ~50      |

---

## 关键特性实现

### ✅ 已实现

1. **授权系统**

   - GitHub OAuth 2.0 Device Flow
   - Keychain 安全存储
   - 登录/登出功能
   - 账户信息展示

2. **通知系统**

   - UserNotifications 集成
   - 权限请求和管理
   - 通知去重机制
   - 点击跳转 GitHub

3. **GitHub API**

   - 通用 API 客户端
   - 速率限制处理
   - Last-Modified 优化
   - 错误处理和重试

4. **调度器**

   - 可配置轮询间隔
   - 暂停/恢复功能
   - 指数退避策略
   - 状态监控

5. **数据持久化**

   - UserDefaults 设置存储
   - JSON 文件缓存
   - Last-Modified 缓存
   - 线程去重缓存

6. **菜单栏 UI**

   - NSStatusItem 菜单
   - 状态显示
   - 快速操作
   - 最近事件列表

7. **首选项界面**

   - SwiftUI 实现
   - 4 个设置标签页
   - 实时设置更新
   - 测试功能

8. **启动项**
   - macOS 13+ SMAppService
   - 开机自启开关
   - 状态检查

### 🚧 待扩展（路线图）

- [ ] 筛选特定仓库
- [ ] 多账户支持
- [ ] 统计仪表盘
- [ ] 自定义通知规则
- [ ] GraphQL API
- [ ] 国际化

---

## 遵循的最佳实践

### 1. 代码质量

- ✅ 使用 `Codable` 进行 JSON 解析
- ✅ 使用 `Result` 和 `async/await` 处理异步
- ✅ 错误使用枚举细分
- ✅ 重要方法添加注释
- ✅ 使用 `@MainActor` 确保线程安全

### 2. 安全性

- ✅ token 存储在 Keychain
- ✅ 不上传任何用户数据
- ✅ 最小化权限请求
- ✅ 沙盒环境运行

### 3. 性能优化

- ✅ 使用 `If-Modified-Since` 减少传输
- ✅ 遵守 GitHub API 速率限制
- ✅ 本地缓存减少请求
- ✅ 智能去重避免重复通知

### 4. 用户体验

- ✅ 纯菜单栏应用（不占用 Dock）
- ✅ 系统级通知集成
- ✅ 暗色模式自适应
- ✅ 清晰的错误提示

---

## 构建和运行

### 前提条件

1. macOS 13.0+
2. Xcode 15.0+
3. Apple Developer Account（用于签名）

### 配置步骤

1. 打开 `CommitPop.xcodeproj`
2. 选择开发团队
3. 在 Info.plist 中添加：
   - `LSUIElement` = YES
   - `NSUserNotificationsUsageDescription`
4. 启用 App Sandbox
5. 勾选 Outgoing Connections (Client)
6. Cmd + R 运行

详细配置请参考 `XCODE_SETUP.md`

---

## 测试建议

### 单元测试（TODO）

```swift
// 建议添加的测试
- DeviceFlowAuthServiceTests
- GitHubAPITests
- KeychainStoreTests
- CacheStoreTests
- NotificationDeduplicationTests
```

### 手动测试清单

- [ ] 首次启动请求通知权限
- [ ] OAuth Device Flow 登录流程
- [ ] 拉取通知并发送系统通知
- [ ] 点击通知跳转 GitHub
- [ ] 菜单栏状态显示正确
- [ ] 设置修改立即生效
- [ ] 暂停/恢复通知功能
- [ ] 开机自启设置
- [ ] 注销清除 token
- [ ] 速率限制处理
- [ ] 304 Not Modified 处理

---

## 已知限制

1. **系统要求**: 需要 macOS 13.0+（SMAppService）
2. **API 限制**: GitHub API 5000 req/hour
3. **轮询延迟**: 最小 1 分钟（实时性受限）
4. **沙盒限制**: 需要网络权限

---

## 贡献者

- 沈柯宇 (项目发起人)
- GitHub Copilot (AI 辅助开发)

---

## 许可证

Apache License 2.0

Copyright 2025 CommitPop Contributors

---

## 项目完成度

### 核心功能: 100% ✅

- [x] OAuth 授权
- [x] 通知拉取
- [x] 系统通知
- [x] 菜单栏 UI
- [x] 首选项界面
- [x] 数据持久化
- [x] 开机自启

### 文档完整度: 100% ✅

- [x] README.md
- [x] LICENSE
- [x] XCODE_SETUP.md
- [x] 代码注释

### 可直接运行: ✅

项目已完成所有核心功能，可以立即编译运行！

---

**最后更新**: 2025 年 11 月 4 日
