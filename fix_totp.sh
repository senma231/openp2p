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

# 备份原始文件
backup_file() {
    local file="$1"
    if [ -f "$file" ]; then
        cp "$file" "${file}.bak.$(date +%Y%m%d%H%M%S)"
        info "已备份文件: ${file}"
        return 0
    else
        error "文件不存在: ${file}"
        return 1
    fi
}

# 修复TOTP验证函数
fix_totp() {
    local api_file="/opt/openp2p/source/core/api.go"
    
    # 备份文件
    backup_file "$api_file" || return 1
    
    info "开始修复TOTP验证函数..."
    
    # 使用sed替换validateTOTP函数
    # 首先找到函数的开始和结束行
    local start_line=$(grep -n "func validateTOTP" "$api_file" | cut -d: -f1)
    if [ -z "$start_line" ]; then
        error "找不到validateTOTP函数"
        return 1
    fi
    
    # 找到函数的结束行（下一个函数的开始行减1）
    local next_func_line=$(tail -n +$((start_line+1)) "$api_file" | grep -n "^func " | head -1 | cut -d: -f1)
    if [ -z "$next_func_line" ]; then
        # 如果找不到下一个函数，假设函数到文件末尾
        next_func_line=$(wc -l < "$api_file")
    else
        next_func_line=$((start_line + next_func_line))
    fi
    local end_line=$((next_func_line - 1))
    
    info "找到validateTOTP函数: 行 $start_line 到 $end_line"
    
    # 创建临时文件
    local temp_file=$(mktemp)
    
    # 复制函数前的内容
    head -n $((start_line-1)) "$api_file" > "$temp_file"
    
    # 添加新的validateTOTP函数
    cat >> "$temp_file" << 'EOF'
// 验证TOTP码
func validateTOTP(key string, code string) bool {
	// 开发模式下使用固定验证码
	if isDevelopment && code == "123456" {
		return true
	}

	// 生产模式使用标准TOTP验证
	codeNum, err := strconv.ParseUint(code, 10, 64)
	if err != nil {
		log.Printf("TOTP code parse error: %v", err)
		return false
	}

	// 将 base32 编码的密钥转换为字节数组
	keyBytes, err := base32.StdEncoding.DecodeString(key)
	if err != nil {
		log.Printf("TOTP key decode error: %v", err)
		return false
	}

	// 使用 TOTP 验证
	// 增加时间偏移容忍度，允许前后1分钟的验证码
	now := time.Now()
	for _, offset := range []int{-60, -30, 0, 30, 60} {
		testTime := now.Add(time.Duration(offset) * time.Second)
		if validateTOTPAtTime(keyBytes, codeNum, testTime) {
			return true
		}
	}

	return false
}

// 在特定时间点验证TOTP码
func validateTOTPAtTime(key []byte, code uint64, t time.Time) bool {
	// 计算TOTP
	timeCounter := uint64(t.Unix()) / 30
	h := hmac.New(sha1.New, key)
	binary.Write(h, binary.BigEndian, timeCounter)
	sum := h.Sum(nil)

	// RFC 4226/RFC 6238 截断
	offset := sum[len(sum)-1] & 0x0F
	truncatedHash := binary.BigEndian.Uint32(sum[offset:offset+4]) & 0x7FFFFFFF
	hotp := truncatedHash % 1000000

	return hotp == code
}
EOF
    
    # 复制函数后的内容
    tail -n +$((end_line+1)) "$api_file" >> "$temp_file"
    
    # 检查导入包
    if ! grep -q "crypto/hmac" "$temp_file"; then
        info "添加缺少的导入包..."
        # 找到import语句块
        local import_start=$(grep -n "^import (" "$temp_file" | cut -d: -f1)
        local import_end=$(grep -n "^)" "$temp_file" | head -1 | cut -d: -f1)
        
        if [ -n "$import_start" ] && [ -n "$import_end" ]; then
            # 创建新的临时文件
            local temp_file2=$(mktemp)
            
            # 复制import语句前的内容
            head -n $import_start "$temp_file" > "$temp_file2"
            
            # 添加新的import语句块
            cat >> "$temp_file2" << 'EOF'
import (
	"crypto/hmac"
	"crypto/sha1"
	"encoding/base32"
	"encoding/binary"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"strconv"
	"sync"
	"time"
)
EOF
            
            # 复制import语句后的内容
            tail -n +$((import_end+1)) "$temp_file" >> "$temp_file2"
            
            # 替换临时文件
            mv "$temp_file2" "$temp_file"
        else
            warn "无法找到import语句块，请手动添加缺少的包"
        fi
    fi
    
    # 替换原始文件
    mv "$temp_file" "$api_file"
    
    info "TOTP验证函数修复完成"
    
    # 重新编译
    info "重新编译应用..."
    cd /opt/openp2p/source
    if go build -o /opt/openp2p/openp2p ./cmd/openp2p.go; then
        info "编译成功"
        
        # 重启服务
        info "重启服务..."
        systemctl restart openp2p
        
        info "修复完成，请尝试使用Google验证器登录"
    else
        error "编译失败，请检查错误信息"
        return 1
    fi
    
    return 0
}

# 主函数
main() {
    info "开始修复TOTP验证问题..."
    
    # 检查是否为root用户
    if [ "$(id -u)" != "0" ]; then
        error "请使用root权限运行此脚本"
        exit 1
    fi
    
    # 修复TOTP验证
    if fix_totp; then
        info "TOTP验证问题修复成功"
    else
        error "TOTP验证问题修复失败"
        exit 1
    fi
    
    info "修复完成"
}

# 执行主函数
main 