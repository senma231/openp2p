import axios from 'axios'
import { ElMessage } from 'element-plus'
import router from '../router'

// 创建axios实例
const api = axios.create({
    baseURL: '/api',
    timeout: 15000,
    headers: {
        'Content-Type': 'application/json'
    }
})

// 请求拦截器
api.interceptors.request.use(
    config => {
        const token = localStorage.getItem('token')
        if (token) {
            config.headers['Authorization'] = token
        }
        return config
    },
    error => {
        console.error('Request error:', error)
        return Promise.reject(error)
    }
)

// 响应拦截器
api.interceptors.response.use(
    response => {
        const res = response.data
        return res
    },
    error => {
        if (error.response) {
            if (error.response.status === 401) {
                localStorage.removeItem('token')
                router.push('/login')
                return Promise.reject(new Error('未授权，请重新登录'))
            }
            return Promise.reject(new Error(error.response.data.message || '请求失败'))
        }
        return Promise.reject(new Error('网络错误'))
    }
)

export default api

// 认证API
export const login = (credentials) => {
    return api.post('/auth/login', credentials)
}

export const register = (userData) => {
    return api.post('/auth/register', userData)
}

export const getUserInfo = () => {
    return api.get('/user/info')
}

// 更新用户信息
export const updateUserInfo = (userData) => {
    return api.put('/user/info', userData)
}

// 统计数据API
export const getStats = () => {
    return api.get('/stats')
}

// 节点管理API
export const getNodes = async () => {
    try {
        const response = await api.get('/nodes')
        return response
    } catch (error) {
        console.error('获取节点列表失败:', error)
        return { code: 1, message: error.message, data: [] }
    }
}

export const getNodeDetail = async (nodeId) => {
    try {
        const response = await api.get(`/nodes/${nodeId}`)
        return response
    } catch (error) {
        console.error('获取节点详情失败:', error)
        return { code: 1, message: error.message, data: null }
    }
}

export const getNodePerformance = (nodeId, timeRange) => {
    return api.get(`/nodes/${nodeId}/performance`, { params: { timeRange } })
}

export const getNodeConnections = (nodeId, params) => {
    return api.get(`/nodes/${nodeId}/connections`, { params })
}

export const addNode = async (nodeData) => {
    try {
        const response = await api.post('/nodes', nodeData)
        return response
    } catch (error) {
        console.error('添加节点失败:', error)
        return { code: 1, message: error.message }
    }
}

export const updateNode = async (nodeId, nodeData) => {
    try {
        const response = await api.put(`/nodes/${nodeId}`, nodeData)
        return response
    } catch (error) {
        console.error('更新节点失败:', error)
        return { code: 1, message: error.message }
    }
}

export const deleteNode = async (nodeId) => {
    try {
        const response = await api.delete(`/nodes/${nodeId}`)
        return response
    } catch (error) {
        console.error('删除节点失败:', error)
        return { code: 1, message: error.message }
    }
}

// 端口映射API
export const getMappings = () => {
    return api.get('/mappings')
}

export const addMapping = (mappingData) => {
    return api.post('/mappings', mappingData)
}

export const updateMapping = (mappingId, mappingData) => {
    return api.put(`/mappings/${mappingId}`, mappingData)
}

export const deleteMapping = (mappingId) => {
    return api.delete(`/mappings/${mappingId}`)
}

// 高级映射（级联映射）API
export const getAdvancedMappings = () => {
    return api.get('/advanced-mappings')
}

export const getAdvancedMappingDetail = (mappingId) => {
    return api.get(`/advanced-mappings/${mappingId}`)
}

export const addAdvancedMapping = (mappingData) => {
    return api.post('/advanced-mappings', mappingData)
}

export const updateAdvancedMapping = (mappingId, mappingData) => {
    return api.put(`/advanced-mappings/${mappingId}`, mappingData)
}

export const deleteAdvancedMapping = (mappingId) => {
    return api.delete(`/advanced-mappings/${mappingId}`)
}

export const startAdvancedMapping = (mappingId) => {
    return api.post(`/advanced-mappings/${mappingId}/start`)
}

export const stopAdvancedMapping = (mappingId) => {
    return api.post(`/advanced-mappings/${mappingId}/stop`)
}

export const getAdvancedMappingTraffic = (mappingId, timeRange) => {
    return api.get(`/advanced-mappings/${mappingId}/traffic`, { params: { timeRange } })
}

export const getAdvancedMappingHistory = (mappingId, params = {}) => {
    return api.get(`/advanced-mappings/${mappingId}/history`, { params })
}

export const exportAdvancedMappingHistory = (mappingId) => {
    return api.get(`/advanced-mappings/${mappingId}/history/export`, {
        responseType: 'blob'
    })
}

export const testAdvancedMappingConnection = (mappingId) => {
    return api.post(`/advanced-mappings/${mappingId}/test`)
}

// 日志查询API
export const getLogs = (params) => {
    return api.get('/logs', { params })
}

export const exportLogs = (params) => {
    return api.get('/logs/export', { 
        params,
        responseType: 'blob'
    })
}

// 认证相关API
export const resetTOTP = (data) => {
    return api.post('/auth/reset-totp', data)
}

// 检查管理员是否存在
export const checkAdminExists = async () => {
    try {
        const response = await api.get('/auth/check-admin')
        return response  // 返回完整的响应对象
    } catch (error) {
        console.error('检查管理员账号失败:', error)
        throw error
    }
}

export const deleteAdmin = (data) => {
    return api.post('/auth/delete-admin', data)
}