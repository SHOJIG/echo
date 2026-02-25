<template>
  <div class="all-blogs-dashboard">
    <header class="page-header">
      <div class="title-section">
        <h2>🌐 发现 Web3 博客</h2>
        <p>探索去中心化世界里的所有声音</p>
      </div>
      <button class="back-btn" @click="$emit('go-back')">返回我的空间</button>
    </header>

    <main class="dash-content">
      <div v-if="loading" class="loading-state">
        <div class="loader"></div>
        <p>正在从区块链拉取所有博客数据...</p>
      </div>
      
      <div v-else-if="allBlogs.length === 0" class="empty-state">
        目前还没有任何人发布博客哦，快去发布第一篇吧！
      </div>

      <div v-else class="blog-grid">
        <div v-for="blog in allBlogs" :key="blog.id" class="blog-card">
          <h4>{{ blog.name }}</h4>
          <p class="author">👤 作者: {{ formatAddress(blog.owner) }}</p>
          <p class="intro">{{ blog.intro }}</p>
          
          <div class="blog-meta">
            <span>👁️ 浏览量: {{ blog.viewCount }}</span>
            <span>💰 价格: {{ blog.price }} BLG</span>
          </div>
          
          <div class="blog-footer">
            <small>发布时间: {{ blog.publishDate }}</small>
            <button class="action-btn" @click="handleViewDetail(blog.id)">查看文章</button>
          </div>
        </div>
      </div>
    </main>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import { ethers } from 'ethers';
import { getContract } from '../utils/web3';

const emit = defineEmits(['go-back']);

const allBlogs = ref([]);
const loading = ref(true);

// 格式化钱包地址显示
const formatAddress = (address) => {
  if (!address) return '';
  return `${address.slice(0, 6)}...${address.slice(-4)}`;
};

// 核心逻辑：从 0 开始遍历获取所有博客
const fetchAllBlogs = async () => {
  try {
    loading.value = true;
    const contract = getContract();
    const blogsData = [];
    let currentId = 0;

    // 无限循环，直到遇到 "blog not exist" 报错退出
    while (true) {
      try {
        const detail = await contract.getBlogDetail(currentId);
        
        // 如果博客没有被 DAO 社区隐藏，才展示出来
        if (!detail[7]) { // detail[7] 对应返回值里的 isHidden
          blogsData.push({
            id: currentId.toString(),
            owner: detail[0],
            name: detail[1],
            intro: detail[2],
            ipfsCID: detail[3],
            price: ethers.formatEther(detail[4]), // 将 wei 转为 BLG 数量
            viewCount: detail[5].toString(),
            publishDate: new Date(Number(detail[6]) * 1000).toLocaleString(),
            isHidden: detail[7]
          });
        }
        
        currentId++; // 继续查找下一个 ID
      } catch (err) {
        // 当查询超出当前博客数量时，合约报错，退出循环
        console.log(`遍历结束，链上共 ${currentId} 篇博客数据`);
        break; 
      }
    }

    // 翻转数组，让最新发布的博客展示在最前面
    allBlogs.value = blogsData.reverse();
  } catch (error) {
    console.error("获取所有博客列表失败:", error);
  } finally {
    loading.value = false;
  }
};

const handleViewDetail = (blogId) => {
  // 这里可以抛出事件或使用 Vue Router 跳转到详情页
  alert(`准备查看博客 ID: ${blogId}，此处可结合路由做详情页跳转`);
};

onMounted(() => {
  fetchAllBlogs();
});
</script>

<style scoped>
.all-blogs-dashboard { max-width: 1200px; margin: 0 auto; padding: 20px; }
.page-header { display: flex; justify-content: space-between; align-items: center; padding-bottom: 20px; border-bottom: 1px solid #e2e8f0; margin-bottom: 30px;}
.title-section h2 { margin-bottom: 5px; color: #1e293b; }
.title-section p { color: #64748b; font-size: 0.9rem; }
.back-btn { padding: 8px 16px; background: white; border: 1px solid #cbd5e1; border-radius: 6px; cursor: pointer; transition: all 0.2s; }
.back-btn:hover { background: #f8fafc; border-color: #94a3b8; }

.blog-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(320px, 1fr)); gap: 24px; }
.blog-card { background: white; border: 1px solid #e2e8f0; padding: 24px; border-radius: 16px; box-shadow: 0 4px 6px rgba(0,0,0,0.02); transition: transform 0.2s, box-shadow 0.2s; display: flex; flex-direction: column;}
.blog-card:hover { transform: translateY(-4px); box-shadow: 0 12px 20px rgba(0,0,0,0.08); }
.blog-card h4 { font-size: 1.3rem; margin-bottom: 12px; color: #0f172a; }
.author { font-size: 0.85rem; color: #8b5cf6; margin-bottom: 10px; font-weight: bold;}
.intro { color: #475569; font-size: 0.95rem; margin-bottom: 20px; line-height: 1.6; flex-grow: 1; }
.blog-meta { display: flex; justify-content: space-between; font-size: 0.9rem; margin-bottom: 15px; padding: 10px; background: #f8fafc; border-radius: 8px; font-weight: 500;}
.blog-footer { display: flex; justify-content: space-between; align-items: center; border-top: 1px solid #f1f5f9; padding-top: 15px; }
.blog-footer small { color: #94a3b8; }
.action-btn { padding: 6px 16px; background: #6366f1; color: white; border: none; border-radius: 6px; cursor: pointer; transition: background 0.2s; }
.action-btn:hover { background: #4f46e5; }

.empty-state, .loading-state { text-align: center; padding: 60px 20px; color: #64748b; background: white; border: 1px dashed #cbd5e1; border-radius: 12px; }
.loader { border: 4px solid #f3f3f3; border-top: 4px solid #6366f1; border-radius: 50%; width: 40px; height: 40px; animation: spin 1s linear infinite; margin: 0 auto 15px; }
@keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }
</style>