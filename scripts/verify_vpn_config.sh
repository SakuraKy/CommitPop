#!/bin/bash

# CommitPop VPN配置验证脚本
# 用于检查GitHub API是否可以正常访问

set -e

echo "🔍 CommitPop - VPN配置验证"
echo "================================"
echo ""

# 1. 检查DNS配置
echo "1️⃣  检查DNS配置..."
DNS_INFO=$(scutil --dns | head -10)
echo "$DNS_INFO"
if echo "$DNS_INFO" | grep -q "172.19.0.2"; then
    echo "⚠️  警告: 检测到VPN DNS (172.19.0.2)"
    echo "   如果GitHub访问失败,请配置分流规则"
else
    echo "✅ DNS配置正常"
fi
echo ""

# 2. 测试ping
echo "2️⃣  测试ping api.github.com..."
if ping -c 2 api.github.com > /dev/null 2>&1; then
    PING_TIME=$(ping -c 1 api.github.com | grep "time=" | awk -F'time=' '{print $2}' | awk '{print $1}')
    echo "✅ Ping成功: ${PING_TIME}ms"
else
    echo "❌ Ping失败"
fi
echo ""

# 3. 测试DNS解析
echo "3️⃣  测试DNS解析..."
IP=$(nslookup api.github.com | grep "Address" | tail -1 | awk '{print $2}')
if [ ! -z "$IP" ]; then
    echo "✅ DNS解析成功: $IP"
else
    echo "❌ DNS解析失败"
fi
echo ""

# 4. 测试HTTP连接
echo "4️⃣  测试HTTP连接..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://api.github.com --max-time 5)
if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "304" ]; then
    echo "✅ HTTP连接成功: $HTTP_CODE"
else
    echo "❌ HTTP连接失败: $HTTP_CODE"
fi
echo ""

# 5. 检查VPN状态
echo "5️⃣  检查VPN连接状态..."
VPN_LIST=$(scutil --nc list | grep "Connected")
if [ ! -z "$VPN_LIST" ]; then
    echo "🔗 VPN已连接:"
    echo "$VPN_LIST"
else
    echo "⚪ 未检测到VPN连接"
fi
echo ""

# 6. 测试CommitPop应用
echo "6️⃣  测试CommitPop应用..."
if [ -f "/Users/shenkeyu/Documents/CommitPop/build/Build/Products/Debug/CommitPop.app/Contents/MacOS/CommitPop" ]; then
    echo "✅ 应用已构建"
    
    # 检查是否在运行
    if pgrep -x "CommitPop" > /dev/null; then
        echo "🟢 应用正在运行"
        
        # 查看最近的日志
        echo ""
        echo "📋 最近的应用日志:"
        log show --predicate 'subsystem == "com.sakuraky.CommitPop"' \
          --last 1m --style compact --info --debug 2>/dev/null | \
          grep -E "(同步|API|✅|❌)" | tail -5 || echo "   (暂无日志)"
    else
        echo "⚪ 应用未运行"
        echo "   可以运行: open /Users/shenkeyu/Documents/CommitPop/build/Build/Products/Debug/CommitPop.app"
    fi
else
    echo "⚠️  应用未构建"
    echo "   请先运行: cd /Users/shenkeyu/Documents/CommitPop && xcodebuild -scheme CommitPop -configuration Debug -derivedDataPath ./build"
fi
echo ""

# 总结
echo "================================"
echo "✨ 验证完成!"
echo ""
echo "📚 下一步:"
echo "   1. 如果DNS显示VPN地址(172.19.0.2),请配置分流规则"
echo "   2. 配置完成后,重启VPN并重新运行此脚本验证"
echo "   3. 查看详细配置指南: cat VPN_CONFIG_GUIDE.md"
echo ""
