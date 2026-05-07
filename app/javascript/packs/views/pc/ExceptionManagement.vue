<template>
  <div class="exception-management">
    <el-card class="mb-4">
      <template #header>
        <div class="card-header">
          <h2>异常管理</h2>
          <el-button type="primary" @click="showCreateDialog">
            <el-icon><Plus /></el-icon>
            新增异常
          </el-button>
        </div>
      </template>
      
      <!-- 搜索和过滤 -->
      <div class="search-bar">
        <el-input
          v-model="searchKeyword"
          placeholder="搜索运单号/手机号/收件人"
          style="width: 300px; margin-right: 10px;"
          clearable
          @clear="handleSearch"
          @keyup.enter="handleSearch"
        >
          <template #append>
            <el-button @click="handleSearch">
              <el-icon><Search /></el-icon>
            </el-button>
          </template>
        </el-input>
        
        <el-select v-model="exceptionType" placeholder="异常类型" style="width: 150px; margin-right: 10px;" @change="handleSearch">
          <el-option label="全部" value="" />
          <el-option label="滞留" value="overdue" />
          <el-option label="破损" value="damaged" />
          <el-option label="错发" value="wrong_delivery" />
          <el-option label="丢失" value="lost" />
          <el-option label="其他" value="other" />
        </el-select>
        
        <el-select v-model="statusFilter" placeholder="处理状态" style="width: 150px;" @change="handleSearch">
          <el-option label="全部" value="" />
          <el-option label="待处理" value="pending" />
          <el-option label="处理中" value="processing" />
          <el-option label="已解决" value="resolved" />
        </el-select>
      </div>
      
      <!-- 异常列表 -->
      <el-table :data="exceptions" style="width: 100%" v-loading="loading" empty-text="暂无异常记录">
        <el-table-column prop="package.tracking_number" label="运单号" width="180" />
        <el-table-column prop="package.recipient_name" label="收件人" width="120" />
        <el-table-column prop="package.recipient_phone" label="手机号" width="150" />
        <el-table-column prop="exception_type" label="异常类型" width="120">
          <template #default="scope">
            <el-tag :type="getExceptionTypeTag(scope.row.exception_type)">
              {{ getExceptionTypeName(scope.row.exception_type) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="status" label="状态" width="100">
          <template #default="scope">
            <el-tag :type="getStatusTag(scope.row.status)">
              {{ getStatusName(scope.row.status) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="description" label="异常描述" min-width="200" show-overflow-tooltip />
        <el-table-column prop="reported_by.name" label="报告人" width="100" />
        <el-table-column prop="created_at" label="报告时间" width="160" />
        <el-table-column label="操作" width="200" fixed="right">
          <template #default="scope">
            <el-button size="small" @click="showDetail(scope.row)">详情</el-button>
            <el-button 
              v-if="scope.row.status === 'pending'" 
              size="small" 
              type="warning" 
              @click="handleProcess(scope.row)"
            >
              处理
            </el-button>
            <el-button 
              v-if="scope.row.status === 'processing'" 
              size="small" 
              type="success" 
              @click="handleResolve(scope.row)"
            >
              解决
            </el-button>
            <el-button 
              v-if="scope.row.status === 'pending' || scope.row.status === 'processing'" 
              size="small" 
              type="danger" 
              @click="handleDelete(scope.row)"
            >
              删除
            </el-button>
          </template>
        </el-table-column>
      </el-table>
      
      <!-- 分页 -->
      <div class="pagination-container">
        <el-pagination
          v-model:current-page="currentPage"
          v-model:page-size="pageSize"
          :page-sizes="[10, 20, 50, 100]"
          :total="total"
          :layout="'total, sizes, prev, pager, next, jumper'"
          @size-change="handleSizeChange"
          @current-change="handleCurrentChange"
        />
      </div>
    </el-card>
    
    <!-- 创建异常对话框 -->
    <el-dialog v-model="createDialogVisible" title="新增异常" width="600px">
      <el-form :model="createForm" :rules="createRules" ref="createFormRef" label-width="100px">
        <el-form-item label="运单号" prop="tracking_number">
          <el-input v-model="createForm.tracking_number" placeholder="请输入运单号" />
        </el-form-item>
        <el-form-item label="异常类型" prop="exception_type">
          <el-select v-model="createForm.exception_type" placeholder="请选择异常类型" style="width: 100%;">
            <el-option label="滞留" value="overdue" />
            <el-option label="破损" value="damaged" />
            <el-option label="错发" value="wrong_delivery" />
            <el-option label="丢失" value="lost" />
            <el-option label="其他" value="other" />
          </el-select>
        </el-form-item>
        <el-form-item label="异常描述" prop="description">
          <el-input 
            v-model="createForm.description" 
            type="textarea" 
            :rows="4" 
            placeholder="请输入异常描述" 
            maxlength="500"
            show-word-limit
          />
        </el-form-item>
      </el-form>
      <template #footer>
        <span class="dialog-footer">
          <el-button @click="createDialogVisible = false">取消</el-button>
          <el-button type="primary" @click="handleCreate" :loading="createLoading">创建</el-button>
        </span>
      </template>
    </el-dialog>
    
    <!-- 处理异常对话框 -->
    <el-dialog v-model="processDialogVisible" title="处理异常" width="600px">
      <el-form :model="processForm" :rules="processRules" ref="processFormRef" label-width="100px">
        <el-form-item label="处理说明" prop="solution">
          <el-input 
            v-model="processForm.solution" 
            type="textarea" 
            :rows="4" 
            placeholder="请输入处理说明" 
            maxlength="500"
            show-word-limit
          />
        </el-form-item>
      </el-form>
      <template #footer>
        <span class="dialog-footer">
          <el-button @click="processDialogVisible = false">取消</el-button>
          <el-button type="primary" @click="handleProcessSubmit" :loading="processLoading">确认处理</el-button>
        </span>
      </template>
    </el-dialog>
    
    <!-- 解决异常对话框 -->
    <el-dialog v-model="resolveDialogVisible" title="解决异常" width="600px">
      <el-form :model="resolveForm" :rules="resolveRules" ref="resolveFormRef" label-width="100px">
        <el-form-item label="解决说明" prop="solution">
          <el-input 
            v-model="resolveForm.solution" 
            type="textarea" 
            :rows="4" 
            placeholder="请输入解决说明" 
            maxlength="500"
            show-word-limit
          />
        </el-form-item>
      </el-form>
      <template #footer>
        <span class="dialog-footer">
          <el-button @click="resolveDialogVisible = false">取消</el-button>
          <el-button type="primary" @click="handleResolveSubmit" :loading="resolveLoading">确认解决</el-button>
        </span>
      </template>
    </el-dialog>
    
    <!-- 异常详情对话框 -->
    <el-dialog v-model="detailDialogVisible" title="异常详情" width="800px">
      <div v-if="selectedException" class="exception-detail">
        <el-descriptions :column="2" border>
          <el-descriptions-item label="运单号">{{ selectedException.package?.tracking_number || '--' }}</el-descriptions-item>
          <el-descriptions-item label="收件人">{{ selectedException.package?.recipient_name || '--' }}</el-descriptions-item>
          <el-descriptions-item label="手机号">{{ selectedException.package?.recipient_phone || '--' }}</el-descriptions-item>
          <el-descriptions-item label="取件码">{{ selectedException.package?.pickup_code || '--' }}</el-descriptions-item>
          <el-descriptions-item label="异常类型">{{ getExceptionTypeName(selectedException.exception_type) }}</el-descriptions-item>
          <el-descriptions-item label="状态">
            <el-tag :type="getStatusTag(selectedException.status)">
              {{ getStatusName(selectedException.status) }}
            </el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="异常描述" :span="2">{{ selectedException.description || '--' }}</el-descriptions-item>
          <el-descriptions-item label="处理说明" :span="2">{{ selectedException.solution || '--' }}</el-descriptions-item>
          <el-descriptions-item label="报告人">{{ selectedException.reported_by?.name || '--' }}</el-descriptions-item>
          <el-descriptions-item label="报告时间">{{ selectedException.created_at || '--' }}</el-descriptions-item>
          <el-descriptions-item label="解决人">{{ selectedException.resolved_by?.name || '--' }}</el-descriptions-item>
          <el-descriptions-item label="解决时间">{{ selectedException.resolved_at || '--' }}</el-descriptions-item>
        </el-descriptions>
      </div>
      <template #footer>
        <span class="dialog-footer">
          <el-button @click="detailDialogVisible = false">关闭</el-button>
        </span>
      </template>
    </el-dialog>
  </div>
</template>

<script>
import { ref, reactive, onMounted, nextTick } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Search, Plus } from '@element-plus/icons-vue'
import axios from 'axios'

export default {
  name: 'ExceptionManagement',
  setup() {
    // 响应式数据
    const exceptions = ref([])
    const loading = ref(false)
    const searchKeyword = ref('')
    const exceptionType = ref('')
    const statusFilter = ref('')
    const currentPage = ref(1)
    const pageSize = ref(10)
    const total = ref(0)
    
    // 对话框状态
    const createDialogVisible = ref(false)
    const processDialogVisible = ref(false)
    const resolveDialogVisible = ref(false)
    const detailDialogVisible = ref(false)
    
    // 表单数据
    const createForm = reactive({
      tracking_number: '',
      exception_type: '',
      description: ''
    })
    
    const processForm = reactive({
      solution: ''
    })
    
    const resolveForm = reactive({
      solution: ''
    })
    
    const selectedException = ref(null)
    
    // 表单引用
    const createFormRef = ref(null)
    const processFormRef = ref(null)
    const resolveFormRef = ref(null)
    
    // 加载状态
    const createLoading = ref(false)
    const processLoading = ref(false)
    const resolveLoading = ref(false)
    
    // 表单验证规则
    const createRules = {
      tracking_number: [
        { required: true, message: '请输入运单号', trigger: 'blur' }
      ],
      exception_type: [
        { required: true, message: '请选择异常类型', trigger: 'change' }
      ],
      description: [
        { required: true, message: '请输入异常描述', trigger: 'blur' },
        { min: 5, message: '异常描述至少5个字符', trigger: 'blur' }
      ]
    }
    
    const processRules = {
      solution: [
        { required: true, message: '请输入处理说明', trigger: 'blur' },
        { min: 5, message: '处理说明至少5个字符', trigger: 'blur' }
      ]
    }
    
    const resolveRules = {
      solution: [
        { required: true, message: '请输入解决说明', trigger: 'blur' },
        { min: 5, message: '解决说明至少5个字符', trigger: 'blur' }
      ]
    }
    
    // 工具函数
    const getExceptionTypeName = (type) => {
      const types = {
        overdue: '滞留',
        damaged: '破损',
        wrong_delivery: '错发',
        lost: '丢失',
        other: '其他'
      }
      return types[type] || type
    }
    
    const getExceptionTypeTag = (type) => {
      const tags = {
        overdue: 'warning',
        damaged: 'danger',
        wrong_delivery: 'info',
        lost: 'danger',
        other: 'info'
      }
      return tags[type] || 'info'
    }
    
    const getStatusName = (status) => {
      const statuses = {
        pending: '待处理',
        processing: '处理中',
        resolved: '已解决'
      }
      return statuses[status] || status
    }
    
    const getStatusTag = (status) => {
      const tags = {
        pending: 'warning',
        processing: 'info',
        resolved: 'success'
      }
      return tags[status] || 'info'
    }
    
    // API调用函数
    const loadExceptions = async () => {
      loading.value = true
      
      try {
        const params = {
          page: currentPage.value,
          per_page: pageSize.value
        }
        
        // 安全的参数处理
        if (searchKeyword.value && typeof searchKeyword.value === 'string') {
          const trimmed = searchKeyword.value.trim()
          if (trimmed) params.search = trimmed
        }
        
        if (exceptionType.value && typeof exceptionType.value === 'string') {
          const trimmed = exceptionType.value.trim()
          if (trimmed) params.exception_type = trimmed
        }
        
        if (statusFilter.value && typeof statusFilter.value === 'string') {
          const trimmed = statusFilter.value.trim()
          if (trimmed) params.status = trimmed
        }
        
        const response = await axios.get('/api/v1/exceptions', { params })
        
        // 安全的数据处理
        exceptions.value = Array.isArray(response.data.data) ? response.data.data : []
        total.value = response.data.meta?.total || exceptions.value.length
        
      } catch (error) {
        console.error('获取异常列表失败:', error)
        ElMessage.error('获取异常列表失败')
        exceptions.value = []
        total.value = 0
      } finally {
        loading.value = false
      }
    }
    
    const handleSearch = () => {
      currentPage.value = 1
      loadExceptions()
    }
    
    const handleSizeChange = (size) => {
      pageSize.value = size
      currentPage.value = 1
      loadExceptions()
    }
    
    const handleCurrentChange = (current) => {
      currentPage.value = current
      loadExceptions()
    }
    
    // 对话框操作
    const showCreateDialog = () => {
      createForm.tracking_number = ''
      createForm.exception_type = ''
      createForm.description = ''
      createDialogVisible.value = true
      
      nextTick(() => {
        if (createFormRef.value) {
          createFormRef.value.clearValidate()
        }
      })
    }
    
    const handleCreate = async () => {
      if (!createFormRef.value) return
      
      try {
        await createFormRef.value.validate()
        createLoading.value = true
        
        // 首先根据运单号查找包裹ID
        const packageResponse = await axios.get('/api/v1/packages', {
          params: { tracking_number: createForm.tracking_number }
        })
        
        if (!packageResponse.data.data || packageResponse.data.data.length === 0) {
          throw new Error('未找到对应的包裹信息')
        }
        
        const packageId = packageResponse.data.data[0].id
        
        // 发送创建异常的请求
        const response = await axios.post('/api/v1/exceptions', {
          exception: {
            package_id: packageId,
            exception_type: createForm.exception_type,
            description: createForm.description
          }
        })
        
        ElMessage.success('异常创建成功')
        createDialogVisible.value = false
        loadExceptions()
        
      } catch (error) {
        console.error('创建异常失败:', error)
        if (error.message === '未找到对应的包裹信息') {
          ElMessage.error('未找到对应的包裹信息，请检查运单号是否正确')
        } else if (error.response?.data?.errors) {
          ElMessage.error(error.response.data.errors.join('、'))
        } else if (error.response?.data?.error) {
          ElMessage.error(error.response.data.error)
        } else {
          ElMessage.error('创建异常失败')
        }
      } finally {
        createLoading.value = false
      }
    }
    
    const showDetail = (exception) => {
      selectedException.value = exception
      detailDialogVisible.value = true
    }
    
    const handleProcess = (exception) => {
      selectedException.value = exception
      processForm.solution = ''
      processDialogVisible.value = true
      
      nextTick(() => {
        if (processFormRef.value) {
          processFormRef.value.clearValidate()
        }
      })
    }
    
    const handleProcessSubmit = async () => {
      if (!processFormRef.value || !selectedException.value) return
      
      try {
        await processFormRef.value.validate()
        processLoading.value = true
        
        const response = await axios.post(`/api/v1/exceptions/${selectedException.value.id}/process`, {
          solution: processForm.solution || ''
        })
        
        ElMessage.success('异常处理成功')
        processDialogVisible.value = false
        loadExceptions()
        
      } catch (error) {
        console.error('处理异常失败:', error)
        if (error.response?.data?.errors) {
          ElMessage.error(error.response.data.errors.join('、'))
        } else if (error.response?.data?.error) {
          ElMessage.error(error.response.data.error)
        } else {
          ElMessage.error('处理异常失败')
        }
      } finally {
        processLoading.value = false
      }
    }
    
    const handleResolve = (exception) => {
      selectedException.value = exception
      resolveForm.solution = ''
      resolveDialogVisible.value = true
      
      nextTick(() => {
        if (resolveFormRef.value) {
          resolveFormRef.value.clearValidate()
        }
      })
    }
    
    const handleResolveSubmit = async () => {
      if (!resolveFormRef.value || !selectedException.value) return
      
      try {
        await resolveFormRef.value.validate()
        resolveLoading.value = true
        
        const response = await axios.post(`/api/v1/exceptions/${selectedException.value.id}/resolve`, {
          solution: resolveForm.solution || ''
        })
        
        ElMessage.success('异常解决成功')
        resolveDialogVisible.value = false
        loadExceptions()
        
      } catch (error) {
        console.error('解决异常失败:', error)
        if (error.response?.data?.errors) {
          ElMessage.error(error.response.data.errors.join('、'))
        } else if (error.response?.data?.error) {
          ElMessage.error(error.response.data.error)
        } else {
          ElMessage.error('解决异常失败')
        }
      } finally {
        resolveLoading.value = false
      }
    }
    
    const handleDelete = async (exception) => {
      try {
        await ElMessageBox.confirm(
          `确定要删除异常记录吗？运单号：${exception.package?.tracking_number}`,
          '确认删除',
          {
            confirmButtonText: '确定',
            cancelButtonText: '取消',
            type: 'warning'
          }
        )
        
        await axios.delete(`/api/v1/exceptions/${exception.id}`)
        ElMessage.success('异常删除成功')
        loadExceptions()
        
      } catch (error) {
        if (error !== 'cancel') {
          console.error('删除异常失败:', error)
          ElMessage.error('删除异常失败')
        }
      }
    }
    
    // 生命周期
    onMounted(() => {
      loadExceptions()
    })
    
    return {
      // 响应式数据
      exceptions,
      loading,
      searchKeyword,
      exceptionType,
      statusFilter,
      currentPage,
      pageSize,
      total,
      
      // 对话框状态
      createDialogVisible,
      processDialogVisible,
      resolveDialogVisible,
      detailDialogVisible,
      
      // 表单数据
      createForm,
      processForm,
      resolveForm,
      selectedException,
      
      // 表单引用
      createFormRef,
      processFormRef,
      resolveFormRef,
      
      // 加载状态
      createLoading,
      processLoading,
      resolveLoading,
      
      // 图标
      Search,
      Plus,
      
      // 方法
      handleSearch,
      handleSizeChange,
      handleCurrentChange,
      showCreateDialog,
      handleCreate,
      showDetail,
      handleProcess,
      handleProcessSubmit,
      handleResolve,
      handleResolveSubmit,
      handleDelete,
      
      // 工具函数
      getExceptionTypeName,
      getExceptionTypeTag,
      getStatusName,
      getStatusTag
    }
  }
}
</script>

<style scoped>
.exception-management {
  padding: 20px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.search-bar {
  margin-bottom: 20px;
  display: flex;
  align-items: center;
}

.pagination-container {
  margin-top: 20px;
  display: flex;
  justify-content: center;
}

.exception-detail {
  padding: 10px 0;
}
</style>