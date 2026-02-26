<template>
  <header class="top-navbar animate__animated animate__fadeInDown">
    <div class="nav-left">
      <nav class="nav-links">
        <a href="#" :class="{ active: route.path === '/' }" @click.prevent="$router.push('/')">博客</a>
        <a href="#" :class="{ active: route.path === '/blogs' }" @click.prevent="$router.push('/blogs')">探索</a>
        <a href="#" :class="{ active: route.path.startsWith('/albums') }" @click.prevent="$router.push('/albums')">相册</a>
        <a href="#">订阅</a>
      </nav>
    </div>

    <div class="nav-right">
      <div class="token-container">
        <div class="token-balance" title="点击领取每日代币" @click="toggleFaucetDropdown">
          💰 {{ tokenBalance }} BLG
        </div>
        
        <transition name="dropdown-fade">
          <div v-show="showFaucetDropdown" class="faucet-dropdown">
            <div class="faucet-header">每日空投福利</div>
            <p class="faucet-desc">每 24 小时可免费领取 100 BLG</p>
            <button 
              class="claim-btn" 
              :class="{ 'disabled-btn': !canClaimTokens }"
              :disabled="!canClaimTokens || isClaiming"
              @click.stop="handleClaimTokens"
            >
              {{ isClaiming ? '领取中...' : claimBtnText }}
            </button>
          </div>
        </transition>
      </div>
      
      <button class="icon-btn" title="写博客">✍️</button>
      <button class="icon-btn" title="消息通知">🔔</button>
      
      <div class="nav-avatar-container">
        <div class="nav-avatar-wrapper" @click="toggleAvatarDropdown">
          <img class="nav-avatar" :src="userAvatar" alt="avatar" />
        </div>
        
        <transition name="dropdown-fade">
          <div v-show="showAvatarDropdown" class="avatar-dropdown">
            <div class="dropdown-item" @click="handleEditUsername">
              ✏️ 修改名字
            </div>
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
import { useRoute, useRouter } from 'vue-router';
import { getContract } from '../utils/web3'; 
import { ethers } from 'ethers'; 

const route = useRoute();
const router = useRouter();
const emit = defineEmits(['logout']);

const userAvatar = ref('https://images.cnblogs.com/cnblogs_com/blogs/784559/galleries/2387286/o_240325050905_tx.png');

// --- 下拉菜单状态控制 ---
const showAvatarDropdown = ref(false);
const showFaucetDropdown = ref(false);

// 点击空白处关闭所有下拉菜单
const closeAllDropdowns = () => {
  showAvatarDropdown.value = false;
  showFaucetDropdown.value = false;
};

// 切换头像下拉（并关闭水龙头下拉）
const toggleAvatarDropdown = (e) => {
  showAvatarDropdown.value = !showAvatarDropdown.value;
  showFaucetDropdown.value = false;
  e.stopPropagation(); 
};

// 切换水龙头下拉（并关闭头像下拉）
const toggleFaucetDropdown = (e) => {
  showFaucetDropdown.value = !showFaucetDropdown.value;
  showAvatarDropdown.value = false;
  e.stopPropagation();
};

// --- 余额与水龙头逻辑 ---
const tokenBalance = ref('0.00');
const canClaimTokens = ref(false);
const isClaiming = ref(false);
const claimBtnText = ref('检查中...');

// 检查水龙头领取状态
const checkFaucetStatus = async (address, contract) => {
  try {
    const lastTime = await contract.lastFaucetTime(address);
    const lastTimeMs = Number(lastTime) * 1000;
    const cooldownMs = 24 * 60 * 60 * 1000; // 24小时的毫秒数
    const nowMs = Date.now();

    if (lastTimeMs === 0 || nowMs >= lastTimeMs + cooldownMs) {
      canClaimTokens.value = true;
      claimBtnText.value = '🎁 立即领取 (100 BLG)';
    } else {
      canClaimTokens.value = false;
      // 计算还要多久才能领
      const nextTime = new Date(lastTimeMs + cooldownMs);
      const hours = nextTime.getHours().toString().padStart(2, '0');
      const minutes = nextTime.getMinutes().toString().padStart(2, '0');
      claimBtnText.value = `冷却中 (${hours}:${minutes} 可领)`;
    }
  } catch (e) {
    console.error("检查水龙头状态失败:", e);
    claimBtnText.value = '状态获取失败';
  }
};

// 拉取余额并连带检查水龙头状态
const fetchBalance = async () => {
  try {
    if (window.ethereum) {
      const provider = new ethers.BrowserProvider(window.ethereum);
      const signer = await provider.getSigner();
      const address = await signer.getAddress();
      
      const contract = getContract();
      const rawBalance = await contract.balanceOf(address);
      tokenBalance.value = Number(ethers.formatEther(rawBalance)).toFixed(2);

      // 同步检查领取状态
      await checkFaucetStatus(address, contract);
    }
  } catch (error) {
    console.error("获取代币余额失败:", error);
  }
};

// 处理领取水龙头
const handleClaimTokens = async () => {
  if (!canClaimTokens.value || isClaiming.value) return;

  try {
    isClaiming.value = true;
    const contract = getContract();
    const tx = await contract.claimTokens();
    alert("正在向区块链发送领取请求，请等待区块确认...");
    
    await tx.wait(); 
    alert("🎉 领取成功！100 BLG 已发放至您的钱包。");
    
    await fetchBalance(); // 刷新余额和按钮状态
    closeAllDropdowns();
  } catch(e) {
    console.error("领取失败:", e);
    alert("领取失败，可能未过 24 小时或拒绝了交易。");
  } finally {
    isClaiming.value = false;
  }
};

// --- 用户资料及登出逻辑 ---
const handleLogout = () => {
  closeAllDropdowns();
  emit('logout'); 
};

const handleEditUsername = async () => {
  closeAllDropdowns(); 
  
  const newName = prompt("请输入您的新用户名：");
  if (!newName || newName.trim() === "") return;
  
  try {
    const contract = getContract();
    const tx = await contract.setUsername(newName);
    alert("请求已发送，正在等待区块链确认，请稍候...");
    
    await tx.wait(); 
    alert("名字修改成功！");
    window.location.reload(); 
  } catch(e) {
    console.error("修改名字失败:", e);
    alert("修改失败，请检查控制台报错。");
  }
};

onMounted(() => {
  document.addEventListener('click', closeAllDropdowns);
  fetchBalance(); 
});

onUnmounted(() => {
  document.removeEventListener('click', closeAllDropdowns);
});
</script>

<style scoped>
/* ================= 顶部导航栏样式 ================= */
.top-navbar { display: flex; justify-content: space-between; align-items: center; padding: 0 40px; height: 60px; background: #ffffff; border-radius: 0; box-shadow: 0 2px 12px rgba(0, 0, 0, 0.08); width: 100%; box-sizing: border-box; position: relative; z-index: 100; }
.nav-left { display: flex; align-items: center; gap: 30px; }
.nav-links { display: flex; gap: 25px; }
.nav-links a { text-decoration: none; color: #606266; font-size: 1rem; font-weight: 500; transition: color 0.2s; position: relative; line-height: 60px; }
.nav-links a:hover, .nav-links a.active { color: #6366f1; font-weight: bold;}
.nav-links a.active::after { content: ''; position: absolute; bottom: 0; left: 0; width: 100%; height: 3px; background: #6366f1; border-radius: 3px 3px 0 0; }
.nav-right { display: flex; align-items: center; gap: 20px; }
.icon-btn { background: none; border: none; font-size: 1.3rem; cursor: pointer; transition: transform 0.2s; outline: none; padding: 5px; display: flex; align-items: center; justify-content: center;}
.icon-btn:hover { transform: scale(1.15); }

/* ==== 头像下拉菜单 ==== */
.nav-avatar-container { position: relative; display: flex; align-items: center; }
.nav-avatar-wrapper { width: 38px; height: 38px; border-radius: 50%; border: 2px solid #e4e7ed; overflow: hidden; cursor: pointer; transition: border-color 0.2s; box-shadow: 0 2px 6px rgba(0,0,0,0.1); }
.nav-avatar-wrapper:hover { border-color: #6366f1; }
.nav-avatar { width: 100%; height: 100%; object-fit: cover; }
.avatar-dropdown { position: absolute; top: 55px; right: 0; background: #ffffff; border: 1px solid #ebeef5; border-radius: 8px; box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1); min-width: 140px; z-index: 100; overflow: hidden; }
.dropdown-item { padding: 12px 20px; font-size: 0.95rem; color: #606266; cursor: pointer; transition: background 0.2s, color 0.2s; font-weight: 500; }
.dropdown-item:hover { background: #f8fafc; color: #6366f1; }
.logout-item { color: #ef4444; }
.logout-item:hover { background: #fef2f2; color: #dc2626; }

/* ==== 代币与水龙头样式 ==== */
.token-container { position: relative; }
.token-balance { background: #eef2ff; color: #4f46e5; padding: 6px 16px; border-radius: 20px; font-size: 0.95rem; font-weight: bold; display: flex; align-items: center; border: 1px solid #c7d2fe; cursor: pointer; transition: all 0.2s; user-select: none; }
.token-balance:hover { background: #e0e7ff; transform: translateY(-1px); box-shadow: 0 2px 6px rgba(99, 102, 241, 0.2); }

.faucet-dropdown { position: absolute; top: 45px; right: 0; width: 220px; background: #ffffff; border: 1px solid #ebeef5; border-radius: 12px; box-shadow: 0 8px 24px rgba(0, 0, 0, 0.12); padding: 15px; z-index: 100; text-align: center; }
.faucet-header { font-weight: bold; color: #1e293b; font-size: 1rem; margin-bottom: 5px; }
.faucet-desc { font-size: 0.8rem; color: #64748b; margin-bottom: 15px; }
.claim-btn { width: 100%; padding: 10px 0; background: #6366f1; color: white; border: none; border-radius: 8px; font-weight: bold; cursor: pointer; transition: background 0.2s; }
.claim-btn:hover:not(.disabled-btn) { background: #4f46e5; }
.disabled-btn { background: #cbd5e1 !important; color: #f8fafc !important; cursor: not-allowed; }

/* ==== 动画 ==== */
.dropdown-fade-enter-active, .dropdown-fade-leave-active { transition: opacity 0.2s ease, transform 0.2s ease; }
.dropdown-fade-enter-from, .dropdown-fade-leave-to { opacity: 0; transform: translateY(-10px); }

@media (max-width: 900px) {
  .top-navbar { padding: 0 15px; } 
  .nav-links a:nth-child(n+3) { display: none; }
}
</style>