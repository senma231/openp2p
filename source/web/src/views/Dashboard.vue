<template>
  <div class="dashboard-container">
    <el-row :gutter="20">
      <el-col :span="6">
        <el-card class="stat-card">
          <template #header>
            <div class="card-header">
              <span>在线节点数</span>
              <el-tag type="success" size="small">实时</el-tag>
            </div>
          </template>
          <div class="card-value">
            <span class="number">{{ stats.onlineNodes }}</span>
            <span class="unit">个</span>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card class="stat-card">
          <template #header>
            <div class="card-header">
              <span>活跃连接数</span>
              <el-tag type="warning" size="small">实时</el-tag>
            </div>
          </template>
          <div class="card-value">
            <span class="number">{{ stats.activeConnections }}</span>
            <span class="unit">个</span>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card class="stat-card">
          <template #header>
            <div class="card-header">
              <span>总流量</span>
              <el-tag type="info" size="small">今日</el-tag>
            </div>
          </template>
          <div class="card-value">
            <span class="number">{{ formatTraffic(stats.totalTraffic) }}</span>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card class="stat-card">
          <template #header>
            <div class="card-header">
              <span>平均延迟</span>
              <el-tag type="primary" size="small">实时</el-tag>
            </div>
          </template>
          <div class="card-value">
            <span class="number">{{ stats.avgLatency }}</span>
            <span class="unit">ms</span>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <el-row :gutter="20" class="chart-row">
      <el-col :span="12">
        <el-card class="chart-card">
          <template #header>
            <div class="card-header">
              <span>流量趋势</span>
              <el-radio-group v-model="trafficTimeRange" size="small" @change="updateTrafficChart">
                <el-radio-button label="hour">1小时</el-radio-button>
                <el-radio-button label="day">24小时</el-radio-button>
                <el-radio-button label="week">7天</el-radio-button>
              </el-radio-group>
            </div>
          </template>
          <div ref="trafficChartRef" class="chart-container"></div>
        </el-card>
      </el-col>
      <el-col :span="12">
        <el-card class="chart-card">
          <template #header>
            <div class="card-header">
              <span>节点状态分布</span>
            </div>
          </template>
          <div ref="nodeStatusChartRef" class="chart-container"></div>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import { getStats, getNodes } from '../api'
import * as echarts from 'echarts'

const stats = ref({
  onlineNodes: 0,
  activeConnections: 0,
  totalTraffic: 0,
  avgLatency: 0
})

const trafficTimeRange = ref('hour')
const trafficChartRef = ref(null)
const nodeStatusChartRef = ref(null)
let trafficChart = null
let nodeStatusChart = null

// 格式化流量数据
const formatTraffic = (bytes) => {
  if (bytes === 0) return '0 B'
  const k = 1024
  const sizes = ['B', 'KB', 'MB', 'GB', 'TB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
}

// 初始化流量趋势图表
const initTrafficChart = () => {
  trafficChart = echarts.init(trafficChartRef.value)
  const option = {
    tooltip: {
      trigger: 'axis'
    },
    xAxis: {
      type: 'category',
      data: []
    },
    yAxis: {
      type: 'value',
      name: '流量',
      axisLabel: {
        formatter: (value) => formatTraffic(value)
      }
    },
    series: [
      {
        name: '上行流量',
        type: 'line',
        data: [],
        areaStyle: {}
      },
      {
        name: '下行流量',
        type: 'line',
        data: [],
        areaStyle: {}
      }
    ]
  }
  trafficChart.setOption(option)
}

// 初始化节点状态分布图表
const initNodeStatusChart = () => {
  nodeStatusChart = echarts.init(nodeStatusChartRef.value)
  const option = {
    tooltip: {
      trigger: 'item'
    },
    legend: {
      orient: 'vertical',
      left: 'left'
    },
    series: [
      {
        name: '节点状态',
        type: 'pie',
        radius: ['40%', '70%'],
        avoidLabelOverlap: false,
        itemStyle: {
          borderRadius: 10,
          borderColor: '#fff',
          borderWidth: 2
        },
        label: {
          show: false,
          position: 'center'
        },
        emphasis: {
          label: {
            show: true,
            fontSize: '20',
            fontWeight: 'bold'
          }
        },
        labelLine: {
          show: false
        },
        data: []
      }
    ]
  }
  nodeStatusChart.setOption(option)
}

// 更新流量趋势图表
const updateTrafficChart = async () => {
  // TODO: 根据 trafficTimeRange 获取不同时间范围的流量数据
  const mockData = {
    timestamps: ['12:00', '13:00', '14:00', '15:00'],
    upload: [100, 200, 150, 300],
    download: [200, 300, 250, 400]
  }

  trafficChart.setOption({
    xAxis: {
      data: mockData.timestamps
    },
    series: [
      {
        name: '上行流量',
        data: mockData.upload
      },
      {
        name: '下行流量',
        data: mockData.download
      }
    ]
  })
}

// 更新节点状态分布图表
const updateNodeStatusChart = (nodes) => {
  if (!nodes || !Array.isArray(nodes)) {
    nodes = []
  }
  
  const statusCount = {
    online: nodes.filter(node => node.status === 'online').length || 0,
    offline: nodes.filter(node => node.status === 'offline').length || 0
  }

  if (nodeStatusChart) {
    nodeStatusChart.setOption({
      series: [{
        data: [
          { value: statusCount.online, name: '在线' },
          { value: statusCount.offline, name: '离线' }
        ]
      }]
    })
  }
}

// 获取统计数据
const fetchStats = async () => {
  try {
    const response = await getStats()
    if (response && response.data) {
      stats.value = {
        onlineNodes: response.data.online_nodes || 0,
        activeConnections: response.data.active_connections || 0,
        totalTraffic: response.data.total_traffic || 0,
        avgLatency: response.data.avg_latency || 0
      }
    }
  } catch (error) {
    console.error('获取统计数据失败:', error)
  }
}

// 获取节点数据并更新图表
const fetchNodes = async () => {
  try {
    const response = await getNodes()
    if (response && response.data) {
      updateNodeStatusChart(response.data)
    }
  } catch (error) {
    console.error('获取节点数据失败:', error)
  }
}

// 初始化
onMounted(async () => {
  // 初始化图表
  initTrafficChart()
  initNodeStatusChart()

  // 获取数据
  await fetchStats()
  await fetchNodes()
  await updateTrafficChart()

  // 添加窗口大小变化监听
  window.addEventListener('resize', handleResize)
})

// 处理窗口大小变化
const handleResize = () => {
  if (trafficChart) {
    trafficChart.resize()
  }
  if (nodeStatusChart) {
    nodeStatusChart.resize()
  }
}

// 组件卸载时清理
onUnmounted(() => {
  window.removeEventListener('resize', handleResize)
  if (trafficChart) {
    trafficChart.dispose()
  }
  if (nodeStatusChart) {
    nodeStatusChart.dispose()
  }
})
</script>

<style scoped>
.dashboard-container {
  padding: 20px;
}

.chart-row {
  margin-top: 20px;
}

.chart-container {
  height: 400px;
  width: 100%;
}

.chart-card {
  height: 100%;
}

.stat-card {
  height: 100%;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.card-value {
  text-align: center;
  padding: 20px 0;
}

.card-value .number {
  font-size: 24px;
  font-weight: bold;
  margin-right: 5px;
}

.chart-card {
  margin-bottom: 20px;
}
</style>