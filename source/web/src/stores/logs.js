import { defineStore } from 'pinia'
import { ref } from 'vue'
import { getLogs } from '../api'

// 日志管理状态
export const useLogsStore = defineStore('logs', () => {
  const logs = ref([])
  const loading = ref(false)
  const total = ref(0)
  const currentPage = ref(1)
  const pageSize = ref(10)
  const logLevel = ref('all')

  // 获取日志列表
  const fetchLogs = async () => {
    loading.value = true
    try {
      const data = await getLogs({
        page: currentPage.value,
        pageSize: pageSize.value,
        level: logLevel.value !== 'all' ? logLevel.value : undefined
      })
      logs.value = data.logs
      total.value = data.total
    } catch (error) {
      console.error('获取日志列表失败:', error)
    } finally {
      loading.value = false
    }
  }

  // 更新分页大小
  const updatePageSize = (size) => {
    pageSize.value = size
    currentPage.value = 1
    fetchLogs()
  }

  // 更新当前页码
  const updateCurrentPage = (page) => {
    currentPage.value = page
    fetchLogs()
  }

  // 更新日志级别筛选
  const updateLogLevel = (level) => {
    logLevel.value = level
    currentPage.value = 1
    fetchLogs()
  }

  return {
    logs,
    loading,
    total,
    currentPage,
    pageSize,
    logLevel,
    fetchLogs,
    updatePageSize,
    updateCurrentPage,
    updateLogLevel
  }
})