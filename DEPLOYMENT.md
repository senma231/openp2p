# OpenP2P 部署指南

## 前端部署 (Cloudflare Pages)

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
        VITE_API_URL=https://your-api-server.com
        NODE_VERSION=16
        ```
      - 根目录：`/`
   7. 点击"保存并部署"

3. **环境变量说明**
   - `VITE_API_URL`: 后端API服务器的URL（必须配置）
   - `NODE_VERSION`: Node.js版本，建议使用16或更高版本
   - `IS_CLOUDFLARE`: 设置为true（Cloudflare环境标识）

## 后端部署

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
   git clone https://github.com/your-username/openp2p.git
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

1. **防火墙设置**
   ```bash
   # 安装ufw（如果未安装）
   sudo apt install ufw

   # 配置防火墙规则
   sudo ufw allow ssh
   sudo ufw allow 27183/tcp  # API端口
   sudo ufw allow 27182/tcp  # P2P端口
   sudo ufw allow 27182/udp  # P2P端口

   # 启用防火墙
   sudo ufw enable
   ```

2. **SSL配置（推荐）**
   安装和配置Nginx：
   ```bash
   # 安装Nginx
   sudo apt install nginx

   # 安装certbot
   sudo apt install certbot python3-certbot-nginx
   ```

   获取SSL证书：
   ```bash
   sudo certbot --nginx -d your-api-server.com
   ```

   Nginx配置文件 `/etc/nginx/sites-available/openp2p`:
   ```nginx
   server {
       listen 443 ssl http2;
       server_name your-api-server.com;

       ssl_certificate /etc/letsencrypt/live/your-api-server.com/fullchain.pem;
       ssl_certificate_key /etc/letsencrypt/live/your-api-server.com/privkey.pem;

       # SSL配置
       ssl_protocols TLSv1.2 TLSv1.3;
       ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
       ssl_prefer_server_ciphers off;
       ssl_session_timeout 1d;
       ssl_session_cache shared:SSL:50m;
       ssl_stapling on;
       ssl_stapling_verify on;

       # CORS配置
       add_header 'Access-Control-Allow-Origin' 'https://your-cloudflare-pages-domain.pages.dev';
       add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS';
       add_header 'Access-Control-Allow-Headers' 'Content-Type, Authorization';
       add_header 'Access-Control-Allow-Credentials' 'true';

       location / {
           proxy_pass http://localhost:27183;
           proxy_http_version 1.1;
           proxy_set_header Upgrade $http_upgrade;
           proxy_set_header Connection 'upgrade';
           proxy_set_header Host $host;
           proxy_set_header X-Real-IP $remote_addr;
           proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
           proxy_set_header X-Forwarded-Proto $scheme;
           proxy_cache_bypass $http_upgrade;
       }
   }

   server {
       listen 80;
       server_name your-api-server.com;
       return 301 https://$server_name$request_uri;
   }
   ```

   启用配置：
   ```bash
   sudo ln -s /etc/nginx/sites-available/openp2p /etc/nginx/sites-enabled/
   sudo nginx -t
   sudo systemctl restart nginx
   ```

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
     3. 检查防火墙：`sudo ufw status`

   - **前端无法连接API**
     1. 检查CORS配置
     2. 验证API地址配置是否正确
     3. 检查SSL证书是否有效

   - **服务启动失败**
     1. 检查日志：`sudo journalctl -u openp2p -n 50`
     2. 检查配置文件权限
     3. 验证端口是否被占用

3. **性能优化**
   - 调整系统参数：
     ```bash
     # 编辑系统限制
     sudo nano /etc/security/limits.conf
     ```
     添加：
     ```
     *         soft    nofile      65535
     *         hard    nofile      65535
     ```

   - 调整内核参数：
     ```bash
     sudo nano /etc/sysctl.conf
     ```
     添加：
     ```
     net.core.somaxconn = 65535
     net.ipv4.tcp_max_syn_backlog = 65535
     ```

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