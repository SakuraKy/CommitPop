//
//  AdvancedTabView.swift
//  CommitPop
//
//  高级设置 Tab
//

import SwiftUI

struct AdvancedTabView: View {
    
    @ObservedObject private var settingsStore = SettingsStore.shared
    @State private var showingClearCacheAlert = false
    @State private var showingExportSheet = false
    @State private var exportedData: String = ""
    @State private var statusMessage: String?
    
    var body: some View {
        Form {
            Section(header: Text("仓库选择").font(.headline)) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("选定监控的仓库（未来功能）")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if settingsStore.selectedRepositories.isEmpty {
                        Text("当前监控所有仓库")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(settingsStore.selectedRepositories, id: \.self) { repo in
                            Text("• \(repo)")
                                .font(.caption)
                        }
                    }
                }
            }
            
            Section(header: Text("缓存管理").font(.headline)) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("缓存信息:")
                            .foregroundColor(.secondary)
                        Spacer()
                        if let lastSync = CacheStore.shared.getLastSyncDate() {
                            Text(DateISO8601.relativeString(from: lastSync))
                                .font(.caption)
                        } else {
                            Text("无缓存")
                                .font(.caption)
                        }
                    }
                    
                    HStack(spacing: 12) {
                        Button(action: exportCache) {
                            Label("导出缓存", systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(.bordered)
                        
                        Button(role: .destructive, action: {
                            showingClearCacheAlert = true
                        }) {
                            Label("清除缓存", systemImage: "trash")
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            
            Section(header: Text("调试").font(.headline)) {
                Button(action: printDebugInfo) {
                    Label("打印调试信息", systemImage: "ladybug")
                }
                .buttonStyle(.bordered)
            }
            
            Section(header: Text("关于").font(.headline)) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("版本:")
                        Text(Constants.appVersion)
                            .foregroundColor(.secondary)
                    }
                    
                    Button(action: openGitHub) {
                        Label("GitHub 仓库", systemImage: "link")
                    }
                    .buttonStyle(.link)
                    
                    Text("开源协议: Apache License 2.0")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if let message = statusMessage {
                Section {
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .alert("确认清除缓存", isPresented: $showingClearCacheAlert) {
            Button("取消", role: .cancel) { }
            Button("清除", role: .destructive, action: clearCache)
        } message: {
            Text("这将清除所有本地缓存数据，包括 Last-Modified 和线程去重信息。此操作不可撤销。")
        }
        .sheet(isPresented: $showingExportSheet) {
            VStack(spacing: 16) {
                Text("导出的缓存数据")
                    .font(.headline)
                
                TextEditor(text: .constant(exportedData))
                    .font(.system(.caption, design: .monospaced))
                    .frame(height: 300)
                    .border(Color.gray.opacity(0.3))
                
                HStack {
                    Button("关闭") {
                        showingExportSheet = false
                    }
                    .buttonStyle(.bordered)
                    
                    Button("复制") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(exportedData, forType: .string)
                        statusMessage = "已复制到剪贴板"
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .frame(width: 500, height: 400)
        }
    }
    
    // MARK: - Actions
    
    private func exportCache() {
        if let data = CacheStore.shared.exportCache() {
            exportedData = data
            showingExportSheet = true
        } else {
            statusMessage = "导出失败"
        }
    }
    
    private func clearCache() {
        CacheStore.shared.clearAllCache()
        statusMessage = "缓存已清除"
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            statusMessage = nil
        }
    }
    
    private func printDebugInfo() {
        print("=== CommitPop Debug Info ===")
        print("Version: \(Constants.appVersion)")
        print("Has Token: \(KeychainStore.shared.hasAccessToken())")
        print("Polling Interval: \(settingsStore.pollingInterval) min")
        print("Participating Only: \(settingsStore.participatingOnly)")
        print("Notifications Paused: \(settingsStore.notificationsPaused)")
        
        if let lastSync = CacheStore.shared.getLastSyncDate() {
            print("Last Sync: \(lastSync)")
        } else {
            print("Last Sync: Never")
        }
        
        if let lastModified = CacheStore.shared.getLastModified() {
            print("Last-Modified: \(lastModified)")
        } else {
            print("Last-Modified: None")
        }
        
        print("===========================")
        
        statusMessage = "调试信息已打印到控制台"
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            statusMessage = nil
        }
    }
    
    private func openGitHub() {
        OpenURL.open("https://github.com/yourusername/CommitPop")
    }
}

#Preview {
    AdvancedTabView()
        .frame(width: 600, height: 500)
}
