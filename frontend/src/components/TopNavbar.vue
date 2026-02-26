<template>
  <header class="top-navbar animate__animated animate__fadeInDown">
    <div class="nav-left">
      <nav class="nav-links">
        <a href="#" class="active">博客</a>
        <a href="#" @click.prevent="$emit('go-to-explore')">探索</a>
        <a href="#">订阅</a>
        <a href="#">相册</a>
      </nav>
    </div>

    <div class="nav-right">
      <button class="icon-btn" title="写博客">✍️</button>
      <button class="icon-btn" title="消息通知">🔔</button>
      
      <div class="nav-avatar-container">
        <div class="nav-avatar-wrapper" @click="toggleDropdown">
          <img class="nav-avatar" :src="userAvatar" alt="avatar" />
        </div>
        
        <transition name="dropdown-fade">
          <div v-show="showDropdown" class="avatar-dropdown">
            <div class="dropdown-item logout-item" @click="handleLogout">
              🚪 退出登录
            </div>
          </div>
        </transition>
      </div>
    </div>
  </header>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue';

// 定义需要抛出给父组件的事件
const emit = defineEmits(['logout', 'go-to-explore']);

// 静态头像（后续可以改为从 props 或全局 store 传入）
const userAvatar = ref('https://images.cnblogs.com/cnblogs_com/blogs/784559/galleries/2387286/o_240325050905_tx.png');

// ==== 下拉菜单逻辑 ====
const showDropdown = ref(false);

const toggleDropdown = (e) => {
  showDropdown.value = !showDropdown.value;
  e.stopPropagation(); 
};

const closeDropdown = () => {
  showDropdown.value = false;
};

const handleLogout = () => {
  closeDropdown();
  emit('logout'); // 触发退出事件
};

onMounted(() => {
  document.addEventListener('click', closeDropdown);
});

onUnmounted(() => {
  document.removeEventListener('click', closeDropdown);
});
</script>

<style scoped>
/* ================= 顶部导航栏样式 ================= */
.top-navbar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0 40px; 
  height: 60px;
  background: #ffffff;
  border-radius: 0;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.08);
  width: 100%;
  box-sizing: border-box; 
  position: relative; 
  z-index: 100; 
}

.nav-left { display: flex; align-items: center; gap: 30px; }
.nav-links { display: flex; gap: 25px; }
.nav-links a { text-decoration: none; color: #606266; font-size: 1rem; font-weight: 500; transition: color 0.2s; position: relative; line-height: 60px; }
.nav-links a:hover, .nav-links a.active { color: #6366f1; font-weight: bold;}
.nav-links a.active::after { content: ''; position: absolute; bottom: 0; left: 0; width: 100%; height: 3px; background: #6366f1; border-radius: 3px 3px 0 0; }

.nav-right { display: flex; align-items: center; gap: 20px; }
.icon-btn { background: none; border: none; font-size: 1.3rem; cursor: pointer; transition: transform 0.2s; outline: none; padding: 5px; display: flex; align-items: center; justify-content: center;}
.icon-btn:hover { transform: scale(1.15); }

.nav-avatar-container { position: relative; display: flex; align-items: center; }
.nav-avatar-wrapper { width: 38px; height: 38px; border-radius: 50%; border: 2px solid #e4e7ed; overflow: hidden; cursor: pointer; transition: border-color 0.2s; box-shadow: 0 2px 6px rgba(0,0,0,0.1); }
.nav-avatar-wrapper:hover { border-color: #6366f1; }
.nav-avatar { width: 100%; height: 100%; object-fit: cover; }

.avatar-dropdown {
  position: absolute;
  top: 55px; 
  right: 0;
  background: #ffffff;
  border: 1px solid #ebeef5;
  border-radius: 8px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
  min-width: 140px;
  z-index: 100;
  overflow: hidden; 
}

.dropdown-item {
  padding: 12px 20px;
  font-size: 0.95rem;
  color: #606266;
  cursor: pointer;
  transition: background 0.2s, color 0.2s;
  font-weight: 500;
}

.logout-item { color: #ef4444; }
.logout-item:hover { background: #fef2f2; color: #dc2626; }

.dropdown-fade-enter-active, .dropdown-fade-leave-active {
  transition: opacity 0.2s ease, transform 0.2s ease;
}
.dropdown-fade-enter-from, .dropdown-fade-leave-to {
  opacity: 0;
  transform: translateY(-10px);
}

@media (max-width: 900px) {
  .top-navbar { padding: 0 15px; } 
  .nav-links a:nth-child(n+3) { display: none; }
}
</style>