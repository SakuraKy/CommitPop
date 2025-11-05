<div align="center">

<img src="Resources/icon.png" width="128" height="128" alt="CommitPop Icon">

# CommitPop

这是一个利用 macOS 系统通知实时监控 GitHub 动态的软件

可以让你在工作、上课等恶劣环境下安全隐秘地接收 GitHub 通知

[![license](https://img.shields.io/badge/license-Apache%202.0-blue)](LICENSE)
[![release](https://img.shields.io/badge/release-v1.0-brightgreen)](https://github.com/SakuraKy/CommitPop/releases)
[![platform](https://img.shields.io/badge/platform-macOS%2013%2B-lightgrey)](https://www.apple.com/macos)
[![Email](https://img.shields.io/badge/Email-sakuraky.shen%40gmail.com-red?style=flat-square&logo=gmail&logoColor=white)](mailto:sakuraky.shen@gmail.com)

---

[English](README.md) | [简体中文](README_CN.md)

</div>

---

## ✨ 功能特性

- ✅ **纯本地运行** - 无需自建服务器，所有数据处理均在本地完成
- 🔐 **安全可靠** - 使用 Keychain 加密存储访问令牌，保护你的隐私
- 🎯 **精准通知** - 智能去重，只推送真正需要关注的更新
- ⚡ **性能优化** - 使用 Last-Modified 头减少 API 请求，遵守速率限制
- 🎨 **原生体验** - 纯 Swift 开发，使用 AppKit + SwiftUI，完美融入 macOS
- 🌙 **暗色模式** - 自动适配系统主题
- 🔕 **灵活配置** - 可调节轮询间隔（1-30 分钟），暂停/恢复通知
- 🚀 **开机自启** - 支持 macOS 13+ 登录项（可选）
- 📊 **状态监控** - 菜单栏显示登录状态、同步时间、API 配额
- 🔗 **快速访问** - 点击通知直达对应的 GitHub 页面

---

## 📦 快速开始

### 系统要求

- macOS 13.0 或更高版本
- Xcode 15.0+ (用于编译)
- 有效的网络连接

### 下载安装

#### 方式一：下载预编译版本（推荐）

前往 [Releases](https://github.com/SakuraKy/CommitPop/releases) 页面下载最新版本。

#### 方式二：从源代码编译

```bash
# 克隆仓库
git clone https://github.com/SakuraKy/CommitPop.git
cd CommitPop

# 使用 Xcode 打开项目
open CommitPop.xcodeproj

# 在 Xcode 中按 Cmd + R 编译运行
```

### 初次使用

1. **启动应用** - 首次启动时，系统会请求通知权限，请点击"允许"
2. **创建 OAuth App** - 访问 [GitHub Developer Settings](https://github.com/settings/developers) 创建 OAuth App
3. **配置 Client ID** - 在应用首选项中粘贴 Client ID
4. **设备码登录** - 按照提示在浏览器中完成授权
5. **开始使用** - 应用将自动开始监控并推送通知

详细配置步骤请参考 [使用指南](#使用指南)。

---

## 📖 使用指南

<details>
<summary><b>创建 GitHub OAuth App</b></summary>

CommitPop 使用 OAuth 2.0 Device Flow 进行授权，需要先创建一个 OAuth App。

1. 登录 GitHub，访问 [Developer Settings](https://github.com/settings/developers)
2. 点击 **OAuth Apps** → **New OAuth App**
3. 填写应用信息：
   - Application name: `CommitPop`
   - Homepage URL: `https://github.com/SakuraKy/CommitPop`
   - Authorization callback URL: `http://localhost`
4. 创建后，复制 **Client ID**

</details>

<details>
<summary><b>首次启动配置</b></summary>

1. 启动 CommitPop，允许通知权限
2. 打开首选项（点击菜单栏图标 → 打开首选项，或按 `Cmd + ,`）
3. 在"登录"标签页粘贴 Client ID
4. 点击"开始设备码登录"
5. 复制显示的 User Code，在浏览器中完成授权
6. 应用会自动完成登录并开始同步

</details>

<details>
<summary><b>日常使用</b></summary>

**菜单栏操作：**

- 立即同步 - 手动触发一次同步
- 暂停/恢复通知 - 临时关闭通知
- 最近事件 - 快速访问最近的通知
- 退出 - 退出应用

**首选项配置：**

- 登录：查看账户、注销
- 通知：调整间隔、配置范围、测试通知
- 启动项：开机自启设置
- 高级：缓存管理、调试信息

</details>

---

## 🔧 技术架构

### 技术栈

| 分类    | 技术                         |
| ------- | ---------------------------- |
| 语言    | Swift 5.9+                   |
| UI 框架 | SwiftUI + AppKit             |
| 通知    | UserNotifications            |
| 网络    | URLSession                   |
| 存储    | Keychain + UserDefaults      |
| 授权    | GitHub OAuth 2.0 Device Flow |

### 项目结构

<details>
<summary>查看完整目录结构</summary>

```
CommitPop/
├── Auth/                        # 授权模块（OAuth + Keychain）
├── GitHub/                      # GitHub API 模块
├── Notifications/               # 系统通知模块
├── Scheduler/                   # 定时调度器
├── Persistence/                 # 数据持久化
├── MenuBar/                     # 菜单栏控制
├── PreferencesUI/               # 设置界面（SwiftUI）
└── Utils/                       # 工具类
```

</details>

### 关键特性实现

- **OAuth Device Flow** - 无需浏览器回调，纯设备码授权
- **Last-Modified 优化** - 使用 HTTP 条件请求减少传输
- **智能去重** - 基于 thread.id + updatedAt 判断
- **速率限制处理** - 解析响应头，遵守 5,000 req/hour 限制
- **安全存储** - Token 存储于 Keychain，加密保护

---

## 🛠️ 开发指南

### 环境配置

详细的 Xcode 配置指南请参考 [XCODE_SETUP.md](XCODE_SETUP.md)。

### 调试技巧

- **查看日志** - Xcode Console（带 emoji 前缀便于识别）
- **测试通知** - 首选项 → 通知 → 发送测试通知
- **打印调试信息** - 首选项 → 高级 → 打印调试信息

### 常见问题

<details>
<summary>为什么应用不出现在 Dock？</summary>

CommitPop 配置为纯菜单栏应用（`LSUIElement = YES`），不会在 Dock 显示。

</details>

<details>
<summary>如何配置 Info.plist？</summary>

在 Xcode 项目设置 → Info 中添加：

- `Application is agent (UIElement)` = YES
- `NSUserNotificationsUsageDescription`

</details>

<details>
<summary>需要哪些权限？</summary>

- 通知权限（UserNotifications）
- 网络权限（App Sandbox - Outgoing Connections）

</details>

---

## 🤝 贡献

欢迎各种形式的贡献！

- 🐛 [报告 Bug](https://github.com/SakuraKy/CommitPop/issues/new?labels=bug)
- 💡 [功能建议](https://github.com/SakuraKy/CommitPop/issues/new?labels=enhancement)
- 📝 提交 Pull Request
- ⭐ Star 本项目

### 贡献步骤

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

---

## 📋 路线图

- [ ] 支持筛选特定仓库
- [ ] 支持多账户切换
- [ ] 添加统计仪表盘
- [ ] GraphQL API 支持
- [ ] 国际化（多语言支持）
- [ ] 自定义通知规则
- [ ] 导出通知历史

---

## 📄 许可证

本项目采用 [Apache License 2.0](LICENSE) 许可证。

---

## ⭐ Star History

如果觉得这个项目对你有帮助，欢迎 Star ⭐

---

<div align="center">

**[⬆ 回到顶部](#commitpop)**

Made with ❤️ for the GitHub community

</div>
