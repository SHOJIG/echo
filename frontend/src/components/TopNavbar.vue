<template>
  <header class="top-navbar animate__animated animate__fadeInDown">
    <div class="nav-left">
      <nav class="nav-links">
        <a href="#" :class="{ active: route.path === '/' }" @click.prevent="$router.push('/')">博客</a>
        <a href="#" :class="{ active: route.path === '/blogs' }" @click.prevent="$router.push('/blogs')">探索</a>
        <a href="#" :class="{ active: route.path.startsWith('/albums') }" @click.prevent="$router.push('/albums')">相册</a>
        <a href="#" :class="{ active: route.path === '/subscribe' }" @click.prevent="$router.push('/subscribe')">订阅</a>
      </nav>
    </div>

    <div class="nav-right">
      <div class="token-container">
        <div class="token-balance" title="点击领取每日代币" @click="toggleFaucetDropdown">
          <img :src="getIpfsUrl('bafkreibal4uvu3li6swxdmtwn7mk4ttfp2h6ysmzu2unzulnoqyd7ttsty')" alt="写博客" class="custom-icon" style="margin-right: 10px;" /> {{ tokenBalance }} BLG
        </div>
        
        <transition name="dropdown-fade">
          <div v-show="showFaucetDropdown" class="faucet-dropdown">
            <div class="faucet-header">每日福利</div>
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
      
      <button class="icon-btn" title="写博客" @click="$router.push('/publish')">
        <img :src="getIpfsUrl('bafkreie52yu6kox54b7n5htub2belwd2quv43iftbrjmlgf5vx7bp7pyrq')" alt="写博客" class="custom-icon" />
      </button>
      
      <div class="nav-avatar-container">
        <div class="nav-avatar-wrapper" @click="toggleAvatarDropdown">
          <img class="nav-avatar" :src="userAvatar" alt="avatar" />
        </div>
        
        <transition name="dropdown-fade">
          <div v-show="showAvatarDropdown" class="avatar-dropdown">
            <div class="dropdown-item" @click="handleEditUsername">
              修改名字
            </div>
            
            <div class="dropdown-item" @click="triggerAvatarUpload">
              {{ isUploadingAvatar ? '上传中...' : '修改头像' }}
            </div>
            
            <div class="dropdown-item logout-item" @click="handleLogout">
              退出登录
            </div>
          </div>
        </transition>
        
        <input 
          type="file" 
          ref="avatarInput" 
          style="display: none;" 
          accept="image/*" 
          @change="handleAvatarUpload" 
        />
      </div>
    </div>
  </header>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { getContract } from '../utils/web3'; 
import { ethers } from 'ethers'; 
import { getIpfsUrl } from '../utils/ipfs';

const route = useRoute();
const router = useRouter();
const emit = defineEmits(['logout']);

const defaultAvatar = getIpfsUrl("bafkreihxhqdm4ixe6cwlfblkisruar2zn56rek2ybl6qliar7djizccoiq");
const userAvatar = ref(defaultAvatar);
const showAvatarDropdown = ref(false);
const showFaucetDropdown = ref(false);

const closeAllDropdowns = () => {
  showAvatarDropdown.value = false;
  showFaucetDropdown.value = false;
};

const toggleAvatarDropdown = (e) => {
  showAvatarDropdown.value = !showAvatarDropdown.value;
  showFaucetDropdown.value = false;
  e.stopPropagation(); 
};

const toggleFaucetDropdown = (e) => {
  showFaucetDropdown.value = !showFaucetDropdown.value;
  showAvatarDropdown.value = false;
  e.stopPropagation();
};
const avatarInput = ref(null);
const isUploadingAvatar = ref(false);

const triggerAvatarUpload = () => {
  if (isUploadingAvatar.value) return;
  avatarInput.value.click();
};

const handleAvatarUpload = async (event) => {
  const file = event.target.files[0];
  if (!file) return;

  isUploadingAvatar.value = true;
  closeAllDropdowns();

  try {
    const formData = new FormData();
    formData.append('file', file);
    formData.append('pinataMetadata', JSON.stringify({ name: 'UserAvatar' }));

    const pinataJwt = import.meta.env.VITE_PINATA_JWT;
    const res = await fetch('https://api.pinata.cloud/pinning/pinFileToIPFS', {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${pinataJwt}` },
      body: formData
    });

    if (!res.ok) throw new Error("上传到 Pinata 失败");
    const resData = await res.json();
    const ipfsCID = resData.IpfsHash;
    const contract = getContract();
    const tx = await contract.setAvatar(ipfsCID);
    
    alert("头像已传至 IPFS，请在 MetaMask 中确认并等待区块打包...");
    await tx.wait(); 
    
    alert("头像修改成功！");
    window.location.reload();

  } catch (e) {
    console.error("修改头像失败:", e);
    alert("上传或上链失败，请查看控制台日志。");
  } finally {
    isUploadingAvatar.value = false;
    if (avatarInput.value) avatarInput.value.value = ''
  }
};
const tokenBalance = ref('0.00');
const canClaimTokens = ref(false);
const isClaiming = ref(false);
const claimBtnText = ref('检查中...');

const checkFaucetStatus = async (address, contract) => {
  try {
    const lastTime = await contract.lastFaucetTime(address);
    const lastTimeMs = Number(lastTime) * 1000;
    const todayStart = new Date();
    todayStart.setHours(0, 0, 0, 0);
    const todayStartMs = todayStart.getTime();

    if (lastTimeMs === 0 || lastTimeMs < todayStartMs) {
      canClaimTokens.value = true;
      claimBtnText.value = '立即领取';
    } else {
      canClaimTokens.value = false;
      claimBtnText.value = '今日已领';
    }
  } catch (e) {
    console.error("检查水龙头状态失败:", e);
    claimBtnText.value = '状态获取失败';
  }
};

const fetchUserData = async () => {
  try {
    if (window.ethereum) {
      const provider = new ethers.BrowserProvider(window.ethereum);
      const signer = await provider.getSigner();
      const address = await signer.getAddress();
      const contract = getContract();

      const rawBalance = await contract.balanceOf(address);
      tokenBalance.value = Number(ethers.formatEther(rawBalance)).toFixed(2);

      const avatarCid = await contract.getAvatar(address);
      if (avatarCid) {
        userAvatar.value = getIpfsUrl(avatarCid);
      }
      await checkFaucetStatus(address, contract);
    }
  } catch (error) {
    console.error("获取用户数据失败:", error);
  }
};

const handleClaimTokens = async () => {
  if (!canClaimTokens.value || isClaiming.value) return;
  try {
    isClaiming.value = true;
    const contract = getContract();
    const tx = await contract.claimTokens();
    alert("正在向区块链发送领取请求，请等待区块确认...");
    await tx.wait(); 
    alert("领取成功！100 BLG 已发放至您的钱包。");
    await fetchUserData(); 
    closeAllDropdowns();
  } catch(e) {
    console.error("领取失败:", e);
    alert("领取失败，可能未过 24 小时或拒绝了交易。");
  } finally {
    isClaiming.value = false;
  }
};

const handleLogout = () => {
  closeAllDropdowns();
  emit('logout'); 
  router.push('/index');
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
  }
};

onMounted(() => {
  document.addEventListener('click', closeAllDropdowns);
  fetchUserData();
});

onUnmounted(() => {
  document.removeEventListener('click', closeAllDropdowns);
});
</script>

<style scoped>

.top-navbar { display: flex; justify-content: space-between; align-items: center; padding: 0 40px; height: 60px; background: #ffffff; border-radius: 0; box-shadow: 0 2px 12px rgba(0, 0, 0, 0.08); width: 100%; box-sizing: border-box; position: relative; z-index: 100; }
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
.avatar-dropdown { position: absolute; top: 55px; right: 0; background: #ffffff; border: 1px solid #ebeef5; border-radius: 8px; box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1); min-width: 110px; z-index: 100; overflow: hidden; }
.dropdown-item { padding: 12px 20px; font-size: 0.95rem; color: #606266; cursor: pointer; transition: background 0.2s, color 0.2s; font-weight: 500; border-bottom: 1px solid #f1f5f9; }
.dropdown-item:last-child { border-bottom: none; }
.dropdown-item:hover { background: #f8fafc; color: #6366f1; }
.logout-item { color: #ef4444; }
.logout-item:hover { background: #fef2f2; color: #dc2626; }

.token-container { position: relative; }
.token-balance { background: #eef2ff; color: #4f46e5; padding: 6px 16px; border-radius: 20px; font-size: 0.95rem; font-weight: bold; display: flex; align-items: center; border: 1px solid #c7d2fe; cursor: pointer; transition: all 0.2s; user-select: none; }
.token-balance:hover { background: #e0e7ff; transform: translateY(-1px); box-shadow: 0 2px 6px rgba(99, 102, 241, 0.2); }

.faucet-dropdown { position: absolute; top: 45px; right: 0; width: 150px; background: #ffffff; border: 1px solid #ebeef5; border-radius: 12px; box-shadow: 0 8px 24px rgba(0, 0, 0, 0.12); padding: 15px; z-index: 100; text-align: center; }
.faucet-header { font-weight: bold; color: #1e293b; font-size: 1rem; margin-bottom: 5px; }
.claim-btn { width: 100%; padding: 10px 0; background: #6366f1; color: white; border: none; border-radius: 8px; font-weight: bold; cursor: pointer; transition: background 0.2s; }
.claim-btn:hover:not(.disabled-btn) { background: #4f46e5; }
.disabled-btn { background: #cbd5e1 !important; color: #f8fafc !important; cursor: not-allowed; }

.custom-icon { width: 24px; height: 24px; object-fit: contain; }

.dropdown-fade-enter-active, .dropdown-fade-leave-active { transition: opacity 0.2s ease, transform 0.2s ease; }
.dropdown-fade-enter-from, .dropdown-fade-leave-to { opacity: 0; transform: translateY(-10px); }

@media (max-width: 900px) {
  .top-navbar { padding: 0 15px; } 
  .nav-links a:nth-child(n+3) { display: none; }
}
</style>