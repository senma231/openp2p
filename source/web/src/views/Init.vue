<template>
  <div class="init-container">
    <el-card class="init-card">
      <div class="init-header">
        <h2>OpenP2P 管理后台</h2>
        <p>初始化管理员账号</p>
      </div>
      
      <!-- 初始化表单 -->
      <el-form 
        v-if="!setupComplete" 
        :model="initForm" 
        :rules="rules" 
        ref="initFormRef" 
        @submit.prevent="handleInit"
      >
        <el-form-item prop="username">
          <el-input 
            v-model="initForm.username" 
            placeholder="管理员用户名" 
            prefix-icon="User"
          />
        </el-form-item>
        <el-form-item>
          <el-button 
            type="primary" 
            :loading="loading" 
            class="init-button" 
            @click="handleInit"
          >
            创建管理员账号
          </el-button>
        </el-form-item>
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

        <div v-if="testCode" class="test-code">
          <p>测试环境验证码：</p>
          <el-tag size="large" type="success">{{ testCode }}</el-tag>
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
import { ref, reactive, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { User } from '@element-plus/icons-vue'
import { useAuthStore } from '../stores/auth'
import { checkAdminExists } from '../api'

const router = useRouter()
const authStore = useAuthStore()
const loading = ref(false)
const initFormRef = ref(null)
const setupComplete = ref(false)
const totpKey = ref('')
const totpQRCode = ref('')
const testCode = ref('')

// 初始化表单
const initForm = reactive({
  username: ''
})

// 表单验证规则
const rules = {
  username: [
    { required: true, message: '请输入管理员用户名', trigger: 'blur' },
    { min: 3, message: '用户名长度不能少于3个字符', trigger: 'blur' }
  ]
}

// 初始化处理
const handleInit = async () => {
  if (!initFormRef.value) return
  
  try {
    await initFormRef.value.validate()
    loading.value = true
    
    const response = await authStore.register({
      username: initForm.username
    })
    
    // 保存TOTP信息
    totpKey.value = response.data.totp_key
    totpQRCode.value = response.data.qr_url
    testCode.value = response.data.test_code
    setupComplete.value = true
    
    ElMessage.success('管理员账号创建成功，请设置两步验证')
  } catch (error) {
    ElMessage.error(error.message || '创建管理员账号失败')
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
  ElMessage.success('初始化完成，请使用管理员账号和验证码登录')
  router.push('/login')
}

// 在组件挂载时检查管理员账号
onMounted(async () => {
  try {
    const response = await checkAdminExists()
    if (response.data) {
      ElMessage.warning('管理员账号已存在')
      router.push('/login')
    }
  } catch (error) {
    console.error('检查管理员账号失败:', error)
  }
})
</script>

<style lang="scss" scoped>
.init-container {
  height: 100vh;
  display: flex;
  justify-content: center;
  align-items: center;
  background-color: #f5f7fa;
}

.init-card {
  width: 400px;
  
  .init-header {
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
  
  .init-button {
    width: 100%;
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
    margin: 20px auto;
    padding: 20px;
    background: #fff;
    border-radius: 4px;
    width: 250px;
    height: 250px;
    display: flex;
    justify-content: center;
    align-items: center;
    
    .qr-code {
      width: 200px;
      height: 200px;
      object-fit: contain;
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

.test-code {
  margin: 20px 0;
  text-align: center;
  
  p {
    margin-bottom: 10px;
    color: #606266;
  }
  
  .el-tag {
    font-size: 24px;
    padding: 12px 20px;
  }
}
</style> 