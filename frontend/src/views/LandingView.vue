<template>
  <div class="landing-container">
    <div class="carousel">
      <div 
        v-for="(img, index) in images" 
        :key="index"
        class="carousel-slide"
        :class="{ active: currentIndex === index }"
        :style="{ backgroundImage: `url(${img})` }"
      ></div>
      <div class="overlay"></div> </div>

    <div class="center-content">
      <h1 class="title">Share Blog</h1>
      <p class="subtitle">你的去中心化博客</p>
      
      <button class="enter-btn" @click="handleEnter" :disabled="isConnecting">
        {{ isConnecting ? '连接中...' : '开始探索' }}
      </button>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue';
import { initWeb3 } from '../utils/web3';
const emit = defineEmits(['login-success']);

const isConnecting = ref(false);

const images = [
  'https://images.unsplash.com/photo-1639762681485-074b7f938ba0?q=80&w=2832&auto=format&fit=crop',
  'https://images.unsplash.com/photo-1642104704074-907c0698cbd9?q=80&w=2832&auto=format&fit=crop',
  'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?q=80&w=2564&auto=format&fit=crop'
];
const currentIndex = ref(0);
let timer = null;

onMounted(() => {
  timer = setInterval(() => {
    currentIndex.value = (currentIndex.value + 1) % images.length;
  }, 4000);
});

onUnmounted(() => {
  clearInterval(timer);
});
const handleEnter = async () => {
  try {
    isConnecting.value = true;
    const { signer } = await initWeb3();
    const address = await signer.getAddress();
    emit('login-success', address);
  } catch (error) {
    console.error("连接钱包失败", error);
  } finally {
    isConnecting.value = false;
  }
};
</script>

<style scoped>
.landing-container {
  position: relative;
  width: 100vw;
  height: 100vh;
  overflow: hidden;
  display: flex;
  justify-content: center;
  align-items: center;
}

.carousel {
  position: absolute;
  top: 0; left: 0; width: 100%; height: 100%;
  z-index: 1;
}

.carousel-slide {
  position: absolute;
  top: 0; left: 0; width: 100%; height: 100%;
  background-size: cover;
  background-position: center;
  opacity: 0;
  transition: opacity 1.5s ease-in-out;
}

.carousel-slide.active { opacity: 1; }

.overlay {
  position: absolute;
  top: 0; left: 0; width: 100%; height: 100%;
  background: rgba(0, 0, 0, 0.6);
}

.center-content {
  position: relative;
  z-index: 10;
  text-align: center;
  color: white;
  animation: fadeIn 2s ease-out;
}

.title { font-size: 3.5rem; margin-bottom: 10px; font-weight: 800; letter-spacing: 2px;}
.subtitle { font-size: 1.2rem; margin-bottom: 40px; color: #cbd5e1; }

.enter-btn {
  padding: 15px 40px;
  font-size: 1.2rem;
  font-weight: bold;
  color: white;
  background: linear-gradient(135deg, #6366f1, #8b5cf6);
  border: none;
  border-radius: 50px;
  cursor: pointer;
  box-shadow: 0 4px 15px rgba(139, 92, 246, 0.4);
  transition: transform 0.2s, box-shadow 0.2s;
}

.enter-btn:hover {
  transform: translateY(-3px) scale(1.05);
  box-shadow: 0 6px 20px rgba(139, 92, 246, 0.6);
}

@keyframes fadeIn {
  from { opacity: 0; transform: translateY(20px); }
  to { opacity: 1; transform: translateY(0); }
}
</style>

