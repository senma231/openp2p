<template>
  <div class="logs-container">
    <div class="page-header">
      <h2>系统日志</h2>
      <div class="header-controls">
        <el-select v-model="logLevel" placeholder="日志级别" @change="handleLevelChange">
          <el-option label="全部" value="all" />
          <el-option label="错误" value="error" />
          <el-option label="警告" value="warning" />
          <el-option label="信息" value="info" />
          <el-option label="调试" value="debug" />
        </el-select>
        <el-button type="primary" @click="exportLogs">
          <el-icon><Download /></el-icon>导出日志
        </el-button>
      </div>
    </div>

    <el-table :data="logs" v-loading="loading" style="width: 100%">
      <el-table-column prop="timestamp" label="时间" width="180">
        <template #default="{ row }">
          {{ formatDate(row.timestamp) }}
        </template>
      </el-table-column>
      <el-table-column prop="level" label="级别" width="100">
        <template #default="{ row }">
          <el-tag :type="getLogLevelType(row.level)" size="small">
            {{ getLogLevelText(row.level) }}
          </el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="module" label="模块" width="120" />
      <el-table-column prop="message" label="内容" show-overflow-tooltip />
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
  </div>
</template>

<script setup>
import { onMounted } from 'vue'
import { useLogsStore } from '../stores/logs'
import { storeToRefs } from 'pinia'
import { ElMessage } from 'element-plus'
import { Download } from '@element-plus/icons-vue'

const logsStore = useLogsStore()
const { logs, loading, total, currentPage, pageSize, logLevel } = storeToRefs(logsStore)

// 格式化日期
const formatDate = (timestamp) => {
  return new Date(timestamp).toLocaleString()
}

// 获取日志级别对应的标签类型
const getLogLevelType = (level) => {
  const types = {
    error: 'danger',
    warning: 'warning',
    info: 'info',
    debug: ''
  }
  return types[level] || ''
}

// 获取日志级别对应的显示文本
const getLogLevelText = (level) => {
  const texts = {
    error: '错误',
    warning: '警告',
    info: '信息',
    debug: '调试'
  }
  return texts[level] || level
}

// 处理分页大小变化
const handleSizeChange = (val) => {
  logsStore.updatePageSize(val)
}

// 处理页码变化
const handleCurrentChange = (val) => {
  logsStore.updateCurrentPage(val)
}

// 处理日志级别变化
const handleLevelChange = () => {
  logsStore.updateLogLevel(logLevel.value)
}

// 导出日志
const exportLogs = async () => {
  try {
    const data = await logsStore.exportLogs()
    const blob = new Blob([data], { type: 'text/plain;charset=utf-8' })
    const url = window.URL.createObjectURL(blob)
    const link = document.createElement('a')
    link.href = url
    link.setAttribute('download', `system-logs-${new Date().toISOString().split('T')[0]}.txt`)
    document.body.appendChild(link)
    link.click()
    document.body.removeChild(link)
    window.URL.revokeObjectURL(url)
    ElMessage.success('日志导出成功')
  } catch (error) {
    ElMessage.error('日志导出失败')
  }
}

// 组件挂载时获取日志数据
onMounted(() => {
  logsStore.fetchLogs()
})
</script>

<style lang="scss" scoped>
.logs-container {
  padding: 20px;

  .page-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 20px;

    .header-controls {
      display: flex;
      gap: 10px;
    }
  }

  .pagination-container {
    margin-top: 20px;
    display: flex;
    justify-content: flex-end;
  }
}
</style>