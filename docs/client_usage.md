# OpenP2P 客户端使用说明

## 安装步骤

1. 从GitHub Releases页面下载最新的客户端压缩包 `openp2p-client-vX.X.X.zip`
2. 解压缩到任意目录，例如 `C:\Program Files\OpenP2P`
3. 将示例配置文件 `config.json.example` 复制为 `config.json`
4. 编辑 `config.json` 文件，填写服务器地址和节点令牌等信息

## 配置文件说明

配置文件使用JSON格式，主要字段说明：

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

## 启动客户端

### Windows

1. **直接双击运行**：
   - 确保 `config.json` 文件与可执行文件 `openp2p-client-windows-amd64.exe` 在同一目录下
   - 双击 `openp2p-client-windows-amd64.exe` 运行

2. **命令行运行**：
   - 打开命令提示符或PowerShell
   - 切换到客户端所在目录
   - 执行命令：
     ```
     .\openp2p-client-windows-amd64.exe
     ```

3. **指定配置文件**：
   - 如果配置文件不在默认位置，可以使用 `-config` 参数指定：
     ```
     .\openp2p-client-windows-amd64.exe -config=C:\path\to\config.json
     ```

### Linux/macOS

1. **命令行运行**：
   ```bash
   ./openp2p-client-linux-amd64  # Linux
   ./openp2p-client-darwin-amd64  # macOS
   ```

2. **指定配置文件**：
   ```bash
   ./openp2p-client-linux-amd64 -config=/path/to/config.json
   ```

## 查看日志

客户端日志默认保存在以下位置：

- Windows: `%LOCALAPPDATA%\OpenP2P\logs\`
- Linux: `~/.local/share/openp2p/logs/`
- macOS: `~/Library/Application Support/OpenP2P/logs/`

日志文件名格式为 `client_YYYYMMDD.log`

如果无法在上述位置找到日志，请检查临时目录：

- Windows: `%TEMP%\openp2p\logs\`
- Linux/macOS: `/tmp/openp2p/logs/`

## 常见问题

### 1. 客户端无法连接到服务器

可能的原因：
- 配置文件中的服务器地址或端口不正确
- 节点令牌无效或已过期
- 网络连接问题
- 服务器未运行或不可访问

解决方法：
1. 检查配置文件中的服务器地址，确保不包含 `http://` 前缀
2. 在管理界面中验证节点令牌是否正确
3. 使用 `ping` 命令测试与服务器的连接
4. 检查防火墙设置

### 2. 找不到日志文件

可能的原因：
- 日志目录权限问题
- 客户端未正确启动
- 日志级别设置过低

解决方法：
1. 确保客户端有权限写入日志目录
2. 将日志级别设置为2或3（`"log_level": 3`）
3. 检查临时目录中是否有日志文件
4. 通过命令行启动客户端，查看控制台输出

### 3. 配置文件未被读取

可能的原因：
- 配置文件不在正确位置
- 配置文件格式错误
- 使用了错误的可执行文件

解决方法：
1. 确保配置文件与可执行文件在同一目录下
2. 验证配置文件的JSON格式是否正确
3. 使用命令行启动并指定配置文件路径
4. 确保使用的是客户端可执行文件（`openp2p-client-windows-amd64.exe`），而不是服务器端程序

## 作为服务运行

### Windows

1. 使用NSSM（Non-Sucking Service Manager）：
   ```
   nssm install OpenP2P "C:\Program Files\OpenP2P\openp2p-client-windows-amd64.exe"
   nssm set OpenP2P AppDirectory "C:\Program Files\OpenP2P"
   nssm start OpenP2P
   ```

### Linux

1. 创建systemd服务文件 `/etc/systemd/system/openp2p-client.service`：
   ```
   [Unit]
   Description=OpenP2P Client
   After=network.target

   [Service]
   Type=simple
   User=your_username
   WorkingDirectory=/opt/openp2p
   ExecStart=/opt/openp2p/openp2p-client-linux-amd64
   Restart=on-failure

   [Install]
   WantedBy=multi-user.target
   ```

2. 启用并启动服务：
   ```bash
   sudo systemctl enable openp2p-client
   sudo systemctl start openp2p-client
   ```

## 更多帮助

如需更多帮助，请参考项目文档或联系系统管理员。 