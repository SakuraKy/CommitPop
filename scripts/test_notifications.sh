#!/bin/bash

# 测试脚本：验证 CommitPop 通知功能

echo "=== CommitPop 通知功能测试 ==="
echo ""

# 1. 检查应用是否运行
if pgrep -x "CommitPop" > /dev/null; then
    echo "✅ CommitPop 正在运行"
    PID=$(pgrep -x "CommitPop")
    echo "   进程 PID: $PID"
else
    echo "❌ CommitPop 未运行"
    exit 1
fi

echo ""
echo "=== 最近 30 秒的同步日志 ==="
log show --predicate 'subsystem == "com.sakuraky.CommitPop" AND category == "PollingScheduler"' \
    --last 30s --info --debug 2>/dev/null | \
    grep -E "同步|处理通知|最近事件|recentThreads" | tail -n 20

echo ""
echo "=== 请在 CommitPop 菜单栏图标上点击，查看'最近事件'部分 ==="
echo ""
echo "💡 提示："
echo "1. 如果'最近事件'仍然显示旧数据，可能是菜单刷新问题"
echo "2. 如果没有通知弹窗，是因为 GitHub 上的通知都是已读状态"
echo "3. 去 GitHub 创建一个新 Issue 来测试通知功能"
