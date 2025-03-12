import { defineStore } from 'pinia'
import { ref } from 'vue'

// 仪表盘状态管理
export const useDashboardStore = defineStore('dashboard', () => {
  const stats = ref({
    onlineNodes: 0,
    activeConnections: 0,
    totalTraffic: 0,
    avgLatency: 0
  })

  const trafficData = ref([])
  const nodeStatusData = ref([])
  const loading = ref(false)

  const fetchStats = async () => {
    loading.value = true
    try {
      // TODO: 调用后端API获取统计数据
      const response = await fetch('/api/stats')
      const data = await response.json()
      stats.value = data
    } catch (error) {
      console.error('获取统计数据失败:', error)
    } finally {
      loading.value = false
    }
  }

  const fetchTrafficData = async (timeRange) => {
    try {
      // TODO: 调用后端API获取流量趋势数据
      const response = await fetch(`/api/stats/traffic?range=${timeRange}`)
      const data = await response.json()
      trafficData.value = data
    } catch (error) {
      console.error('获取流量趋势数据失败:', error)
    }
  }

  const fetchNodeStatusData = async () => {
    try {
      // TODO: 调用后端API获取节点状态分布数据
      const response = await fetch('/api/stats/node-status')
      const data = await response.json()
      nodeStatusData.value = data
    } catch (error) {
      console.error('获取节点状态分布数据失败:', error)
    }
  }

  // 定时刷新数据
  const startAutoRefresh = () => {
    fetchStats()
    fetchNodeStatusData()
    const interval = setInterval(() => {
      fetchStats()
      fetchNodeStatusData()
    }, 30000) // 每30秒刷新一次
    return interval
  }

  return {
    stats,
    trafficData,
    nodeStatusData,
    loading,
    fetchStats,
    fetchTrafficData,
    fetchNodeStatusData,
    startAutoRefresh
  }
})