<template>
  <div class="customer-self-service">
    <div class="service-container">
      <!-- 头部 -->
      <div class="service-header">
        <h1>{{ stationInfo.name }}</h1>
        <p>{{ stationInfo.address }}</p>
        <p class="contact-info">联系电话: {{ stationInfo.phone }}</p>
      </div>
      
      <!-- 功能导航 -->
      <div class="service-nav">
        <van-grid :column-num="2" :border="false">
          <van-grid-item 
            icon="search" 
            text="包裹查询"
            @click="activeTab = 'query'"
            :class="{ active: activeTab === 'query' }"
          />
          <van-grid-item 
            icon="user-o" 
            text="客户注册"
            @click="activeTab = 'register'"
            :class="{ active: activeTab === 'register' }"
          />
        </van-grid>
      </div>
      
      <!-- 包裹查询 -->
      <div v-if="activeTab === 'query'" class="query-section">
        <div class="section-title">
          <h3>包裹查询</h3>
          <p>请输入手机号查询您的包裹</p>
        </div>
        
        <van-form @submit="queryPackages">
          <van-field
            v-model="queryForm.phone"
            name="phone"
            label="手机号"
            placeholder="请输入您的手机号"
            :rules="[{ required: true, message: '请输入手机号' }]"
            type="tel"
            maxlength="11"
            clearable
          />
          
          <van-button 
            type="primary" 
            block 
            native-type="submit"
            :loading="queryLoading"
            style="margin-top: 20px;"
          >
            查询包裹
          </van-button>
        </van-form>
        
        <!-- 查询结果 -->
        <div v-if="queryResult.length > 0" class="query-result">
          <h4>查询结果 ({{ queryResult.length }})</h4>
          
          <van-list
            v-model:loading="listLoading"
            :finished="listFinished"
            finished-text="没有更多包裹"
          >
            <van-cell-group>
              <van-cell
                v-for="pkg in queryResult"
                :key="pkg.id"
                :title="`运单号: ${pkg.tracking_number}`"
                :value="pkg.status_name"
                :label="`收件人: ${pkg.recipient_name} | 入库时间: ${formatDate(pkg.stored_at)}`"
                @click="showPackageDetail(pkg)"
              >
                <template #extra>
                  <van-tag 
                    :type="getStatusType(pkg.status)"
                    size="small"
                  >
                    {{ pkg.status_name }}
                  </van-tag>
                </template>
              </van-cell>
            </van-cell-group>
          </van-list>
        </div>
        
        <div v-else-if="querySearched" class="no-data">
          <van-empty description="未找到相关包裹" />
        </div>
      </div>
      
      <!-- 客户注册 -->
      <div v-else-if="activeTab === 'register'" class="register-section">
        <div class="section-title">
          <h3>客户注册</h3>
          <p>注册账号后可以更方便地管理您的包裹</p>
        </div>
        
        <van-form @submit="registerCustomer">
          <van-field
            v-model="registerForm.name"
            name="name"
            label="姓名"
            placeholder="请输入您的姓名"
            :rules="[{ required: true, message: '请输入姓名' }]"
            clearable
          />
          
          <van-field
            v-model="registerForm.phone"
            name="phone"
            label="手机号"
            placeholder="请输入手机号"
            :rules="[
              { required: true, message: '请输入手机号' },
              { pattern: /^1[3-9]\\d{9}$/, message: '手机号格式不正确' }
            ]"
            type="tel"
            maxlength="11"
            clearable
          />
          
          <van-field
            v-model="registerForm.password"
            name="password"
            label="密码"
            placeholder="请设置密码（至少6位）"
            :rules="[
              { required: true, message: '请输入密码' },
              { min: 6, message: '密码至少6位' }
            ]"
            type="password"
            clearable
          />
          
          <van-field
            v-model="registerForm.passwordConfirmation"
            name="passwordConfirmation"
            label="确认密码"
            placeholder="请再次输入密码"
            :rules="[
              { required: true, message: '请确认密码' },
              { validator: validatePassword, message: '两次密码不一致' }
            ]"
            type="password"
            clearable
          />
          
          <van-button 
            type="primary" 
            block 
            native-type="submit"
            :loading="registerLoading"
            style="margin-top: 20px;"
          >
            注册账号
          </van-button>
        </van-form>
      </div>
      
      <!-- 服务说明 -->
      <div class="service-info">
        <van-collapse v-model="activeNames">
          <van-collapse-item title="服务说明" name="1">
            <div class="service-description">
              <p><strong>包裹查询：</strong>输入手机号即可查询您的包裹信息</p>
              <p><strong>客户注册：</strong>注册账号后可以更方便地管理包裹</p>
              <p><strong>取件流程：</strong>查询到包裹后，凭取件码到前台取件</p>
              <p><strong>营业时间：</strong>{{ stationInfo.businessHours }}</p>
            </div>
          </van-collapse-item>
        </van-collapse>
      </div>
    </div>
    
    <!-- 包裹详情对话框 -->
    <van-dialog 
      v-model:show="detailDialogVisible" 
      title="包裹详情"
      show-cancel-button
      confirm-button-text="确认取件"
      cancel-button-text="关闭"
      @confirm="confirmPickup"
    >
      <div v-if="selectedPackage" class="package-detail">
        <van-cell-group>
          <van-cell title="运单号" :value="selectedPackage.tracking_number" />
          <van-cell title="收件人" :value="selectedPackage.recipient_name" />
          <van-cell title="手机号" :value="selectedPackage.recipient_phone" />
          <van-cell title="取件码" :value="selectedPackage.pickup_code" />
          <van-cell title="状态" :value="selectedPackage.status_name" />
          <van-cell title="入库时间" :value="formatDate(selectedPackage.stored_at)" />
          <van-cell title="取件时间" :value="formatDate(selectedPackage.picked_up_at)" />
          <van-cell title="存储位置" :value="selectedPackage.storage_location" />
        </van-cell-group>
      </div>
    </van-dialog>
    
    <!-- 取件验证对话框 -->
    <van-dialog 
      v-model:show="pickupDialogVisible" 
      title="取件验证"
      show-cancel-button
      confirm-button-text="确认"
      cancel-button-text="取消"
      @confirm="submitPickupCode"
    >
      <van-field
        v-model="pickupCode"
        label="取件码"
        placeholder="请输入取件码"
        maxlength="8"
        clearable
      />
    </van-dialog>
  </div>
</template>

<script>
import { ref } from 'vue'
import { showToast, showConfirmDialog } from 'vant'
import axios from 'axios'

export default {
  name: 'CustomerSelfService',
  setup() {
    // 驿站信息
    const stationInfo = ref({
      name: '易站快递驿站',
      address: 'XX市XX区XX街道XX号',
      phone: '400-123-4567',
      businessHours: '08:00-20:00'
    })
    
    // 状态管理
    const activeTab = ref('query')
    const activeNames = ref(['1'])
    
    // 查询相关
    const queryForm = ref({
      phone: ''
    })
    const queryResult = ref([])
    const queryLoading = ref(false)
    const querySearched = ref(false)
    const listLoading = ref(false)
    const listFinished = ref(false)
    
    // 注册相关
    const registerForm = ref({
      name: '',
      phone: '',
      password: '',
      passwordConfirmation: ''
    })
    const registerLoading = ref(false)
    
    // 对话框相关
    const detailDialogVisible = ref(false)
    const pickupDialogVisible = ref(false)
    const selectedPackage = ref(null)
    const pickupCode = ref('')
    
    // 密码验证
    const validatePassword = (val) => {
      return val === registerForm.value.password
    }
    
    // 包裹查询
    const queryPackages = async () => {
      if (!queryForm.value.phone.trim()) {
        showToast('请输入手机号')
        return
      }
      
      if (!/^1[3-9]\d{9}$/.test(queryForm.value.phone)) {
        showToast('请输入正确的手机号格式')
        return
      }
      
      queryLoading.value = true
      
      try {
        const response = await axios.get(`/api/v1/packages?recipient_phone=${queryForm.value.phone}`)
        
        if (response.data.data && response.data.data.length > 0) {
          queryResult.value = response.data.data
          showToast(`找到 ${queryResult.value.length} 个包裹`)
        } else {
          queryResult.value = []
          showToast('未找到相关包裹')
        }
        
        querySearched.value = true
        
      } catch (error) {
        console.error('查询包裹失败:', error)
        showToast('查询失败，请重试')
      } finally {
        queryLoading.value = false
      }
    }
    
    // 客户注册
    const registerCustomer = async () => {
      if (registerForm.value.password !== registerForm.value.passwordConfirmation) {
        showToast('两次密码输入不一致')
        return
      }
      
      registerLoading.value = true
      
      try {
        const response = await axios.post('/api/v1/register', registerForm.value)
        
        showToast('注册成功！请使用手机号和密码登录')
        
        // 清空表单
        registerForm.value = {
          name: '',
          phone: '',
          password: '',
          passwordConfirmation: ''
        }
        
        // 切换到查询页面
        activeTab.value = 'query'
        
      } catch (error) {
        console.error('注册失败:', error)
        if (error.response?.data?.errors) {
          showToast(error.response.data.errors.join('、'))
        } else {
          showToast('注册失败，请重试')
        }
      } finally {
        registerLoading.value = false
      }
    }
    
    // 显示包裹详情
    const showPackageDetail = (pkg) => {
      selectedPackage.value = pkg
      detailDialogVisible.value = true
    }
    
    // 确认取件
    const confirmPickup = () => {
      if (selectedPackage.value.status === 'picked_up') {
        showToast('该包裹已取件')
        return
      }
      
      pickupCode.value = ''
      pickupDialogVisible.value = true
    }
    
    // 提交取件码
    const submitPickupCode = async () => {
      if (!pickupCode.value.trim()) {
        showToast('请输入取件码')
        return
      }
      
      if (pickupCode.value !== selectedPackage.value.pickup_code) {
        showToast('取件码不正确')
        return
      }
      
      try {
        await axios.post(`/api/v1/packages/${selectedPackage.value.id}/pick_up`)
        
        showToast('取件成功')
        
        // 更新包裹状态
        selectedPackage.value.status = 'picked_up'
        selectedPackage.value.status_name = '已取件'
        selectedPackage.value.picked_up_at = new Date().toISOString()
        
        // 刷新查询结果
        await queryPackages()
        
        pickupDialogVisible.value = false
        detailDialogVisible.value = false
        
      } catch (error) {
        console.error('取件失败:', error)
        showToast('取件失败，请重试')
      }
    }
    
    // 获取状态类型
    const getStatusType = (status) => {
      const types = {
        pending: 'primary',
        stored: 'success',
        picked_up: 'warning',
        exception: 'danger'
      }
      return types[status] || 'default'
    }
    
    // 格式化日期
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
    
    return {
      stationInfo,
      activeTab,
      activeNames,
      queryForm,
      queryResult,
      queryLoading,
      querySearched,
      registerForm,
      registerLoading,
      detailDialogVisible,
      pickupDialogVisible,
      selectedPackage,
      pickupCode,
      validatePassword,
      queryPackages,
      registerCustomer,
      showPackageDetail,
      confirmPickup,
      submitPickupCode,
      getStatusType,
      formatDate
    }
  }
}
</script>

<style scoped>
.customer-self-service {
  min-height: 100vh;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  padding: 20px;
}

.service-container {
  background: white;
  border-radius: 15px;
  padding: 20px;
  box-shadow: 0 10px 30px rgba(0,0,0,0.1);
}

.service-header {
  text-align: center;
  margin-bottom: 30px;
  padding-bottom: 20px;
  border-bottom: 1px solid #f0f0f0;
}

.service-header h1 {
  color: #333;
  margin-bottom: 10px;
  font-size: 24px;
}

.service-header p {
  color: #666;
  margin: 5px 0;
}

.contact-info {
  color: #409EFF !important;
  font-weight: bold;
}

.service-nav {
  margin-bottom: 30px;
}

.service-nav :deep(.van-grid-item) {
  transition: all 0.3s;
}

.service-nav :deep(.van-grid-item.active) {
  background: #f5f7fa;
  border-radius: 8px;
}

.section-title {
  margin-bottom: 20px;
}

.section-title h3 {
  color: #333;
  margin-bottom: 5px;
}

.section-title p {
  color: #666;
  font-size: 14px;
}

.query-result {
  margin-top: 20px;
}

.query-result h4 {
  color: #333;
  margin-bottom: 15px;
}

.no-data {
  margin-top: 50px;
}

.service-info {
  margin-top: 30px;
}

.service-description p {
  margin-bottom: 10px;
  line-height: 1.6;
}

.package-detail {
  padding: 10px 0;
}
</style>