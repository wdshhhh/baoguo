import { createApp, ref } from 'vue'

console.log('=== Vue App Initialization Started ===')

const app = createApp({
  template: `
    <div style="text-align:center;margin-top:100px;">
      <h1>菜鸟驿站包裹管理系统</h1>
      <p>Vue is working!</p>
      <p>Count: {{ count }}</p>
      <button @click="count++">Increment</button>
    </div>
  `,
  setup() {
    const count = ref(0)
    return { count }
  }
})

app.mount('#app')
console.log('=== Vue App Mounted Successfully ===')