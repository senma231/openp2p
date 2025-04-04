module openp2p

go 1.20

require (
	github.com/emirpasic/gods v1.18.1
	github.com/gorilla/websocket v1.5.1
	github.com/openp2p-cn/go-reuseport v0.3.2
	github.com/openp2p-cn/service v1.0.0
	github.com/openp2p-cn/totp v0.0.0-20230421034602-0f3320ffb25e
	github.com/openp2p-cn/wireguard-go v0.0.20241020
	github.com/quic-go/quic-go v0.41.0
	github.com/skip2/go-qrcode v0.0.0-20200617195104-da1b6568686e
	github.com/vishvananda/netlink v1.1.1-0.20211118161826-650dca95af54
	github.com/xtaci/kcp-go/v5 v5.6.7
	golang.org/x/net v0.30.0
	golang.org/x/sys v0.26.0
	golang.zx2c4.com/wireguard/windows v0.5.3
)

require (
	github.com/go-logr/logr v1.3.0 // indirect
	github.com/go-task/slim-sprig v0.0.0-20230315185526-52ccab3ef572 // indirect
	github.com/golang/protobuf v1.5.4 // indirect
	github.com/google/btree v1.1.2 // indirect
	github.com/google/pprof v0.0.0-20210407192527-94a9f03dee38 // indirect
	github.com/kardianos/service v1.2.2 // indirect
	github.com/klauspost/cpuid/v2 v2.2.6 // indirect
	github.com/klauspost/reedsolomon v1.12.0 // indirect
	github.com/onsi/ginkgo/v2 v2.9.5 // indirect
	github.com/pkg/errors v0.9.1 // indirect
	github.com/templexxx/cpu v0.1.0 // indirect
	github.com/templexxx/xorsimd v0.4.2 // indirect
	github.com/tjfoc/gmsm v1.4.1 // indirect
	github.com/vishvananda/netns v0.0.0-20210104183010-2eb08e3e575f // indirect
	go.uber.org/mock v0.3.0 // indirect
	golang.org/x/crypto v0.28.0 // indirect
	golang.org/x/exp v0.0.0-20230725093048-515e97ebf090 // indirect
	golang.org/x/mod v0.21.0 // indirect
	golang.org/x/sync v0.8.0 // indirect
	golang.org/x/time v0.7.0 // indirect
	golang.org/x/tools v0.26.0 // indirect
	golang.zx2c4.com/wintun v0.0.0-20230126152724-0fa3db229ce2 // indirect
	golang.zx2c4.com/wireguard v0.0.0-20231211153847-12269c276173 // indirect
)

replace github.com/openp2p-cn/totp => github.com/openp2p-cn/totp v0.0.0-20230421034602-0f3320ffb25e

// 添加gvisor的替换，使用兼容Go 1.20的旧版本
replace gvisor.dev/gvisor => gvisor.dev/gvisor v0.0.0-20220901235040-6ca97ef2ce1c
