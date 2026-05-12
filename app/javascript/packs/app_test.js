import { createApp, ref } from 'vue'

console.log('=== Vue Test App Initialization Started ===')

try {
  const app = createApp({
    template: `
      <div style="text-align:center;margin-top:100px;">
        <h1>菜鸟驿站包裹管理系统</h1>
        <p style="color:green;">Vue is working!</p>
        <p>Count: {{ count }}</p>
        <button @click="count++">Increment</button>
      </div>
    `,
    setup() {
      const count = ref(0)
      console.log('=== Vue setup called ===')
      return { count }
    }
  })

  console.log('=== Vue app created ===')
  
  app.mount('#app')
  
  console.log('=== Vue app mounted successfully ===')
} catch (error) {
  console.error('=== Vue app initialization error ===', error)
}