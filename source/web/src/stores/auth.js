import { defineStore } from 'pinia'
import { ref } from 'vue'
import { login as loginApi, register as registerApi } from '../api'
import { getUserInfo as getUserInfoApi } from '../api/user'

// 用户认证状态管理
export const useAuthStore = defineStore('auth', () => {
  const token = ref(localStorage.getItem('token') || '')
  const user = ref(JSON.parse(localStorage.getItem('user')) || null)
  const role = ref(localStorage.getItem('role') || '')
  const loading = ref(false)

  // 登录
  const login = async (credentials) => {
    loading.value = true
    try {
      const response = await loginApi(credentials)
      token.value = response.data.token
      role.value = response.data.role || 'admin'
      localStorage.setItem('token', response.data.token)
      localStorage.setItem('role', response.data.role || 'admin')
      
      // 登录成功后获取用户信息
      await fetchUserInfo()
      
      return response
    } catch (error) {
      console.error('Login failed:', error)
      throw error
    } finally {
      loading.value = false
    }
  }

  // 获取用户信息
  const fetchUserInfo = async () => {
    if (!token.value) return null
    
    try {
      const response = await getUserInfoApi()
      if (response.code === 0 && response.data) {
        user.value = response.data
        localStorage.setItem('user', JSON.stringify(response.data))
        return response.data
      }
      return null
    } catch (error) {
      console.error('Failed to fetch user info:', error)
      return null
    }
  }

  // 注册
  const register = async (userData) => {
    loading.value = true
    try {
      const response = await registerApi(userData)
      return response
    } catch (error) {
      console.error('Registration failed:', error)
      throw error
    } finally {
      loading.value = false
    }
  }

  // 登出
  const logout = () => {
    token.value = ''
    role.value = ''
    user.value = null
    localStorage.removeItem('token')
    localStorage.removeItem('role')
    localStorage.removeItem('user')
  }

  // 检查用户是否有权限访问某个功能
  const hasPermission = (permission) => {
    if (!role.value || role.value !== 'admin') return false
    return true
  }

  // 初始化时检查token
  if (token.value && !user.value) {
    // 如果有token但没有用户信息，尝试获取用户信息
    fetchUserInfo()
  }

  return {
    token,
    role,
    user,
    loading,
    login,
    register,
    logout,
    hasPermission,
    fetchUserInfo
  }
})