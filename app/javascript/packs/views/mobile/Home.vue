<template>
  <div class="mobile-home">
    <!-- 顶部用户信息 -->
    <van-nav-bar 
      title="菜鸟驿站" 
      :border="false"
      :fixed="true"
      :placeholder="true"
    >
      <template #right>
        <van-icon name="user-o" size="18" @click="navigateTo('/mobile/profile')" />
      </template>
    </van-nav-bar>

    <!-- 用户欢迎区域 -->
    <van-card class="welcome-card">
      <div class="welcome-content">
        <van-image
          round
          width="60"
          height="60"
          src="https://fastly.jsdelivr.net/npm/@vant/assets/cat.jpeg"
          class="avatar"
        />
        <div class="user-info">
          <h3>欢迎回来，{{ userStore.userName || '用户' }}</h3>
          <p class="role">{{ formatRole(userStore.userRole) }}</p>
        </div>
      </div>
    </van-card>

    <!-- 快捷操作区域 -->
    <van-card class="quick-actions-card">
      <template #header>
        <div class="card-header">
          <van-icon name="apps-o" />
          <span>快捷操作</span>
        </div>
      </template>
      
      <div class="quick-actions-grid">
        <div class="action-item" @click="navigateTo('/mobile/scan')">
          <van-icon name="scan" size="24" color="#1989fa" />
          <span>扫码取件</span>
        </div>
        
        <div class="action-item" @click="navigateTo('/mobile/packages')">
          <van-icon name="package-o" size="24" color="#07c160" />
          <span>我的包裹</span>
        </div>
        
        <div class="action-item" @click="handleQueryPackage">
          <van-icon name="search" size="24" color="#ff976a" />
          <span>包裹查询</span>
        </div>
        
        <div class="action-item" @click="handleReportException">
          <van-icon name="warning-o" size="24" color="#ee0a24" />
          <span>异常上报</span>
        </div>
      </div>
    </van-card>

    <!-- 今日统计 -->
    <van-card class="stats-card">
      <template #header>
        <div class="card-header">
          <van-icon name="chart-trending-o" />
          <span>今日概览</span>
        </div>
      </template>
      
      <div class="stats-grid">
        <div class="stat-item">
          <div class="stat-value">{{ todayStats.stored || 0 }}</div>
          <div class="stat-label">入库包裹</div>
        </div>
        <div class="stat-item">
          <div class="stat-value">{{ todayStats.pickedUp || 0 }}</div>
          <div class="stat-label">出库包裹</div>
        </div>
        <div class="stat-item">
          <div class="stat-value">{{ todayStats.exceptions || 0 }}</div>
          <div class="stat-label">异常处理</div>
        </div>
        <div class="stat-item">
          <div class="stat-value">{{ todayStats.customers || 0 }}</div>
          <div class="stat-label">服务客户</div>
        </div>
      </div>
    </van-card>

    <!-- 通知公告 -->
    <van-card class="notice-card" v-if="notices.length > 0">
      <template #header>
        <div class="card-header">
          <van-icon name="volume-o" />
          <span>系统公告</span>
        </div>
      </template>
      
      <van-notice-bar
        left-icon="info-o"
        :text="notices[0]"
        background="#ecf9ff"
        color="#1989fa"
      />
    </van-card>

    <!-- 底部导航 -->
    <van-tabbar v-model="activeTab" :fixed="true">
      <van-tabbar-item name="home" icon="home-o" @click="navigateTo('/mobile')">首页</van-tabbar-item>
      <van-tabbar-item name="packages" icon="package-o" @click="navigateTo('/mobile/packages')">包裹</van-tabbar-item>
      <van-tabbar-item name="scan" icon="scan" @click="navigateTo('/mobile/scan')">扫码</van-tabbar-item>
      <van-tabbar-item name="profile" icon="user-o" @click="navigateTo('/mobile/profile')">我的</van-tabbar-item>
    </van-tabbar>

    <!-- 包裹查询弹窗 -->
    <van-popup v-model:show="showQueryDialog" round position="bottom">
      <div class="query-dialog">
        <van-nav-bar 
          title="包裹查询"
          left-text="取消"
          right-text="查询"
          @click-left="showQueryDialog = false"
          @click-right="handleQuery"
        />
        
        <div class="dialog-content">
          <van-field
            v-model="queryTrackingNumber"
            label="运单号"
            placeholder="请输入运单号"
            clearable
          />
          <van-field
            v-model="queryPhone"
            label="手机号"
            placeholder="请输入手机号"
            clearable
          />
        </div>
      </div>
    </van-popup>
  </div>
</template>

<script>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useStore } from '../../stores/user'
import { 
  NavBar, Card, Button, Icon, Image, Tabbar, TabbarItem, 
  NoticeBar, Popup, Field, Toast, Dialog 
} from 'vant'

export default {
  name: 'MobileHome',
  components: {
    [NavBar.name]: NavBar,
    [Card.name]: Card,
    [Button.name]: Button,
    [Icon.name]: Icon,
    [Image.name]: Image,
    [Tabbar.name]: Tabbar,
    [TabbarItem.name]: TabbarItem,
    [NoticeBar.name]: NoticeBar,
    [Popup.name]: Popup,
    [Field.name]: Field
  },
  setup() {
    const router = useRouter()
    const userStore = useStore()
    
    const activeTab = ref('home')
    const todayStats = ref({})
    const notices = ref([
      '系统已升级至最新版本，优化了扫码取件体验',
      '新增异常上报功能，欢迎使用反馈'
    ])
    
    // 查询相关
    const showQueryDialog = ref(false)
    const queryTrackingNumber = ref('')
    const queryPhone = ref('')

    // 格式化角色显示
    const formatRole = (role) => {
      const roles = {
        'customer': '客户',
        'staff': '工作人员',
        'admin': '管理员'
      }
      return roles[role] || '用户'
    }

    // 导航方法
    const navigateTo = (path) => {
      router.push(path)
    }

    // 处理包裹查询
    const handleQueryPackage = () => {
      showQueryDialog.value = true
    }

    // 执行查询
    const handleQuery = async () => {
      if (!queryTrackingNumber.value && !queryPhone.value) {
        Toast('请输入运单号或手机号')
        return
      }

      try {
        // 这里调用API查询包裹信息
        Toast.loading({
          message: '查询中...',
          forbidClick: true,
          duration: 0
        })

        // 模拟API调用
        setTimeout(() => {
          Toast.clear()
          showQueryDialog.value = false
          
          // 显示查询结果
          Dialog.alert({
            title: '查询结果',
            message: `包裹状态：已入库\n取件码：04126958\n存储位置：A区5号架`
          })
        }, 1000)

      } catch (error) {
        Toast.clear()
        Toast('查询失败，请重试')
      }
    }

    // 处理异常上报
    const handleReportException = () => {
      Dialog.confirm({
        title: '异常上报',
        message: '请确认是否要上报异常？'
      }).then(() => {
        router.push('/exceptions')
      })
    }

    // 获取今日统计数据
    const fetchTodayStats = async () => {
      try {
        // 模拟API调用
        todayStats.value = {
          stored: 15,
          pickedUp: 12,
          exceptions: 2,
          customers: 8
        }
      } catch (error) {
        console.error('获取统计数据失败:', error)
      }
    }

    onMounted(() => {
      fetchTodayStats()
    })

    return {
      userStore,
      activeTab,
      todayStats,
      notices,
      showQueryDialog,
      queryTrackingNumber,
      queryPhone,
      formatRole,
      navigateTo,
      handleQueryPackage,
      handleQuery,
      handleReportException
    }
  }
}
</script>

<style scoped>
.mobile-home {
  padding: 12px;
  padding-bottom: 60px; /* 为底部导航留出空间 */
  background: #f7f8fa;
  min-height: 100vh;
}

.welcome-card {
  margin-bottom: 12px;
  border-radius: 12px;
}

.welcome-content {
  display: flex;
  align-items: center;
  padding: 16px;
}

.avatar {
  margin-right: 16px;
}

.user-info h3 {
  margin: 0 0 4px 0;
  font-size: 18px;
  color: #323233;
}

.role {
  margin: 0;
  font-size: 14px;
  color: #969799;
}

.quick-actions-card,
.stats-card,
.notice-card {
  margin-bottom: 12px;
  border-radius: 12px;
}

.card-header {
  display: flex;
  align-items: center;
  font-weight: 600;
  color: #323233;
}

.card-header .van-icon {
  margin-right: 8px;
}

.quick-actions-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
  padding: 16px;
}

.action-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 20px 12px;
  background: #fff;
  border-radius: 8px;
  border: 1px solid #ebedf0;
  cursor: pointer;
  transition: all 0.3s;
}

.action-item:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0,0,0,0.1);
}

.action-item span {
  margin-top: 8px;
  font-size: 14px;
  color: #646566;
}

.stats-grid {
  display: grid;
  grid-template-columns: 1fr 1fr 1fr 1fr;
  gap: 12px;
  padding: 16px;
}

.stat-item {
  text-align: center;
  padding: 12px;
  background: #f7f8fa;
  border-radius: 8px;
}

.stat-value {
  font-size: 20px;
  font-weight: 600;
  color: #1989fa;
  margin-bottom: 4px;
}

.stat-label {
  font-size: 12px;
  color: #969799;
}

.query-dialog {
  background: #fff;
  border-radius: 20px 20px 0 0;
}

.dialog-content {
  padding: 20px;
}

/* 响应式设计 */
@media (max-width: 320px) {
  .quick-actions-grid {
    grid-template-columns: 1fr;
  }
  
  .stats-grid {
    grid-template-columns: 1fr 1fr;
  }
}
</style>