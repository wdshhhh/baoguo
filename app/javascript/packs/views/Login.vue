<template>
  <div class="login-container">
    <div class="login-form">
      <h2>菜鸟驿站包裹管理系统</h2>
      
      <!-- 切换登录/注册 -->
      <div class="form-tabs">
        <el-tabs v-model="activeTab" type="card" @tab-click="handleTabChange">
          <el-tab-pane label="登录" name="login">
            <el-form
              :model="loginForm"
              :rules="loginRules"
              ref="loginFormRef"
              label-position="top"
            >
              <el-form-item label="手机号" prop="phone">
                <el-input
                  v-model="loginForm.phone"
                  placeholder="请输入手机号"
                  maxlength="11"
                >
                  <template #prefix>
                    <el-icon><SmartPhone /></el-icon>
                  </template>
                </el-input>
              </el-form-item>
              
              <el-form-item label="密码" prop="password">
                <el-input
                  v-model="loginForm.password"
                  type="password"
                  placeholder="请输入密码"
                  show-password
                >
                  <template #prefix>
                    <el-icon><Lock /></el-icon>
                  </template>
                </el-input>
              </el-form-item>
              
              <el-form-item>
                <el-button
                  type="primary"
                  class="login-btn"
                  @click="handleLogin"
                  :loading="loading"
                >
                  登录
                </el-button>
              </el-form-item>
            </el-form>
          </el-tab-pane>
          
          <el-tab-pane label="注册" name="register">
            <el-form
              :model="registerForm"
              :rules="registerRules"
              ref="registerFormRef"
              label-position="top"
            >
              <el-form-item label="手机号" prop="phone">
                <el-input
                  v-model="registerForm.phone"
                  placeholder="请输入手机号"
                  maxlength="11"
                >
                  <template #prefix>
                    <el-icon><SmartPhone /></el-icon>
                  </template>
                </el-input>
              </el-form-item>
              
              <el-form-item label="姓名" prop="name">
                <el-input
                  v-model="registerForm.name"
                  placeholder="请输入姓名"
                >
                  <template #prefix>
                    <el-icon><User /></el-icon>
                  </template>
                </el-input>
              </el-form-item>
              
              <el-form-item label="工号（选填）" prop="employee_number">
                <el-input
                  v-model="registerForm.employee_number"
                  placeholder="请输入工号"
                >
                  <template #prefix>
                    <el-icon><Document /></el-icon>
                  </template>
                </el-input>
              </el-form-item>
              
              <el-form-item label="密码" prop="password">
                <el-input
                  v-model="registerForm.password"
                  type="password"
                  placeholder="请输入密码（至少6位）"
                  show-password
                >
                  <template #prefix>
                    <el-icon><Lock /></el-icon>
                  </template>
                </el-input>
              </el-form-item>
              
              <el-form-item label="确认密码" prop="password_confirmation">
                <el-input
                  v-model="registerForm.password_confirmation"
                  type="password"
                  placeholder="请再次输入密码"
                  show-password
                >
                  <template #prefix>
                    <el-icon><Lock /></el-icon>
                  </template>
                </el-input>
              </el-form-item>
              
              <el-form-item>
                <el-button
                  type="primary"
                  class="login-btn"
                  @click="handleRegister"
                  :loading="loading"
                >
                  注册
                </el-button>
              </el-form-item>
            </el-form>
          </el-tab-pane>
        </el-tabs>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, reactive } from 'vue'
import { useRouter } from 'vue-router'
import { useUserStore } from '../stores/user'
import { SmartPhone, Lock, User, Document } from '@element-plus/icons-vue'
import { ElMessage } from 'element-plus'
import axios from 'axios'

export default {
  name: 'Login',
  setup() {
    const router = useRouter()
    const userStore = useUserStore()
    const loginFormRef = ref(null)
    const registerFormRef = ref(null)
    const loading = ref(false)
    const activeTab = ref('login')
    
    const loginForm = reactive({
      phone: '',
      password: ''
    })
    
    const registerForm = reactive({
      phone: '',
      name: '',
      employee_number: '',
      password: '',
      password_confirmation: ''
    })
    
    const loginRules = {
      phone: [
        { required: true, message: '请输入手机号', trigger: 'blur' },
        { pattern: /^1[3-9]\d{9}$/, message: '手机号格式不正确', trigger: 'blur' }
      ],
      password: [
        { required: true, message: '请输入密码', trigger: 'blur' },
        { min: 6, message: '密码长度至少6位', trigger: 'blur' }
      ]
    }
    
    const registerRules = {
      phone: [
        { required: true, message: '请输入手机号', trigger: 'blur' },
        { pattern: /^1[3-9]\d{9}$/, message: '手机号格式不正确', trigger: 'blur' }
      ],
      name: [
        { required: true, message: '请输入姓名', trigger: 'blur' }
      ],
      password: [
        { required: true, message: '请输入密码', trigger: 'blur' },
        { min: 6, message: '密码长度至少6位', trigger: 'blur' }
      ],
      password_confirmation: [
        { required: true, message: '请确认密码', trigger: 'blur' },
        {
          validator: (rule, value, callback) => {
            if (value !== registerForm.password) {
              callback(new Error('两次密码输入不一致'))
            } else {
              callback()
            }
          },
          trigger: 'blur'
        }
      ]
    }
    
    const handleLogin = async () => {
      if (!loginFormRef.value) return
      
      try {
        await loginFormRef.value.validate()
        loading.value = true
        
        const response = await axios.post('/api/v1/login', {
          phone: loginForm.phone,
          password: loginForm.password
        })
        
        // 检查响应是否包含 data 字段
        if (response.data && response.data.data) {
          userStore.login(response.data.data.token, response.data.data.user)
          ElMessage.success('登录成功')
          router.push('/pc')
        } else {
          // 处理业务错误
          const errorMessage = response.data?.error || response.data?.message || '登录失败'
          ElMessage.error(errorMessage)
        }
      } catch (error) {
        console.error('登录失败', error)
        // 区分网络错误和业务错误
        if (error.response) {
          // 业务错误
          const errorMessage = error.response.data?.error || error.response.data?.message || '登录失败'
          ElMessage.error(errorMessage)
        } else if (error.request) {
          // 网络错误
          ElMessage.error('网络连接失败，请检查网络设置')
        } else {
          // 其他错误
          ElMessage.error('登录失败，请稍后重试')
        }
      } finally {
        loading.value = false
      }
    }
    
    const handleRegister = async () => {
      if (!registerFormRef.value) return
      
      try {
        await registerFormRef.value.validate()
        loading.value = true
        
        const response = await axios.post('/api/v1/register', registerForm)
        
        // 检查响应是否包含 data 字段
        if (response.data && response.data.data) {
          userStore.login(response.data.data.token, response.data.data.user)
          ElMessage.success(response.data.data.message || '注册成功')
          router.push('/pc')
        } else {
          // 处理业务错误
          const errorMessage = response.data?.error || response.data?.message || '注册失败'
          ElMessage.error(errorMessage)
        }
      } catch (error) {
        console.error('注册失败', error)
        // 区分网络错误和业务错误
        if (error.response) {
          // 业务错误
          const errorMessage = error.response.data?.error || error.response.data?.message || '注册失败'
          ElMessage.error(errorMessage)
        } else if (error.request) {
          // 网络错误
          ElMessage.error('网络连接失败，请检查网络设置')
        } else {
          // 其他错误
          ElMessage.error('注册失败，请稍后重试')
        }
      } finally {
        loading.value = false
      }
    }
    
    const handleTabChange = () => {
      // 切换标签时重置表单
      if (activeTab.value === 'login') {
        loginFormRef.value?.resetFields()
      } else {
        registerFormRef.value?.resetFields()
      }
    }
    
    return {
      activeTab,
      loginForm,
      registerForm,
      loginRules,
      registerRules,
      loginFormRef,
      registerFormRef,
      loading,
      handleLogin,
      handleRegister,
      handleTabChange
    }
  }
}
</script>

<style scoped>
.login-container {
  min-height: 100vh;
  display: flex;
  justify-content: center;
  align-items: center;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  padding: 20px;
}

.login-form {
  background: white;
  border-radius: 12px;
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
  padding: 40px;
  width: 100%;
  max-width: 450px;
  text-align: center;
}

.login-form h2 {
  color: #303133;
  margin-bottom: 30px;
  font-size: 24px;
  font-weight: bold;
}

.form-tabs {
  margin-top: 20px;
}

.login-btn {
  width: 100%;
  height: 48px;
  font-size: 16px;
  margin-top: 20px;
}

:deep(.el-form-item__label) {
  font-weight: 500;
  color: #303133;
}

:deep(.el-tabs__header) {
  margin-bottom: 30px;
}

:deep(.el-tabs__active-bar) {
  background-color: #409EFF;
}

:deep(.el-tabs__item.is-active) {
  color: #409EFF;
}
</style>
