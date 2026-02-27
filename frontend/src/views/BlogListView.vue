<template>
  <div>
    <TopNavbar/>

    <div class="all-blogs-dashboard">
      <header class="page-header animate__animated animate__fadeInDown">
        <div class="title-section">
          <h2>🌐 发现 Web3 博客</h2>
          <p>探索去中心化世界里的所有声音</p>
        </div>
        <button class="back-btn" @click="$emit('go-back')">返回我的空间</button>
      </header>

      <main class="dash-content animate__animated animate__fadeInUp">
        <div v-if="loading" class="loading-state">
          <div class="loader"></div>
          <p>正在从区块链拉取所有博客数据...</p>
        </div>
        
        <div v-else-if="allBlogs.length === 0" class="empty-state">
          目前还没有任何人发布博客哦，快去发布第一篇吧！
        </div>

        <div v-else class="blog-grid">
          <div v-for="blog in allBlogs" :key="blog.id" class="blog-card">
            <h4 @click="handleAction(blog)" class="clickable-title">{{ blog.name }}</h4>
            <p class="author">👤 作者: {{ blog.authorDisplay }}</p>
            <p class="intro">{{ blog.intro }}</p>
            
            <div class="blog-meta">
              <span>👁️ 浏览量: {{ blog.viewCount }}</span>
              <span>💰 价格: {{ blog.price }} BLG</span>
            </div>
            
            <div class="blog-footer">
              <small>发布时间: {{ blog.publishDate }}</small>
              <button 
                class="action-btn" 
                :class="{ 'subscribe-btn': !blog.hasAccess }"
                @click="handleAction(blog)"
                :disabled="blog.isPurchasing"
              >
                <span v-if="blog.isPurchasing">链上确认中...</span>
                <span v-else>{{ blog.hasAccess ? '查看文章' : '订阅文章' }}</span>
              </button>
            </div>
          </div>
        </div>
      </main>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import { ethers } from 'ethers';
import { useRouter } from 'vue-router';
import { getContract } from '../utils/web3';
import TopNavbar from '../components/TopNavbar.vue'; 

const emit = defineEmits(['go-back']);
const router = useRouter();

const allBlogs = ref([]);
const loading = ref(true);
const currentUserAddress = ref('');

const formatAddress = (address) => {
  if (!address) return '';
  return `${address.slice(0, 6)}...${address.slice(-4)}`;
};

// 获取当前连接的钱包地址
const getCurrentUser = async () => {
  try {
    const provider = new ethers.BrowserProvider(window.ethereum);
    const signer = await provider.getSigner();
    currentUserAddress.value = await signer.getAddress();
  } catch (error) {
    console.warn("未能获取当前钱包地址，请确认是否连接钱包");
  }
};

const fetchAllBlogs = async () => {
  try {
    loading.value = true;
    await getCurrentUser(); 
    const contract = getContract();
    const blogsData = [];
    
    const totalBlogs = await contract.getBlogCount();
    const count = Number(totalBlogs);

    for (let currentId = 0; currentId < count; currentId++) {
      const detail = await contract.getBlogDetail(currentId);
      
      if (!detail[7]) { 
        const authorName = await contract.getUsername(detail[0]);
        const displayAuthor = authorName ? authorName : formatAddress(detail[0]);

        const isOwner = detail[0].toLowerCase() === currentUserAddress.value.toLowerCase();
        let hasPurchased = false;
        
        try {
          hasPurchased = await contract.hasPurchased(currentUserAddress.value, currentId);
        } catch (e) {
          console.warn(`查询购买状态失败: ID ${currentId}`);
        }

        const hasAccess = isOwner || hasPurchased;

        blogsData.push({
          id: currentId.toString(),
          owner: detail[0],
          authorDisplay: displayAuthor, 
          name: detail[1],
          intro: detail[2],
          ipfsCID: detail[3],
          price: ethers.formatEther(detail[4]),
          viewCount: detail[5].toString(),
          publishDate: new Date(Number(detail[6]) * 1000).toLocaleString(),
          isHidden: detail[7],
          hasAccess, 
          isPurchasing: false // 新增一个局部状态，防止用户重复点击同一个按钮
        });
      }
    }

    allBlogs.value = blogsData.reverse();
  } catch (error) {
    console.error("获取所有博客列表失败:", error);
  } finally {
    loading.value = false;
  }
};

// 点击文章标题或按钮的统一处理
const handleAction = async (blog) => {
  if (blog.isPurchasing) return; // 如果正在买，防抖阻止再次点击

  if (blog.hasAccess) {
    // 已经有权限，直接跳进详情页
    router.push(`/blog/${blog.id}`);
  } else {
    // 没权限，直接唤起 MetaMask 进行购买
    await purchaseDirectly(blog);
  }
};

// 直接唤起 MetaMask 的购买逻辑
const purchaseDirectly = async (blog) => {
  blog.isPurchasing = true; // 按钮变成 "链上确认中..."
  try {
    const contract = getContract();
    
    // 直接调用合约，这里会自动弹出 MetaMask
    const tx = await contract.purchaseBlog(blog.id);
    
    // 交易发送出去了，等待打包
    await tx.wait(); 
    
    // 购买成功
    alert("🎉 订阅成功！即将为您跳转到文章页面。");
    
    // 更新权限并自动跳转
    blog.hasAccess = true;
    router.push(`/blog/${blog.id}`);

  } catch (error) {
    console.error("购买失败:", error);
    // 处理用户拒绝交易或余额不足等情况
    if (error.code === 'ACTION_REJECTED') {
      alert("您取消了 MetaMask 交易确认。");
    } else {
      alert(`订阅失败！\n错误信息: ${error.shortMessage || error.message}`);
    }
  } finally {
    blog.isPurchasing = false; // 恢复按钮状态
  }
};

onMounted(() => {
  fetchAllBlogs();
});
</script>

<style scoped>
/* 原有基础样式 */
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
.action-btn:disabled { background: #94a3b8; cursor: not-allowed; opacity: 0.8; } /* 禁用状态样式 */

.empty-state, .loading-state { text-align: center; padding: 60px 20px; color: #64748b; background: white; border: 1px dashed #cbd5e1; border-radius: 12px; }
.loader { border: 4px solid #f3f3f3; border-top: 4px solid #6366f1; border-radius: 50%; width: 40px; height: 40px; animation: spin 1s linear infinite; margin: 0 auto 15px; }
@keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }

/* 标题点击样式 */
.clickable-title {
  cursor: pointer;
  transition: color 0.2s ease;
}
.clickable-title:hover {
  color: #6366f1; 
}

/* 订阅按钮的特殊样式（区别于查看文章） */
.subscribe-btn {
  background: #f59e0b; 
}
.subscribe-btn:hover {
  background: #d97706;
}
</style>