<template>
  <div class="pc-layout">
    <header class="pc-header">
      <div class="header-left">
        <h1>菜鸟驿站包裹管理系统</h1>
      </div>
      <div class="header-right">
        <el-dropdown>
          <span class="user-info">
            {{ userStore.userName }}
            <el-icon><Avatar /></el-icon>
          </span>
          <template #dropdown>
            <el-dropdown-menu>
              <el-dropdown-item @click="handleLogout">退出登录</el-dropdown-item>
            </el-dropdown-menu>
          </template>
        </el-dropdown>
      </div>
    </header>
    
    <div class="pc-body">
      <aside class="pc-sidebar">
        <el-menu
          :default-active="activeMenu"
          class="el-menu-vertical"
          @select="handleMenuSelect"
        >
          <el-menu-item index="/pc/dashboard">
            <el-icon><House /></el-icon>
            <span>控制台</span>
          </el-menu-item>
          <el-menu-item index="/pc/packages">
            <el-icon><Package /></el-icon>
            <span>包裹管理</span>
          </el-menu-item>
          <el-menu-item index="/pc/exceptions">
            <el-icon><Warning /></el-icon>
            <span>异常处理</span>
          </el-menu-item>
          <el-menu-item index="/pc/statistics">
            <el-icon><DataAnalysis /></el-icon>
            <span>数据统计</span>
          </el-menu-item>
          <el-sub-menu index="/ai">
            <template #title>
              <el-icon><ChatDotRound /></el-icon>
              <span>AI智能助手</span>
            </template>
            <el-menu-item index="/pc/ai-dashboard">
              <span>AI功能中心</span>
            </el-menu-item>
            <el-menu-item index="/pc/ai-assistant">
              <span>智能对话助手</span>
            </el-menu-item>
          </el-sub-menu>
          <el-menu-item v-if="userStore.isAdmin" index="/pc/settings">
            <el-icon><Setting /></el-icon>
            <span>系统设置</span>
          </el-menu-item>
        </el-menu>
      </aside>
      
      <main class="pc-main">
        <router-view />
      </main>
    </div>
  </div>
</template>

<script>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useUserStore } from '../stores/user'
import { House, Package, Warning, DataAnalysis, Setting, Avatar, ChatDotRound } from '@element-plus/icons-vue'

export default {
  name: 'PCLayout',
  setup() {
    const router = useRouter()
    const userStore = useUserStore()
    const activeMenu = ref('/pc/dashboard')

    const handleMenuSelect = (key) => {
      router.push(key)
    }

    const handleLogout = async () => {
      await userStore.logout()
      router.push('/login')
    }

    onMounted(() => {
      activeMenu.value = router.currentRoute.value.path
    })

    return {
      userStore,
      activeMenu,
      handleMenuSelect,
      handleLogout
    }
  }
}
</script>

<style scoped>
.pc-layout {
  display: flex;
  flex-direction: column;
  height: 100vh;
  overflow: hidden;
}

.pc-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0 20px;
  height: 60px;
  background-color: #007bff;
  color: white;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

.header-left h1 {
  font-size: 18px;
  font-weight: bold;
  margin: 0;
}

.user-info {
  display: flex;
  align-items: center;
  gap: 8px;
  cursor: pointer;
}

.pc-body {
  display: flex;
  flex: 1;
  overflow: hidden;
}

.pc-sidebar {
  width: 200px;
  background-color: #f8f9fa;
  border-right: 1px solid #e9ecef;
  overflow-y: auto;
}

.pc-main {
  flex: 1;
  padding: 20px;
  overflow-y: auto;
  background-color: #f5f5f5;
}

.el-menu-vertical {
  border-right: none;
}

.el-menu-item.is-active {
  background-color: #e6f2ff !important;
  color: #007bff !important;
}
</style>
