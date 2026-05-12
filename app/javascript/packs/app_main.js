import { createApp, ref, reactive, h } from 'vue'

console.log('=== Main App Started ===')

try {
  const MainApp = {
    setup() {
      const currentUser = ref('测试用户')
      const currentTime = ref(new Date().toLocaleString('zh-CN'))
      const menuItems = reactive([
        { name: '包裹管理', icon: '📦', path: '/packages', active: false },
        { name: '异常管理', icon: '⚠️', path: '/exceptions', active: false },
        { name: '统计分析', icon: '📊', path: '/statistics', active: false },
        { name: 'AI助手', icon: '🤖', path: '/ai-assistant', active: false },
        { name: '系统设置', icon: '⚙️', path: '/settings', active: false }
      ])
      
      const activeMenu = ref('包裹管理')
      
      const selectMenu = (item) => {
        activeMenu.value = item.name
        console.log('Selected menu:', item.name)
      }
      
      console.log('=== Vue setup called ===')
      return { 
        currentUser, 
        currentTime,
        menuItems,
        activeMenu,
        selectMenu
      }
    },
    render() {
      const { currentUser, currentTime, menuItems, activeMenu, selectMenu } = this
      return h('div', { style: 'display:flex;height:100vh;background:#f5f7fa;' }, [
        // 侧边栏
        h('aside', { style: 'width:200px;background:#2f3542;color:white;display:flex;flex-direction:column;' }, [
          h('div', { style: 'padding:20px;text-align:center;border-bottom:1px solid #434a54;' }, [
            h('h1', { style: 'font-size:18px;margin:0;' }, '📦 菜鸟驿站')
          ]),
          h('nav', { style: 'flex:1;padding:10px;' }, [
            h('ul', { style: 'list-style:none;padding:0;margin:0;' }, [
              ...menuItems.map(item => 
                h('li', { style: 'margin-bottom:5px;' }, [
                  h('button', {
                    onClick: () => selectMenu(item),
                    style: `width:100%;padding:12px 15px;border:none;border-radius:4px;text-align:left;display:flex;align-items:center;gap:10px;font-size:14px;transition:all 0.2s;${activeMenu === item.name ? 'background:#409EFF;color:white;' : 'background:transparent;color:#b8c4d4;hover{background:#3a414d;}'}`
                  }, [
                    item.icon,
                    item.name
                  ])
                ])
              )
            ])
          ]),
          h('div', { style: 'padding:15px;border-top:1px solid #434a54;' }, [
            h('div', { style: 'display:flex;align-items:center;gap:10px;' }, [
              h('div', { style: 'width:36px;height:36px;border-radius:50%;background:#409EFF;display:flex;align-items:center;justify-content:center;font-size:16px;' }, currentUser[0]),
              h('div', { style: 'font-size:14px;' }, currentUser)
            ])
          ])
        ]),
        // 主内容区
        h('main', { style: 'flex:1;display:flex;flex-direction:column;' }, [
          // 顶部导航
          h('header', { style: 'height:60px;background:white;border-bottom:1px solid #e4e7ed;display:flex;align-items:center;justify-content:space-between;padding:0 20px;' }, [
            h('h2', { style: 'margin:0;font-size:18px;color:#303133;' }, activeMenu),
            h('span', { style: 'color:#909399;font-size:14px;' }, currentTime)
          ]),
          // 内容区域
          h('div', { style: 'flex:1;padding:20px;' }, [
            h('div', { style: 'background:white;border-radius:8px;box-shadow:0 2px 12px rgba(0,0,0,0.08);padding:24px;' }, [
              h('h3', { style: 'font-size:16px;color:#303133;margin-bottom:20px;' }, '欢迎使用菜鸟驿站包裹管理系统'),
              h('div', { style: 'display:grid;grid-template-columns:repeat(4,1fr);gap:20px;' }, [
                h('div', { style: 'background:#ecf5ff;border-radius:8px;padding:20px;text-align:center;' }, [
                  h('div', { style: 'font-size:32px;font-weight:bold;color:#409EFF;margin-bottom:8px;' }, '128'),
                  h('div', { style: 'font-size:14px;color:#606266;' }, '今日包裹')
                ]),
                h('div', { style: 'background:#f0f9eb;border-radius:8px;padding:20px;text-align:center;' }, [
                  h('div', { style: 'font-size:32px;font-weight:bold;color:#67c23a;margin-bottom:8px;' }, '25'),
                  h('div', { style: 'font-size:14px;color:#606266;' }, '待取件')
                ]),
                h('div', { style: 'background:#fff7e6;border-radius:8px;padding:20px;text-align:center;' }, [
                  h('div', { style: 'font-size:32px;font-weight:bold;color:#e6a23c;margin-bottom:8px;' }, '5'),
                  h('div', { style: 'font-size:14px;color:#606266;' }, '异常包裹')
                ]),
                h('div', { style: 'background:#fef0f0;border-radius:8px;padding:20px;text-align:center;' }, [
                  h('div', { style: 'font-size:32px;font-weight:bold;color:#f56c6c;margin-bottom:8px;' }, '3'),
                  h('div', { style: 'font-size:14px;color:#606266;' }, '超时未取')
                ])
              ]),
              h('div', { style: 'margin-top:24px;' }, [
                h('h4', { style: 'font-size:14px;color:#303133;margin-bottom:16px;' }, '快捷操作'),
                h('div', { style: 'display:flex;gap:15px;' }, [
                  h('button', {
                    style: 'padding:12px 24px;border:none;border-radius:4px;background:#409EFF;color:white;font-size:14px;cursor:pointer;transition:background 0.2s;hover{background:#67a5ff;}'
                  }, '📤 新增包裹'),
                  h('button', {
                    style: 'padding:12px 24px;border:none;border-radius:4px;background:#67c23a;color:white;font-size:14px;cursor:pointer;transition:background 0.2s;hover{background:#85ce61;}'
                  }, '🔍 OCR识别面单'),
                  h('button', {
                    style: 'padding:12px 24px;border:none;border-radius:4px;background:#e6a23c;color:white;font-size:14px;cursor:pointer;transition:background 0.2s;hover{background:#ebb563;}'
                  }, '📊 生成报表')
                ])
              ])
            ])
          ])
        ])
      ])
    }
  }

  const app = createApp(MainApp)
  console.log('=== Vue app created ===')
  
  app.mount('#app')
  console.log('=== Vue app mounted successfully ===')
} catch (error) {
  console.error('=== Vue initialization error ===', error)
  document.getElementById('app').innerHTML = '<h1 style="color:red;">Vue initialization failed!</h1><p>' + error.message + '</p>'
}