import { defineStore } from 'pinia'
import { ref } from 'vue'

// 日志管理状态
export const useLogStore = defineStore('log', () => {
  const logs = ref([])
  const loading = ref(false)
  const total = ref(0)

  const fetchLogs = async (params) => {
    loading.value = true
    try {
      // TODO: 调用后端API获取日志列表
      const queryParams = new URLSearchParams({
        page: params.page || 1,
        pageSize: params.pageSize || 10,
        level: params.level || 'all',
        startTime: params.startTime,
        endTime: params.endTime,
        module: params.module
      })

      const response = await fetch(`/api/logs?${queryParams}`)
      const data = await response.json()
      logs.value = data.items
      total.value = data.total
    } catch (error) {
      console.error('获取日志列表失败:', error)
    } finally {
      loading.value = false
    }
  }

  const clearLogs = async () => {
    try {
      // TODO: 调用后端API清空日志
      await fetch('/api/logs/clear', {
        method: 'POST'
      })
      logs.value = []
      total.value = 0
    } catch (error) {
      console.error('清空日志失败:', error)
      throw error
    }
  }

  const exportLogs = async (params) => {
    try {
      // TODO: 调用后端API导出日志
      const queryParams = new URLSearchParams({
        level: params.level || 'all',
        startTime: params.startTime,
        endTime: params.endTime,
        module: params.module
      })

      const response = await fetch(`/api/logs/export?${queryParams}`)
      const blob = await response.blob()
      const url = window.URL.createObjectURL(blob)
      const a = document.createElement('a')
      a.href = url
      a.download = `logs_${new Date().toISOString()}.csv`
      document.body.appendChild(a)
      a.click()
      window.URL.revokeObjectURL(url)
      document.body.removeChild(a)
    } catch (error) {
      console.error('导出日志失败:', error)
      throw error
    }
  }

  return {
    logs,
    loading,
    total,
    fetchLogs,
    clearLogs,
    exportLogs
  }
})