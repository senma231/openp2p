<template>
  <div class="settings-container">
    <div class="page-header">
      <h2>个人设置</h2>
    </div>
    
    <el-card class="settings-card">
      <template #header>
        <div class="card-header">
          <span>基本信息</span>
        </div>
      </template>
      <el-form :model="userForm" :rules="userRules" ref="userFormRef" label-width="100px">
        <el-form-item label="用户名" prop="username">
          <el-input v-model="userForm.username" disabled />
        </el-form-item>
        <el-form-item label="显示名称" prop="displayName">
          <el-input v-model="userForm.displayName" placeholder="请输入显示名称" />
        </el-form-item>
        <el-form-item label="邮箱" prop="email">
          <el-input v-model="userForm.email" placeholder="请输入邮箱" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="updateUserInfo" :loading="userLoading">保存</el-button>
        </el-form-item>
      </el-form>
    </el-card>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted, watch } from 'vue'
import { ElMessage } from 'element-plus'
import { useAuthStore } from '../stores/auth'
import { updateUserInfo as apiUpdateUserInfo } from '../api/user'

const authStore = useAuthStore()
const userFormRef = ref(null)
const userLoading = ref(false)

// 用户信息表单
const userForm = reactive({
  username: '',
  displayName: '',
  email: ''
})

// 用户信息表单验证规则
const userRules = {
  displayName: [
    { max: 20, message: '显示名称长度不能超过20个字符', trigger: 'blur' }
  ],
  email: [
    { type: 'email', message: '请输入正确的邮箱地址', trigger: 'blur' }
  ]
}

// 更新用户信息
const updateUserInfo = async () => {
  if (!userFormRef.value) return
  
  await userFormRef.value.validate(async (valid) => {
    if (!valid) return
    
    userLoading.value = true
    try {
      // 使用authStore中的方法更新用户信息
      await authStore.updateUserInfo({
        displayName: userForm.displayName,
        email: userForm.email
      })
      ElMessage.success('个人信息更新成功')
    } catch (error) {
      ElMessage.error(error.message || '更新失败')
    } finally {
      userLoading.value = false
    }
  })
}

// 获取用户信息
const getUserInfo = () => {
  if (authStore.user) {
    userForm.username = authStore.user.username || ''
    userForm.displayName = authStore.user.displayName || ''
    userForm.email = authStore.user.email || ''
  }
}

// 监听authStore.user变化，更新表单
watch(() => authStore.user, (newUser) => {
  if (newUser) {
    getUserInfo()
  }
}, { immediate: true })

// 组件挂载时获取用户信息
onMounted(() => {
  getUserInfo()
  
  // 如果没有用户信息，尝试重新获取
  if (!authStore.user) {
    authStore.fetchUserInfo().then(() => {
      getUserInfo()
    })
  }
})
</script>

<style lang="scss" scoped>
.settings-container {
  .page-header {
    margin-bottom: 20px;
  }
  
  .settings-card {
    margin-bottom: 20px;
    
    .card-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
    }
  }
}
</style> 