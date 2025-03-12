<template>
  <div class="login-container">
    <el-card class="login-card">
      <div class="login-header">
        <h2>OpenP2P 管理后台</h2>
        <p>请登录以继续</p>
      </div>
      <el-form :model="loginForm" :rules="rules" ref="loginFormRef" @submit.prevent="handleLogin">
        <el-form-item prop="username">
          <el-input 
            v-model="loginForm.username" 
            placeholder="用户名" 
            prefix-icon="User"
            autocomplete="username"
          />
        </el-form-item>
        <el-form-item prop="totpCode">
          <el-input 
            v-model="loginForm.totpCode" 
            placeholder="动态验证码" 
            prefix-icon="Key"
            maxlength="6"
          />
        </el-form-item>
        <el-form-item>
          <el-button 
            type="primary" 
            :loading="loading" 
            class="login-button" 
            @click="handleLogin"
          >
            登录
          </el-button>
        </el-form-item>
      </el-form>
      <div class="first-time-tip" v-show="showFirstTimeTip">
        首次启动系统？请先 <router-link to="/init">初始化管理员账号</router-link>
      </div>
    </el-card>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { User, Key } from '@element-plus/icons-vue'
import { useAuthStore } from '../stores/auth'
import { checkAdminExists } from '../api'

const router = useRouter()
const authStore = useAuthStore()
const loading = ref(false)
const loginFormRef = ref(null)
const showFirstTimeTip = ref(false)

// 登录表单
const loginForm = reactive({
  username: '',
  totpCode: ''
})

// 表单验证规则
const rules = {
  username: [
    { required: true, message: '请输入用户名', trigger: 'blur' }
  ],
  totpCode: [
    { required: true, message: '请输入动态验证码', trigger: 'blur' },
    { min: 6, max: 6, message: '验证码必须是6位数字', trigger: 'blur' }
  ]
}

// 登录处理
const handleLogin = async () => {
  if (!loginFormRef.value) return
  
  try {
    await loginFormRef.value.validate()
    loading.value = true
    
    const response = await authStore.login({
      username: loginForm.username,
      totp_code: loginForm.totpCode
    })
    
    // 保存token
    localStorage.setItem('token', response.data.token)
    
    // 登录成功提示
    ElMessage.success('登录成功')
    
    // 跳转到首页
    router.push('/')
  } catch (error) {
    ElMessage.error(error.message || '登录失败')
  } finally {
    loading.value = false
  }
}

// 检查管理员账号
const checkAdmin = async () => {
  try {
    const response = await checkAdminExists()
    if (!response.data) {
      router.push('/init')
    }
  } catch (error) {
    console.error('检查管理员账号失败:', error)
  }
}

// 在组件挂载时检查管理员账号
onMounted(() => {
  checkAdmin()
})
</script>

<style lang="scss" scoped>
.login-container {
  height: 100vh;
  display: flex;
  justify-content: center;
  align-items: center;
  background-color: #f5f7fa;
}

.login-card {
  width: 400px;
  
  .login-header {
    text-align: center;
    margin-bottom: 30px;
    
    h2 {
      margin: 0;
      font-size: 24px;
      color: #303133;
    }
    
    p {
      margin: 10px 0 0;
      font-size: 14px;
      color: #909399;
    }
  }
  
  .login-button {
    width: 100%;
  }
  
  .first-time-tip {
    text-align: center;
    font-size: 14px;
    margin-top: 20px;
    padding: 10px;
    background-color: #ecf5ff;
    border-radius: 4px;
    color: #409EFF;
    
    a {
      color: #409EFF;
      font-weight: bold;
      text-decoration: none;
      
      &:hover {
        text-decoration: underline;
      }
    }
  }
}
</style> 