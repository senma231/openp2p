# OpenP2P 客户端连接指南

## 客户端配置说明

OpenP2P客户端使用JSON格式的配置文件，默认为`config.json`。以下是配置文件的详细说明：

```json
{
  "server": "openp2p.example.com",  // 服务器地址，不要包含http://前缀
  "port": 27183,                    // 服务器端口，默认27183
  "name": "Office",                 // 节点名称，用于在管理界面中显示
  "token": "your_token_here",       // 节点令牌，从管理界面创建节点时获取
  "bind": "0.0.0.0",                // 绑定地址，默认0.0.0.0
  "p2p_port": 0,                    // P2P端口，0表示随机选择
  "log_level": 2,                   // 日志级别：0=关闭，1=错误，2=信息，3=调试
  "auto_start": false,              // 是否自动启动
  "auto_login": false,              // 是否自动登录
  "language": "zh_CN",              // 界面语言
  "theme": "light"                  // 界面主题
}
```

## 客户端连接流程

OpenP2P客户端与服务器的连接流程如下：

1. **启动客户端**：客户端读取配置文件（config.json）
2. **验证配置**：客户端向服务器发送验证请求（/api/client/verify）
3. **建立连接**：验证成功后，客户端向服务器发送连接请求（/api/client/connect）
4. **保持心跳**：客户端定期向服务器发送心跳请求（/api/client/heartbeat）

## 客户端日志

客户端日志默认保存在以下位置：

- Windows: `%LOCALAPPDATA%\OpenP2P\logs\`
- Linux: `~/.local/share/openp2p/logs/`
- macOS: `~/Library/Application Support/OpenP2P/logs/`

如果找不到日志文件，请检查：

1. 客户端是否有写入权限
2. 日志级别设置（config.json中的log_level）
3. 是否有其他路径覆盖设置

## 常见问题解决

### 1. 服务器地址格式问题

确保服务器地址不包含`http://`或`https://`前缀。例如：

- 正确: `"server": "openp2p.example.com"`
- 错误: `"server": "http://openp2p.example.com"`

### 2. 客户端无法连接到服务器

如果客户端无法连接到服务器，请检查以下几点：

1. 确认服务器地址和端口是否正确
2. 确认节点令牌是否与管理界面中创建的节点令牌一致
3. 检查网络连接，确保客户端可以访问服务器
4. 查看客户端日志获取详细错误信息

### 3. 客户端日志位置

客户端日志默认保存在以下位置：

- Windows: `%LOCALAPPDATA%\OpenP2P\logs\`
- Linux: `~/.local/share/openp2p/logs/`
- macOS: `~/Library/Application Support/OpenP2P/logs/`

如果无法在上述位置找到日志，请检查临时目录：

- Windows: `%TEMP%\openp2p\logs\`
- Linux/macOS: `/tmp/openp2p/logs/`

### 4. 节点状态显示离线

如果节点在管理界面中显示为离线状态，请检查：

1. 客户端是否正在运行
2. 客户端日志中是否有连接错误
3. 客户端和服务器之间的网络连接是否正常
4. 防火墙是否阻止了客户端与服务器的通信

### 5. 节点信息不完整

如果节点信息在管理界面中显示不完整，可能是因为：

1. 客户端版本过旧，需要更新到最新版本
2. 客户端配置文件中缺少必要的字段
3. 客户端与服务器之间的通信存在问题

## 故障排除步骤

1. **检查客户端日志**：查看客户端日志文件，寻找错误信息
2. **验证配置文件**：确保配置文件格式正确，所有必要字段都已填写
3. **测试网络连接**：使用ping或telnet测试客户端是否可以连接到服务器
4. **重启客户端**：有时候简单地重启客户端可以解决连接问题
5. **更新客户端**：确保使用的是最新版本的客户端

如果以上步骤无法解决问题，请联系系统管理员获取帮助。

## 客户端API说明

客户端与服务器通信使用以下API：

### 1. 验证配置

```