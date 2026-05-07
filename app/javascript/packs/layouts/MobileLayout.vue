<template>
  <div class="mobile-layout">
    <header class="mobile-header">
      <h1>{{ currentTitle }}</h1>
    </header>
    
    <main class="mobile-main">
      <router-view />
    </main>
    
    <footer class="mobile-footer">
      <van-tabbar v-model="activeTab" route>
        <van-tabbar-item icon="home-o" to="/mobile/home">
          首页
        </van-tabbar-item>
        <van-tabbar-item icon="scan" to="/mobile/scan">
          扫码
        </van-tabbar-item>
        <van-tabbar-item icon="package" to="/mobile/packages">
          包裹
        </van-tabbar-item>
        <van-tabbar-item icon="user-o" to="/mobile/profile">
          我的
        </van-tabbar-item>
      </van-tabbar>
    </footer>
  </div>
</template>

<script>
import { ref, computed, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useUserStore } from '../stores/user'

export default {
  name: 'MobileLayout',
  setup() {
    const route = useRoute()
    const router = useRouter()
    const userStore = useUserStore()
    const activeTab = ref('/mobile/home')

    const currentTitle = computed(() => {
      const titleMap = {
        '/mobile/home': '首页',
        '/mobile/scan': '扫码',
        '/mobile/packages': '包裹',
        '/mobile/profile': '我的'
      }
      return titleMap[route.path] || '菜鸟驿站'
    })

    watch(route, (newRoute) => {
      activeTab.value = newRoute.path
    }, { immediate: true })

    return {
      activeTab,
      currentTitle,
      userStore
    }
  }
}
</script>

<style scoped>
.mobile-layout {
  display: flex;
  flex-direction: column;
  height: 100vh;
  overflow: hidden;
  background-color: #f5f5f5;
}

.mobile-header {
  height: 44px;
  background-color: #007bff;
  color: white;
  display: flex;
  align-items: center;
  justify-content: center;
  position: sticky;
  top: 0;
  z-index: 100;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

.mobile-header h1 {
  font-size: 16px;
  font-weight: bold;
  margin: 0;
}

.mobile-main {
  flex: 1;
  overflow-y: auto;
  padding: 10px;
}

.mobile-footer {
  height: 50px;
  border-top: 1px solid #e9ecef;
  background-color: white;
}
</style>
