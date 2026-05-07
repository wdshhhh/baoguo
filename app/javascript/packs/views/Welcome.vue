<template>
  <div class="welcome-container">
    <header class="welcome-header">
      <h1>菜鸟驿站包裹管理系统</h1>
      <p>基于 Ruby on Rails + Vue.js 构建的现代化包裹管理解决方案</p>
    </header>
    
    <main class="welcome-main">
      <div class="welcome-cards">
        <div class="welcome-card">
          <div class="card-icon">
            <el-icon :size="48"><Monitor /></el-icon>
          </div>
          <h2>PC 端管理</h2>
          <p>完整的包裹管理功能，包括入库、出库、查询、统计等操作，适合驿站工作人员使用。</p>
          <el-button type="primary" @click="navigateTo('/pc')">
            进入 PC 端
          </el-button>
        </div>
        
        <div class="welcome-card">
          <div class="card-icon">
            <el-icon :size="48"><SmartPhone /></el-icon>
          </div>
          <h2>移动端操作</h2>
          <p>便捷的移动操作，支持扫码出库、包裹查询、异常处理等功能，随时随地管理包裹。</p>
          <el-button type="info" @click="navigateTo('/mobile')">
            进入移动端
          </el-button>
        </div>
        
        <div class="welcome-card">
          <div class="card-icon">
            <el-icon :size="48"><Link /></el-icon>
          </div>
          <h2>API 接口</h2>
          <p>完整的 RESTful API，支持第三方系统集成，为驿站提供更多扩展可能性。</p>
          <el-button type="success" @click="navigateTo('/api/v1')">
            API 文档
          </el-button>
        </div>
      </div>
    </main>
    
    <footer class="welcome-footer">
      <p>&copy; 2026 菜鸟驿站包裹管理系统 - 基于 Ruby on Rails 8.1.1 和 Vue.js 3 构建</p>
    </footer>
  </div>
</template>

<script>
import { Monitor, SmartPhone, Link } from '@element-plus/icons-vue'
import { useRouter } from 'vue-router'

export default {
  name: 'Welcome',
  setup() {
    const router = useRouter()
    
    const navigateTo = (path) => {
      router.push(path)
    }
    
    return {
      navigateTo
    }
  }
}
</script>

<style scoped>
.welcome-container {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  background-color: #f5f5f5;
}

.welcome-header {
  background: linear-gradient(135deg, #007bff 0%, #0056b3 100%);
  color: white;
  padding: 60px 20px;
  text-align: center;
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
}

.welcome-header h1 {
  font-size: 36px;
  font-weight: bold;
  margin-bottom: 15px;
}

.welcome-header p {
  font-size: 18px;
  opacity: 0.9;
  margin: 0;
}

.welcome-main {
  flex: 1;
  padding: 60px 20px;
  max-width: 1200px;
  margin: 0 auto;
  width: 100%;
}

.welcome-cards {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 30px;
}

.welcome-card {
  background-color: white;
  border-radius: 12px;
  padding: 40px 30px;
  text-align: center;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
  transition: transform 0.3s ease, box-shadow 0.3s ease;
}

.welcome-card:hover {
  transform: translateY(-10px);
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.15);
}

.card-icon {
  margin-bottom: 20px;
  color: #007bff;
}

.welcome-card h2 {
  font-size: 24px;
  font-weight: bold;
  margin-bottom: 15px;
  color: #333;
}

.welcome-card p {
  color: #666;
  line-height: 1.6;
  margin-bottom: 30px;
}

.welcome-footer {
  background-color: #f8f9fa;
  padding: 30px 20px;
  text-align: center;
  color: #666;
  font-size: 14px;
  border-top: 1px solid #e9ecef;
}

@media (max-width: 768px) {
  .welcome-header {
    padding: 40px 20px;
  }
  
  .welcome-header h1 {
    font-size: 28px;
  }
  
  .welcome-main {
    padding: 40px 20px;
  }
  
  .welcome-card {
    padding: 30px 20px;
  }
}
</style>
