import { createApp, ref } from 'vue'

console.log('=== DEBUG Vue App Started ===')

try {
  const app = createApp({
    template: `
      <div style="text-align:center;margin-top:100px;">
        <h1>菜鸟驿站包裹管理系统</h1>
        <p style="color:green;font-size:24px;">Vue is working!</p>
        <p>Count: {{ count }}</p>
        <button @click="count++" style="padding:10px 20px;">Increment</button>
      </div>
    `,
    setup() {
      const count = ref(0)
      console.log('=== Vue setup called ===')
      return { count }
    }
  })

  app.mount('#app')
  console.log('=== Vue app mounted successfully ===')
} catch (error) {
  console.error('=== Vue initialization error ===', error)
  document.getElementById('app').innerHTML = '<h1 style="color:red;">Vue initialization failed!</h1><p>' + error.message + '</p>'
}