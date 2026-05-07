<template>
  <div class="ai-assistant">
    <!-- 顶部导航 -->
    <el-card class="mb-4">
      <template #header>
        <div class="card-header">
          <h2>🤖 AI智能助手 - 快递驿站助手</h2>
          <div class="header-actions">
            <el-button type="primary" @click="clearConversation">
              <el-icon><Refresh /></el-icon>
              清空对话
            </el-button>
            <el-button type="success" @click="exportConversation">
              <el-icon><Download /></el-icon>
              导出对话
            </el-button>
          </div>
        </div>
      </template>
      
      <!-- 系统状态 -->
      <div class="system-info">
        <el-row :gutter="20">
          <el-col :span="8">
            <el-statistic title="对话轮数" :value="conversation.length" />
          </el-col>
          <el-col :span="8">
            <el-statistic title="AI状态" value="在线" />
          </el-col>
          <el-col :span="8">
            <el-statistic title="API提供商" value="DeepSeek" />
          </el-col>
        </el-row>
      </div>
    </el-card>

    <!-- 对话区域 -->
    <el-card class="conversation-card">
      <template #header>
        <div class="conversation-header">
          <h3>💬 智能对话</h3>
          <el-tag type="success">DeepSeek AI</el-tag>
        </div>
      </template>
      
      <div class="conversation-container" ref="conversationContainer">
        <!-- 欢迎消息 -->
        <div v-if="conversation.length === 0" class="welcome-message">
          <div class="welcome-content">
            <el-icon class="welcome-icon"><ChatDotRound /></el-icon>
            <h3>欢迎使用快递驿站AI助手！</h3>
            <p>我是您的智能助手，可以帮助您：</p>
            <ul>
              <li>📦 查询包裹状态和位置</li>
              <li>🏪 了解驿站营业信息和地址</li>
              <li>💰 咨询收费标准和优惠活动</li>
              <li>🚚 处理包裹异常和投诉建议</li>
              <li>📊 查看数据分析和报表</li>
              <li>❓ 解答使用过程中的问题</li>
            </ul>
            <p>请在下方的输入框中输入您的问题，我会尽力为您解答！</p>
          </div>
        </div>
        
        <!-- 对话消息 -->
        <div v-for="(msg, index) in conversation" :key="index" class="message" :class="{ 'user-message': msg.role === 'user', 'assistant-message': msg.role === 'assistant' }">
          <div class="message-avatar">
            <el-avatar v-if="msg.role === 'user'" :size="40" style="background-color: #409EFF">
              <el-icon><User /></el-icon>
            </el-avatar>
            <el-avatar v-else :size="40" style="background-color: #67C23A">
              <el-icon><Robot /></el-icon>
            </el-avatar>
          </div>
          <div class="message-content">
            <div class="message-header">
              <span class="sender-name">{{ msg.role === 'user' ? '您' : 'AI助手' }}</span>
              <span class="message-time">{{ msg.timestamp }}</span>
            </div>
            <div class="message-text" v-html="formatMessage(msg.content)"></div>
            
            <!-- 建议操作 -->
            <div v-if="msg.suggestedActions && msg.suggestedActions.length > 0" class="suggested-actions">
              <el-button 
                v-for="(action, actionIndex) in msg.suggestedActions" 
                :key="actionIndex"
                size="small"
                @click="handleSuggestedAction(action, msg.content)"
              >
                {{ action }}
              </el-button>
            </div>
          </div>
        </div>
        
        <!-- 加载状态 -->
        <div v-if="isLoading" class="loading-message">
          <div class="message-avatar">
            <el-avatar :size="40" style="background-color: #67C23A">
              <el-icon><Robot /></el-icon>
            </el-avatar>
          </div>
          <div class="message-content">
            <div class="loading-text">
              <span class="dot">.</span>
              <span class="dot">.</span>
              <span class="dot">.</span>
              AI助手正在思考中
            </div>
          </div>
        </div>
      </div>
      
      <!-- 输入区域 -->
      <div class="input-area">
        <el-input
          v-model="userInput"
          type="textarea"
          :rows="3"
          placeholder="请输入您的问题...（例如：如何查询包裹状态？驿站营业时间是什么时候？）"
          @keydown.enter.exact.prevent="sendMessage"
          :disabled="isLoading"
        />
        <div class="input-actions">
          <el-button-group>
            <el-button type="primary" @click="sendMessage" :loading="isLoading" :disabled="!userInput.trim()">
              <el-icon><Promotion /></el-icon>
              发送消息
            </el-button>
            <el-button @click="insertQuickQuestion">
              <el-icon><Magic /></el-icon>
              快捷问题
            </el-button>
          </el-button-group>
          
          <div class="quick-questions">
            <span class="quick-label">快捷提问：</span>
            <el-button 
              v-for="(question, qIndex) in quickQuestions" 
              :key="qIndex"
              size="small"
              @click="insertQuickQuestion(question)"
            >
              {{ question }}
            </el-button>
          </div>
        </div>
      </div>
    </el-card>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted, nextTick } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import axios from 'axios'

// 响应式数据
const conversation = ref([])
const userInput = ref('')
const isLoading = ref(false)
const conversationContainer = ref(null)

// 快捷问题列表
const quickQuestions = reactive([
  '如何查询包裹状态？',
  '驿站营业时间是什么时候？',
  '取件需要什么证件？',
  '包裹异常怎么处理？',
  '收费标准是怎样的？'
])

// 发送消息
const sendMessage = async () => {
  if (!userInput.value.trim()) return
  
  const userMessage = userInput.value.trim()
  userInput.value = ''
  
  // 添加用户消息到对话
  conversation.value.push({
    role: 'user',
    content: userMessage,
    timestamp: new Date().toLocaleTimeString(),
    suggestedActions: []
  })
  
  isLoading.value = true
  
  try {
    // 调用AI助手API
    const response = await axios.post('/api/v1/ai/assistant', {
      message: userMessage,
      conversation_history: conversation.value.slice(-10) // 只发送最近10轮对话
    })
    
    // 添加AI回复到对话
    conversation.value.push({
      role: 'assistant',
      content: response.data.data.response,
      timestamp: new Date().toLocaleTimeString(),
      suggestedActions: response.data.data.suggested_actions || []
    })
    
    ElMessage.success('AI助手已回复')
    
  } catch (error) {
    console.error('AI助手调用失败:', error)
    
    // 添加错误回复
    conversation.value.push({
      role: 'assistant',
      content: '抱歉，AI助手暂时无法响应。请稍后再试或联系技术支持。',
      timestamp: new Date().toLocaleTimeString(),
      suggestedActions: ['重新发送', '联系客服']
    })
    
    ElMessage.error('AI助手响应失败')
  } finally {
    isLoading.value = false
    scrollToBottom()
  }
}

// 清空对话
const clearConversation = async () => {
  try {
    await ElMessageBox.confirm('确定要清空当前对话吗？', '提示', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    })
    
    conversation.value = []
    ElMessage.success('对话已清空')
  } catch {
    // 用户取消操作
  }
}

// 导出对话
const exportConversation = () => {
  const conversationText = conversation.value.map(msg => {
    return `${msg.role === 'user' ? '用户' : 'AI助手'} (${msg.timestamp}): ${msg.content}`
  }).join('\n\n')
  
  const blob = new Blob([conversationText], { type: 'text/plain' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = `ai-assistant-conversation-${new Date().toISOString().split('T')[0]}.txt`
  a.click()
  URL.revokeObjectURL(url)
  
  ElMessage.success('对话已导出')
}

// 插入快捷问题
const insertQuickQuestion = (question = null) => {
  if (question) {
    userInput.value = question
  } else {
    // 随机选择一个快捷问题
    const randomQuestion = quickQuestions[Math.floor(Math.random() * quickQuestions.length)]
    userInput.value = randomQuestion
  }
}

// 处理建议操作
const handleSuggestedAction = (action, context) => {
  switch (action) {
    case '查看包裹详情':
      // 跳转到包裹管理页面
      window.location.href = '/pc/packages'
      break
    case '查看取件流程':
      userInput.value = '请详细说明取件流程'
      sendMessage()
      break
    case '查看地图位置':
      userInput.value = '驿站在哪里？怎么导航过去？'
      sendMessage()
      break
    case '联系人工客服':
      ElMessage.info('请拨打客服电话：400-123-4567')
      break
    default:
      userInput.value = action
      sendMessage()
  }
}

// 格式化消息内容
const formatMessage = (content) => {
  // 简单的格式化：将换行符转换为HTML换行
  return content.replace(/\n/g, '<br>')
}

// 滚动到底部
const scrollToBottom = () => {
  nextTick(() => {
    if (conversationContainer.value) {
      conversationContainer.value.scrollTop = conversationContainer.value.scrollHeight
    }
  })
}

// 组件挂载时滚动到底部
onMounted(() => {
  scrollToBottom()
})
</script>

<style scoped>
.ai-assistant {
  max-width: 1200px;
  margin: 0 auto;
  padding: 20px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.header-actions {
  display: flex;
  gap: 10px;
}

.system-info {
  margin-top: 20px;
}

.conversation-card {
  height: 70vh;
  display: flex;
  flex-direction: column;
}

.conversation-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.conversation-container {
  flex: 1;
  overflow-y: auto;
  padding: 20px;
  background-color: #f8f9fa;
  border-radius: 8px;
  margin-bottom: 20px;
}

.welcome-message {
  text-align: center;
  padding: 40px 20px;
}

.welcome-content {
  max-width: 600px;
  margin: 0 auto;
}

.welcome-icon {
  font-size: 48px;
  color: #409EFF;
  margin-bottom: 20px;
}

.welcome-content h3 {
  color: #303133;
  margin-bottom: 15px;
}

.welcome-content ul {
  text-align: left;
  margin: 20px 0;
}

.welcome-content li {
  margin: 8px 0;
  color: #606266;
}

.message {
  display: flex;
  margin-bottom: 20px;
  gap: 12px;
}

.user-message {
  flex-direction: row-reverse;
}

.message-avatar {
  flex-shrink: 0;
}

.message-content {
  flex: 1;
  max-width: 70%;
}

.user-message .message-content {
  text-align: right;
}

.message-header {
  margin-bottom: 8px;
}

.sender-name {
  font-weight: bold;
  color: #303133;
}

.message-time {
  font-size: 12px;
  color: #909399;
  margin-left: 10px;
}

.message-text {
  background: white;
  padding: 12px 16px;
  border-radius: 8px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
  line-height: 1.6;
}

.user-message .message-text {
  background: #409EFF;
  color: white;
}

.suggested-actions {
  margin-top: 10px;
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
}

.loading-message {
  display: flex;
  margin-bottom: 20px;
  gap: 12px;
}

.loading-text {
  display: flex;
  align-items: center;
  color: #909399;
}

.dot {
  animation: blink 1.4s infinite both;
  animation-delay: 0.2s;
}

.dot:nth-child(2) {
  animation-delay: 0.4s;
}

.dot:nth-child(3) {
  animation-delay: 0.6s;
}

@keyframes blink {
  0%, 80%, 100% {
    opacity: 0;
  }
  40% {
    opacity: 1;
  }
}

.input-area {
  border-top: 1px solid #e4e7ed;
  padding-top: 20px;
}

.input-actions {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-top: 10px;
}

.quick-questions {
  display: flex;
  align-items: center;
  gap: 8px;
}

.quick-label {
  font-size: 14px;
  color: #606266;
}
</style>