<template>
  <div v-if="isChecking" class="loading-screen">
    <div class="loader"></div>
    <p>正在同步区块链数据...</p>
  </div>

  <LandingView v-else-if="!isLoggedIn" @login-success="handleLogin" />
  
  <DashboardView v-else :userAddress="currentUser" @logout="handleLogout" />
</template>

<script setup>
import { ref, onMounted } from 'vue';
import LandingView from './views/LandingView.vue';
import DashboardView from './views/DashboardView.vue';
import { checkConnection } from './utils/web3'; // 引入静默检查函数

const isLoggedIn = ref(false);
const currentUser = ref('');
const isChecking = ref(true); // 默认一开始处于检查中状态

// 组件挂载时，自动检查 MetaMask 状态
onMounted(async () => {
  const address = await checkConnection();
  
  if (address) {
    // 如果之前连过，直接恢复状态
    currentUser.value = address;
    isLoggedIn.value = true;
  }
  
  // 检查完毕，关闭过渡动画
  isChecking.value = false;
});

const handleLogin = (address) => {
  currentUser.value = address;
  isLoggedIn.value = true;
};

const handleLogout = () => {
  isLoggedIn.value = false;
  currentUser.value = '';
};
</script>

<style>
* { box-sizing: border-box; margin: 0; padding: 0; }
body { font-family: 'Helvetica Neue', Arial, sans-serif; background-color: #f8fafc; color: #0f172a; }

/* 过渡动画层的样式 */
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