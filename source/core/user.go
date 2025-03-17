package core

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"sync"
	"time"
)

// UserManager 用户管理器
type UserManager struct {
	users     map[string]User
	adminUser *User
	userLock  sync.RWMutex
	dataPath  string
}

// NewUserManager 创建用户管理器
func NewUserManager(dataPath string) *UserManager {
	return &UserManager{
		users:    make(map[string]User),
		dataPath: dataPath,
	}
}

// Init 初始化用户管理器
func (um *UserManager) Init() error {
	// 创建数据目录
	if err := os.MkdirAll(um.dataPath, 0755); err != nil {
		return fmt.Errorf("创建数据目录失败: %v", err)
	}

	// 加载用户数据
	if err := um.loadUsers(); err != nil {
		return fmt.Errorf("加载用户数据失败: %v", err)
	}

	return nil
}

// 加载用户数据
func (um *UserManager) loadUsers() error {
	userFile := filepath.Join(um.dataPath, "users.json")

	// 检查文件是否存在
	if _, err := os.Stat(userFile); os.IsNotExist(err) {
		// 文件不存在，初始化空数据
		um.users = make(map[string]User)
		um.adminUser = nil
		return nil
	}

	// 读取文件
	data, err := os.ReadFile(userFile)
	if err != nil {
		return fmt.Errorf("读取用户数据文件失败: %v", err)
	}

	// 解析数据
	var userData struct {
		Admin *User           `json:"admin"`
		Users map[string]User `json:"users"`
	}
	if err := json.Unmarshal(data, &userData); err != nil {
		return fmt.Errorf("解析用户数据失败: %v", err)
	}

	// 更新用户数据
	um.userLock.Lock()
	defer um.userLock.Unlock()

	um.adminUser = userData.Admin
	um.users = userData.Users

	return nil
}

// 保存用户数据
func (um *UserManager) saveUsers() error {
	userFile := filepath.Join(um.dataPath, "users.json")

	// 准备数据
	um.userLock.RLock()
	userData := struct {
		Admin *User           `json:"admin"`
		Users map[string]User `json:"users"`
	}{
		Admin: um.adminUser,
		Users: um.users,
	}
	um.userLock.RUnlock()

	// 序列化数据
	data, err := json.MarshalIndent(userData, "", "  ")
	if err != nil {
		return fmt.Errorf("序列化用户数据失败: %v", err)
	}

	// 写入文件
	if err := os.WriteFile(userFile, data, 0644); err != nil {
		return fmt.Errorf("写入用户数据文件失败: %v", err)
	}

	return nil
}

// GetAdminUser 获取管理员用户
func (um *UserManager) GetAdminUser() *User {
	um.userLock.RLock()
	defer um.userLock.RUnlock()
	return um.adminUser
}

// SetAdminUser 设置管理员用户
func (um *UserManager) SetAdminUser(user *User) error {
	um.userLock.Lock()
	um.adminUser = user
	um.userLock.Unlock()

	return um.saveUsers()
}

// GetUser 获取用户
func (um *UserManager) GetUser(username string) (*User, bool) {
	um.userLock.RLock()
	defer um.userLock.RUnlock()

	// 检查是否是管理员
	if um.adminUser != nil && um.adminUser.Username == username {
		return um.adminUser, true
	}

	// 检查普通用户
	user, exists := um.users[username]
	if !exists {
		return nil, false
	}
	return &user, true
}

// AddUser 添加用户
func (um *UserManager) AddUser(user User) error {
	um.userLock.Lock()
	um.users[user.Username] = user
	um.userLock.Unlock()

	return um.saveUsers()
}

// UpdateUser 更新用户
func (um *UserManager) UpdateUser(username string, updateFunc func(*User) error) error {
	um.userLock.Lock()
	defer um.userLock.Unlock()

	// 检查是否是管理员
	if um.adminUser != nil && um.adminUser.Username == username {
		if err := updateFunc(um.adminUser); err != nil {
			return err
		}
		return um.saveUsers()
	}

	// 检查普通用户
	user, exists := um.users[username]
	if !exists {
		return fmt.Errorf("用户不存在: %s", username)
	}

	if err := updateFunc(&user); err != nil {
		return err
	}

	um.users[username] = user
	return um.saveUsers()
}

// DeleteUser 删除用户
func (um *UserManager) DeleteUser(username string) error {
	um.userLock.Lock()
	defer um.userLock.Unlock()

	// 检查是否是管理员
	if um.adminUser != nil && um.adminUser.Username == username {
		um.adminUser = nil
		return um.saveUsers()
	}

	// 检查普通用户
	if _, exists := um.users[username]; !exists {
		return fmt.Errorf("用户不存在: %s", username)
	}

	delete(um.users, username)
	return um.saveUsers()
}

// HasAdmin 检查是否有管理员
func (um *UserManager) HasAdmin() bool {
	um.userLock.RLock()
	defer um.userLock.RUnlock()
	return um.adminUser != nil
}

// GetUserInfo 获取用户信息（不包含敏感信息）
func (um *UserManager) GetUserInfo(username string) (map[string]interface{}, error) {
	user, exists := um.GetUser(username)
	if !exists {
		return nil, fmt.Errorf("用户不存在: %s", username)
	}

	// 返回用户信息（不包含敏感信息）
	return map[string]interface{}{
		"username": user.Username,
		"role":     user.Role,
		"created":  user.Created,
		"displayName": func() string {
			if user.DisplayName != "" {
				return user.DisplayName
			}
			return user.Username
		}(),
		"email": user.Email,
	}, nil
}

// UpdateUserInfo 更新用户信息
func (um *UserManager) UpdateUserInfo(username string, displayName, email string) error {
	return um.UpdateUser(username, func(user *User) error {
		user.DisplayName = displayName
		user.Email = email
		return nil
	})
}

// CreateAdmin 创建管理员用户
func (um *UserManager) CreateAdmin(username string, totpKey string) error {
	if um.HasAdmin() {
		return fmt.Errorf("管理员已存在")
	}

	admin := &User{
		Username: username,
		TOTPKey:  totpKey,
		Role:     "admin",
		Created:  time.Now(),
	}

	return um.SetAdminUser(admin)
}

// ResetAdminTOTP 重置管理员TOTP密钥
func (um *UserManager) ResetAdminTOTP(newTOTPKey string) error {
	if !um.HasAdmin() {
		return fmt.Errorf("管理员不存在")
	}

	return um.UpdateUser(um.adminUser.Username, func(user *User) error {
		user.TOTPKey = newTOTPKey
		return nil
	})
}
