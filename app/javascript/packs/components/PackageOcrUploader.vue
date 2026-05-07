<template>
  <div class="package-ocr-uploader">
    <!-- 上传按钮 -->
    <el-button 
      type="primary" 
      :loading="uploading" 
      @click="triggerUpload"
      size="small"
      class="ocr-button"
    >
      <el-icon><Camera /></el-icon>
      {{ buttonText }}
    </el-button>
    
    <!-- 隐藏的文件输入 -->
    <input
      ref="fileInput"
      type="file"
      accept="image/*"
      style="display: none"
      @change="handleFileChange"
    />
    
    <!-- 识别状态提示 -->
    <el-alert
      v-if="recognizing"
      title="正在识别面单信息，请稍候..."
      type="info"
      :closable="false"
      show-icon
      style="margin-top: 10px;"
    />
    
    <!-- 识别结果提示 -->
    <el-alert
      v-if="ocrResult && !recognizing"
      :title="`识别完成！已自动填充 ${detectedFieldsCount} 个字段`"
      type="success"
      :closable="true"
      show-icon
      @close="clearResult"
      style="margin-top: 10px;"
    />
    
    <!-- 错误信息 -->
    <el-alert
      v-if="errorMessage"
      :title="errorMessage"
      type="error"
      :closable="true"
      show-icon
      @close="clearError"
      style="margin-top: 10px;"
    />
  </div>
</template>

<script>
import { ElMessage } from 'element-plus'
import axios from 'axios'

export default {
  name: 'PackageOcrUploader',
  emits: ['ocr-result'],
  data() {
    return {
      uploading: false,
      recognizing: false,
      previewImage: null,
      ocrResult: null,
      errorMessage: '',
      buttonText: 'OCR识别面单'
    }
  },
  computed: {
    detectedFieldsCount() {
      if (!this.ocrResult) return 0
      const fields = ['tracking_number', 'recipient_name', 'recipient_phone', 'recipient_address', 'courier_company']
      return fields.filter(field => this.ocrResult[field] && this.ocrResult[field].trim()).length
    }
  },
  methods: {
    // 触发文件选择
    triggerUpload() {
      this.$refs.fileInput.click()
    },
    
    // 处理文件选择
    async handleFileChange(event) {
      const file = event.target.files[0]
      if (!file) return
      
      // 验证文件类型和大小
      if (!this.validateFile(file)) {
        return
      }
      
      this.uploading = true
      this.buttonText = '上传中...'
      
      try {
        // 创建预览
        this.previewImage = URL.createObjectURL(file)
        
        // 调用OCR识别
        await this.performOcrRecognition(file)
        
      } catch (error) {
        console.error('OCR识别失败:', error)
        this.errorMessage = 'OCR识别失败，请重试或手动输入'
      } finally {
        this.uploading = false
        this.buttonText = 'OCR识别面单'
        // 清空文件输入
        event.target.value = ''
      }
    },
    
    // 验证文件
    validateFile(file) {
      const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif']
      const maxSize = 10 * 1024 * 1024 // 10MB
      
      if (!allowedTypes.includes(file.type)) {
        this.errorMessage = '请上传 JPG、PNG 格式的图片'
        return false
      }
      
      if (file.size > maxSize) {
        this.errorMessage = '图片大小不能超过 10MB'
        return false
      }
      
      return true
    },
    
    // 执行OCR识别
    async performOcrRecognition(file) {
      this.recognizing = true
      this.errorMessage = ''
      
      try {
        const formData = new FormData()
        formData.append('image', file)
        
        console.log('开始OCR API调用...')
        
        const response = await axios.post('/api/v1/ai/ocr_parcel_public', formData, {
          headers: {
            'Content-Type': 'multipart/form-data'
          },
          timeout: 30000 // 30秒超时
        })
        
        console.log('OCR API响应:', response.data)
        
        if (response.data && response.data.success) {
          this.ocrResult = response.data.data
          console.log('OCR识别成功，结果:', this.ocrResult)
          this.emitResult()
          ElMessage.success(`识别完成！检测到 ${this.detectedFieldsCount} 个字段`)
        } else {
          console.error('OCR API返回失败:', response.data)
          throw new Error(response.data?.error || '识别失败')
        }
        
      } catch (error) {
        console.error('OCR API调用失败:', error)
        console.error('错误详情:', {
          message: error.message,
          response: error.response?.data,
          status: error.response?.status,
          statusText: error.response?.statusText
        })
        
        // 检查是否是网络错误或超时
        if (error.code === 'ECONNABORTED') {
          this.errorMessage = 'OCR识别超时，请重试'
        } else if (error.response?.status === 413) {
          this.errorMessage = '图片文件过大，请压缩后重试'
        } else if (error.response?.status === 415) {
          this.errorMessage = '不支持的图片格式'
        } else if (error.response?.status === 401) {
          this.errorMessage = '认证失败，请重新登录'
        } else if (error.response?.status === 500) {
          this.errorMessage = '服务器内部错误，请联系管理员'
        } else if (error.message === '识别失败') {
          // 如果后端返回"识别失败"，但实际识别成功，说明是数据格式问题
          this.errorMessage = '识别结果处理异常，请重试'
        } else {
          this.errorMessage = 'OCR识别失败，请检查网络连接或重试'
        }
        
        // 不抛出错误，避免影响后续处理
        // throw error
      } finally {
        this.recognizing = false
      }
    },
    
    // 发送识别结果
    emitResult() {
      if (this.ocrResult) {
        this.$emit('ocr-result', this.ocrResult)
      }
    },
    
    // 清空结果
    clearResult() {
      this.ocrResult = null
      this.previewImage = null
      this.emitResult() // 发送空结果
    },
    
    // 清空错误
    clearError() {
      this.errorMessage = ''
    }
  },
  
  beforeUnmount() {
    // 清理预览URL
    if (this.previewImage) {
      URL.revokeObjectURL(this.previewImage)
    }
  }
}
</script>

<style scoped>
.package-ocr-uploader {
  display: inline-block;
}

.ocr-button {
  margin-right: 10px;
}

.image-preview {
  text-align: center;
  margin-bottom: 15px;
}

.preview-image {
  max-width: 100%;
  max-height: 300px;
  border: 1px solid #ddd;
  border-radius: 4px;
}

.preview-actions {
  margin-top: 10px;
}

.ocr-result {
  margin-top: 15px;
}

.result-form {
  margin-top: 15px;
}

.confidence-text {
  margin-left: 10px;
  font-size: 12px;
  color: #666;
}

.raw-text {
  margin-top: 15px;
  padding: 10px;
  background-color: #f5f5f5;
  border-radius: 4px;
}

.text-content {
  font-family: monospace;
  font-size: 12px;
  white-space: pre-wrap;
  margin: 0;
}

.error-message {
  margin-top: 15px;
}

.retry-options {
  margin-top: 10px;
}

.retry-buttons {
  margin-top: 10px;
}

.retry-buttons .el-button {
  margin-right: 10px;
}
</style>