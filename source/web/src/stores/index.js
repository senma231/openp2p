import { defineStore } from 'pinia'
import { ref } from 'vue'

// 节点管理状态
export const useNodeStore = defineStore('node', () => {
  const nodes = ref([])
  const loading = ref(false)

  const fetchNodes = async () => {
    loading.value = true
    try {
      // TODO: 调用后端API获取节点列表
      const response = await fetch('/api/nodes')
      nodes.value = await response.json()
    } catch (error) {
      console.error('获取节点列表失败:', error)
    } finally {
      loading.value = false
    }
  }

  const addNode = async (node) => {
    try {
      // TODO: 调用后端API添加节点
      await fetch('/api/nodes', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(node)
      })
      await fetchNodes()
    } catch (error) {
      console.error('添加节点失败:', error)
      throw error
    }
  }

  const updateNode = async (node) => {
    try {
      // TODO: 调用后端API更新节点
      await fetch(`/api/nodes/${node.name}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(node)
      })
      await fetchNodes()
    } catch (error) {
      console.error('更新节点失败:', error)
      throw error
    }
  }

  const deleteNode = async (nodeName) => {
    try {
      // TODO: 调用后端API删除节点
      await fetch(`/api/nodes/${nodeName}`, {
        method: 'DELETE'
      })
      await fetchNodes()
    } catch (error) {
      console.error('删除节点失败:', error)
      throw error
    }
  }

  return {
    nodes,
    loading,
    fetchNodes,
    addNode,
    updateNode,
    deleteNode
  }
})

// 端口映射状态
export const useMappingStore = defineStore('mapping', () => {
  const mappings = ref([])
  const loading = ref(false)

  const fetchMappings = async () => {
    loading.value = true
    try {
      // TODO: 调用后端API获取映射列表
      const response = await fetch('/api/mappings')
      mappings.value = await response.json()
    } catch (error) {
      console.error('获取映射列表失败:', error)
    } finally {
      loading.value = false
    }
  }

  const addMapping = async (mapping) => {
    try {
      // TODO: 调用后端API添加映射
      await fetch('/api/mappings', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(mapping)
      })
      await fetchMappings()
    } catch (error) {
      console.error('添加映射失败:', error)
      throw error
    }
  }

  const updateMapping = async (mapping) => {
    try {
      // TODO: 调用后端API更新映射
      await fetch(`/api/mappings/${mapping.name}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(mapping)
      })
      await fetchMappings()
    } catch (error) {
      console.error('更新映射失败:', error)
      throw error
    }
  }

  const deleteMapping = async (mappingName) => {
    try {
      // TODO: 调用后端API删除映射
      await fetch(`/api/mappings/${mappingName}`, {
        method: 'DELETE'
      })
      await fetchMappings()
    } catch (error) {
      console.error('删除映射失败:', error)
      throw error
    }
  }

  return {
    mappings,
    loading,
    fetchMappings,
    addMapping,
    updateMapping,
    deleteMapping
  }
})