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