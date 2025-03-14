# OpenP2P Private

一个完整的P2P内网穿透解决方案，支持私有化部署。

## 功能特点

- 完全私有化部署，不依赖外部服务
- 支持P2P穿透，降低服务器负载
- 支持多种节点类型（客户端、内网节点、公网节点）
- 完整的Web管理界面
- 支持端口映射和高级映射功能
- 多平台客户端支持（Windows、Linux、macOS）

## 快速开始

### 服务端部署

详细部署步骤请参考 [部署指南.md](部署指南.md)

### 客户端安装

详细安装步骤请参考 [客户端安装指南.md](客户端安装指南.md)

## 项目结构

```
.
├── cmd/                    # 命令行工具
│   ├── server/            # 服务端入口
│   └── client/            # 客户端入口
├── source/                # 源代码
│   ├── core/             # 核心功能
│   ├── web/              # Web管理界面
│   └── config.json       # 配置文件
├── doc/                   # 文档
├── scripts/              # 构建脚本
└── docker/               # Docker配置
```

## 构建

### 服务端

```bash
# 构建服务端
go build -o openp2p ./cmd/server
```

### 客户端

```bash
# 构建客户端
go build -o openp2p-client ./cmd/client
```

## 版本管理

请参考 [VERSION.md](VERSION.md) 了解版本更新和维护策略。

## 贡献指南

1. Fork 本仓库
2. 创建您的特性分支 (git checkout -b feature/AmazingFeature)
3. 提交您的更改 (git commit -m 'Add some AmazingFeature')
4. 推送到分支 (git push origin feature/AmazingFeature)
5. 打开一个 Pull Request

## 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详细信息

# TOTP验证修复指南

## 问题描述

在不同时区的服务器上，Google验证器(TOTP)验证可能会失败，因为服务器时间与用户设备时间存在时区差异。

## 解决方案

我们提供了一个修复脚本`fix_totp.sh`，它会修改TOTP验证函数，增加时间偏移容忍度，允许前后1分钟的验证码有效。

## 使用方法

1. 将`fix_totp.sh`上传到服务器
2. 赋予执行权限：
   ```bash
   chmod +x fix_totp.sh
   ```
3. 以root权限运行脚本：
   ```bash
   sudo ./fix_totp.sh
   ```

## 脚本功能

脚本会执行以下操作：

1. 备份原始的`api.go`文件
2. 修改`validateTOTP`函数，增加时间偏移容忍度
3. 添加新的`validateTOTPAtTime`函数
4. 确保所需的导入包都已添加
5. 重新编译应用
6. 重启服务

## 修复后的效果

修复后，即使服务器与用户设备存在时区差异，TOTP验证也能正常工作。用户可以使用Google验证器生成的验证码成功登录系统。

## 注意事项

- 脚本需要root权限运行
- 脚本会自动备份原始文件，备份文件名格式为`api.go.bak.YYYYMMDDHHMMSS`
- 如果修复失败，可以使用备份文件恢复原始状态

## 技术细节

修复的核心是在验证TOTP码时，不仅验证当前时间的码，还验证前后1分钟时间点的码：

```go
// 增加时间偏移容忍度，允许前后1分钟的验证码
now := time.Now()
for _, offset := range []int{-60, -30, 0, 30, 60} {
    testTime := now.Add(time.Duration(offset) * time.Second)
    if validateTOTPAtTime(keyBytes, codeNum, testTime) {
        return true
    }
}
```

这样即使服务器与用户设备存在时间差，只要在合理范围内（±1分钟），验证码仍然有效。 