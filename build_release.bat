@echo off
setlocal enabledelayedexpansion

echo [INFO] 开始构建 OpenP2P 客户端

:: 获取版本号
for /f "tokens=2 delims=：" %%a in ('findstr "当前版本" VERSION.md') do (
    set VERSION=%%a
    set VERSION=!VERSION: =!
)

if "!VERSION!"=="" (
    echo [ERROR] 无法从 VERSION.md 获取版本号
    exit /b 1
)

echo [INFO] 开始构建 OpenP2P 客户端 v!VERSION!

:: 创建发布目录
set RELEASE_DIR=release\v!VERSION!
mkdir %RELEASE_DIR% 2>nul

:: 构建 Windows 客户端
echo [INFO] 构建 Windows 客户端...
cd source
set GOOS=windows
set GOARCH=amd64
go build -o "..\%RELEASE_DIR%\openp2p-windows-amd64.exe" .\cmd\openp2p.go
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Windows 客户端构建失败
    exit /b 1
)
echo [INFO] Windows 客户端构建成功

:: 返回项目根目录
cd ..

:: 复制文档和配置文件
echo [INFO] 复制文档和配置文件...
copy README.md "%RELEASE_DIR%\"
copy VERSION.md "%RELEASE_DIR%\"
copy 客户端安装指南.md "%RELEASE_DIR%\"
copy source\config.json "%RELEASE_DIR%\"

:: 创建 ZIP 压缩包
echo [INFO] 创建压缩包...
cd %RELEASE_DIR%
powershell Compress-Archive -Path openp2p-windows-amd64.exe, README.md, VERSION.md, 客户端安装指南.md, config.json -DestinationPath "..\openp2p-windows-amd64-v!VERSION!.zip" -Force
cd ..

:: 创建发布说明
echo [INFO] 创建发布说明...
(
echo # OpenP2P v!VERSION! 发布说明
echo.
echo ## 更新内容
echo.
echo - 修复了 TOTP 验证问题，增加了时间偏移容忍度
echo - 优化了项目结构，删除了废弃的文件和脚本
echo - 其他 bug 修复和性能优化
echo.
echo ## 下载
echo.
echo - [Windows 64位](openp2p-windows-amd64-v!VERSION!.zip^)
echo.
echo ## 安装说明
echo.
echo 请参考压缩包中的 `客户端安装指南.md` 文件。
echo.
echo ## 配置说明
echo.
echo 默认配置文件为 `config.json`，您可以根据需要修改。
) > "release_notes_v!VERSION!.md"

echo [INFO] 发布准备完成！
echo [INFO] 发布文件位于: %CD%
echo [INFO] 请使用以下命令创建 GitHub Release:
echo gh release create v!VERSION! --title "OpenP2P v!VERSION!" --notes-file release_notes_v!VERSION!.md *.zip

exit /b 0 