import { createRouter, createWebHistory } from 'vue-router'

// 导入组件
const Login = () => import('../views/Login.vue')
const Dashboard = () => import('../views/pc/Dashboard.vue')
const PackageManagement = () => import('../views/pc/Packages.vue')
const ExceptionManagement = () => import('../views/pc/ExceptionManagement.vue')
const Statistics = () => import('../views/pc/Statistics.vue')
const AiAssistant = () => import('../views/pc/AiAssistant.vue')
const Settings = () => import('../views/pc/Settings.vue')

// 移动端组件
const MobileHome = () => import('../views/mobile/Home.vue')
const MobilePackages = () => import('../views/mobile/Packages.vue')
const MobileScan = () => import('../views/mobile/Scan.vue')
const MobileProfile = () => import('../views/mobile/Profile.vue')

const routes = [
  {
    path: '/',
    redirect: '/dashboard'
  },
  {
    path: '/pc',
    redirect: '/dashboard'
  },
  {
    path: '/login',
    name: 'Login',
    component: Login,
    meta: { requiresGuest: true }
  },
  // PC端路由
  {
    path: '/dashboard',
    name: 'Dashboard',
    component: Dashboard,
    meta: { requiresAuth: true, title: '系统仪表板' }
  },
  {
    path: '/packages',
    name: 'PackageManagement',
    component: PackageManagement,
    meta: { requiresAuth: true, title: '包裹管理' }
  },
  {
    path: '/exceptions',
    name: 'ExceptionManagement',
    component: ExceptionManagement,
    meta: { requiresAuth: true, requiresStaff: true, title: '异常管理' }
  },
  {
    path: '/statistics',
    name: 'Statistics',
    component: Statistics,
    meta: { requiresAuth: true, requiresStaff: true, title: '统计分析' }
  },
  {
    path: '/ai-assistant',
    name: 'AiAssistant',
    component: AiAssistant,
    meta: { requiresAuth: true, title: 'AI助手' }
  },
  {
    path: '/settings',
    name: 'Settings',
    component: Settings,
    meta: { requiresAuth: true, title: '系统设置' }
  },
  {
    path: '/pc/settings',
    name: 'PcSettings',
    component: Settings,
    meta: { requiresAuth: true, title: '系统设置' }
  },
  // 移动端路由
  {
    path: '/mobile',
    name: 'MobileHome',
    component: MobileHome,
    meta: { requiresAuth: true, isMobile: true, title: '首页' }
  },
  {
    path: '/mobile/packages',
    name: 'MobilePackages',
    component: MobilePackages,
    meta: { requiresAuth: true, isMobile: true, title: '我的包裹' }
  },
  {
    path: '/mobile/scan',
    name: 'MobileScan',
    component: MobileScan,
    meta: { requiresAuth: true, isMobile: true, title: '扫码取件' }
  },
  {
    path: '/mobile/profile',
    name: 'MobileProfile',
    component: MobileProfile,
    meta: { requiresAuth: true, isMobile: true, title: '个人中心' }
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

// 路由守卫
router.beforeEach((to, from, next) => {
  const token = localStorage.getItem('token')
  const userInfo = JSON.parse(localStorage.getItem('userInfo') || 'null') || {}
  
  // 设置页面标题
  if (to.meta.title) {
    document.title = `${to.meta.title} - 菜鸟驿站管理系统`
  }
  
  // 检查是否需要认证
  if (to.meta.requiresAuth && !token) {
    next('/login')
    return
  }
  
  // 检查是否需要工作人员权限
  if (to.meta.requiresStaff && !(userInfo.role === 'staff' || userInfo.role === 'admin')) {
    alert('只有工作人员可以访问此页面')
    next(from.path)
    return
  }
  
  // 如果已登录但访问登录页，重定向到首页
  if (to.meta.requiresGuest && token) {
    next('/dashboard')
    return
  }
  
  next()
})

// 路由错误处理
router.onError((error) => {
  console.error('路由错误:', error)
  // 可以在这里添加错误上报或用户提示
})

export default router