import api from './index'

// 更新用户信息
export const updateUserInfo = (userData) => {
  return api.put('/auth/user', userData)
}

// 更新用户密码
export const updatePassword = (passwordData) => {
  return api.put('/auth/password', passwordData)
}

export default {
  updateUserInfo,
  updatePassword
} 