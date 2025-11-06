# CommitPop - 故障排除指南

## DNS解析失败问题 (NSURLErrorDomain Code=-1003)

### 问题描述

应用在使用VPN(如Hiddify)时,GitHub API请求失败,错误信息:
```
A server with the specified hostname could not be found.
Resolved 0 endpoints in 0ms using unknown from query
interface: utun6
```

### 根本原因

VPN客户端的DNS配置干扰了URLSession的DNS解析:
- VPN DNS服务器: `172.19.0.2`
- VPN接口: `utun6`
- URLSession无法通过VPN的DNS解析域名(尽管系统命令如ping/curl可以)

### 解决方案

#### 方案1: 临时关闭VPN (推荐用于测试)

```bash
# 查看VPN连接状态
scutil --nc list

# 如果使用Hiddify,在Hiddify客户端中暂时断开连接
```

#### 方案2: 配置VPN分流规则 (推荐用于生产)

在VPN客户端(如Hiddify/Clash/Surge)中配置规则,让以下域名直连:
- `api.github.com`
- `github.com`
- `*.github.com`

**Hiddify配置示例:**
```yaml
rules:
  - DOMAIN,api.github.com,DIRECT
  - DOMAIN-SUFFIX,github.com,DIRECT
```

**Clash配置示例:**
```yaml
rules:
  - DOMAIN,api.github.com,DIRECT
  - DOMAIN-SUFFIX,github.com,DIRECT
```

#### 方案3: 修改系统DNS (不推荐)

```bash
# 临时使用公共DNS
networksetup -setdnsservers Wi-Fi 8.8.8.8 1.1.1.1

# 恢复自动DNS
networksetup -setdnsservers Wi-Fi empty
```

### 验证修复

1. 关闭VPN或配置分流后,重新构建并运行应用:
   ```bash
   cd /Users/shenkeyu/Documents/CommitPop
   xcodebuild -scheme CommitPop -configuration Debug -derivedDataPath ./build
   open ./build/Build/Products/Debug/CommitPop.app
   ```

2. 查看系统日志确认请求成功:
   ```bash
   log show --predicate 'subsystem == "com.sakuraky.CommitPop"' \
     --last 30s --style compact --info --debug | \
     grep -E "(同步|API|✅)"
   ```

3. 应该看到类似的成功日志:
   ```
   ✅ API响应成功，获取到 X 条通知
   ✅ 同步完成 - 总通知数: X
   ```

### 技术细节

**为什么curl/ping可以工作但URLSession不行?**

- `curl`和`ping`使用系统的DNS解析器(getaddrinfo),可以正确处理VPN的DNS
- `URLSession`使用底层的Network.framework,在某些VPN配置下可能无法正确解析DNS
- 错误信息中的"using unknown from query"表明DNS查询方式不被支持

**相关错误代码:**
- `NSURLErrorDomain Code=-1003`: Cannot Find Host
- `kCFErrorDomainCFNetwork Code=-1003`: DNS Lookup Failed
- `_kCFStreamErrorCodeKey=-72000`: DNS Query Failed

### 日志分析

**正常工作的DNS配置:**
```bash
$ scutil --dns
resolver #1
  nameserver[0] : 8.8.8.8
  flags    : Request A records
  reach    : 0x00000002 (Reachable)
```

**有问题的VPN DNS配置:**
```bash
$ scutil --dns
resolver #1
  nameserver[0] : 172.19.0.2
  if_index : 25 (utun6)  # ← VPN接口
  flags    : Request A records
  reach    : 0x00000002 (Reachable)
```

### 相关资源

- [Apple URLSession文档](https://developer.apple.com/documentation/foundation/urlsession)
- [Network.framework DNS解析](https://developer.apple.com/documentation/network)
- [Hiddify文档](https://hiddify.com)

---

**最后更新:** 2025-11-05
**问题状态:** 已定位 - VPN DNS配置问题
