<template>
  <div class="node-list">
    <el-card class="box-card">
      <template #header>
        <div class="card-header">
          <span>节点管理</span>
          <el-button type="primary" @click="showAddDialog">添加节点</el-button>
        </div>
      </template>

      <el-table :data="nodes" v-loading="loading" style="width: 100%">
        <el-table-column prop="name" label="节点名称" />
        <el-table-column prop="ip" label="IP地址" />
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
        <el-table-column prop="bandwidth" label="带宽">
          <template #default="{ row }">
            {{ row.bandwidth }}Mbps
          </template>
        </el-table-column>
        <el-table-column prop="lastSeen" label="最后在线时间">
          <template #default="{ row }">
            {{ formatDate(row.lastSeen) }}
          </template>
        </el-table-column>
        <el-table-column label="操作" width="200">
          <template #default="{ row }">
            <el-button size="small" @click="showEditDialog(row)">编辑</el-button>
            <el-button size="small" type="danger" @click="handleDelete(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <!-- 添加/编辑节点对话框 -->
    <el-dialog
      :title="dialogType === 'add' ? '添加节点' : '编辑节点'"
      v-model="dialogVisible"
      width="500px"
    >
      <el-form
        ref="formRef"
        :model="form"
        :rules="rules"
        label-width="100px"
      >
        <el-form-item label="节点名称" prop="name">
          <el-input v-model="form.name" placeholder="请输入节点名称" />
        </el-form-item>
        <el-form-item label="IP地址" prop="ip">
          <el-input v-model="form.ip" placeholder="请输入IP地址" />
        </el-form-item>
        <el-form-item label="共享带宽" prop="bandwidth">
          <el-input-number
            v-model="form.bandwidth"
            :min="1"
            :max="1000"
            placeholder="请输入共享带宽"
          />
          <span class="unit">Mbps</span>
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
import { ref, computed } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { useNodesStore } from '../stores/nodes'
import { formatDate } from '../utils/date'

const nodesStore = useNodesStore()
const { nodes, loading } = storeToRefs(nodesStore)

// 表单相关
const formRef = ref(null)
const dialogVisible = ref(false)
const dialogType = ref('add')
const form = ref({
  name: '',
  ip: '',
  bandwidth: 100
})

// 表单验证规则
const rules = {
  name: [
    { required: true, message: '请输入节点名称', trigger: 'blur' },
    { min: 2, max: 20, message: '长度在 2 到 20 个字符', trigger: 'blur' }
  ],
  ip: [
    { required: true, message: '请输入IP地址', trigger: 'blur' },
    { pattern: /^(?:\d{1,3}\.){3}\d{1,3}$/, message: '请输入正确的IP地址格式', trigger: 'blur' }
  ],
  bandwidth: [
    { required: true, message: '请输入共享带宽', trigger: 'blur' },
    { type: 'number', min: 1, max: 1000, message: '带宽范围在 1 到 1000 之间', trigger: 'blur' }
  ]
}

// 显示添加对话框
const showAddDialog = () => {
  dialogType.value = 'add'
  form.value = {
    name: '',
    ip: '',
    bandwidth: 100
  }
  dialogVisible.value = true
}

// 显示编辑对话框
const showEditDialog = (node) => {
  dialogType.value = 'edit'
  form.value = { ...node }
  dialogVisible.value = true
}

// 提交表单
const handleSubmit = async () => {
  if (!formRef.value) return
  
  await formRef.value.validate(async (valid) => {
    if (valid) {
      try {
        if (dialogType.value === 'add') {
          await nodesStore.createNode(form.value)
          ElMessage.success('添加成功')
        } else {
          await nodesStore.updateNodeData(form.value.id, form.value)
          ElMessage.success('更新成功')
        }
        dialogVisible.value = false
      } catch (error) {
        ElMessage.error(error.message || '操作失败')
      }
    }
  })
}

// 删除节点
const handleDelete = (node) => {
  ElMessageBox.confirm('确认删除该节点吗？', '提示', {
    confirmButtonText: '确定',
    cancelButtonText: '取消',
    type: 'warning'
  }).then(async () => {
    try {
      await nodesStore.removeNode(node.id)
      ElMessage.success('删除成功')
    } catch (error) {
      ElMessage.error(error.message || '删除失败')
    }
  })
}
</script>

<style scoped>
.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.unit {
  margin-left: 8px;
  color: #909399;
}

.dialog-footer {
  display: flex;
  justify-content: flex-end;
  gap: 12px;
}
</style>