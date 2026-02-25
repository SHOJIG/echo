<template>
  <div class="wallet-card">
    <button v-if="!address" @click="connectWallet" class="btn primary">
      🦊 连接 MetaMask 钱包
    </button>
    
    <div v-else class="wallet-info">
      <div class="info-item">
        <span>🟢 当前账户:</span>
        <strong>{{ formattedAddress }}</strong>
      </div>
      <div class="info-item">
        <span>💰 BLG 余额:</span>
        <strong>{{ balance }}</strong>
      </div>
      <button @click="claimFaucet" class="btn success" :disabled="loading">
        {{ loading ? '处理中...' : '🚰 领取 100 BLG (水龙头)' }}
      </button>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue';
import { ethers } from 'ethers';
import { initWeb3, getContract } from '../utils/web3';

const address = ref('');
const balance = ref('0');
const loading = ref(false);

// 截取显示地址 (例如: 0x1234...ABCD)
const formattedAddress = computed(() => {
  if (!address.value) return '';
  return `${address.value.slice(0, 6)}...${address.value.slice(-4)}`;
});

// 连接钱包
const connectWallet = async () => {
  try {
    const { signer } = await initWeb3();
    address.value = await signer.getAddress();
    await fetchBalance();
  } catch (error) {
    console.error("钱包连接失败:", error);
  }
};

// 获取余额
const fetchBalance = async () => {
  if (!address.value) return;
  try {
    const contract = getContract();
    const rawBalance = await contract.balanceOf(address.value);
    // 将链上的大整数 (Wei) 转换为人类可读的数字
    balance.value = ethers.formatEther(rawBalance);
  } catch (error) {
    console.error("获取余额失败:", error);
  }
};

// 调用水龙头
const claimFaucet = async () => {
  try {
    loading.value = true;
    const contract = getContract();
    const tx = await contract.claimTokens();
    alert("交易已提交到区块链，等待区块确认中...");
    
    await tx.wait(); // 等待区块打包确认
    alert("🎉 领取成功！100 BLG 已到账！");
    
    await fetchBalance(); // 刷新余额
  } catch (error) {
    console.error("领水失败:", error);
    alert("领取失败！可能是因为 24 小时冷却期未到，或者你拒绝了交易。");
  } finally {
    loading.value = false;
  }
};
</script>

<style scoped>
.wallet-card { padding: 15px; border: 1px solid #e2e8f0; border-radius: 8px; background-color: #f8fafc; }
.wallet-info { display: flex; flex-direction: column; gap: 10px; }
.info-item { display: flex; justify-content: space-between; font-size: 14px; }
.btn { padding: 10px 15px; border: none; border-radius: 6px; cursor: pointer; font-weight: bold; transition: 0.2s; }
.btn:disabled { opacity: 0.6; cursor: not-allowed; }
.btn.primary { background-color: #3b82f6; color: white; }
.btn.primary:hover { background-color: #2563eb; }
.btn.success { background-color: #10b981; color: white; margin-top: 10px; }
.btn.success:hover { background-color: #059669; }
</style>