import { defineStore } from 'pinia'
import { ref } from 'vue'
import { getStats } from '../api'

// 系统统计数据状态管理
export const useStatsStore = defineStore('stats', () => {
  const stats = ref({
    onlineNodes: 0,
    activeConnections: 0,
    totalTraffic: 0,
    avgLatency: 0
  })
  const loading = ref(false)

  // 获取统计数据
  const fetchStats = async () => {
    loading.value = true
    try {
      const data = await getStats()
      stats.value = data
    } catch (error) {
      console.error('获取统计数据失败:', error)
    } finally {
      loading.value = false
    }
  }

  // 定时更新统计数据
  const startAutoUpdate = () => {
    fetchStats()
    setInterval(() => {
      fetchStats()
    }, 30000) // 每30秒更新一次
  }

  return {
    stats,
    loading,
    fetchStats,
    startAutoUpdate
  }
})