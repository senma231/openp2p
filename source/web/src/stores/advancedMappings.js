import { defineStore } from 'pinia'
import { ref } from 'vue'
import { 
  getAdvancedMappings, 
  getAdvancedMappingDetail, 
  addAdvancedMapping, 
  updateAdvancedMapping, 
  deleteAdvancedMapping,
  startAdvancedMapping,
  stopAdvancedMapping,
  getAdvancedMappingTraffic,
  getAdvancedMappingHistory,
  testAdvancedMappingConnection
} from '../api'

export const useAdvancedMappingsStore = defineStore('advancedMappings', () => {
  const advancedMappings = ref([])
  const loading = ref(false)

  // 获取高级映射列表
  const fetchAdvancedMappings = async () => {
    loading.value = true
    try {
      const response = await getAdvancedMappings()
      advancedMappings.value = response.data || []
      return response.data
    } catch (error) {
      console.error('获取高级映射列表失败:', error)
      throw error
    } finally {
      loading.value = false
    }
  }

  // 添加高级映射
  const addMapping = async (mappingData) => {
    try {
      const response = await addAdvancedMapping(mappingData)
      await fetchAdvancedMappings()
      return response
    } catch (error) {
      console.error('添加高级映射失败:', error)
      throw error
    }
  }

  // 更新高级映射
  const updateMapping = async (name, mappingData) => {
    try {
      const response = await updateAdvancedMapping(name, mappingData)
      await fetchAdvancedMappings()
      return response
    } catch (error) {
      console.error('更新高级映射失败:', error)
      throw error
    }
  }

  // 删除高级映射
  const removeMapping = async (name) => {
    try {
      const response = await deleteAdvancedMapping(name)
      await fetchAdvancedMappings()
      return response
    } catch (error) {
      console.error('删除高级映射失败:', error)
      throw error
    }
  }

  // 获取高级映射详情
  const getAdvancedMappingDetails = async (mappingId) => {
    try {
      const response = await getAdvancedMappingDetail(mappingId)
      return response
    } catch (error) {
      console.error('获取高级映射详情失败:', error)
      throw error
    }
  }

  // 启动高级映射
  const startMapping = async (mappingId) => {
    try {
      await startAdvancedMapping(mappingId)
      return true
    } catch (error) {
      console.error('启动高级映射失败:', error)
      throw error
    }
  }

  // 停止高级映射
  const stopMapping = async (mappingId) => {
    try {
      await stopAdvancedMapping(mappingId)
      return true
    } catch (error) {
      console.error('停止高级映射失败:', error)
      throw error
    }
  }

  // 获取高级映射流量数据
  const getAdvancedMappingTrafficData = async (mappingId, timeRange) => {
    try {
      const response = await getAdvancedMappingTraffic(mappingId, timeRange)
      return response
    } catch (error) {
      console.error('获取高级映射流量数据失败:', error)
      throw error
    }
  }

  // 获取高级映射连接历史
  const getAdvancedMappingHistoryData = async (mappingId, params = {}) => {
    try {
      const response = await getAdvancedMappingHistory(mappingId, params)
      return response
    } catch (error) {
      console.error('获取高级映射连接历史失败:', error)
      throw error
    }
  }

  // 导出高级映射历史记录
  const exportAdvancedMappingHistory = async (mappingId) => {
    try {
      const response = await api.get(`/advanced-mappings/${mappingId}/history/export`, {
        responseType: 'blob'
      })
      return response
    } catch (error) {
      console.error('导出高级映射历史记录失败:', error)
      throw error
    }
  }

  // 测试高级映射连接
  const testConnection = async (mappingId) => {
    try {
      const response = await testAdvancedMappingConnection(mappingId)
      return response
    } catch (error) {
      console.error('测试高级映射连接失败:', error)
      throw error
    }
  }

  return {
    advancedMappings,
    loading,
    fetchAdvancedMappings,
    addMapping,
    updateMapping,
    removeMapping,
    getAdvancedMappingDetails,
    startMapping,
    stopMapping,
    getAdvancedMappingTrafficData,
    getAdvancedMappingHistoryData,
    exportAdvancedMappingHistory,
    testConnection
  }
}) 