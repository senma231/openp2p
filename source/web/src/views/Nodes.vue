<template>
  <div class="nodes-container">
    <div class="page-header">
      <h2>节点管理</h2>
      <el-button type="primary" @click="handleAddNode">
        <el-icon><Plus /></el-icon>添加节点
      </el-button>
    </div>

    <el-table :data="nodesStore.nodes" style="width: 100%" v-loading="nodesStore.loading">
      <el-table-column prop="name" label="节点名称" />
      <el-table-column prop="ip" label="IP地址" />
      <el-table-column prop="type" label="节点类型">
        <template #default="{ row }">
          <el-tag :type="getNodeTypeTag(row.type)">
            {{ getNodeTypeText(row.type) }}
          </el-tag>
        </template>
      </el-table-column>
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
      <el-table-column prop="bandwidth" label="共享带宽">
        <template #default="{ row }">
          {{ row.bandwidth }}Mbps
        </template>
      </el-table-column>
      <el-table-column label="操作" width="250">
        <template #default="{ row }">
          <el-button-group>
            <el-button size="small" @click="viewNodeDetail(row)">
              <el-icon><View /></el-icon>详情
            </el-button>
            <el-button size="small" @click="editNode(row)">
              <el-icon><Edit /></el-icon>编辑
            </el-button>
            <el-button size="small" type="danger" @click="deleteNode(row)">
              <el-icon><Delete /></el-icon>删除
            </el-button>
          </el-button-group>
        </template>
      </el-table-column>
    </el-table>

    <!-- 添加/编辑节点对话框 -->
    <el-dialog
      :title="editingNode ? '编辑节点' : '添加节点'"
      v-model="dialogVisible"
      @close="handleDialogClose"
      width="500px">
      <div class="node-type-info" v-if="!editingNode">
        <el-alert
          title="节点类型说明"
          type="info"
          :closable="false"
          description="客户端节点：需要在目标机器上安装客户端软件，连接后会自动上报IP地址。
公网节点：直接可访问的服务器节点。
内网节点：内网中的服务器节点。"
        />
      </div>
      <el-form :model="nodeForm" label-width="100px">
        <el-form-item label="节点名称" required>
          <el-input v-model="nodeForm.name" placeholder="请输入节点名称" />
        </el-form-item>
        <el-form-item 
          label="Token" 
          required>
          <el-input v-model="nodeForm.token" placeholder="请输入Token">
            <template #append>
              <el-button @click="generateToken">生成</el-button>
            </template>
          </el-input>
          <div class="form-tip">Token用于标识和验证节点，请妥善保存</div>
        </el-form-item>
        <el-form-item label="节点类型" required>
          <el-select v-model="nodeForm.type" placeholder="请选择节点类型">
            <el-option label="公网节点" value="public" />
            <el-option label="内网节点" value="private" />
            <el-option label="客户端" value="client" />
          </el-select>
        </el-form-item>
        
        <!-- 内网节点特有配置 -->
        <template v-if="nodeForm.type === 'private'">
          <el-form-item label="内网IP" required>
            <el-input v-model="nodeForm.privateIp" placeholder="请输入内网IP地址" />
            <div class="form-tip">目标机器的内网IP地址</div>
          </el-form-item>
          <el-form-item label="代理节点" required>
            <el-select v-model="nodeForm.proxyNodeId" placeholder="请选择代理节点">
              <el-option 
                v-for="node in clientNodes" 
                :key="node.id" 
                :label="node.name" 
                :value="node.id"
              />
            </el-select>
            <div class="form-tip">选择同一内网中已安装客户端的节点作为代理</div>
          </el-form-item>
        </template>

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
import { ref, onMounted, onUnmounted, computed } from 'vue'
import { useRouter } from 'vue-router'
import { Plus, Edit, Delete, View } from '@element-plus/icons-vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { useNodesStore } from '../stores/nodes'
import { storeToRefs } from 'pinia'

const router = useRouter()
const nodesStore = useNodesStore()

// 使用 storeToRefs 来保持响应性
const { nodes, loading } = storeToRefs(nodesStore)

const dialogVisible = ref(false)
const editingNode = ref(null)

// 获取客户端节点列表（用于选择代理节点）
const clientNodes = computed(() => {
  return nodes.value.filter(node => 
    node.type === 'client' && node.status === 'online'
  )
})

// 节点表单
const nodeForm = ref({
  name: '',
  token: '',
  type: 'client',
  bandwidth: 10,
  privateIp: '',  // 内网IP
  proxyNodeId: '' // 代理节点ID
})

// 处理添加节点
const handleAddNode = () => {
  editingNode.value = null
  nodeForm.value = {
    name: '',
    token: '',
    type: 'client',
    bandwidth: 10,
    privateIp: '',
    proxyNodeId: ''
  }
  dialogVisible.value = true
}

// 处理对话框关闭
const handleDialogClose = () => {
  editingNode.value = null
  nodeForm.value = {
    name: '',
    token: '',
    type: 'client',
    bandwidth: 10,
    privateIp: '',
    proxyNodeId: ''
  }
}

// 查看节点详情
const viewNodeDetail = (node) => {
  if (!node || !node.name) {
    ElMessage.warning('节点信息不完整，无法查看详情')
    return
  }
  router.push(`/nodes/${node.name}`)
}

// 编辑节点
const editNode = (node) => {
  if (!node) {
    ElMessage.warning('节点信息不完整，无法编辑')
    return
  }
  
  editingNode.value = node
  // 确保表单数据正确
  nodeForm.value = {
    name: node.name || '',
    token: node.token || '',
    type: node.type || 'client',
    bandwidth: node.bandwidth || 0,
    privateIp: node.privateIp || '',
    proxyNodeId: node.proxyNodeId || ''
  }
  
  dialogVisible.value = true
}

// 删除节点
const deleteNode = (node) => {
  if (!node || !node.name) {
    ElMessage.warning('节点信息不完整，无法删除')
    return
  }
  
  ElMessageBox.confirm(
    `确定要删除节点 ${node.name} 吗？`,
    '警告',
    {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning',
    }
  ).then(async () => {
    try {
      await nodesStore.removeNode(node.name)
      ElMessage.success('删除成功')
    } catch (error) {
      ElMessage.error('删除失败：' + (error.message || '未知错误'))
    }
  }).catch(() => {})
}

// 保存节点
const saveNode = async () => {
  try {
    if (editingNode.value) {
      await nodesStore.updateNodeData(editingNode.value.name, nodeForm.value)
      ElMessage.success('更新成功')
    } else {
      await nodesStore.createNode(nodeForm.value)
      ElMessage.success('添加成功')
    }
    dialogVisible.value = false
    handleDialogClose()
  } catch (error) {
    ElMessage.error('保存失败：' + error.message)
  }
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

// 获取节点类型标签样式
const getNodeTypeTag = (type) => {
  const tags = {
    'public': 'success',
    'private': 'warning',
    'client': 'info'
  }
  return tags[type] || ''
}

// 生成随机Token
const generateToken = () => {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
  let token = ''
  for (let i = 0; i < 32; i++) {
    token += chars.charAt(Math.floor(Math.random() * chars.length))
  }
  nodeForm.value.token = token
}

// 组件挂载时获取节点列表
onMounted(() => {
  nodesStore.fetchNodes()
})

// 定时刷新节点列表
const refreshInterval = ref(null)
onMounted(() => {
  nodesStore.fetchNodes()
  // 每30秒刷新一次节点列表
  refreshInterval.value = setInterval(() => {
    nodesStore.fetchNodes()
  }, 30000)
})

// 组件卸载时清除定时器
onUnmounted(() => {
  if (refreshInterval.value) {
    clearInterval(refreshInterval.value)
  }
})
</script>

<style lang="scss" scoped>
.nodes-container {
  .page-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 20px;
  }

  .unit {
    margin-left: 8px;
    color: #909399;
  }
}

.node-type-info {
  margin-bottom: 20px;
}

.form-tip {
  font-size: 12px;
  color: #909399;
  margin-top: 4px;
}
</style>