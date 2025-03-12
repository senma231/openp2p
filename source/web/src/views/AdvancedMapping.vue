<template>
  <div class="advanced-mapping-container">
    <div class="page-header">
      <h2>高级映射配置</h2>
      <el-button type="primary" @click="handleAddMapping">
        <el-icon><Plus /></el-icon>添加级联映射
      </el-button>
    </div>

    <el-alert
      title="级联映射说明"
      type="info"
      description="级联映射允许您创建多级内网穿透链路，实现复杂网络环境下的连接。例如：客户端 -> 内网节点A -> 内网节点B -> 目标服务器"
      show-icon
      :closable="false"
      style="margin-bottom: 20px"
    />

    <el-table :data="advancedMappingsStore.advancedMappings" style="width: 100%" v-loading="advancedMappingsStore.loading">
      <el-table-column prop="name" label="映射名称" />
      <el-table-column prop="protocol" label="协议">
        <template #default="{ row }">
          <el-tag>{{ row.protocol.toUpperCase() }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="entryPort" label="入口端口" />
      <el-table-column label="映射链路">
        <template #default="{ row }">
          <div class="mapping-chain">
            <template v-for="(node, index) in row.nodes" :key="index">
              <span class="node-name">{{ node.name }}</span>
              <el-icon v-if="index < row.nodes.length - 1"><ArrowRight /></el-icon>
            </template>
          </div>
        </template>
      </el-table-column>
      <el-table-column prop="targetPort" label="目标端口" />
      <el-table-column prop="status" label="状态">
        <template #default="{ row }">
          <el-tag :type="row.status === 'connected' ? 'success' : 'danger'">
            {{ row.status === 'connected' ? '已连接' : '未连接' }}
          </el-tag>
        </template>
      </el-table-column>
      <el-table-column label="操作" width="250">
        <template #default="{ row }">
          <el-button-group>
            <el-button 
              size="small" 
              :type="row.status === 'connected' ? 'danger' : 'success'"
              @click="toggleMappingStatus(row)"
            >
              {{ row.status === 'connected' ? '停止' : '启动' }}
            </el-button>
            <el-button size="small" @click="editMapping(row)">
              <el-icon><Edit /></el-icon>编辑
            </el-button>
            <el-button size="small" type="danger" @click="deleteMapping(row)">
              <el-icon><Delete /></el-icon>删除
            </el-button>
          </el-button-group>
        </template>
      </el-table-column>
    </el-table>

    <!-- 添加/编辑级联映射对话框 -->
    <el-dialog
      :title="editingMapping ? '编辑级联映射' : '添加级联映射'"
      v-model="dialogVisible"
      @close="handleDialogClose"
      width="650px">
      <el-form :model="mappingForm" label-width="100px">
        <el-form-item label="映射名称" required>
          <el-input v-model="mappingForm.name" placeholder="请输入映射名称" />
        </el-form-item>
        <el-form-item label="协议" required>
          <el-select v-model="mappingForm.protocol" placeholder="请选择协议">
            <el-option label="TCP" value="tcp" />
            <el-option label="UDP" value="udp" />
          </el-select>
        </el-form-item>
        <el-form-item label="入口端口" required>
          <el-input-number
            v-model="mappingForm.entryPort"
            :min="1"
            :max="65535"
            placeholder="请输入入口端口"
          />
        </el-form-item>

        <div class="mapping-chain-config">
          <div class="chain-header">
            <span>映射链路配置</span>
            <el-button type="primary" size="small" @click="addNodeToChain" :disabled="mappingForm.nodes.length >= 5">
              添加节点
            </el-button>
          </div>
          
          <el-empty v-if="mappingForm.nodes.length === 0" description="请添加节点到映射链路"></el-empty>
          
          <div v-else class="chain-nodes">
            <div v-for="(node, index) in mappingForm.nodes" :key="index" class="chain-node-item">
              <div class="node-index">{{ index + 1 }}</div>
              <div class="node-config">
                <el-form-item :label="index === 0 ? '起始节点' : (index === mappingForm.nodes.length - 1 ? '目标节点' : '中继节点')" required>
                  <el-select v-model="node.nodeId" placeholder="请选择节点">
                    <el-option
                      v-for="availableNode in availableNodes"
                      :key="availableNode.name"
                      :label="availableNode.name"
                      :value="availableNode.name"
                    />
                  </el-select>
                </el-form-item>
                <el-form-item v-if="index === mappingForm.nodes.length - 1" label="目标端口" required>
                  <el-input-number
                    v-model="mappingForm.targetPort"
                    :min="1"
                    :max="65535"
                    placeholder="请输入目标端口"
                  />
                </el-form-item>
              </div>
              <el-button 
                v-if="mappingForm.nodes.length > 2" 
                type="danger" 
                circle 
                size="small" 
                @click="removeNodeFromChain(index)"
                :disabled="index === 0 || index === mappingForm.nodes.length - 1"
              >
                <el-icon><Delete /></el-icon>
              </el-button>
            </div>
          </div>
        </div>

        <el-form-item label="备注">
          <el-input v-model="mappingForm.description" type="textarea" placeholder="请输入备注信息" />
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
import { ref, onMounted } from 'vue'
import { Plus, Edit, Delete, ArrowRight } from '@element-plus/icons-vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { useAdvancedMappingsStore } from '../stores/advancedMappings'
import { useNodesStore } from '../stores/nodes'

const advancedMappingsStore = useAdvancedMappingsStore()
const nodesStore = useNodesStore()

const availableNodes = ref([])
const dialogVisible = ref(false)
const editingMapping = ref(null)

// 映射表单
const mappingForm = ref({
  name: '',
  protocol: 'tcp',
  entryPort: 0,
  nodes: [],
  targetPort: 0,
  description: ''
})

// 获取节点列表
const fetchNodes = async () => {
  try {
    const nodes = await nodesStore.fetchNodes()
    availableNodes.value = nodes || []
  } catch (error) {
    console.error('获取节点列表失败:', error)
    ElMessage.error('获取节点列表失败')
  }
}

// 处理添加映射
const handleAddMapping = () => {
  editingMapping.value = null
  resetForm()
  dialogVisible.value = true
}

// 添加节点到链路
const addNodeToChain = () => {
  if (mappingForm.value.nodes.length === 0) {
    // 添加起始节点和目标节点
    mappingForm.value.nodes.push({ nodeId: '' })
    mappingForm.value.nodes.push({ nodeId: '' })
  } else {
    // 在倒数第二个位置添加中继节点
    mappingForm.value.nodes.splice(mappingForm.value.nodes.length - 1, 0, { nodeId: '' })
  }
}

// 从链路中移除节点
const removeNodeFromChain = (index) => {
  // 不允许移除起始节点和目标节点
  if (index > 0 && index < mappingForm.value.nodes.length - 1) {
    mappingForm.value.nodes.splice(index, 1)
  }
}

// 编辑映射
const editMapping = (mapping) => {
  editingMapping.value = mapping
  mappingForm.value = {
    name: mapping.name,
    protocol: mapping.protocol,
    entryPort: mapping.entryPort,
    nodes: mapping.nodes.map(node => ({ nodeId: node.name })),
    targetPort: mapping.targetPort,
    description: mapping.description || ''
  }
  dialogVisible.value = true
}

// 删除映射
const deleteMapping = (mapping) => {
  ElMessageBox.confirm(
    `确定要删除级联映射 ${mapping.name} 吗？`,
    '警告',
    {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning',
    }
  ).then(async () => {
    try {
      await advancedMappingsStore.removeAdvancedMapping(mapping.name)
      ElMessage.success('删除成功')
    } catch (error) {
      ElMessage.error('删除失败：' + error.message)
    }
  })
}

// 保存映射
const saveMapping = async () => {
  // 验证表单
  if (!mappingForm.value.name) {
    return ElMessage.warning('请输入映射名称')
  }
  if (!mappingForm.value.entryPort) {
    return ElMessage.warning('请输入入口端口')
  }
  if (mappingForm.value.nodes.length < 2) {
    return ElMessage.warning('请至少配置起始节点和目标节点')
  }
  if (!mappingForm.value.targetPort) {
    return ElMessage.warning('请输入目标端口')
  }

  // 验证所有节点都已选择
  if (mappingForm.value.nodes.some(node => !node.nodeId)) {
    return ElMessage.warning('请选择所有节点')
  }

  try {
    const mappingData = {
      name: mappingForm.value.name,
      protocol: mappingForm.value.protocol,
      entryPort: mappingForm.value.entryPort,
      nodes: mappingForm.value.nodes,
      targetPort: mappingForm.value.targetPort,
      description: mappingForm.value.description
    }

    if (editingMapping.value) {
      await advancedMappingsStore.updateMapping(editingMapping.value.name, mappingData)
      ElMessage.success('更新成功')
    } else {
      await advancedMappingsStore.addMapping(mappingData)
      ElMessage.success('添加成功')
    }

    dialogVisible.value = false
    resetForm()
  } catch (error) {
    ElMessage.error(error.message || '保存失败')
  }
}

// 重置表单
const resetForm = () => {
  editingMapping.value = null
  mappingForm.value = {
    name: '',
    protocol: 'tcp',
    entryPort: 0,
    nodes: [],
    targetPort: 0,
    description: ''
  }
}

// 切换映射状态
const toggleMappingStatus = async (mapping) => {
  try {
    if (mapping.status === 'connected') {
      await advancedMappingsStore.stopMapping(mapping.name)
      ElMessage.success('停止成功')
    } else {
      await advancedMappingsStore.startMapping(mapping.name)
      ElMessage.success('启动成功')
    }
    await advancedMappingsStore.fetchAdvancedMappings()
  } catch (error) {
    ElMessage.error(error.message || '操作失败')
  }
}

// 关闭对话框时重置表单
const handleDialogClose = () => {
  resetForm()
}

// 初始化
onMounted(async () => {
  try {
    await fetchNodes()
    await advancedMappingsStore.fetchAdvancedMappings()
  } catch (error) {
    console.error('初始化失败:', error)
    ElMessage.error('加载数据失败')
  }
})

defineExpose({
  fetchAdvancedMappings: advancedMappingsStore.fetchAdvancedMappings
})
</script>

<style lang="scss" scoped>
.advanced-mapping-container {
  .page-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 20px;
  }

  .mapping-chain {
    display: flex;
    align-items: center;
    flex-wrap: wrap;
    gap: 5px;

    .node-name {
      font-weight: 500;
    }
  }

  .mapping-chain-config {
    border: 1px solid #e4e7ed;
    border-radius: 4px;
    padding: 15px;
    margin-bottom: 20px;

    .chain-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 15px;
      font-weight: bold;
    }

    .chain-nodes {
      .chain-node-item {
        display: flex;
        align-items: flex-start;
        margin-bottom: 15px;
        position: relative;

        .node-index {
          width: 24px;
          height: 24px;
          background-color: #409eff;
          color: white;
          border-radius: 50%;
          display: flex;
          justify-content: center;
          align-items: center;
          margin-right: 10px;
          margin-top: 10px;
        }

        .node-config {
          flex: 1;
        }
      }
    }
  }
}
</style> 