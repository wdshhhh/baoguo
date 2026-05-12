<template>
  <div class="settings">
    <el-card class="mb-4">
      <template #header>
        <div class="card-header">
          <h2>系统设置</h2>
        </div>
      </template>
      
      <el-tabs v-model="activeTab" @tab-change="handleTabChange">
        <!-- 基础信息设置 -->
        <el-tab-pane label="基础信息" name="basic">
          <div class="section">
            <div class="section-header">
              <h3>🏠 基础信息设置</h3>
            </div>
            
            <el-form :model="basicSettings" :rules="basicRules" ref="basicForm" label-width="150px">
              <el-form-item label="站点名称" prop="site_name">
                <el-input v-model="basicSettings.site_name" :disabled="!canModify" />
              </el-form-item>
              <el-form-item label="站点地址" prop="site_address">
                <el-input v-model="basicSettings.site_address" :disabled="!canModify" />
              </el-form-item>
              <el-form-item label="联系电话" prop="contact_phone">
                <el-input v-model="basicSettings.contact_phone" :disabled="!canModify" />
              </el-form-item>
              <el-form-item label="管理员姓名" prop="admin_name">
                <el-input v-model="basicSettings.admin_name" :disabled="!canModify" />
              </el-form-item>
              <el-form-item label="管理员邮箱" prop="admin_email">
                <el-input v-model="basicSettings.admin_email" :disabled="!canModify" />
              </el-form-item>
              <el-form-item label="服务说明" prop="service_description">
                <el-input type="textarea" v-model="basicSettings.service_description" :disabled="!canModify" :rows="3" />
              </el-form-item>
              <el-form-item>
                <el-button type="primary" @click="saveBasicSettings" :disabled="!canModify" :loading="basicSaving">保存</el-button>
                <el-button @click="resetBasicSettings">重置</el-button>
              </el-form-item>
            </el-form>
          </div>
        </el-tab-pane>
        
        <!-- 包裹规则设置 -->
        <el-tab-pane label="包裹规则" name="package_rules">
          <div class="section">
            <div class="section-header">
              <h3>📦 包裹规则设置</h3>
            </div>
            
            <el-form :model="packageRules" :rules="packageRulesRules" ref="packageRulesForm" label-width="180px">
              <el-form-item label="免费存放天数(天)" prop="overdue_days">
                <el-input v-model.number="packageRules.overdue_days" :disabled="!canModify" />
              </el-form-item>
              <el-form-item label="超期日收费(元)" prop="overdue_fee_per_day">
                <el-input v-model.number="packageRules.overdue_fee_per_day" :disabled="!canModify" />
              </el-form-item>
              <el-form-item label="最大存放天数(天)" prop="max_storage_days">
                <el-input v-model.number="packageRules.max_storage_days" :disabled="!canModify" />
              </el-form-item>
              <el-form-item label="大件阈值(kg)" prop="large_package_weight">
                <el-input v-model.number="packageRules.large_package_weight" :disabled="!canModify" />
              </el-form-item>
              <el-form-item label="异常标记天数(天)" prop="exception_days">
                <el-input v-model.number="packageRules.exception_days" :disabled="!canModify" />
              </el-form-item>
              <el-form-item label="自动标记异常">
                <el-switch v-model="packageRules.auto_mark_exception" :disabled="!canModify" />
              </el-form-item>
              <el-form-item>
                <el-button type="primary" @click="savePackageRules" :disabled="!canModify" :loading="packageRulesSaving">保存</el-button>
                <el-button @click="resetPackageRules">重置</el-button>
              </el-form-item>
            </el-form>
          </div>
        </el-tab-pane>
        
        <!-- 通知设置 -->
        <el-tab-pane label="通知设置" name="notification">
          <div class="section">
            <div class="section-header">
              <h3>🔔 通知设置</h3>
            </div>
            
            <el-form :model="notificationSettings" ref="notificationForm" label-width="150px">
              <el-form-item label="短信通知">
                <el-switch v-model="notificationSettings.sms_notification" :disabled="!canModify" />
              </el-form-item>
              <el-form-item label="邮件通知">
                <el-switch v-model="notificationSettings.email_notification" :disabled="!canModify" />
              </el-form-item>
              <el-form-item label="微信通知">
                <el-switch v-model="notificationSettings.wechat_notification" :disabled="!canModify" />
              </el-form-item>
              <el-form-item label="入库通知">
                <el-switch v-model="notificationSettings.notify_on_stored" :disabled="!canModify" />
              </el-form-item>
              <el-form-item label="超期前通知">
                <el-switch v-model="notificationSettings.notify_before_overdue" :disabled="!canModify" />
              </el-form-item>
              <el-form-item label="超期提前天数(天)" prop="overdue_notify_days">
                <el-input v-model.number="notificationSettings.overdue_notify_days" :disabled="!canModify" />
              </el-form-item>
              <el-form-item>
                <el-button type="primary" @click="saveNotificationSettings" :disabled="!canModify" :loading="notificationSaving">保存</el-button>
                <el-button @click="resetNotificationSettings">重置</el-button>
              </el-form-item>
            </el-form>
          </div>
        </el-tab-pane>
        
        <!-- 营业时间设置 -->
        <el-tab-pane label="营业时间" name="business_hours">
          <div class="section">
            <div class="section-header">
              <h3>⏰ 营业时间设置</h3>
            </div>
            
            <el-form :model="businessHours" :rules="businessHoursRules" ref="businessHoursForm" label-width="150px">
              <el-divider content-position="left">工作日时间</el-divider>
              <el-form-item label="上班时间" prop="work_start_time">
                <el-time-picker v-model="businessHours.work_start_time" format="HH:mm" :disabled="!canModify" />
              </el-form-item>
              <el-form-item label="下班时间" prop="work_end_time">
                <el-time-picker v-model="businessHours.work_end_time" format="HH:mm" :disabled="!canModify" />
              </el-form-item>
              <el-form-item label="午休开始" prop="break_start_time">
                <el-time-picker v-model="businessHours.break_start_time" format="HH:mm" :disabled="!canModify" />
              </el-form-item>
              <el-form-item label="午休结束" prop="break_end_time">
                <el-time-picker v-model="businessHours.break_end_time" format="HH:mm" :disabled="!canModify" />
              </el-form-item>
              
              <el-divider content-position="left">周末时间</el-divider>
              <el-form-item label="周末上班" prop="weekend_start_time">
                <el-time-picker v-model="businessHours.weekend_start_time" format="HH:mm" :disabled="!canModify" />
              </el-form-item>
              <el-form-item label="周末下班" prop="weekend_end_time">
                <el-time-picker v-model="businessHours.weekend_end_time" format="HH:mm" :disabled="!canModify" />
              </el-form-item>
              
              <el-divider content-position="left">节假日设置</el-divider>
              <el-form-item label="节假日营业">
                <el-switch v-model="businessHours.holiday_open" :disabled="!canModify" />
              </el-form-item>
              <el-form-item label="节假日上班" prop="holiday_start_time">
                <el-time-picker v-model="businessHours.holiday_start_time" format="HH:mm" :disabled="!canModify" />
              </el-form-item>
              <el-form-item label="节假日下班" prop="holiday_end_time">
                <el-time-picker v-model="businessHours.holiday_end_time" format="HH:mm" :disabled="!canModify" />
              </el-form-item>
              
              <el-form-item>
                <el-button type="primary" @click="saveBusinessHours" :disabled="!canModify" :loading="businessHoursSaving">保存</el-button>
                <el-button @click="resetBusinessHours">重置</el-button>
              </el-form-item>
            </el-form>
          </div>
        </el-tab-pane>
        
        <!-- 快递公司管理 -->
        <el-tab-pane label="快递公司" name="courier_companies">
          <div class="section">
            <div class="section-header">
              <h3>📮 快递公司管理</h3>
              <el-button type="primary" @click="showCourierCompanyModal = true" :disabled="!canModify">
                <el-icon><Plus /></el-icon>
                新增快递公司
              </el-button>
            </div>
            
            <el-table :data="courierCompanies" style="width: 100%">
              <el-table-column prop="name" label="快递公司名称" />
              <el-table-column prop="code" label="编码" />
              <el-table-column prop="contact_phone" label="联系电话" />
              <el-table-column prop="website" label="官网" />
              <el-table-column prop="status" label="状态">
                <template #default="scope">
                  <el-tag :type="scope.row.status === 'enabled' ? 'success' : 'danger'">
                    {{ scope.row.status === 'enabled' ? '启用' : '禁用' }}
                  </el-tag>
                </template>
              </el-table-column>
              <el-table-column label="操作" width="200">
                <template #default="scope">
                  <el-button size="small" @click="editCourierCompany(scope.row)" :disabled="!canModify">编辑</el-button>
                  <el-button size="small" @click="toggleCourierCompanyStatus(scope.row)" :disabled="!canModify">
                    {{ scope.row.status === 'enabled' ? '禁用' : '启用' }}
                  </el-button>
                  <el-button size="small" type="danger" @click="deleteCourierCompany(scope.row)" :disabled="!canModify">删除</el-button>
                </template>
              </el-table-column>
            </el-table>
          </div>
        </el-tab-pane>
        
        <!-- 货架管理 -->
        <el-tab-pane label="货架管理" name="shelves">
          <div class="section">
            <div class="section-header">
              <h3>📊 货架管理</h3>
              <el-button type="primary" @click="showShelfModal = true" :disabled="!canModify">
                <el-icon><Plus /></el-icon>
                新增货架
              </el-button>
            </div>
            
            <el-table :data="shelves" style="width: 100%">
              <el-table-column prop="name" label="货架名称" />
              <el-table-column prop="location" label="位置" />
              <el-table-column prop="capacity" label="容量" />
              <el-table-column prop="current_usage" label="当前使用" />
              <el-table-column prop="usage_rate" label="使用率">
                <template #default="scope">
                  <el-progress :percentage="scope.row.usage_rate" :show-text="true" />
                </template>
              </el-table-column>
              <el-table-column prop="status" label="状态">
                <template #default="scope">
                  <el-tag :type="scope.row.status === 'enabled' ? 'success' : 'danger'">
                    {{ scope.row.status === 'enabled' ? '启用' : '禁用' }}
                  </el-tag>
                </template>
              </el-table-column>
              <el-table-column label="操作" width="200">
                <template #default="scope">
                  <el-button size="small" @click="editShelf(scope.row)" :disabled="!canModify">编辑</el-button>
                  <el-button size="small" @click="toggleShelfStatus(scope.row)" :disabled="!canModify">
                    {{ scope.row.status === 'enabled' ? '禁用' : '启用' }}
                  </el-button>
                  <el-button size="small" type="danger" @click="deleteShelf(scope.row)" :disabled="!canModify">删除</el-button>
                </template>
              </el-table-column>
            </el-table>
          </div>
        </el-tab-pane>
        
        <!-- 用户管理 -->
        <el-tab-pane label="用户管理" name="users">
          <div class="section">
            <div class="section-header">
              <h3>👥 用户管理</h3>
              <el-button type="primary" @click="showAddUserDialog" :disabled="!canModify">
                <el-icon><Plus /></el-icon>
                新增用户
              </el-button>
            </div>
            
            <el-table :data="users" style="width: 100%">
              <el-table-column prop="id" label="ID" width="80" />
              <el-table-column prop="username" label="用户名" />
              <el-table-column prop="phone" label="手机号" />
              <el-table-column prop="role" label="角色">
                <template #default="scope">
                  <el-tag :type="scope.row.role === 'admin' ? 'danger' : scope.row.role === 'staff' ? 'primary' : 'info'">
                    {{ scope.row.role === 'admin' ? '管理员' : scope.row.role === 'staff' ? '工作人员' : '普通用户' }}
                  </el-tag>
                </template>
              </el-table-column>
              <el-table-column prop="created_at" label="创建时间" />
              <el-table-column label="操作" width="150">
                <template #default="scope">
                  <el-button size="small" @click="editUser(scope.row)" :disabled="!canModify">编辑</el-button>
                  <el-button size="small" type="danger" @click="deleteUser(scope.row)" :disabled="!canModify">删除</el-button>
                </template>
              </el-table-column>
            </el-table>
          </div>
        </el-tab-pane>
        
        <!-- 配置变更日志 -->
        <el-tab-pane label="变更日志" name="logs">
          <div class="section">
            <div class="section-header">
              <h3>📝 配置变更日志</h3>
            </div>
            
            <el-input v-model="logSearchKey" placeholder="搜索配置项..." style="width: 300px; margin-bottom: 20px;" />
            
            <el-table :data="filteredLogs" style="width: 100%">
              <el-table-column prop="setting_label" label="配置项" />
              <el-table-column prop="old_value" label="旧值" />
              <el-table-column prop="new_value" label="新值" />
              <el-table-column prop="change_type" label="操作类型">
                <template #default="scope">
                  <el-tag :type="scope.row.change_type === 'create' ? 'success' : scope.row.change_type === 'update' ? 'primary' : 'warning'">
                    {{ scope.row.change_type === 'create' ? '新增' : scope.row.change_type === 'update' ? '修改' : '重置' }}
                  </el-tag>
                </template>
              </el-table-column>
              <el-table-column prop="changed_by" label="操作人" />
              <el-table-column prop="ip_address" label="IP地址" />
              <el-table-column prop="created_at" label="操作时间" />
            </el-table>
          </div>
        </el-tab-pane>
      </el-tabs>
    </el-card>
    
    <!-- 快递公司对话框 -->
    <el-dialog v-model="showCourierCompanyModal" :title="editingCourierCompany ? '编辑快递公司' : '新增快递公司'">
      <el-form :model="courierCompanyForm" :rules="courierCompanyRules" ref="courierCompanyForm" label-width="100px">
        <el-form-item label="名称" prop="name">
          <el-input v-model="courierCompanyForm.name" />
        </el-form-item>
        <el-form-item label="编码" prop="code">
          <el-input v-model="courierCompanyForm.code" />
        </el-form-item>
        <el-form-item label="联系电话" prop="contact_phone">
          <el-input v-model="courierCompanyForm.contact_phone" />
        </el-form-item>
        <el-form-item label="官网">
          <el-input v-model="courierCompanyForm.website" />
        </el-form-item>
        <el-form-item label="描述">
          <el-input type="textarea" v-model="courierCompanyForm.description" :rows="3" />
        </el-form-item>
      </el-form>
      <template #footer>
        <span class="dialog-footer">
          <el-button @click="closeCourierCompanyModal">取消</el-button>
          <el-button type="primary" @click="saveCourierCompany" :loading="courierCompanySaving">确定</el-button>
        </span>
      </template>
    </el-dialog>
    
    <!-- 货架对话框 -->
    <el-dialog v-model="showShelfModal" :title="editingShelf ? '编辑货架' : '新增货架'">
      <el-form :model="shelfForm" :rules="shelfRules" ref="shelfForm" label-width="100px">
        <el-form-item label="名称" prop="name">
          <el-input v-model="shelfForm.name" />
        </el-form-item>
        <el-form-item label="位置" prop="location">
          <el-input v-model="shelfForm.location" />
        </el-form-item>
        <el-form-item label="容量" prop="capacity">
          <el-input v-model.number="shelfForm.capacity" />
        </el-form-item>
        <el-form-item label="描述">
          <el-input type="textarea" v-model="shelfForm.description" :rows="3" />
        </el-form-item>
      </el-form>
      <template #footer>
        <span class="dialog-footer">
          <el-button @click="closeShelfModal">取消</el-button>
          <el-button type="primary" @click="saveShelf" :loading="shelfSaving">确定</el-button>
        </span>
      </template>
    </el-dialog>
    
    <!-- 新增用户对话框 -->
    <el-dialog v-model="addUserDialogVisible" title="新增用户">
      <el-form :model="newUser" :rules="userRules" ref="userForm" label-width="100px">
        <el-form-item label="用户名" prop="username">
          <el-input v-model="newUser.username" />
        </el-form-item>
        <el-form-item label="手机号" prop="phone">
          <el-input v-model="newUser.phone" />
        </el-form-item>
        <el-form-item label="密码" prop="password">
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
          <el-button type="primary" @click="addUser" :loading="userSaving">确定</el-button>
        </span>
      </template>
    </el-dialog>
  </div>
</template>

<script>
import { Plus } from '@element-plus/icons-vue'
import { ref, reactive, computed, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import axios from 'axios'

export default {
  name: 'Settings',
  components: { Plus },
  setup() {
    const activeTab = ref('basic')
    const canModify = ref(true)
    
    // 基础信息设置
    const basicSettings = reactive({
      site_name: '',
      site_address: '',
      contact_phone: '',
      admin_name: '',
      admin_email: '',
      service_description: ''
    })
    const basicSaving = ref(false)
    const basicRules = {
      site_name: [
        { required: true, message: '请输入站点名称', trigger: 'blur' },
        { min: 2, max: 50, message: '站点名称长度在2-50字符之间', trigger: 'blur' }
      ],
      contact_phone: [
        { pattern: /^(1[3-9]\d{9}|0\d{2,3}-\d{7,8})$/, message: '请输入正确的手机号或座机号', trigger: 'blur' }
      ],
      admin_email: [
        { type: 'email', message: '请输入正确的邮箱格式', trigger: 'blur' }
      ]
    }
    
    // 包裹规则设置
    const packageRules = reactive({
      overdue_days: 3,
      overdue_fee_per_day: 1,
      max_storage_days: 15,
      large_package_weight: 5,
      exception_days: 7,
      auto_mark_exception: true
    })
    const packageRulesSaving = ref(false)
    const packageRulesRules = {
      overdue_days: [
        { type: 'number', required: true, message: '请输入免费存放天数', trigger: 'blur' },
        { min: 1, max: 30, message: '免费存放天数必须在1-30之间', trigger: 'blur' }
      ],
      overdue_fee_per_day: [
        { type: 'number', min: 0, message: '超期日收费不能为负数', trigger: 'blur' }
      ],
      max_storage_days: [
        { type: 'number', min: 1, max: 90, message: '最大存放天数必须在1-90之间', trigger: 'blur' }
      ],
      large_package_weight: [
        { type: 'number', min: 1, message: '大件阈值必须大于0', trigger: 'blur' }
      ],
      exception_days: [
        { type: 'number', min: 1, max: 30, message: '异常标记天数必须在1-30之间', trigger: 'blur' }
      ]
    }
    
    // 通知设置
    const notificationSettings = reactive({
      sms_notification: true,
      email_notification: false,
      wechat_notification: false,
      notify_on_stored: true,
      notify_before_overdue: true,
      overdue_notify_days: 1
    })
    const notificationSaving = ref(false)
    
    // 营业时间设置
    const businessHours = reactive({
      work_start_time: '08:00',
      work_end_time: '18:00',
      break_start_time: '12:00',
      break_end_time: '13:00',
      weekend_start_time: '09:00',
      weekend_end_time: '17:00',
      holiday_open: false,
      holiday_start_time: '09:00',
      holiday_end_time: '17:00'
    })
    const businessHoursSaving = ref(false)
    const businessHoursRules = {
      work_start_time: [{ required: true, message: '请输入上班时间', trigger: 'blur' }],
      work_end_time: [{ required: true, message: '请输入下班时间', trigger: 'blur' }]
    }
    
    // 快递公司管理
    const courierCompanies = ref([])
    const showCourierCompanyModal = ref(false)
    const editingCourierCompany = ref(null)
    const courierCompanySaving = ref(false)
    const courierCompanyForm = reactive({
      name: '',
      code: '',
      contact_phone: '',
      website: '',
      description: ''
    })
    const courierCompanyRules = {
      name: [
        { required: true, message: '请输入快递公司名称', trigger: 'blur' },
        { min: 2, max: 50, message: '名称长度在2-50字符之间', trigger: 'blur' }
      ],
      code: [
        { required: true, message: '请输入编码', trigger: 'blur' },
        { min: 2, max: 20, message: '编码长度在2-20字符之间', trigger: 'blur' }
      ],
      contact_phone: [
        { pattern: /^1[3-9]\d{9}$/, message: '请输入正确的手机号', trigger: 'blur' }
      ]
    }
    
    // 货架管理
    const shelves = ref([])
    const showShelfModal = ref(false)
    const editingShelf = ref(null)
    const shelfSaving = ref(false)
    const shelfForm = reactive({
      name: '',
      location: '',
      capacity: 50,
      description: ''
    })
    const shelfRules = {
      name: [
        { required: true, message: '请输入货架名称', trigger: 'blur' },
        { min: 2, max: 50, message: '名称长度在2-50字符之间', trigger: 'blur' }
      ],
      capacity: [
        { type: 'number', required: true, message: '请输入容量', trigger: 'blur' },
        { min: 1, message: '容量必须大于0', trigger: 'blur' }
      ]
    }
    
    // 用户管理
    const users = ref([])
    const addUserDialogVisible = ref(false)
    const userSaving = ref(false)
    const newUser = reactive({
      username: '',
      phone: '',
      password: '',
      role: 'user'
    })
    const userRules = {
      username: [
        { required: true, message: '请输入用户名', trigger: 'blur' },
        { min: 2, max: 50, message: '用户名长度在2-50字符之间', trigger: 'blur' }
      ],
      phone: [
        { required: true, message: '请输入手机号', trigger: 'blur' },
        { pattern: /^1[3-9]\d{9}$/, message: '请输入正确的手机号', trigger: 'blur' }
      ],
      password: [
        { required: true, message: '请输入密码', trigger: 'blur' },
        { min: 6, message: '密码长度至少6位', trigger: 'blur' }
      ]
    }
    
    // 配置变更日志
    const settingsLogs = ref([])
    const logSearchKey = ref('')
    const filteredLogs = computed(() => {
      if (!logSearchKey.value) return settingsLogs.value
      return settingsLogs.value.filter(log => 
        log.setting_label?.toLowerCase().includes(logSearchKey.value.toLowerCase()) ||
        log.key?.toLowerCase().includes(logSearchKey.value.toLowerCase())
      )
    })
    
    // 获取token
    const getToken = () => localStorage.getItem('token')
    
    // 加载基础设置
    const loadBasicSettings = async () => {
      try {
        const response = await axios.get('/api/v1/system_settings', {
          headers: { Authorization: `Bearer ${getToken()}` }
        })
        const data = response.data.data || response.data
        Object.assign(basicSettings, {
          site_name: data.site_name || '',
          site_address: data.site_address || '',
          contact_phone: data.contact_phone || '',
          admin_name: data.admin_name || '',
          admin_email: data.admin_email || '',
          service_description: data.service_description || ''
        })
      } catch (error) {
        console.error('加载基础设置失败:', error)
      }
    }
    
    // 保存基础设置
    const saveBasicSettings = async () => {
      basicSaving.value = true
      try {
        const data = {
          site_name: basicSettings.site_name,
          site_address: basicSettings.site_address,
          contact_phone: basicSettings.contact_phone,
          admin_name: basicSettings.admin_name,
          admin_email: basicSettings.admin_email,
          service_description: basicSettings.service_description
        }
        await axios.put('/api/v1/system_settings/batch_update', { settings: data }, {
          headers: { Authorization: `Bearer ${getToken()}` }
        })
        ElMessage.success('基础信息保存成功')
      } catch (error) {
        const errMsg = error.response?.data?.message || error.message || '保存失败'
        ElMessage.error(errMsg)
      } finally {
        basicSaving.value = false
      }
    }
    
    // 重置基础设置
    const resetBasicSettings = () => {
      loadBasicSettings()
    }
    
    // 加载包裹规则
    const loadPackageRules = async () => {
      try {
        const response = await axios.get('/api/v1/system_settings', {
          headers: { Authorization: `Bearer ${getToken()}` }
        })
        const data = response.data.data || response.data
        Object.assign(packageRules, {
          overdue_days: parseInt(data.overdue_days) || 3,
          overdue_fee_per_day: parseFloat(data.overdue_fee_per_day) || 1,
          max_storage_days: parseInt(data.max_storage_days) || 15,
          large_package_weight: parseFloat(data.large_package_weight) || 5,
          exception_days: parseInt(data.exception_days) || 7,
          auto_mark_exception: (data.auto_mark_exception || 'true') === 'true'
        })
      } catch (error) {
        console.error('加载包裹规则失败:', error)
      }
    }
    
    // 保存包裹规则
    const savePackageRules = async () => {
      packageRulesSaving.value = true
      try {
        const data = {
          overdue_days: packageRules.overdue_days.toString(),
          overdue_fee_per_day: packageRules.overdue_fee_per_day.toString(),
          max_storage_days: packageRules.max_storage_days.toString(),
          large_package_weight: packageRules.large_package_weight.toString(),
          exception_days: packageRules.exception_days.toString(),
          auto_mark_exception: packageRules.auto_mark_exception.toString()
        }
        await axios.put('/api/v1/system_settings/batch_update', { settings: data }, {
          headers: { Authorization: `Bearer ${getToken()}` }
        })
        ElMessage.success('包裹规则保存成功')
      } catch (error) {
        const errMsg = error.response?.data?.message || error.message || '保存失败'
        ElMessage.error(errMsg)
      } finally {
        packageRulesSaving.value = false
      }
    }
    
    // 重置包裹规则
    const resetPackageRules = () => {
      loadPackageRules()
    }
    
    // 加载通知设置
    const loadNotificationSettings = async () => {
      try {
        const response = await axios.get('/api/v1/system_settings', {
          headers: { Authorization: `Bearer ${getToken()}` }
        })
        const data = response.data.data || response.data
        Object.assign(notificationSettings, {
          sms_notification: (data.sms_notification || 'true') === 'true',
          email_notification: (data.email_notification || 'false') === 'true',
          wechat_notification: (data.wechat_notification || 'false') === 'true',
          notify_on_stored: (data.notify_on_stored || 'true') === 'true',
          notify_before_overdue: (data.notify_before_overdue || 'true') === 'true',
          overdue_notify_days: parseInt(data.overdue_notify_days) || 1
        })
      } catch (error) {
        console.error('加载通知设置失败:', error)
      }
    }
    
    // 保存通知设置
    const saveNotificationSettings = async () => {
      notificationSaving.value = true
      try {
        const data = {
          sms_notification: notificationSettings.sms_notification.toString(),
          email_notification: notificationSettings.email_notification.toString(),
          wechat_notification: notificationSettings.wechat_notification.toString(),
          notify_on_stored: notificationSettings.notify_on_stored.toString(),
          notify_before_overdue: notificationSettings.notify_before_overdue.toString(),
          overdue_notify_days: notificationSettings.overdue_notify_days.toString()
        }
        await axios.put('/api/v1/system_settings/batch_update', { settings: data }, {
          headers: { Authorization: `Bearer ${getToken()}` }
        })
        ElMessage.success('通知设置保存成功')
      } catch (error) {
        const errMsg = error.response?.data?.message || error.message || '保存失败'
        ElMessage.error(errMsg)
      } finally {
        notificationSaving.value = false
      }
    }
    
    // 重置通知设置
    const resetNotificationSettings = () => {
      loadNotificationSettings()
    }
    
    // 加载营业时间
    const loadBusinessHours = async () => {
      try {
        const response = await axios.get('/api/v1/system_settings', {
          headers: { Authorization: `Bearer ${getToken()}` }
        })
        const data = response.data.data || response.data
        Object.assign(businessHours, {
          work_start_time: data.work_start_time || '08:00',
          work_end_time: data.work_end_time || '18:00',
          break_start_time: data.break_start_time || '12:00',
          break_end_time: data.break_end_time || '13:00',
          weekend_start_time: data.weekend_start_time || '09:00',
          weekend_end_time: data.weekend_end_time || '17:00',
          holiday_open: (data.holiday_open || 'false') === 'true',
          holiday_start_time: data.holiday_start_time || '09:00',
          holiday_end_time: data.holiday_end_time || '17:00'
        })
      } catch (error) {
        console.error('加载营业时间失败:', error)
      }
    }
    
    // 保存营业时间
    const saveBusinessHours = async () => {
      businessHoursSaving.value = true
      try {
        const data = {
          work_start_time: businessHours.work_start_time,
          work_end_time: businessHours.work_end_time,
          break_start_time: businessHours.break_start_time,
          break_end_time: businessHours.break_end_time,
          weekend_start_time: businessHours.weekend_start_time,
          weekend_end_time: businessHours.weekend_end_time,
          holiday_open: businessHours.holiday_open.toString(),
          holiday_start_time: businessHours.holiday_start_time,
          holiday_end_time: businessHours.holiday_end_time
        }
        await axios.put('/api/v1/system_settings/batch_update', { settings: data }, {
          headers: { Authorization: `Bearer ${getToken()}` }
        })
        ElMessage.success('营业时间保存成功')
      } catch (error) {
        const errMsg = error.response?.data?.message || error.message || '保存失败'
        ElMessage.error(errMsg)
      } finally {
        businessHoursSaving.value = false
      }
    }
    
    // 重置营业时间
    const resetBusinessHours = () => {
      loadBusinessHours()
    }
    
    // 加载快递公司
    const loadCourierCompanies = async () => {
      try {
        const response = await axios.get('/api/v1/courier_companies', {
          headers: { Authorization: `Bearer ${getToken()}` }
        })
        courierCompanies.value = response.data.data || response.data || []
      } catch (error) {
        console.error('加载快递公司失败:', error)
      }
    }
    
    // 打开快递公司弹窗
    const openCourierCompanyModal = () => {
      showCourierCompanyModal.value = true
      editingCourierCompany.value = null
      Object.assign(courierCompanyForm, { name: '', code: '', contact_phone: '', website: '', description: '' })
    }
    
    // 编辑快递公司
    const editCourierCompany = (company) => {
      editingCourierCompany.value = company
      Object.assign(courierCompanyForm, {
        name: company.name,
        code: company.code,
        contact_phone: company.contact_phone || '',
        website: company.website || '',
        description: company.description || ''
      })
      showCourierCompanyModal.value = true
    }
    
    // 关闭快递公司弹窗
    const closeCourierCompanyModal = () => {
      showCourierCompanyModal.value = false
      editingCourierCompany.value = null
    }
    
    // 保存快递公司
    const saveCourierCompany = async () => {
      courierCompanySaving.value = true
      try {
        const data = {
          courier_company: {
            name: courierCompanyForm.name,
            code: courierCompanyForm.code,
            contact_phone: courierCompanyForm.contact_phone,
            website: courierCompanyForm.website,
            description: courierCompanyForm.description
          }
        }
        
        if (editingCourierCompany.value) {
          await axios.put(`/api/v1/courier_companies/${editingCourierCompany.value.id}`, data, {
            headers: { Authorization: `Bearer ${getToken()}` }
          })
          ElMessage.success('快递公司更新成功')
        } else {
          await axios.post('/api/v1/courier_companies', data, {
            headers: { Authorization: `Bearer ${getToken()}` }
          })
          ElMessage.success('快递公司添加成功')
        }
        
        closeCourierCompanyModal()
        loadCourierCompanies()
      } catch (error) {
        const errMsg = error.response?.data?.message || error.message || '保存失败'
        ElMessage.error(errMsg)
      } finally {
        courierCompanySaving.value = false
      }
    }
    
    // 切换快递公司状态
    const toggleCourierCompanyStatus = async (company) => {
      try {
        await axios.put(`/api/v1/courier_companies/${company.id}/toggle_status`, {}, {
          headers: { Authorization: `Bearer ${getToken()}` }
        })
        company.status = company.status === 'enabled' ? 'disabled' : 'enabled'
        ElMessage.success(`快递公司已${company.status === 'enabled' ? '启用' : '禁用'}`)
      } catch (error) {
        const errMsg = error.response?.data?.message || error.message || '操作失败'
        ElMessage.error(errMsg)
      }
    }
    
    // 删除快递公司
    const deleteCourierCompany = async (company) => {
      if (!confirm(`确定要删除快递公司 "${company.name}" 吗？`)) return
      
      try {
        await axios.delete(`/api/v1/courier_companies/${company.id}`, {
          headers: { Authorization: `Bearer ${getToken()}` }
        })
        courierCompanies.value = courierCompanies.value.filter(c => c.id !== company.id)
        ElMessage.success('快递公司删除成功')
      } catch (error) {
        const errMsg = error.response?.data?.message || error.message || '删除失败'
        ElMessage.error(errMsg)
      }
    }
    
    // 加载货架
    const loadShelves = async () => {
      try {
        const response = await axios.get('/api/v1/shelves', {
          headers: { Authorization: `Bearer ${getToken()}` }
        })
        shelves.value = response.data.data || response.data || []
      } catch (error) {
        console.error('加载货架失败:', error)
      }
    }
    
    // 打开货架弹窗
    const openShelfModal = () => {
      showShelfModal.value = true
      editingShelf.value = null
      Object.assign(shelfForm, { name: '', location: '', capacity: 50, description: '' })
    }
    
    // 编辑货架
    const editShelf = (shelf) => {
      editingShelf.value = shelf
      Object.assign(shelfForm, {
        name: shelf.name,
        location: shelf.location || '',
        capacity: shelf.capacity,
        description: shelf.description || ''
      })
      showShelfModal.value = true
    }
    
    // 关闭货架弹窗
    const closeShelfModal = () => {
      showShelfModal.value = false
      editingShelf.value = null
    }
    
    // 保存货架
    const saveShelf = async () => {
      shelfSaving.value = true
      try {
        const data = {
          shelf: {
            name: shelfForm.name,
            location: shelfForm.location,
            capacity: shelfForm.capacity,
            description: shelfForm.description
          }
        }
        
        if (editingShelf.value) {
          await axios.put(`/api/v1/shelves/${editingShelf.value.id}`, data, {
            headers: { Authorization: `Bearer ${getToken()}` }
          })
          ElMessage.success('货架更新成功')
        } else {
          await axios.post('/api/v1/shelves', data, {
            headers: { Authorization: `Bearer ${getToken()}` }
          })
          ElMessage.success('货架添加成功')
        }
        
        closeShelfModal()
        loadShelves()
      } catch (error) {
        const errMsg = error.response?.data?.message || error.message || '保存失败'
        ElMessage.error(errMsg)
      } finally {
        shelfSaving.value = false
      }
    }
    
    // 切换货架状态
    const toggleShelfStatus = async (shelf) => {
      try {
        await axios.put(`/api/v1/shelves/${shelf.id}/toggle_status`, {}, {
          headers: { Authorization: `Bearer ${getToken()}` }
        })
        shelf.status = shelf.status === 'enabled' ? 'disabled' : 'enabled'
        ElMessage.success(`货架已${shelf.status === 'enabled' ? '启用' : '禁用'}`)
      } catch (error) {
        const errMsg = error.response?.data?.message || error.message || '操作失败'
        ElMessage.error(errMsg)
      }
    }
    
    // 删除货架
    const deleteShelf = async (shelf) => {
      if (!confirm(`确定要删除货架 "${shelf.name}" 吗？`)) return
      
      try {
        await axios.delete(`/api/v1/shelves/${shelf.id}`, {
          headers: { Authorization: `Bearer ${getToken()}` }
        })
        shelves.value = shelves.value.filter(s => s.id !== shelf.id)
        ElMessage.success('货架删除成功')
      } catch (error) {
        const errMsg = error.response?.data?.message || error.message || '删除失败'
        ElMessage.error(errMsg)
      }
    }
    
    // 加载用户列表
    const loadUsers = async () => {
      try {
        const response = await axios.get('/api/v1/users', {
          headers: { Authorization: `Bearer ${getToken()}` }
        })
        users.value = response.data.data || response.data || []
      } catch (error) {
        console.error('加载用户列表失败:', error)
      }
    }
    
    // 显示添加用户对话框
    const showAddUserDialog = () => {
      addUserDialogVisible.value = true
      Object.assign(newUser, { username: '', phone: '', password: '', role: 'user' })
    }
    
    // 添加用户
    const addUser = async () => {
      userSaving.value = true
      try {
        const data = {
          user: {
            username: newUser.username,
            phone: newUser.phone,
            password: newUser.password,
            role: newUser.role
          }
        }
        await axios.post('/api/v1/users', data, {
          headers: { Authorization: `Bearer ${getToken()}` }
        })
        addUserDialogVisible.value = false
        loadUsers()
        ElMessage.success('用户添加成功')
      } catch (error) {
        const errMsg = error.response?.data?.message || error.message || '添加失败'
        ElMessage.error(errMsg)
      } finally {
        userSaving.value = false
      }
    }
    
    // 编辑用户
    const editUser = (user) => {
      console.log('编辑用户:', user)
      ElMessage.info('编辑用户功能开发中...')
    }
    
    // 删除用户
    const deleteUser = async (user) => {
      if (!confirm(`确定要删除用户 "${user.username}" 吗？`)) return
      
      try {
        await axios.delete(`/api/v1/users/${user.id}`, {
          headers: { Authorization: `Bearer ${getToken()}` }
        })
        users.value = users.value.filter(u => u.id !== user.id)
        ElMessage.success('用户删除成功')
      } catch (error) {
        const errMsg = error.response?.data?.message || error.message || '删除失败'
        ElMessage.error(errMsg)
      }
    }
    
    // 加载配置变更日志
    const loadSettingsLogs = async () => {
      try {
        const response = await axios.get('/api/v1/system_settings/logs', {
          headers: { Authorization: `Bearer ${getToken()}` }
        })
        settingsLogs.value = response.data.data || response.data || []
      } catch (error) {
        console.error('加载配置变更日志失败:', error)
      }
    }
    
    // 检查用户权限
    const checkUserPermission = async () => {
      try {
        const response = await axios.get('/api/v1/users/current', {
          headers: { Authorization: `Bearer ${getToken()}` }
        })
        const user = response.data.data || response.data
        canModify.value = user.role === 'admin'
      } catch (error) {
        canModify.value = false
      }
    }
    
    // 切换标签页时加载对应数据
    const handleTabChange = (tab) => {
      switch (tab) {
        case 'basic':
          loadBasicSettings()
          break
        case 'package_rules':
          loadPackageRules()
          break
        case 'notification':
          loadNotificationSettings()
          break
        case 'business_hours':
          loadBusinessHours()
          break
        case 'courier_companies':
          loadCourierCompanies()
          break
        case 'shelves':
          loadShelves()
          break
        case 'users':
          loadUsers()
          break
        case 'logs':
          loadSettingsLogs()
          break
      }
    }
    
    onMounted(() => {
      checkUserPermission()
      loadBasicSettings()
    })
    
    return {
      activeTab,
      canModify,
      basicSettings,
      basicSaving,
      basicRules,
      packageRules,
      packageRulesSaving,
      packageRulesRules,
      notificationSettings,
      notificationSaving,
      businessHours,
      businessHoursSaving,
      businessHoursRules,
      courierCompanies,
      showCourierCompanyModal,
      editingCourierCompany,
      courierCompanySaving,
      courierCompanyForm,
      courierCompanyRules,
      shelves,
      showShelfModal,
      editingShelf,
      shelfSaving,
      shelfForm,
      shelfRules,
      users,
      addUserDialogVisible,
      userSaving,
      newUser,
      userRules,
      settingsLogs,
      logSearchKey,
      filteredLogs,
      saveBasicSettings,
      resetBasicSettings,
      savePackageRules,
      resetPackageRules,
      saveNotificationSettings,
      resetNotificationSettings,
      saveBusinessHours,
      resetBusinessHours,
      openCourierCompanyModal,
      editCourierCompany,
      closeCourierCompanyModal,
      saveCourierCompany,
      toggleCourierCompanyStatus,
      deleteCourierCompany,
      openShelfModal,
      editShelf,
      closeShelfModal,
      saveShelf,
      toggleShelfStatus,
      deleteShelf,
      showAddUserDialog,
      addUser,
      editUser,
      deleteUser,
      handleTabChange
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

.section-header h3 {
  margin: 0;
  font-size: 16px;
  color: #303133;
}

.dialog-footer {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
}

.section {
  padding: 20px;
}

.el-form-item {
  margin-bottom: 20px;
}

.el-divider {
  margin: 20px 0;
}
</style>
