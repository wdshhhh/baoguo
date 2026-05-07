<template>
  <div class="packages">
    <div class="packages-container">
      <div class="packages-header">
        <h2>包裹管理</h2>
      </div>
      
      <div class="search-bar">
        <van-field
          v-model="searchKeyword"
          placeholder="搜索运单号/取件码"
          left-icon="search"
          @keyup.enter="searchPackages"
        />
        <van-button type="primary" size="small" @click="searchPackages">
          搜索
        </van-button>
        <van-button type="info" size="small" @click="showAddPackage" style="margin-left: 10px;">
          <van-icon name="plus" />
          新增
        </van-button>
      </div>
      
      <div class="action-bar">
        <van-button type="primary" block @click="startScan" style="margin-bottom: 10px;">
          <van-icon name="scan" />
          扫码
        </van-button>
        <van-button type="info" block @click="startOcr" :loading="ocrLoading">
          <van-icon name="photo" />
          AI拍照识别
        </van-button>
      </div>
      
      <div class="filter-bar">
        <van-segmented-control v-model="activeFilter">
          <van-segmented-control-item value="all">全部</van-segmented-control-item>
          <van-segmented-control-item value="pending">待取件</van-segmented-control-item>
          <van-segmented-control-item value="picked">已取件</van-segmented-control-item>
          <van-segmented-control-item value="exception">异常</van-segmented-control-item>
        </van-segmented-control>
      </div>
      
      <div class="packages-list">
        <van-list
          v-model:loading="loading"
          :finished="finished"
          finished-text="没有更多包裹"
          @load="loadPackages"
        >
          <van-card
            v-for="packageItem in packages"
            :key="packageItem.id"
            :title="packageItem.tracking_number"
            :desc="`取件码: ${packageItem.pickup_code}`"
            class="package-card"
          >
            <template #footer>
              <div class="package-footer">
                <span class="package-status">
                  <van-tag :type="packageItem.status === 'pending' ? 'info' : packageItem.status === 'picked' ? 'success' : 'danger'">
                    {{ packageItem.status === 'pending' ? '待取件' : packageItem.status === 'picked' ? '已取件' : '异常' }}
                  </van-tag>
                </span>
                <span class="package-time">{{ packageItem.created_at }}</span>
              </div>
            </template>
            <template #extra>
              <van-button 
                type="primary" 
                size="small" 
                @click="handlePackage(packageItem)"
              >
                {{ packageItem.status === 'pending' ? '取件' : '详情' }}
              </van-button>
            </template>
          </van-card>
        </van-list>
      </div>
    </div>
    
    <!-- 新增包裹对话框 -->
    <van-popup v-model:show="addPackageDialog" position="bottom" round>
      <div class="add-package-dialog">
        <div class="dialog-header">
          <h3>新增包裹</h3>
          <van-icon name="cross" @click="addPackageDialog = false" />
        </div>
        
        <div class="dialog-content">
          <van-form @submit="addPackage">
            <van-field
              v-model="newPackageForm.tracking_number"
              label="运单号"
              placeholder="请输入运单号"
              required
            />
            <van-field
              v-model="newPackageForm.recipient_name"
              label="收件人"
              placeholder="请输入收件人姓名"
              required
            />
            <van-field
              v-model="newPackageForm.recipient_phone"
              label="手机号"
              placeholder="请输入手机号"
              type="tel"
              required
            />
            <van-field
              v-model="newPackageForm.storage_location"
              label="存储位置"
              placeholder="请输入存储位置"
            />
            <van-field name="package_type" label="包裹类型">
              <template #input>
                <van-radio-group v-model="newPackageForm.package_type" direction="horizontal">
                  <van-radio name="normal">普通</van-radio>
                  <van-radio name="large">大件</van-radio>
                  <van-radio name="fragile">易碎</van-radio>
                </van-radio-group>
              </template>
            </van-field>
            <van-field
              v-model="newPackageForm.weight"
              label="重量(kg)"
              placeholder="请输入重量"
              type="number"
            />
            
            <div style="margin: 16px;">
              <van-button round block type="primary" native-type="submit">
                确认新增
              </van-button>
            </div>
          </van-form>
        </div>
      </div>
    </van-popup>
  </div>
</template>

<script>
import { ref, onMounted, watch } from 'vue'
import { showDialog, showImagePreview } from 'vant'
import axios from 'axios'

export default {
  name: 'Packages',
  setup() {
    const searchKeyword = ref('')
    const activeFilter = ref('all')
    const loading = ref(false)
    const finished = ref(false)
    const packages = ref([])
    const ocrLoading = ref(false)
    const addPackageDialog = ref(false)
    const newPackageForm = ref({
      tracking_number: '',
      recipient_name: '',
      recipient_phone: '',
      storage_location: '',
      package_type: 'normal',
      weight: 0
    })
    
    const loadPackages = () => {
      // 模拟数据
      setTimeout(() => {
        const newPackages = [
          {
            id: 1,
            tracking_number: 'SF1234567890',
            pickup_code: 'A1234',
            status: 'pending',
            created_at: '2026-04-02 10:00:00'
          },
          {
            id: 2,
            tracking_number: 'YT9876543210',
            pickup_code: 'B5678',
            status: 'picked',
            created_at: '2026-04-02 09:00:00'
          },
          {
            id: 3,
            tracking_number: 'ZT1122334455',
            pickup_code: 'C9876',
            status: 'exception',
            created_at: '2026-04-02 08:00:00'
          }
        ]
        packages.value = [...packages.value, ...newPackages]
        loading.value = false
        finished.value = true
      }, 1000)
    }
    
    const searchPackages = () => {
      // 实现搜索功能
      console.log('搜索:', searchKeyword.value)
      loadPackages()
    }
    
    const handlePackage = (packageItem) => {
      // 处理包裹操作
      console.log('处理包裹:', packageItem)
    }
    
    // 扫码功能
    const startScan = () => {
      // 移动端扫码功能
      console.log('开始扫码')
    }
    
    // AI OCR识别
    const startOcr = async () => {
      try {
        ocrLoading.value = true
        
        // 检查摄像头权限
        if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
          showDialog({
            title: '提示',
            message: '您的设备不支持摄像头功能'
          })
          return
        }
        
        // 创建拍照界面
        const video = document.createElement('video')
        const canvas = document.createElement('canvas')
        const context = canvas.getContext('2d')
        
        const stream = await navigator.mediaDevices.getUserMedia({ 
          video: { facingMode: 'environment' } 
        })
        
        video.srcObject = stream
        video.play()
        
        // 显示拍照对话框
        showDialog({
          title: '拍摄快递面单',
          message: '请将快递面单对准摄像头',
          showCancelButton: true,
          confirmButtonText: '拍照',
          cancelButtonText: '取消'
        }).then(async () => {
          // 拍照
          canvas.width = video.videoWidth
          canvas.height = video.videoHeight
          context.drawImage(video, 0, 0, canvas.width, canvas.height)
          
          // 停止摄像头
          stream.getTracks().forEach(track => track.stop())
          
          // 转换为Blob
          canvas.toBlob(async (blob) => {
            await processOcrImage(blob)
          }, 'image/jpeg', 0.8)
          
        }).catch(() => {
          // 取消拍照，停止摄像头
          stream.getTracks().forEach(track => track.stop())
        })
        
      } catch (error) {
        console.error('OCR拍照失败:', error)
        showDialog({
          title: '错误',
          message: '拍照失败，请重试'
        })
      } finally {
        ocrLoading.value = false
      }
    }
    
    // 处理OCR识别
    const processOcrImage = async (imageBlob) => {
      try {
        const formData = new FormData()
        formData.append('image', imageBlob, 'ocr_capture.jpg')
        
        const response = await axios.post('/api/v1/ai/ocr_parcel_enhanced', formData, {
          headers: {
            'Content-Type': 'multipart/form-data'
          }
        })
        
        if (response.data.success) {
          const ocrData = response.data.data
          
          // 自动填充表单
          if (ocrData.tracking_number) {
            newPackageForm.value.tracking_number = ocrData.tracking_number
          }
          if (ocrData.customer_name) {
            newPackageForm.value.recipient_name = ocrData.customer_name
          }
          if (ocrData.customer_phone) {
            newPackageForm.value.recipient_phone = ocrData.customer_phone
          }
          
          // 显示识别结果
          showDialog({
            title: '识别成功',
            message: `运单号: ${ocrData.tracking_number || '未识别'}\n姓名: ${ocrData.customer_name || '未识别'}\n手机号: ${ocrData.customer_phone || '未识别'}\n置信度: ${Math.round(ocrData.confidence * 100)}%`,
            confirmButtonText: '应用结果',
            cancelButtonText: '重新识别'
          }).then(() => {
            // 打开新增包裹对话框
            showAddPackage()
          }).catch(() => {
            // 重新识别
            startOcr()
          })
          
        } else {
          showDialog({
            title: '识别失败',
            message: response.data.error || '识别失败，请重试'
          })
        }
        
      } catch (error) {
        console.error('OCR识别失败:', error)
        showDialog({
          title: '识别失败',
          message: '网络错误，请重试'
        })
      }
    }
    
    // 显示新增包裹对话框
    const showAddPackage = () => {
      addPackageDialog.value = true
    }
    
    // 新增包裹
    const addPackage = async () => {
      // 实现新增包裹逻辑
      console.log('新增包裹:', newPackageForm.value)
      addPackageDialog.value = false
    }
    
    watch(activeFilter, () => {
      // 切换筛选条件
      packages.value = []
      finished.value = false
      loadPackages()
    })
    
    onMounted(() => {
      loadPackages()
    })
    
    return {
      searchKeyword,
      activeFilter,
      loading,
      finished,
      packages,
      ocrLoading,
      addPackageDialog,
      newPackageForm,
      searchPackages,
      handlePackage,
      loadPackages,
      startScan,
      startOcr,
      showAddPackage,
      addPackage
    }
  }
}
</script>

<style scoped>
.packages {
  padding: 16px;
  background: #f5f5f5;
  min-height: 100vh;
}

.packages-container {
  background: white;
  border-radius: 8px;
  padding: 16px;
}

.packages-header {
  text-align: center;
  margin-bottom: 16px;
}

.packages-header h2 {
  margin: 0;
  color: #333;
}

.search-bar {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 16px;
}

.action-bar {
  margin-bottom: 16px;
}

.filter-bar {
  margin-bottom: 16px;
}

.packages-list {
  max-height: 60vh;
  overflow-y: auto;
}

.package-card {
  margin-bottom: 12px;
  border-radius: 8px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
}

.package-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-top: 8px;
}

.package-time {
  font-size: 12px;
  color: #999;
}

.add-package-dialog {
  padding: 20px;
}

.dialog-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
  padding-bottom: 10px;
  border-bottom: 1px solid #eee;
}

.dialog-header h3 {
  margin: 0;
  color: #333;
}

.dialog-content {
  max-height: 60vh;
  overflow-y: auto;
}
</style>
