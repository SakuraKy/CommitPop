//
//  GeneralTabView.swift
//  CommitPop
//
//  登录设置 Tab
//

import SwiftUI

struct GeneralTabView: View {
    
    @StateObject private var authService = DeviceFlowAuthService()
    @StateObject private var settingsStore = SettingsStore.shared
    @State private var accountInfo: AccountModel?
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 登录状态
                GroupBox(label: Label("登录状态", systemImage: "person.circle")) {
                    VStack(alignment: .leading, spacing: 12) {
                        if let account = accountInfo {
                            HStack {
                                Text("已登录为:")
                                    .foregroundColor(.secondary)
                                Text(account.login)
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                            
                            if let name = account.name {
                                HStack {
                                    Text("用户名:")
                                        .foregroundColor(.secondary)
                                    Text(name)
                                    Spacer()
                                }
                            }
                            
                            Button(action: logout) {
                                Label("注销并清除令牌", systemImage: "rectangle.portrait.and.arrow.right")
                            }
                            .buttonStyle(.bordered)
                            .tint(.red)
                            
                        } else {
                            Text("未登录")
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                }
                
                // GitHub OAuth 设置
                GroupBox(label: Label("GitHub OAuth 设置", systemImage: "key.fill")) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("请在 GitHub 开发者设置中创建 OAuth App 并开启 Device Flow")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Text("Client ID:")
                            TextField("输入 Client ID", text: $settingsStore.githubClientID)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        Button(action: openGitHubSettings) {
                            Label("打开 GitHub 开发者设置", systemImage: "link")
                        }
                        .buttonStyle(.link)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                }
                
                // 设备码登录
                if accountInfo == nil {
                    GroupBox(label: Label("设备码登录", systemImage: "device.laptop")) {
                        VStack(alignment: .leading, spacing: 12) {
                            if authService.isAuthenticating {
                                if let deviceCode = authService.deviceCode {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("请在浏览器中打开以下页面并输入代码：")
                                            .font(.caption)
                                        
                                        HStack {
                                            Text(deviceCode.userCode)
                                                .font(.system(.title2, design: .monospaced))
                                                .fontWeight(.bold)
                                                .foregroundColor(.blue)
                                            
                                            Button(action: {
                                                NSPasteboard.general.clearContents()
                                                NSPasteboard.general.setString(deviceCode.userCode, forType: .string)
                                            }) {
                                                Image(systemName: "doc.on.doc")
                                            }
                                            .buttonStyle(.borderless)
                                            .help("复制代码")
                                        }
                                        
                                        Button(action: {
                                            OpenURL.openGitHubDeviceVerification()
                                        }) {
                                            Label("打开验证页面", systemImage: "arrow.up.right.square")
                                        }
                                        .buttonStyle(.bordered)
                                        
                                        Text("等待授权中...")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        ProgressView()
                                            .progressViewStyle(.linear)
                                        
                                        Button(action: {
                                            authService.cancelAuth()
                                        }) {
                                            Text("取消")
                                        }
                                        .buttonStyle(.bordered)
                                    }
                                } else {
                                    ProgressView()
                                }
                            } else {
                                Button(action: startDeviceFlow) {
                                    Label("开始设备码登录", systemImage: "arrow.right.circle")
                                }
                                .buttonStyle(.borderedProminent)
                                .disabled(settingsStore.githubClientID.isEmpty)
                            }
                            
                            if let error = authService.authError {
                                Text("错误: \(error.localizedDescription)")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                            
                            if let error = errorMessage {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .onAppear {
            checkLoginStatus()
        }
    }
    
    // MARK: - Actions
    
    private func startDeviceFlow() {
        errorMessage = nil
        
        guard !settingsStore.githubClientID.isEmpty else {
            errorMessage = "请先输入 Client ID"
            return
        }
        
        Task {
            do {
                let deviceCode = try await authService.startDeviceFlow(
                    clientID: settingsStore.githubClientID
                )
                
                // 开始轮询
                authService.startPollingForAccessToken(clientID: settingsStore.githubClientID)
                
                // 监听登录成功
                NotificationCenter.default.addObserver(
                    forName: Constants.NotificationNames.userDidLogin,
                    object: nil,
                    queue: .main
                ) { _ in
                    checkLoginStatus()
                }
                
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func logout() {
        do {
            try authService.logout()
            accountInfo = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func checkLoginStatus() {
        guard KeychainStore.shared.hasAccessToken() else {
            accountInfo = nil
            return
        }
        
        isLoading = true
        Task {
            do {
                let account = try await GitHubAPI.shared.getCurrentUser()
                accountInfo = account
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
    
    private func openGitHubSettings() {
        OpenURL.open("https://github.com/settings/developers")
    }
}

#Preview {
    GeneralTabView()
        .frame(width: 600, height: 500)
}
