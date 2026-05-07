<template>
  <div class="ai-dashboard">
    <el-card class="mb-4">
      <template #header>
        <div class="card-header">
          <h2>🚀 AI智能功能展示中心（DeepSeek API集成）</h2>
          <el-button type="primary" @click="checkSystemStatus">
            <el-icon><Monitor /></el-icon>
            检查系统状态
          </el-button>
        </div>
      </template>
      
      <!-- API密钥状态 -->
      <div class="api-status mb-4">
        <el-alert 
          title="DeepSeek API已配置"
          type="success"
          :closable="false"
        >
          <template #description>
            <div class="api-details">
              <div class="api-info">
                <strong>API提供商:</strong> DeepSeek AI
              </div>
              <div class="api-info">
                <strong>API密钥状态:</strong> 
                <el-tag type="success">已配置</el-tag>
              </div>
              <div class="api-info">
                <strong>支持功能:</strong> 智能对话、包裹分类、数据分析
              </div>
            </div>
          </template>
        </el-alert>
      </div>
      
      <div class="system-status" v-if="systemStatus">
        <el-alert 
          :title="`AI系统状态: ${systemStatus.system_status === 'healthy' ? '健康' : '异常'}`"
          :type="systemStatus.system_status === 'healthy' ? 'success' : 'error'"
          :closable="false"
        >
          <template #description>
            <div class="status-details">
              <div v-for="(status, service) in systemStatus.services" :key="service" class="status-item">
                <span class="service-name">{{ getServiceName(service) }}:</span>
                <el-tag :type="status ? 'success' : 'error'">
                  {{ status ? '正常' : '异常' }}
                </el-tag>
              </div>
            </div>
          </template>
        </el-alert>
      </div>
    </el-card>

    <!-- AI功能卡片网格 -->
    <div class="ai-grid">
      <!-- 智能包裹识别和分类 -->
      <el-card class="ai-card">
        <template #header>
          <div class="ai-card-header">
            <el-icon class="ai-icon"><Box /></el-icon>
            <h3>智能包裹识别和分类</h3>
          </div>
        </template>
        <div class="ai-card-content">
          <p>基于OCR结果的智能包裹分类系统</p>
          <div class="demo-section">
            <el-input
              v-model="classificationText"
              type="textarea"
              :rows="3"
              placeholder="请输入包裹OCR识别结果或运单信息..."
              style="margin-bottom: 10px;"
            />
            <el-button type="primary" @click="testClassification" :loading="classificationLoading">
              智能分类测试
            </el-button>
          </div>
          
          <div v-if="classificationResult" class="result-section">
            <el-divider>分类结果</el-divider>
            <div class="result-item">
              <strong>包裹类型:</strong> {{ getPackageTypeText(classificationResult.package_type) }}
            </div>
            <div class="result-item">
              <strong>优先级:</strong> {{ getPriorityText(classificationResult.priority_level) }}
            </div>
            <div class="result-item">
              <strong>预估重量:</strong> {{ classificationResult.estimated_weight }} kg
            </div>
            <div class="result-item">
              <strong>置信度:</strong> {{ (classificationResult.confidence * 100).toFixed(1) }}%
            </div>
          </div>
        </div>
      </el-card>

      <!-- 异常预测和预警 -->
      <el-card class="ai-card">
        <template #header>
          <div class="ai-card-header">
            <el-icon class="ai-icon"><Warning /></el-icon>
            <h3>异常预测和预警</h3>
          </div>
        </template>
        <div class="ai-card-content">
          <p>基于历史数据的智能异常预测系统</p>
          <div class="demo-section">
            <el-button type="warning" @click="testExceptionPrediction" :loading="predictionLoading">
              运行异常预测
            </el-button>
            <el-button type="info" @click="getRealTimeAlerts" style="margin-left: 10px;">
              查看实时预警
            </el-button>
          </div>
          
          <div v-if="predictionResult" class="result-section">
            <el-divider>预测结果</el-divider>
            <div class="result-item">
              <strong>整体风险等级:</strong> 
              <el-tag :type="predictionResult.overall_risk_level === 'high' ? 'danger' : predictionResult.overall_risk_level === 'medium' ? 'warning' : 'success'">
                {{ getRiskLevelText(predictionResult.overall_risk_level) }}
              </el-tag>
            </div>
            <div class="result-item">
              <strong>高风险包裹:</strong> {{ predictionResult.high_risk_packages?.length || 0 }} 个
            </div>
            <div class="result-item">
              <strong>中风险包裹:</strong> {{ predictionResult.medium_risk_packages?.length || 0 }} 个
            </div>
            <div class="result-item">
              <strong>预测置信度:</strong> {{ (predictionResult.prediction_confidence * 100).toFixed(1) }}%
            </div>
          </div>

          <div v-if="realTimeAlerts.length > 0" class="alert-section">
            <el-divider>实时预警</el-divider>
            <div v-for="alert in realTimeAlerts" :key="alert.type" class="alert-item">
              <el-alert
                :title="alert.message"
                :type="alert.severity === 'high' ? 'error' : 'warning'"
                :closable="false"
                show-icon
              />
            </div>
          </div>
        </div>
      </el-card>

      <!-- 客户服务聊天机器人 -->
      <el-card class="ai-card">
        <template #header>
          <div class="ai-card-header">
            <el-icon class="ai-icon"><ChatDotRound /></el-icon>
            <h3>智能客服聊天机器人</h3>
          </div>
        </template>
        <div class="ai-card-content">
          <p>24小时智能客服，支持自然语言交互</p>
          <div class="chat-demo">
            <div class="chat-messages">
              <div v-for="(msg, index) in chatMessages" :key="index" 
                   :class="['message', msg.sender]"
              >
                <div class="message-content">{{ msg.content }}</div>
                <div class="message-time">{{ msg.time }}</div>
              </div>
            </div>
            
            <div class="chat-input">
              <el-input
                v-model="chatInput"
                placeholder="请输入您的问题..."
                @keyup.enter="sendChatMessage"
              >
                <template #append>
                  <el-button @click="sendChatMessage" :loading="chatLoading">
                    <el-icon><Promotion /></el-icon>
                  </el-button>
                </template>
              </el-input>
            </div>
          </div>
        </div>
      </el-card>

      <!-- 数据分析和智能报表 -->
      <el-card class="ai-card">
        <template #header>
          <div class="ai-card-header">
            <el-icon class="ai-icon"><DataAnalysis /></el-icon>
            <h3>数据分析和智能报表</h3>
          </div>
        </template>
        <div class="ai-card-content">
          <p>智能数据分析与可视化报表系统</p>
          <div class="demo-section">
            <el-select v-model="reportType" placeholder="选择报表类型" style="width: 100%; margin-bottom: 10px;">
              <el-option label="每日摘要" value="daily_summary" />
              <el-option label="周度趋势" value="weekly_trends" />
              <el-option label="月度分析" value="monthly_analysis" />
              <el-option label="异常分析" value="exception_analysis" />
            </el-select>
            <el-button type="primary" @click="generateReport" :loading="reportLoading" style="width: 100%;">
              生成智能报表
            </el-button>
          </div>
          
          <div v-if="reportResult" class="result-section">
            <el-divider>报表概要</el-divider>
            <div class="result-item">
              <strong>报表类型:</strong> {{ getReportTypeText(reportResult.report_type) }}
            </div>
            <div class="result-item">
              <strong>数据范围:</strong> {{ reportResult.date_range?.start }} 至 {{ reportResult.date_range?.end }}
            </div>
            <div v-if="reportResult.summary" class="result-item">
              <strong>总包裹数:</strong> {{ reportResult.summary.total_packages }}
            </div>
            <div v-if="reportResult.trend_analysis" class="result-item">
              <strong>趋势分析:</strong> {{ reportResult.trend_analysis }}
            </div>
          </div>
        </div>
      </el-card>

      <!-- 语音识别和交互 -->
      <el-card class="ai-card">
        <template #header>
          <div class="ai-card-header">
            <el-icon class="ai-icon"><Microphone /></el-icon>
            <h3>语音识别和交互</h3>
          </div>
        </template>
        <div class="ai-card-content">
          <p>语音识别与语音合成功能演示</p>
          <div class="demo-section">
            <el-button-group>
              <el-button type="primary" @click="startVoiceRecognition" :loading="voiceLoading">
                <el-icon><Microphone /></el-icon>
                语音识别
              </el-button>
              <el-button type="success" @click="testTextToSpeech">
                <el-icon><VideoPlay /></el-icon>
                语音合成
              </el-button>
            </el-button-group>
          </div>
          
          <div v-if="voiceResult" class="result-section">
            <el-divider>语音识别结果</el-divider>
            <div class="result-item">
              <strong>识别文本:</strong> {{ voiceResult.recognized_text }}
            </div>
            <div class="result-item">
              <strong>置信度:</strong> {{ (voiceResult.confidence * 100).toFixed(1) }}%
            </div>
          </div>

          <div v-if="ttsResult" class="result-section">
            <el-divider>语音合成结果</el-divider>
            <div class="result-item">
              <strong>合成状态:</strong> 成功
            </div>
            <div class="result-item">
              <strong>音频时长:</strong> {{ ttsResult.duration }} 秒
            </div>
          </div>
        </div>
      </el-card>

      <!-- 图像识别和OCR处理 -->
      <el-card class="ai-card">
        <template #header>
          <div class="ai-card-header">
            <el-icon class="ai-icon"><Picture /></el-icon>
            <h3>图像识别和OCR处理</h3>
          </div>
        </template>
        <div class="ai-card-content">
          <p>高级OCR识别与图像分析功能</p>
          <div class="demo-section">
            <el-upload
              class="upload-demo"
              action="#"
              :auto-upload="false"
              :show-file-list="false"
              :on-change="handleImageUpload"
            >
              <el-button type="primary">
                <el-icon><Upload /></el-icon>
                上传包裹图片
              </el-button>
            </el-upload>
            
            <div v-if="uploadedImage" class="image-preview">
              <img :src="uploadedImage" alt="上传的图片" style="max-width: 100%; max-height: 200px;" />
              <el-button type="success" @click="testAdvancedOcr" :loading="ocrLoading" style="margin-top: 10px;">
                执行OCR识别
              </el-button>
            </div>
          </div>
          
          <div v-if="ocrResult" class="result-section">
            <el-divider>OCR识别结果</el-divider>
            <div class="result-item">
              <strong>识别质量:</strong> 
              <el-tag :type="ocrResult.overall_quality > 80 ? 'success' : ocrResult.overall_quality > 60 ? 'warning' : 'error'">
                {{ ocrResult.overall_quality }} 分
              </el-tag>
            </div>
            <div v-if="ocrResult.ocr_info" class="result-item">
              <strong>运单号:</strong> {{ ocrResult.ocr_info.tracking_number || '未识别' }}
            </div>
            <div v-if="ocrResult.damage_assessment" class="result-item">
              <strong>破损检测:</strong> {{ ocrResult.damage_assessment.has_damage ? '有破损' : '无破损' }}
            </div>
          </div>
        </div>
      </el-card>
    </div>
  </div>
</template>

<script>
import { ref, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import axios from 'axios'

export default {
  name: 'AiDashboard',
  setup() {
    // 系统状态
    const systemStatus = ref(null)
    
    // 智能包裹分类
    const classificationText = ref('')
    const classificationResult = ref(null)
    const classificationLoading = ref(false)
    
    // 异常预测
    const predictionResult = ref(null)
    const predictionLoading = ref(false)
    const realTimeAlerts = ref([])
    
    // 聊天机器人
    const chatInput = ref('')
    const chatMessages = ref([
      { sender: 'bot', content: '您好！我是快递驿站智能助手，有什么可以帮您的？', time: new Date().toLocaleTimeString() }
    ])
    const chatLoading = ref(false)
    
    // 数据分析
    const reportType = ref('daily_summary')
    const reportResult = ref(null)
    const reportLoading = ref(false)
    
    // 语音识别
    const voiceResult = ref(null)
    const voiceLoading = ref(false)
    const ttsResult = ref(null)
    
    // OCR识别
    const uploadedImage = ref(null)
    const ocrResult = ref(null)
    const ocrLoading = ref(false)

    // 检查系统状态
    const checkSystemStatus = async () => {
      try {
        const response = await axios.get('/api/v1/ai/system_status')
        // 后端返回的数据结构是 {data: {...}}
        systemStatus.value = response.data.data
        ElMessage.success('系统状态检查完成')
      } catch (error) {
        ElMessage.error('系统状态检查失败: ' + (error.response?.data?.error || error.message))
      }
    }

    // 智能包裹分类测试
    const testClassification = async () => {
      if (!classificationText.value.trim()) {
        ElMessage.warning('请输入包裹信息')
        return
      }
      
      classificationLoading.value = true
      try {
        const response = await axios.post('/api/v1/ai/intelligent_classification', {
          ocr_data: { raw_text: classificationText.value }
        })
        // 后端返回的数据结构是 {data: {...}}
        classificationResult.value = response.data.data
        ElMessage.success('智能分类完成')
      } catch (error) {
        ElMessage.error('智能分类失败: ' + (error.response?.data?.error || error.message))
      } finally {
        classificationLoading.value = false
      }
    }

    // 异常预测测试
    const testExceptionPrediction = async () => {
      predictionLoading.value = true
      try {
        const response = await axios.get('/api/v1/ai/exception_prediction')
        // 后端返回的数据结构是 {data: {...}}
        predictionResult.value = response.data.data
        ElMessage.success('异常预测完成')
      } catch (error) {
        ElMessage.error('异常预测失败: ' + (error.response?.data?.error || error.message))
      } finally {
        predictionLoading.value = false
      }
    }

    // 获取实时预警
    const getRealTimeAlerts = async () => {
      try {
        const response = await axios.get('/api/v1/ai/real_time_alerts')
        // 后端返回的数据结构是 {data: {...}}
        realTimeAlerts.value = response.data.data.alerts
        ElMessage.success('实时预警获取完成')
      } catch (error) {
        ElMessage.error('实时预警获取失败: ' + (error.response?.data?.error || error.message))
      }
    }

    // 发送聊天消息
    const sendChatMessage = async () => {
      if (!chatInput.value.trim()) return
      
      const userMessage = chatInput.value
      chatMessages.value.push({
        sender: 'user',
        content: userMessage,
        time: new Date().toLocaleTimeString()
      })
      
      chatInput.value = ''
      chatLoading.value = true
      
      try {
        const response = await axios.post('/api/v1/ai/chatbot', {
          message: userMessage
        })
        // 后端返回的数据结构是 {data: {...}}
        chatMessages.value.push({
          sender: 'bot',
          content: response.data.data.response,
          time: new Date().toLocaleTimeString()
        })
      } catch (error) {
        ElMessage.error('聊天机器人响应失败: ' + (error.response?.data?.error || error.message))
      } finally {
        chatLoading.value = false
      }
    }

    // 生成报表
    const generateReport = async () => {
      reportLoading.value = true
      try {
        const response = await axios.get('/api/v1/ai/analytics_report', {
          params: { report_type: reportType.value }
        })
        // 后端返回的数据结构是 {data: {...}}
        reportResult.value = response.data.data
        ElMessage.success('报表生成完成')
      } catch (error) {
        ElMessage.error('报表生成失败: ' + (error.response?.data?.error || error.message))
      } finally {
        reportLoading.value = false
      }
    }

    // 语音识别测试
    const startVoiceRecognition = async () => {
      voiceLoading.value = true
      try {
        // 模拟语音识别（实际项目中应使用真实音频数据）
        const response = await axios.post('/api/v1/ai/speech_recognition', {
          audio_data: '模拟音频数据',
          language: 'zh-CN'
        })
        // 后端返回的数据结构是 {data: {...}}
        voiceResult.value = response.data.data
        ElMessage.success('语音识别完成')
      } catch (error) {
        ElMessage.error('语音识别失败: ' + (error.response?.data?.error || error.message))
      } finally {
        voiceLoading.value = false
      }
    }

    // 文本转语音测试
    const testTextToSpeech = async () => {
      try {
        const response = await axios.post('/api/v1/ai/text_to_speech', {
          text: '欢迎使用快递驿站智能语音系统',
          language: 'zh-CN'
        })
        // 后端返回的数据结构是 {data: {...}}
        ttsResult.value = response.data.data
        ElMessage.success('语音合成完成')
      } catch (error) {
        ElMessage.error('语音合成失败: ' + (error.response?.data?.error || error.message))
      }
    }

    // 处理图片上传
    const handleImageUpload = (file) => {
      const reader = new FileReader()
      reader.onload = (e) => {
        uploadedImage.value = e.target.result
      }
      reader.readAsDataURL(file.raw)
    }

    // 高级OCR测试
    const testAdvancedOcr = async () => {
      if (!uploadedImage.value) {
        ElMessage.warning('请先上传图片')
        return
      }
      
      ocrLoading.value = true
      try {
        const response = await axios.post('/api/v1/ai/advanced_ocr', {
          image: uploadedImage.value
        })
        // 后端返回的数据结构是 {data: {...}}
        ocrResult.value = response.data.data
        ElMessage.success('OCR识别完成')
      } catch (error) {
        ElMessage.error('OCR识别失败: ' + (error.response?.data?.error || error.message))
      } finally {
        ocrLoading.value = false
      }
    }

    // 工具方法
    const extractTrackingNumber = (text) => {
      // 运单号格式匹配：数字、字母、特殊字符组合
      const patterns = [
        /[A-Z]{2}[0-9]{9}[A-Z]{2}/, // 国际运单格式
        /[0-9]{12}/, // 12位数字运单
        /[0-9]{10}/, // 10位数字运单
        /[A-Z0-9]{8,15}/ // 混合字符运单
      ]
      
      for (const pattern of patterns) {
        const match = text.match(pattern)
        if (match) return match[0]
      }
      return ''
    }

    const getServiceName = (service) => {
      const names = {
        ocr_service: 'OCR服务',
        prediction_service: '预测服务',
        chatbot_service: '聊天机器人',
        analytics_service: '分析服务',
        speech_service: '语音服务'
      }
      return names[service] || service
    }

    const getPackageTypeText = (type) => {
      const types = {
        fragile: '易碎物品',
        large: '大件包裹',
        priority: '优先包裹',
        document: '文件类',
        normal: '普通包裹'
      }
      return types[type] || type
    }

    const getPriorityText = (priority) => {
      const priorities = {
        high: '高',
        medium: '中',
        low: '低'
      }
      return priorities[priority] || priority
    }

    const getRiskLevelText = (level) => {
      const levels = {
        high: '高风险',
        medium: '中风险',
        low: '低风险'
      }
      return levels[level] || level
    }

    const getReportTypeText = (type) => {
      const types = {
        daily_summary: '每日摘要',
        weekly_trends: '周度趋势',
        monthly_analysis: '月度分析',
        exception_analysis: '异常分析'
      }
      return types[type] || type
    }

    onMounted(() => {
      checkSystemStatus()
    })

    return {
      systemStatus,
      classificationText,
      classificationResult,
      classificationLoading,
      predictionResult,
      predictionLoading,
      realTimeAlerts,
      chatInput,
      chatMessages,
      chatLoading,
      reportType,
      reportResult,
      reportLoading,
      voiceResult,
      voiceLoading,
      ttsResult,
      uploadedImage,
      ocrResult,
      ocrLoading,
      
      checkSystemStatus,
      testClassification,
      testExceptionPrediction,
      getRealTimeAlerts,
      sendChatMessage,
      generateReport,
      startVoiceRecognition,
      testTextToSpeech,
      handleImageUpload,
      testAdvancedOcr,
      
      getServiceName,
      getPackageTypeText,
      getPriorityText,
      getRiskLevelText,
      getReportTypeText
    }
  }
}
</script>

<style scoped>
.ai-dashboard {
  padding: 20px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.system-status {
  margin-bottom: 0;
}

.status-details {
  display: flex;
  flex-wrap: wrap;
  gap: 15px;
  margin-top: 10px;
}

.status-item {
  display: flex;
  align-items: center;
  gap: 8px;
}

.service-name {
  font-weight: 500;
}

.ai-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(400px, 1fr));
  gap: 20px;
  margin-top: 20px;
}

.ai-card {
  height: fit-content;
}

.ai-card-header {
  display: flex;
  align-items: center;
  gap: 10px;
}

.ai-icon {
  font-size: 24px;
  color: #409EFF;
}

.ai-card-content {
  min-height: 200px;
}

.demo-section {
  margin: 15px 0;
}

.result-section {
  margin-top: 15px;
  padding: 10px;
  background-color: #f8f9fa;
  border-radius: 4px;
}

.result-item {
  margin: 8px 0;
  display: flex;
  align-items: center;
  gap: 10px;
}

.alert-section {
  margin-top: 15px;
}

.alert-item {
  margin: 5px 0;
}

.chat-demo {
  border: 1px solid #e4e7ed;
  border-radius: 4px;
  padding: 10px;
  max-height: 300px;
  display: flex;
  flex-direction: column;
}

.chat-messages {
  flex: 1;
  overflow-y: auto;
  margin-bottom: 10px;
  max-height: 200px;
}

.message {
  margin: 8px 0;
  display: flex;
  flex-direction: column;
}

.message.user {
  align-items: flex-end;
}

.message.bot {
  align-items: flex-start;
}

.message-content {
  padding: 8px 12px;
  border-radius: 12px;
  max-width: 80%;
}

.message.user .message-content {
  background-color: #409EFF;
  color: white;
}

.message.bot .message-content {
  background-color: #f0f2f5;
  color: #333;
}

.message-time {
  font-size: 12px;
  color: #999;
  margin-top: 4px;
}

.chat-input {
  margin-top: 10px;
}

.image-preview {
  text-align: center;
  margin: 10px 0;
}

@media (max-width: 768px) {
  .ai-grid {
    grid-template-columns: 1fr;
  }
  
  .ai-card {
    margin-bottom: 20px;
  }
}
</style>