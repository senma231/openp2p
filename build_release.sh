#!/bin/bash

# 设置颜色
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 显示信息函数
info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 获取版本号
VERSION=$(cat VERSION.md | grep -oP '(?<=当前版本：).*' | tr -d '[:space:]')
if [ -z "$VERSION" ]; then
    error "无法从 VERSION.md 获取版本号"
    exit 1
fi

info "开始构建 OpenP2P 客户端 v${VERSION}"

# 创建发布目录
RELEASE_DIR="release/v${VERSION}"
mkdir -p "$RELEASE_DIR"

# 构建 Windows 客户端
info "构建 Windows 客户端..."
cd source
GOOS=windows GOARCH=amd64 go build -o "../${RELEASE_DIR}/openp2p-windows-amd64.exe" ./cmd/openp2p.go
if [ $? -ne 0 ]; then
    error "Windows 客户端构建失败"
    exit 1
fi
info "Windows 客户端构建成功"

# 构建 Linux 客户端
info "构建 Linux 客户端..."
GOOS=linux GOARCH=amd64 go build -o "../${RELEASE_DIR}/openp2p-linux-amd64" ./cmd/openp2p.go
if [ $? -ne 0 ]; then
    error "Linux 客户端构建失败"
    exit 1
fi
info "Linux 客户端构建成功"

# 构建 macOS 客户端
info "构建 macOS 客户端..."
GOOS=darwin GOARCH=amd64 go build -o "../${RELEASE_DIR}/openp2p-macos-amd64" ./cmd/openp2p.go
if [ $? -ne 0 ]; then
    error "macOS 客户端构建失败"
    exit 1
fi
info "macOS 客户端构建成功"

# 返回项目根目录
cd ..

# 复制文档和配置文件
info "复制文档和配置文件..."
cp README.md "${RELEASE_DIR}/"
cp VERSION.md "${RELEASE_DIR}/"
cp 客户端安装指南.md "${RELEASE_DIR}/"
cp source/config.json "${RELEASE_DIR}/"

# 创建 ZIP 压缩包
info "创建压缩包..."
cd "$RELEASE_DIR"
zip -r "../openp2p-windows-amd64-v${VERSION}.zip" openp2p-windows-amd64.exe README.md VERSION.md 客户端安装指南.md config.json
zip -r "../openp2p-linux-amd64-v${VERSION}.zip" openp2p-linux-amd64 README.md VERSION.md 客户端安装指南.md config.json
zip -r "../openp2p-macos-amd64-v${VERSION}.zip" openp2p-macos-amd64 README.md VERSION.md 客户端安装指南.md config.json
cd ..

# 创建发布说明
info "创建发布说明..."
cat > "release_notes_v${VERSION}.md" << EOF
# OpenP2P v${VERSION} 发布说明

## 更新内容

- 修复了 TOTP 验证问题，增加了时间偏移容忍度
- 优化了项目结构，删除了废弃的文件和脚本
- 其他 bug 修复和性能优化

## 下载

- [Windows 64位](openp2p-windows-amd64-v${VERSION}.zip)
- [Linux 64位](openp2p-linux-amd64-v${VERSION}.zip)
- [macOS 64位](openp2p-macos-amd64-v${VERSION}.zip)

## 安装说明

请参考压缩包中的 \`客户端安装指南.md\` 文件。

## 配置说明

默认配置文件为 \`config.json\`，您可以根据需要修改。
EOF

info "发布准备完成！"
info "发布文件位于: $(pwd)"
info "请使用以下命令创建 GitHub Release:"
echo "gh release create v${VERSION} --title \"OpenP2P v${VERSION}\" --notes-file release_notes_v${VERSION}.md *.zip"

exit 0 