<template>
  <div class="register-container">
    <el-card class="register-card">
      <div class="register-header">
        <h2>OpenP2P 管理后台</h2>
        <p>创建管理员账号</p>
      </div>
      
      <!-- 注册表单 -->
      <el-form 
        v-if="!registrationComplete" 
        :model="registerForm" 
        :rules="rules" 
        ref="registerFormRef" 
        @submit.prevent="handleRegister"
      >
        <el-form-item prop="username">
          <el-input 
            v-model="registerForm.username" 
            placeholder="用户名" 
            prefix-icon="User"
            autocomplete="username"
          />
        </el-form-item>
        <el-form-item>
          <el-button 
            type="primary" 
            :loading="loading" 
            class="register-button" 
            @click="handleRegister"
          >
            注册
          </el-button>
        </el-form-item>
        <div class="login-link">
          已有账号？<router-link to="/login">立即登录</router-link>
        </div>
      </el-form>

      <!-- TOTP 设置说明 -->
      <div v-else class="totp-setup">
        <h3>请完成两步验证设置</h3>
        <p class="setup-desc">使用 Google Authenticator 或其他兼容的验证器 App 扫描下方二维码</p>
        
        <div class="qr-container">
          <img :src="totpQRCode" alt="TOTP QR Code" class="qr-code" />
        </div>
        
        <div class="manual-key">
          <p>如果无法扫描二维码，请手动输入以下密钥：</p>
          <el-input
            v-model="totpKey"
            readonly
            class="key-input"
          >
            <template #append>
              <el-button @click="copyTOTPKey">
                复制
              </el-button>
            </template>
          </el-input>
        </div>

        <div class="setup-actions">
          <el-button type="primary" @click="goToLogin">
            完成设置，前往登录
          </el-button>
        </div>
      </div>
    </el-card>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { User } from '@element-plus/icons-vue'
import { useAuthStore } from '../stores/auth'

const router = useRouter()
const authStore = useAuthStore()
const loading = ref(false)
const registerFormRef = ref(null)
const registrationComplete = ref(false)
const totpKey = ref('')
const totpQRCode = ref('')

// 注册表单
const registerForm = reactive({
  username: ''
})

// 表单验证规则
const rules = {
  username: [
    { required: true, message: '请输入用户名', trigger: 'blur' },
    { min: 3, message: '用户名长度不能少于3个字符', trigger: 'blur' }
  ]
}

// 注册处理
const handleRegister = async () => {
  if (!registerFormRef.value) return
  
  try {
    await registerFormRef.value.validate()
    loading.value = true
    
    const response = await authStore.register({
      username: registerForm.username
    })
    
    // 保存TOTP信息
    totpKey.value = response.data.totp_key
    totpQRCode.value = response.data.qr_url
    registrationComplete.value = true
    
    ElMessage.success('注册成功，请设置两步验证')
  } catch (error) {
    ElMessage.error(error.message || '注册失败')
  } finally {
    loading.value = false
  }
}

// 复制TOTP密钥
const copyTOTPKey = async () => {
  try {
    await navigator.clipboard.writeText(totpKey.value)
    ElMessage.success('密钥已复制到剪贴板')
  } catch (err) {
    ElMessage.error('复制失败，请手动复制')
  }
}

// 前往登录页
const goToLogin = () => {
  router.push('/login')
}
</script>

<style lang="scss" scoped>
.register-container {
  height: 100vh;
  display: flex;
  justify-content: center;
  align-items: center;
  background-color: #f5f7fa;
}

.register-card {
  width: 400px;
  
  .register-header {
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
  
  .register-button {
    width: 100%;
  }
  
  .login-link {
    text-align: center;
    font-size: 14px;
    margin-top: 20px;
    
    a {
      color: #409EFF;
      text-decoration: none;
      
      &:hover {
        text-decoration: underline;
      }
    }
  }
}

.totp-setup {
  text-align: center;
  
  h3 {
    margin: 0 0 20px;
    font-size: 18px;
    color: #303133;
  }
  
  .setup-desc {
    margin-bottom: 20px;
    color: #606266;
  }
  
  .qr-container {
    margin: 20px 0;
    padding: 20px;
    background: #fff;
    border-radius: 4px;
    
    .qr-code {
      max-width: 200px;
      height: auto;
    }
  }
  
  .manual-key {
    margin: 20px 0;
    
    p {
      margin-bottom: 10px;
      color: #606266;
    }
    
    .key-input {
      width: 100%;
      margin-top: 10px;
    }
  }
  
  .setup-actions {
    margin-top: 30px;
  }
}
</style> 