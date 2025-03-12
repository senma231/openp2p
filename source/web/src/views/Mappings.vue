<template>
  <div class="mappings-container">
    <div class="page-header">
      <h2>端口映射</h2>
      <el-button type="primary" @click="dialogVisible = true">
        <el-icon><Plus /></el-icon>添加映射
      </el-button>
    </div>

    <el-table :data="mappings" style="width: 100%" v-loading="loading">
      <el-table-column prop="name" label="应用名称" />
      <el-table-column prop="protocol" label="协议">
        <template #default="{ row }">
          <el-tag>{{ row.protocol.toUpperCase() }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="srcPort" label="本地端口" />
      <el-table-column prop="peerNode" label="目标节点" />
      <el-table-column prop="dstPort" label="目标端口" />
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
            <el-button size="small" @click="viewMappingDetail(row)">
              <el-icon><View /></el-icon>详情
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

    <!-- 添加/编辑映射对话框 -->
    <el-dialog
      :title="editingMapping ? '编辑映射' : '添加映射'"
      v-model="dialogVisible"
      width="500px">
      <el-form :model="mappingForm" label-width="100px">
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
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { Plus, Edit, Delete, View } from '@element-plus/icons-vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { useMappingsStore } from '../stores/mappings'
import { useNodesStore } from '../stores/nodes'

const router = useRouter()
const mappingsStore = useMappingsStore()
const nodesStore = useNodesStore()

const { mappings, loading } = mappingsStore
const { nodes } = nodesStore

const dialogVisible = ref(false)
const editingMapping = ref(null)

// 映射表单
const mappingForm = ref({
  name: '',
  protocol: 'tcp',
  srcPort: 0,
  peerNode: '',
  dstPort: 0
})

// 查看映射详情
const viewMappingDetail = (mapping) => {
  router.push(`/mappings/${mapping.name}`)
}

// 编辑映射
const editMapping = (mapping) => {
  editingMapping.value = mapping
  mappingForm.value = { ...mapping }
  dialogVisible.value = true
}

// 删除映射
const deleteMapping = (mapping) => {
  ElMessageBox.confirm(
    `确定要删除映射 ${mapping.name} 吗？`,
    '警告',
    {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning',
    }
  ).then(async () => {
    try {
      await mappingsStore.removeMapping(mapping.name)
      ElMessage.success('删除成功')
    } catch (error) {
      ElMessage.error('删除失败：' + error.message)
    }
  })
}

// 保存映射
const saveMapping = async () => {
  try {
    if (editingMapping.value) {
      await mappingsStore.updateMappingData(editingMapping.value.name, mappingForm.value)
      ElMessage.success('更新成功')
    } else {
      await mappingsStore.createMapping(mappingForm.value)
      ElMessage.success('添加成功')
    }
    dialogVisible.value = false
    editingMapping.value = null
  } catch (error) {
    ElMessage.error('保存失败：' + error.message)
  }
}

// 初始化加载
onMounted(() => {
  mappingsStore.fetchMappings()
  nodesStore.fetchNodes()
})
</script>

<style lang="scss" scoped>
.mappings-container {
  .page-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 20px;
  }
}
</style>