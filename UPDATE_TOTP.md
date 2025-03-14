# TOTP验证更新指南

为了解决TOTP验证失败的问题，我们修改了`validateTOTP`函数，增加了时间偏移容忍度，允许前后1分钟的验证码。

## 服务器更新步骤

1. 登录到服务器

```bash
ssh root@your-server-ip
```

2. 备份当前的api.go文件

```bash
cp /opt/openp2p/source/core/api.go /opt/openp2p/source/core/api.go.bak
```

3. 编辑api.go文件，替换validateTOTP函数

```bash
nano /opt/openp2p/source/core/api.go
```

找到`validateTOTP`函数，替换为以下代码：

```go
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
```

4. 确保导入了所有必要的包

在文件顶部的import部分，确保包含以下包：

```go
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
```

5. 重新编译并重启服务

```bash
cd /opt/openp2p/source
go build -o /opt/openp2p/openp2p ./cmd/openp2p.go
systemctl restart openp2p
```

6. 测试登录

现在尝试使用Google验证器生成的TOTP码登录，应该可以成功了。

## 注意事项

1. 如果服务器时区与您的手机时区不同，建议将服务器时区设置为与您的手机相同的时区：

```bash
sudo timedatectl set-timezone Asia/Shanghai
```

2. 如果修改后仍然无法登录，可以临时启用开发模式，使用固定验证码"123456"：

```bash
systemctl stop openp2p
/opt/openp2p/openp2p --dev=true
```

3. 如果您使用的是deploy.sh脚本部署，请确保在脚本中也更新了这部分代码。 