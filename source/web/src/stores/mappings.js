import { defineStore } from 'pinia'
import { ref } from 'vue'
import { getMappings, addMapping, updateMapping, deleteMapping } from '../api'

// 端口映射状态管理
export const useMappingsStore = defineStore('mappings', () => {
  const mappings = ref([])
  const loading = ref(false)

  // 获取所有映射
  const fetchMappings = async () => {
    loading.value = true
    try {
      const data = await getMappings()
      mappings.value = data
      return data
    } catch (error) {
      console.error('获取映射列表失败:', error)
    } finally {
      loading.value = false
    }
  }

  // 添加映射
  const createMapping = async (mappingData) => {
    try {
      await addMapping(mappingData)
      await fetchMappings()
      return true
    } catch (error) {
      console.error('添加映射失败:', error)
      throw error
    }
  }

  // 更新映射
  const updateMappingData = async (mappingId, mappingData) => {
    try {
      await updateMapping(mappingId, mappingData)
      await fetchMappings()
      return true
    } catch (error) {
      console.error('更新映射失败:', error)
      throw error
    }
  }

  // 删除映射
  const removeMapping = async (mappingId) => {
    try {
      await deleteMapping(mappingId)
      await fetchMappings()
      return true
    } catch (error) {
      console.error('删除映射失败:', error)
      throw error
    }
  }

  // 获取映射详情
  const getMappingDetail = async (mappingId) => {
    try {
      const response = await fetch(`/api/mappings/${mappingId}`)
      if (!response.ok) {
        throw new Error('获取映射详情失败')
      }
      const data = await response.json()
      return data
    } catch (error) {
      console.error('获取映射详情失败:', error)
      throw error
    }
  }

  // 获取映射流量数据
  const getMappingTraffic = async (mappingId, timeRange) => {
    try {
      const response = await fetch(`/api/mappings/${mappingId}/traffic?timeRange=${timeRange}`)
      if (!response.ok) {
        throw new Error('获取映射流量数据失败')
      }
      const data = await response.json()
      return data
    } catch (error) {
      console.error('获取映射流量数据失败:', error)
      throw error
    }
  }

  // 获取映射连接历史
  const getMappingHistory = async (mappingId, params = {}) => {
    try {
      const queryParams = new URLSearchParams()
      if (params.page) queryParams.append('page', params.page)
      if (params.pageSize) queryParams.append('pageSize', params.pageSize)
      
      const response = await fetch(`/api/mappings/${mappingId}/history?${queryParams.toString()}`)
      if (!response.ok) {
        throw new Error('获取映射连接历史失败')
      }
      const data = await response.json()
      return data
    } catch (error) {
      console.error('获取映射连接历史失败:', error)
      throw error
    }
  }

  // 启动映射
  const startMapping = async (mappingId) => {
    try {
      const response = await fetch(`/api/mappings/${mappingId}/start`, {
        method: 'POST'
      })
      if (!response.ok) {
        throw new Error('启动映射失败')
      }
      return true
    } catch (error) {
      console.error('启动映射失败:', error)
      throw error
    }
  }

  // 停止映射
  const stopMapping = async (mappingId) => {
    try {
      const response = await fetch(`/api/mappings/${mappingId}/stop`, {
        method: 'POST'
      })
      if (!response.ok) {
        throw new Error('停止映射失败')
      }
      return true
    } catch (error) {
      console.error('停止映射失败:', error)
      throw error
    }
  }

  return {
    mappings,
    loading,
    fetchMappings,
    createMapping,
    updateMappingData,
    removeMapping,
    getMappingDetail,
    getMappingTraffic,
    getMappingHistory,
    startMapping,
    stopMapping
  }
})