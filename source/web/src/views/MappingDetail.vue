<template>
  <div class="mapping-detail-container">
    <div class="page-header">
      <div class="header-left">
        <el-button @click="$router.back()" icon="ArrowLeft">返回</el-button>
        <h2>映射详情: {{ mappingName }}</h2>
      </div>
      <div class="header-right">
        <el-tag v-if="mappingInfo" :type="mappingInfo.status === 'connected' ? 'success' : 'danger'">
          {{ mappingInfo.status === 'connected' ? '已连接' : '未连接' }}
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
              <div>
                <el-button type="primary" size="small" @click="editMapping" v-if="mappingInfo">编辑</el-button>
                <el-button 
                  :type="mappingInfo && mappingInfo.status === 'connected' ? 'danger' : 'success'" 
                  size="small" 
                  @click="toggleMappingStatus" 
                  v-if="mappingInfo"
                >
                  {{ mappingInfo && mappingInfo.status === 'connected' ? '停止' : '启动' }}
                </el-button>
              </div>
            </div>
          </template>
          <div v-if="mappingInfo" class="info-list">
            <div class="info-item">
              <span class="label">应用名称:</span>
              <span class="value">{{ mappingInfo.name }}</span>
            </div>
            <div class="info-item">
              <span class="label">协议:</span>
              <span class="value">{{ mappingInfo.protocol.toUpperCase() }}</span>
            </div>
            <div class="info-item">
              <span class="label">本地端口:</span>
              <span class="value">{{ mappingInfo.srcPort }}</span>
            </div>
            <div class="info-item">
              <span class="label">目标节点:</span>
              <span class="value">{{ mappingInfo.peerNode }}</span>
            </div>
            <div class="info-item">
              <span class="label">目标端口:</span>
              <span class="value">{{ mappingInfo.dstPort }}</span>
            </div>
            <div class="info-item">
              <span class="label">创建时间:</span>
              <span class="value">{{ formatDate(mappingInfo.createdAt) }}</span>
            </div>
            <div class="info-item">
              <span class="label">最后连接时间:</span>
              <span class="value">{{ formatDate(mappingInfo.lastConnected) }}</span>
            </div>
          </div>
          <el-empty v-else description="暂无映射信息"></el-empty>
        </el-card>
      </el-col>

      <!-- 流量监控卡片 -->
      <el-col :span="12">
        <el-card class="detail-card">
          <template #header>
            <div class="card-header">
              <span>流量监控</span>
              <el-select v-model="timeRange" size="small" @change="fetchTrafficData">
                <el-option label="最近1小时" value="1h"></el-option>
                <el-option label="最近24小时" value="24h"></el-option>
                <el-option label="最近7天" value="7d"></el-option>
              </el-select>
            </div>
          </template>
          <div v-if="mappingInfo && mappingInfo.status === 'connected'" class="traffic-data">
            <div class="traffic-stats">
              <div class="stat-item">
                <div class="stat-label">总上行流量</div>
                <div class="stat-value">{{ formatTraffic(mappingInfo.totalUpload || 0) }}</div>
              </div>
              <div class="stat-item">
                <div class="stat-label">总下行流量</div>
                <div class="stat-value">{{ formatTraffic(mappingInfo.totalDownload || 0) }}</div>
              </div>
              <div class="stat-item">
                <div class="stat-label">当前上行速率</div>
                <div class="stat-value">{{ formatSpeed(mappingInfo.uploadSpeed || 0) }}</div>
              </div>
              <div class="stat-item">
                <div class="stat-label">当前下行速率</div>
                <div class="stat-value">{{ formatSpeed(mappingInfo.downloadSpeed || 0) }}</div>
              </div>
            </div>
            <div ref="trafficChartRef" class="chart-container"></div>
          </div>
          <el-empty v-else description="映射未连接，无法获取流量数据"></el-empty>
        </el-card>
      </el-col>
    </el-row>

    <!-- 连接历史 -->
    <el-card class="detail-card">
      <template #header>
        <div class="card-header">
          <span>连接历史</span>
          <el-button type="primary" size="small" @click="refreshHistory">刷新</el-button>
        </div>
      </template>
      <el-table :data="connectionHistory" style="width: 100%" v-loading="historyLoading">
        <el-table-column prop="id" label="连接ID" width="100" />
        <el-table-column prop="sourceIP" label="源IP" />
        <el-table-column prop="startTime" label="开始时间">
          <template #default="{ row }">
            {{ formatDate(row.startTime) }}
          </template>
        </el-table-column>
        <el-table-column prop="endTime" label="结束时间">
          <template #default="{ row }">
            {{ row.endTime ? formatDate(row.endTime) : '仍在连接' }}
          </template>
        </el-table-column>
        <el-table-column prop="duration" label="持续时间">
          <template #default="{ row }">
            {{ formatDuration(row.duration) }}
          </template>
        </el-table-column>
        <el-table-column prop="upload" label="上行流量">
          <template #default="{ row }">
            {{ formatTraffic(row.upload) }}
          </template>
        </el-table-column>
        <el-table-column prop="download" label="下行流量">
          <template #default="{ row }">
            {{ formatTraffic(row.download) }}
          </template>
        </el-table-column>
      </el-table>
      <el-pagination
        v-if="connectionHistory.length > 0"
        class="pagination"
        :current-page="currentPage"
        :page-size="pageSize"
        :total="totalHistory"
        layout="total, prev, pager, next"
        @current-change="handlePageChange"
      />
      <el-empty v-else description="暂无连接历史"></el-empty>
    </el-card>

    <!-- 编辑映射对话框 -->
    <el-dialog
      title="编辑映射"
      v-model="dialogVisible"
      width="500px">
      <el-form :model="mappingForm" label-width="100px" v-if="mappingInfo">
        <el-form-item label="应用名称" required>
          <el-input v-model="mappingForm.name" placeholder="请输入应用名称" />
        </el-form-item>
        <el-form-item label="协议" required>
          <el-select v-model="mappingForm.protocol" placeholder="请选择协议">
            <el-option label="TCP" value="tcp" />
            <el-option label="UDP" value="udp" />
          </el-select>
        </el-form-item>
        <el-form-item label="本地端口" required>
          <el-input-number
            v-model="mappingForm.srcPort"
            :min="1"
            :max="65535"
            placeholder="请输入本地端口"
          />
        </el-form-item>
        <el-form-item label="目标节点" required>
          <el-select v-model="mappingForm.peerNode" placeholder="请选择目标节点">
            <el-option
              v-for="node in nodes"
              :key="node.name"
              :label="node.name"
              :value="node.name"
            />
          </el-select>
        </el-form-item>
        <el-form-item label="目标端口" required>
          <el-input-number
            v-model="mappingForm.dstPort"
            :min="1"
            :max="65535"
            placeholder="请输入目标端口"
          />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="saveMapping">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, onMounted, computed, onUnmounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { ArrowLeft } from '@element-plus/icons-vue'
import { useMappingsStore } from '../stores/mappings'
import { useNodesStore } from '../stores/nodes'
import * as echarts from 'echarts'

const route = useRoute()
const router = useRouter()
const mappingsStore = useMappingsStore()
const nodesStore = useNodesStore()

const mappingName = computed(() => route.params.name)
const loading = ref(true)
const mappingInfo = ref(null)
const timeRange = ref('1h')
const trafficChartRef = ref(null)
let trafficChart = null
let refreshTimer = null

// 连接历史相关
const connectionHistory = ref([])
const historyLoading = ref(false)
const currentPage = ref(1)
const pageSize = ref(10)
const totalHistory = ref(0)

// 编辑映射相关
const dialogVisible = ref(false)
const mappingForm = ref({
  name: '',
  protocol: 'tcp',
  srcPort: 0,
  peerNode: '',
  dstPort: 0
})
const nodes = ref([])

// 获取映射信息
const fetchMappingInfo = async () => {
  loading.value = true
  try {
    const data = await mappingsStore.getMappingDetail(mappingName.value)
    mappingInfo.value = data
    // 初始化图表
    if (data && data.status === 'connected') {
      initTrafficChart()
      fetchTrafficData()
    }
  } catch (error) {
    ElMessage.error('获取映射信息失败：' + error.message)
  } finally {
    loading.value = false
  }
}

// 获取流量数据
const fetchTrafficData = async () => {
  if (!mappingInfo.value || mappingInfo.value.status !== 'connected') return
  
  try {
    const data = await mappingsStore.getMappingTraffic(mappingName.value, timeRange.value)
    updateTrafficChart(data)
  } catch (error) {
    console.error('获取流量数据失败:', error)
  }
}

// 获取连接历史
const fetchConnectionHistory = async () => {
  historyLoading.value = true
  try {
    const data = await mappingsStore.getMappingHistory(mappingName.value, {
      page: currentPage.value,
      pageSize: pageSize.value
    })
    connectionHistory.value = data.items || []
    totalHistory.value = data.total || 0
  } catch (error) {
    console.error('获取连接历史失败:', error)
  } finally {
    historyLoading.value = false
  }
}

// 刷新连接历史
const refreshHistory = () => {
  fetchConnectionHistory()
}

// 处理分页变化
const handlePageChange = (page) => {
  currentPage.value = page
  fetchConnectionHistory()
}

// 初始化流量图表
const initTrafficChart = () => {
  if (trafficChart) {
    trafficChart.dispose()
  }
  
  if (!trafficChartRef.value) return
  
  trafficChart = echarts.init(trafficChartRef.value)
  const option = {
    title: {
      text: '流量趋势',
      left: 'center'
    },
    tooltip: {
      trigger: 'axis',
      formatter: function(params) {
        let result = params[0].name + '<br/>'
        params.forEach(param => {
          result += param.seriesName + ': ' + formatTraffic(param.value) + '/s<br/>'
        })
        return result
      }
    },
    legend: {
      data: ['上行速率', '下行速率'],
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
        formatter: value => formatTraffic(value) + '/s'
      }
    },
    series: [
      {
        name: '上行速率',
        type: 'line',
        data: [],
        areaStyle: {},
        smooth: true
      },
      {
        name: '下行速率',
        type: 'line',
        data: [],
        areaStyle: {},
        smooth: true
      }
    ]
  }
  
  trafficChart.setOption(option)
  
  // 响应窗口大小变化
  window.addEventListener('resize', () => {
    trafficChart && trafficChart.resize()
  })
}

// 更新流量图表
const updateTrafficChart = (data) => {
  if (!trafficChart) return
  
  trafficChart.setOption({
    xAxis: {
      data: data.timestamps || []
    },
    series: [
      {
        name: '上行速率',
        data: data.uploadSpeeds || []
      },
      {
        name: '下行速率',
        data: data.downloadSpeeds || []
      }
    ]
  })
}

// 编辑映射
const editMapping = () => {
  mappingForm.value = {
    name: mappingInfo.value.name,
    protocol: mappingInfo.value.protocol,
    srcPort: mappingInfo.value.srcPort,
    peerNode: mappingInfo.value.peerNode,
    dstPort: mappingInfo.value.dstPort
  }
  dialogVisible.value = true
}

// 保存映射
const saveMapping = async () => {
  try {
    await mappingsStore.updateMappingData(mappingName.value, mappingForm.value)
    ElMessage.success('更新成功')
    dialogVisible.value = false
    fetchMappingInfo()
  } catch (error) {
    ElMessage.error('保存失败：' + error.message)
  }
}

// 切换映射状态
const toggleMappingStatus = async () => {
  if (!mappingInfo.value) return
  
  try {
    if (mappingInfo.value.status === 'connected') {
      await mappingsStore.stopMapping(mappingName.value)
      ElMessage.success('映射已停止')
    } else {
      await mappingsStore.startMapping(mappingName.value)
      ElMessage.success('映射已启动')
    }
    fetchMappingInfo()
  } catch (error) {
    ElMessage.error('操作失败：' + error.message)
  }
}

// 格式化日期
const formatDate = (timestamp) => {
  if (!timestamp) return '未知'
  return new Date(timestamp).toLocaleString()
}

// 格式化持续时间
const formatDuration = (seconds) => {
  if (!seconds) return '0秒'
  
  const hours = Math.floor(seconds / 3600)
  const minutes = Math.floor((seconds % 3600) / 60)
  const remainingSeconds = seconds % 60
  
  let result = ''
  if (hours > 0) result += `${hours}小时`
  if (minutes > 0) result += `${minutes}分钟`
  if (remainingSeconds > 0 || result === '') result += `${remainingSeconds}秒`
  
  return result
}

// 格式化流量
const formatTraffic = (bytes) => {
  if (bytes === 0 || !bytes) return '0 B'
  
  const k = 1024
  const sizes = ['B', 'KB', 'MB', 'GB', 'TB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
}

// 格式化速率
const formatSpeed = (bytesPerSecond) => {
  return formatTraffic(bytesPerSecond) + '/s'
}

// 获取节点列表
const fetchNodes = async () => {
  try {
    const data = await nodesStore.fetchNodes()
    nodes.value = data || []
  } catch (error) {
    console.error('获取节点列表失败:', error)
  }
}

// 组件挂载时获取数据
onMounted(() => {
  fetchMappingInfo()
  fetchConnectionHistory()
  fetchNodes()
  
  // 定时刷新数据
  refreshTimer = setInterval(() => {
    if (mappingInfo.value && mappingInfo.value.status === 'connected') {
      fetchMappingInfo()
      fetchTrafficData()
    }
  }, 30000) // 每30秒刷新一次
})

// 组件卸载时清除定时器和图表
onUnmounted(() => {
  if (refreshTimer) {
    clearInterval(refreshTimer)
  }
  
  if (trafficChart) {
    trafficChart.dispose()
    trafficChart = null
  }
})
</script>

<style lang="scss" scoped>
.mapping-detail-container {
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
    
    .traffic-data {
      .traffic-stats {
        display: flex;
        flex-wrap: wrap;
        gap: 20px;
        margin-bottom: 20px;
        
        .stat-item {
          flex: 1;
          min-width: 120px;
          text-align: center;
          
          .stat-label {
            color: #606266;
            margin-bottom: 5px;
          }
          
          .stat-value {
            font-size: 18px;
            font-weight: 500;
          }
        }
      }
    }
    
    .chart-container {
      height: 300px;
      margin-top: 20px;
    }
  }
  
  .pagination {
    margin-top: 20px;
    display: flex;
    justify-content: flex-end;
  }
}
</style> 