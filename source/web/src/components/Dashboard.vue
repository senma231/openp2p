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
              <el-tag type="info" size="small">实时</el-tag>
            </div>
          </template>
          <div class="card-value">
            <span class="number">{{ stats.avgLatency }}</span>
            <span class="unit">ms</span>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <el-row :gutter="20" class="mt-4">
      <el-col :span="12">
        <el-card class="box-card">
          <template #header>
            <div class="card-header">
              <span>节点状态</span>
            </div>
          </template>
          <el-table :data="nodes" style="width: 100%">
            <el-table-column prop="name" label="节点名称" />
            <el-table-column prop="status" label="状态">
              <template #default="{ row }">
                <el-tag :type="row.status === 'online' ? 'success' : 'danger'">
                  {{ row.status === 'online' ? '在线' : '离线' }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="latency" label="延迟">
              <template #default="{ row }">
                {{ row.latency }}ms
              </template>
            </el-table-column>
          </el-table>
        </el-card>
      </el-col>

      <el-col :span="12">
        <LogViewer />
      </el-col>
    </el-row>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import { getStats, getNodes } from '../api'
import LogViewer from './LogViewer.vue'

const stats = ref({
  onlineNodes: 0,
  activeConnections: 0,
  totalTraffic: 0,
  avgLatency: 0
})

const nodes = ref([])

// 格式化流量数据
const formatTraffic = (bytes) => {
  if (bytes === 0) return '0 B'
  const k = 1024
  const sizes = ['B', 'KB', 'MB', 'GB', 'TB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
}

// 获取统计数据
const fetchStats = async () => {
  try {
    const data = await getStats()
    stats.value = data
  } catch (error) {
    console.error('获取统计数据失败:', error)
  }
}

// 获取节点数据
const fetchNodes = async () => {
  try {
    const data = await getNodes()
    nodes.value = data
  } catch (error) {
    console.error('获取节点数据失败:', error)
  }
}

// 定时刷新数据
let refreshInterval

onMounted(() => {
  fetchStats()
  fetchNodes()
  refreshInterval = setInterval(() => {
    fetchStats()
    fetchNodes()
  }, 5000) // 每5秒刷新一次
})

onUnmounted(() => {
  if (refreshInterval) {
    clearInterval(refreshInterval)
  }
})
</script>

<style scoped>
.dashboard-container {
  padding: 20px;
}

.mt-4 {
  margin-top: 20px;
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
  color: #409EFF;
}

.card-value .unit {
  margin-left: 5px;
  font-size: 14px;
  color: #909399;
}
</style>