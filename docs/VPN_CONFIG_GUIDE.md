# Hiddify VPN 分流配置指南

## 问题背景

CommitPop应用在使用Hiddify VPN时,GitHub API请求失败(DNS解析失败)。需要配置VPN分流规则,让GitHub相关域名直接连接,不走代理。

## 方案1: Hiddify GUI配置 (推荐)

### 步骤:

1. **打开Hiddify应用**

2. **进入设置/配置页面**
   - 点击菜单栏图标
   - 选择 "设置" 或 "Preferences"

3. **找到路由/规则设置**
   - 查找 "路由规则" / "Routing Rules" / "Route"
   - 或者 "配置" / "Config" 选项

4. **添加直连规则**
   
   在规则列表中添加以下域名规则(选择"直连"/"DIRECT"模式):
   ```
   api.github.com          → DIRECT
   github.com              → DIRECT
   *.github.com            → DIRECT
   githubusercontent.com    → DIRECT
   *.githubusercontent.com → DIRECT
   ```

5. **保存并重启VPN连接**

---

## 方案2: 修改配置文件 (高级)

如果Hiddify使用sing-box核心,配置文件位置:
```
/Users/shenkeyu/Library/Group Containers/group.apple.hiddify.com/Library/Caches/Working/configs/
```

### Sing-box配置格式:

在配置文件中添加 `route` 部分:

```json
{
  "route": {
    "rules": [
      {
        "domain": [
          "api.github.com",
          "github.com"
        ],
        "domain_suffix": [
          ".github.com",
          ".githubusercontent.com"
        ],
        "outbound": "direct"
      }
    ],
    "final": "节点选择"
  },
  "outbounds": [
    {
      "type": "direct",
      "tag": "direct"
    },
    // ... 其他节点配置
  ]
}
```

**⚠️ 注意:** 
- 直接修改配置文件可能在VPN更新配置时被覆盖
- 建议在Hiddify GUI中配置更持久

---

## 方案3: 使用Clash Verge Rev (备选)

您的系统中也安装了Clash Verge Rev,可以切换使用:

### Clash配置位置:
```
/Users/shenkeyu/Library/Application Support/io.github.clash-verge-rev.clash-verge-rev/
```

### 在Clash中添加规则:

1. **打开Clash Verge Rev**

2. **进入配置页面** → "规则" / "Rules"

3. **添加以下规则**(在规则列表顶部):

```yaml
# GitHub直连规则
- DOMAIN,api.github.com,DIRECT
- DOMAIN,github.com,DIRECT
- DOMAIN-SUFFIX,github.com,DIRECT
- DOMAIN-SUFFIX,githubusercontent.com,DIRECT
```

4. **保存并重新加载配置**

---

## 验证配置是否生效

### 1. 检查DNS解析

在VPN连接状态下:

```bash
# 应该看到使用系统DNS或本地DNS,而非VPN DNS
scutil --dns | head -20
```

期望结果:不应该看到 `172.19.0.2` 作为第一DNS服务器

### 2. 测试GitHub连接

```bash
# 应该显示较低的延迟(直连)
ping api.github.com

# 检查使用的IP地址
curl -v https://api.github.com 2>&1 | grep "Trying"
```

### 3. 运行CommitPop并查看日志

```bash
# 清理旧日志
sudo log erase --all

# 启动应用
open /Users/shenkeyu/Documents/CommitPop/build/Build/Products/Debug/CommitPop.app

# 等待10秒,查看日志
sleep 10
log show --predicate 'subsystem == "com.sakuraky.CommitPop"' \
  --last 30s --style compact --info --debug | \
  grep -E "(API|同步|✅|❌)"
```

**成功的标志:**
```
✅ API响应成功，获取到 X 条通知
✅ 同步完成
```

**失败的标志:**
```
❌ 网络错误: A server with the specified hostname could not be found
```

---

## 推荐的分流策略

### 完整的GitHub相关域名列表:

```
# 核心域名
api.github.com
github.com
*.github.com

# CDN和资源
githubusercontent.com
*.githubusercontent.com
github.githubassets.com
*.githubassets.com

# 其他服务
githubstatus.com
github.io
*.github.io
```

### 为什么要配置分流?

1. **提高访问速度**: GitHub在国内直连通常比走代理更快
2. **避免DNS问题**: 某些VPN的DNS配置可能导致URLSession无法解析
3. **节省流量**: 不占用VPN流量配额
4. **提高稳定性**: 避免VPN断线影响GitHub访问

---

## 临时解决方案(测试用)

如果无法立即配置分流,可以临时断开VPN测试:

```bash
# 查看VPN连接
scutil --nc list

# 断开VPN(在Hiddify/Clash客户端中操作)
# 或者完全退出VPN客户端
```

---

## 故障排除

### 配置后仍然无法连接?

1. **完全重启VPN客户端**
   ```bash
   # 退出Hiddify
   # 等待5秒
   # 重新打开Hiddify并连接
   ```

2. **清除DNS缓存**
   ```bash
   sudo dscacheutil -flushcache
   sudo killall -HUP mDNSResponder
   ```

3. **检查规则优先级**
   - 确保GitHub规则在规则列表**顶部**
   - 规则是从上到下匹配的

4. **尝试不同的规则类型**
   - `DOMAIN`: 精确匹配域名
   - `DOMAIN-SUFFIX`: 匹配域名后缀
   - `DOMAIN-KEYWORD`: 匹配包含关键词的域名

---

## 联系支持

如果以上方法都无效:

1. **查看Hiddify文档**: https://hiddify.com/
2. **Clash文档**: https://clash.wiki/
3. **Sing-box文档**: https://sing-box.sagernet.org/

---

**创建时间:** 2025-11-05  
**适用版本:** Hiddify (任意版本), Clash Verge Rev  
**配置核心:** sing-box / clash
