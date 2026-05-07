<template>
  <div class="enhanced-ocr-uploader">
    <!-- 上传区域 -->
    <div class="upload-area" @click="triggerUpload" :class="{ 'drag-over': dragOver }">
      <div class="upload-content">
        <el-icon class="upload-icon"><Camera /></el-icon>
        <p class="upload-text">点击或拖拽上传快递面单图片</p>
        <p class="upload-hint">支持 JPG、PNG 格式，建议尺寸大于 300x300 像素</p>
      </div>
      
      <!-- 隐藏的文件输入 -->
      <input
        ref="fileInput"
        type="file"
        accept="image/*"
        style="display: none"
        @change="handleFileChange"
        multiple
      />
    </div>

    <!-- 批量上传进度 -->
    <div v-if="batchUploads.length > 0" class="batch-progress">
      <h4>批量识别进度</h4>
      <div class="progress-list">
        <div v-for="(upload, index) in batchUploads" :key="index" class="progress-item">
          <div class="file-info">
            <span class="file-name">{{ upload.file.name }}</span>
            <span class="file-size">{{ formatFileSize(upload.file.size) }}</span>
          </div>
          <div class="progress-bar">
            <el-progress 
              :percentage="upload.progress" 
              :status="getProgressStatus(upload)"
              :show-text="false"
            />
          </div>
          <div class="status-info">
            <span :class="['status', getStatusClass(upload.status)]">
              {{ getStatusText(upload.status) }}
            </span>
            <span v-if="upload.result" class="confidence">
              置信度: {{ (upload.result.confidence * 100).toFixed(1) }}%
            </span>
          </div>
        </div>
      </div>
    </div>

    <!-- 识别模式选择 -->
    <div class="recognition-mode">
      <h4>识别模式</h4>
      <el-radio-group v-model="recognitionMode" size="small">
        <el-radio-button value="auto">自动模式</el-radio-button>
        <el-radio-button value="ai">AI优先</el-radio-button>
        <el-radio-button value="hybrid">混合模式</el-radio-button>
        <el-radio-button value="traditional">传统OCR</el-radio-button>
      </el-radio-group>
      
      <el-checkbox v-model="enableImageValidation" size="small">
        启用图像质量验证
      </el-checkbox>
    </div>

    <!-- 识别结果对话框 -->
    <el-dialog
      v-model="dialogVisible"
      :title="dialogTitle"
      width="800px"
      :before-close="handleDialogClose"
    >
      <div class="ocr-dialog-content">
        <!-- 图片预览和操作 -->
        <div class="preview-section">
          <div class="image-preview">
            <img :src="currentImage.preview" :alt="currentImage.name" class="preview-image" />
            <div class="image-overlay">
              <el-button-group>
                <el-button @click="rotateImage(-90)" size="small">
                  <el-icon><RefreshLeft /></el-icon>
                </el-button>
                <el-button @click="rotateImage(90)" size="small">
                  <el-icon><RefreshRight /></el-icon>
                </el-button>
                <el-button @click="zoomIn" size="small">
                  <el-icon><ZoomIn /></el-icon>
                </el-button>
                <el-button @click="zoomOut" size="small">
                  <el-icon><ZoomOut /></el-icon>
                </el-button>
              </el-button-group>
            </div>
          </div>
          
          <div class="image-info">
            <p><strong>文件名:</strong> {{ currentImage.name }}</p>
            <p><strong>尺寸:</strong> {{ currentImage.width }} × {{ currentImage.height }} 像素</p>
            <p><strong>大小:</strong> {{ formatFileSize(currentImage.size) }}</p>
            <p><strong>质量评分:</strong> {{ currentImage.qualityScore }}/10</p>
          </div>
        </div>

        <!-- 识别结果 -->
        <div class="result-section">
          <h4>识别结果</h4>
          
          <!-- 质量验证结果 -->
          <div v-if="imageValidationResult" class="validation-result">
            <el-alert
              :title="imageValidationResult.valid ? '图像质量合格' : '图像质量不合格'"
              :type="imageValidationResult.valid ? 'success' : 'error'"
              :closable="false"
            />
            <div v-if="imageValidationResult.errors.length > 0" class="validation-errors">
              <p><strong>问题:</strong></p>
              <ul>
                <li v-for="error in imageValidationResult.errors" :key="error">{{ error }}</li>
              </ul>
            </div>
          </div>

          <!-- 识别结果表单 -->
          <el-form :model="ocrResult" label-width="100px" class="result-form">
            <el-form-item label="运单号">
              <el-input 
                v-model="ocrResult.tracking_number" 
                placeholder="识别出的运单号"
                :class="{ 'low-confidence': ocrResult.confidence < 0.8 }"
              />
              <span class="confidence-badge" :class="getConfidenceClass(ocrResult.confidence)">
                {{ (ocrResult.confidence * 100).toFixed(1) }}%
              </span>
            </el-form-item>
            
            <el-form-item label="收件人姓名">
              <el-input v-model="ocrResult.customer_name" placeholder="识别出的收件人姓名" />
            </el-form-item>
            
            <el-form-item label="手机号">
              <el-input v-model="ocrResult.customer_phone" placeholder="识别出的手机号" />
            </el-form-item>
            
            <el-form-item label="快递公司">
              <el-input v-model="ocrResult.courier_company" placeholder="识别出的快递公司" />
            </el-form-item>
            
            <el-form-item label="收件地址">
              <el-input 
                type="textarea" 
                v-model="ocrResult.recipient_address" 
                placeholder="识别出的收件地址"
                :rows="3"
              />
            </el-form-item>
            
            <!-- 识别详情 -->
            <el-collapse v-if="ocrResult.details" class="recognition-details">
              <el-collapse-item title="识别详情">
                <p><strong>识别模式:</strong> {{ ocrResult.details.mode }}</p>
                <p><strong>处理时间:</strong> {{ ocrResult.details.processing_time }}ms</p>
                <p><strong>原始文本:</strong></p>
                <pre class="raw-text">{{ ocrResult.details.raw_text }}</pre>
              </el-collapse-item>
            </el-collapse>
          </el-form>
        </div>
      </div>
      
      <template #footer>
        <el-button @click="handleDialogClose">取消</el-button>
        <el-button @click="reupload">重新识别</el-button>
        <el-button type="primary" @click="confirmResult" :loading="saving">
          确认并创建包裹
        </el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script>
import { ref, reactive, computed } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { 
  Camera, RefreshLeft, RefreshRight, ZoomIn, ZoomOut 
} from '@element-plus/icons-vue'

export default {
  name: 'EnhancedOcrUploader',
  components: {
    Camera, RefreshLeft, RefreshRight, ZoomIn, ZoomOut
  },
  emits: ['ocr-success'],
  setup(props, { emit }) {
    // 响应式数据
    const fileInput = ref(null)
    const dialogVisible = ref(false)
    const recognitionMode = ref('auto')
    const enableImageValidation = ref(true)
    const dragOver = ref(false)
    const saving = ref(false)
    
    // 当前处理的图片
    const currentImage = reactive({
      file: null,
      preview: '',
      name: '',
      size: 0,
      width: 0,
      height: 0,
      qualityScore: 0,
      rotation: 0,
      scale: 1
    })
    
    // OCR识别结果
    const ocrResult = reactive({
      tracking_number: '',
      customer_name: '',
      customer_phone: '',
      courier_company: '',
      recipient_address: '',
      confidence: 0,
      details: null
    })
    
    // 图像验证结果
    const imageValidationResult = ref(null)
    
    // 批量上传队列
    const batchUploads = ref([])

    // 计算属性
    const dialogTitle = computed(() => {
      return `面单识别 - ${currentImage.name}`
    })

    // 方法
    const triggerUpload = () => {
      fileInput.value.click()
    }

    const handleFileChange = (event) => {
      const files = Array.from(event.target.files)
      if (files.length === 0) return

      if (files.length === 1) {
        // 单文件处理
        processSingleFile(files[0])
      } else {
        // 批量处理
        processBatchFiles(files)
      }
      
      // 清空输入框
      event.target.value = ''
    }

    const processSingleFile = async (file) => {
      if (!validateFileType(file)) return
      
      try {
        // 读取图片信息
        const imageInfo = await loadImageInfo(file)
        Object.assign(currentImage, imageInfo)
        
        // 图像质量验证
        if (enableImageValidation.value) {
          await validateImageQuality(file)
        }
        
        // 显示对话框
        dialogVisible.value = true
        
        // 自动开始识别
        await recognize()
        
      } catch (error) {
        ElMessage.error(`文件处理失败: ${error.message}`)
      }
    }

    const processBatchFiles = async (files) => {
      // 过滤有效文件
      const validFiles = files.filter(validateFileType)
      
      if (validFiles.length === 0) {
        ElMessage.warning('没有有效的图片文件')
        return
      }

      // 添加到批量处理队列
      batchUploads.value = validFiles.map(file => ({
        file,
        progress: 0,
        status: 'pending',
        result: null
      }))

      // 开始批量处理
      processBatchQueue()
    }

    const processBatchQueue = async () => {
      for (let i = 0; i < batchUploads.value.length; i++) {
        const upload = batchUploads.value[i]
        upload.status = 'processing'
        
        try {
          // 模拟处理进度
          for (let progress = 0; progress <= 100; progress += 10) {
            upload.progress = progress
            await new Promise(resolve => setTimeout(resolve, 100))
          }
          
          // 执行OCR识别
          const result = await performOcrRecognition(upload.file)
          upload.result = result
          upload.status = result.success ? 'success' : 'error'
          
        } catch (error) {
          upload.status = 'error'
          upload.result = { success: false, error: error.message }
        }
      }
      
      // 批量处理完成
      ElMessage.success(`批量识别完成: ${batchUploads.value.filter(u => u.status === 'success').length} 成功`)
    }

    const validateFileType = (file) => {
      const validTypes = ['image/jpeg', 'image/png', 'image/webp']
      if (!validTypes.includes(file.type)) {
        ElMessage.error('只支持 JPG、PNG、WEBP 格式的图片')
        return false
      }
      
      if (file.size > 10 * 1024 * 1024) { // 10MB
        ElMessage.error('图片大小不能超过 10MB')
        return false
      }
      
      return true
    }

    const loadImageInfo = (file) => {
      return new Promise((resolve, reject) => {
        const reader = new FileReader()
        const img = new Image()
        
        reader.onload = (e) => {
          img.onload = () => {
            resolve({
              file,
              preview: e.target.result,
              name: file.name,
              size: file.size,
              width: img.width,
              height: img.height,
              qualityScore: calculateQualityScore(img)
            })
          }
          img.onerror = reject
          img.src = e.target.result
        }
        reader.onerror = reject
        reader.readAsDataURL(file)
      })
    }

    const validateImageQuality = async (file) => {
      // 模拟图像质量验证
      imageValidationResult.value = {
        valid: Math.random() > 0.3, // 70%通过率
        errors: Math.random() > 0.7 ? ['图像模糊', '亮度不足'] : [],
        metrics: {
          sharpness: Math.random().toFixed(2),
          brightness: Math.random().toFixed(2),
          contrast: Math.random().toFixed(2)
        }
      }
    }

    const recognize = async () => {
      try {
        ElMessage.info('开始识别面单信息...')
        
        const result = await performOcrRecognition(currentImage.file)
        
        if (result.success) {
          Object.assign(ocrResult, result.data)
          ElMessage.success('面单识别成功')
        } else {
          ElMessage.error(`识别失败: ${result.error}`)
        }
        
      } catch (error) {
        ElMessage.error(`识别过程出错: ${error.message}`)
      }
    }

    const performOcrRecognition = async (file) => {
      // 模拟API调用
      return new Promise((resolve) => {
        setTimeout(() => {
          const mockData = {
            tracking_number: 'SF' + Math.random().toString().slice(2, 12),
            customer_name: ['张三', '李四', '王五'][Math.floor(Math.random() * 3)],
            customer_phone: '138' + Math.random().toString().slice(2, 11),
            courier_company: ['顺丰', '圆通', '中通'][Math.floor(Math.random() * 3)],
            recipient_address: '阜新市某区某街道某小区',
            confidence: Math.random() * 0.3 + 0.7, // 0.7-1.0
            details: {
              mode: recognitionMode.value,
              processing_time: Math.floor(Math.random() * 1000) + 500,
              raw_text: '模拟识别出的原始文本内容...'
            }
          }
          
          resolve({
            success: true,
            data: mockData
          })
        }, 2000)
      })
    }

    const confirmResult = async () => {
      if (!ocrResult.tracking_number || !ocrResult.customer_name || !ocrResult.customer_phone) {
        ElMessage.warning('请完善必填信息')
        return
      }

      saving.value = true
      
      try {
        // 模拟保存操作
        await new Promise(resolve => setTimeout(resolve, 1000))
        
        emit('ocr-success', {
          ...ocrResult,
          image: currentImage.preview
        })
        
        ElMessage.success('包裹创建成功')
        dialogVisible.value = false
        resetForm()
        
      } catch (error) {
        ElMessage.error('保存失败: ' + error.message)
      } finally {
        saving.value = false
      }
    }

    const reupload = () => {
      resetForm()
      triggerUpload()
    }

    const handleDialogClose = () => {
      dialogVisible.value = false
      resetForm()
    }

    const resetForm = () => {
      Object.assign(ocrResult, {
        tracking_number: '',
        customer_name: '',
        customer_phone: '',
        courier_company: '',
        recipient_address: '',
        confidence: 0,
        details: null
      })
      imageValidationResult.value = null
    }

    // 辅助方法
    const calculateQualityScore = (img) => {
      // 简化质量评分算法
      const aspectRatio = img.width / img.height
      const sizeScore = Math.min(img.width * img.height / (300 * 300), 10)
      return Math.min(sizeScore, 10).toFixed(1)
    }

    const formatFileSize = (bytes) => {
      if (bytes === 0) return '0 Bytes'
      const k = 1024
      const sizes = ['Bytes', 'KB', 'MB', 'GB']
      const i = Math.floor(Math.log(bytes) / Math.log(k))
      return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
    }

    const getProgressStatus = (upload) => {
      switch (upload.status) {
        case 'success': return 'success'
        case 'error': return 'exception'
        default: return null
      }
    }

    const getStatusClass = (status) => {
      const classes = {
        pending: 'pending',
        processing: 'processing',
        success: 'success',
        error: 'error'
      }
      return classes[status] || 'pending'
    }

    const getStatusText = (status) => {
      const texts = {
        pending: '等待中',
        processing: '处理中',
        success: '成功',
        error: '失败'
      }
      return texts[status] || '未知'
    }

    const getConfidenceClass = (confidence) => {
      if (confidence >= 0.9) return 'high'
      if (confidence >= 0.7) return 'medium'
      return 'low'
    }

    // 图像操作
    const rotateImage = (degrees) => {
      currentImage.rotation += degrees
    }

    const zoomIn = () => {
      currentImage.scale = Math.min(currentImage.scale + 0.1, 3)
    }

    const zoomOut = () => {
      currentImage.scale = Math.max(currentImage.scale - 0.1, 0.5)
    }

    return {
      fileInput,
      dialogVisible,
      recognitionMode,
      enableImageValidation,
      dragOver,
      saving,
      currentImage,
      ocrResult,
      imageValidationResult,
      batchUploads,
      dialogTitle,
      triggerUpload,
      handleFileChange,
      recognize,
      confirmResult,
      reupload,
      handleDialogClose,
      rotateImage,
      zoomIn,
      zoomOut,
      formatFileSize,
      getProgressStatus,
      getStatusClass,
      getStatusText,
      getConfidenceClass
    }
  }
}
</script>

<style scoped>
.enhanced-ocr-uploader {
  max-width: 800px;
  margin: 0 auto;
}

.upload-area {
  border: 2px dashed #dcdfe6;
  border-radius: 8px;
  padding: 40px 20px;
  text-align: center;
  cursor: pointer;
  transition: all 0.3s;
  background: #fafafa;
}

.upload-area:hover,
.upload-area.drag-over {
  border-color: #409eff;
  background: #f0f9ff;
}

.upload-icon {
  font-size: 48px;
  color: #909399;
  margin-bottom: 16px;
}

.upload-text {
  font-size: 16px;
  color: #606266;
  margin-bottom: 8px;
}

.upload-hint {
  font-size: 14px;
  color: #909399;
}

.batch-progress {
  margin-top: 20px;
}

.progress-item {
  display: flex;
  align-items: center;
  margin-bottom: 10px;
  padding: 10px;
  background: #f5f7fa;
  border-radius: 4px;
}

.file-info {
  flex: 1;
  min-width: 200px;
}

.file-name {
  display: block;
  font-weight: 500;
}

.file-size {
  font-size: 12px;
  color: #909399;
}

.progress-bar {
  flex: 2;
  margin: 0 20px;
}

.status-info {
  min-width: 120px;
  text-align: right;
}

.status {
  padding: 2px 8px;
  border-radius: 4px;
  font-size: 12px;
}

.status.pending { background: #f4f4f5; color: #909399; }
.status.processing { background: #f0f9ff; color: #409eff; }
.status.success { background: #f0f9ff; color: #67c23a; }
.status.error { background: #fef0f0; color: #f56c6c; }

.confidence {
  font-size: 12px;
  color: #909399;
}

.recognition-mode {
  margin-top: 20px;
  padding: 16px;
  background: #f5f7fa;
  border-radius: 4px;
}

.recognition-mode h4 {
  margin: 0 0 12px 0;
  color: #303133;
}

.ocr-dialog-content {
  max-height: 60vh;
  overflow-y: auto;
}

.preview-section {
  display: flex;
  gap: 20px;
  margin-bottom: 20px;
}

.image-preview {
  position: relative;
  flex: 1;
  max-width: 300px;
}

.preview-image {
  width: 100%;
  height: auto;
  border-radius: 4px;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.1);
}

.image-overlay {
  position: absolute;
  top: 10px;
  right: 10px;
}

.image-info {
  flex: 1;
  font-size: 14px;
}

.image-info p {
  margin: 8px 0;
}

.result-section h4 {
  margin: 0 0 16px 0;
  color: #303133;
}

.validation-result {
  margin-bottom: 16px;
}

.validation-errors {
  margin-top: 8px;
  padding: 8px 12px;
  background: #fef0f0;
  border-radius: 4px;
}

.validation-errors ul {
  margin: 4px 0;
  padding-left: 20px;
}

.result-form {
  margin-top: 16px;
}

.confidence-badge {
  margin-left: 8px;
  padding: 2px 6px;
  border-radius: 4px;
  font-size: 12px;
  font-weight: 500;
}

.confidence-badge.high { background: #f0f9ff; color: #409eff; }
.confidence-badge.medium { background: #fdf6ec; color: #e6a23c; }
.confidence-badge.low { background: #fef0f0; color: #f56c6c; }

.low-confidence {
  border-color: #f56c6c !important;
}

.recognition-details {
  margin-top: 16px;
}

.raw-text {
  background: #f5f7fa;
  padding: 8px;
  border-radius: 4px;
  font-size: 12px;
  white-space: pre-wrap;
  max-height: 100px;
  overflow-y: auto;
}
</style>