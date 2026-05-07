<template>
  <div class="customer-query">
    <div class="query-container">
      <div class="query-header">
        <h2>包裹查询</h2>
        <p>请输入手机号查询您的包裹</p>
      </div>
      
      <div class="query-form">
        <van-field
          v-model="phoneNumber"
          label="手机号"
          placeholder="请输入您的手机号"
          type="tel"
          maxlength="11"
          clearable
        />
        
        <van-button 
          type="primary" 
          block 
          @click="queryPackages"
          :loading="loading"
          style="margin-top: 20px;"
        >
          查询包裹
        </van-button>
      </div>
      
      <div v-if="packages.length > 0" class="packages-list">
        <h3>您的包裹 ({{ packages.length }})</h3>
        
        <van-list
          v-model:loading="listLoading"
          :finished="listFinished"
          finished-text="没有更多包裹"
        >
          <van-cell-group>
            <van-cell
              v-for="pkg in packages"
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
      
      <div v-else-if="searched" class="no-data">
        <van-empty description="未找到相关包裹" />
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
import { showToast, showConfirmDialog, showDialog } from 'vant'
import axios from 'axios'

export default {
  name: 'CustomerQuery',
  setup() {
    const phoneNumber = ref('')
    const packages = ref([])
    const loading = ref(false)
    const listLoading = ref(false)
    const listFinished = ref(false)
    const searched = ref(false)
    const detailDialogVisible = ref(false)
    const pickupDialogVisible = ref(false)
    const selectedPackage = ref(null)
    const pickupCode = ref('')
    
    const validatePhone = (phone) => {
      return /^1[3-9]\d{9}$/.test(phone)
    }
    
    const queryPackages = async () => {
      if (!phoneNumber.value.trim()) {
        showToast('请输入手机号')
        return
      }
      
      if (!validatePhone(phoneNumber.value)) {
        showToast('请输入正确的手机号格式')
        return
      }
      
      loading.value = true
      
      try {
        const response = await axios.get(`/api/v1/packages?recipient_phone=${phoneNumber.value}`)
        
        if (response.data.data && response.data.data.length > 0) {
          packages.value = response.data.data
          showToast(`找到 ${packages.value.length} 个包裹`)
        } else {
          packages.value = []
          showToast('未找到相关包裹')
        }
        
        searched.value = true
        
      } catch (error) {
        console.error('查询包裹失败:', error)
        showToast('查询失败，请重试')
      } finally {
        loading.value = false
      }
    }
    
    const showPackageDetail = (pkg) => {
      selectedPackage.value = pkg
      detailDialogVisible.value = true
    }
    
    const confirmPickup = () => {
      if (selectedPackage.value.status === 'picked_up') {
        showToast('该包裹已取件')
        return
      }
      
      pickupCode.value = ''
      pickupDialogVisible.value = true
    }
    
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
        
        // 刷新列表
        await queryPackages()
        
        pickupDialogVisible.value = false
        detailDialogVisible.value = false
        
      } catch (error) {
        console.error('取件失败:', error)
        showToast('取件失败，请重试')
      }
    }
    
    const getStatusType = (status) => {
      const types = {
        pending: 'primary',
        stored: 'success',
        picked_up: 'warning',
        exception: 'danger'
      }
      return types[status] || 'default'
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
    
    return {
      phoneNumber,
      packages,
      loading,
      listLoading,
      listFinished,
      searched,
      detailDialogVisible,
      pickupDialogVisible,
      selectedPackage,
      pickupCode,
      queryPackages,
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
.customer-query {
  padding: 0;
}

.query-container {
  min-height: 100vh;
  padding: 20px;
}

.query-header {
  text-align: center;
  margin-bottom: 30px;
}

.query-header h2 {
  margin-bottom: 10px;
  color: #333;
}

.query-header p {
  color: #666;
  font-size: 14px;
}

.packages-list {
  margin-top: 30px;
}

.packages-list h3 {
  margin-bottom: 15px;
  color: #333;
}

.package-detail {
  padding: 10px 0;
}

.no-data {
  margin-top: 50px;
}
</style>