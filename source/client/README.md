# OpenP2P 客户端

## 简介

OpenP2P客户端用于连接到OpenP2P服务器，实现P2P网络连接和端口映射功能。

## 配置说明

客户端使用JSON格式的配置文件，默认为`config.json`。配置文件包含以下字段：

```json
{
  "server": "localhost",         // 服务器地址，必填
  "port": 27183,                 // 服务器端口，默认27183
  "name": "测试节点",             // 节点名称，建议填写，方便识别
  "token": "your_token_here",    // 节点令牌，必填，用于身份验证
  "bind": "0.0.0.0",             // 绑定地址，默认0.0.0.0
  "p2p_port": 0,                 // P2P端口，0表示随机选择
  "log_level": 3,                // 日志级别：0=关闭，1=错误，2=信息，3=调试
  "auto_start": true,            // 是否自动启动
  "auto_login": true,            // 是否自动登录
  "language": "zh_CN",           // 界面语言
  "theme": "light"               // 界面主题
}
```

## 使用方法

1. 复制`config.json.example`为`config.json`
2. 修改配置文件中的服务器地址和节点令牌
3. 运行客户端程序：
   ```
   ./openp2p-client -config=config.json
   ```

## 日志文件

客户端日志默认保存在以下位置：

- Windows: `%LOCALAPPDATA%\OpenP2P\logs\`
- Linux: `~/.local/share/openp2p/logs/`
- macOS: `~/Library/Application Support/OpenP2P/logs/`

## 常见问题

### 客户端无法连接到服务器

1. 检查服务器地址和端口是否正确
2. 确认节点令牌是否与服务器上注册的节点匹配
3. 检查网络连接是否正常
4. 查看日志文件获取详细错误信息

### 客户端连接后立即断开

1. 检查服务器是否正常运行
2. 确认节点令牌是否有效
3. 检查防火墙设置是否允许客户端访问服务器

## 构建说明

```bash
# 进入源码目录
cd source

# 构建客户端
go build -o bin/openp2p-client cmd/client/main.go
``` 