# OpenP2P 客户端使用说明

## 安装说明

1. 从 [GitHub Releases](https://github.com/senma231/openp2p/releases) 下载最新版本的客户端
2. 解压到任意目录
3. 根据下面的说明配置和运行客户端

## 配置文件说明

客户端使用 JSON 格式的配置文件，默认名称为 `config.json`，应放置在客户端可执行文件同目录下。

配置文件示例：

```json
{
  "server": "openp2p.example.com",  // 服务器地址
  "port": 27183,                    // 服务器端口
  "name": "MyNode",                 // 节点名称
  "token": "xxxxxxxxxxxxxxxx",      // 节点令牌（从管理界面获取）
  "bind": "0.0.0.0",                // 绑定地址
  "p2p_port": 0,                    // P2P端口（0表示自动选择）
  "log_level": 3,                   // 日志级别（1-错误，2-信息，3-调试）
  "auto_start": false,              // 是否自动启动
  "auto_login": false,              // 是否自动登录
  "language": "zh_CN",              // 界面语言
  "theme": "light"                  // 界面主题
}
```

### 必填字段

- `server`: 管理服务器地址
- `port`: 管理服务器端口
- `name`: 节点名称（必须与管理界面创建的节点名称一致）
- `token`: 节点令牌（从管理界面获取）

### 可选字段

- `bind`: 绑定地址，默认为 `0.0.0.0`
- `p2p_port`: P2P端口，默认为 `0`（自动选择）
- `log_level`: 日志级别，默认为 `2`
  - `1`: 只记录错误
  - `2`: 记录信息和错误
  - `3`: 记录调试、信息和错误
- `auto_start`: 是否自动启动，默认为 `false`
- `auto_login`: 是否自动登录，默认为 `false`
- `language`: 界面语言，默认为 `zh_CN`
- `theme`: 界面主题，默认为 `light`

## 启动客户端

### Windows

双击 `openp2p-client.exe` 或在命令行中运行：

```cmd
openp2p-client.exe
```

如果配置文件不在默认位置，可以使用 `-config` 参数指定：

```cmd
openp2p-client.exe -config D:\path\to\config.json
```

### Linux/macOS

在终端中运行：

```bash
./openp2p-client
```

如果配置文件不在默认位置，可以使用 `-config` 参数指定：

```bash
./openp2p-client -config /path/to/config.json
```

## 日志文件

客户端会在以下位置创建日志文件：

1. 首先尝试在当前目录下创建 `logs` 文件夹，日志文件名为 `client_YYYYMMDD.log`
2. 如果当前目录无法创建，则尝试在系统日志目录创建：
   - Windows: `%APPDATA%\openp2p\logs\client_YYYYMMDD.log`
   - Linux: `~/.local/share/openp2p/logs/client_YYYYMMDD.log`
   - macOS: `~/Library/Application Support/openp2p/logs/client_YYYYMMDD.log`

## 常见问题

### 客户端无法连接到服务器

1. 检查配置文件中的服务器地址和端口是否正确
2. 确认节点名称和令牌与管理界面创建的节点一致
3. 检查网络连接，确保可以访问服务器
4. 查看日志文件，了解详细错误信息

### 没有日志输出

1. 确认配置文件中的 `log_level` 设置为 `2` 或 `3`
2. 检查当前目录下是否有 `logs` 文件夹，如果没有，检查系统日志目录
3. 确保客户端有写入日志文件的权限

### 客户端启动后立即退出

1. 在命令行中启动客户端，查看错误信息
2. 检查配置文件格式是否正确
3. 确认所有必填字段都已填写

## 作为服务运行

### Windows

1. 以管理员身份打开命令提示符
2. 使用 `sc` 命令创建服务：

```cmd
sc create OpenP2PClient binPath= "D:\path\to\openp2p-client.exe -config D:\path\to\config.json" start= auto
sc description OpenP2PClient "OpenP2P Client Service"
sc start OpenP2PClient
```

### Linux (systemd)

1. 创建服务文件 `/etc/systemd/system/openp2p-client.service`：

```ini
[Unit]
Description=OpenP2P Client Service
After=network.target

[Service]
Type=simple
User=your_username
ExecStart=/path/to/openp2p-client -config /path/to/config.json
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
```

2. 重新加载 systemd 配置并启动服务：

```bash
sudo systemctl daemon-reload
sudo systemctl enable openp2p-client
sudo systemctl start openp2p-client
```

3. 查看服务状态：

```bash
sudo systemctl status openp2p-client
``` 