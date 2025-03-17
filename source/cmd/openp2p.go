package main

import (
	"flag"
	"log"
	"os"

	"openp2p/core"
)

var isDev = flag.Bool("dev", false, "Run in development mode")

func main() {
	flag.Parse()

	// 设置环境变量
	os.Setenv("OPENP2P_ENV", "production")
	os.Setenv("GO_ENV", "production")
	os.Setenv("GIN_MODE", "release")

	// 设置开发模式
	if *isDev {
		log.Println("Running in development mode")
		os.Setenv("OPENP2P_ENV", "development")
		os.Setenv("GO_ENV", "development")
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
