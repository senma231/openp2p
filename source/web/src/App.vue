<template>
  <div>
    <!-- 登录页面不显示布局 -->
    <template v-if="isLoginPage">
      <router-view />
    </template>
    
    <!-- 应用主布局 -->
    <el-container v-else class="app-container">
      <el-aside width="200px">
        <el-menu
          :router="true"
          :default-active="activeMenu"
          class="el-menu-vertical"
          background-color="#304156"
          text-color="#bfcbd9"
          active-text-color="#409EFF">
          <el-menu-item index="/dashboard">
            <el-icon><Monitor /></el-icon>
            <span>仪表盘</span>
          </el-menu-item>
          <el-menu-item index="/nodes">
            <el-icon><Connection /></el-icon>
            <span>节点管理</span>
          </el-menu-item>
          <el-menu-item index="/mappings">
            <el-icon><Share /></el-icon>
            <span>端口映射</span>
          </el-menu-item>
          <el-menu-item index="/advanced-mapping">
            <el-icon><SetUp /></el-icon>
            <span>高级映射</span>
          </el-menu-item>
          <el-menu-item index="/logs">
            <el-icon><Document /></el-icon>
            <span>日志查看</span>
          </el-menu-item>
        </el-menu>
      </el-aside>
      <el-container>
        <el-header height="60px">
          <div class="header-left">
            <h2>OpenP2P 管理后台</h2>
          </div>
          <div class="header-right">
            <el-dropdown @command="handleCommand">
              <span class="user-dropdown">
                {{ username }}
                <el-icon><CaretBottom /></el-icon>
              </span>
              <template #dropdown>
                <el-dropdown-menu>
                  <el-dropdown-item command="settings">个人设置</el-dropdown-item>
                  <el-dropdown-item command="logout">退出登录</el-dropdown-item>
                </el-dropdown-menu>
              </template>
            </el-dropdown>
          </div>
        </el-header>
        <el-main>
          <router-view v-slot="{ Component }">
            <keep-alive>
              <component :is="Component" />
            </keep-alive>
          </router-view>
        </el-main>
      </el-container>
    </el-container>
  </div>
</template>

<script setup>
import { computed, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { Monitor, Connection, Share, Document, CaretBottom, SetUp } from '@element-plus/icons-vue'
import { useAuthStore } from './stores/auth'
import { ElMessage } from 'element-plus'

const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()

// 判断当前是否为登录页
const isLoginPage = computed(() => {
  return route.path === '/login' || route.path === '/init'
})

// 获取当前激活的菜单项
const activeMenu = computed(() => route.path)

// 获取用户名
const username = computed(() => {
  return authStore.user?.username || '管理员'
})

// 处理下拉菜单命令
const handleCommand = (command) => {
  if (command === 'logout') {
    authStore.logout()
    ElMessage.success('已退出登录')
    router.push('/login')
  } else if (command === 'settings') {
    router.push('/settings')
  }
}
</script>

<style lang="scss" scoped>
.app-container {
  height: 100vh;
}

.el-aside {
  background-color: #304156;
  .el-menu {
    border-right: none;
  }
}

.el-header {
  background-color: #fff;
  border-bottom: 1px solid #e6e6e6;
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0 20px;
}

.header-right {
  .user-dropdown {
    cursor: pointer;
    color: #606266;
    display: flex;
    align-items: center;
    gap: 4px;
  }
}

.el-main {
  background-color: #f0f2f5;
  padding: 20px;
}
</style>