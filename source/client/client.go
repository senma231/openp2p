package client

import (
	"bytes"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"time"
)

// ClientConfig 客户端配置结构
type ClientConfig struct {
	Server    string `json:"server"`
	Port      int    `json:"port"`
	Name      string `json:"name"`
	Token     string `json:"token"`
	Bind      string `json:"bind"`
	P2PPort   int    `json:"p2p_port"`
	LogLevel  int    `json:"log_level"`
	AutoStart bool   `json:"auto_start"`
	AutoLogin bool   `json:"auto_login"`
	Language  string `json:"language"`
	Theme     string `json:"theme"`
}

// ClientStatus 客户端状态
type ClientStatus struct {
	Connected   bool      `json:"connected"`
	LastConnect time.Time `json:"last_connect"`
	ServerTime  int64     `json:"server_time"`
	NodeID      string    `json:"node_id"`
	NodeName    string    `json:"node_name"`
	Error       string    `json:"error,omitempty"`
}

// Client 客户端结构
type Client struct {
	Config     ClientConfig
	Status     ClientStatus
	httpClient *http.Client
	stopChan   chan struct{}
	logger     *log.Logger
}

// APIResponse API响应结构
type APIResponse struct {
	Code    int             `json:"code"`
	Message string          `json:"message"`
	Data    json.RawMessage `json:"data,omitempty"`
}

// NewClient 创建新客户端
func NewClient(configPath string) (*Client, error) {
	// 读取配置文件
	configData, err := os.ReadFile(configPath)
	if err != nil {
		return nil, fmt.Errorf("读取配置文件失败: %v", err)
	}

	// 解析配置
	var config ClientConfig
	if err := json.Unmarshal(configData, &config); err != nil {
		return nil, fmt.Errorf("解析配置文件失败: %v", err)
	}

	// 验证必填字段
	if config.Server == "" {
		return nil, fmt.Errorf("服务器地址不能为空")
	}
	if config.Token == "" {
		return nil, fmt.Errorf("节点令牌不能为空")
	}

	// 设置默认值
	if config.Port == 0 {
		config.Port = 27183
	}
	if config.Bind == "" {
		config.Bind = "0.0.0.0"
	}
	if config.LogLevel == 0 {
		config.LogLevel = 2 // 默认信息级别
	}

	// 创建日志目录
	logDir := getLogDir()
	fmt.Printf("日志目录: %s\n", logDir)

	// 创建日志文件
	logFileName := filepath.Join(logDir, fmt.Sprintf("client_%s.log", time.Now().Format("20060102")))
	fmt.Printf("日志文件: %s\n", logFileName)

	logFile, err := os.OpenFile(
		logFileName,
		os.O_CREATE|os.O_APPEND|os.O_WRONLY,
		0644,
	)
	if err != nil {
		// 如果创建日志文件失败，使用标准输出
		fmt.Printf("创建日志文件失败: %v，将使用标准输出\n", err)
		logFile = os.Stdout
	}

	// 创建客户端
	client := &Client{
		Config: config,
		Status: ClientStatus{
			Connected: false,
		},
		httpClient: &http.Client{
			Timeout: 10 * time.Second,
		},
		stopChan: make(chan struct{}),
		logger:   log.New(logFile, "", log.LstdFlags),
	}

	// 记录初始日志
	client.logf(1, "客户端初始化完成，配置文件: %s", configPath)
	client.logf(1, "服务器地址: %s:%d", config.Server, config.Port)
	client.logf(1, "节点名称: %s", config.Name)
	client.logf(1, "日志级别: %d", config.LogLevel)

	return client, nil
}

// Start 启动客户端
func (c *Client) Start() error {
	c.logf(1, "客户端启动，连接到服务器 %s:%d", c.Config.Server, c.Config.Port)

	// 验证配置
	if err := c.verifyConfig(); err != nil {
		c.logf(1, "配置验证失败: %v", err)
		c.Status.Error = err.Error()
		return err
	}

	// 建立连接
	if err := c.connect(); err != nil {
		c.logf(1, "连接服务器失败: %v", err)
		c.Status.Error = err.Error()
		return err
	}

	// 启动心跳
	go c.heartbeatLoop()

	return nil
}

// Stop 停止客户端
func (c *Client) Stop() {
	c.logf(2, "客户端停止")
	close(c.stopChan)
}

// 验证配置
func (c *Client) verifyConfig() error {
	c.logf(2, "验证配置...")

	// 处理服务器地址格式
	serverAddr := c.Config.Server
	// 移除可能的协议前缀
	serverAddr = strings.TrimPrefix(serverAddr, "http://")
	serverAddr = strings.TrimPrefix(serverAddr, "https://")

	// 构建请求URL
	url := fmt.Sprintf("http://%s:%d/api/client/verify", serverAddr, c.Config.Port)

	// 构建请求体
	reqBody, err := json.Marshal(c.Config)
	if err != nil {
		return fmt.Errorf("序列化配置失败: %v", err)
	}

	// 发送请求
	resp, err := c.httpClient.Post(url, "application/json", bytes.NewBuffer(reqBody))
	if err != nil {
		return fmt.Errorf("发送验证请求失败: %v", err)
	}
	defer resp.Body.Close()

	// 解析响应
	var apiResp APIResponse
	if err := json.NewDecoder(resp.Body).Decode(&apiResp); err != nil {
		return fmt.Errorf("解析响应失败: %v", err)
	}

	// 检查响应状态
	if apiResp.Code != 0 {
		return fmt.Errorf("验证失败: %s", apiResp.Message)
	}

	// 解析响应数据
	var verifyData struct {
		NodeID          string   `json:"node_id"`
		NodeName        string   `json:"node_name"`
		NodeType        string   `json:"node_type"`
		ConfigValid     bool     `json:"config_valid"`
		Recommendations []string `json:"recommendations"`
	}
	if err := json.Unmarshal(apiResp.Data, &verifyData); err != nil {
		return fmt.Errorf("解析验证数据失败: %v", err)
	}

	c.Status.NodeID = verifyData.NodeID
	c.Status.NodeName = verifyData.NodeName

	c.logf(2, "配置验证成功，节点ID: %s, 节点名称: %s", verifyData.NodeID, verifyData.NodeName)
	for _, rec := range verifyData.Recommendations {
		c.logf(2, "建议: %s", rec)
	}

	return nil
}

// 建立连接
func (c *Client) connect() error {
	c.logf(2, "连接服务器...")

	// 处理服务器地址格式
	serverAddr := c.Config.Server
	// 移除可能的协议前缀
	serverAddr = strings.TrimPrefix(serverAddr, "http://")
	serverAddr = strings.TrimPrefix(serverAddr, "https://")

	// 构建请求URL
	url := fmt.Sprintf("http://%s:%d/api/client/connect", serverAddr, c.Config.Port)

	// 构建请求体
	reqBody, err := json.Marshal(map[string]interface{}{
		"token":    c.Config.Token,
		"name":     c.Config.Name,
		"version":  "1.0.1",
		"platform": runtime.GOOS,
	})
	if err != nil {
		return fmt.Errorf("序列化连接数据失败: %v", err)
	}

	// 发送请求
	resp, err := c.httpClient.Post(url, "application/json", bytes.NewBuffer(reqBody))
	if err != nil {
		return fmt.Errorf("发送连接请求失败: %v", err)
	}
	defer resp.Body.Close()

	// 解析响应
	var apiResp APIResponse
	if err := json.NewDecoder(resp.Body).Decode(&apiResp); err != nil {
		return fmt.Errorf("解析响应失败: %v", err)
	}

	// 检查响应状态
	if apiResp.Code != 0 {
		return fmt.Errorf("连接失败: %s", apiResp.Message)
	}

	// 解析响应数据
	var connectData struct {
		NodeID     string `json:"node_id"`
		NodeName   string `json:"node_name"`
		ServerTime int64  `json:"server_time"`
	}
	if err := json.Unmarshal(apiResp.Data, &connectData); err != nil {
		return fmt.Errorf("解析连接数据失败: %v", err)
	}

	c.Status.Connected = true
	c.Status.LastConnect = time.Now()
	c.Status.ServerTime = connectData.ServerTime
	c.Status.NodeID = connectData.NodeID
	c.Status.NodeName = connectData.NodeName
	c.Status.Error = ""

	c.logf(2, "连接成功，节点ID: %s, 节点名称: %s", connectData.NodeID, connectData.NodeName)

	return nil
}

// 发送心跳
func (c *Client) sendHeartbeat() error {
	if !c.Status.Connected {
		return fmt.Errorf("未连接到服务器")
	}

	// 处理服务器地址格式
	serverAddr := c.Config.Server
	// 移除可能的协议前缀
	serverAddr = strings.TrimPrefix(serverAddr, "http://")
	serverAddr = strings.TrimPrefix(serverAddr, "https://")

	// 构建请求URL
	url := fmt.Sprintf("http://%s:%d/api/client/heartbeat", serverAddr, c.Config.Port)

	// 构建请求体
	reqBody, err := json.Marshal(map[string]string{
		"token": c.Config.Token,
	})
	if err != nil {
		return fmt.Errorf("序列化心跳数据失败: %v", err)
	}

	// 发送请求
	resp, err := c.httpClient.Post(url, "application/json", bytes.NewBuffer(reqBody))
	if err != nil {
		return fmt.Errorf("发送心跳请求失败: %v", err)
	}
	defer resp.Body.Close()

	// 解析响应
	var apiResp APIResponse
	if err := json.NewDecoder(resp.Body).Decode(&apiResp); err != nil {
		return fmt.Errorf("解析响应失败: %v", err)
	}

	// 检查响应状态
	if apiResp.Code != 0 {
		return fmt.Errorf("心跳失败: %s", apiResp.Message)
	}

	// 解析响应数据
	var heartbeatData struct {
		ServerTime int64 `json:"server_time"`
	}
	if err := json.Unmarshal(apiResp.Data, &heartbeatData); err != nil {
		return fmt.Errorf("解析心跳数据失败: %v", err)
	}

	c.Status.ServerTime = heartbeatData.ServerTime
	c.Status.LastConnect = time.Now()

	c.logf(3, "心跳成功，服务器时间: %d", heartbeatData.ServerTime)

	return nil
}

// 心跳循环
func (c *Client) heartbeatLoop() {
	ticker := time.NewTicker(30 * time.Second)
	defer ticker.Stop()

	for {
		select {
		case <-ticker.C:
			if err := c.sendHeartbeat(); err != nil {
				c.logf(1, "心跳失败: %v", err)
				c.Status.Connected = false
				c.Status.Error = err.Error()

				// 尝试重新连接
				if err := c.connect(); err != nil {
					c.logf(1, "重新连接失败: %v", err)
				}
			}
		case <-c.stopChan:
			return
		}
	}
}

// 记录日志
func (c *Client) logf(level int, format string, args ...interface{}) {
	if c.Config.LogLevel >= level {
		c.logger.Printf(format, args...)
	}
}

// 获取日志目录
func getLogDir() string {
	var logDir string

	switch runtime.GOOS {
	case "windows":
		// Windows: %LOCALAPPDATA%\OpenP2P\logs
		localAppData := os.Getenv("LOCALAPPDATA")
		if localAppData == "" {
			localAppData = filepath.Join(os.Getenv("USERPROFILE"), "AppData", "Local")
		}
		logDir = filepath.Join(localAppData, "OpenP2P", "logs")
	case "darwin":
		// macOS: ~/Library/Application Support/OpenP2P/logs
		homeDir, _ := os.UserHomeDir()
		logDir = filepath.Join(homeDir, "Library", "Application Support", "OpenP2P", "logs")
	default:
		// Linux: ~/.local/share/openp2p/logs
		homeDir, _ := os.UserHomeDir()
		logDir = filepath.Join(homeDir, ".local", "share", "openp2p", "logs")
	}

	// 确保日志目录存在
	if err := os.MkdirAll(logDir, 0755); err != nil {
		// 如果创建失败，使用临时目录
		fmt.Printf("创建日志目录失败: %v，将使用临时目录\n", err)
		logDir = filepath.Join(os.TempDir(), "openp2p", "logs")
		os.MkdirAll(logDir, 0755)
	}

	return logDir
}
