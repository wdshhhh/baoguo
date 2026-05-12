import { createApp } from 'vue'
import { createPinia } from 'pinia'
import router from './router/index'
import App from './App.vue'

// 引入 Element Plus
import ElementPlus from 'element-plus'
import 'element-plus/dist/index.css'
import * as ElementPlusIconsVue from '@element-plus/icons-vue'

// 引入 Vant
import Vant from 'vant'
import 'vant/lib/index.css'

// 引入 Axios
import axios from 'axios'

// 创建应用
const app = createApp(App)

// 注册 Element Plus 图标
for (const [key, component] of Object.entries(ElementPlusIconsVue)) {
  app.component(key, component)
}

// 配置 Axios
axios.defaults.baseURL = ''
axios.interceptors.request.use(config => {
  const token = localStorage.getItem('token')
  
  // 对于登录接口，不需要添加token
  if (config.url && config.url.includes('/api/v1/login')) {
    return config
  }
  
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  
  return config
})

axios.interceptors.response.use(
  response => response,
  error => {
    if (error.response?.status === 401) {
      localStorage.removeItem('token')
      router.push('/login')
    }
    return Promise.reject(error)
  }
)

app.config.globalProperties.$axios = axios

// 使用插件
app.use(createPinia())
app.use(router)
app.use(ElementPlus)
app.use(Vant)

app.mount('#app')
