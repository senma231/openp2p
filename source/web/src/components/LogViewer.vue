<template>
  <div class="log-viewer">
    <el-card class="box-card">
      <template #header>
        <div class="card-header">
          <span>系统日志</span>
          <div class="header-controls">
            <el-select v-model="logLevel" placeholder="日志级别" @change="handleLevelChange">
              <el-option label="全部" value="all" />
              <el-option label="错误" value="ERROR" />
              <el-option label="警告" value="WARN" />
              <el-option label="信息" value="INFO" />
              <el-option label="调试" value="DEBUG" />
            </el-select>
            <el-button type="primary" @click="exportLogs">导出日志</el-button>
          </div>
        </div>
      </template>

      <el-table :data="logs" v-loading="loading" style="width: 100%">
        <el-table-column prop="timestamp" label="时间" width="180">
          <template #default="{ row }">
            {{ formatDate(row.timestamp) }}
          </template>
        </el-table-column>
        <el-table-column prop="level" label="级别" width="100">
          <template #default="{ row }">
            <el-tag :type="getLogLevelType(row.level)" size="small">
              {{ row.level }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="message" label="内容" />
      </el-table>

      <div class="pagination-container">
        <el-pagination
          v-model:current-page="currentPage"
          v-model:page-size="pageSize"
          :page-sizes="[10, 20, 50, 100]"
          :total="total"
          layout="total, sizes, prev, pager, next"
          @size-change="handleSizeChange"
          @current-change="handleCurrentChange"
        />
      </div>
    </el-card>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useLogsStore } from '../stores/logs'
import { ElMessage } from 'element-plus'

const logsStore = useLogsStore()
const logs = ref([])
const loading = ref(false)
const total = ref(0)
const currentPage = ref(1)
const pageSize = ref(10)
const logLevel = ref('all')

// 格式化日期
const formatDate = (timestamp) => {
  return new Date(timestamp).toLocaleString()
}

// 获取日志级别对应的标签类型
const getLogLevelType = (level) => {
  const types = {
    ERROR: 'danger',
    WARN: 'warning',
    INFO: 'info',
    DEBUG: ''
  }
  return types[level] || ''
}

// 处理页码变化
const handleCurrentChange = (page) => {
  currentPage.value = page
  fetchLogs()
}

// 处理每页数量变化
const handleSizeChange = (size) => {
  pageSize.value = size
  currentPage.value = 1
  fetchLogs()
}

// 处理日志级别变化
const handleLevelChange = () => {
  currentPage.value = 1
  fetchLogs()
}

// 获取日志数据
const fetchLogs = async () => {
  loading.value = true
  try {
    await logsStore.updateLogLevel(logLevel.value)
    await logsStore.updatePageSize(pageSize.value)
    await logsStore.updateCurrentPage(currentPage.value)
    logs.value = logsStore.logs
    total.value = logsStore.total
  } catch (error) {
    ElMessage.error('获取日志数据失败')
  } finally {
    loading.value = false
  }
}

// 导出日志
const exportLogs = () => {
  // TODO: 实现日志导出功能
  ElMessage.info('日志导出功能开发中')
}

onMounted(() => {
  fetchLogs()
})
</script>

<style scoped>
.log-viewer {
  margin: 20px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.header-controls {
  display: flex;
  gap: 10px;
}

.pagination-container {
  margin-top: 20px;
  display: flex;
  justify-content: flex-end;
}
</style>