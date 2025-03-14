# TOTP验证修复说明

## 问题描述

在不同时区的服务器上，TOTP（基于时间的一次性密码）验证可能会失败，因为服务器时间与用户设备时间存在差异。

## 修复方案

我们已经修改了 `validateTOTP` 函数，增加了时间偏移容忍度，允许前后1分钟的验证码有效。这样即使服务器与用户设备存在时区差异，只要在合理范围内（±1分钟），验证码仍然有效。

## 重新部署步骤

1. 登录到您的VPS

2. 进入项目目录
   ```bash
   cd /opt/openp2p
   ```

3. 拉取最新代码
   ```bash
   git pull origin main
   ```

4. 重新编译应用
   ```bash
   cd /opt/openp2p/source
   go build -o /opt/openp2p/openp2p ./cmd/openp2p.go
   ```

5. 重启服务
   ```bash
   systemctl restart openp2p
   ```

6. 检查服务状态
   ```bash
   systemctl status openp2p
   ```

## 验证修复是否成功

1. 尝试使用Google验证器登录系统
2. 如果登录成功，说明修复已生效

## 注意事项

- 如果您的服务器时间与标准时间相差超过1分钟，建议同步服务器时间：
  ```bash
  apt-get update
  apt-get install -y ntp
  systemctl start ntp
  systemctl enable ntp
  ```

- 如果修复后仍然遇到问题，请检查服务器日志：
  ```bash
  journalctl -u openp2p -f
  ```

## 技术细节

修改的核心代码如下：

```go
// 使用 TOTP 验证
// 增加时间偏移容忍度，允许前后1分钟的验证码
now := time.Now()
for _, offset := range []int{-60, -30, 0, 30, 60} {
    testTime := now.Add(time.Duration(offset) * time.Second)
    if validateTOTPAtTime(keyBytes, codeNum, testTime) {
        return true
    }
}
```

这段代码会尝试验证当前时间前后1分钟内的验证码，只要有一个验证通过，就认为验证成功。 