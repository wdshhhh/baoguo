<template>
  <div class="packages">
    <el-card class="mb-4">
      <template #header>
        <div class="card-header">
          <h2>包裹管理</h2>
          <el-button type="primary" @click="showAddPackageDialog">
            <el-icon><Plus /></el-icon>
            新增包裹
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
            <el-button @click="searchPackages">
              <el-icon><Search /></el-icon>
            </el-button>
          </template>
        </el-input>
        
        <el-button type="primary" @click="startScan" style="margin-right: 10px;">
          <el-icon><Camera /></el-icon>
          扫码
        </el-button>
        
        <OcrUploader 
          @ocr-result="handleOcrResult"
          style="margin-right: 10px;"
        />
        
        <el-select v-model="statusFilter" placeholder="状态" style="width: 150px; margin-right: 10px;">
          <el-option label="全部" value="" />
          <el-option label="待入库" value="pending" />
          <el-option label="已入库" value="stored" />
          <el-option label="已取件" value="picked_up" />
          <el-option label="异常" value="exception" />
        </el-select>
        
        <el-date-picker
          v-model="dateRange"
          type="daterange"
          range-separator="至"
          start-placeholder="开始日期"
          end-placeholder="结束日期"
          style="width: 300px;"
        />
      </div>
      
      <el-table :data="packages" style="width: 100%">
        <el-table-column prop="tracking_number" label="运单号" width="180" />
        <el-table-column prop="recipient_phone" label="手机号" width="150" />
        <el-table-column prop="pickup_code" label="取件码" width="100" />
        <el-table-column prop="status" label="状态" width="100">
          <template #default="scope">
            <el-tag
              :type="scope.row.status === 'pending' ? 'info' : scope.row.status === 'picked_up' ? 'success' : 'danger'"
            >
              {{ scope.row.status_name }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="stored_at" label="入库时间" width="180" />
        <el-table-column prop="picked_up_at" label="取件时间" width="180" />
        <el-table-column label="操作" width="200" fixed="right">
          <template #default="scope">
            <el-button size="small" type="primary" @click="pickupPackage(scope.row)" v-if="scope.row.status === 'stored'">
              取件
            </el-button>
            <el-button size="small" type="warning" @click="editPackage(scope.row)">
              编辑
            </el-button>
            <el-button size="small" type="danger" @click="deletePackage(scope.row)">
              删除
            </el-button>
            <el-button size="small" type="danger" @click="markException(scope.row)" v-if="scope.row.status !== 'exception'">
              异常
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
    
    <!-- 新增包裹对话框 -->
    <el-dialog v-model="addPackageDialogVisible" title="新增包裹" width="700px">
      <div class="ocr-section" style="margin-bottom: 20px;">
        <div class="ocr-header" style="display: flex; align-items: center; margin-bottom: 10px;">
          <h4 style="margin: 0; margin-right: 10px;">OCR面单识别</h4>
          <PackageOcrUploader @ocr-result="handleOcrResult" @package-created="handlePackageCreated" />
        </div>
        
        <!-- 实时识别结果显示区域 -->
        <div v-if="ocrResult" class="ocr-result-display" style="border: 1px solid #e4e7ed; border-radius: 4px; padding: 15px; background: #f8f9fa;">
          <h5 style="margin: 0 0 10px 0; color: #409eff;">📄 OCR识别结果</h5>
          
          <div class="ocr-fields" style="display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 10px;">
            <div v-if="ocrResult.tracking_number" class="ocr-field">
              <span class="field-label">运单号:</span>
              <span class="field-value">{{ ocrResult.tracking_number }}</span>
            </div>
            <div v-if="ocrResult.recipient_name" class="ocr-field">
              <span class="field-label">收件人:</span>
              <span class="field-value">{{ ocrResult.recipient_name }}</span>
            </div>
            <div v-if="ocrResult.recipient_phone" class="ocr-field">
              <span class="field-label">手机号:</span>
              <span class="field-value">{{ ocrResult.recipient_phone }}</span>
            </div>
            <div v-if="ocrResult.courier_company" class="ocr-field">
              <span class="field-label">快递公司:</span>
              <span class="field-value">{{ ocrResult.courier_company }}</span>
            </div>
            <div v-if="ocrResult.recipient_address" class="ocr-field" style="grid-column: 1 / -1;">
              <span class="field-label">地址:</span>
              <span class="field-value">{{ ocrResult.recipient_address }}</span>
            </div>
          </div>
          
          <div v-if="ocrResult.confidence" class="ocr-confidence" style="margin-top: 10px; display: flex; align-items: center;">
            <span class="confidence-label">识别置信度:</span>
            <el-progress 
              :percentage="Math.round(ocrResult.confidence * 100)" 
              :status="ocrResult.confidence > 0.8 ? 'success' : 'warning'"
              style="flex: 1; margin: 0 10px;"
            />
            <span class="confidence-value">{{ Math.round(ocrResult.confidence * 100) }}%</span>
          </div>
          
          <div class="ocr-actions" style="margin-top: 10px; display: flex; justify-content: space-between;">
            <el-button size="small" @click="clearOcrResult">清除结果</el-button>
            <el-button size="small" type="primary" @click="applyAllOcrFields">应用全部字段</el-button>
          </div>
        </div>
        
        <el-alert
          v-if="ocrDetectedFields > 0"
          :title="`OCR识别完成！已自动填充 ${ocrDetectedFields} 个字段`"
          type="success"
          :closable="true"
          show-icon
          @close="clearOcrResult"
        />
      </div>
      
      <el-form :model="newPackage" label-width="120px" :rules="packageRules" ref="packageFormRef">
        <el-form-item label="运单号" prop="tracking_number">
          <el-input v-model="newPackage.tracking_number" placeholder="请输入运单号或使用OCR识别" />
        </el-form-item>
        <el-form-item label="收件人姓名" prop="recipient_name">
          <el-input v-model="newPackage.recipient_name" placeholder="请输入收件人姓名或使用OCR识别" />
        </el-form-item>
        <el-form-item label="收件人手机号" prop="recipient_phone">
          <el-input v-model="newPackage.recipient_phone" placeholder="请输入收件人手机号或使用OCR识别" />
        </el-form-item>
        <el-form-item label="收件人地址" prop="recipient_address">
          <el-input v-model="newPackage.recipient_address" type="textarea" placeholder="请输入收件人地址或使用OCR识别" />
        </el-form-item>
        <el-form-item label="包裹类型" prop="package_type">
          <el-select v-model="newPackage.package_type" placeholder="请选择包裹类型">
            <el-option label="普通" value="normal" />
            <el-option label="大件" value="large" />
            <el-option label="易碎" value="fragile" />
            <el-option label="贵重" value="valuable" />
          </el-select>
        </el-form-item>
        <el-form-item label="重量(kg)" prop="weight">
          <el-input-number v-model="newPackage.weight" :min="0.1" :step="0.1" />
        </el-form-item>
        <el-form-item label="存储位置" prop="storage_location">
          <el-input v-model="newPackage.storage_location" placeholder="请输入存储位置" />
        </el-form-item>
        <el-form-item label="备注" prop="remark">
          <el-input v-model="newPackage.remark" type="textarea" placeholder="请输入备注信息" />
        </el-form-item>
      </el-form>
      <template #footer>
        <span class="dialog-footer">
          <el-button @click="addPackageDialogVisible = false">取消</el-button>
          <el-button type="primary" @click="addPackage">确定</el-button>
        </span>
      </template>
    </el-dialog>
    
    <!-- 编辑包裹对话框 -->
    <el-dialog v-model="editPackageDialogVisible" title="编辑包裹" width="600px">
      <el-form :model="editingPackage" label-width="120px" :rules="packageRules" ref="editPackageFormRef">
        <el-form-item label="运单号" prop="tracking_number">
          <el-input v-model="editingPackage.tracking_number" placeholder="请输入运单号" />
        </el-form-item>
        <el-form-item label="收件人姓名" prop="recipient_name">
          <el-input v-model="editingPackage.recipient_name" placeholder="请输入收件人姓名" />
        </el-form-item>
        <el-form-item label="收件人手机号" prop="recipient_phone">
          <el-input v-model="editingPackage.recipient_phone" placeholder="请输入收件人手机号" />
        </el-form-item>
        <el-form-item label="收件人地址" prop="recipient_address">
          <el-input v-model="editingPackage.recipient_address" type="textarea" placeholder="请输入收件人地址" />
        </el-form-item>
        <el-form-item label="包裹类型" prop="package_type">
          <el-select v-model="editingPackage.package_type" placeholder="请选择包裹类型">
            <el-option label="普通" value="normal" />
            <el-option label="大件" value="large" />
            <el-option label="易碎" value="fragile" />
            <el-option label="贵重" value="valuable" />
          </el-select>
        </el-form-item>
        <el-form-item label="重量(kg)" prop="weight">
          <el-input-number v-model="editingPackage.weight" :min="0.1" :step="0.1" />
        </el-form-item>
        <el-form-item label="存储位置" prop="storage_location">
          <el-input v-model="editingPackage.storage_location" placeholder="请输入存储位置" />
        </el-form-item>
        <el-form-item label="备注" prop="remark">
          <el-input v-model="editingPackage.remark" type="textarea" placeholder="请输入备注信息" />
        </el-form-item>
      </el-form>
      <template #footer>
        <span class="dialog-footer">
          <el-button @click="editPackageDialogVisible = false">取消</el-button>
          <el-button type="primary" @click="updatePackage">确定</el-button>
        </span>
      </template>
    </el-dialog>
  </div>
</template>

<script>
import { Plus, Search, Camera } from '@element-plus/icons-vue'
import { ref, onMounted, computed } from 'vue'
import axios from 'axios'
import { ElMessage, ElMessageBox } from 'element-plus'
import OcrUploader from '../../components/OcrUploader.vue'
import PackageOcrUploader from '../../components/PackageOcrUploader.vue'

export default {
  name: 'Packages',
  components: {
    OcrUploader,
    PackageOcrUploader
  },
  setup() {
    const packages = ref([])
    const searchKeyword = ref('')
    const statusFilter = ref('')
    const dateRange = ref([])
    const currentPage = ref(1)
    const pageSize = ref(10)
    const total = ref(0)
    const addPackageDialogVisible = ref(false)
    const editPackageDialogVisible = ref(false)
    const newPackage = ref({
      tracking_number: '',
      recipient_name: '',
      recipient_phone: '',
      recipient_address: '',
      package_type: '',
      weight: 0.1,
      storage_location: '',
      remark: ''
    })
    const editingPackage = ref({})
    
    const packageFormRef = ref(null)
    const editPackageFormRef = ref(null)
    
    // OCR相关数据
    const ocrResult = ref(null)
    const ocrDetectedFields = computed(() => {
      if (!ocrResult.value) return 0
      const fields = ['tracking_number', 'recipient_name', 'recipient_phone', 'recipient_address', 'courier_company']
      return fields.filter(field => ocrResult.value[field] && ocrResult.value[field].trim()).length
    })
    
    const packageRules = {
      tracking_number: [
        { required: true, message: '请输入运单号', trigger: 'blur' }
      ],
      recipient_name: [
        { required: true, message: '请输入收件人姓名', trigger: 'blur' }
      ],
      recipient_phone: [
        { required: true, message: '请输入收件人手机号', trigger: 'blur' },
        { pattern: /^1[3-9]\d{9}$/, message: '手机号格式不正确', trigger: 'blur' }
      ],
      recipient_address: [
        { required: true, message: '请输入收件人地址', trigger: 'blur' }
      ],
      package_type: [
        { required: true, message: '请选择包裹类型', trigger: 'change' }
      ],
      weight: [
        { required: true, message: '请输入重量', trigger: 'blur' }
      ],
      storage_location: [
        { required: true, message: '请输入存储位置', trigger: 'blur' }
      ]
    }
    
    const loadPackages = async () => {
      try {
        const params = {
          page: currentPage.value,
          per_page: pageSize.value
        }
        
        if (searchKeyword.value) {
          // 智能搜索：根据输入内容判断搜索类型
          const keyword = searchKeyword.value.trim()
          
          if (/^\d{11}$/.test(keyword)) {
            // 如果是11位数字，认为是手机号
            params.recipient_phone = keyword
          } else if (/^[A-Za-z0-9]{10,20}$/.test(keyword)) {
            // 如果是字母数字组合，认为是运单号
            params.tracking_number = keyword
          } else if (/^\d{8}$/.test(keyword)) {
            // 如果是8位数字，认为是取件码
            params.pickup_code = keyword
          } else {
            // 其他情况，使用多个字段进行搜索
            params.tracking_number = keyword
            params.recipient_phone = keyword
            params.pickup_code = keyword
            params.recipient_name = keyword
          }
        }
        
        if (statusFilter.value) {
          params.status = statusFilter.value
        }
        
        if (dateRange.value && dateRange.value.length === 2) {
          params.start_date = dateRange.value[0].toISOString().split('T')[0]
          params.end_date = dateRange.value[1].toISOString().split('T')[0]
        }
        
        const response = await axios.get('/api/v1/packages', { params })
        packages.value = response.data.data
        total.value = response.data.meta.total
      } catch (error) {
        console.error('获取包裹列表失败', error)
        ElMessage.error('获取包裹列表失败')
      }
    }
    
    const searchPackages = () => {
      // 实现搜索功能
      loadPackages()
    }
    
    const handleSizeChange = (size) => {
      pageSize.value = size
      loadPackages()
    }
    
    const handleCurrentChange = (current) => {
      currentPage.value = current
      loadPackages()
    }
    
    const showAddPackageDialog = () => {
      addPackageDialogVisible.value = true
    }
    
    const addPackage = async () => {
      if (!packageFormRef.value) return
      
      try {
        await packageFormRef.value.validate()
        
        console.log('新增包裹请求数据:', newPackage.value)
        console.log('当前token:', localStorage.getItem('token'))
        
        const response = await axios.post('/api/v1/packages', newPackage.value)
        
        console.log('新增包裹响应:', response)
        
        if (response.data.data) {
          ElMessage.success('新增包裹成功')
          addPackageDialogVisible.value = false
          packageFormRef.value.resetFields()
          newPackage.value = {
            tracking_number: '',
            recipient_name: '',
            recipient_phone: '',
            recipient_address: '',
            package_type: '',
            weight: 0.1,
            storage_location: '',
            remark: ''
          }
          loadPackages()
        }
      } catch (error) {
        console.error('新增包裹失败', error)
        console.error('错误详情:', {
          message: error.message,
          response: error.response,
          request: error.request
        })
        if (error.response?.data?.error) {
          ElMessage.error(error.response.data.error)
        } else if (error.response?.status === 500) {
          ElMessage.error('服务器内部错误，请检查控制台日志')
        } else {
          ElMessage.error('新增包裹失败')
        }
      }
    }
    
    const editPackage = (packageItem) => {
      editingPackage.value = { ...packageItem }
      editPackageDialogVisible.value = true
    }
    
    const updatePackage = async () => {
      if (!editPackageFormRef.value) return
      
      try {
        await editPackageFormRef.value.validate()
        
        console.log('更新包裹请求数据:', JSON.parse(JSON.stringify(editingPackage.value)))
        
        const response = await axios.put(`/api/v1/packages/${editingPackage.value.id}`, JSON.parse(JSON.stringify(editingPackage.value)))
        
        console.log('更新包裹响应:', response)
        
        if (response.data.data) {
          ElMessage.success('更新包裹成功')
          editPackageDialogVisible.value = false
          loadPackages()
        }
      } catch (error) {
        console.error('更新包裹失败', error)
        console.error('更新错误详情:', {
          message: error.message,
          response: error.response,
          request: error.request
        })
        if (error.response?.data?.error) {
          ElMessage.error(error.response.data.error)
        } else if (error.response?.status === 500) {
          ElMessage.error('服务器内部错误，请检查控制台日志')
        } else {
          ElMessage.error('更新包裹失败')
        }
      }
    }
    
    const deletePackage = async (packageItem) => {
      try {
        await ElMessageBox.confirm('确定要删除这个包裹吗？', '确认删除', {
          confirmButtonText: '确定',
          cancelButtonText: '取消',
          type: 'warning'
        })
        
        await axios.delete(`/api/v1/packages/${packageItem.id}`)
        ElMessage.success('删除包裹成功')
        loadPackages()
      } catch (error) {
        if (error === 'cancel') {
          return
        }
        console.error('删除包裹失败', error)
        ElMessage.error('删除包裹失败')
      }
    }
    
    const pickupPackage = async (packageItem) => {
      try {
        await ElMessageBox.confirm('确定要标记为已取件吗？', '确认取件', {
          confirmButtonText: '确定',
          cancelButtonText: '取消',
          type: 'warning'
        })
        
        await axios.post(`/api/v1/packages/${packageItem.id}/pick_up`)
        ElMessage.success('取件操作成功')
        loadPackages()
      } catch (error) {
        if (error === 'cancel') {
          return
        }
        console.error('取件操作失败', error)
        if (error.response?.data?.error) {
          ElMessage.error(error.response.data.error)
        } else {
          ElMessage.error('取件操作失败')
        }
      }
    }
    
    const startScan = async () => {
      try {
        // 检查摄像头是否可用
        let hasCamera = false
        if (navigator.mediaDevices && navigator.mediaDevices.getUserMedia) {
          try {
            const devices = await navigator.mediaDevices.enumerateDevices()
            hasCamera = devices.some(device => device.kind === 'videoinput')
          } catch (error) {
            console.warn('摄像头检测失败:', error)
            hasCamera = false
          }
        }
        
        if (!hasCamera) {
          // 没有摄像头，直接显示键盘输入
          const { value } = await ElMessageBox.prompt(
            '请输入运单号或取件码：',
            '键盘输入',
            {
              confirmButtonText: '确认输入',
              cancelButtonText: '取消',
              inputType: 'text',
              inputPlaceholder: '直接输入运单号或取件码',
              inputValue: searchKeyword.value,
            }
          )
          
          if (value && value.trim()) {
            processScannedCode(value.trim(), 'manual')
          }
        } else {
          // 有摄像头，显示选择对话框
          const { value, action } = await ElMessageBox.prompt(
            '请输入运单号或取件码：',
            '扫码/输入功能',
            {
              confirmButtonText: '确认输入',
              cancelButtonText: '摄像头扫码',
              showCancelButton: true,
              inputType: 'text',
              inputPlaceholder: '直接输入运单号或取件码',
              inputValue: searchKeyword.value,
              beforeClose: (action, instance, done) => {
                if (action === 'confirm') {
                  if (instance.inputValue && instance.inputValue.trim()) {
                    processScannedCode(instance.inputValue.trim(), 'manual')
                    done()
                  } else {
                    ElMessage.error('请输入有效的运单号或取件码')
                    return false
                  }
                } else if (action === 'cancel') {
                  startCameraScan().then(done).catch(done)
                } else {
                  done()
                }
              }
            }
          )
        }
        
      } catch (error) {
        if (error !== 'cancel') {
          console.error('扫码失败:', error)
          ElMessage.error('扫码失败，请重试')
        }
      }
    }
    
    const startCameraScan = () => {
      return new Promise((resolve, reject) => {
        // 创建扫码界面
        const scanDialog = document.createElement('div')
        scanDialog.style.cssText = `
          position: fixed;
          top: 0;
          left: 0;
          width: 100%;
          height: 100%;
          background: rgba(0,0,0,0.8);
          z-index: 9999;
          display: flex;
          flex-direction: column;
          align-items: center;
          justify-content: center;
        `
        
        const scanContent = document.createElement('div')
        scanContent.style.cssText = `
          background: white;
          padding: 20px;
          border-radius: 8px;
          text-align: center;
          max-width: 500px;
          width: 90%;
        `
        
        const scanTitle = document.createElement('h3')
        scanTitle.textContent = '摄像头扫码'
        scanTitle.style.marginBottom = '20px'
        
        const scanFrame = document.createElement('div')
        scanFrame.style.cssText = `
          width: 300px;
          height: 300px;
          border: 2px solid #409EFF;
          margin: 0 auto 20px;
          position: relative;
          overflow: hidden;
        `
        
        const scanLine = document.createElement('div')
        scanLine.style.cssText = `
          position: absolute;
          top: 0;
          left: 0;
          width: 100%;
          height: 2px;
          background: #409EFF;
          animation: scan 2s linear infinite;
        `
        
        const scanHint = document.createElement('p')
        scanHint.textContent = '请将二维码/条形码对准扫描框'
        scanHint.style.marginBottom = '20px'
        
        const closeBtn = document.createElement('button')
        closeBtn.textContent = '关闭扫描'
        closeBtn.style.cssText = `
          padding: 10px 20px;
          background: #dc3545;
          color: white;
          border: none;
          border-radius: 4px;
          cursor: pointer;
        `
        
        // 添加CSS动画
        const style = document.createElement('style')
        style.textContent = `
          @keyframes scan {
            0% { top: 0; }
            50% { top: 100%; }
            100% { top: 0; }
          }
        `
        
        scanFrame.appendChild(scanLine)
        scanContent.appendChild(scanTitle)
        scanContent.appendChild(scanFrame)
        scanContent.appendChild(scanHint)
        scanContent.appendChild(closeBtn)
        scanDialog.appendChild(scanContent)
        document.head.appendChild(style)
        document.body.appendChild(scanDialog)
        
        // 启动摄像头
        const video = document.createElement('video')
        video.style.cssText = `
          width: 100%;
          height: 100%;
          object-fit: cover;
        `
        
        const canvas = document.createElement('canvas')
        const ctx = canvas.getContext('2d')
        
        let stream = null
        
        const startCamera = async () => {
          try {
            stream = await navigator.mediaDevices.getUserMedia({ 
              video: { width: 640, height: 480 } 
            })
            video.srcObject = stream
            video.play()
            scanFrame.appendChild(video)
            
            // 开始扫码检测
            scanForQRCode()
            
          } catch (error) {
            console.error('摄像头启动失败:', error)
            ElMessage.error('摄像头启动失败')
            closeScanner()
            reject(error)
          }
        }
        
        const scanForQRCode = () => {
          if (!stream) return
          
          canvas.width = video.videoWidth
          canvas.height = video.videoHeight
          
          const scanInterval = setInterval(() => {
            ctx.drawImage(video, 0, 0, canvas.width, canvas.height)
            const imageData = ctx.getImageData(0, 0, canvas.width, canvas.height)
            
            // 简单的二维码检测逻辑
            const detectedCode = detectSimpleQRCode(imageData)
            
            if (detectedCode) {
              clearInterval(scanInterval)
              processScannedCode(detectedCode, 'qr')
              closeScanner()
              resolve(detectedCode)
            }
          }, 100)
          
          closeBtn.onclick = () => {
            clearInterval(scanInterval)
            closeScanner()
            reject(new Error('用户取消扫描'))
          }
        }
        
        const closeScanner = () => {
          if (stream) {
            stream.getTracks().forEach(track => track.stop())
          }
          if (scanDialog.parentNode) {
            scanDialog.parentNode.removeChild(scanDialog)
          }
          if (style.parentNode) {
            style.parentNode.removeChild(style)
          }
        }
        
        startCamera()
      })
    }
    
    const detectSimpleQRCode = (imageData) => {
      // 简化的二维码检测逻辑
      // 实际项目中应使用专业的二维码识别库
      
      // 这里返回模拟数据，实际项目中应集成专业库
      const mockCodes = ['SF1234567890', 'YT9876543210', '04060001', '04060002']
      const randomCode = mockCodes[Math.floor(Math.random() * mockCodes.length)]
      
      // 模拟检测成功概率
      if (Math.random() > 0.7) {
        return randomCode
      }
      
      return null
    }
    
    const processScannedCode = async (code, source) => {
      try {
        ElMessage.success(`扫描成功: ${code}`)
        
        // 根据扫描的代码类型执行不同操作
        if (/^\d{8}$/.test(code)) {
          // 取件码 - 执行取件操作
          await processPickupCode(code)
        } else {
          // 运单号 - 查询包裹信息并自动填充搜索
          searchKeyword.value = code
          await searchPackages()
        }
        
      } catch (error) {
        console.error('处理扫描代码失败:', error)
        ElMessage.error('处理失败，请重试')
      }
    }

    // 处理OCR识别结果
    const handleOcrResult = (ocrData) => {
      try {
        console.log('接收到OCR识别结果:', ocrData)
        
        // 检查OCR数据是否有效
        if (!ocrData) {
          console.error('OCR数据为空')
          ElMessage.error('OCR识别结果为空，请重试')
          return
        }
        
        // 检查是否有识别到的字段
        const hasValidData = ocrData.tracking_number || ocrData.recipient_name || ocrData.recipient_phone || ocrData.courier_company
        
        if (!hasValidData) {
          console.warn('OCR识别结果中没有有效字段:', ocrData)
          ElMessage.warning('OCR识别完成，但未检测到有效信息，请手动输入')
        }
        
        // 保存OCR结果
        ocrResult.value = ocrData
        
        console.log('OCR识别结果已保存:', ocrResult.value)
        
        // 智能填充包裹表单
        smartFillPackageForm(ocrData)
        
        // 如果不在新增包裹对话框，自动打开
        if (!addPackageDialogVisible.value) {
          showAddPackageDialog()
        }
        
        ElMessage.success(`OCR识别完成！已自动填充 ${ocrDetectedFields.value} 个字段`)
        
      } catch (error) {
        console.error('处理OCR结果失败:', error)
        ElMessage.error('处理OCR结果失败')
      }
    }
    
    // 智能填充包裹表单
    const smartFillPackageForm = (ocrData) => {
      // 1. 运单号处理
      if (ocrData.tracking_number) {
        newPackage.value.tracking_number = ocrData.tracking_number
        
        // 根据运单号自动识别快递公司
        const courier = detectCourierByTrackingNumber(ocrData.tracking_number)
        if (courier) {
          newPackage.value.courier_company = courier
        }
      }
      
      // 2. 收件人信息处理
      if (ocrData.recipient_name) {
        newPackage.value.recipient_name = ocrData.recipient_name
      }
      
      if (ocrData.recipient_phone) {
        // 手机号格式标准化
        const formattedPhone = formatPhoneNumber(ocrData.recipient_phone)
        newPackage.value.recipient_phone = formattedPhone
      }
      
      // 3. 地址信息智能处理
      if (ocrData.recipient_address) {
        const addressInfo = parseAddress(ocrData.recipient_address)
        newPackage.value.recipient_address = addressInfo.formattedAddress
        
        // 根据地址信息智能设置存储位置
        if (addressInfo.area) {
          newPackage.value.storage_location = addressInfo.area
        }
      }
      
      // 4. 快递公司信息
      if (ocrData.courier_company) {
        newPackage.value.courier_company = ocrData.courier_company
      }
      
      // 5. 包裹类型智能识别
      const packageType = detectPackageType(ocrData)
      if (packageType) {
        newPackage.value.package_type = packageType
      }
      
      // 6. 重量估算（如果有相关信息）
      const estimatedWeight = estimateWeight(ocrData)
      if (estimatedWeight) {
        newPackage.value.weight = estimatedWeight
      }
      
      // 7. 备注信息（包含原始OCR文本和识别置信度）
      if (ocrData.raw_text) {
        const confidence = ocrData.confidence || '未知'
        newPackage.value.remark = `OCR识别结果（置信度: ${confidence}）: ${ocrData.raw_text.substring(0, 200)}...`
      }
    }
    
    // 根据运单号识别快递公司
    const detectCourierByTrackingNumber = (trackingNumber) => {
      const courierPatterns = {
        '顺丰': /^SF\d{10,12}$/i,
        '圆通': /^YT\d{10,12}$/i,
        '申通': /^STO\d{10,12}$/i,
        '韵达': /^YD\d{10,12}$/i,
        '中通': /^ZTO\d{10,12}$/i,
        'EMS': /^E\d{10,12}$/i,
        '京东': /^JD\d{10,12}$/i,
        '德邦': /^DBL\d{10,12}$/i,
        '百世': /^HTKY\d{10,12}$/i
      }
      
      for (const [courier, pattern] of Object.entries(courierPatterns)) {
        if (pattern.test(trackingNumber)) {
          return courier
        }
      }
      
      return null
    }
    
    // 手机号格式标准化
    const formatPhoneNumber = (phone) => {
      // 移除所有非数字字符
      const cleaned = phone.replace(/\D/g, '')
      
      // 如果是11位数字，直接返回
      if (/^1[3-9]\d{9}$/.test(cleaned)) {
        return cleaned
      }
      
      // 如果是其他格式，尝试标准化
      return cleaned
    }
    
    // 地址信息智能解析
    const parseAddress = (address) => {
      const result = {
        formattedAddress: address,
        area: null
      }
      
      // 简单的地址解析逻辑
      const areaPatterns = [
        /(\S+区)/,
        /(\S+街道)/,
        /(\S+路)/,
        /(\S+小区)/,
        /(\S+大厦)/
      ]
      
      for (const pattern of areaPatterns) {
        const match = address.match(pattern)
        if (match) {
          result.area = match[1]
          break
        }
      }
      
      return result
    }
    
    // 包裹类型智能识别
    const detectPackageType = (ocrData) => {
      const text = (ocrData.raw_text || '').toLowerCase()
      
      // 根据关键词识别包裹类型
      if (text.includes('易碎') || text.includes('玻璃') || text.includes('陶瓷')) {
        return 'fragile'
      } else if (text.includes('大件') || text.includes('重型') || text.includes('体积大')) {
        return 'large'
      } else if (text.includes('贵重') || text.includes('珠宝') || text.includes('电子')) {
        return 'valuable'
      } else if (text.includes('文件') || text.includes('文档') || text.includes('信件')) {
        return 'document'
      }
      
      return 'normal'
    }
    
    // 重量估算
    const estimateWeight = (ocrData) => {
      const text = (ocrData.raw_text || '').toLowerCase()
      
      // 根据关键词估算重量
      if (text.includes('大件') || text.includes('重型')) {
        return 5.0
      } else if (text.includes('文件') || text.includes('文档')) {
        return 0.5
      } else if (text.includes('小件') || text.includes('轻量')) {
        return 1.0
      }
      
      // 默认重量
      return 1.5
    }
    
    // 清空OCR结果
    const clearOcrResult = () => {
      ocrResult.value = null
    }
    
    // 应用全部OCR字段到表单
    const applyAllOcrFields = () => {
      if (!ocrResult.value) return
      
      try {
        // 强制应用所有OCR字段，覆盖现有表单内容
        if (ocrResult.value.tracking_number) {
          newPackage.value.tracking_number = ocrResult.value.tracking_number
        }
        
        if (ocrResult.value.recipient_name) {
          newPackage.value.recipient_name = ocrResult.value.recipient_name
        }
        
        if (ocrResult.value.recipient_phone) {
          // 手机号格式标准化
          const formattedPhone = ocrResult.value.recipient_phone.replace(/[^\d]/g, '')
          newPackage.value.recipient_phone = formattedPhone
        }
        
        if (ocrResult.value.courier_company) {
          newPackage.value.courier_company = ocrResult.value.courier_company
        }
        
        if (ocrResult.value.recipient_address) {
          newPackage.value.recipient_address = ocrResult.value.recipient_address
        }
        
        // 添加备注信息
        if (ocrResult.value.raw_text) {
          const confidence = ocrResult.value.confidence || '未知'
          newPackage.value.remark = `OCR识别结果（置信度: ${confidence}）: ${ocrResult.value.raw_text.substring(0, 200)}...`
        }
        
        ElMessage.success('已应用全部OCR识别字段到表单')
        
      } catch (error) {
        console.error('应用OCR字段失败:', error)
        ElMessage.error('应用OCR字段失败')
      }
    }
    
    // 处理一键创建包裹成功事件
    const handlePackageCreated = (packageData) => {
      console.log('包裹创建成功:', packageData)
      
      // 关闭新增包裹对话框
      addPackageDialogVisible.value = false
      
      // 清空表单
      if (packageFormRef.value) {
        packageFormRef.value.resetFields()
      }
      
      // 清空OCR结果
      clearOcrResult()
      
      // 刷新包裹列表
      loadPackages()
      
      ElMessage.success(`包裹创建成功！运单号: ${packageData.tracking_number}`)
    }
    
    const processPickupCode = async (pickupCode) => {
      try {
        const response = await axios.get(`/api/v1/packages/search_by_code?code=${pickupCode}`)
        
        if (response.data.data) {
          const packageInfo = response.data.data
          
          // 显示包裹信息并询问是否取件
          const confirm = await ElMessageBox.confirm(
            `包裹信息：\\n收件人：${packageInfo.recipient_name}\\n手机号：${packageInfo.recipient_phone}\\n状态：${packageInfo.status_name}\\n\\n是否确认取件？`,
            '确认取件',
            {
              confirmButtonText: '确认取件',
              cancelButtonText: '取消',
              type: 'warning'
            }
          )
          
          if (confirm) {
            await axios.post(`/api/v1/packages/${packageInfo.id}/pick_up`)
            ElMessage.success('取件成功')
            loadPackages() // 刷新列表
          }
        } else {
          ElMessage.error('未找到对应的包裹')
        }
        
      } catch (error) {
        console.error('取件操作失败:', error)
        if (error.response?.status === 404) {
          ElMessage.error('未找到对应的包裹')
        } else {
          ElMessage.error('取件操作失败')
        }
      }
    }
    
    const markException = async (packageItem) => {
      try {
        const { value: formValues } = await ElMessageBox.prompt('请输入异常描述', '标记异常', {
          confirmButtonText: '确定',
          cancelButtonText: '取消',
          inputType: 'textarea',
          inputPlaceholder: '请输入异常描述'
        })
        
        await axios.post(`/api/v1/packages/${packageItem.id}/mark_exception`, {
          exception_type: 'other',
          description: formValues
        })
        ElMessage.success('标记异常成功')
        loadPackages()
      } catch (error) {
        if (error === 'cancel') {
          return
        }
        console.error('标记异常失败', error)
        if (error.response?.data?.error) {
          ElMessage.error(error.response.data.error)
        } else {
          ElMessage.error('标记异常失败')
        }
      }
    }
    
    onMounted(() => {
      loadPackages()
    })
    
    return {
      packages,
      searchKeyword,
      statusFilter,
      dateRange,
      currentPage,
      pageSize,
      total,
      addPackageDialogVisible,
      editPackageDialogVisible,
      newPackage,
      editingPackage,
      packageFormRef,
      editPackageFormRef,
      packageRules,
      ocrDetectedFields,
      searchPackages,
      handleSizeChange,
      handleCurrentChange,
      showAddPackageDialog,
      addPackage,
      editPackage,
      updatePackage,
      deletePackage,
      pickupPackage,
      markException,
      startScan,
      handleOcrResult,
      clearOcrResult,
      applyAllOcrFields,
      handlePackageCreated
    }
  }
}
</script>

<style scoped>
.packages {
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

.dialog-footer {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
}
</style>
