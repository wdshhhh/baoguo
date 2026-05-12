import { createApp, ref, h } from 'vue'

console.log('=== Basic Vue App Started ===')

try {
  const App = {
    setup() {
      const message = ref('菜鸟驿站包裹管理系统')
      const count = ref(0)
      console.log('=== Vue setup called ===')
      return { message, count }
    },
    render() {
      return h('div', { style: 'text-align:center;margin-top:100px;' }, [
        h('h1', this.message),
        h('p', { style: 'color:green;font-size:24px;' }, 'Vue is working!'),
        h('p', `Count: ${this.count}`),
        h('button', { 
          onClick: () => this.count++,
          style: 'padding:10px 20px;font-size:16px;'
        }, 'Increment')
      ])
    }
  }

  const app = createApp(App)
  console.log('=== Vue app created ===')
  
  app.mount('#app')
  console.log('=== Vue app mounted successfully ===')
} catch (error) {
  console.error('=== Vue initialization error ===', error)
  document.getElementById('app').innerHTML = '<h1 style="color:red;">Vue initialization failed!</h1><p>' + error.message + '</p>'
}