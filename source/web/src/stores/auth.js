import { defineStore } from 'pinia'
import { ref } from 'vue'
import { login as loginApi, register as registerApi } from '../api'

// 用户认证状态管理
export const useAuthStore = defineStore('auth', () => {
  const token = ref(localStorage.getItem('token') || '')
  const role = ref('')
  const loading = ref(false)

  // 登录
  const login = async (credentials) => {
    loading.value = true
    try {
      const response = await loginApi(credentials)
      token.value = response.data.token
      role.value = response.data.role
      localStorage.setItem('token', response.data.token)
      return response
    } catch (error) {
      console.error('Login failed:', error)
      throw error
    } finally {
      loading.value = false
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
    localStorage.removeItem('token')
  }

  // 检查用户是否有权限访问某个功能
  const hasPermission = (permission) => {
    if (!role.value || role.value !== 'admin') return false
    return true
  }

  // 初始化时检查token
  if (token.value) {
    // 如果有token但没有用户信息，清除token
    if (!role.value) {
      logout()
    }
  }

  return {
    token,
    role,
    loading,
    login,
    register,
    logout,
    hasPermission
  }
})