//
//  AllEventsView.swift
//  CommitPop
//
//  显示所有 GitHub 通知事件
//

import SwiftUI

struct AllEventsView: View {

    @ObservedObject var scheduler: PollingScheduler
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            // 顶部工具栏 - 标题居中，刷新按钮在右侧
            HStack {
                Spacer()

                Text("全部事件")
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                Button(action: refreshEvents) {
                    Label("刷新", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
                .disabled(isLoading)
            }
            .padding()

            Divider()

            // 事件列表
            if isLoading {
                VStack {
                    Spacer()
                    ProgressView("加载中...")
                    Spacer()
                }
            } else if let error = errorMessage {
                VStack {
                    Spacer()
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)
                    Text(error)
                        .foregroundColor(.secondary)
                        .padding()
                    Button("重试", action: refreshEvents)
                        .buttonStyle(.bordered)
                    Spacer()
                }
            } else if scheduler.recentThreads.isEmpty {
                VStack {
                    Spacer()
                    Image(systemName: "tray")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("没有事件")
                        .foregroundColor(.secondary)
                        .padding()
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(scheduler.recentThreads, id: \.id) { thread in
                            EventRowView(thread: thread)
                            Divider()
                        }
                    }
                }
            }
        }
        .frame(minWidth: 600, minHeight: 400)
        .onAppear {
            if scheduler.recentThreads.isEmpty {
                refreshEvents()
            }
        }
    }

    private func refreshEvents() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                await scheduler.syncNow()
                await MainActor.run {
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "加载失败: \(error.localizedDescription)"
                }
            }
        }
    }
}

/// 单个事件行视图
struct EventRowView: View {

    let thread: GitHubNotificationThread

    var body: some View {
        Button(action: openThread) {
            HStack(alignment: .top, spacing: 12) {
                // 未读/已读指示器
                Circle()
                    .fill(thread.unread ? Color.blue : Color.clear)
                    .frame(width: 8, height: 8)
                    .padding(.top, 6)

                VStack(alignment: .leading, spacing: 6) {
                    // 标题
                    Text(thread.subject.title)
                        .font(.body)
                        .fontWeight(thread.unread ? .semibold : .regular)
                        .foregroundColor(.primary)
                        .lineLimit(2)

                    // 仓库名称
                    Text(thread.repository.fullName)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    // 时间和状态
                    HStack(spacing: 8) {
                        // 时间
                        if let date = parseISO8601Date(thread.updatedAt) {
                            Text(formatRelativeDate(date))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        // 状态标签
                        HStack(spacing: 4) {
                            Image(systemName: thread.unread ? "envelope.badge" : "envelope.open")
                                .font(.caption2)
                            Text(thread.unread ? "未读" : "已读")
                                .font(.caption2)
                        }
                        .foregroundColor(thread.unread ? .blue : .secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    thread.unread
                                        ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                        )

                        // 事件类型
                        Text(reasonText(thread.reason))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.gray.opacity(0.1))
                            )
                    }
                }

                Spacer()

                // 右侧箭头
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(
            Color.clear
                .contentShape(Rectangle())
        )
        .onHover { hovering in
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }

    private func openThread() {
        var urlString: String?
        if let commentUrl = thread.subject.latestCommentUrl {
            urlString = convertAPIUrlToHtml(commentUrl)
        } else if let subjectUrl = thread.subject.url {
            urlString = convertAPIUrlToHtml(subjectUrl)
        }

        if let urlString = urlString, let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }

    private func convertAPIUrlToHtml(_ apiUrl: String) -> String {
        return
            apiUrl
            .replacingOccurrences(of: "https://api.github.com/repos/", with: "https://github.com/")
            .replacingOccurrences(of: "/pulls/", with: "/pull/")
            .replacingOccurrences(of: "/issues/", with: "/issues/")
    }

    private func parseISO8601Date(_ dateString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: dateString)
            ?? {
                formatter.formatOptions = [.withInternetDateTime]
                return formatter.date(from: dateString)
            }()
    }

    private func formatRelativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func reasonText(_ reason: String) -> String {
        switch reason {
        case "assign":
            return "被指派"
        case "author":
            return "你创建的"
        case "comment":
            return "有评论"
        case "invitation":
            return "邀请"
        case "manual":
            return "手动订阅"
        case "mention":
            return "被提及"
        case "review_requested":
            return "请求评审"
        case "security_alert":
            return "安全警报"
        case "state_change":
            return "状态变更"
        case "subscribed":
            return "已订阅"
        case "team_mention":
            return "团队提及"
        default:
            return reason
        }
    }
}

#Preview {
    AllEventsView(scheduler: PollingScheduler())
}
