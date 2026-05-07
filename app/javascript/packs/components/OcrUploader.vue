<template>
  <div class="ocr-uploader">
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
    
    <!-- 预览和结果对话框 -->
    <el-dialog
      v-model="dialogVisible"
      :title="dialogTitle"
      width="600px"
      :before-close="handleDialogClose"
    >
      <div class="ocr-dialog-content">
        <!-- 图片预览 -->
        <div v-if="previewImage" class="image-preview">
          <img :src="previewImage" alt="快递面单" class="preview-image" />
          <div class="preview-actions">
            <el-button @click="reupload" size="small">重新上传</el-button>
            <el-button type="primary" @click="recognize" :loading="recognizing" size="small">
              识别面单
            </el-button>
          </div>
        </div>
        
        <!-- 识别结果 -->
        <div v-if="ocrResult" class="ocr-result">
          <h4>识别结果</h4>
          <el-alert
            v-if="ocrResult.confidence < 0.8"
            title="识别置信度较低，请手动核对"
            type="warning"
            :closable="false"
            show-icon
          />
          
          <el-form label-width="100px" class="result-form">
            <el-form-item label="运单号">
              <el-input 
                v-model="ocrResult.tracking_number" 
                placeholder="识别出的运单号"
                @input="emitResult"
              />
            </el-form-item>
            <el-form-item label="收件人姓名">
              <el-input 
                v-model="ocrResult.recipient_name" 
                placeholder="识别出的收件人姓名"
                @input="emitResult"
              />
            </el-form-item>
            <el-form-item label="手机号">
              <el-input 
                v-model="ocrResult.recipient_phone" 
                placeholder="识别出的手机号"
                @input="emitResult"
              />
            </el-form-item>
            <el-form-item label="快递公司">
              <el-input 
                v-model="ocrResult.courier_company" 
                placeholder="识别出的快递公司"
                @input="emitResult"
              />
            </el-form-item>
            <el-form-item label="收件地址">
              <el-input 
                v-model="ocrResult.recipient_address" 
                placeholder="识别出的收件地址"
                type="textarea"
                :rows="2"
                @input="emitResult"
              />
            </el-form-item>
            <el-form-item label="置信度">
              <el-progress 
                :percentage="Math.round(ocrResult.confidence * 100)" 
                :status="ocrResult.confidence > 0.8 ? 'success' : 'warning'"
              />
              <span class="confidence-text">{{ Math.round(ocrResult.confidence * 100) }}%</span>
            </el-form-item>
          </el-form>
          
          <div class="raw-text" v-if="ocrResult.raw_text">
            <h5>原始识别文本：</h5>
            <p class="text-content">{{ ocrResult.raw_text }}</p>
          </div>
          
          <!-- 新增包裹操作 -->
          <div class="package-actions" v-if="ocrResult.tracking_number || ocrResult.recipient_phone">
            <h5>包裹操作：</h5>
            <div class="action-buttons">
              <el-button type="primary" @click="createPackage" :loading="creatingPackage">
                <el-icon><Plus /></el-icon>
                新增包裹
              </el-button>
              <el-button type="success" @click="fillForm" :disabled="!ocrResult.tracking_number">
                <el-icon><Edit /></el-icon>
                填充表单
              </el-button>
            </div>
          </div>
        </div>
        
        <!-- 错误信息 -->
        <div v-if="errorMessage && !ocrResult" class="error-message">
          <el-alert :title="errorMessage" type="error" :closable="false" show-icon />
          
          <!-- AI重试选项 -->
          <div class="retry-options" v-if="showRetryOptions">
            <h5>识别失败，请选择：</h5>
            <div class="retry-buttons">
              <el-button type="primary" @click="retryWithOCR" :loading="retrying">
                <el-icon><Refresh /></el-icon>
                重新识别
              </el-button>
              <el-button @click="manualInput" type="warning">
                <el-icon><Edit /></el-icon>
                手动输入信息
              </el-button>
              <el-button @click="reupload" type="info">
                <el-icon><Refresh /></el-icon>
                重新上传图片
              </el-button>
            </div>
          </div>
        </div>
      </div>
      
      <template #footer>
        <el-button @click="handleDialogClose">取消</el-button>
        <el-button 
          type="primary" 
          @click="applyResult" 
          :disabled="!ocrResult || !ocrResult.tracking_number"
        >
          应用结果
        </el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script>
import { ref, computed, nextTick } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import axios from 'axios'
import { Camera, Refresh, Edit, Plus } from '@element-plus/icons-vue'

export default {
  name: 'OcrUploader',
  props: {
    buttonText: {
      type: String,
      default: 'AI拍照识别'
    },
    // 是否在移动端使用
    isMobile: {
      type: Boolean,
      default: false
    }
  },
  emits: ['ocr-result'],
  setup(props, { emit }) {
    const fileInput = ref(null)
    const dialogVisible = ref(false)
    const uploading = ref(false)
    const recognizing = ref(false)
    const retrying = ref(false)
    const creatingPackage = ref(false)
    const previewImage = ref('')
    const ocrResult = ref(null)
    const errorMessage = ref('')
    const currentFile = ref(null)
    const lastError = ref('')

    const dialogTitle = ref('快递面单识别')
    
    // 计算是否显示重试选项
    const showRetryOptions = computed(() => {
      return errorMessage.value && !recognizing.value && !retrying.value
    })

    // 新增包裹
    const createPackage = async () => {
      if (!ocrResult.value) return

      creatingPackage.value = true
      try {
        // 调用后端API创建包裹
         const response = await axios.post('/api/v1/packages', {
           package: {
             tracking_number: ocrResult.value.tracking_number,
             recipient_name: ocrResult.value.recipient_name || '待填写',
             recipient_phone: ocrResult.value.recipient_phone,
             courier_company: ocrResult.value.courier_company,
             recipient_address: ocrResult.value.recipient_address || '待填写'
           }
         })

        if (response.data.success) {
          ElMessage.success('包裹创建成功')
          // 关闭对话框
          dialogVisible.value = false
          // 清空数据
          setTimeout(() => {
            previewImage.value = ''
            ocrResult.value = null
            errorMessage.value = ''
            currentFile.value = null
          }, 300)
        } else {
          ElMessage.error(response.data.error || '包裹创建失败')
        }
      } catch (error) {
        console.error('创建包裹失败:', error)
        ElMessage.error('网络错误，创建包裹失败')
      } finally {
        creatingPackage.value = false
      }
    }

    // 填充表单
    const fillForm = () => {
      if (ocrResult.value) {
        emit('ocr-result', ocrResult.value)
        ElMessage.success('已填充表单数据')
      }
    }

    // 触发文件选择
    const triggerUpload = () => {
      if (props.isMobile && navigator.mediaDevices) {
        // 移动端使用摄像头
        openCamera()
      } else {
        // PC端使用文件选择
        fileInput.value.click()
      }
    }

    // 打开摄像头（移动端）
    const openCamera = () => {
      if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
        ElMessage.warning('您的设备不支持摄像头功能')
        fileInput.value.click()
        return
      }

      const video = document.createElement('video')
      const canvas = document.createElement('canvas')
      const context = canvas.getContext('2d')

      navigator.mediaDevices.getUserMedia({ video: true })
        .then(stream => {
          video.srcObject = stream
          video.play()
          
          // 创建拍照界面
          const cameraDialog = document.createElement('div')
          cameraDialog.style.cssText = `
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

          const cameraContent = document.createElement('div')
          cameraContent.style.cssText = `
            background: white;
            padding: 20px;
            border-radius: 8px;
            text-align: center;
            max-width: 90%;
          `

          const cameraTitle = document.createElement('h3')
          cameraTitle.textContent = '拍摄快递面单'
          cameraTitle.style.marginBottom = '20px'

          const cameraFrame = document.createElement('div')
          cameraFrame.style.cssText = `
            width: 300px;
            height: 300px;
            border: 2px solid #409EFF;
            margin: 0 auto 20px;
            overflow: hidden;
          `

          const captureBtn = document.createElement('button')
          captureBtn.textContent = '拍照'
          captureBtn.style.cssText = `
            padding: 10px 20px;
            background: #409EFF;
            color: white;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            margin-right: 10px;
          `

          const cancelBtn = document.createElement('button')
          cancelBtn.textContent = '取消'
          cancelBtn.style.cssText = `
            padding: 10px 20px;
            background: #dc3545;
            color: white;
            border: none;
            border-radius: 4px;
            cursor: pointer;
          `

          cameraFrame.appendChild(video)
          cameraContent.appendChild(cameraTitle)
          cameraContent.appendChild(cameraFrame)
          cameraContent.appendChild(captureBtn)
          cameraContent.appendChild(cancelBtn)
          cameraDialog.appendChild(cameraContent)
          document.body.appendChild(cameraDialog)

          // 拍照
          captureBtn.onclick = () => {
            canvas.width = video.videoWidth
            canvas.height = video.videoHeight
            context.drawImage(video, 0, 0, canvas.width, canvas.height)
            
            canvas.toBlob(blob => {
              const file = new File([blob], 'camera_capture.jpg', { type: 'image/jpeg' })
              handleFile(file)
              
              // 关闭摄像头和界面
              stream.getTracks().forEach(track => track.stop())
              document.body.removeChild(cameraDialog)
            }, 'image/jpeg', 0.8)
          }

          cancelBtn.onclick = () => {
            stream.getTracks().forEach(track => track.stop())
            document.body.removeChild(cameraDialog)
          }
        })
        .catch(error => {
          console.error('摄像头启动失败:', error)
          ElMessage.warning('摄像头启动失败，请使用文件上传')
          fileInput.value.click()
        })
    }

    // 处理文件选择
    const handleFileChange = (event) => {
      const file = event.target.files[0]
      if (file) {
        handleFile(file)
      }
      // 清空input，允许重复选择同一文件
      event.target.value = ''
    }

    // 处理文件
    const handleFile = (file) => {
      // 检查文件类型和大小
      if (!file.type.startsWith('image/')) {
        ElMessage.error('请选择图片文件')
        return
      }

      if (file.size > 10 * 1024 * 1024) { // 10MB限制
        ElMessage.error('图片大小不能超过10MB')
        return
      }

      currentFile.value = file
      
      // 创建预览
      const reader = new FileReader()
      reader.onload = (e) => {
        previewImage.value = e.target.result
        dialogVisible.value = true
        ocrResult.value = null
        errorMessage.value = ''
        dialogTitle.value = '快递面单识别 - 预览'
      }
      reader.readAsDataURL(file)
    }

    // 重新上传
    const reupload = () => {
      previewImage.value = ''
      ocrResult.value = null
      errorMessage.value = ''
      triggerUpload()
    }

    // 识别面单
    const recognize = async () => {
      if (!currentFile.value) return

      recognizing.value = true
      errorMessage.value = ''
      lastError.value = ''

      try {
        const formData = new FormData()
        formData.append('image', currentFile.value)

        // 调用Tesseract OCR接口（取消AI识别）
        const response = await axios.post('/api/v1/ai/ocr_parcel_public', formData, {
          headers: {
            'Content-Type': 'multipart/form-data'
          }
        })

        console.log('OCR API响应:', response.data)
        console.log('响应success字段:', response.data?.success)
        console.log('响应data字段:', response.data?.data)
        
        if (response.data && response.data.success === true) {
          console.log('识别成功，数据:', response.data.data)
          ocrResult.value = response.data.data
          // 立即清除错误信息
          errorMessage.value = ''
          lastError.value = ''
          console.log('清除错误信息后 errorMessage:', errorMessage.value)
          dialogTitle.value = '快递面单识别 - 结果'
          ElMessage.success('识别成功')
        } else {
          console.log('识别失败，响应数据:', response.data)
          // 即使失败，也尝试显示识别数据（如果有的话）
          if (response.data?.data) {
            ocrResult.value = response.data.data
            errorMessage.value = ''
            lastError.value = ''
            console.log('失败但有数据，显示数据:', response.data.data)
            ElMessage.warning('识别置信度较低，请手动核对')
          } else {
            errorMessage.value = response.data?.error || '识别失败'
            lastError.value = errorMessage.value
            console.log('设置错误信息 errorMessage:', errorMessage.value)
            ElMessage.error('识别失败')
          }
        }
      } catch (error) {
        console.error('OCR识别错误:', error)
        errorMessage.value = error.response?.data?.error || '网络错误，请重试'
        lastError.value = errorMessage.value
        ElMessage.error('识别失败')
      } finally {
        recognizing.value = false
      }
    }

    // 重新识别（使用Tesseract OCR）
    const retryWithOCR = async () => {
      if (!currentFile.value) return

      retrying.value = true
      errorMessage.value = ''

      try {
        ElMessage.info('正在重新识别...')
        
        const formData = new FormData()
        formData.append('image', currentFile.value)

        const response = await axios.post('/api/v1/ai/ocr_parcel_public', formData, {
          headers: {
            'Content-Type': 'multipart/form-data'
          }
        })

        if (response.data && response.data.success === true) {
          ocrResult.value = response.data.data
          errorMessage.value = ''
          lastError.value = ''
          dialogTitle.value = '重新识别 - 结果'
          ElMessage.success('重新识别成功')
        } else {
          errorMessage.value = response.data?.error || '重新识别失败'
          lastError.value = errorMessage.value
          ElMessage.error('重新识别失败')
        }
      } catch (error) {
        console.error('重新识别错误:', error)
        errorMessage.value = error.response?.data?.error || '重新识别网络错误'
        ElMessage.error('重新识别失败')
      } finally {
        retrying.value = false
      }
    }

    // 手动输入信息
    const manualInput = async () => {
      try {
        const result = await ElMessageBox.prompt('请输入运单号', '手动输入', {
          confirmButtonText: '确定',
          cancelButtonText: '取消',
          inputPattern: /^[A-Za-z0-9]{10,15}$/,
          inputErrorMessage: '请输入10-15位的运单号'
        })

        if (result.value) {
          // 创建手动输入的结果
          ocrResult.value = {
            tracking_number: result.value,
            recipient_name: '',
            recipient_phone: '',
            courier_company: '',
            recipient_address: '',
            confidence: 1.0,
            raw_text: '手动输入运单号',
            manual_input: true
          }
          
          dialogTitle.value = '手动输入 - 结果'
          ElMessage.success('已手动输入运单号')
        }
      } catch {
        // 用户取消输入
      }
    }

    // 发射结果事件
    const emitResult = () => {
      if (ocrResult.value) {
        emit('ocr-result', ocrResult.value)
      }
    }

    // 应用结果
    const applyResult = () => {
      if (ocrResult.value) {
        emit('ocr-result', ocrResult.value)
        dialogVisible.value = false
        ElMessage.success('已应用识别结果')
      }
    }

    // 关闭对话框
    const handleDialogClose = () => {
      dialogVisible.value = false
      // 延迟清空数据，避免动画闪烁
      setTimeout(() => {
        previewImage.value = ''
        ocrResult.value = null
        errorMessage.value = ''
        currentFile.value = null
      }, 300)
    }

    return {
      fileInput,
      dialogVisible,
      uploading,
      recognizing,
      retrying,
      previewImage,
      ocrResult,
      errorMessage,
      dialogTitle,
      showRetryOptions,
      triggerUpload,
      handleFileChange,
      reupload,
      recognize,
      retryWithOCR,
      manualInput,
      emitResult,
      applyResult,
      handleDialogClose,
      createPackage,
      fillForm
    }
  }
}
</script>

<style scoped>
.ocr-uploader {
  display: inline-block;
}

.ocr-button {
  margin-left: 10px;
}

.ocr-dialog-content {
  max-height: 60vh;
  overflow-y: auto;
}

.image-preview {
  text-align: center;
  margin-bottom: 20px;
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
  margin-top: 20px;
}

.result-form {
  margin-top: 15px;
}

.confidence-text {
  margin-left: 10px;
  font-size: 14px;
  color: #666;
}

.raw-text {
    margin-top: 15px;
    padding: 10px;
    background: #f5f5f5;
    border-radius: 4px;
  }

  .text-content {
    margin: 5px 0 0 0;
    font-size: 14px;
    line-height: 1.4;
    color: #333;
  }

  .package-actions {
    margin-top: 20px;
    padding: 15px;
    background-color: #f0f9ff;
    border-radius: 4px;
    border: 1px solid #bae6fd;
  }

  .package-actions h5 {
    margin: 0 0 15px 0;
    color: #0369a1;
    font-size: 14px;
    font-weight: 600;
  }

  .package-actions .action-buttons {
    display: flex;
    gap: 10px;
    flex-wrap: wrap;
  }

  .package-actions .action-buttons .el-button {
    flex: 1;
    min-width: 120px;
  }

.error-message {
  margin-top: 15px;
}

.retry-options {
  margin-top: 20px;
  padding: 15px;
  background-color: #f8f9fa;
  border-radius: 8px;
  border: 1px solid #e9ecef;
}

.retry-options h5 {
  margin: 0 0 15px 0;
  color: #495057;
  font-size: 14px;
}

.retry-buttons {
  display: flex;
  gap: 10px;
  flex-wrap: wrap;
}

.retry-buttons .el-button {
  flex: 1;
  min-width: 120px;
}

/* 响应式设计 */
@media (max-width: 768px) {
  .retry-buttons {
    flex-direction: column;
  }
  
  .retry-buttons .el-button {
    width: 100%;
  }
}
</style>