#!/bin/bash

# 设置版本号
VERSION=$(cat VERSION.md | grep "当前版本：" | cut -d "：" -f 2)
BUILD_DIR="release"
PLATFORMS=("windows/amd64" "linux/amd64" "darwin/amd64" "darwin/arm64")

# 创建构建目录
mkdir -p $BUILD_DIR

# 构建函数
build() {
    PLATFORM=$1
    OUTPUT=$2
    
    echo "Building for $PLATFORM..."
    GOOS=${PLATFORM%/*} GOARCH=${PLATFORM#*/} go build -o "$OUTPUT" ./cmd/client
    
    if [ $? -eq 0 ]; then
        echo "Successfully built for $PLATFORM"
    else
        echo "Failed to build for $PLATFORM"
        exit 1
    fi
}

# 打包函数
package() {
    PLATFORM=$1
    BINARY=$2
    
    echo "Packaging for $PLATFORM..."
    PACKAGE_NAME="openp2p-client-${PLATFORM%/*}-${PLATFORM#*/}-$VERSION"
    
    # 创建临时目录
    mkdir -p "tmp/$PACKAGE_NAME"
    
    # 复制文件
    cp "$BINARY" "tmp/$PACKAGE_NAME/"
    cp config.json.example "tmp/$PACKAGE_NAME/"
    cp README.md "tmp/$PACKAGE_NAME/"
    cp LICENSE "tmp/$PACKAGE_NAME/"
    
    # 创建压缩包
    cd tmp
    if [[ ${PLATFORM%/*} == "windows" ]]; then
        zip -r "../$BUILD_DIR/$PACKAGE_NAME.zip" "$PACKAGE_NAME"
    else
        tar -czf "../$BUILD_DIR/$PACKAGE_NAME.tar.gz" "$PACKAGE_NAME"
    fi
    cd ..
    
    # 清理临时目录
    rm -rf tmp
}

# 主构建流程
echo "Starting build process for OpenP2P Client v$VERSION"

for PLATFORM in "${PLATFORMS[@]}"; do
    # 设置输出文件名
    if [[ ${PLATFORM%/*} == "windows" ]]; then
        OUTPUT="$BUILD_DIR/openp2p-client.exe"
    else
        OUTPUT="$BUILD_DIR/openp2p-client"
    fi
    
    # 构建
    build $PLATFORM $OUTPUT
    
    # 打包
    package $PLATFORM $OUTPUT
    
    # 清理构建文件
    rm $OUTPUT
done

echo "Build process completed!" 