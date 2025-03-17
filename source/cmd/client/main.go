package main

import (
	"flag"
	"fmt"
	"log"
	"os"
	"os/signal"
	"path/filepath"
	"syscall"

	"../../client"
)

func main() {
	// 解析命令行参数
	configPath := flag.String("config", "config.json", "配置文件路径")
	flag.Parse()

	// 如果配置文件路径是相对路径，转换为绝对路径
	if !filepath.IsAbs(*configPath) {
		dir, err := os.Getwd()
		if err != nil {
			log.Fatalf("获取当前目录失败: %v", err)
		}
		*configPath = filepath.Join(dir, *configPath)
	}

	// 检查配置文件是否存在
	if _, err := os.Stat(*configPath); os.IsNotExist(err) {
		log.Fatalf("配置文件不存在: %s", *configPath)
	}

	// 创建客户端
	c, err := client.NewClient(*configPath)
	if err != nil {
		log.Fatalf("创建客户端失败: %v", err)
	}

	// 启动客户端
	if err := c.Start(); err != nil {
		log.Fatalf("启动客户端失败: %v", err)
	}

	fmt.Printf("客户端已启动，连接到服务器 %s:%d\n", c.Config.Server, c.Config.Port)

	// 等待中断信号
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)
	<-sigChan

	// 停止客户端
	c.Stop()
	fmt.Println("客户端已停止")
}
