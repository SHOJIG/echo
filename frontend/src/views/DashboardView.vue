<template>
  <div class="dashboard">
    <header class="dash-header">
      <h2>我的 Web3 博客空间</h2>
      <div class="user-info">
        <button class="explore-btn" @click="$emit('go-to-explore')">
          🌐 发现更多博客
        </button>
        <span class="address-badge">👤 {{ shortAddress }}</span>
        <button class="logout-btn" @click="$emit('logout')">退出</button>
      </div>
    </header>

    <main class="dash-content">
      <section class="blog-list-section">
        <h3>📚 我发布的文章</h3>
        
        <div v-if="loading" class="loading">正在从区块链拉取数据...</div>
        
        <div v-else-if="myBlogs.length === 0" class="empty-state">
          你还没有在链上发布过文章哦！
        </div>

        <div v-else class="blog-grid">
          <div v-for="blog in myBlogs" :key="blog.id" class="blog-card">
            <h4>{{ blog.name }}</h4>
            <p class="intro">{{ blog.intro }}</p>
            <div class="blog-meta">
              <span>👁️ 浏览: {{ blog.viewCount }}</span>
              <span>💰 价格: {{ blog.price }} BLG</span>
            </div>
            <div class="blog-footer">
              <small>发布时间: {{ new Date(Number(blog.publishDate) * 1000).toLocaleString() }}</small>
            </div>
          </div>
        </div>
      </section>

      <aside class="sidebar">
        <PublishBlog @published="fetchMyBlogs" />
      </aside>
    </main>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue';
import { ethers } from 'ethers';
import { getContract } from '../utils/web3';
import PublishBlog from '../components/PublishBlog.vue';

const props = defineProps({
  userAddress: String
});

const shortAddress = computed(() => {
  return props.userAddress ? `${props.userAddress.slice(0, 6)}...${props.userAddress.slice(-4)}` : '';
});

const myBlogs = ref([]);
const loading = ref(true);

// 核心逻辑：从智能合约拉取当前用户发布的博客
const fetchMyBlogs = async () => {
  try {
    loading.value = true;
    const contract = getContract();
    
    // 1. 获取用户发布的所有博客 ID 数组
    const blogIds = await contract.getUserPublishedBlogs(props.userAddress);
    
    // 2. 遍历 ID，获取每篇博客的具体详情
    const blogsData = [];
    for (let i = 0; i < blogIds.length; i++) {
      const id = blogIds[i];
      const detail = await contract.getBlogDetail(id);
      
      blogsData.push({
        id: id.toString(),
        owner: detail[0],
        name: detail[1],
        intro: detail[2],
        ipfsCID: detail[3],
        price: ethers.formatEther(detail[4]), // 将 wei 转为正常 BLG 数量
        viewCount: detail[5].toString(),
        publishDate: detail[6].toString(),
        isHidden: detail[7]
      });
    }
    
    // 反转数组，让最新发布的排在最前面
    myBlogs.value = blogsData.reverse();
  } catch (error) {
    console.error("获取博客列表失败:", error);
  } finally {
    loading.value = false;
  }
};

// 组件挂载时自动拉取数据
onMounted(() => {
  fetchMyBlogs();
});
</script>

<style scoped>
.explore-btn {
  padding: 8px 15px; background: #6366f1; color: white; border: none; border-radius: 6px; cursor: pointer; margin-right: 15px; font-weight: bold;
}
.explore-btn:hover { background: #4f46e5; }
.dashboard { max-width: 1200px; margin: 0 auto; padding: 20px; }
.dash-header { display: flex; justify-content: space-between; align-items: center; padding-bottom: 20px; border-bottom: 1px solid #e2e8f0; margin-bottom: 30px;}
.address-badge { background: #f1f5f9; padding: 8px 15px; border-radius: 20px; font-weight: bold; margin-right: 15px; }
.logout-btn { padding: 8px 15px; border: 1px solid #ef4444; color: #ef4444; background: transparent; border-radius: 6px; cursor: pointer; }

.dash-content { display: flex; gap: 30px; }
.blog-list-section { flex: 2; }
.sidebar { flex: 1; }

.blog-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 20px; margin-top: 20px; }
.blog-card { background: white; border: 1px solid #e2e8f0; padding: 20px; border-radius: 12px; box-shadow: 0 2px 4px rgba(0,0,0,0.05); transition: transform 0.2s; }
.blog-card:hover { transform: translateY(-5px); box-shadow: 0 10px 15px rgba(0,0,0,0.1); }
.blog-card h4 { font-size: 1.2rem; margin-bottom: 10px; color: #1e293b; }
.intro { color: #64748b; font-size: 0.95rem; margin-bottom: 15px; line-height: 1.5; }
.blog-meta { display: flex; justify-content: space-between; font-size: 0.9rem; margin-bottom: 15px; color: #0f172a; font-weight: bold; }
.blog-footer { border-top: 1px solid #f1f5f9; padding-top: 10px; color: #94a3b8; }

.empty-state, .loading { text-align: center; padding: 50px; color: #64748b; background: #f8fafc; border-radius: 12px; margin-top: 20px; }

@media (max-width: 768px) {
  .dash-content { flex-direction: column; }
}
</style>