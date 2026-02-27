<template>
  <div class="dashboard-page">
    <TopNavbar/>

    <div class="home_center_box animate__animated animate__fadeInUp">
      <header class="page-header">
        <div class="title-section">
          <h2>📚 我的订阅</h2>
          <p>这里是你所有购买/订阅的 Web3 精彩内容</p>
        </div>
        <button class="back-btn" @click="$router.push('/')">返回首页</button>
      </header>

      <main class="layout-container">
        <div class="left-content">
          
          <div v-if="loading" class="loading-state">
            <div class="loader"></div>
            <p>正在从区块链拉取你的订阅数据...</p>
          </div>
          
          <div v-else-if="allBlogs.length === 0" class="empty-state card">
            <div class="empty-icon">📭</div>
            <p>你还没有订阅过任何文章，快去探索发现吧！</p>
            <button class="explore-btn" @click="$router.push('/blogs')">去发现博客</button>
          </div>

          <div v-else class="article-list">
            <div v-for="blog in paginatedBlogs" :key="blog.id" class="article-card card card-hover">
              <div class="article-content">
                
                <div class="article-header-row">
                  <h4 class="article-title" @click="goToDetail(blog.id)">{{ blog.name }}</h4>
                  <button class="read-btn" @click="goToDetail(blog.id)">阅读文章</button>
                </div>

                <div class="author-info clickable-author" @click="searchByAuthor(blog.authorDisplay)">
                  <img 
                    class="author-avatar" 
                    :src="blog.authorAvatar ? getIpfsUrl(blog.authorAvatar) : defaultAvatar" 
                    alt="avatar" 
                  />
                  <span class="author-name">{{ blog.authorDisplay }}</span>
                </div>

                <p class="article-intro">{{ blog.intro }}</p>
                
                <div class="article-meta">
                  <span class="meta-item">👁️ 浏览: {{ blog.viewCount }}</span>
                  <span class="meta-item">💰 价格: {{ blog.price }} BLG</span>
                  <span class="meta-item time">发布于 {{ blog.publishDate }}</span>
                </div>
              </div>
            </div>

            <div class="pagination" v-if="totalPages > 1">
              <button 
                class="page-btn" 
                :disabled="currentPage === 1" 
                @click="changePage(currentPage - 1)"
              >
                上一页
              </button>
              
              <button 
                v-for="page in totalPages" 
                :key="page"
                class="page-btn" 
                :class="{ active: currentPage === page }"
                @click="changePage(page)"
              >
                {{ page }}
              </button>
              
              <button 
                class="page-btn" 
                :disabled="currentPage === totalPages" 
                @click="changePage(currentPage + 1)"
              >
                下一页
              </button>
            </div>
          </div>
        </div>

      </main>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue';
import { ethers } from 'ethers';
import { useRouter } from 'vue-router'; 
import { getContract } from '../utils/web3';
import TopNavbar from '../components/TopNavbar.vue';
import { getIpfsUrl } from '../utils/ipfs';

const router = useRouter(); 
const defaultAvatar = getIpfsUrl("bafkreihxhqdm4ixe6cwlfblkisruar2zn56rek2ybl6qliar7djizccoiq");

const allBlogs = ref([]);
const loading = ref(true);
const currentUserAddress = ref('');

// ================= 分页相关逻辑 =================
const currentPage = ref(1);
const pageSize = 10; // 规定每页 10 个

const totalPages = computed(() => {
  return Math.ceil(allBlogs.value.length / pageSize);
});

const paginatedBlogs = computed(() => {
  const start = (currentPage.value - 1) * pageSize;
  const end = start + pageSize;
  return allBlogs.value.slice(start, end);
});

const changePage = (page) => {
  if (page >= 1 && page <= totalPages.value) {
    currentPage.value = page;
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }
};
// ===================================================

const formatAddress = (address) => {
  if (!address) return '';
  return `${address.slice(0, 6)}...${address.slice(-4)}`;
};

const goToDetail = (blogId) => {
  router.push(`/blog/${blogId}`);
};

const searchByAuthor = (authorName) => {
  // 如果你想支持点击作者去探索页搜索，可以跳过去并带参
  router.push({ path: '/blogs', query: { search: `author:${authorName}` } });
};

const fetchPurchasedBlogs = async () => {
  try {
    loading.value = true;
    
    // 获取当前用户钱包地址
    const provider = new ethers.BrowserProvider(window.ethereum);
    const signer = await provider.getSigner();
    currentUserAddress.value = await signer.getAddress();

    const contract = getContract();
    
    // 获取用户订阅（购买）的所有博客 ID 数组
    const blogIds = await contract.getUserPurchasedBlogs(currentUserAddress.value);
    
    const blogsData = [];
    for (let i = 0; i < blogIds.length; i++) {
      const id = blogIds[i];
      const detail = await contract.getBlogDetail(id);
      
      // 如果博客已被原作者或 DAO 删除/隐藏，则跳过不展示
      if (detail[7]) {
        continue;
      }

      const authorAddress = detail[0];
      const authorName = await contract.getUsername(authorAddress);
      const avatarCid = await contract.getAvatar(authorAddress);
      
      blogsData.push({
        id: id.toString(),
        owner: authorAddress,
        authorDisplay: authorName || formatAddress(authorAddress),
        authorAvatar: avatarCid,
        name: detail[1],
        intro: detail[2],
        ipfsCID: detail[3],
        price: ethers.formatEther(detail[4]),
        viewCount: detail[5].toString(),
        publishDate: new Date(Number(detail[6]) * 1000).toLocaleString(undefined, { year: 'numeric', month: '2-digit', day: '2-digit', hour: '2-digit', minute: '2-digit' }),
        isHidden: detail[7]
      });
    }
    
    // 倒序展示，最新订阅的在最前
    allBlogs.value = blogsData.reverse();
    currentPage.value = 1; 
  } catch (error) {
    console.error("获取订阅列表失败:", error);
  } finally {
    loading.value = false;
  }
};

onMounted(() => {
  fetchPurchasedBlogs();
});
</script>

<style scoped>
.dashboard-page { min-height: 100vh; background-color: #f8fafc; }
.home_center_box { max-width: 1000px; /* 调整为适合单行展示的宽度 */ margin: 30px auto; padding: 0 20px; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif; color: #333; }

.page-header { display: flex; justify-content: space-between; align-items: center; padding-bottom: 20px; border-bottom: 1px solid #e2e8f0; margin-bottom: 30px;}
.title-section h2 { margin-bottom: 5px; color: #1e293b; font-size: 1.8rem; }
.title-section p { color: #64748b; font-size: 1rem; margin: 0; }
.back-btn { padding: 8px 16px; background: white; border: 1px solid #cbd5e1; border-radius: 6px; cursor: pointer; transition: background 0.2s; white-space: nowrap;}
.back-btn:hover { background: #f8fafc; }

.layout-container { display: flex; gap: 20px; align-items: flex-start; justify-content: center;}
.left-content { width: 100%; display: flex; flex-direction: column; gap: 20px; }

.card { background: #ffffff; border: 1px solid #e4e7ed; border-radius: 12px; box-shadow: 0px 4px 6px rgba(0, 0, 0, 0.02); overflow: hidden; color: #303133; transition: all 0.3s ease; }
.card-hover:hover { box-shadow: 0 10px 20px rgba(0, 0, 0, 0.08); transform: translateY(-4px); }

.article-list { display: flex; flex-direction: column; gap: 20px; }
.article-card { padding: 24px; }

.article-header-row { display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 15px; }
.article-title { margin: 0; font-size: 1.4rem; color: #1e293b; cursor: pointer; transition: color 0.2s; flex: 1; padding-right: 15px; line-height: 1.4;}
.article-title:hover { color: #6366f1; }

.read-btn { background: #6366f1; color: white; border: none; padding: 6px 16px; border-radius: 6px; font-size: 0.9rem; cursor: pointer; transition: background 0.2s; flex-shrink: 0;}
.read-btn:hover { background: #4f46e5; }

/* 结合自 BlogListView 的作者栏样式 */
.author-info { display: flex; align-items: center; gap: 8px; margin-bottom: 15px; }
.author-avatar { width: 28px; height: 28px; border-radius: 50%; object-fit: cover; border: 1px solid #f1f5f9; }
.author-name { font-size: 0.9rem; color: #8b5cf6; font-weight: bold; }
.clickable-author { cursor: pointer; }
.clickable-author:hover .author-name { color: #6366f1; text-decoration: underline; }

.article-intro { color: #475569; font-size: 1rem; line-height: 1.6; margin-bottom: 20px; word-wrap: break-word; }
.article-meta { display: flex; gap: 15px; font-size: 0.9rem; color: #64748b; align-items: center; flex-wrap: wrap; background: #f8fafc; padding: 10px; border-radius: 8px;}
.meta-item.time { margin-left: auto; }

.empty-state { padding: 80px 20px; text-align: center; color: #909399; background: #fafafa; border-style: dashed;}
.empty-icon { font-size: 3.5rem; margin-bottom: 15px; }
.explore-btn { margin-top: 20px; background: #10b981; color: white; border: none; padding: 10px 24px; border-radius: 8px; font-size: 1rem; cursor: pointer; transition: background 0.2s;}
.explore-btn:hover { background: #059669; }

.loading-state { text-align: center; padding: 60px; color: #909399; }
.loader { border: 4px solid #f3f3f3; border-top: 4px solid #6366f1; border-radius: 50%; width: 40px; height: 40px; animation: spin 1s linear infinite; margin: 0 auto 15px; }

.pagination { display: flex; justify-content: center; gap: 8px; margin-top: 40px; flex-wrap: wrap; }
.page-btn { padding: 8px 16px; border: 1px solid #cbd5e1; background: #fff; border-radius: 6px; cursor: pointer; color: #475569; font-weight: 500; transition: all 0.2s ease; }
.page-btn:hover:not(:disabled) { border-color: #6366f1; color: #6366f1; }
.page-btn.active { background: #6366f1; color: #fff; border-color: #6366f1; }
.page-btn:disabled { background: #f1f5f9; color: #94a3b8; border-color: #e2e8f0; cursor: not-allowed; }

@keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }

@media (max-width: 768px) {
  .article-meta { flex-direction: column; align-items: flex-start; gap: 8px;}
  .meta-item.time { margin-left: 0; }
  .article-header-row { flex-direction: column; gap: 10px;}
  .read-btn { width: 100%; }
}
</style>