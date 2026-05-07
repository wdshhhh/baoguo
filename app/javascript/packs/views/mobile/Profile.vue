<template>
  <div class="profile">
    <div class="profile-container">
      <div class="profile-header">
        <div class="user-info">
          <div class="avatar">
            <van-icon name="user-circle" size="60" />
          </div>
          <div class="user-details">
            <h2>{{ user.username }}</h2>
            <p>{{ user.phone }}</p>
            <span class="user-role">
              <van-tag :type="user.role === 'admin' ? 'danger' : user.role === 'staff' ? 'primary' : 'info'">
                {{ user.role === 'admin' ? '管理员' : user.role === 'staff' ? '工作人员' : '普通用户' }}
              </van-tag>
            </span>
          </div>
        </div>
      </div>
      
      <div class="profile-menu">
        <van-cell-group>
          <van-cell title="个人信息" is-link @click="editProfile">
            <template #right-icon>
              <van-icon name="chevron-right" />
            </template>
          </van-cell>
          <van-cell title="修改密码" is-link @click="changePassword">
            <template #right-icon>
              <van-icon name="chevron-right" />
            </template>
          </van-cell>
          <van-cell title="系统设置" is-link @click="systemSettings">
            <template #right-icon>
              <van-icon name="chevron-right" />
            </template>
          </van-cell>
          <van-cell title="关于我们" is-link @click="about">
            <template #right-icon>
              <van-icon name="chevron-right" />
            </template>
          </van-cell>
        </van-cell-group>
      </div>
      
      <div class="profile-actions">
        <van-button type="danger" block @click="logout">
          退出登录
        </van-button>
      </div>
      
      <div class="profile-footer">
        <p>版本: {{ version }}</p>
      </div>
    </div>
    
    <!-- 修改密码对话框 -->
    <van-dialog v-model:show="changePasswordDialogVisible" title="修改密码">
      <van-field
        v-model="oldPassword"
        type="password"
        label="旧密码"
        placeholder="请输入旧密码"
      />
      <van-field
        v-model="newPassword"
        type="password"
        label="新密码"
        placeholder="请输入新密码"
      />
      <van-field
        v-model="confirmPassword"
        type="password"
        label="确认密码"
        placeholder="请再次输入新密码"
      />
      <template #footer>
        <button class="van-dialog__footer__button" @click="changePasswordDialogVisible = false">
          取消
        </button>
        <button class="van-dialog__footer__button van-dialog__footer__button--primary" @click="submitChangePassword">
          确认
        </button>
      </template>
    </van-dialog>
  </div>
</template>

<script>
import { ref, onMounted } from 'vue'
import { useUserStore } from '../../stores/user'
import { useRouter } from 'vue-router'

export default {
  name: 'Profile',
  setup() {
    const userStore = useUserStore()
    const router = useRouter()
    const user = ref({
      username: 'admin',
      phone: '13800138000',
      role: 'admin'
    })
    const version = ref('1.0.0')
    const changePasswordDialogVisible = ref(false)
    const oldPassword = ref('')
    const newPassword = ref('')
    const confirmPassword = ref('')
    
    const editProfile = () => {
      // 实现编辑个人信息功能
      console.log('编辑个人信息')
    }
    
    const changePassword = () => {
      changePasswordDialogVisible.value = true
    }
    
    const submitChangePassword = () => {
      // 实现修改密码功能
      console.log('修改密码')
      changePasswordDialogVisible.value = false
    }
    
    const systemSettings = () => {
      // 实现系统设置功能
      console.log('系统设置')
    }
    
    const about = () => {
      // 实现关于我们功能
      console.log('关于我们')
    }
    
    const logout = () => {
      // 实现退出登录功能
      userStore.logout()
      router.push('/login')
    }
    
    onMounted(() => {
      // 加载用户信息
      console.log('加载用户信息')
    })
    
    return {
      user,
      version,
      changePasswordDialogVisible,
      oldPassword,
      newPassword,
      confirmPassword,
      editProfile,
      changePassword,
      submitChangePassword,
      systemSettings,
      about,
      logout
    }
  }
}
</script>

<style scoped>
.profile {
  padding: 0;
}

.profile-container {
  min-height: 100vh;
  padding: 20px;
}

.profile-header {
  background: linear-gradient(135deg, #007bff 0%, #0056b3 100%);
  border-radius: 12px;
  padding: 30px 20px;
  margin-bottom: 30px;
  color: white;
}

.user-info {
  display: flex;
  align-items: center;
}

.avatar {
  margin-right: 20px;
}

.user-details h2 {
  font-size: 20px;
  font-weight: bold;
  margin-bottom: 5px;
}

.user-details p {
  font-size: 14px;
  opacity: 0.9;
  margin-bottom: 10px;
}

.user-role {
  display: inline-block;
}

.profile-menu {
  margin-bottom: 30px;
}

.profile-actions {
  margin-bottom: 30px;
}

.profile-footer {
  text-align: center;
  color: #999;
  font-size: 12px;
}
</style>
