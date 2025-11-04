//
//  NotificationsTabView.swift
//  CommitPop
//
//  通知设置 Tab
//

import SwiftUI

struct NotificationsTabView: View {
    
    @StateObject private var settingsStore = SettingsStore.shared
    
    var body: some View {
        Form {
            Section(header: Text("通知范围").font(.headline)) {
                Toggle("仅参与的通知", isOn: $settingsStore.participatingOnly)
                    .help("只接收我参与的会话通知（@提及、评论等）")
                
                Text("如果关闭，将接收所有仓库的通知（可能会很多）")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section(header: Text("轮询设置").font(.headline)) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("轮询间隔:")
                        Spacer()
                        Text("\(settingsStore.pollingInterval) 分钟")
                            .foregroundColor(.secondary)
                    }
                    
                    Slider(
                        value: Binding(
                            get: { Double(settingsStore.pollingInterval) },
                            set: { settingsStore.pollingInterval = Int($0) }
                        ),
                        in: Double(Constants.Defaults.minPollingInterval)...Double(Constants.Defaults.maxPollingInterval),
                        step: 1
                    )
                    
                    Text("建议间隔：5-10 分钟，避免频繁请求")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Section(header: Text("通知选项").font(.headline)) {
                Toggle("启用通知声音", isOn: $settingsStore.notificationSoundEnabled)
                    .help("通知到达时播放系统声音")
                
                Toggle("暂停通知", isOn: $settingsStore.notificationsPaused)
                    .help("暂时停止发送通知（后台仍会同步）")
            }
            
            Section(header: Text("测试").font(.headline)) {
                Button(action: sendTestNotification) {
                    Label("发送测试通知", systemImage: "bell.badge")
                }
                .buttonStyle(.bordered)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
    
    // MARK: - Actions
    
    private func sendTestNotification() {
        Task {
            await NotificationCenterManager.shared.sendNotification(
                title: "CommitPop 测试通知",
                body: "这是一条测试通知，用于验证通知功能是否正常工作。",
                identifier: "test_notification_\(UUID().uuidString)",
                soundEnabled: settingsStore.notificationSoundEnabled
            )
        }
    }
}

#Preview {
    NotificationsTabView()
        .frame(width: 600, height: 500)
}
