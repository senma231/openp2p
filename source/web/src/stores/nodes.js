import { defineStore } from 'pinia'
import { ref } from 'vue'
import { getNodes, addNode, updateNode, deleteNode } from '../api'

// 节点管理状态
export const useNodesStore = defineStore('nodes', () => {
  const nodes = ref([])
  const loading = ref(false)

  // 获取所有节点
  const fetchNodes = async () => {
    loading.value = true
    try {
      const response = await getNodes()
      if (response.code === 0 && Array.isArray(response.data)) {
        // 确保每个节点对象都有必要的字段
        nodes.value = response.data.map(node => ({
          name: node.name || '',
          ip: node.ip || '',
          type: node.type || 'client',
          status: node.status || 'offline',
          latency: node.latency || 0,
          bandwidth: node.bandwidth || 0,
          token: node.token || '',
          ...node // 保留其他字段
        }))
      } else {
        nodes.value = []
        console.error('获取节点列表失败: 数据格式不正确', response)
      }
    } catch (error) {
      console.error('获取节点列表失败:', error)
      nodes.value = []
    } finally {
      loading.value = false
    }
  }

  // 添加节点
  const createNode = async (nodeData) => {
    try {
      const data = {
        name: nodeData.name,
        token: nodeData.token,
        type: nodeData.type,
        bandwidth: nodeData.bandwidth || 0
      }

      // 如果是内网节点，添加额外配置
      if (nodeData.type === 'private') {
        data.privateIp = nodeData.privateIp
        data.proxyNodeId = nodeData.proxyNodeId
      }

      const response = await addNode(data)
      if (response.code === 0) {
        await fetchNodes()
        return true
      }
      throw new Error(response.message || '添加节点失败')
    } catch (error) {
      console.error('添加节点失败:', error)
      throw error
    }
  }

  // 更新节点
  const updateNodeData = async (nodeId, nodeData) => {
    try {
      const data = {
        name: nodeData.name,
        token: nodeData.token,
        type: nodeData.type,
        bandwidth: nodeData.bandwidth || 0
      }

      // 如果是内网节点，添加额外配置
      if (nodeData.type === 'private') {
        data.privateIp = nodeData.privateIp
        data.proxyNodeId = nodeData.proxyNodeId
      }

      const response = await updateNode(nodeId, data)
      if (response.code === 0) {
        await fetchNodes()
        return true
      }
      throw new Error(response.message || '更新节点失败')
    } catch (error) {
      console.error('更新节点失败:', error)
      throw error
    }
  }

  // 删除节点
  const removeNode = async (nodeId) => {
    try {
      const response = await deleteNode(nodeId)
      if (response.code === 0) {
        await fetchNodes()
        return true
      }
      throw new Error(response.message || '删除节点失败')
    } catch (error) {
      console.error('删除节点失败:', error)
      throw error
    }
  }

  // 获取节点详情
  const getNodeDetail = async (nodeId) => {
    try {
      const response = await fetch(`/api/nodes/${nodeId}`)
      if (!response.ok) {
        throw new Error('获取节点详情失败')
      }
      const data = await response.json()
      if (data.code === 0) {
        return data.data
      }
      throw new Error(data.message || '获取节点详情失败')
    } catch (error) {
      console.error('获取节点详情失败:', error)
      throw error
    }
  }

  // 获取节点性能数据
  const getNodePerformance = async (nodeId, timeRange) => {
    try {
      const response = await fetch(`/api/nodes/${nodeId}/performance?timeRange=${timeRange}`)
      if (!response.ok) {
        throw new Error('获取节点性能数据失败')
      }
      const data = await response.json()
      if (data.code === 0) {
        return data.data
      }
      throw new Error(data.message || '获取节点性能数据失败')
    } catch (error) {
      console.error('获取节点性能数据失败:', error)
      throw error
    }
  }

  // 获取节点连接列表
  const getNodeConnections = async (nodeId, params = {}) => {
    try {
      const queryParams = new URLSearchParams()
      if (params.page) queryParams.append('page', params.page)
      if (params.pageSize) queryParams.append('pageSize', params.pageSize)
      
      const response = await fetch(`/api/nodes/${nodeId}/connections?${queryParams.toString()}`)
      if (!response.ok) {
        throw new Error('获取节点连接列表失败')
      }
      const data = await response.json()
      if (data.code === 0) {
        return data.data
      }
      throw new Error(data.message || '获取节点连接列表失败')
    } catch (error) {
      console.error('获取节点连接列表失败:', error)
      throw error
    }
  }

  return {
    nodes,
    loading,
    fetchNodes,
    createNode,
    updateNodeData,
    removeNode,
    getNodeDetail,
    getNodePerformance,
    getNodeConnections
  }
})