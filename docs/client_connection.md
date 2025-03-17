# OpenP2P 客户端连接指南

## 客户端连接流程

OpenP2P客户端与服务器的连接流程如下：

1. **启动客户端**：客户端读取配置文件（config.json）
2. **验证配置**：客户端向服务器发送验证请求（/api/client/verify）
3. **建立连接**：验证成功后，客户端向服务器发送连接请求（/api/client/connect）
4. **保持心跳**：客户端定期向服务器发送心跳请求（/api/client/heartbeat）

## 客户端日志

客户端日志默认保存在以下位置：

- Windows: `%LOCALAPPDATA%\OpenP2P\logs\`（而非%APPDATA%）
- Linux: `~/.local/share/openp2p/logs/`
- macOS: `~/Library/Application Support/OpenP2P/logs/`

如果找不到日志文件，请检查：

1. 客户端是否有写入权限
2. 日志级别设置（config.json中的log_level）
3. 是否有其他路径覆盖设置

## 常见问题排查

### 客户端无法连接到服务器

1. **检查网络连接**：确保客户端可以访问服务器IP和端口
   ```
   ping openp2p.example.com
   telnet openp2p.example.com 27183
   ```

2. **检查配置文件**：确保server和token字段正确
   ```json
   {
     "server": "openp2p.example.com",
     "port": 27183,
     "name": "Office",
     "token": "xxxxxxxxxxxxxxxx"
   }
   ```

3. **检查服务器节点配置**：在管理后台确认节点已正确创建，并且token匹配

4. **检查防火墙设置**：确保客户端和服务器的防火墙允许相关端口通信

### 客户端连接后立即断开

1. **检查心跳设置**：客户端应每30-60秒发送一次心跳
2. **检查服务器日志**：查看服务器是否接收到连接请求
3. **检查客户端日志**：查看详细的连接错误信息

### 节点显示离线但客户端正在运行

1. **重启客户端**：有时重启客户端可以解决连接问题
2. **手动触发连接**：在客户端界面上手动触发重连
3. **检查时间同步**：确保客户端和服务器的系统时间大致同步

## 客户端API说明

客户端与服务器通信使用以下API：

### 1. 验证配置

```
POST /api/client/verify
Content-Type: application/json

{
  "server": "openp2p.example.com",
  "port": 27183,
  "name": "Office",
  "token": "xxxxxxxxxxxxxxxx"
}
```

### 2. 建立连接

```
POST /api/client/connect
Content-Type: application/json

{
  "token": "xxxxxxxxxxxxxxxx",
  "name": "Office",
  "ip": "192.168.1.100",
  "version": "1.0.1",
  "platform": "windows"
}
```

### 3. 心跳请求

```
POST /api/client/heartbeat
Content-Type: application/json

{
  "token": "xxxxxxxxxxxxxxxx"
}
```

## 故障排除命令

如果客户端无法正常连接，可以使用以下命令手动测试API：

```bash
# 验证配置
curl -X POST http://openp2p.example.com:27183/api/client/verify \
  -H "Content-Type: application/json" \
  -d '{"server":"openp2p.example.com","port":27183,"name":"Office","token":"xxxxxxxxxxxxxxxx"}'

# 建立连接
curl -X POST http://openp2p.example.com:27183/api/client/connect \
  -H "Content-Type: application/json" \
  -d '{"token":"xxxxxxxxxxxxxxxx","name":"Office","version":"1.0.1","platform":"windows"}'

# 发送心跳
curl -X POST http://openp2p.example.com:27183/api/client/heartbeat \
  -H "Content-Type: application/json" \
  -d '{"token":"xxxxxxxxxxxxxxxx"}'
``` 