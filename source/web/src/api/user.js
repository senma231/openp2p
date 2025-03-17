import api from './index'

// 获取用户信息
export const getUserInfo = () => {
  return api.get('/user/info')
}

// 更新用户信息
export const updateUserInfo = (userData) => {
  return api.put('/user/info', userData)
}

// 更新用户密码
export const updatePassword = (passwordData) => {
  return api.put('/auth/password', passwordData)
}

export default {
  getUserInfo,
  updateUserInfo,
  updatePassword
} 