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