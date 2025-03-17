#!/bin/bash

# 设置版本号
VERSION=$(git describe --tags --always)
BUILD_TIME=$(date "+%Y-%m-%d %H:%M:%S")
GO_VERSION=$(go version | awk '{print $3}')

# 创建构建目录
mkdir -p build

# 构建服务器端
echo "构建服务器端..."
GOOS=linux GOARCH=amd64 go build -o build/openp2p-linux-amd64 -ldflags "-X main.Version=$VERSION -X 'main.BuildTime=$BUILD_TIME' -X 'main.GoVersion=$GO_VERSION'" ./source/cmd/openp2p.go
GOOS=windows GOARCH=amd64 go build -o build/openp2p-windows-amd64.exe -ldflags "-X main.Version=$VERSION -X 'main.BuildTime=$BUILD_TIME' -X 'main.GoVersion=$GO_VERSION'" ./source/cmd/openp2p.go
GOOS=darwin GOARCH=amd64 go build -o build/openp2p-darwin-amd64 -ldflags "-X main.Version=$VERSION -X 'main.BuildTime=$BUILD_TIME' -X 'main.GoVersion=$GO_VERSION'" ./source/cmd/openp2p.go

# 构建客户端
echo "构建客户端..."
GOOS=linux GOARCH=amd64 go build -o build/openp2p-client-linux-amd64 -ldflags "-X main.Version=$VERSION -X 'main.BuildTime=$BUILD_TIME' -X 'main.GoVersion=$GO_VERSION'" ./source/cmd/client/main.go
GOOS=windows GOARCH=amd64 go build -o build/openp2p-client-windows-amd64.exe -ldflags "-X main.Version=$VERSION -X 'main.BuildTime=$BUILD_TIME' -X 'main.GoVersion=$GO_VERSION'" ./source/cmd/client/main.go
GOOS=darwin GOARCH=amd64 go build -o build/openp2p-client-darwin-amd64 -ldflags "-X main.Version=$VERSION -X 'main.BuildTime=$BUILD_TIME' -X 'main.GoVersion=$GO_VERSION'" ./source/cmd/client/main.go

# 复制配置文件示例
cp source/client/config.json.example build/config.json.example

# 打包
echo "打包文件..."
cd build
zip -r openp2p-server-$VERSION.zip openp2p-linux-amd64 openp2p-windows-amd64.exe openp2p-darwin-amd64
zip -r openp2p-client-$VERSION.zip openp2p-client-linux-amd64 openp2p-client-windows-amd64.exe openp2p-client-darwin-amd64 config.json.example

echo "构建完成！"
echo "服务器端: openp2p-server-$VERSION.zip"
echo "客户端: openp2p-client-$VERSION.zip" 