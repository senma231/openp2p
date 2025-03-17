<template>
  <div class="node-detail-container">
    <div class="page-header">
      <div class="header-left">
        <el-button @click="$router.back()" icon="ArrowLeft">返回</el-button>
        <h2>节点详情: {{ nodeName }}</h2>
      </div>
      <div class="header-right">
        <el-tag v-if="nodeInfo" :type="nodeInfo.status === 'online' ? 'success' : 'danger'">
          {{ nodeInfo.status === 'online' ? '在线' : '离线' }}
        </el-tag>
      </div>
    </div>

    <el-row :gutter="20" v-loading="loading">
      <!-- 基本信息卡片 -->
      <el-col :span="12">
        <el-card class="detail-card">
          <template #header>
            <div class="card-header">
              <span>基本信息</span>
              <el-button type="primary" size="small" @click="editNode" v-if="nodeInfo">编辑</el-button>
            </div>
          </template>
          <div v-if="nodeInfo" class="info-list">
            <div class="info-item">
              <span class="label">节点名称:</span>
              <span class="value">{{ nodeInfo.name }}</span>
            </div>
            <div class="info-item">
              <span class="label">IP地址:</span>
              <span class="value">{{ nodeInfo.ip }}</span>
            </div>
            <div class="info-item">
              <span class="label">节点类型:</span>
              <span class="value">{{ getNodeTypeText(nodeInfo.type) }}</span>
            </div>
            <div class="info-item">
              <span class="label">共享带宽:</span>
              <span class="value">{{ nodeInfo.bandwidth }}Mbps</span>
            </div>
            <div class="info-item">
              <span class="label">延迟:</span>
              <span class="value">{{ nodeInfo.latency }}ms</span>
            </div>
            <div class="info-item">
              <span class="label">最后在线时间:</span>
              <span class="value">{{ formatTimeDiff(nodeInfo.lastSeen) }}</span>
            </div>
          </div>
          <el-empty v-else description="暂无节点信息"></el-empty>
        </el-card>
      </el-col>

      <!-- 性能监控卡片 -->
      <el-col :span="12">
        <el-card class="detail-card">
          <template #header>
            <div class="card-header">
              <span>性能监控</span>
              <el-select v-model="timeRange" size="small" @change="fetchPerformanceData">
                <el-option label="最近1小时" value="1h"></el-option>
                <el-option label="最近24小时" value="24h"></el-option>
                <el-option label="最近7天" value="7d"></el-option>
              </el-select>
            </div>
          </template>
          <div v-if="nodeInfo && nodeInfo.status === 'online'" class="performance-data">
            <div class="info-item">
              <span class="label">连接状态:</span>
              <span class="value">已连接</span>
            </div>
            <div class="info-item">
              <span class="label">连接时间:</span>
              <span class="value">{{ formatTimeDiff(nodeInfo.lastSeen) }}</span>
            </div>
            <div class="info-item">
              <span class="label">延迟:</span>
              <span class="value">{{ nodeInfo.latency }}ms</span>
            </div>
            <div class="info-item">
              <span class="label">带宽使用:</span>
              <span class="value">{{ nodeInfo.bandwidth ? nodeInfo.bandwidth + 'Mbps' : '未知' }}</span>
            </div>
          </div>
          <el-empty v-else description="节点离线，无法获取性能数据"></el-empty>
        </el-card>
      </el-col>
    </el-row>

    <!-- 连接列表 -->
    <el-card class="detail-card" v-if="false">
      <template #header>
        <div class="card-header">
          <span>活跃连接</span>
          <el-button type="primary" size="small" @click="refreshConnections">刷新</el-button>
        </div>
      </template>
      <el-table :data="connections" style="width: 100%" v-loading="connectionsLoading">
        <el-table-column prop="id" label="连接ID" width="100" />
        <el-table-column prop="sourceIP" label="源IP" />
        <el-table-column prop="sourcePort" label="源端口" width="100" />
        <el-table-column prop="destIP" label="目标IP" />
        <el-table-column prop="destPort" label="目标端口" width="100" />
        <el-table-column prop="protocol" label="协议" width="80">
          <template #default="{ row }">
            <el-tag size="small">{{ row.protocol.toUpperCase() }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="duration" label="持续时间" width="120">
          <template #default="{ row }">
            {{ formatDuration(row.duration) }}
          </template>
        </el-table-column>
        <el-table-column prop="traffic" label="流量" width="120">
          <template #default="{ row }">
            {{ formatTraffic(row.traffic) }}
          </template>
        </el-table-column>
      </el-table>
      <el-pagination
        v-if="connections.length > 0"
        class="pagination"
        :current-page="currentPage"
        :page-size="pageSize"
        :total="totalConnections"
        layout="total, prev, pager, next"
        @current-change="handlePageChange"
      />
      <el-empty v-else description="暂无活跃连接"></el-empty>
    </el-card>

    <!-- 编辑节点对话框 -->
    <el-dialog
      title="编辑节点"
      v-model="dialogVisible"
      width="500px">
      <el-form :model="nodeForm" label-width="100px" v-if="nodeInfo">
        <el-form-item label="节点名称" required>
          <el-input v-model="nodeForm.name" placeholder="请输入节点名称" />
        </el-form-item>
        <el-form-item label="节点类型" required>
          <el-select v-model="nodeForm.type" placeholder="请选择节点类型">
            <el-option label="公网节点" value="public" />
            <el-option label="内网节点" value="private" />
            <el-option label="客户端" value="client" />
          </el-select>
        </el-form-item>
        <el-form-item label="共享带宽">
          <el-input-number
            v-model="nodeForm.bandwidth"
            :min="0"
            :max="1000"
            placeholder="请输入共享带宽"
          />
          <span class="unit">Mbps</span>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="saveNode">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, onMounted, computed, onUnmounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { ArrowLeft } from '@element-plus/icons-vue'
import { useNodesStore } from '../stores/nodes'
import * as echarts from 'echarts'

const route = useRoute()
const router = useRouter()
const nodesStore = useNodesStore()

const nodeName = computed(() => route.params.name)
const loading = ref(true)
const nodeInfo = ref(null)
const timeRange = ref('1h')
const networkChartRef = ref(null)
let networkChart = null
let refreshTimer = null

// 连接相关
const connections = ref([])
const connectionsLoading = ref(false)
const currentPage = ref(1)
const pageSize = ref(10)
const totalConnections = ref(0)

// 编辑节点相关
const dialogVisible = ref(false)
const nodeForm = ref({
  name: '',
  type: '',
  bandwidth: 0
})

// 获取节点信息
const fetchNodeInfo = async () => {
  loading.value = true
  try {
    // 先从store中获取节点列表
    await nodesStore.fetchNodes()
    
    // 然后获取当前节点详情
    const data = await nodesStore.getNodeDetail(nodeName.value)
    if (data) {
      nodeInfo.value = {
        ...data,
        // 确保所有必要字段都有默认值
        status: data.status || 'offline',
        latency: data.latency || 0,
        bandwidth: data.bandwidth || 0,
        lastSeen: data.lastSeen || new Date().toISOString(),
        ip: data.ip || '未知',
        type: data.type || 'client'
      }
      
      // 初始化编辑表单
      nodeForm.value = {
        name: nodeInfo.value.name || '',
        type: nodeInfo.value.type || 'client',
        bandwidth: nodeInfo.value.bandwidth || 0,
        token: nodeInfo.value.token || ''
      }
      
      console.log('节点详情:', nodeInfo.value)
    } else {
      ElMessage.warning('未找到节点信息')
      router.push('/nodes')
    }
  } catch (error) {
    console.error('获取节点信息失败:', error)
    ElMessage.error('获取节点信息失败：' + (error.message || '未知错误'))
  } finally {
    loading.value = false
  }
}

// 获取节点性能数据
const fetchPerformanceData = async () => {
  // 简化实现，仅刷新节点信息
  fetchNodeInfo()
}

// 获取节点连接列表
const fetchConnections = async () => {
  connectionsLoading.value = true
  try {
    const data = await nodesStore.getNodeConnections(nodeName.value, {
      page: currentPage.value,
      pageSize: pageSize.value
    })
    connections.value = data.items || []
    totalConnections.value = data.total || 0
  } catch (error) {
    console.error('获取连接列表失败:', error)
  } finally {
    connectionsLoading.value = false
  }
}

// 刷新连接列表
const refreshConnections = () => {
  fetchNodeInfo()
}

// 处理分页变化
const handlePageChange = (page) => {
  currentPage.value = page
  fetchConnections()
}

// 初始化网络流量图表
const initNetworkChart = () => {
  if (networkChart) {
    networkChart.dispose()
  }
  
  if (!networkChartRef.value) return
  
  networkChart = echarts.init(networkChartRef.value)
  const option = {
    title: {
      text: '网络流量',
      left: 'center'
    },
    tooltip: {
      trigger: 'axis',
      formatter: function(params) {
        let result = params[0].name + '<br/>'
        params.forEach(param => {
          result += param.seriesName + ': ' + formatTraffic(param.value) + '<br/>'
        })
        return result
      }
    },
    legend: {
      data: ['上行流量', '下行流量'],
      bottom: 0
    },
    grid: {
      left: '3%',
      right: '4%',
      bottom: '10%',
      top: '15%',
      containLabel: true
    },
    xAxis: {
      type: 'category',
      boundaryGap: false,
      data: []
    },
    yAxis: {
      type: 'value',
      axisLabel: {
        formatter: value => formatTraffic(value)
      }
    },
    series: [
      {
        name: '上行流量',
        type: 'line',
        data: [],
        areaStyle: {},
        smooth: true
      },
      {
        name: '下行流量',
        type: 'line',
        data: [],
        areaStyle: {},
        smooth: true
      }
    ]
  }
  
  networkChart.setOption(option)
  
  // 响应窗口大小变化
  window.addEventListener('resize', () => {
    networkChart && networkChart.resize()
  })
}

// 更新网络流量图表
const updateNetworkChart = (data) => {
  if (!networkChart) return
  
  networkChart.setOption({
    xAxis: {
      data: data.timestamps || []
    },
    series: [
      {
        name: '上行流量',
        data: data.upload || []
      },
      {
        name: '下行流量',
        data: data.download || []
      }
    ]
  })
}

// 编辑节点
const editNode = () => {
  if (!nodeInfo.value) return
  
  // 确保表单数据正确
  nodeForm.value = {
    name: nodeInfo.value.name || '',
    type: nodeInfo.value.type || 'client',
    bandwidth: nodeInfo.value.bandwidth || 0,
    token: nodeInfo.value.token || ''
  }
  
  dialogVisible.value = true
}

// 保存节点
const saveNode = async () => {
  if (!nodeInfo.value) return
  
  try {
    await nodesStore.updateNodeData(nodeInfo.value.name, nodeForm.value)
    ElMessage.success('更新成功')
    dialogVisible.value = false
    // 重新获取节点信息
    fetchNodeInfo()
  } catch (error) {
    ElMessage.error('保存失败：' + (error.message || '未知错误'))
  }
}

// 格式化时间差
const formatTimeDiff = (timestamp) => {
  if (!timestamp) return '未知'
  
  const now = new Date()
  const date = new Date(timestamp)
  const diffSeconds = Math.floor((now - date) / 1000)
  
  if (diffSeconds < 60) return `${diffSeconds}秒前`
  
  const minutes = Math.floor(diffSeconds / 60)
  const remainingSeconds = diffSeconds % 60
  
  let result = ''
  if (minutes > 0) result += `${minutes}分钟`
  if (remainingSeconds > 0 || result === '') result += `${remainingSeconds}秒`
  
  return result
}

// 获取节点类型文本
const getNodeTypeText = (type) => {
  const types = {
    'public': '公网节点',
    'private': '内网节点',
    'client': '客户端'
  }
  return types[type] || '未知'
}

// 组件挂载时获取数据
onMounted(() => {
  fetchNodeInfo()
  
  // 定时刷新数据
  refreshTimer = setInterval(() => {
    fetchNodeInfo()
  }, 30000) // 每30秒刷新一次
})

// 组件卸载时清除定时器
onUnmounted(() => {
  if (refreshTimer) {
    clearInterval(refreshTimer)
  }
})
</script>

<style lang="scss" scoped>
.node-detail-container {
  .page-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 20px;
    
    .header-left {
      display: flex;
      align-items: center;
      gap: 10px;
    }
  }
  
  .detail-card {
    margin-bottom: 20px;
    
    .card-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
    }
    
    .info-list {
      .info-item {
        margin-bottom: 12px;
        display: flex;
        
        .label {
          width: 120px;
          color: #606266;
        }
        
        .value {
          font-weight: 500;
        }
      }
    }
    
    .performance-data {
      .info-item {
        margin-bottom: 12px;
        display: flex;
        
        .label {
          width: 120px;
          color: #606266;
        }
        
        .value {
          font-weight: 500;
        }
      }
    }
  }
  
  .pagination {
    margin-top: 20px;
    display: flex;
    justify-content: flex-end;
  }
  
  .unit {
    margin-left: 8px;
    color: #909399;
  }
}
</style>