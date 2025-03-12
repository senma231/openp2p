<template>
  <div class="advanced-mapping-detail-container">
    <div class="page-header">
      <div class="header-left">
        <el-button @click="$router.back()" icon="ArrowLeft">返回</el-button>
        <h2>高级映射详情: {{ mappingName }}</h2>
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
                <el-button type="danger" size="small" @click="handleDelete" v-if="mappingInfo">删除</el-button>
              </div>
            </div>
          </template>
          <div v-if="mappingInfo" class="info-list">
            <div class="info-item">
              <span class="label">映射名称:</span>
              <span class="value">{{ mappingInfo.name }}</span>
            </div>
            <div class="info-item">
              <span class="label">协议:</span>
              <span class="value">{{ mappingInfo.protocol.toUpperCase() }}</span>
            </div>
            <div class="info-item">
              <span class="label">入口端口:</span>
              <span class="value">{{ mappingInfo.entryPort }}</span>
            </div>
            <div class="info-item">
              <span class="label">目标端口:</span>
              <span class="value">{{ mappingInfo.targetPort }}</span>
            </div>
            <div class="info-item">
              <span class="label">创建时间:</span>
              <span class="value">{{ formatDate(mappingInfo.createdAt) }}</span>
            </div>
            <div class="info-item">
              <span class="label">最后连接时间:</span>
              <span class="value">{{ formatDate(mappingInfo.lastConnected) }}</span>
            </div>
            <div class="info-item">
              <span class="label">备注:</span>
              <span class="value">{{ mappingInfo.description || '无' }}</span>
            </div>
          </div>
          <el-empty v-else description="暂无映射信息"></el-empty>
        </el-card>
      </el-col>

      <!-- 链路状态卡片 -->
      <el-col :span="12">
        <el-card class="detail-card">
          <template #header>
            <div class="card-header">
              <span>链路状态</span>
              <div>
                <el-button type="primary" size="small" @click="testMappingConnection" :loading="testing">
                  测试连接
                </el-button>
                <el-tooltip content="刷新链路状态" placement="top">
                  <el-button type="primary" size="small" @click="fetchMappingInfo" :loading="loading">
                    <el-icon><Refresh /></el-icon>
                  </el-button>
                </el-tooltip>
              </div>
            </div>
          </template>
          <div v-if="mappingInfo" class="chain-status">
            <div class="chain-visualization">
              <div v-for="(node, index) in mappingInfo.nodes" :key="index" class="chain-node">
                <div class="node-box" :class="{ 'node-active': node.status === 'online' }">
                  <div class="node-name">{{ node.name }}</div>
                  <div class="node-type">{{ getNodeTypeText(node.type) }}</div>
                  <div class="node-ip">{{ node.ip }}</div>
                  <div class="node-status">
                    <el-tag size="small" :type="node.status === 'online' ? 'success' : 'danger'">
                      {{ node.status === 'online' ? '在线' : '离线' }}
                    </el-tag>
                  </div>
                  <div class="node-latency" v-if="node.latency !== undefined">
                    延迟: {{ node.latency }}ms
                  </div>
                </div>
                <el-icon v-if="index < mappingInfo.nodes.length - 1" class="chain-arrow">
                  <ArrowRight />
                </el-icon>
              </div>
            </div>
            <div v-if="testResult" class="test-result" :class="testResult.success ? 'success' : 'error'">
              <el-icon>
                <component :is="testResult.success ? 'CircleCheck' : 'CircleClose'" />
              </el-icon>
              <span>{{ testResult.message }}</span>
              <div class="test-details" v-if="testResult.details">
                <div v-for="(detail, index) in testResult.details" :key="index" class="detail-item">
                  <span class="detail-label">{{ detail.node }}:</span>
                  <span class="detail-value">{{ detail.latency }}ms</span>
                </div>
              </div>
            </div>
          </div>
          <el-empty v-else description="暂无链路信息"></el-empty>
        </el-card>
      </el-col>
    </el-row>

    <!-- 流量监控卡片 -->
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

    <!-- 连接历史 -->
    <el-card class="detail-card">
      <template #header>
        <div class="card-header">
          <span>连接历史</span>
          <div>
            <el-button type="primary" size="small" @click="exportHistory" :loading="exporting">导出</el-button>
            <el-button type="primary" size="small" @click="refreshHistory">刷新</el-button>
          </div>
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
  </div>
</template>

<script setup>
import { ref, onMounted, computed, onUnmounted, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { ArrowLeft, ArrowRight, CircleCheck, CircleClose, Refresh } from '@element-plus/icons-vue'
import { useAdvancedMappingsStore } from '../stores/advancedMappings'
import * as echarts from 'echarts'
import { useTheme } from '../composables/theme'

const route = useRoute()
const router = useRouter()
const advancedMappingsStore = useAdvancedMappingsStore()
const { isDark } = useTheme()

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

// 测试连接相关
const testing = ref(false)
const testResult = ref(null)

// 导出相关
const exporting = ref(false)

// 获取映射信息
const fetchMappingInfo = async () => {
  loading.value = true
  try {
    const data = await advancedMappingsStore.getAdvancedMappingDetails(mappingName.value)
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
    const data = await advancedMappingsStore.getAdvancedMappingTrafficData(mappingName.value, timeRange.value)
    updateTrafficChart(data)
  } catch (error) {
    console.error('获取流量数据失败:', error)
  }
}

// 获取连接历史
const fetchConnectionHistory = async () => {
  historyLoading.value = true
  try {
    const data = await advancedMappingsStore.getAdvancedMappingHistoryData(mappingName.value, {
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

// 测试映射连接
const testMappingConnection = async () => {
  testing.value = true
  testResult.value = null
  try {
    const result = await advancedMappingsStore.testConnection(mappingName.value)
    testResult.value = {
      success: result.success,
      message: result.message || (result.success ? '连接测试成功' : '连接测试失败')
    }
  } catch (error) {
    testResult.value = {
      success: false,
      message: '连接测试失败：' + error.message
    }
  } finally {
    testing.value = false
  }
}

// 切换映射状态
const toggleMappingStatus = async () => {
  if (!mappingInfo.value) return
  
  try {
    if (mappingInfo.value.status === 'connected') {
      await advancedMappingsStore.stopMapping(mappingName.value)
      ElMessage.success('映射已停止')
    } else {
      await advancedMappingsStore.startMapping(mappingName.value)
      ElMessage.success('映射已启动')
    }
    fetchMappingInfo()
  } catch (error) {
    ElMessage.error('操作失败：' + error.message)
  }
}

// 编辑映射
const editMapping = () => {
  router.push({
    path: '/advanced-mapping',
    query: { edit: mappingName.value }
  })
}

// 删除映射
const handleDelete = () => {
  ElMessageBox.confirm(
    '确定要删除该映射吗？删除后无法恢复。',
    '删除确认',
    {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning',
    }
  ).then(async () => {
    try {
      await advancedMappingsStore.removeAdvancedMapping(mappingName.value)
      ElMessage.success('删除成功')
      router.push('/advanced-mapping')
    } catch (error) {
      ElMessage.error('删除失败：' + error.message)
    }
  }).catch(() => {})
}

// 导出历史记录
const exportHistory = async () => {
  exporting.value = true
  try {
    const response = await advancedMappingsStore.exportAdvancedMappingHistory(mappingName.value)
    const blob = new Blob([response], { type: 'text/csv' })
    const url = window.URL.createObjectURL(blob)
    const link = document.createElement('a')
    link.href = url
    link.setAttribute('download', `mapping-history-${mappingName.value}.csv`)
    document.body.appendChild(link)
    link.click()
    document.body.removeChild(link)
    window.URL.revokeObjectURL(url)
    ElMessage.success('导出成功')
  } catch (error) {
    ElMessage.error('导出失败：' + error.message)
  } finally {
    exporting.value = false
  }
}

// 初始化流量图表
const initTrafficChart = () => {
  if (trafficChart) {
    trafficChart.dispose()
  }
  
  if (!trafficChartRef.value) return
  
  trafficChart = echarts.init(trafficChartRef.value, isDark.value ? 'dark' : undefined)
  const option = {
    backgroundColor: 'transparent',
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
        areaStyle: {
          opacity: 0.1
        },
        smooth: true,
        lineStyle: {
          width: 2
        },
        itemStyle: {
          borderWidth: 2
        }
      },
      {
        name: '下行速率',
        type: 'line',
        data: [],
        areaStyle: {
          opacity: 0.1
        },
        smooth: true,
        lineStyle: {
          width: 2
        },
        itemStyle: {
          borderWidth: 2
        }
      }
    ]
  }
  
  trafficChart.setOption(option)
  
  // 响应窗口大小变化
  window.addEventListener('resize', () => {
    trafficChart && trafficChart.resize()
  })
  
  // 监听主题变化
  watch(isDark, (newValue) => {
    trafficChart.dispose()
    trafficChart = echarts.init(trafficChartRef.value, newValue ? 'dark' : undefined)
    trafficChart.setOption(option)
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

// 获取节点类型文本
const getNodeTypeText = (type) => {
  const types = {
    'public': '公网节点',
    'private': '内网节点',
    'client': '客户端'
  }
  return types[type] || '未知'
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

// 组件挂载时获取数据
onMounted(() => {
  fetchMappingInfo()
  fetchConnectionHistory()
  
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
.advanced-mapping-detail-container {
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
    
    .chain-status {
      .chain-visualization {
        display: flex;
        align-items: center;
        justify-content: space-between;
        flex-wrap: wrap;
        gap: 20px;
        margin-bottom: 20px;
        
        .chain-node {
          display: flex;
          align-items: center;
          gap: 10px;
          
          .node-box {
            padding: 15px;
            border: 1px solid #dcdfe6;
            border-radius: 4px;
            text-align: center;
            min-width: 150px;
            
            &.node-active {
              border-color: #67c23a;
              background-color: #f0f9eb;
            }
            
            .node-name {
              font-weight: bold;
              margin-bottom: 8px;
            }
            
            .node-type {
              color: #909399;
              margin-bottom: 8px;
            }
          }
          
          .chain-arrow {
            font-size: 24px;
            color: #909399;
          }
        }
      }
      
      .test-result {
        display: flex;
        align-items: center;
        gap: 8px;
        padding: 12px;
        border-radius: 4px;
        margin-top: 20px;
        
        &.success {
          background-color: #f0f9eb;
          color: #67c23a;
        }
        
        &.error {
          background-color: #fef0f0;
          color: #f56c6c;
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