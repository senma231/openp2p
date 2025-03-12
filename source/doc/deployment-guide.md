# OpenP2P 部署指南

## 环境要求

### 系统要求
- Windows 7及以上版本
- Linux（支持Ubuntu、CentOS等主流发行版）
- MacOS

### 硬件要求
- CPU：支持386、amd64、arm、arm64、mipsle、mipsle64、mips、mips64、s390x、ppc64le架构
- 内存：最低2MB+
- 磁盘空间：最低2MB+
- 网络：支持UDP/TCP通信

### 开发环境要求（仅开发者）
- Go version 1.20（支持win7）

## 安装步骤

### 1. 获取安装包

从官方网站下载对应平台的安装包：
- Windows: openp2p.exe
- Linux/MacOS: openp2p

### 2. 注册账号

1. 访问 https://console.openp2p.cn
2. 注册新用户（无需认证）
3. 获取Token（在"我的"页面获取）

### 3. 安装服务

#### Windows
1. 以管理员身份运行命令提示符
2. 执行安装命令：
```
openp2p.exe install -node <节点名> -token <你的Token>
```

#### Linux/MacOS
1. 赋予执行权限：
```bash
chmod +x openp2p
```
2. 执行安装命令：
```bash
sudo ./openp2p install -node <节点名> -token <你的Token>
```

### 4. 配置文件

安装后配置文件位置：
- Windows: C:\Program Files\OpenP2P\config.json
- Linux/MacOS: /usr/local/openp2p/config.json

配置文件示例：
```json
{
  "network": {
    "Node": "节点名称",
    "Token": "你的Token",
    "ShareBandwidth": 10,
    "ServerHost": "api.openp2p.cn",
    "ServerPort": 27183
  },
  "apps": [
    {
      "AppName": "RemoteDesktop",
      "Protocol": "tcp",
      "SrcPort": 23389,
      "PeerNode": "目标节点名",
      "DstPort": 3389,
      "DstHost": "localhost"
    }
  ]
}
```

## 常见问题

### 1. 连接失败

#### 防火墙设置
- Windows：确保已允许openp2p.exe通过防火墙
- Linux：检查防火墙是否放行UDP端口27182-27183

#### 端口占用
检查配置文件中的端口是否被其他程序占用：
- Windows: `netstat -ano | findstr <端口号>`
- Linux: `netstat -tunlp | grep <端口号>`

### 2. 性能优化

- 调整ShareBandwidth参数：根据实际带宽设置合适的共享带宽
- 选择合适的传输协议：TCP用于稳定性要求高的场景，UDP用于实时性要求高的场景

### 3. 服务管理

#### 启动服务
- Windows: `net start openp2p`
- Linux: `systemctl start openp2p`

#### 停止服务
- Windows: `net stop openp2p`
- Linux: `systemctl stop openp2p`

#### 查看日志
- Windows: 事件查看器 -> 应用程序
- Linux: `journalctl -u openp2p`

## 升级说明

### 自动升级
```bash
./openp2p update
```

### 手动升级
1. 停止服务
2. 替换可执行文件
3. 重启服务

## 卸载说明

### Windows
```cmd
C:\Program Files\OpenP2P\openp2p.exe uninstall
```

### Linux/MacOS
```bash
sudo /usr/local/openp2p/openp2p uninstall
```