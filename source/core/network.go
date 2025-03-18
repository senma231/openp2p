package core

import (
    "fmt"
    "log"
    "net"
    "time"
)

// 网络诊断
func DiagnoseNetwork(server string, port int) {
    log.Printf("开始网络诊断...")
    
    // 检查DNS解析
    log.Printf("正在解析服务器地址: %s", server)
    ips, err := net.LookupIP(server)
    if err != nil {
        log.Printf("DNS解析失败: %v", err)
    } else {
        log.Printf("DNS解析成功，IP地址: %v", ips)
    }
    
    // 尝试TCP连接
    address := fmt.Sprintf("%s:%d", server, port)
    log.Printf("正在尝试TCP连接: %s", address)
    
    start := time.Now()
    conn, err := net.DialTimeout("tcp", address, 5*time.Second)
    elapsed := time.Since(start)
    
    if err != nil {
        log.Printf("TCP连接失败: %v", err)
    } else {
        log.Printf("TCP连接成功，耗时: %v", elapsed)
        conn.Close()
    }
    
    log.Printf("网络诊断完成")
}