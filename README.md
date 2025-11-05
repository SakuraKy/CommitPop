<div align="center">

<img src="Resources/icon.png" width="128" height="128" alt="CommitPop Icon">

# CommitPop

A macOS menu bar app that monitors GitHub notifications in real-time using system notifications

Stay stealthily updated on GitHub activities during work, class, or other critical moments

[![license](https://img.shields.io/badge/license-Apache%202.0-blue)](LICENSE)
[![release](https://img.shields.io/badge/release-v1.0-brightgreen)](https://github.com/SakuraKy/CommitPop/releases)
[![platform](https://img.shields.io/badge/platform-macOS%2013%2B-lightgrey)](https://www.apple.com/macos)
[![Email](https://img.shields.io/badge/Email-sakuraky.shen%40gmail.com-red?style=flat-square&logo=gmail&logoColor=white)](mailto:sakuraky.shen@gmail.com)

---

[English](README.md) | [简体中文](README_CN.md)

</div>

---

## ✨ Features

- ✅ **Fully Local** - No server required, all data processing happens locally
- 🔐 **Secure & Reliable** - Access tokens encrypted and stored in Keychain
- 🎯 **Smart Notifications** - Intelligent deduplication, only notifies what matters
- ⚡ **Performance Optimized** - Uses Last-Modified headers to reduce API calls, respects rate limits
- 🎨 **Native Experience** - Pure Swift with AppKit + SwiftUI, seamlessly integrated with macOS
- 🌙 **Dark Mode** - Automatically adapts to system theme
- 🔕 **Flexible Configuration** - Adjustable polling intervals (1-30 minutes), pause/resume notifications
- 🚀 **Launch at Login** - Supports macOS 13+ login items (optional)
- 📊 **Status Monitoring** - Menu bar displays login status, sync time, API quota
- 🔗 **Quick Access** - Click notifications to jump directly to GitHub pages

---

## 📦 Quick Start

### System Requirements

- macOS 13.0 or later
- Xcode 15.0+ (for building from source)
- Active internet connection

### Download & Install

#### Option 1: Download Pre-built Binary (Recommended)

Visit the [Releases](https://github.com/SakuraKy/CommitPop/releases) page to download the latest version.

#### Option 2: Build from Source

```bash
# Clone the repository
git clone https://github.com/SakuraKy/CommitPop.git
cd CommitPop

# Open with Xcode
open CommitPop.xcodeproj

# Press Cmd + R in Xcode to build and run
```

### First-Time Setup

1. **Launch the App** - On first launch, grant notification permissions when prompted
2. **Create OAuth App** - Visit [GitHub Developer Settings](https://github.com/settings/developers) to create an OAuth App
3. **Configure Client ID** - Paste your Client ID in the app preferences
4. **Device Flow Login** - Follow the instructions to authorize in your browser
5. **Start Using** - The app will automatically start monitoring and sending notifications

For detailed configuration steps, see [User Guide](#user-guide).

---

## 📖 User Guide

<details>
<summary><b>Create GitHub OAuth App</b></summary>

CommitPop uses OAuth 2.0 Device Flow for authorization, which requires creating an OAuth App first.

1. Log in to GitHub and visit [Developer Settings](https://github.com/settings/developers)
2. Click **OAuth Apps** → **New OAuth App**
3. Fill in the application details:
   - Application name: `CommitPop`
   - Homepage URL: `https://github.com/SakuraKy/CommitPop`
   - Authorization callback URL: `http://localhost`
4. After creation, copy the **Client ID**

</details>

<details>
<summary><b>Initial Configuration</b></summary>

1. Launch CommitPop and grant notification permissions
2. Open Preferences (click menu bar icon → Open Preferences, or press `Cmd + ,`)
3. Paste your Client ID in the "Login" tab
4. Click "Start Device Flow Login"
5. Copy the displayed User Code and authorize in your browser
6. The app will automatically complete login and start syncing

</details>

<details>
<summary><b>Daily Usage</b></summary>

**Menu Bar Actions:**

- Sync Now - Manually trigger a sync
- Pause/Resume Notifications - Temporarily disable notifications
- Recent Events - Quick access to recent notifications
- Quit - Exit the application

**Preferences:**

- Login: View account, sign out
- Notifications: Adjust intervals, configure scope, test notifications
- Startup: Launch at login settings
- Advanced: Cache management, debug info

</details>

---

## 🔧 Technical Architecture

### Tech Stack

| Category       | Technology                   |
| -------------- | ---------------------------- |
| Language       | Swift 5.9+                   |
| UI Framework   | SwiftUI + AppKit             |
| Notifications  | UserNotifications            |
| Networking     | URLSession                   |
| Storage        | Keychain + UserDefaults      |
| Authorization  | GitHub OAuth 2.0 Device Flow |

### Project Structure

<details>
<summary>View Complete Directory Structure</summary>

```
CommitPop/
├── Auth/                        # Authorization module (OAuth + Keychain)
├── GitHub/                      # GitHub API module
├── Notifications/               # System notification module
├── Scheduler/                   # Polling scheduler
├── Persistence/                 # Data persistence
├── MenuBar/                     # Menu bar controller
├── PreferencesUI/               # Settings UI (SwiftUI)
└── Utils/                       # Utilities
```

</details>

### Key Implementation Details

- **OAuth Device Flow** - No browser callback needed, pure device code authorization
- **Last-Modified Optimization** - Uses HTTP conditional requests to reduce bandwidth
- **Smart Deduplication** - Based on thread.id + updatedAt timestamps
- **Rate Limit Handling** - Parses response headers, respects 5,000 req/hour limit
- **Secure Storage** - Tokens stored in Keychain with encryption

---

## 🛠️ Development Guide

### Environment Setup

For detailed Xcode configuration instructions, see [XCODE_SETUP.md](XCODE_SETUP.md).

### Debugging Tips

- **View Logs** - Xcode Console (with emoji prefixes for easy identification)
- **Test Notifications** - Preferences → Notifications → Send Test Notification
- **Print Debug Info** - Preferences → Advanced → Print Debug Info

### Common Issues

<details>
<summary>Why doesn't the app appear in the Dock?</summary>

CommitPop is configured as a menu bar-only app (`LSUIElement = YES`), so it won't show in the Dock.

</details>

<details>
<summary>How to configure Info.plist?</summary>

In Xcode Project Settings → Info, add:

- `Application is agent (UIElement)` = YES
- `NSUserNotificationsUsageDescription`

</details>

<details>
<summary>What permissions are required?</summary>

- Notification permissions (UserNotifications)
- Network permissions (App Sandbox - Outgoing Connections)

</details>

---

## 🤝 Contributing

Contributions of all kinds are welcome!

- 🐛 [Report Bugs](https://github.com/SakuraKy/CommitPop/issues/new?labels=bug)
- 💡 [Feature Requests](https://github.com/SakuraKy/CommitPop/issues/new?labels=enhancement)
- 📝 Submit Pull Requests
- ⭐ Star this project

### Contribution Steps

1. Fork this repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📋 Roadmap

- [ ] Support filtering specific repositories
- [ ] Support multiple account switching
- [ ] Add statistics dashboard
- [ ] GraphQL API support
- [ ] Internationalization (multi-language support)
- [ ] Custom notification rules
- [ ] Export notification history

---

## 📄 License

This project is licensed under the [Apache License 2.0](LICENSE).

---

## ⭐ Star History

If you find this project helpful, feel free to give it a Star ⭐

---

<div align="center">

**[⬆ Back to Top](#commitpop)**

Made with ❤️ for the GitHub community

</div>
