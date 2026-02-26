<template>
  <div v-if="isChecking" class="loading-screen">
    <div class="loader"></div>
    <p>正在同步区块链数据...</p>
  </div>

  <router-view 
    v-else
    :userAddress="currentUser" 
    @login-success="handleLogin"
    @logout="handleLogout"
    @go-to-explore="goToBlogs"
    @go-back="goToHome"
  />
</template>

<script setup>
import { ref, onMounted } from 'vue';
import { useRouter, useRoute } from 'vue-router'; // 引入路由相关的方法
import { checkConnection } from './utils/web3'; 

const router = useRouter(); // 用于执行跳转，如 router.push()
const route = useRoute();   // 用于获取当前 URL 信息

const isLoggedIn = ref(false);
const currentUser = ref('');
const isChecking = ref(true); 

// 组件挂载时，自动检查 MetaMask 状态
onMounted(async () => {
  const address = await checkConnection();
  
  if (address) {
    // 已经连接过钱包
    currentUser.value = address;
    isLoggedIn.value = true;
    
    // 如果当前在登录页，自动跳回首页
    if (route.path === '/index') {
      router.push('/');
    }
  } else {
    // 未登录，强制跳转到登录页
    if (route.path !== '/index') {
      router.push('/index');
    }
  }
  
  // 检查完毕，关闭过渡动画
  isChecking.value = false;
});

const handleLogin = (address) => {
  currentUser.value = address;
  isLoggedIn.value = true;
  router.push('/'); // 登录成功后跳转到首页
};

const handleLogout = () => {
  isLoggedIn.value = false;
  currentUser.value = '';
  router.push('/index'); // 退出登录后跳转到登录页
};

const goToBlogs = () => {
  router.push('/blogs'); // 导航到博客列表页
};

const goToHome = () => {
  router.push('/'); // 导航回首页
};
</script>

<style>
/* CSS 保持你原来的不变即可 */
* { box-sizing: border-box; margin: 0; padding: 0; }
body { font-family: 'Helvetica Neue', Arial, sans-serif; background-color: #f8fafc; color: #0f172a; }

.loading-screen {
  position: fixed;
  top: 0; left: 0; width: 100vw; height: 100vh;
  background-color: #0f172a;
  color: white;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  z-index: 9999;
}

.loader {
  border: 4px solid rgba(255,255,255,0.1);
  border-left-color: #8b5cf6;
  border-radius: 50%;
  width: 40px;
  height: 40px;
  animation: spin 1s linear infinite;
  margin-bottom: 20px;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}
</style>