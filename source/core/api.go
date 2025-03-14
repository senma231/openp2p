package core

import (
	"bytes"
	"crypto/hmac"
	"crypto/rand"
	"crypto/sha1"
	"encoding/base32"
	"encoding/base64"
	"encoding/binary"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/skip2/go-qrcode"
)

// 用户结构
type User struct {
	Username string    `json:"username"`
	TOTPKey  string    `json:"totp_key,omitempty"`
	Role     string    `json:"role"`
	Created  time.Time `json:"created"`
}

// 用户存储
var (
	adminUser *User
	users     = make(map[string]User)
	userLock  sync.RWMutex
)

// API响应结构
type APIResponse struct {
	Code    int         `json:"code"`
	Message string      `json:"message"`
	Data    interface{} `json:"data,omitempty"`
}

// 节点状态结构
type NodeStatus struct {
	Name      string    `json:"name"`
	IP        string    `json:"ip"`
	Status    string    `json:"status"`
	Latency   int       `json:"latency"`
	Bandwidth int       `json:"bandwidth"`
	LastSeen  time.Time `json:"lastSeen"`
}

// 统计数据结构
type Stats struct {
	OnlineNodes       int     `json:"onlineNodes"`
	ActiveConnections int     `json:"activeConnections"`
	TotalTraffic      float64 `json:"totalTraffic"`
	AvgLatency        int     `json:"avgLatency"`
}

var isDevelopment = false // 默认为生产模式

// 环境配置结构
type EnvConfig struct {
	IsDevelopment bool   `json:"is_development"`
	TestTOTPCode  string `json:"test_totp_code"`
}

// 加载环境配置
func LoadEnvConfig() error {
	// 尝试从配置文件加载
	data, err := os.ReadFile("config/env.json")
	if err == nil {
		var config EnvConfig
		if err := json.Unmarshal(data, &config); err == nil {
			isDevelopment = config.IsDevelopment
			return nil
		}
	}
	// 如果配置文件不存在或无法读取，使用环境变量
	if env := os.Getenv("OPENP2P_ENV"); env == "development" {
		isDevelopment = true
	}
	return nil
}

// 生成随机TOTP密钥
func generateTOTPKey() string {
	// 生成20字节的随机数据
	bytes := make([]byte, 20)
	if _, err := rand.Read(bytes); err != nil {
		log.Printf("Error generating random bytes: %v", err)
		return ""
	}
	// 使用base32编码，确保生成的密钥长度为32个字符
	return strings.ToUpper(base32.StdEncoding.EncodeToString(bytes))
}

// InitConfig 初始化配置
func InitConfig() error {
	// 在开发模式下使用默认配置
	if isDevelopment {
		return nil
	}
	return nil
}

// InitP2PNetwork 初始化P2P网络
func InitP2PNetwork() error {
	// 在开发模式下跳过P2P网络初始化
	if isDevelopment {
		return nil
	}
	return nil
}

// 高级映射结构
type AdvancedMapping struct {
	Name        string     `json:"name"`
	Protocol    string     `json:"protocol"`
	EntryPort   int        `json:"entryPort"`
	Nodes       []NodeInfo `json:"nodes"`
	TargetPort  int        `json:"targetPort"`
	Description string     `json:"description,omitempty"`
	Status      string     `json:"status"`
}

type NodeInfo struct {
	Name string `json:"name"`
}

// 高级映射存储
var (
	advancedMappings    = make(map[string]*AdvancedMapping)
	advancedMappingLock sync.RWMutex
)

// 添加CORS中间件
func corsMiddleware(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		// 允许的来源域名
		allowedOrigins := []string{
			"https://your-cloudflare-pages-domain.pages.dev",
			"http://localhost:5173", // 开发环境
		}

		// 检查请求的Origin是否在允许列表中
		origin := r.Header.Get("Origin")
		for _, allowed := range allowedOrigins {
			if origin == allowed {
				w.Header().Set("Access-Control-Allow-Origin", origin)
				break
			}
		}

		// 其他CORS头
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
		w.Header().Set("Access-Control-Allow-Credentials", "true")

		// 处理预检请求
		if r.Method == "OPTIONS" {
			w.WriteHeader(http.StatusOK)
			return
		}

		next(w, r)
	}
}

// InitAPIRoutes 初始化API路由
func InitAPIRoutes() {
	// 认证相关路由
	http.HandleFunc("/api/auth/register", corsMiddleware(handleRegister))
	http.HandleFunc("/api/auth/login", corsMiddleware(handleLogin))
	http.HandleFunc("/api/auth/reset-totp", corsMiddleware(handleResetTOTP))
	http.HandleFunc("/api/auth/check-admin", corsMiddleware(handleCheckAdmin))
	http.HandleFunc("/api/auth/delete-admin", corsMiddleware(handleDeleteAdmin))

	// 其他API路由
	http.HandleFunc("/api/stats", corsMiddleware(handleStats))
	http.HandleFunc("/api/nodes", corsMiddleware(handleNodes))
	http.HandleFunc("/api/mappings", corsMiddleware(handleMappings))
	http.HandleFunc("/api/logs", corsMiddleware(handleLogs))

	// 高级映射相关路由
	http.HandleFunc("/api/advanced-mappings", corsMiddleware(handleAdvancedMappings))
	http.HandleFunc("/api/advanced-mappings/", corsMiddleware(handleAdvancedMappingOperation))

	// 启动HTTP服务器
	go func() {
		log.Printf("Starting HTTP server on port 27183 in %s mode",
			map[bool]string{true: "development", false: "production"}[isDevelopment])
		if err := http.ListenAndServe(":27183", nil); err != nil {
			log.Printf("HTTP server error: %v", err)
		}
	}()
}

// 注册处理
func handleRegister(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	userLock.Lock()
	defer userLock.Unlock()

	// 检查是否已存在管理员
	if adminUser != nil {
		responseJSON(w, APIResponse{Code: 1, Message: "Administrator already exists"})
		return
	}

	var userData struct {
		Username string `json:"username"`
	}

	if err := json.NewDecoder(r.Body).Decode(&userData); err != nil {
		responseJSON(w, APIResponse{Code: 1, Message: "Invalid request body"})
		return
	}

	// 生成TOTP密钥
	totpKey := generateTOTPKey()
	if totpKey == "" {
		responseJSON(w, APIResponse{Code: 1, Message: "Failed to generate TOTP key"})
		return
	}

	// 创建管理员用户
	adminUser = &User{
		Username: userData.Username,
		TOTPKey:  totpKey,
		Role:     "admin",
		Created:  time.Now(),
	}

	// 生成测试环境的验证码
	var testCode string
	if isDevelopment {
		testCode = "123456" // 在开发模式下使用固定的测试验证码
	}

	// 生成 QR 码 URL（使用自定义 issuer）
	issuer := "OpenP2P-Private"
	if isDevelopment {
		issuer += "-Dev"
	}
	qrURL := fmt.Sprintf("data:image/png;base64,%s",
		generateQRCode(fmt.Sprintf("otpauth://totp/%s?secret=%s&issuer=%s",
			userData.Username, totpKey, issuer)))

	// 返回TOTP密钥和二维码URL
	responseJSON(w, APIResponse{
		Code:    0,
		Message: "Registration successful",
		Data: map[string]interface{}{
			"totp_key":  totpKey,
			"qr_url":    qrURL,
			"test_code": testCode,
		},
	})
}

// 生成QR码
func generateQRCode(content string) string {
	// 使用 qrcode 包生成二维码
	qr, err := qrcode.New(content, qrcode.Medium)
	if err != nil {
		log.Printf("Error generating QR code: %v", err)
		return ""
	}

	// 将二维码转换为PNG格式
	var buf bytes.Buffer
	err = qr.Write(256, &buf)
	if err != nil {
		log.Printf("Error writing QR code: %v", err)
		return ""
	}

	// 返回base64编码的图片数据
	return base64.StdEncoding.EncodeToString(buf.Bytes())
}

// 登录处理
func handleLogin(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var loginData struct {
		Username string `json:"username"`
		TOTPCode string `json:"totp_code"`
	}

	if err := json.NewDecoder(r.Body).Decode(&loginData); err != nil {
		log.Printf("Invalid request body: %v", err)
		responseJSON(w, APIResponse{Code: 1, Message: "Invalid request body"})
		return
	}

	userLock.RLock()
	defer userLock.RUnlock()

	// 检查用户是否存在
	if adminUser == nil || adminUser.Username != loginData.Username {
		log.Printf("Invalid username: %s, adminUser exists: %v", loginData.Username, adminUser != nil)
		responseJSON(w, APIResponse{Code: 1, Message: "Invalid username"})
		return
	}

	// 验证TOTP码
	if !validateTOTP(adminUser.TOTPKey, loginData.TOTPCode) {
		log.Printf("Invalid TOTP code: %s for user: %s", loginData.TOTPCode, loginData.Username)
		responseJSON(w, APIResponse{Code: 1, Message: "Invalid TOTP code"})
		return
	}

	// 生成会话token
	token := generateToken(adminUser.Username)

	log.Printf("Login successful for user: %s", loginData.Username)
	responseJSON(w, APIResponse{
		Code:    0,
		Message: "Login successful",
		Data: map[string]string{
			"token": token,
			"role":  adminUser.Role,
		},
	})
}

// 重置TOTP密钥
func handleResetTOTP(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// 验证当前TOTP码
	var resetData struct {
		CurrentTOTPCode string `json:"current_totp_code"`
	}

	if err := json.NewDecoder(r.Body).Decode(&resetData); err != nil {
		responseJSON(w, APIResponse{Code: 1, Message: "Invalid request body"})
		return
	}

	userLock.Lock()
	defer userLock.Unlock()

	if !validateTOTP(adminUser.TOTPKey, resetData.CurrentTOTPCode) {
		responseJSON(w, APIResponse{Code: 1, Message: "Invalid TOTP code"})
		return
	}

	// 生成新的TOTP密钥
	newTOTPKey := generateTOTPKey()
	adminUser.TOTPKey = newTOTPKey

	responseJSON(w, APIResponse{
		Code:    0,
		Message: "TOTP key reset successful",
		Data: map[string]string{
			"totp_key": newTOTPKey,
			"qr_url":   "otpauth://totp/" + adminUser.Username + "?secret=" + newTOTPKey + "&issuer=OpenP2P",
		},
	})
}

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
	hotp := uint64(truncatedHash % 1000000)

	return hotp == code
}

// 辅助函数：生成token
func generateToken(username string) string {
	bytes := make([]byte, 32)
	rand.Read(bytes)
	return base64.StdEncoding.EncodeToString(bytes)
}

// 辅助函数：JSON响应
func responseJSON(w http.ResponseWriter, response APIResponse) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// 统计数据处理
func handleStats(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// 获取实时统计数据
	stats := Stats{
		OnlineNodes:       len(gConf.Apps),
		ActiveConnections: getActiveConnections(),
		TotalTraffic:      calculateTotalTraffic(),
		AvgLatency:        calculateAvgLatency(),
	}

	responseJSON(w, APIResponse{Code: 0, Data: stats})
}

// 节点管理处理
func handleNodes(w http.ResponseWriter, r *http.Request) {
	switch r.Method {
	case http.MethodGet:
		// 获取所有节点状态
		nodes := make([]NodeStatus, 0)
		for _, app := range gConf.Apps {
			nodes = append(nodes, NodeStatus{
				Name:      app.AppName,
				IP:        app.peerIP,
				Status:    getNodeStatus(*app),
				Latency:   getPeerLatency(*app),
				Bandwidth: app.shareBandwidth,
				LastSeen:  app.connectTime,
			})
		}
		responseJSON(w, APIResponse{Code: 0, Data: nodes})

	case http.MethodPost:
		// 添加新节点
		var newApp AppConfig
		if err := json.NewDecoder(r.Body).Decode(&newApp); err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}
		// 添加节点配置
		gConf.Apps = append(gConf.Apps, &newApp)
		responseJSON(w, APIResponse{Code: 0, Message: "节点添加成功"})

	default:
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
	}
}

// 端口映射处理
func handleMappings(w http.ResponseWriter, r *http.Request) {
	switch r.Method {
	case http.MethodGet:
		// 获取所有映射配置
		mappings := make([]AppConfig, 0)
		for _, app := range gConf.Apps {
			mappings = append(mappings, *app)
		}
		responseJSON(w, APIResponse{Code: 0, Data: mappings})

	case http.MethodPost:
		// 添加新映射
		var newMapping AppConfig
		if err := json.NewDecoder(r.Body).Decode(&newMapping); err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}
		// 添加映射配置
		gConf.Apps = append(gConf.Apps, &newMapping)
		responseJSON(w, APIResponse{Code: 0, Message: "映射添加成功"})

	default:
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
	}
}

// 日志查询处理
func handleLogs(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// 获取查询参数
	page := 1
	pageSize := 10
	level := ""

	query := r.URL.Query()
	if p := query.Get("page"); p != "" {
		if pageNum, err := strconv.Atoi(p); err == nil && pageNum > 0 {
			page = pageNum
		}
	}
	if ps := query.Get("pageSize"); ps != "" {
		if size, err := strconv.Atoi(ps); err == nil && size > 0 {
			pageSize = size
		}
	}
	level = query.Get("level")

	// 获取日志记录
	logs, total := getSystemLogs(page, pageSize, level)
	responseJSON(w, APIResponse{Code: 0, Data: map[string]interface{}{
		"logs":  logs,
		"total": total,
	}})
}

func getActiveConnections() int {
	count := 0
	for _, app := range gConf.Apps {
		if app.Enabled == 1 && app.connectTime.After(time.Now().Add(-time.Minute*5)) {
			count++
		}
	}
	return count
}

func calculateTotalTraffic() float64 {
	// TODO: 实现流量统计
	return 0
}

func calculateAvgLatency() int {
	total := 0
	count := 0
	for _, app := range gConf.Apps {
		if latency := getPeerLatency(*app); latency > 0 {
			total += latency
			count++
		}
	}
	if count == 0 {
		return 0
	}
	return total / count
}

func getNodeStatus(app AppConfig) string {
	if app.Enabled == 0 {
		return "offline"
	}
	if app.connectTime.After(time.Now().Add(-time.Minute * 5)) {
		return "online"
	}
	return "offline"
}

func getPeerLatency(app AppConfig) int {
	// TODO: 实现延迟检测
	return 0
}

type LogEntry struct {
	Timestamp int64  `json:"timestamp"`
	Level     string `json:"level"`
	Module    string `json:"module"`
	Message   string `json:"message"`
}

func getSystemLogs(page, pageSize int, level string) ([]LogEntry, int) {
	// 模拟日志数据
	allLogs := []LogEntry{
		{Timestamp: time.Now().Unix(), Level: "info", Module: "system", Message: "系统启动成功"},
		{Timestamp: time.Now().Add(-time.Minute).Unix(), Level: "warning", Module: "network", Message: "网络连接不稳定"},
		{Timestamp: time.Now().Add(-time.Hour).Unix(), Level: "error", Module: "database", Message: "数据库连接失败"},
	}

	// 根据级别筛选
	filteredLogs := make([]LogEntry, 0)
	for _, log := range allLogs {
		if level == "" || level == "all" || log.Level == level {
			filteredLogs = append(filteredLogs, log)
		}
	}

	// 计算总数
	total := len(filteredLogs)

	// 计算分页
	start := (page - 1) * pageSize
	end := start + pageSize
	if start >= total {
		return []LogEntry{}, total
	}
	if end > total {
		end = total
	}

	return filteredLogs[start:end], total
}

// 检查管理员是否存在
func handleCheckAdmin(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	userLock.RLock()
	exists := adminUser != nil
	userLock.RUnlock()

	responseJSON(w, APIResponse{
		Code: 0,
		Data: exists,
	})
}

// 删除管理员账号
func handleDeleteAdmin(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// 验证当前TOTP码
	var deleteData struct {
		TOTPCode string `json:"totp_code"`
	}

	if err := json.NewDecoder(r.Body).Decode(&deleteData); err != nil {
		responseJSON(w, APIResponse{Code: 1, Message: "Invalid request body"})
		return
	}

	userLock.Lock()
	defer userLock.Unlock()

	// 检查是否存在管理员账号
	if adminUser == nil {
		responseJSON(w, APIResponse{Code: 1, Message: "No admin user exists"})
		return
	}

	// 验证TOTP码
	if !validateTOTP(adminUser.TOTPKey, deleteData.TOTPCode) {
		responseJSON(w, APIResponse{Code: 1, Message: "Invalid TOTP code"})
		return
	}

	// 删除管理员账号
	adminUser = nil

	responseJSON(w, APIResponse{
		Code:    0,
		Message: "Admin account deleted successfully",
	})
}

// 处理高级映射请求
func handleAdvancedMappings(w http.ResponseWriter, r *http.Request) {
	switch r.Method {
	case http.MethodGet:
		// 获取所有高级映射
		advancedMappingLock.RLock()
		mappings := make([]*AdvancedMapping, 0, len(advancedMappings))
		for _, mapping := range advancedMappings {
			mappings = append(mappings, mapping)
		}
		advancedMappingLock.RUnlock()
		responseJSON(w, APIResponse{Code: 0, Data: mappings})

	case http.MethodPost:
		// 添加新的高级映射
		var mapping AdvancedMapping
		if err := json.NewDecoder(r.Body).Decode(&mapping); err != nil {
			responseJSON(w, APIResponse{Code: 1, Message: "Invalid request body"})
			return
		}

		// 验证必要字段
		if mapping.Name == "" || mapping.Protocol == "" || mapping.EntryPort == 0 || len(mapping.Nodes) < 2 || mapping.TargetPort == 0 {
			responseJSON(w, APIResponse{Code: 1, Message: "Missing required fields"})
			return
		}

		advancedMappingLock.Lock()
		if _, exists := advancedMappings[mapping.Name]; exists {
			advancedMappingLock.Unlock()
			responseJSON(w, APIResponse{Code: 1, Message: "Mapping name already exists"})
			return
		}

		mapping.Status = "disconnected"
		advancedMappings[mapping.Name] = &mapping
		advancedMappingLock.Unlock()

		responseJSON(w, APIResponse{Code: 0, Message: "Advanced mapping created successfully"})

	default:
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
	}
}

// 处理单个高级映射操作
func handleAdvancedMappingOperation(w http.ResponseWriter, r *http.Request) {
	// 从URL中获取映射名称
	parts := strings.Split(r.URL.Path, "/")
	if len(parts) < 3 {
		http.Error(w, "Invalid URL", http.StatusBadRequest)
		return
	}
	mappingName := parts[3]
	operation := ""
	if len(parts) > 4 {
		operation = parts[4]
	}

	advancedMappingLock.RLock()
	mapping, exists := advancedMappings[mappingName]
	advancedMappingLock.RUnlock()

	if !exists {
		responseJSON(w, APIResponse{Code: 1, Message: "Mapping not found"})
		return
	}

	switch {
	case operation == "start" && r.Method == http.MethodPost:
		// 启动映射
		mapping.Status = "connected"
		responseJSON(w, APIResponse{Code: 0, Message: "Mapping started successfully"})

	case operation == "stop" && r.Method == http.MethodPost:
		// 停止映射
		mapping.Status = "disconnected"
		responseJSON(w, APIResponse{Code: 0, Message: "Mapping stopped successfully"})

	case operation == "" && r.Method == http.MethodPut:
		// 更新映射
		var updatedMapping AdvancedMapping
		if err := json.NewDecoder(r.Body).Decode(&updatedMapping); err != nil {
			responseJSON(w, APIResponse{Code: 1, Message: "Invalid request body"})
			return
		}

		advancedMappingLock.Lock()
		mapping.Protocol = updatedMapping.Protocol
		mapping.EntryPort = updatedMapping.EntryPort
		mapping.Nodes = updatedMapping.Nodes
		mapping.TargetPort = updatedMapping.TargetPort
		mapping.Description = updatedMapping.Description
		advancedMappingLock.Unlock()

		responseJSON(w, APIResponse{Code: 0, Message: "Mapping updated successfully"})

	case operation == "" && r.Method == http.MethodDelete:
		// 删除映射
		advancedMappingLock.Lock()
		delete(advancedMappings, mappingName)
		advancedMappingLock.Unlock()

		responseJSON(w, APIResponse{Code: 0, Message: "Mapping deleted successfully"})

	default:
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
	}
}
