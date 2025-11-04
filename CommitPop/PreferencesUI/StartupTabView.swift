//
//  StartupTabView.swift
//  CommitPop
//
//  启动项设置 Tab
//

import SwiftUI
import ServiceManagement

struct StartupTabView: View {
    
    @StateObject private var settingsStore = SettingsStore.shared
    @State private var launchAtLoginStatus: String = "未知"
    
    var body: some View {
        Form {
            Section(header: Text("登录时启动").font(.headline)) {
                Toggle("开机自动启动 CommitPop", isOn: $settingsStore.launchAtLogin)
                    .help("在登录 macOS 时自动启动 CommitPop")
                
                Text("当前状态: \(launchAtLoginStatus)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if #available(macOS 13.0, *) {
                    Text("使用 macOS 13+ 的 SMAppService 实现")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("⚠️ 开机自启需要 macOS 13.0 或更高版本")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            
            Section(header: Text("说明").font(.headline)) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("• 启用后，CommitPop 将在您登录 macOS 时自动启动")
                    Text("• 应用将在后台运行，不会显示主窗口")
                    Text("• 您可以随时从菜单栏访问 CommitPop")
                    Text("• 关闭此选项不会影响当前运行的应用")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Section {
                Button(action: checkStatus) {
                    Label("检查当前状态", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear {
            checkStatus()
        }
    }
    
    // MARK: - Actions
    
    private func checkStatus() {
        if #available(macOS 13.0, *) {
            let service = SMAppService.mainApp
            switch service.status {
            case .enabled:
                launchAtLoginStatus = "已启用"
            case .notRegistered:
                launchAtLoginStatus = "未注册"
            case .notFound:
                launchAtLoginStatus = "未找到"
            case .requiresApproval:
                launchAtLoginStatus = "需要批准"
            @unknown default:
                launchAtLoginStatus = "未知"
            }
        } else {
            launchAtLoginStatus = "不支持（需要 macOS 13+）"
        }
    }
}

#Preview {
    StartupTabView()
        .frame(width: 600, height: 500)
}
