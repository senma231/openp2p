# [English](/README.md)|中文  
网站: [openp2p.cn](https://openp2p.cn)
## OpenP2P是什么
它是一个开源、免费、轻量级的P2P共享网络。你的设备将组成一个私有P2P网络，里面的设备可以直接访问其它成员，或者通过其它成员转发数据间接访问。如果私有网络无法完成通信，将会到公有P2P网络寻找共享节点协助通信。
相比BT网络用来共享文件，OpenP2P网络用来共享带宽。
我们的目标是：充分利用带宽，利用共享节点转发数据，建设一个远程连接的通用基础设施。

## 为什么选择OpenP2P
### 1. 免费
完全免费，满足大部分用户的核心白票需求。不像其它类似的产品，OpenP2P不需要有公网IP的服务器，不需要花钱买服务。了解它原理即可理解为什么能做到免费。
### 2. 共享
你的设备会形成一个私有P2P网络，它们之间共享带宽，提供网络数据转发服务。
当你的私有P2P网络下没有可以提供转发服务的节点时，会尝试在公共P2P网络寻找转发节点。
默认会开启共享限速10mbps，只有你用户下提供了共享节点才能使用别人的共享节点。这非常公平，也是这个项目的初衷。
我们建议你在带宽足够的地方（比如办公室，家里的百兆光纤）加入共享网络。
如果你不想共享任何节点，或设置共享带宽，请查看[详细使用说明](/USAGE-ZH.md)
### 3. 安全
代码开源，P2P隧道使用TLS1.3+AES双重加密，共享节点临时授权使用TOTP一次性密码

[查看详细](#安全性)
### 4. 轻量
文件大小2MB+，运行内存2MB+；它可以仅跑在应用层，或者配合wintun驱动使用组网功能
### 5. 跨平台
因为轻量，所以很容易支持各个平台。支持主流的操作系统：Windows,Linux,MacOS；和主流的cpu架构：386、amd64、arm、arm64、mipsle、mipsle64、mips、mips64、s390x、ppc64le
### 6. 高效
P2P直连可以让你的设备跑满带宽。不论你的设备在任何网络环境，无论NAT1-4（Cone或Symmetric），UDP或TCP打洞,UPNP,IPv6都支持。依靠Quic协议优秀的拥塞算法，能在糟糕的网络环境获得高带宽低延时。

### 7. 二次开发
基于OpenP2P只需数行代码，就能让原来只能局域网通信的程序，变成任何内网都能通信

## 快速入门
仅需简单4步就能用起来。  
下面是一个远程办公例子：在家里连入办公室Windows电脑。  
（另外一个快速入门视频 <https://www.bilibili.com/video/BV1Et4y1P7bF/>）
### 1.注册
前往<https://console.openp2p.cn> 注册新用户，暂无需任何认证

   ![image](/doc/images/register.png)
### 2.安装
分别在本地和远程电脑下载后双击运行，一键安装

   ![image](/doc/images/install.png)
   
Windows默认会阻止没有花钱买它家证书签名过的程序，选择“仍要运行”即可。

   ![image](/doc/images/win10warn.png)

   ![image](/doc/images/stillrun.png)
### 3.新建P2P应用

![image](/doc/images/devices.png)

![image](/doc/images/newapp.png)

![image](/doc/images/newappedit.png)

### 4.使用P2P应用
在“MyHomePC”设备上能看到刚才创建的P2P应用，连接下图显示的“本地监听端口”即可。

![image](/doc/images/p2pappok.png)

在家里Windows电脑，按Win+R输入mstsc打开远程桌面，输入127.0.0.1:23389 /admin  

   ![image](/doc/images/mstscconnect.png)

   ![image](/doc/images/afterconnect.png)

## 详细使用说明
[这里](/USAGE-ZH.md)介绍如何手动运行

## 典型应用场景
特别适合大流量的内网访问
>*  远程办公: Windows MSTSC、VNC等远程桌面，SSH，内网各种ERP系统
>*  远程访问内网ERP系统
>*  远程访问NAS: 管理大量视频、图片
>*  远程监控摄像头
>*  远程刷机
>*  远程数据备份
---
## 概要设计
### 原型
![image](/doc/images/prototype.png)
### 客户端架构
![image](/doc/images/architecture.png)
### P2PApp
它是项目里最重要的概念，一个P2PApp就是把远程的一个服务（mstsc/ssh等）通过P2P网络映射到本地监听。二次开发或者我们提供的Restful API，主要工作就是管理P2PApp
![image](/doc/images/appdetail.png)
## 安全性
加入OpenP2P共享网络的节点，只能凭授权访问。共享节点只会中转数据，别人无法访问内网任何资源。
### 1. TLS1.3+AES
两个节点间通信数据走业界最安全的TLS1.3通道。通信内容还会使用AES加密，双重安全，密钥是通过服务端作换。有效阻止中间人攻击
### 2. 共享的中转节点是否会获得我的数据
没错，中转节点天然就是一个中间人，所以才加上AES加密通信内容保证安全。中转节点是无法获取明文的

### 3. 中转节点是如何校验权限的
服务端有个调度模型，根据带宽、ping值、稳定性、服务时长，尽可能地使共享节点均匀地提供服务。连接共享节点使用TOTP密码，hmac-sha256算法校验，它是一次性密码，和我们平时使用的手机验证码或银行密码器一样的原理。

## 编译
go version 1.20 only (支持win7) 
cd到代码根目录，执行
```
make
```
手动编译特定系统和架构 
All GOOS values:
```
"aix", "android", "darwin", "dragonfly", "freebsd", "hurd", "illumos", "ios", "js", "linux", "nacl", "netbsd", "openbsd", "plan9", "solaris", "windows", "zos"
```
All GOARCH values:
```
"386", "amd64", "amd64p32", "arm", "arm64", "arm64be", "armbe", "loong64", "mips", "mips64", "mips64le", "mips64p32", "mips64p32le", "mipsle", "ppc", "ppc64", "ppc64le", "riscv", "riscv64", "s390", "s390x", "sparc", "sparc64", "wasm"
```

比如linux+amd64
```
export GOPROXY=https://goproxy.io,direct
go mod tidy
CGO_ENABLED=0 env GOOS=linux GOARCH=amd64 go build -o openp2p --ldflags '-s -w ' -gcflags '-l' -p 8 -installsuffix cgo ./cmd
```

## RoadMap
近期计划：
1. ~~支持IPv6~~(100%)
2. ~~支持随系统自动启动，安装成系统服务~~(100%)
3. ~~提供一些免费服务器给特别差的网络，如广电网络~~(100%)
4. ~~建立网站，用户可以在网站管理所有P2PApp和设备。查看设备在线状态，升级，增删查改重启P2PApp等~~(100%)
5. 建立公众号，用户可在微信公众号管理所有P2PApp和设备
6. 客户端提供WebUI
7. ~~支持自有服务器，开源服务器程序~~(100%)
8. 共享节点调度模型优化，对不同的运营商优化
9. ~~方便二次开发，提供API和lib~~(100%)
10. ~~应用层支持UDP协议，实现很简单，但UDP应用较少暂不急~~(100%)
11. ~~底层通信支持KCP协议，目前仅支持Quic；KCP专门对延时优化，被游戏加速器广泛使用，可以牺牲一定的带宽降低延时~~(100%)
12. ~~支持Android系统，让旧手机焕发青春变成移动网关~~(100%)
13. ~~支持Windows网上邻居共享文件~~(100%)
14. ~~内网直连优化~~(100%)
15. ~~支持UPNP~~(100%)
16. ~~支持Android~~(100%)
17. 支持IOS

远期计划：
1. 利用区块链技术去中心化，让共享设备的用户有收益，从而促进更多用户共享，达到正向闭环。
2. 企业级支持，可以更好地管理大量设备，和更安全更细的权限控制

## 参与贡献
TODO或ISSUE里如果有你擅长的领域，或者你有特别好的主意，可以加入OpenP2P项目，贡献你的代码。待项目茁壮成长后，你们就是知名开源项目的主要代码贡献者，岂不快哉。

## 技术交流
QQ群：16947733  
邮箱：openp2p.cn@gmail.com tenderiron@139.com  

## 免责声明
本项目开源供大家学习和免费使用，禁止用于非法用途，任何不当使用本项目或意外造成的损失，本项目及相关人员不会承担任何责任。
