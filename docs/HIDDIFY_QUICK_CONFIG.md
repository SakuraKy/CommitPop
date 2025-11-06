# Hiddify 分流配置 - 快速操作指南

## 📱 Hiddify GUI 配置步骤 (推荐)

### 方法A: 使用路由规则编辑器

1. **打开Hiddify应用**
   - 点击菜单栏的Hiddify图标

2. **进入路由设置**
   - 点击 "路由" / "Route" / "Routing" 选项
   - 或者: 设置 → 高级设置 → 路由规则

3. **添加GitHub直连规则**
   
   找到规则编辑区域,添加以下内容:
   
   ```json
   {
     "rules": [
       {
         "domain": ["api.github.com", "github.com"],
         "domain_suffix": [".github.com", ".githubusercontent.com"],
         "outbound": "direct"
       }
     ]
   }
   ```

4. **保存并应用**
   - 点击"保存"或"应用"按钮
   - 重新连接VPN

### 方法B: 使用配置文件编辑器

1. **打开Hiddify**

2. **找到配置编辑**
   - 配置 → 编辑配置
   - 或者: 选中当前配置 → 编辑

3. **在配置中添加路由规则**
   
   如果配置文件中**没有** `route` 部分,在 `outbounds` 同级添加:
   
   ```json
   {
     "route": {
       "rules": [
         {
           "domain": ["api.github.com", "github.com"],
           "domain_suffix": [".github.com", ".githubusercontent.com"],
           "outbound": "direct"
         }
       ],
       "auto_detect_interface": true,
       "final": "节点选择"
     },
     "outbounds": [
       {
         "type": "direct",
         "tag": "direct"
       },
       // ... 其他节点
     ]
   }
   ```

4. **保存并重启连接**

---

## 🖥️ 命令行方法 (备用)

如果GUI无法配置,可以直接编辑配置文件:

```bash
# 1. 备份原配置
cp "/Users/shenkeyu/Library/Group Containers/group.apple.hiddify.com/Library/Caches/Working/configs/1c735f7d-5a81-4aba-8907-47b82783ec01.json" \
   "/Users/shenkeyu/Library/Group Containers/group.apple.hiddify.com/Library/Caches/Working/configs/1c735f7d-5a81-4aba-8907-47b82783ec01.json.backup"

# 2. 使用编辑器打开配置文件
open -e "/Users/shenkeyu/Library/Group Containers/group.apple.hiddify.com/Library/Caches/Working/configs/1c735f7d-5a81-4aba-8907-47b82783ec01.json"

# 3. 按照上面的方法B添加route部分

# 4. 保存后,在Hiddify中重新加载配置
```

---

## 🎯 更简单的方法: 使用域名分组

某些Hiddify版本支持更简单的UI配置:

1. **打开Hiddify** → **配置** → **当前配置**

2. **查找 "绕过规则" 或 "直连规则"**

3. **添加以下域名**:
   ```
   api.github.com
   github.com
   *.github.com
   *.githubusercontent.com
   ```

4. **选择动作**: "直连" / "DIRECT" / "绕过代理"

5. **保存并重新连接**

---

## ✅ 验证配置

配置完成后:

1. **断开VPN**
2. **等待3秒**
3. **重新连接VPN**
4. **运行验证脚本**:
   ```bash
   cd /Users/shenkeyu/Documents/CommitPop
   ./verify_vpn_config.sh
   ```

5. **查看CommitPop日志**:
   ```bash
   # 重启应用
   killall CommitPop
   open ./build/Build/Products/Debug/CommitPop.app
   
   # 10秒后查看日志
   sleep 10
   log show --predicate 'subsystem == "com.sakuraky.CommitPop"' \
     --last 30s --style compact --info | \
     grep "✅"
   ```

**期望看到**:
```
✅ API响应成功，获取到 X 条通知
✅ 同步完成
```

---

## 🔧 如果Hiddify没有路由设置

某些Hiddify版本可能没有内置路由编辑器,可以:

### 选项1: 更新Hiddify到最新版本
- 访问: https://github.com/hiddify/hiddify-next/releases
- 下载最新的macOS版本

### 选项2: 切换到Clash Verge Rev

您的系统已安装Clash Verge Rev,可以考虑切换:

```bash
# 1. 关闭Hiddify
# 2. 打开Clash Verge Rev
open -a "Clash Verge Rev"

# 3. 导入您的订阅链接到Clash
# 4. 按照 VPN_CONFIG_GUIDE.md 中的Clash配置方法添加规则
```

---

## 📞 需要帮助?

如果以上方法都无法配置:

1. **截图Hiddify的主界面**,我可以帮您找到配置入口
2. **查看Hiddify版本**: 应用 → 关于
3. **尝试运行**: `./verify_vpn_config.sh` 并发送输出

---

## 🚀 临时解决方案

在配置VPN之前,您可以:

**方案1**: 暂时断开VPN使用CommitPop
**方案2**: 仅在需要访问国外网站时开启VPN

这不会影响CommitPop的功能,因为GitHub在国内是可以直接访问的。

---

**配置时间**: 约2-5分钟  
**难度**: ⭐⭐☆☆☆ (简单)  
**效果**: 解决DNS解析问题,提升访问速度
