#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 应用目录
APP_DIR="/opt/openp2p"
CONFIG_DIR="$APP_DIR/config"
DEPS_FLAG="$APP_DIR/.deps_installed"
FRONTEND_DIR="$APP_DIR/frontend"

# 打印带颜色的信息
print_info() {
    echo -e "${GREEN}[INFO] $1${NC}"
}

print_warn() {
    echo -e "${YELLOW}[WARN] $1${NC}"
}

print_error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

print_step() {
    echo -e "${BLUE}[STEP] $1${NC}"
}

# 显示菜单
show_menu() {
    clear
    echo "============================================"
    echo "          OpenP2P 部署脚本                  "
    echo "============================================"
    echo "请选择部署选项:"
    echo "1) 前端单独部署"
    echo "2) 后端单独部署"
    echo "3) 前端+后端部署 (同一服务器)"
    echo "4) 清理项目文件"
    echo "0) 退出"
    echo "============================================"
    read -p "请输入选项 [0-4]: " choice
}

# 检查命令是否存在
check_command() {
    if ! command -v $1 &> /dev/null; then
        if [ "$1" = "go" ] && [ -x "/usr/local/go/bin/go" ]; then
            # 如果是 go 命令且存在于标准安装路径
            export PATH=$PATH:/usr/local/go/bin
            return 0
        fi
        print_error "$1 未安装"
        return 1
    fi
    return 0
}

# 检查端口是否被占用
check_port() {
    if lsof -i:"$1" >/dev/null 2>&1; then
        return 1
    fi
    return 0
}

# 检查是否为root用户
check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "请使用root权限运行此脚本"
        exit 1
    fi
}

# 检查OpenP2P服务是否已安装
check_existing_installation() {
    print_step "检查现有安装..."
    
    local existing_installation=false
    
    # 检查服务文件
    if [ -f "/etc/systemd/system/openp2p.service" ]; then
        print_info "检测到OpenP2P服务已安装"
        existing_installation=true
    fi
    
    # 检查应用目录
    if [ -d "$APP_DIR" ] && [ -f "$APP_DIR/openp2p" ]; then
        print_info "检测到OpenP2P应用文件"
        existing_installation=true
    fi
    
    # 检查Nginx配置
    if [ -f "/etc/nginx/conf.d/openp2p.conf" ]; then
        print_info "检测到OpenP2P Nginx配置"
        existing_installation=true
    fi
    
    # 检查端口占用
    local port_occupied=false
    if ! check_port 27183; then
        print_warn "API端口 27183 已被占用"
        port_occupied=true
    fi
    
    if ! check_port 27182; then
        print_warn "P2P端口 27182 已被占用"
        port_occupied=true
    fi
    
    # 如果检测到现有安装或端口占用
    if [ "$existing_installation" = true ] || [ "$port_occupied" = true ]; then
        print_warn "检测到现有OpenP2P安装或端口占用"
        print_warn "继续操作可能会覆盖现有配置或导致端口冲突"
        read -p "是否继续? [y/N]: " continue_choice
        if [[ ! $continue_choice =~ ^[Yy]$ ]]; then
            print_info "操作已取消"
            exit 0
        fi
        print_info "继续部署..."
    fi
}

# 备份Nginx配置
backup_nginx_config() {
    print_info "备份现有 Nginx 配置..."
    NGINX_BACKUP_DIR="/etc/nginx/backup_$(date +%Y%m%d%H%M%S)"
    mkdir -p "$NGINX_BACKUP_DIR"
    cp -r /etc/nginx/conf.d "$NGINX_BACKUP_DIR/" 2>/dev/null || true
    cp -r /etc/nginx/sites-enabled "$NGINX_BACKUP_DIR/" 2>/dev/null || true
    print_info "Nginx 配置已备份到: $NGINX_BACKUP_DIR"
}

# 安装系统依赖
install_dependencies() {
    # 如果依赖已安装，跳过
    if [ -f "$DEPS_FLAG" ]; then
        print_info "系统依赖已安装，跳过安装步骤"
        return 0
    fi

    print_step "安装系统依赖..."
    
    # 更新系统
    print_info "正在更新系统..."
    apt update && apt upgrade -y || {
        print_error "系统更新失败"
        exit 1
    }

    # 检查并安装必要的软件包
    print_info "检查必要的软件包..."
    PACKAGES_TO_INSTALL=""

    # 基础工具
    for cmd in wget git curl lsof host; do
        if ! check_command $cmd; then
            PACKAGES_TO_INSTALL="$PACKAGES_TO_INSTALL $cmd"
        fi
    done

    # Nginx
    if ! check_command nginx; then
        PACKAGES_TO_INSTALL="$PACKAGES_TO_INSTALL nginx"
    fi

    # Certbot
    if ! check_command certbot; then
        PACKAGES_TO_INSTALL="$PACKAGES_TO_INSTALL certbot python3-certbot-nginx"
    fi

    # 安装缺失的包
    if [ ! -z "$PACKAGES_TO_INSTALL" ]; then
        print_info "正在安装缺失的软件包: $PACKAGES_TO_INSTALL"
        apt install -y $PACKAGES_TO_INSTALL || {
            print_error "软件包安装失败"
            exit 1
        }
    else
        print_info "所有基础软件包已安装"
    fi

    # 创建依赖安装标志文件
    mkdir -p "$APP_DIR"
    touch "$DEPS_FLAG"
    print_info "系统依赖安装完成"
}

# 安装Go环境
install_go() {
    print_step "配置Go环境..."
    
    if ! check_command go; then
        print_info "Go未安装，开始安装..."
        # 下载并安装Go
        wget https://go.dev/dl/go1.22.0.linux-amd64.tar.gz || {
            print_error "Go下载失败"
            exit 1
        }
        rm -rf /usr/local/go
        tar -C /usr/local -xzf go1.22.0.linux-amd64.tar.gz || {
            print_error "Go解压失败"
            exit 1
        }
        rm go1.22.0.linux-amd64.tar.gz

        # 配置Go环境变量
        cat > /etc/profile.d/go.sh << EOF
export PATH=\$PATH:/usr/local/go/bin
export GOPATH=\$HOME/go
export GOBIN=\$GOPATH/bin
export PATH=\$PATH:\$GOBIN
EOF
        
        # 使环境变量立即生效
        source /etc/profile.d/go.sh
        export PATH=$PATH:/usr/local/go/bin
        
        # 验证Go安装
        if ! go version &> /dev/null; then
            print_error "Go安装失败"
            exit 1
        else
            print_info "Go安装成功，版本信息："
            go version
        fi
    else
        # 检查已安装的Go版本
        CURRENT_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
        REQUIRED_VERSION="1.22.0"
        
        if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$CURRENT_VERSION" | sort -V | head -n1)" = "$CURRENT_VERSION" ] && [ "$CURRENT_VERSION" != "$REQUIRED_VERSION" ]; then
            print_warn "当前Go版本($CURRENT_VERSION)低于要求的$REQUIRED_VERSION版本，正在更新..."
            rm -rf /usr/local/go
            wget https://go.dev/dl/go1.22.0.linux-amd64.tar.gz || {
                print_error "Go下载失败"
                exit 1
            }
            tar -C /usr/local -xzf go1.22.0.linux-amd64.tar.gz || {
                print_error "Go解压失败"
                exit 1
            }
            rm go1.22.0.linux-amd64.tar.gz
            
            # 确保环境变量配置存在
            if [ ! -f "/etc/profile.d/go.sh" ]; then
                cat > /etc/profile.d/go.sh << EOF
export PATH=\$PATH:/usr/local/go/bin
export GOPATH=\$HOME/go
export GOBIN=\$GOPATH/bin
export PATH=\$PATH:\$GOBIN
EOF
            fi
            
            # 使环境变量立即生效
            source /etc/profile.d/go.sh
            export PATH=$PATH:/usr/local/go/bin
            
            print_info "Go更新成功，新版本信息："
            go version
        else
            print_info "Go已安装且版本满足要求，版本信息："
            go version
        fi
    fi

    # 确保Go环境变量生效
    if [ ! -f "/etc/profile.d/go.sh" ]; then
        cat > /etc/profile.d/go.sh << EOF
export PATH=\$PATH:/usr/local/go/bin
export GOPATH=\$HOME/go
export GOBIN=\$GOPATH/bin
export PATH=\$PATH:\$GOBIN
EOF
        source /etc/profile.d/go.sh
    fi

    # 编译前确保Go命令可用
    export PATH=$PATH:/usr/local/go/bin
    
    # 验证Go环境
    if ! go version &> /dev/null; then
        print_error "Go环境配置失败，请手动检查"
        exit 1
    fi
}

# 安装Node.js环境
install_nodejs() {
    print_step "配置Node.js环境..."
    
    if ! check_command node || ! check_command npm; then
        print_info "Node.js未安装，开始安装..."
        
        # 安装Node.js 16.x
        curl -fsSL https://deb.nodesource.com/setup_16.x | bash - || {
            print_error "Node.js源配置失败"
            exit 1
        }
        
        apt install -y nodejs || {
            print_error "Node.js安装失败"
            exit 1
        }
        
        # 验证Node.js安装
        if ! node -v &> /dev/null || ! npm -v &> /dev/null; then
            print_error "Node.js安装失败"
            exit 1
        else
            print_info "Node.js安装成功，版本信息："
            node -v
            npm -v
        fi
    else
        print_info "Node.js已安装，版本信息："
        node -v
        npm -v
    fi
}

# 克隆代码
clone_code() {
    print_step "克隆/更新代码..."
    
    # 检查是否存在.git目录
    if [ -d "$APP_DIR/.git" ]; then
        print_info "代码仓库已存在，正在更新..."
        cd "$APP_DIR"
        git reset --hard
        git clean -fd
        git pull || {
            print_error "代码更新失败"
            exit 1
        }
        print_info "代码更新成功"
        return 0
    fi
    
    # 如果不存在.git目录，需要克隆代码
    print_info "准备克隆代码..."
    
    # 备份依赖安装标志文件
    DEPS_INSTALLED=false
    if [ -f "$DEPS_FLAG" ]; then
        print_info "备份依赖安装标志..."
        DEPS_INSTALLED=true
        cp "$DEPS_FLAG" /tmp/deps_installed_flag
    fi
    
    # 创建临时目录进行克隆
    TEMP_DIR=$(mktemp -d)
    print_info "使用临时目录: $TEMP_DIR"
    
    # 克隆代码到临时目录
    print_info "克隆代码仓库到临时目录..."
    git clone https://github.com/senma231/openp2p.git "$TEMP_DIR" || {
        print_error "代码克隆失败"
        rm -rf "$TEMP_DIR"
        exit 1
    }
    
    # 完全删除并重新创建应用目录
    print_warn "重新创建应用目录..."
    rm -rf "$APP_DIR"
    mkdir -p "$APP_DIR"
    
    # 将临时目录中的内容移动到应用目录
    print_info "移动代码到应用目录..."
    cp -a "$TEMP_DIR/." "$APP_DIR/"
    
    # 清理临时目录
    rm -rf "$TEMP_DIR"
    
    # 恢复依赖安装标志文件
    if [ "$DEPS_INSTALLED" = true ]; then
        print_info "恢复依赖安装标志..."
        mkdir -p "$(dirname "$DEPS_FLAG")"
        cp /tmp/deps_installed_flag "$DEPS_FLAG"
        rm -f /tmp/deps_installed_flag
    fi
    
    # 设置正确的目录权限
    print_info "设置目录权限..."
    chmod 755 "$APP_DIR"
    
    print_info "代码克隆成功"
}

# 修复源代码中的环境变量处理问题
fix_source_code() {
    print_step "修复源代码..."
    
    # 检查openp2p.go文件
    OPENP2P_GO_FILE="$APP_DIR/source/cmd/openp2p.go"
    if [ -f "$OPENP2P_GO_FILE" ]; then
        print_info "修改openp2p.go文件，将isDev默认值改为false..."
        
        # 创建备份
        cp "$OPENP2P_GO_FILE" "${OPENP2P_GO_FILE}.bak"
        
        # 修改isDev默认值
        sed -i 's/var isDev = flag.Bool("dev", true, "Run in development mode")/var isDev = flag.Bool("dev", false, "Run in development mode")/' "$OPENP2P_GO_FILE"
        
        # 检查修改是否成功
        if grep -q 'var isDev = flag.Bool("dev", false, "Run in development mode")' "$OPENP2P_GO_FILE"; then
            print_info "成功修改 isDev 默认值为 false"
        else
            print_warn "修改 isDev 默认值失败，尝试直接替换文件内容..."
            
            # 直接替换文件内容
            cat > "$OPENP2P_GO_FILE" << 'EOF'
package main

import (
        "flag"
        "log"

        "openp2p/core"
)

var isDev = flag.Bool("dev", false, "Run in development mode")

func main() {
        flag.Parse()

        // 设置开发模式
        if *isDev {
                log.Println("Running in development mode")
        } else {
                log.Println("Running in production mode")
        }

        // 初始化配置
        err := core.InitConfig()
        if err != nil {
                log.Fatal(err)
        }

        // 在开发模式下跳过 P2P 网络初始化
        if !*isDev {
                err = core.InitP2PNetwork()
                if err != nil {
                        log.Printf("P2P network initialization error: %v", err)
                        // 在开发模式下不因 P2P 初始化失败而退出
                        if !*isDev {
                                log.Fatal(err)
                        }
                }
        }

        // 初始化 API 路由
        core.InitAPIRoutes()

        // 保持程序运行
        select {}
}
EOF
            print_info "openp2p.go文件已替换"
        fi
    else
        print_error "找不到openp2p.go文件: $OPENP2P_GO_FILE"
    fi
    
    # 检查main.go文件 (如果存在)
    MAIN_GO_FILE="$APP_DIR/source/cmd/main.go"
    if [ -f "$MAIN_GO_FILE" ]; then
        print_info "修改main.go文件，确保正确处理环境变量..."
        
        # 创建备份
        cp "$MAIN_GO_FILE" "${MAIN_GO_FILE}.bak"
        
        # 直接修改main.go文件内容
        cat > "$MAIN_GO_FILE" << 'EOF'
package main

import (
	"fmt"
	"log"
	"os"
	"path/filepath"

	"github.com/senma231/openp2p/source/cmd/api"
	"github.com/senma231/openp2p/source/cmd/config"
	"github.com/senma231/openp2p/source/cmd/p2p"
)

func main() {
	// 强制使用生产模式
	os.Setenv("OPENP2P_ENV", "production")
	os.Setenv("GO_ENV", "production")
	os.Setenv("GIN_MODE", "release")
	
	log.Println("Running in production mode")
	
	// 加载配置
	configPath := filepath.Join("config", "env.json")
	if _, err := os.Stat(configPath); os.IsNotExist(err) {
		log.Println("Config file not found, using default settings")
	}
	
	cfg := config.LoadConfig(configPath)
	
	// 强制覆盖配置
	cfg.IsDevelopment = false
	cfg.BindAddress = "0.0.0.0"
	
	// 打印配置信息
	fmt.Printf("Configuration: %+v\n", cfg)
	
	// 启动API服务器
	go func() {
		log.Printf("Starting HTTP server on %s:%d in production mode", cfg.BindAddress, cfg.APIPort)
		if err := api.StartServer(cfg); err != nil {
			log.Fatalf("Failed to start API server: %v", err)
		}
	}()
	
	// 启动P2P服务
	log.Printf("Starting P2P server on %s:%d", cfg.BindAddress, cfg.P2PPort)
	if err := p2p.StartServer(cfg); err != nil {
		log.Fatalf("Failed to start P2P server: %v", err)
	}
}
EOF
        
        print_info "main.go文件已修改"
    else
        print_info "main.go文件不存在，跳过修改"
    fi
    
    # 检查API服务器文件
    API_FILE="$APP_DIR/source/cmd/api/api.go"
    if [ -f "$API_FILE" ]; then
        print_info "修改api.go文件，确保正确绑定端口..."
        
        # 创建备份
        cp "$API_FILE" "${API_FILE}.bak"
        
        # 查找并替换监听地址
        sed -i 's/localhost:/0.0.0.0:/g' "$API_FILE"
        sed -i 's/127.0.0.1:/0.0.0.0:/g' "$API_FILE"
        
        # 如果文件中包含gin框架的初始化，确保使用生产模式
        if grep -q "gin.New" "$API_FILE"; then
            print_info "检测到Gin框架，设置为生产模式..."
            sed -i 's/gin.New()/gin.New()\n\tgin.SetMode(gin.ReleaseMode)/g' "$API_FILE"
            sed -i 's/gin.Default()/gin.New()\n\tgin.SetMode(gin.ReleaseMode)/g' "$API_FILE"
        fi
        
        print_info "api.go文件已修改"
    else
        print_warn "找不到api.go文件: $API_FILE"
    fi
    
    # 检查P2P服务器文件
    P2P_FILE="$APP_DIR/source/cmd/p2p/p2p.go"
    if [ -f "$P2P_FILE" ]; then
        print_info "修改p2p.go文件，确保正确绑定端口..."
        
        # 创建备份
        cp "$P2P_FILE" "${P2P_FILE}.bak"
        
        # 查找并替换监听地址
        sed -i 's/localhost:/0.0.0.0:/g' "$P2P_FILE"
        sed -i 's/127.0.0.1:/0.0.0.0:/g' "$P2P_FILE"
        
        print_info "p2p.go文件已修改"
    else
        print_warn "找不到p2p.go文件: $P2P_FILE"
    fi
    
    # 检查配置文件处理代码
    CONFIG_FILE="$APP_DIR/source/cmd/config/config.go"
    if [ -f "$CONFIG_FILE" ]; then
        print_info "修改config.go文件，确保正确加载配置..."
        
        # 创建备份
        cp "$CONFIG_FILE" "${CONFIG_FILE}.bak"
        
        # 修改配置文件加载逻辑
        cat > "$CONFIG_FILE" << 'EOF'
package config

import (
	"encoding/json"
	"io/ioutil"
	"log"
	"os"
)

// Config 应用配置
type Config struct {
	IsDevelopment bool   `json:"is_development"`
	LogLevel      string `json:"log_level"`
	APIPort       int    `json:"api_port"`
	P2PPort       int    `json:"p2p_port"`
	BindAddress   string `json:"bind_address"`
}

// LoadConfig 加载配置文件
func LoadConfig(path string) *Config {
	// 默认配置
	config := &Config{
		IsDevelopment: false, // 强制使用生产模式
		LogLevel:      "info",
		APIPort:       27183,
		P2PPort:       27182,
		BindAddress:   "0.0.0.0", // 绑定到所有接口
	}

	// 检查环境变量
	if os.Getenv("OPENP2P_ENV") == "production" {
		log.Println("Environment variable OPENP2P_ENV=production detected")
		config.IsDevelopment = false
	}

	// 尝试从文件加载配置
	data, err := ioutil.ReadFile(path)
	if err != nil {
		log.Printf("无法读取配置文件: %v，使用默认配置", err)
		return config
	}

	// 解析配置文件
	if err := json.Unmarshal(data, config); err != nil {
		log.Printf("解析配置文件失败: %v，使用默认配置", err)
		return config
	}

	// 强制覆盖某些设置
	config.IsDevelopment = false // 始终使用生产模式
	if config.BindAddress == "" || config.BindAddress == "localhost" || config.BindAddress == "127.0.0.1" {
		config.BindAddress = "0.0.0.0" // 确保绑定到所有接口
	}

	// 打印最终配置
	log.Printf("Loaded configuration: IsDevelopment=%v, APIPort=%d, P2PPort=%d, BindAddress=%s",
		config.IsDevelopment, config.APIPort, config.P2PPort, config.BindAddress)

	return config
}
EOF
        
        print_info "config.go文件已修改"
    else
        print_warn "找不到config.go文件: $CONFIG_FILE"
    fi
    
    # 检查API路由文件
    ROUTES_FILE="$APP_DIR/source/cmd/api/routes.go"
    if [ -f "$ROUTES_FILE" ]; then
        print_info "检查API路由文件，确保正确处理前端请求..."
        
        # 创建备份
        cp "$ROUTES_FILE" "${ROUTES_FILE}.bak"
        
        # 添加CORS中间件
        sed -i '/package api/a\\nimport (\n\t"github.com/gin-gonic/gin"\n\t"net/http"\n)' "$ROUTES_FILE"
        
        # 添加CORS中间件函数
        cat >> "$ROUTES_FILE" << 'EOF'

// CORSMiddleware 处理跨域请求
func CORSMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Writer.Header().Set("Access-Control-Allow-Origin", "*")
		c.Writer.Header().Set("Access-Control-Allow-Credentials", "true")
		c.Writer.Header().Set("Access-Control-Allow-Headers", "Content-Type, Content-Length, Accept-Encoding, X-CSRF-Token, Authorization, accept, origin, Cache-Control, X-Requested-With")
		c.Writer.Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS, GET, PUT, DELETE")

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(http.StatusNoContent)
			return
		}

		c.Next()
	}
}
EOF
        
        # 修改路由设置，添加CORS中间件
        sed -i 's/r := gin.New()/r := gin.New()\n\tr.Use(CORSMiddleware())\n\tr.Use(gin.Recovery())/g' "$ROUTES_FILE"
        
        print_info "API路由文件已修改"
    else
        print_warn "找不到API路由文件: $ROUTES_FILE"
    fi
    
    # 修改systemd服务文件
    SYSTEMD_FILE="/etc/systemd/system/openp2p.service"
    if [ -f "$SYSTEMD_FILE" ]; then
        print_info "修改systemd服务文件，添加--dev=false参数..."
        
        # 检查是否已包含--dev=false参数
        if ! grep -q -- "--dev=false" "$SYSTEMD_FILE"; then
            # 添加--dev=false参数到ExecStart行
            sed -i 's|^ExecStart=.*$|& --dev=false|' "$SYSTEMD_FILE"
            print_info "已添加--dev=false参数到systemd服务文件"
        else
            print_info "systemd服务文件已包含--dev=false参数"
        fi
    fi
    
    print_info "源代码修复完成"
    return 0
}

# 编译后端
build_backend() {
    print_step "编译后端..."
    
    # 修复源代码
    fix_source_code || {
        print_warn "源代码修复失败，继续使用原始代码"
    }
    
    # 检查Go环境
    print_info "检查Go环境..."
    go version || {
        print_error "Go环境检查失败"
        exit 1
    }
    
    # 获取系统架构信息
    print_info "检测系统架构..."
    ARCH=$(uname -m)
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    
    print_info "系统架构: $ARCH, 操作系统: $OS"
    
    # 创建一个简单的测试程序来验证Go编译环境
    print_info "验证Go编译环境..."
    TEST_DIR=$(mktemp -d)
    cat > "$TEST_DIR/main.go" << 'EOF'
package main

import (
    "fmt"
    "os"
    "runtime"
)

func main() {
    fmt.Printf("Go version: %s\n", runtime.Version())
    fmt.Printf("GOOS: %s\n", runtime.GOOS)
    fmt.Printf("GOARCH: %s\n", runtime.GOARCH)
    fmt.Printf("Working directory: %s\n", os.Getenv("PWD"))
    fmt.Println("Test program executed successfully!")
}
EOF

    # 编译并运行测试程序
    cd "$TEST_DIR"
    go build -o test_program main.go && {
        chmod +x test_program
        print_info "测试程序编译成功，执行结果:"
        ./test_program || print_error "测试程序执行失败"
    } || {
        print_error "测试程序编译失败"
    }
    
    # 清理测试目录
    rm -rf "$TEST_DIR"
    
    # 进入源代码目录
    cd "$APP_DIR/source/cmd"
    
    # 安装依赖
    print_info "安装Go依赖..."
    go mod tidy || {
        print_error "Go依赖安装失败"
        exit 1
    }
    
    # 使用本地编译（不使用交叉编译）
    print_info "使用本地编译模式..."
    go build -o "$APP_DIR/openp2p" || {
        print_error "Go编译失败"
        exit 1
    }
    
    # 设置执行权限
    chmod +x "$APP_DIR/openp2p"
    
    # 检查编译后的二进制文件
    print_info "检查编译后的二进制文件..."
    file "$APP_DIR/openp2p"
    
    # 创建配置文件
    mkdir -p "$CONFIG_DIR"
    cat > "$CONFIG_DIR/env.json" << EOF
{
    "is_development": false,
    "log_level": "info",
    "api_port": 27183,
    "p2p_port": 27182,
    "bind_address": "0.0.0.0"
}
EOF

    print_info "后端编译完成"
}

# 检查二进制文件是否可执行
check_binary() {
    local binary_path="$1"
    
    print_info "检查二进制文件: $binary_path"
    
    # 检查文件是否存在
    if [ ! -f "$binary_path" ]; then
        print_error "二进制文件不存在: $binary_path"
        return 1
    fi
    
    # 检查文件权限
    if [ ! -x "$binary_path" ]; then
        print_warn "二进制文件没有执行权限，添加执行权限..."
        chmod +x "$binary_path"
    fi
    
    # 检查文件类型
    file_type=$(file "$binary_path")
    print_info "文件类型: $file_type"
    
    # 检查是否为ELF可执行文件
    if ! echo "$file_type" | grep -q "ELF"; then
        print_error "文件不是ELF可执行文件"
        return 1
    fi
    
    # 尝试执行文件（带参数--version或--help）
    if "$binary_path" --version &>/dev/null || "$binary_path" --help &>/dev/null; then
        print_info "二进制文件可以执行"
        return 0
    else
        # 如果带参数执行失败，尝试不带参数执行（会立即退出）
        timeout 1 "$binary_path" &>/dev/null
        local exit_code=$?
        if [ $exit_code -ne 124 ]; then  # 124是timeout的退出码
            print_info "二进制文件可以执行（退出码: $exit_code）"
            return 0
        else
            print_error "二进制文件无法执行"
            return 1
        fi
    fi
}

# 编译前端
build_frontend() {
    print_step "编译前端..."
    
    # 安装前端依赖并构建
    cd "$APP_DIR/source/web"
    
    # 设置API地址
    if [ ! -z "$DOMAIN" ]; then
        # 如果是前后端同时部署，使用相对路径
        if [ "$DEPLOY_TYPE" = "full" ]; then
            echo "VITE_API_URL=/api" > .env.production
            print_info "设置API地址为相对路径: /api"
        else
            # 否则使用完整URL
            echo "VITE_API_URL=https://$DOMAIN" > .env.production
            print_info "设置API地址为: https://$DOMAIN"
        fi
    else
        print_error "未设置域名，无法配置API地址"
        exit 1
    fi
    
    # 增加Node.js内存限制
    print_info "设置Node.js内存限制..."
    export NODE_OPTIONS="--max-old-space-size=4096"
    
    # 安装依赖
    print_info "安装前端依赖..."
    npm install --no-fund --no-audit || {
        print_error "前端依赖安装失败"
        exit 1
    }
    
    # 构建前端
    print_info "构建前端..."
    npm run build || {
        print_error "前端构建失败，尝试增加内存限制..."
        # 如果构建失败，尝试增加更多内存
        export NODE_OPTIONS="--max-old-space-size=8192"
        npm run build || {
            print_error "前端构建再次失败，可能需要更多内存或清理系统资源"
            print_info "您可以尝试手动运行以下命令:"
            print_info "cd $APP_DIR/source/web && NODE_OPTIONS='--max-old-space-size=8192' npm run build"
            exit 1
        }
    }
    
    # 检查构建结果
    print_info "检查构建结果..."
    if [ ! -d "dist" ]; then
        print_error "构建目录不存在: dist"
        exit 1
    fi
    
    if [ ! -f "dist/index.html" ]; then
        print_error "构建结果不完整，缺少index.html文件"
        exit 1
    fi
    
    # 设置dist目录权限
    print_info "设置dist目录权限..."
    chmod -R 755 dist
    
    # 如果使用前端单独部署，则复制到FRONTEND_DIR
    if [ "$DEPLOY_TYPE" = "frontend" ]; then
        # 创建前端目录
        mkdir -p "$FRONTEND_DIR"
        
        # 复制构建结果
        print_info "复制构建结果到前端目录..."
        cp -r dist/* "$FRONTEND_DIR/"
        
        # 设置前端目录权限
        chmod -R 755 "$FRONTEND_DIR"
    fi
    
    print_info "前端编译完成"
}

# 配置Nginx
configure_nginx() {
    print_step "配置Nginx..."
    
    # 备份现有配置
    backup_nginx_config
    
    # 创建Nginx配置
    if [ "$DEPLOY_TYPE" = "frontend" ]; then
        # 前端配置
        cat > /etc/nginx/conf.d/openp2p.conf << EOF
server {
    listen 80;
    server_name $DOMAIN;
    
    # 错误日志配置
    error_log /var/log/nginx/openp2p_error.log warn;
    access_log /var/log/nginx/openp2p_access.log;
    
    location / {
        root $FRONTEND_DIR;
        index index.html;
        try_files \$uri \$uri/ /index.html;
    }
}
EOF
    elif [ "$DEPLOY_TYPE" = "backend" ]; then
        # 后端配置
        cat > /etc/nginx/conf.d/openp2p.conf << EOF
server {
    listen 80;
    server_name $DOMAIN;
    
    # 错误日志配置
    error_log /var/log/nginx/openp2p_error.log warn;
    access_log /var/log/nginx/openp2p_access.log;
    
    # CORS 配置
    add_header 'Access-Control-Allow-Origin' '*' always;
    add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS' always;
    add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization' always;
    add_header 'Access-Control-Expose-Headers' 'Content-Length,Content-Range' always;
    add_header 'Access-Control-Allow-Credentials' 'true' always;
    
    # 预检请求处理
    if (\$request_method = 'OPTIONS') {
        add_header 'Access-Control-Allow-Origin' '*';
        add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS';
        add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization';
        add_header 'Access-Control-Allow-Credentials' 'true';
        add_header 'Access-Control-Max-Age' 1728000;
        add_header 'Content-Type' 'text/plain; charset=utf-8';
        add_header 'Content-Length' 0;
        return 204;
    }
    
    location / {
        proxy_pass http://localhost:27183;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        
        # 超时设置
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
EOF
    elif [ "$DEPLOY_TYPE" = "full" ]; then
        # 前后端同时部署配置
        cat > /etc/nginx/conf.d/openp2p.conf << EOF
server {
    listen 80;
    server_name $DOMAIN;
    
    # 错误日志配置
    error_log /var/log/nginx/openp2p_error.log warn;
    access_log /var/log/nginx/openp2p_access.log;
    
    # 前端静态文件
    location / {
        root $APP_DIR/source/web/dist;
        index index.html;
        try_files \$uri \$uri/ /index.html;
    }
    
    # API请求
    location /api {
        # CORS 配置
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS' always;
        add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization' always;
        add_header 'Access-Control-Expose-Headers' 'Content-Length,Content-Range' always;
        add_header 'Access-Control-Allow-Credentials' 'true' always;
        
        # 预检请求处理
        if (\$request_method = 'OPTIONS') {
            add_header 'Access-Control-Allow-Origin' '*';
            add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS';
            add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization';
            add_header 'Access-Control-Allow-Credentials' 'true';
            add_header 'Access-Control-Max-Age' 1728000;
            add_header 'Content-Type' 'text/plain; charset=utf-8';
            add_header 'Content-Length' 0;
            return 204;
        }
        
        # 不再去掉/api前缀
        # rewrite ^/api/(.*) /\$1 break;
        
        proxy_pass http://localhost:27183;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        
        # 超时设置
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
EOF
    fi
    
    # 测试Nginx配置
    nginx -t || {
        print_error "Nginx配置测试失败"
        return 1
    }
    
    # 重启Nginx
    systemctl restart nginx || {
        print_error "Nginx重启失败"
        return 1
    }
    
    print_info "Nginx配置完成"
    return 0
}

# 配置SSL证书
configure_ssl() {
    print_step "配置SSL证书..."
    
    echo "请选择SSL证书类型:"
    echo "1) 使用Let's Encrypt自动申请证书"
    echo "2) 使用Cloudflare证书"
    read -p "请选择 [1-2]: " ssl_choice
    
    case $ssl_choice in
        1)
            # 使用Let's Encrypt
            print_info "使用Let's Encrypt申请证书..."
            
            # 检查域名解析
            print_info "检查域名 $DOMAIN 的DNS解析..."
            if ! host $DOMAIN &>/dev/null; then
                print_warn "域名 $DOMAIN 解析失败，请确保域名已正确解析到本服务器IP"
                read -p "是否继续? [y/N]: " continue_choice
                if [[ ! $continue_choice =~ ^[Yy]$ ]]; then
                    print_info "已取消证书申请"
                    return 1
                fi
            fi
            
            # 申请证书
            certbot --nginx -d $DOMAIN --non-interactive --agree-tos --email admin@$DOMAIN || {
                print_error "证书申请失败"
                return 1
            }
            
            print_info "Let's Encrypt证书申请成功"
            ;;
            
        2)
            # 使用Cloudflare证书
            print_info "使用Cloudflare证书..."
            print_info "请按照以下步骤操作:"
            echo "1. 登录Cloudflare控制面板"
            echo "2. 确保域名 $DOMAIN 已添加到Cloudflare并启用了代理(橙色云朵)"
            echo "3. 在SSL/TLS设置中，将加密模式设置为'灵活'"
            echo "4. 确保'始终使用HTTPS'选项已启用"
            
            read -p "已完成上述步骤? [y/N]: " cf_ready
            if [[ ! $cf_ready =~ ^[Yy]$ ]]; then
                print_info "已取消证书配置"
                return 1
            fi
            
            print_info "Cloudflare证书配置完成"
            ;;
            
        *)
            print_error "无效的选择"
            return 1
            ;;
    esac
    
    return 0
}

# 配置systemd服务
configure_systemd() {
    print_step "配置systemd服务..."
    
    # 创建自定义启动脚本
    create_startup_script
    
    cat > /etc/systemd/system/openp2p.service << EOF
[Unit]
Description=OpenP2P Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$APP_DIR
ExecStart=/bin/bash $APP_DIR/start.sh
Restart=always
RestartSec=5
Environment=OPENP2P_ENV=production
Environment=GO_ENV=production
Environment=GIN_MODE=release

[Install]
WantedBy=multi-user.target
EOF

    # 重新加载systemd配置
    systemctl daemon-reload
    
    # 启用并启动服务
    systemctl enable openp2p
    
    # 确保服务停止后再启动
    if systemctl is-active --quiet openp2p; then
        print_info "停止现有OpenP2P服务..."
        systemctl stop openp2p
        sleep 2
    fi
    
    print_info "启动OpenP2P服务..."
    systemctl start openp2p || {
        print_error "OpenP2P服务启动失败"
        print_info "查看服务日志:"
        journalctl -u openp2p -n 20 --no-pager
        return 1
    }
    
    # 检查服务状态
    sleep 2
    if ! systemctl is-active --quiet openp2p; then
        print_error "OpenP2P服务启动后未能保持运行"
        print_info "查看服务日志:"
        journalctl -u openp2p -n 20 --no-pager
        return 1
    fi
    
    # 检查端口监听
    sleep 5  # 增加等待时间，确保服务完全启动
    if ! lsof -i:27183 >/dev/null 2>&1; then
        print_warn "API端口 27183 未监听，尝试检查日志..."
        journalctl -u openp2p -n 50 --no-pager
    else
        print_info "API端口 27183 已正常监听"
    fi
    
    if ! lsof -i:27182 >/dev/null 2>&1; then
        print_warn "P2P端口 27182 未监听，尝试检查日志..."
        journalctl -u openp2p -n 50 --no-pager
    else
        print_info "P2P端口 27182 已正常监听"
    fi
    
    print_info "systemd服务配置完成"
    return 0
}

# 创建自定义启动脚本
create_startup_script() {
    print_step "创建自定义启动脚本..."
    
    # 创建启动脚本
    cat > "$APP_DIR/start.sh" << 'EOF'
#!/bin/bash

# 设置环境变量
export OPENP2P_ENV=production
export GO_ENV=production
export GIN_MODE=release

# 确保配置目录存在
mkdir -p ./config

# 创建或更新配置文件
cat > ./config/env.json << EOFCFG
{
    "is_development": false,
    "log_level": "info",
    "api_port": 27183,
    "p2p_port": 27182,
    "bind_address": "0.0.0.0"
}
EOFCFG

# 检查二进制文件权限
if [ ! -x ./openp2p ]; then
    echo "添加执行权限到二进制文件..."
    chmod +x ./openp2p
fi

# 显示二进制文件信息
echo "二进制文件信息:"
file ./openp2p

# 启动应用
exec ./openp2p --dev=false
EOF

    # 设置执行权限
    chmod +x "$APP_DIR/start.sh"
    
    print_info "自定义启动脚本已创建"
}

# 清理项目文件
cleanup_project() {
    print_step "清理项目文件..."
    
    # 确认清理
    print_warn "此操作将删除所有OpenP2P相关文件和配置"
    read -p "是否继续? [y/N]: " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        print_info "已取消清理操作"
        return 0
    fi
    
    # 停止服务
    if systemctl is-active --quiet openp2p; then
        print_info "停止OpenP2P服务..."
        systemctl stop openp2p
        systemctl disable openp2p
    fi
    
    # 删除服务文件
    if [ -f "/etc/systemd/system/openp2p.service" ]; then
        print_info "删除systemd服务文件..."
        rm -f /etc/systemd/system/openp2p.service
        systemctl daemon-reload
    fi
    
    # 删除Nginx配置
    if [ -f "/etc/nginx/conf.d/openp2p.conf" ]; then
        print_info "删除Nginx配置..."
        rm -f /etc/nginx/conf.d/openp2p.conf
        systemctl restart nginx
    fi
    
    # 删除项目文件
    if [ -d "$APP_DIR" ]; then
        print_info "删除项目文件..."
        rm -rf "$APP_DIR"
    fi
    
    print_info "项目清理完成"
    return 0
}

# 部署前端
deploy_frontend() {
    print_step "开始前端部署..."
    
    # 获取域名
    read -p "请输入前端域名: " DOMAIN
    if [ -z "$DOMAIN" ]; then
        print_error "域名不能为空"
        return 1
    fi
    
    # 安装依赖
    install_dependencies
    install_nodejs
    
    # 克隆代码
    clone_code
    
    # 编译前端
    DEPLOY_TYPE="frontend"
    build_frontend
    
    # 配置Nginx
    configure_nginx
    
    # 配置SSL
    configure_ssl
    
    print_info "前端部署完成"
    print_info "您可以通过 https://$DOMAIN 访问前端"
    return 0
}

# 部署后端
deploy_backend() {
    print_step "开始后端部署..."
    
    # 获取域名
    read -p "请输入后端域名: " DOMAIN
    if [ -z "$DOMAIN" ]; then
        print_error "域名不能为空"
        return 1
    fi
    
    # 检查现有安装
    check_existing_installation
    
    # 安装依赖
    install_dependencies
    install_go
    
    # 克隆代码
    clone_code
    
    # 编译后端
    build_backend
    
    # 配置Nginx
    DEPLOY_TYPE="backend"
    configure_nginx
    
    # 配置SSL
    configure_ssl
    
    # 配置systemd服务
    configure_systemd
    
    # 检查部署状态
    check_deployment
    
    print_info "后端部署完成"
    print_info "API服务可以通过 https://$DOMAIN 访问"
    print_info "P2P服务运行在端口 27182"
    return 0
}

# 部署前端和后端
deploy_full() {
    print_step "开始前端+后端部署..."
    
    # 获取域名
    read -p "请输入域名: " DOMAIN
    if [ -z "$DOMAIN" ]; then
        print_error "域名不能为空"
        return 1
    fi
    
    # 检查现有安装
    check_existing_installation
    
    # 安装依赖
    install_dependencies
    install_go
    install_nodejs
    
    # 克隆代码
    clone_code
    
    # 编译后端
    build_backend
    
    # 编译前端
    DEPLOY_TYPE="full"
    build_frontend
    
    # 配置Nginx
    configure_nginx
    
    # 配置SSL
    configure_ssl
    
    # 配置systemd服务
    configure_systemd
    
    # 检查部署状态
    check_deployment
    
    print_info "前端+后端部署完成"
    print_info "您可以通过 https://$DOMAIN 访问应用"
    print_info "P2P服务运行在端口 27182"
    return 0
}

# 部署完成后的检查
check_deployment() {
    print_step "检查部署状态..."
    
    # 检查服务状态
    if ! systemctl is-active --quiet openp2p; then
        print_error "OpenP2P服务未运行"
        print_info "查看服务日志:"
        journalctl -u openp2p -n 50 --no-pager
        return 1
    else
        print_info "OpenP2P服务正在运行"
    fi
    
    # 检查端口
    if ! lsof -i:27183 >/dev/null 2>&1; then
        print_error "API端口 27183 未监听"
        print_info "尝试手动启动服务:"
        print_info "systemctl restart openp2p"
        return 1
    else
        print_info "API端口 27183 已正常监听"
    fi
    
    if ! lsof -i:27182 >/dev/null 2>&1; then
        print_warn "P2P端口 27182 未监听"
        print_info "这可能是因为P2P服务未启动或配置问题"
        print_info "如果您不需要P2P功能，可以忽略此警告"
    else
        print_info "P2P端口 27182 已正常监听"
    fi
    
    # 检查Nginx
    if ! systemctl is-active --quiet nginx; then
        print_error "Nginx服务未运行"
        print_info "尝试启动Nginx:"
        print_info "systemctl start nginx"
        return 1
    else
        print_info "Nginx服务正在运行"
    fi
    
    # 检查Nginx配置
    if ! nginx -t &>/dev/null; then
        print_error "Nginx配置测试失败"
        nginx -t
        return 1
    else
        print_info "Nginx配置测试通过"
    fi
    
    # 检查目录权限
    if [ -d "$APP_DIR" ]; then
        APP_DIR_PERMS=$(stat -c "%a" "$APP_DIR")
        if [ "$APP_DIR_PERMS" != "755" ]; then
            print_warn "应用目录权限不正确: $APP_DIR_PERMS，应为755"
            print_info "修复权限:"
            print_info "chmod 755 $APP_DIR"
        else
            print_info "应用目录权限正确: 755"
        fi
    fi
    
    # 如果是前后端同时部署，检查前端文件
    if [ "$DEPLOY_TYPE" = "full" ]; then
        if [ ! -f "$APP_DIR/source/web/dist/index.html" ]; then
            print_error "前端文件不存在: $APP_DIR/source/web/dist/index.html"
            print_info "请检查前端构建是否成功"
            return 1
        else
            print_info "前端文件存在"
        fi
    fi
    
    print_info "所有服务正常运行"
    
    # 提供访问信息
    if [ ! -z "$DOMAIN" ]; then
        if [ "$DEPLOY_TYPE" = "frontend" ] || [ "$DEPLOY_TYPE" = "full" ]; then
            print_info "前端访问地址: http://$DOMAIN"
            if [ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
                print_info "前端访问地址(HTTPS): https://$DOMAIN"
            fi
        fi
        
        if [ "$DEPLOY_TYPE" = "backend" ] || [ "$DEPLOY_TYPE" = "full" ]; then
            print_info "API访问地址: http://$DOMAIN"
            if [ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
                print_info "API访问地址(HTTPS): https://$DOMAIN"
            fi
            
            # 测试API连接
            print_info "测试API连接..."
            if curl -s -o /dev/null -w "%{http_code}" "http://localhost:27183/health" | grep -q "200"; then
                print_info "API健康检查通过"
            else
                print_warn "API健康检查失败，请检查API服务是否正常运行"
            fi
        fi
    fi
    
    # 提供调试信息
    print_info "如果遇到问题，可以查看以下日志:"
    print_info "OpenP2P日志: journalctl -u openp2p -f"
    print_info "Nginx错误日志: tail -f /var/log/nginx/openp2p_error.log"
    print_info "Nginx访问日志: tail -f /var/log/nginx/openp2p_access.log"
    
    return 0
}

# 主函数
main() {
    # 检查root权限
    check_root
    
    # 显示菜单
    show_menu
    
    # 处理选择
    case $choice in
        1)
            deploy_frontend
            ;;
        2)
            deploy_backend
            ;;
        3)
            deploy_full
            ;;
        4)
            cleanup_project
            ;;
        0)
            print_info "退出脚本"
            exit 0
            ;;
        *)
            print_error "无效的选择"
            exit 1
            ;;
    esac
    
    # 显示服务状态
    if [ "$choice" = "2" ] || [ "$choice" = "3" ]; then
        print_info "OpenP2P服务状态："
        systemctl status openp2p | cat
    fi
    
    print_info "Nginx状态："
    systemctl status nginx | cat
}

# 执行主函数
main