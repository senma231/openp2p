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

// 在连接服务器前进行网络诊断
core.DiagnoseNetwork(config.Server, config.Port)

// 连接服务器的代码
conn, err := net.Dial("tcp", fmt.Sprintf("%s:%d", config.Server, config.Port))
if err != nil {
    log.Printf("连接服务器失败: %v", err)
    // 添加重试逻辑
    for i := 0; i < 3; i++ {
        log.Printf("尝试重新连接 (%d/3)...", i+1)
        time.Sleep(2 * time.Second)
        conn, err = net.Dial("tcp", fmt.Sprintf("%s:%d", config.Server, config.Port))
        if err == nil {
            break
        }
        log.Printf("重新连接失败: %v", err)
    }
    if err != nil {
        log.Fatalf("无法连接到服务器，请检查网络和配置: %v", err)
    }
}
log.Printf("成功连接到服务器 %s:%d", config.Server, config.Port)
