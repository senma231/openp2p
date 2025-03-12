@echo off
setlocal enabledelayedexpansion

:: 设置版本号
for /f "tokens=2 delims=：" %%i in ('findstr "当前版本：" VERSION.md') do set VERSION=%%i
set BUILD_DIR=release

:: 创建构建目录
if not exist %BUILD_DIR% mkdir %BUILD_DIR%

:: 构建Windows版本
echo Building for Windows...
set GOOS=windows
set GOARCH=amd64
go build -o %BUILD_DIR%\openp2p-client.exe .\cmd\client

if %ERRORLEVEL% neq 0 (
    echo Build failed
    exit /b 1
)

:: 创建发布包
set PACKAGE_NAME=openp2p-client-windows-amd64-%VERSION%

:: 创建临时目录
if not exist tmp\%PACKAGE_NAME% mkdir tmp\%PACKAGE_NAME%

:: 复制文件
copy %BUILD_DIR%\openp2p-client.exe tmp\%PACKAGE_NAME%\
copy config.json.example tmp\%PACKAGE_NAME%\
copy README.md tmp\%PACKAGE_NAME%\
copy LICENSE tmp\%PACKAGE_NAME%\

:: 创建ZIP包
cd tmp
powershell Compress-Archive -Path %PACKAGE_NAME% -DestinationPath ..\%BUILD_DIR%\%PACKAGE_NAME%.zip
cd ..

:: 清理临时文件
rmdir /s /q tmp
del %BUILD_DIR%\openp2p-client.exe

echo Build process completed! 