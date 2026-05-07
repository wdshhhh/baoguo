<template>
  <div class="exceptions">
    <el-card class="mb-4">
      <template #header>
        <div class="card-header">
          <h2>异常处理</h2>
          <el-button type="primary" @click="showCreateDialog">
            <el-icon><Plus /></el-icon>
            新增异常
          </el-button>
        </div>
      </template>
      
      <div class="search-bar">
        <el-input
          v-model="searchKeyword"
          placeholder="搜索运单号/手机号/取件码"
          style="width: 300px; margin-right: 10px;"
        >
          <template #append>
            <el-button @click="searchExceptions">
              <el-icon><Search /></el-icon>
            </el-button>
          </template>
        </el-input>
        
        <el-select v-model="exceptionType" placeholder="异常类型" style="width: 150px; margin-right: 10px;">
          <el-option label="全部" value="" />
          <el-option label="滞留" value="overdue" />
          <el-option label="破损" value="damaged" />
          <el-option label="错发" value="wrong_delivery" />
          <el-option label="丢失" value="lost" />
          <el-option label="其他" value="other" />
        </el-select>
        
        <el-select v-model="statusFilter" placeholder="处理状态" style="width: 150px;">
          <el-option label="全部" value="" />
          <el-option label="待处理" value="pending" />
          <el-option label="处理中" value="processing" />
          <el-option label="已解决" value="resolved" />
        </el-select>
      </div>
      
      <el-table :data="exceptions" style="width: 100%" v-loading="loading">
        <el-table-column prop="package.tracking_number" label="运单号" width="180" />
        <el-table-column prop="package.recipient_name" label="收件人" width="120" />
        <el-table-column prop="package.recipient_phone" label="手机号" width="150" />
        <el-table-column prop="exception_type" label="异常类型" width="120">
          <template #default="scope">
            <el-tag type="danger">
              {{ getExceptionTypeName(scope.row.exception_type) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="status" label="处理状态" width="120">
          <template #default="scope">
            <el-tag
              :type="scope.row.status === 'pending' ? 'warning' : scope.row.status === 'processing' ? 'info' : 'success'"
            >
              {{ scope.row.status === 'pending' ? '待处理' : scope.row.status === 'processing' ? '处理中' : '已解决' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="description" label="异常描述" min-width="200" />
        <el-table-column prop="reported_by.name" label="报告人" width="120" />
        <el-table-column prop="created_at" label="创建时间" width="180" />
        <el-table-column label="操作" width="200" fixed="right">
          <template #default="scope">
            <el-button 
              size="small" 
              type="primary" 
              @click="showDetailDialog(scope.row)"
              :disabled="scope.row.status === 'resolved'"
            >
              详情
            </el-button>
            <el-button 
              size="small" 
              type="warning" 
              @click="processException(scope.row)"
              :disabled="scope.row.status !== 'pending'"
            >
              处理
            </el-button>
            <el-button 
              size="small" 
              type="success" 
              @click="resolveException(scope.row)"
              :disabled="scope.row.status === 'resolved'"
            >
              解决
            </el-button>
          </template>
        </el-table-column>
      </el-table>
      
      <div class="pagination" style="margin-top: 20px;">
        <el-pagination
          v-model:current-page="currentPage"
          v-model:page-size="pageSize"
          :page-sizes="[10, 20, 50, 100]"
          :layout="'total, sizes, prev, pager, next, jumper'"
          :total="total"
          @size-change="handleSizeChange"
          @current-change="handleCurrentChange"
          :hide-on-single-page="true"
        />
      </div>
    </el-card>
    
    <!-- 新增异常对话框 -->
    <el-dialog v-model="createDialogVisible" title="新增异常" width="600px">
      <el-form :model="createForm" label-width="100px" :rules="createRules" ref="createFormRef">
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
            :rows="3" 
            placeholder="请输入异常描述" 
            maxlength="500"
            show-word-limit
          />
        </el-form-item>
      </el-form>
      <template #footer>
        <span class="dialog-footer">
          <el-button @click="createDialogVisible = false">取消</el-button>
          <el-button type="primary" @click="createException" :loading="createLoading">确定</el-button>
        </span>
      </template>
    </el-dialog>
    
    <!-- 异常详情对话框 -->
    <el-dialog v-model="detailDialogVisible" title="异常详情" width="700px">
      <div v-if="selectedException" class="exception-detail">
        <el-descriptions :column="2" border>
          <el-descriptions-item label="运单号">{{ selectedException.package?.tracking_number }}</el-descriptions-item>
          <el-descriptions-item label="收件人">{{ selectedException.package?.recipient_name }}</el-descriptions-item>
          <el-descriptions-item label="手机号">{{ selectedException.package?.recipient_phone }}</el-descriptions-item>
          <el-descriptions-item label="取件码">{{ selectedException.package?.pickup_code }}</el-descriptions-item>
          <el-descriptions-item label="异常类型">{{ getExceptionTypeName(selectedException.exception_type) }}</el-descriptions-item>
          <el-descriptions-item label="处理状态">{{ selectedException.status === 'pending' ? '待处理' : selectedException.status === 'processing' ? '处理中' : '已解决' }}</el-descriptions-item>
          <el-descriptions-item label="异常描述" :span="2">{{ selectedException.description }}</el-descriptions-item>
          <el-descriptions-item label="报告人">{{ selectedException.reported_by?.name }}</el-descriptions-item>
          <el-descriptions-item label="报告时间">{{ formatDate(selectedException.created_at) }}</el-descriptions-item>
          <el-descriptions-item label="处理人">{{ selectedException.resolved_by?.name || '--' }}</el-descriptions-item>
          <el-descriptions-item label="解决时间">{{ formatDate(selectedException.resolved_at) }}</el-descriptions-item>
          <el-descriptions-item label="处理结果" :span="2">{{ selectedException.resolution || '--' }}</el-descriptions-item>
        </el-descriptions>
      </div>
      <template #footer>
        <span class="dialog-footer">
          <el-button @click="detailDialogVisible = false">关闭</el-button>
        </span>
      </template>
    </el-dialog>
    
    <!-- 处理异常对话框 -->
    <el-dialog v-model="processDialogVisible" title="处理异常" width="600px">
      <el-form :model="processForm" label-width="100px" :rules="processRules" ref="processFormRef">
        <el-form-item label="处理说明" prop="resolution">
          <el-input 
            v-model="processForm.resolution" 
            type="textarea" 
            :rows="3" 
            placeholder="请输入处理说明" 
            maxlength="500"
            show-word-limit
          />
        </el-form-item>
      </el-form>
      <template #footer>
        <span class="dialog-footer">
          <el-button @click="processDialogVisible = false">取消</el-button>
          <el-button type="primary" @click="submitProcess" :loading="processLoading">确定处理</el-button>
        </span>
      </template>
    </el-dialog>
    
    <!-- 解决异常对话框 -->
    <el-dialog v-model="resolveDialogVisible" title="解决异常" width="600px">
      <el-form :model="resolveForm" label-width="100px" :rules="resolveRules" ref="resolveFormRef">
        <el-form-item label="解决说明" prop="resolution">
          <el-input 
            v-model="resolveForm.resolution" 
            type="textarea" 
            :rows="3" 
            placeholder="请输入解决说明" 
            maxlength="500"
            show-word-limit
          />
        </el-form-item>
      </el-form>
      <template #footer>
        <span class="dialog-footer">
          <el-button @click="resolveDialogVisible = false">取消</el-button>
          <el-button type="primary" @click="submitResolve" :loading="resolveLoading">确认解决</el-button>
        </span>
      </template>
    </el-dialog>
  </div>
</template>

<script>
import { Search, Plus } from '@element-plus/icons-vue'
import { ref, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import axios from 'axios'

export default {
  name: 'Exceptions',
  setup() {
    const exceptions = ref([])
    const searchKeyword = ref('')
    const exceptionType = ref('')
    const statusFilter = ref('')
    const currentPage = ref(1)
    const pageSize = ref(10)
    const total = ref(0)
    const loading = ref(false)
    
    // 对话框相关
    const createDialogVisible = ref(false)
    const detailDialogVisible = ref(false)
    const processDialogVisible = ref(false)
    const resolveDialogVisible = ref(false)
    
    // 表单相关
    const createForm = ref({
      tracking_number: '',
      exception_type: '',
      description: ''
    })
    const createFormRef = ref(null)
    const createLoading = ref(false)
    
    const selectedException = ref(null)
    const processForm = ref({ resolution: '' })
    const processFormRef = ref(null)
    const processLoading = ref(false)
    
    const resolveForm = ref({ resolution: '' })
    const resolveFormRef = ref(null)
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
      resolution: [
        { required: true, message: '请输入处理说明', trigger: 'blur' },
        { min: 5, message: '处理说明至少5个字符', trigger: 'blur' }
      ]
    }
    
    const resolveRules = {
      resolution: [
        { required: true, message: '请输入解决说明', trigger: 'blur' },
        { min: 5, message: '解决说明至少5个字符', trigger: 'blur' }
      ]
    }
    
    const loadExceptions = async () => {
      loading.value = true
      
      try {
        const params = {
          page: currentPage.value,
          per_page: pageSize.value
        }
        
        // 修复：确保字符串值不为null或undefined
        if (searchKeyword.value && typeof searchKeyword.value === 'string' && searchKeyword.value.trim()) {
          params.search = searchKeyword.value.trim()
        }
        
        if (exceptionType.value && typeof exceptionType.value === 'string' && exceptionType.value.trim()) {
          params.exception_type = exceptionType.value.trim()
        }
        
        if (statusFilter.value && typeof statusFilter.value === 'string' && statusFilter.value.trim()) {
          params.status = statusFilter.value.trim()
        }
        
        const response = await axios.get('/api/v1/exceptions', { params })
        
        // 后端返回的数据结构是 { data: [...] }
        exceptions.value = Array.isArray(response.data.data) ? response.data.data : []
        total.value = response.data.meta?.total || exceptions.value.length
        
      } catch (error) {
        console.error('获取异常列表失败:', error)
        ElMessage.error('获取异常列表失败')
        
        // 模拟数据（当API不可用时）
        exceptions.value = [
          {
            id: 1,
            package: {
              tracking_number: 'SF1234567890',
              recipient_name: '张三',
              recipient_phone: '13800138000',
              pickup_code: '04060001'
            },
            exception_type: 'overdue',
            status: 'pending',
            description: '超过7天未取件，客户联系不上',
            reported_by: { name: '李四' },
            created_at: '2026-04-02 10:00:00'
          },
          {
            id: 2,
            package: {
              tracking_number: 'YT9876543210',
              recipient_name: '王五',
              recipient_phone: '13900139000',
              pickup_code: '04060002'
            },
            exception_type: 'damaged',
            status: 'processing',
            description: '包裹外部有破损，需要联系快递公司处理',
            reported_by: { name: '赵六' },
            created_at: '2026-04-02 09:00:00'
          }
        ]
        total.value = 2
      } finally {
        loading.value = false
      }
    }
    
    const searchExceptions = () => {
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
    
    const showCreateDialog = () => {
      createForm.value = {
        tracking_number: '',
        exception_type: '',
        description: ''
      }
      createDialogVisible.value = true
    }
    
    const createException = async () => {
      if (!createFormRef.value) return
      
      try {
        await createFormRef.value.validate()
        createLoading.value = true
        
        const response = await axios.post('/api/v1/exceptions', { exception: createForm.value })
        
        // 后端返回的数据结构是 { data: ... }
        ElMessage.success('异常创建成功')
        createDialogVisible.value = false
        loadExceptions()
        
      } catch (error) {
        console.error('创建异常失败:', error)
        if (error.response?.data?.errors) {
          ElMessage.error(error.response.data.errors.join('、'))
        } else {
          ElMessage.error('异常创建失败')
        }
      } finally {
        createLoading.value = false
      }
    }
    
    const showDetailDialog = (exception) => {
      selectedException.value = exception
      detailDialogVisible.value = true
    }
    
    const processException = (exception) => {
      try {
        selectedException.value = exception
        processForm.value = { resolution: '' }
        processDialogVisible.value = true
      } catch (error) {
        console.error('打开处理对话框失败:', error)
        ElMessage.error('打开处理对话框失败')
      }
    }
    
    const submitProcess = async () => {
      if (!processFormRef.value || !selectedException.value) return
      
      try {
        await processFormRef.value.validate()
        processLoading.value = true
        
        const response = await axios.post(`/api/v1/exceptions/${selectedException.value.id}/process`, {
          resolution: processForm.value.resolution || ''
        })
        
        // 后端返回的数据结构是 { data: ... }
        ElMessage.success('异常处理成功')
        processDialogVisible.value = false
        loadExceptions()
        
      } catch (error) {
        console.error('处理异常失败:', error)
        if (error.response?.data?.error) {
          ElMessage.error(`处理异常失败: ${error.response.data.error}`)
        } else {
          ElMessage.error('异常处理失败')
        }
      } finally {
        processLoading.value = false
      }
    }
    
    const resolveException = (exception) => {
      try {
        selectedException.value = exception
        resolveForm.value = { resolution: '' }
        resolveDialogVisible.value = true
      } catch (error) {
        console.error('打开解决对话框失败:', error)
        ElMessage.error('打开解决对话框失败')
      }
    }
    
    const submitResolve = async () => {
      if (!resolveFormRef.value || !selectedException.value) return
      
      try {
        await resolveFormRef.value.validate()
        resolveLoading.value = true
        
        const response = await axios.post(`/api/v1/exceptions/${selectedException.value.id}/resolve`, {
          resolution: resolveForm.value.resolution || ''
        })
        
        // 后端返回的数据结构是 { data: ... }
        ElMessage.success('异常解决成功')
        resolveDialogVisible.value = false
        loadExceptions()
        
      } catch (error) {
        console.error('解决异常失败:', error)
        if (error.response?.data?.error) {
          ElMessage.error(`解决异常失败: ${error.response.data.error}`)
        } else {
          ElMessage.error('异常解决失败')
        }
      } finally {
        resolveLoading.value = false
      }
    }
    
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
    
    const formatDate = (dateString) => {
      if (!dateString) return '--'
      const date = new Date(dateString)
      return date.toLocaleString('zh-CN', {
        year: 'numeric',
        month: '2-digit',
        day: '2-digit',
        hour: '2-digit',
        minute: '2-digit'
      })
    }
    
    onMounted(() => {
      loadExceptions()
    })
    
    return {
      exceptions,
      searchKeyword,
      exceptionType,
      statusFilter,
      currentPage,
      pageSize,
      total,
      loading,
      createDialogVisible,
      detailDialogVisible,
      processDialogVisible,
      resolveDialogVisible,
      createForm,
      createFormRef,
      createLoading,
      selectedException,
      processForm,
      processFormRef,
      processLoading,
      resolveForm,
      resolveFormRef,
      resolveLoading,
      createRules,
      processRules,
      resolveRules,
      searchExceptions,
      handleSizeChange,
      handleCurrentChange,
      showCreateDialog,
      createException,
      showDetailDialog,
      processException,
      submitProcess,
      resolveException,
      submitResolve,
      getExceptionTypeName,
      formatDate
    }
  }
}
</script>

<style scoped>
.exceptions {
  padding: 0;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.search-bar {
  display: flex;
  align-items: center;
  margin-bottom: 20px;
  flex-wrap: wrap;
  gap: 10px;
}
</style>
