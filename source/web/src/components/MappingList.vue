<template>
  <div class="mapping-list">
    <el-card class="box-card">
      <template #header>
        <div class="card-header">
          <span>端口映射</span>
          <el-button type="primary" @click="showAddDialog">添加映射</el-button>
        </div>
      </template>

      <el-table :data="mappings" v-loading="loading" style="width: 100%">
        <el-table-column prop="AppName" label="应用名称" />
        <el-table-column prop="Protocol" label="协议" />
        <el-table-column prop="SrcPort" label="源端口" />
        <el-table-column prop="PeerNode" label="目标节点" />
        <el-table-column prop="DstPort" label="目标端口" />
        <el-table-column prop="DstHost" label="目标主机" />
        <el-table-column label="操作" width="200">
          <template #default="{ row }">
            <el-button size="small" @click="showEditDialog(row)">编辑</el-button>
            <el-button size="small" type="danger" @click="handleDelete(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <!-- 添加/编辑映射对话框 -->
    <el-dialog
      :title="dialogType === 'add' ? '添加映射' : '编辑映射'"
      v-model="dialogVisible"
      width="500px"
    >
      <el-form :model="mappingForm" :rules="rules" ref="mappingFormRef" label-width="100px">
        <el-form-item label="应用名称" prop="AppName">
          <el-input v-model="mappingForm.AppName" placeholder="请输入应用名称" />
        </el-form-item>
        <el-form-item label="协议" prop="Protocol">
          <el-select v-model="mappingForm.Protocol" placeholder="请选择协议">
            <el-option label="TCP" value="tcp" />
            <el-option label="UDP" value="udp" />
          </el-select>
        </el-form-item>
        <el-form-item label="源端口" prop="SrcPort">
          <el-input-number v-model="mappingForm.SrcPort" :min="1" :max="65535" placeholder="请输入源端口" />
        </el-form-item>
        <el-form-item label="目标节点" prop="PeerNode">
          <el-input v-model="mappingForm.PeerNode" placeholder="请输入目标节点名称" />
        </el-form-item>
        <el-form-item label="目标端口" prop="DstPort">
          <el-input-number v-model="mappingForm.DstPort" :min="1" :max="65535" placeholder="请输入目标端口" />
        </el-form-item>
        <el-form-item label="目标主机" prop="DstHost">
          <el-input v-model="mappingForm.DstHost" placeholder="请输入目标主机地址" />
        </el-form-item>
      </el-form>
      <template #footer>
        <span class="dialog-footer">
          <el-button @click="dialogVisible = false">取消</el-button>
          <el-button type="primary" @click="handleSubmit">确定</el-button>
        </span>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { useMappingsStore } from '../stores/mappings'

const mappingsStore = useMappingsStore()
const loading = ref(false)
const dialogVisible = ref(false)
const dialogType = ref('add')
const mappingFormRef = ref(null)

const mappingForm = ref({
  AppName: '',
  Protocol: 'tcp',
  SrcPort: null,
  PeerNode: '',
  DstPort: null,
  DstHost: 'localhost'
})

const rules = {
  AppName: [{ required: true, message: '请输入应用名称', trigger: 'blur' }],
  Protocol: [{ required: true, message: '请选择协议', trigger: 'change' }],
  SrcPort: [{ required: true, message: '请输入源端口', trigger: 'blur' }],
  PeerNode: [{ required: true, message: '请输入目标节点名称', trigger: 'blur' }],
  DstPort: [{ required: true, message: '请输入目标端口', trigger: 'blur' }],
  DstHost: [{ required: true, message: '请输入目标主机地址', trigger: 'blur' }]
}

const showAddDialog = () => {
  dialogType.value = 'add'
  mappingForm.value = {
    AppName: '',
    Protocol: 'tcp',
    SrcPort: null,
    PeerNode: '',
    DstPort: null,
    DstHost: 'localhost'
  }
  dialogVisible.value = true
}

const showEditDialog = (mapping) => {
  dialogType.value = 'edit'
  mappingForm.value = { ...mapping }
  dialogVisible.value = true
}

const handleSubmit = async () => {
  if (!mappingFormRef.value) return

  await mappingFormRef.value.validate(async (valid) => {
    if (valid) {
      try {
        if (dialogType.value === 'add') {
          await mappingsStore.createMapping(mappingForm.value)
          ElMessage.success('添加映射成功')
        } else {
          await mappingsStore.updateMappingData(mappingForm.value.id, mappingForm.value)
          ElMessage.success('更新映射成功')
        }
        dialogVisible.value = false
        await fetchMappings()
      } catch (error) {
        ElMessage.error(error.message || '操作失败')
      }
    }
  })
}

const handleDelete = (mapping) => {
  ElMessageBox.confirm('确认删除该映射吗？', '提示', {
    confirmButtonText: '确定',
    cancelButtonText: '取消',
    type: 'warning'
  }).then(async () => {
    try {
      await mappingsStore.removeMapping(mapping.id)
      ElMessage.success('删除成功')
      await fetchMappings()
    } catch (error) {
      ElMessage.error(error.message || '删除失败')
    }
  })
}

const fetchMappings = async () => {
  loading.value = true
  try {
    await mappingsStore.fetchMappings()
  } catch (error) {
    ElMessage.error(error.message || '获取映射列表失败')
  } finally {
    loading.value = false
  }
}

const mappings = computed(() => mappingsStore.mappings)

onMounted(() => {
  fetchMappings()
})
</script>

<style scoped>
.mapping-list {
  padding: 20px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.dialog-footer {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
}
</style>