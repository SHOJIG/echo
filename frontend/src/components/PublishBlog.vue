<template>
  <div class="publish-card">
    <h3>📝 发布去中心化博客</h3>
    
    <div class="form-group">
      <label>文章标题</label>
      <input v-model="form.name" type="text" placeholder="输入炫酷的标题..." />
    </div>

    <div class="form-group">
      <label>文章简介</label>
      <input v-model="form.intro" type="text" placeholder="一句话介绍你的文章..." />
    </div>

    <div class="form-group">
      <label>IPFS CID (文章内容哈希)</label>
      <input v-model="form.ipfsCID" type="text" placeholder="例如: QmHash..." />
      <small>注: 暂时手动输入测试用的 CID，后续接入 IPFS 自动上传</small>
    </div>

    <div class="form-group">
      <label>阅读价格 (BLG)</label>
      <input v-model="form.price" type="number" min="0" placeholder="0 表示免费" />
    </div>

    <button @click="publish" class="btn submit" :disabled="loading">
      {{ loading ? '上链中...' : '🚀 确认发布' }}
    </button>
  </div>
</template>

<script setup>
import { reactive, ref } from 'vue';
import { ethers } from 'ethers';
import { getContract } from '../utils/web3';

const loading = ref(false);
const form = reactive({
  name: '',
  intro: '',
  ipfsCID: '',
  price: 0
});

const publish = async () => {
  if (!form.name || !form.ipfsCID) {
    return alert("⚠️ 标题和 IPFS CID 不能为空！");
  }

  try {
    loading.value = true;
    const contract = getContract();
    
    // 将用户输入的 BLG 数量转换成 Wei (10^18)
    const priceInWei = ethers.parseEther(form.price.toString());
    
    const tx = await contract.publishBlog(
      form.name, 
      form.intro, 
      form.ipfsCID, 
      priceInWei
    );
    
    alert("上链请求已发送，请在 MetaMask 中确认并等待...");
    await tx.wait();
    
    alert("🎉 发布成功！你的文章已永久记录在区块链上！");
    
    // 清空表单
    form.name = '';
    form.intro = '';
    form.ipfsCID = '';
    form.price = 0;
    
  } catch (error) {
    console.error("发布失败:", error);
    alert("发布失败，请检查控制台报错（是否未连接钱包？）。");
  } finally {
    loading.value = false;
  }
};
</script>

<style scoped>
.publish-card { padding: 20px; border: 1px solid #e2e8f0; border-radius: 8px; margin-top: 20px; background-color: #fff; }
.form-group { margin-bottom: 15px; display: flex; flex-direction: column; gap: 5px; }
label { font-weight: bold; font-size: 14px; color: #334155; }
input { padding: 10px; border: 1px solid #cbd5e1; border-radius: 4px; font-size: 14px; }
input:focus { outline: none; border-color: #3b82f6; box-shadow: 0 0 0 2px rgba(59, 130, 246, 0.2); }
small { color: #64748b; font-size: 12px; }
.btn { padding: 10px 15px; border: none; border-radius: 6px; cursor: pointer; font-weight: bold; width: 100%; transition: 0.2s; }
.btn:disabled { opacity: 0.6; cursor: not-allowed; }
.submit { background-color: #8b5cf6; color: white; }
.submit:hover { background-color: #7c3aed; }
</style>