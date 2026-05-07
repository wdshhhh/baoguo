<template>
  <div class="settings">
    <el-card class="mb-4">
      <template #header>
        <div class="card-header">
          <h2>系统设置</h2>
        </div>
      </template>
      
      <el-tabs v-model="activeTab">
        <el-tab-pane label="用户管理" name="users">
          <div class="users-section">
            <div class="section-header">
              <h3>用户列表</h3>
              <el-button type="primary" @click="showAddUserDialog">
                <el-icon><Plus /></el-icon>
                新增用户
              </el-button>
            </div>
            
            <el-table :data="users" style="width: 100%">
              <el-table-column prop="id" label="ID" width="80" />
              <el-table-column prop="username" label="用户名" width="150" />
              <el-table-column prop="phone" label="手机号" width="150" />
              <el-table-column prop="role" label="角色" width="120">
                <template #default="scope">
                  <el-tag
                    :type="scope.row.role === 'admin' ? 'danger' : scope.row.role === 'staff' ? 'primary' : 'info'"
                  >
                    {{ scope.row.role === 'admin' ? '管理员' : scope.row.role === 'staff' ? '工作人员' : '普通用户' }}
                  </el-tag>
                </template>
              </el-table-column>
              <el-table-column prop="created_at" label="创建时间" width="180" />
              <el-table-column label="操作" width="150" fixed="right">
                <template #default="scope">
                  <el-button size="small" type="primary" @click="editUser(scope.row)">
                    编辑
                  </el-button>
                  <el-button size="small" type="danger" @click="deleteUser(scope.row)">
                    删除
                  </el-button>
                </template>
              </el-table-column>
            </el-table>
          </div>
        </el-tab-pane>
        
        <el-tab-pane label="系统参数" name="params">
          <div class="params-section">
            <div class="section-header">
              <h3>系统参数设置</h3>
            </div>
            
            <el-form :model="systemParams" label-width="150px">
              <el-form-item label="取件码长度">
                <el-input v-model.number="systemParams.pickup_code_length" />
              </el-form-item>
              <el-form-item label="包裹滞留天数">
                <el-input v-model.number="systemParams.retention_days" />
              </el-form-item>
              <el-form-item label="默认快递公司">
                <el-input v-model="systemParams.default_carrier" />
              </el-form-item>
              <el-form-item label="系统名称">
                <el-input v-model="systemParams.system_name" />
              </el-form-item>
              <el-form-item>
                <el-button type="primary" @click="saveParams">保存设置</el-button>
              </el-form-item>
            </el-form>
          </div>
        </el-tab-pane>
        
        <el-tab-pane label="数据导出" name="export">
          <div class="export-section">
            <div class="section-header">
              <h3>数据导出</h3>
              <p>导出包裹数据用于分析和报表</p>
            </div>
            
            <el-form :model="exportForm" label-width="120px">
              <el-form-item label="导出类型">
                <el-radio-group v-model="exportForm.type">
                  <el-radio value="excel">Excel格式</el-radio>
                  <el-radio value="csv">CSV格式</el-radio>
                  <el-radio value="pdf">PDF报表</el-radio>
                </el-radio-group>
              </el-form-item>
              
              <el-form-item label="时间范围">
                <el-date-picker
                  v-model="exportForm.dateRange"
                  type="daterange"
                  range-separator="至"
                  start-placeholder="开始日期"
                  end-placeholder="结束日期"
                  style="width: 300px;"
                />
              </el-form-item>
              
              <el-form-item label="包裹状态">
                <el-checkbox-group v-model="exportForm.statuses">
                  <el-checkbox label="pending">待入库</el-checkbox>
                  <el-checkbox label="stored">已入库</el-checkbox>
                  <el-checkbox label="picked_up">已取件</el-checkbox>
                  <el-checkbox label="exception">异常</el-checkbox>
                </el-checkbox-group>
              </el-form-item>
              
              <el-form-item label="包含字段">
                <el-checkbox-group v-model="exportForm.fields">
                  <el-checkbox label="tracking_number">运单号</el-checkbox>
                  <el-checkbox label="recipient_name">收件人</el-checkbox>
                  <el-checkbox label="recipient_phone">手机号</el-checkbox>
                  <el-checkbox label="pickup_code">取件码</el-checkbox>
                  <el-checkbox label="status">状态</el-checkbox>
                  <el-checkbox label="stored_at">入库时间</el-checkbox>
                  <el-checkbox label="picked_up_at">取件时间</el-checkbox>
                  <el-checkbox label="storage_location">存储位置</el-checkbox>
                </el-checkbox-group>
              </el-form-item>
              
              <el-form-item>
                <el-button type="primary" @click="exportData" :loading="exportLoading">
                  <el-icon><Download /></el-icon>
                  导出数据
                </el-button>
                <el-button @click="resetExportForm">重置</el-button>
              </el-form-item>
            </el-form>
            
            <div v-if="exportHistory.length > 0" class="export-history">
              <h4>导出历史</h4>
              <el-table :data="exportHistory" style="width: 100%">
                <el-table-column prop="filename" label="文件名" />
                <el-table-column prop="type" label="类型" width="100" />
                <el-table-column prop="record_count" label="记录数" width="100" />
                <el-table-column prop="created_at" label="导出时间" width="180" />
                <el-table-column label="操作" width="120">
                  <template #default="scope">
                    <el-button size="small" @click="downloadExport(scope.row)">下载</el-button>
                  </template>
                </el-table-column>
              </el-table>
            </div>
          </div>
        </el-tab-pane>
        
        <el-tab-pane label="操作日志" name="logs">
          <div class="logs-section">
            <div class="section-header">
              <h3>操作日志</h3>
            </div>
            
            <el-table :data="logs" style="width: 100%">
              <el-table-column prop="id" label="ID" width="80" />
              <el-table-column prop="user.username" label="操作人" width="150" />
              <el-table-column prop="action" label="操作" width="120" />
              <el-table-column prop="target_type" label="操作对象" width="120" />
              <el-table-column prop="target_id" label="对象ID" width="100" />
              <el-table-column prop="ip" label="IP地址" width="150" />
              <el-table-column prop="created_at" label="操作时间" width="180" />
            </el-table>
            
            <div class="pagination" style="margin-top: 20px;">
              <el-pagination
                v-model:current-page="currentPage"
                v-model:page-size="pageSize"
                :page-sizes="[10, 20, 50, 100]"
                :layout="'total, sizes, prev, pager, next, jumper'"
                :total="logsTotal"
                @size-change="handleSizeChange"
                @current-change="handleCurrentChange"
                :hide-on-single-page="true"
              />
            </div>
          </div>
        </el-tab-pane>
      </el-tabs>
    </el-card>
    
    <!-- 新增用户对话框 -->
    <el-dialog v-model="addUserDialogVisible" title="新增用户">
      <el-form :model="newUser" label-width="100px">
        <el-form-item label="用户名">
          <el-input v-model="newUser.username" />
        </el-form-item>
        <el-form-item label="手机号">
          <el-input v-model="newUser.phone" />
        </el-form-item>
        <el-form-item label="密码">
          <el-input v-model="newUser.password" type="password" />
        </el-form-item>
        <el-form-item label="角色">
          <el-select v-model="newUser.role">
            <el-option label="管理员" value="admin" />
            <el-option label="工作人员" value="staff" />
            <el-option label="普通用户" value="user" />
          </el-select>
        </el-form-item>
      </el-form>
      <template #footer>
        <span class="dialog-footer">
          <el-button @click="addUserDialogVisible = false">取消</el-button>
          <el-button type="primary" @click="addUser">确定</el-button>
        </span>
      </template>
    </el-dialog>
  </div>
</template>

<script>
import { Plus, Download } from '@element-plus/icons-vue'
import { ref, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import axios from 'axios'

export default {
  name: 'Settings',
  setup() {
    const activeTab = ref('users')
    const users = ref([])
    const logs = ref([])
    const currentPage = ref(1)
    const pageSize = ref(10)
    const logsTotal = ref(0)
    const addUserDialogVisible = ref(false)
    const newUser = ref({
      username: '',
      phone: '',
      password: '',
      role: 'user'
    })
    const systemParams = ref({
      pickup_code_length: 8,
      retention_days: 7,
      default_carrier: '顺丰',
      system_name: '易站快递驿站'
    })
    
    // 数据导出相关
    const exportForm = ref({
      type: 'excel',
      dateRange: [],
      statuses: ['stored', 'picked_up'],
      fields: ['tracking_number', 'recipient_name', 'recipient_phone', 'pickup_code', 'status', 'stored_at', 'picked_up_at']
    })
    const exportLoading = ref(false)
    const exportHistory = ref([])
    
    const loadUsers = () => {
      // 模拟数据
      users.value = [
        {
          id: 1,
          username: 'admin',
          phone: '13800138000',
          role: 'admin',
          created_at: '2026-04-01 00:00:00'
        },
        {
          id: 2,
          username: 'staff',
          phone: '13900139000',
          role: 'staff',
          created_at: '2026-04-01 00:00:00'
        }
      ]
    }
    
    const loadLogs = () => {
      // 模拟数据
      logs.value = [
        {
          id: 1,
          user: { username: 'admin' },
          action: 'login',
          target_type: 'user',
          target_id: 1,
          ip: '127.0.0.1',
          created_at: '2026-04-02 10:00:00'
        },
        {
          id: 2,
          user: { username: 'staff' },
          action: 'store',
          target_type: 'package',
          target_id: 1,
          ip: '127.0.0.1',
          created_at: '2026-04-02 10:30:00'
        }
      ]
      logsTotal.value = 2
    }
    
    const showAddUserDialog = () => {
      addUserDialogVisible.value = true
    }
    
    const addUser = () => {
      // 实现新增用户功能
      addUserDialogVisible.value = false
      loadUsers()
    }
    
    const editUser = (user) => {
      // 实现编辑用户功能
      console.log('编辑用户', user)
    }
    
    const deleteUser = (user) => {
      // 实现删除用户功能
      loadUsers()
    }
    
    const saveParams = () => {
      // 实现保存系统参数功能
      console.log('保存系统参数', systemParams.value)
      ElMessage.success('保存成功')
    }
    
    // 数据导出功能
    const exportData = async () => {
      if (!exportForm.value.dateRange || exportForm.value.dateRange.length !== 2) {
        ElMessage.error('请选择时间范围')
        return
      }
      
      if (exportForm.value.fields.length === 0) {
        ElMessage.error('请选择要导出的字段')
        return
      }
      
      exportLoading.value = true
      
      try {
        const params = {
          type: exportForm.value.type,
          start_date: exportForm.value.dateRange[0].toISOString().split('T')[0],
          end_date: exportForm.value.dateRange[1].toISOString().split('T')[0],
          statuses: exportForm.value.statuses.join(','),
          fields: exportForm.value.fields.join(',')
        }
        
        const response = await axios.get('/api/v1/packages/export', { 
          params,
          responseType: 'blob'
        })
        
        // 创建下载链接
        const url = window.URL.createObjectURL(new Blob([response.data]))
        const link = document.createElement('a')
        const filename = `packages_export_${new Date().getTime()}.${exportForm.value.type}`
        
        link.href = url
        link.setAttribute('download', filename)
        document.body.appendChild(link)
        link.click()
        link.remove()
        window.URL.revokeObjectURL(url)
        
        // 添加到导出历史
        exportHistory.value.unshift({
          filename: filename,
          type: exportForm.value.type,
          record_count: '未知',
          created_at: new Date().toLocaleString()
        })
        
        ElMessage.success('导出成功')
        
      } catch (error) {
        console.error('导出失败:', error)
        ElMessage.error('导出失败，请重试')
      } finally {
        exportLoading.value = false
      }
    }
    
    const resetExportForm = () => {
      exportForm.value = {
        type: 'excel',
        dateRange: [],
        statuses: ['stored', 'picked_up'],
        fields: ['tracking_number', 'recipient_name', 'recipient_phone', 'pickup_code', 'status', 'stored_at', 'picked_up_at']
      }
    }
    
    const downloadExport = (exportRecord) => {
      ElMessage.info('下载功能开发中...')
    }
    
    const handleSizeChange = (size) => {
      pageSize.value = size
      loadLogs()
    }
    
    const handleCurrentChange = (current) => {
      currentPage.value = current
      loadLogs()
    }
    
    onMounted(() => {
      loadUsers()
      loadLogs()
    })
    
    return {
      activeTab,
      users,
      logs,
      currentPage,
      pageSize,
      logsTotal,
      addUserDialogVisible,
      newUser,
      systemParams,
      showAddUserDialog,
      addUser,
      editUser,
      deleteUser,
      saveParams,
      handleSizeChange,
      handleCurrentChange
    }
  }
}
</script>

<style scoped>
.settings {
  padding: 0;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.dialog-footer {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
}
</style>
