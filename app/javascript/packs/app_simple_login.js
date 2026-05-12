import { createApp, ref, reactive, h } from 'vue'

console.log('=== Simple Login App Started ===')

try {
  const LoginApp = {
    setup() {
      const activeTab = ref('login')
      const loading = ref(false)
      
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
      
      const handleLogin = () => {
        loading.value = true
        setTimeout(() => {
          alert('登录功能演示 - 手机号: ' + loginForm.phone)
          loading.value = false
        }, 1000)
      }
      
      const handleRegister = () => {
        loading.value = true
        setTimeout(() => {
          alert('注册功能演示 - 姓名: ' + registerForm.name)
          loading.value = false
        }, 1000)
      }
      
      console.log('=== Vue setup called ===')
      return { 
        activeTab, 
        loading, 
        loginForm, 
        registerForm,
        handleLogin,
        handleRegister
      }
    },
    render() {
      return h('div', { style: 'min-height:100vh;display:flex;justify-content:center;align-items:center;background:linear-gradient(135deg, #667eea 0%, #764ba2 100%);padding:20px;' }, [
        h('div', { style: 'background:white;border-radius:12px;box-shadow:0 8px 32px rgba(0,0,0,0.1);padding:40px;width:100%;max-width:450px;text-align:center;' }, [
          h('h2', { style: 'color:#303133;margin-bottom:30px;font-size:24px;font-weight:bold;' }, '菜鸟驿站包裹管理系统'),
          
          h('div', { style: 'display:flex;border-bottom:1px solid #e4e7ed;margin-bottom:30px;' }, [
            h('button', {
              onClick: () => this.activeTab = 'login',
              style: `flex:1;padding:12px;font-size:16px;border:none;background:none;cursor:pointer;color:${this.activeTab === 'login' ? '#409EFF' : '#606266'};border-bottom:2px solid ${this.activeTab === 'login' ? '#409EFF' : 'transparent'};`
            }, '登录'),
            h('button', {
              onClick: () => this.activeTab = 'register',
              style: `flex:1;padding:12px;font-size:16px;border:none;background:none;cursor:pointer;color:${this.activeTab === 'register' ? '#409EFF' : '#606266'};border-bottom:2px solid ${this.activeTab === 'register' ? '#409EFF' : 'transparent'};`
            }, '注册')
          ]),
          
          this.activeTab === 'login' ? h('div', { style: 'text-align:left;' }, [
            h('div', { style: 'margin-bottom:20px;' }, [
              h('label', { style: 'display:block;margin-bottom:8px;font-weight:500;color:#303133;' }, '手机号'),
              h('input', {
                type: 'text',
                value: this.loginForm.phone,
                onInput: e => this.loginForm.phone = e.target.value,
                placeholder: '请输入手机号',
                maxlength: 11,
                style: 'width:100%;padding:12px;border:1px solid #dcdfe6;border-radius:4px;font-size:14px;outline:none;transition:border-color 0.2s;'
              })
            ]),
            h('div', { style: 'margin-bottom:20px;' }, [
              h('label', { style: 'display:block;margin-bottom:8px;font-weight:500;color:#303133;' }, '密码'),
              h('input', {
                type: 'password',
                value: this.loginForm.password,
                onInput: e => this.loginForm.password = e.target.value,
                placeholder: '请输入密码',
                style: 'width:100%;padding:12px;border:1px solid #dcdfe6;border-radius:4px;font-size:14px;outline:none;transition:border-color 0.2s;'
              })
            ]),
            h('button', {
              onClick: this.handleLogin,
              disabled: this.loading,
              style: 'width:100%;height:48px;font-size:16px;border:none;border-radius:4px;background:#409EFF;color:white;cursor:pointer;margin-top:20px;transition:background 0.2s;' + (this.loading ? 'opacity:0.7;cursor:not-allowed;' : ':hover{background:#67a5ff;}')
            }, this.loading ? '登录中...' : '登录')
          ]) : h('div', { style: 'text-align:left;' }, [
            h('div', { style: 'margin-bottom:15px;' }, [
              h('label', { style: 'display:block;margin-bottom:8px;font-weight:500;color:#303133;' }, '手机号'),
              h('input', {
                type: 'text',
                value: this.registerForm.phone,
                onInput: e => this.registerForm.phone = e.target.value,
                placeholder: '请输入手机号',
                maxlength: 11,
                style: 'width:100%;padding:12px;border:1px solid #dcdfe6;border-radius:4px;font-size:14px;outline:none;transition:border-color 0.2s;'
              })
            ]),
            h('div', { style: 'margin-bottom:15px;' }, [
              h('label', { style: 'display:block;margin-bottom:8px;font-weight:500;color:#303133;' }, '姓名'),
              h('input', {
                type: 'text',
                value: this.registerForm.name,
                onInput: e => this.registerForm.name = e.target.value,
                placeholder: '请输入姓名',
                style: 'width:100%;padding:12px;border:1px solid #dcdfe6;border-radius:4px;font-size:14px;outline:none;transition:border-color 0.2s;'
              })
            ]),
            h('div', { style: 'margin-bottom:15px;' }, [
              h('label', { style: 'display:block;margin-bottom:8px;font-weight:500;color:#303133;' }, '工号（选填）'),
              h('input', {
                type: 'text',
                value: this.registerForm.employee_number,
                onInput: e => this.registerForm.employee_number = e.target.value,
                placeholder: '请输入工号',
                style: 'width:100%;padding:12px;border:1px solid #dcdfe6;border-radius:4px;font-size:14px;outline:none;transition:border-color 0.2s;'
              })
            ]),
            h('div', { style: 'margin-bottom:15px;' }, [
              h('label', { style: 'display:block;margin-bottom:8px;font-weight:500;color:#303133;' }, '密码'),
              h('input', {
                type: 'password',
                value: this.registerForm.password,
                onInput: e => this.registerForm.password = e.target.value,
                placeholder: '请输入密码（至少6位）',
                style: 'width:100%;padding:12px;border:1px solid #dcdfe6;border-radius:4px;font-size:14px;outline:none;transition:border-color 0.2s;'
              })
            ]),
            h('div', { style: 'margin-bottom:20px;' }, [
              h('label', { style: 'display:block;margin-bottom:8px;font-weight:500;color:#303133;' }, '确认密码'),
              h('input', {
                type: 'password',
                value: this.registerForm.password_confirmation,
                onInput: e => this.registerForm.password_confirmation = e.target.value,
                placeholder: '请再次输入密码',
                style: 'width:100%;padding:12px;border:1px solid #dcdfe6;border-radius:4px;font-size:14px;outline:none;transition:border-color 0.2s;'
              })
            ]),
            h('button', {
              onClick: this.handleRegister,
              disabled: this.loading,
              style: 'width:100%;height:48px;font-size:16px;border:none;border-radius:4px;background:#409EFF;color:white;cursor:pointer;margin-top:20px;transition:background 0.2s;' + (this.loading ? 'opacity:0.7;cursor:not-allowed;' : ':hover{background:#67a5ff;}')
            }, this.loading ? '注册中...' : '注册')
          ])
        ])
      ])
    }
  }

  const app = createApp(LoginApp)
  console.log('=== Vue app created ===')
  
  app.mount('#app')
  console.log('=== Vue app mounted successfully ===')
} catch (error) {
  console.error('=== Vue initialization error ===', error)
  document.getElementById('app').innerHTML = '<h1 style="color:red;">Vue initialization failed!</h1><p>' + error.message + '</p>'
}