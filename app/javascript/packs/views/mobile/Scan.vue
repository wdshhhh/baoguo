<template>
  <div class="scan">
    <div class="scan-container">
      <div class="scan-header">
        <h2>扫码</h2>
      </div>
      
      <div class="scan-content">
        <div class="scan-area">
          <div class="scan-frame">
            <div class="scan-line"></div>
          </div>
          <p>请将二维码/条形码对准扫描框</p>
        </div>
        
        <div class="scan-buttons">
          <van-button type="info" block @click="manualInput" style="margin-bottom: 10px;">
            📝 键盘输入
          </van-button>
          <van-button type="primary" block @click="scanCode">
            📷 摄像头扫码
          </van-button>
        </div>
      </div>
      
      <div class="scan-history">
        <h3>扫描历史</h3>
        <van-list
          v-model:loading="loading"
          :finished="finished"
          finished-text="没有更多历史记录"
          @load="loadHistory"
        >
          <van-cell
            v-for="item in scanHistory"
            :key="item.id"
            :title="item.code"
            :value="item.type === 'tracking' ? '运单号' : '取件码'"
            :label="item.created_at"
          />
        </van-list>
      </div>
    </div>
    
    <!-- 键盘输入对话框 -->
    <van-dialog v-model:show="manualDialogVisible" title="键盘输入" :show-confirm-button="false">
      <div class="manual-input-dialog">
        <van-field
          v-model="manualCode"
          label="输入码"
          placeholder="请输入运单号或取件码"
          clearable
          autofocus
          @keyup.enter="submitManualCode"
        />
        <div class="input-hint">
          <p>💡 提示：</p>
          <ul>
            <li>运单号：SF1234567890、YT9876543210 等</li>
            <li>取件码：8位数字，如 04060001</li>
            <li>按 Enter 键快速确认</li>
          </ul>
        </div>
        <div class="dialog-buttons">
          <van-button type="default" @click="manualDialogVisible = false" size="large">
            取消
          </van-button>
          <van-button type="primary" @click="submitManualCode" size="large" :disabled="!manualCode.trim()">
            确认输入
          </van-button>
        </div>
      </div>
    </van-dialog>
  </div>
</template>

<style scoped>
.manual-input-dialog {
  padding: 0 16px;
}

.input-hint {
  margin: 16px 0;
  padding: 12px;
  background-color: #f8f9fa;
  border-radius: 8px;
  font-size: 14px;
  color: #666;
}

.input-hint p {
  margin: 0 0 8px 0;
  font-weight: bold;
}

.input-hint ul {
  margin: 0;
  padding-left: 16px;
}

.input-hint li {
  margin: 4px 0;
}

.dialog-buttons {
  display: flex;
  gap: 12px;
  margin-top: 20px;
}

.dialog-buttons .van-button {
  flex: 1;
}

/* 优化扫描界面布局 */
.scan-buttons {
  margin-top: 20px;
}

.scan-buttons .van-button {
  margin-bottom: 10px;
}
</style>

<script>
import { ref, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import axios from 'axios'

export default {
  name: 'Scan',
  setup() {
    const loading = ref(false)
    const finished = ref(false)
    const scanHistory = ref([])
    const manualDialogVisible = ref(false)
    const manualCode = ref('')
    const isScanning = ref(false)
    
    const scanCode = async () => {
      if (isScanning.value) return
      
      isScanning.value = true
      
      try {
        // 检查浏览器是否支持摄像头
        if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
          ElMessage.warning('您的设备不支持摄像头功能，已自动切换到键盘输入')
          manualInput()
          return
        }
        
        // 检查摄像头是否可用
        const devices = await navigator.mediaDevices.enumerateDevices()
        const hasCamera = devices.some(device => device.kind === 'videoinput')
        
        if (!hasCamera) {
          ElMessage.warning('未检测到摄像头设备，已自动切换到键盘输入')
          manualInput()
          return
        }
        
        // 使用HTML5 QR Code Scanner库进行扫码
        await startQRCodeScan()
        
      } catch (error) {
        console.error('扫码失败:', error)
        if (error.name === 'NotAllowedError') {
          ElMessage.warning('摄像头权限被拒绝，已自动切换到键盘输入')
          manualInput()
        } else if (error.name === 'NotFoundError') {
          ElMessage.warning('未找到摄像头设备，已自动切换到键盘输入')
          manualInput()
        } else {
          ElMessage.error('扫码失败，请重试')
        }
      } finally {
        isScanning.value = false
      }
    }
    
    const manualInput = () => {
      manualDialogVisible.value = true
    }
    
    const submitManualCode = () => {
      // 处理手动输入的代码
      if (!manualCode.value.trim()) {
        ElMessage.error('请输入有效的代码')
        return
      }
      
      processScannedCode(manualCode.value.trim(), 'manual')
      manualDialogVisible.value = false
      manualCode.value = ''
    }
    
    const startQRCodeScan = () => {
      return new Promise((resolve, reject) => {
        // 创建扫码界面
        const scanOverlay = document.createElement('div')
        scanOverlay.style.cssText = `
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
        
        const scanFrame = document.createElement('div')
        scanFrame.style.cssText = `
          width: 300px;
          height: 300px;
          border: 2px solid #409EFF;
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
        
        const closeBtn = document.createElement('button')
        closeBtn.textContent = '关闭扫描'
        closeBtn.style.cssText = `
          margin-top: 20px;
          padding: 10px 20px;
          background: #409EFF;
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
        scanOverlay.appendChild(scanFrame)
        scanOverlay.appendChild(closeBtn)
        document.head.appendChild(style)
        document.body.appendChild(scanOverlay)
        
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
              video: { facingMode: 'environment' } 
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
            
            // 简单的二维码检测逻辑（实际项目中应使用专业库）
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
          if (scanOverlay.parentNode) {
            scanOverlay.parentNode.removeChild(scanOverlay)
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
      // 实际项目中应使用专业的二维码识别库如：
      // - jsQR: https://github.com/cozmo/jsQR
      // - quaggaJS: https://github.com/serratus/quaggaJS
      
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
        
        // 添加到扫描历史
        const newScan = {
          id: Date.now(),
          code: code,
          type: /^\d{8}$/.test(code) ? 'pickup' : 'tracking',
          created_at: new Date().toLocaleString(),
          source: source
        }
        
        scanHistory.value.unshift(newScan)
        
        // 根据扫描的代码类型执行不同操作
        if (/^\d{8}$/.test(code)) {
          // 取件码 - 执行取件操作
          await processPickupCode(code)
        } else {
          // 运单号 - 查询包裹信息
          await processTrackingCode(code)
        }
        
      } catch (error) {
        console.error('处理扫描代码失败:', error)
        ElMessage.error('处理失败，请重试')
      }
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
    
    const processTrackingCode = async (trackingNumber) => {
      try {
        const response = await axios.get(`/api/v1/packages?tracking_number=${trackingNumber}`)
        
        if (response.data.data && response.data.data.length > 0) {
          const packageInfo = response.data.data[0]
          
          // 显示包裹信息
          ElMessageBox.alert(
            `包裹信息：\\n运单号：${packageInfo.tracking_number}\\n收件人：${packageInfo.recipient_name}\\n手机号：${packageInfo.recipient_phone}\\n状态：${packageInfo.status_name}\\n取件码：${packageInfo.pickup_code}`,
            '包裹信息'
          )
        } else {
          ElMessage.error('未找到对应的包裹')
        }
        
      } catch (error) {
        console.error('查询包裹失败:', error)
        ElMessage.error('查询失败，请重试')
      }
    }
    
    const loadHistory = () => {
      // 模拟加载历史记录
      setTimeout(() => {
        const newHistory = [
          {
            id: 1,
            code: 'SF1234567890',
            type: 'tracking',
            created_at: '2026-04-02 10:00:00'
          },
          {
            id: 2,
            code: 'A1234',
            type: 'pickup',
            created_at: '2026-04-02 09:30:00'
          }
        ]
        scanHistory.value = [...scanHistory.value, ...newHistory]
        loading.value = false
        finished.value = true
      }, 1000)
    }
    
    onMounted(() => {
      loadHistory()
    })
    
    return {
      loading,
      finished,
      scanHistory,
      manualDialogVisible,
      manualCode,
      scanCode,
      manualInput,
      submitManualCode,
      loadHistory
    }
  }
}
</script>

<style scoped>
.scan {
  padding: 0;
}

.scan-container {
  min-height: 100vh;
  padding: 20px;
}

.scan-header {
  text-align: center;
  margin-bottom: 30px;
}

.scan-header h2 {
  font-size: 20px;
  font-weight: bold;
  color: #333;
}

.scan-content {
  margin-bottom: 40px;
}

.scan-area {
  position: relative;
  width: 100%;
  height: 300px;
  background-color: #f5f5f5;
  border-radius: 12px;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  margin-bottom: 30px;
}

.scan-frame {
  width: 250px;
  height: 250px;
  border: 2px solid #007bff;
  position: relative;
  margin-bottom: 20px;
}

.scan-line {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 2px;
  background-color: #007bff;
  animation: scan 2s infinite;
}

@keyframes scan {
  0% { top: 0; }
  100% { top: 100%; }
}

.scan-area p {
  color: #666;
  font-size: 14px;
}

.scan-buttons {
  display: flex;
  flex-direction: column;
  gap: 15px;
}

.scan-history {
  margin-top: 40px;
}

.scan-history h3 {
  font-size: 16px;
  font-weight: bold;
  color: #333;
  margin-bottom: 15px;
}
</style>
