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
import { useRouter, useRoute } from 'vue-router';
import { checkConnection } from './utils/web3'; 

const router = useRouter();
const route = useRoute();

const isLoggedIn = ref(false);
const currentUser = ref('');
const isChecking = ref(true); 

onMounted(async () => {
  const address = await checkConnection();
  
  if (address) {
    currentUser.value = address;
    isLoggedIn.value = true;

    if (route.path === '/index') {
      router.push('/');
    }
  } else {
    if (route.path !== '/index') {
      router.push('/index');
    }
  }
  isChecking.value = false;
});

const handleLogin = (address) => {
  currentUser.value = address;
  isLoggedIn.value = true;
  router.push('/');
};

const handleLogout = () => {
  isLoggedIn.value = false;
  currentUser.value = '';
  router.push('/index');
};

const goToBlogs = () => {
  router.push('/blogs');
};

const goToHome = () => {
  router.push('/');
};
</script>

<style>

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