// src/main.js
import { createApp } from 'vue'
import './style.css'
import App from './App.vue'
import router from './router' // 引入刚刚创建的路由

const app = createApp(App)

app.use(router) // 注册路由插件
app.mount('#app')