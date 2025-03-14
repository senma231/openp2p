@echo off
setlocal enabledelayedexpansion

:: 颜色定义
set "RED=[91m"
set "GREEN=[92m"
set "YELLOW=[93m"
set "NC=[0m"

:: 打印带颜色的信息
:print_info
echo %GREEN%[INFO] %~1%NC%
exit /b

:print_warn
echo %YELLOW%[WARN] %~1%NC%
exit /b

:print_error
echo %RED%[ERROR] %~1%NC%
exit /b

:: 检查管理员权限
net session >nul 2>&1
if %errorLevel% neq 0 (
    call :print_error "请使用管理员权限运行此脚本"
    exit /b 1
)

:: 创建应用目录
call :print_info "创建应用目录..."
mkdir "C:\opt\openp2p" 2>nul
mkdir "C:\opt\openp2p\config" 2>nul

:: 克隆代码
call :print_info "克隆代码..."
cd /d "C:\opt\openp2p"
git clone https://github.com/senma231/openp2p.git .

:: 创建配置文件
call :print_info "创建配置文件..."
echo {
echo     "is_development": false,
echo     "log_level": "info",
echo     "api_port": 27183,
echo     "p2p_port": 27182
echo } > "C:\opt\openp2p\config\env.json"

:: 创建Windows服务
call :print_info "创建Windows服务..."
sc create OpenP2P binPath= "\"C:\opt\openp2p\openp2p.exe\"" start= auto
sc description OpenP2P "OpenP2P Service"

:: 启动服务
call :print_info "启动服务..."
sc start OpenP2P

:: 检查服务状态
call :print_info "检查服务状态..."
sc query OpenP2P

call :print_info "部署完成！"
call :print_info "请确保您的Cloudflare DNS记录已正确配置："
call :print_info "1. 将 api.openp2p.909981.xyz 的A记录指向您的服务器IP"
call :print_info "2. 将 openp2p.909981.xyz 的CNAME记录指向您的Cloudflare Pages域名"
call :print_info "3. 在Cloudflare中启用SSL/TLS，选择Full模式"
call :print_info "4. 在Cloudflare Pages中更新环境变量："
call :print_info "   VITE_API_URL=https://api.openp2p.909981.xyz"
call :print_info "5. 重新部署前端应用"

pause 