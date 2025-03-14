# OpenP2P 部署指南

## 自动化部署

### Linux系统部署

1. **下载部署脚本**
   ```bash
   wget https://raw.githubusercontent.com/senma231/openp2p/main/deploy.sh
   chmod +x deploy.sh
   ```

2. **运行部署脚本**
   ```bash
   sudo ./deploy.sh
   ```

3. **验证部署**
   ```bash
   # 检查服务状态
   sudo systemctl status openp2p
   sudo systemctl status nginx

   # 检查日志
   sudo journalctl -u openp2p -f
   ```

### Windows系统部署

1. **下载部署脚本**
   - 从GitHub下载 `deploy.bat`
   - 右键点击脚本，选择"以管理员身份运行"

2. **验证部署**
   ```cmd
   # 检查服务状态
   sc query OpenP2P
   ```

## 手动部署步骤

### 前端部署 (Cloudflare Pages)

1. **准备工作**
   - 确保您有一个GitHub账号
   - 确保您有一个Cloudflare账号
   - 将代码推送到GitHub仓库

2. **Cloudflare Pages配置**
   1. 登录[Cloudflare Dashboard](https://dash.cloudflare.com)
   2. 进入Pages页面
   3. 点击"创建项目"
   4. 选择"连接到Git"
   5. 选择您的GitHub仓库
   6. 配置构建设置：
      - 框架预设：选择 Vue
      - 构建命令：`cd source/web && npm install && npm run build`
      - 构建输出目录：`source/web/dist`
      - 环境变量：
        ```
        VITE_API_URL=https://api.openp2p.909981.xyz
        NODE_VERSION=16
        IS_CLOUDFLARE=true
        ```
      - 根目录：`/`
   7. 点击"保存并部署"

3. **环境变量说明**
   - `VITE_API_URL`: 后端API服务器的URL（必须配置）
   - `NODE_VERSION`: Node.js版本，建议使用16或更高版本
   - `IS_CLOUDFLARE`: 设置为true（Cloudflare环境标识）

### 后端部署

1. **系统要求**
   - Go 1.20或更高版本
   - 支持systemd的Linux系统（推荐Ubuntu 20.04或更高版本）
   - 2GB以上内存
   - 10GB以上磁盘空间

2. **安装Go环境**
   ```bash
   # 下载并安装Go
   wget https://go.dev/dl/go1.20.linux-amd64.tar.gz
   sudo tar -C /usr/local -xzf go1.20.linux-amd64.tar.gz
   
   # 配置环境变量
   echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
   source ~/.bashrc
   ```

3. **编译**
   ```bash
   # 克隆代码
   git clone https://github.com/senma231/openp2p.git
   cd openp2p

   # 安装依赖
   cd source/core
   go mod tidy
   
   # 编译
   go build -o openp2p
   ```

4. **配置文件**
   创建配置目录和文件：
   ```bash
   sudo mkdir -p /opt/openp2p/config
   sudo nano /opt/openp2p/config/env.json
   ```

   配置文件内容：
   ```json
   {
     "is_development": false,
     "log_level": "info",
     "api_port": 27183,
     "p2p_port": 27182
   }
   ```

5. **配置systemd服务**
   创建文件 `/etc/systemd/system/openp2p.service`:
   ```ini
   [Unit]
   Description=OpenP2P Service
   After=network.target

   [Service]
   Type=simple
   User=root
   WorkingDirectory=/opt/openp2p
   ExecStart=/opt/openp2p/openp2p
   Restart=always
   RestartSec=5
   Environment=OPENP2P_ENV=production

   [Install]
   WantedBy=multi-user.target
   ```

6. **部署步骤**
   ```bash
   # 创建目录
   sudo mkdir -p /opt/openp2p

   # 复制可执行文件和配置
   sudo cp openp2p /opt/openp2p/
   sudo cp -r config /opt/openp2p/

   # 设置权限
   sudo chmod +x /opt/openp2p/openp2p
   sudo chown -R root:root /opt/openp2p

   # 启动服务
   sudo systemctl daemon-reload
   sudo systemctl enable openp2p
   sudo systemctl start openp2p
   ```

7. **检查服务状态**
   ```bash
   sudo systemctl status openp2p
   sudo journalctl -u openp2p -f
   ```

## 安全配置

1. **Cloudflare SSL配置**
   1. 登录Cloudflare Dashboard
   2. 进入SSL/TLS页面
   3. 将SSL/TLS加密模式设置为"Full"
   4. 在"Edge Certificates"中启用以下选项：
      - Always Use HTTPS
      - Automatic HTTPS Rewrites
      - Minimum TLS Version: 1.2

2. **DNS配置**
   1. 在Cloudflare DNS页面添加以下记录：
      - 记录1（前端）:
        - 类型：CNAME
        - 名称：openp2p
        - 目标：[您的Cloudflare Pages域名]
        - 代理状态：已代理（橙色云朵）
      
      - 记录2（API）:
        - 类型：A
        - 名称：api.openp2p
        - IPv4地址：您的服务器IP
        - 代理状态：已代理（橙色云朵）

## 故障排查

1. **日志查看**
   ```bash
   # 查看后端服务日志
   sudo journalctl -u openp2p -f

   # 查看Nginx访问日志
   sudo tail -f /var/log/nginx/access.log

   # 查看Nginx错误日志
   sudo tail -f /var/log/nginx/error.log
   ```

2. **常见问题处理**
   - **API无法访问**
     1. 检查服务状态：`sudo systemctl status openp2p`
     2. 检查端口占用：`sudo lsof -i :27183`
     3. 检查Cloudflare DNS配置

   - **前端无法连接API**
     1. 检查Cloudflare SSL配置
     2. 验证API地址配置是否正确
     3. 检查Cloudflare DNS配置

   - **服务启动失败**
     1. 检查日志：`sudo journalctl -u openp2p -n 50`
     2. 检查配置文件权限
     3. 验证端口是否被占用

## 更新部署

1. **更新前端**
   - 推送代码到GitHub，Cloudflare Pages会自动部署
   - 可以在Cloudflare Pages面板查看部署状态和日志

2. **更新后端**
   ```bash
   # 备份当前版本
   sudo cp /opt/openp2p/openp2p /opt/openp2p/openp2p.bak

   # 停止服务
   sudo systemctl stop openp2p

   # 更新可执行文件
   sudo cp new-openp2p /opt/openp2p/openp2p
   sudo chmod +x /opt/openp2p/openp2p

   # 重启服务
   sudo systemctl start openp2p

   # 检查更新后的状态
   sudo systemctl status openp2p
   ```

3. **回滚流程**
   如果更新后出现问题：
   ```bash
   # 停止服务
   sudo systemctl stop openp2p

   # 恢复备份
   sudo cp /opt/openp2p/openp2p.bak /opt/openp2p/openp2p
   sudo chmod +x /opt/openp2p/openp2p

   # 重启服务
   sudo systemctl start openp2p
   ``` 