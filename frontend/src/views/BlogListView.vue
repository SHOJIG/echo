<template>
  <div>
    <TopNavbar/>

    <div class="all-blogs-dashboard">
      <header class="page-header animate__animated animate__fadeInDown">
        <div class="title-section">
          <h2>🌐 发现 Web3 博客</h2>
          <p>探索去中心化世界里的所有声音</p>
        </div>
        
        <div class="header-actions">
          <div class="search-box">
            <span class="search-icon">🔍</span>
            <input 
              v-model="searchQuery" 
              type="text" 
              placeholder="搜索或使用 title: 和 author:" 
              class="search-input"
            />
          </div>
          <button class="back-btn" @click="$emit('go-back')">返回我的空间</button>
        </div>
      </header>

      <main class="dash-content animate__animated animate__fadeInUp">
        <div v-if="loading" class="loading-state">
          <div class="loader"></div>
          <p>正在从区块链拉取所有博客数据...</p>
        </div>
        
        <div v-else-if="allBlogs.length === 0" class="empty-state">
          目前还没有任何人发布博客哦，快去发布第一篇吧！
        </div>

        <div v-else-if="filteredBlogs.length === 0" class="empty-state">
          未找到与 "<span style="color: #6366f1;">{{ searchQuery }}</span>" 相关的博客。
        </div>

        <div v-else>
          <div class="masonry-layout">
            <div class="masonry-column" v-for="(column, colIndex) in masonryColumns" :key="colIndex">
              
              <div v-for="blog in column" :key="blog.id" class="blog-card">
                <h4 @click="handleAction(blog)" class="clickable-title">{{ blog.name }}</h4>
                
                <div class="author-info clickable-author" @click="searchByAuthor(blog.authorDisplay)" title="搜索该作者的所有文章">
                  <img 
                    class="author-avatar" 
                    :src="blog.authorAvatar ? getIpfsUrl(blog.authorAvatar) : defaultAvatar" 
                    alt="avatar" 
                  />
                  <span class="author-name">{{ blog.authorDisplay }}</span>
                </div>

                <p class="intro">{{ blog.intro }}</p>
                
                <div class="blog-meta">
                  <span>👁️ {{ blog.viewCount }}</span>
                  <span>💰 {{ blog.price }} BLG</span>
                </div>
                
                <div class="blog-footer">
                  <small>{{ blog.publishDate }}</small>
                  <button 
                    class="action-btn" 
                    :class="{ 'subscribe-btn': !blog.hasAccess }"
                    @click="handleAction(blog)"
                    :disabled="blog.isPurchasing"
                  >
                    <span v-if="blog.isPurchasing">确认中...</span>
                    <span v-else>{{ blog.hasAccess ? '查看' : '订阅' }}</span>
                  </button>
                </div>
              </div>

            </div>
          </div>

          <div class="pagination" v-if="totalPages > 1">
            <button class="page-btn" :disabled="currentPage === 1" @click="changePage(currentPage - 1)">上一页</button>
            <button 
              v-for="page in totalPages" :key="page"
              class="page-btn" :class="{ active: currentPage === page }" @click="changePage(page)"
            >
              {{ page }}
            </button>
            <button class="page-btn" :disabled="currentPage === totalPages" @click="changePage(currentPage + 1)">下一页</button>
          </div>
        </div>
      </main>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, watch, onMounted, onUnmounted } from 'vue';
import { ethers } from 'ethers';
import { useRouter } from 'vue-router';
import { getContract } from '../utils/web3';
import { getIpfsUrl } from '../utils/ipfs'; 
import TopNavbar from '../components/TopNavbar.vue'; 

const emit = defineEmits(['go-back']);
const router = useRouter();

const allBlogs = ref([]);
const loading = ref(true);
const currentUserAddress = ref('');
const defaultAvatar = getIpfsUrl("bafkreihxhqdm4ixe6cwlfblkisruar2zn56rek2ybl6qliar7djizccoiq");

// ================= 搜索与过滤逻辑 =================
const searchQuery = ref('');

// [新增] 点击作者触发搜索的方法
const searchByAuthor = (authorName) => {
  searchQuery.value = `author:${authorName}`;
  // 滚动到顶部让用户看到搜索结果的变化
  window.scrollTo({ top: 0, behavior: 'smooth' });
};

const filteredBlogs = computed(() => {
  if (!searchQuery.value.trim()) {
    return allBlogs.value;
  }
  
  const query = searchQuery.value.trim().toLowerCase();
  
  let authorQuery = '';
  let titleQuery = '';
  let generalTerms = [];
  
  const tokens = query.split(/\s+/);
  
  tokens.forEach(token => {
    if (token.startsWith('author:')) {
      authorQuery = token.replace('author:', '');
    } else if (token.startsWith('title:')) {
      titleQuery = token.replace('title:', '');
    } else {
      generalTerms.push(token);
    }
  });
  
  const generalStr = generalTerms.join(' ');

  return allBlogs.value.filter(blog => {
    const blogName = blog.name.toLowerCase();
    const blogAuthor = blog.authorDisplay.toLowerCase();
    
    let match = true;
    
    if (authorQuery && !blogAuthor.includes(authorQuery)) {
      match = false;
    }
    
    if (titleQuery && !blogName.includes(titleQuery)) {
      match = false;
    }
    
    if (generalStr && !blogName.includes(generalStr) && !blogAuthor.includes(generalStr)) {
      match = false;
    }
    
    return match;
  });
});

watch(searchQuery, () => {
  currentPage.value = 1;
});
// =================================================================

const currentPage = ref(1);
const pageSize = 5; 
const totalPages = computed(() => Math.ceil(filteredBlogs.value.length / pageSize));
const paginatedBlogs = computed(() => {
  const start = (currentPage.value - 1) * pageSize;
  return filteredBlogs.value.slice(start, start + pageSize);
});

const changePage = (page) => {
  if (page >= 1 && page <= totalPages.value) {
    currentPage.value = page;
    window.scrollTo({ top: 0, behavior: 'smooth' }); 
  }
};

const colCount = ref(3); 

const updateColCount = () => {
  if (window.innerWidth <= 600) colCount.value = 1;
  else if (window.innerWidth <= 900) colCount.value = 2;
  else colCount.value = 3;
};

const masonryColumns = computed(() => {
  const cols = Array.from({ length: colCount.value }, () => []);
  paginatedBlogs.value.forEach((blog, index) => {
    cols[index % colCount.value].push(blog);
  });
  return cols;
});

const formatAddress = (address) => {
  if (!address) return '';
  return `${address.slice(0, 10)}...${address.slice(-6)}`;
};

const getCurrentUser = async () => {
  try {
    const provider = new ethers.BrowserProvider(window.ethereum);
    const signer = await provider.getSigner();
    currentUserAddress.value = await signer.getAddress();
  } catch (error) {
    console.warn("未能获取当前钱包地址");
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
        const authorAddress = detail[0];
        const authorName = await contract.getUsername(authorAddress);
        const avatarCid = await contract.getAvatar(authorAddress);
        const isOwner = currentUserAddress.value && (authorAddress.toLowerCase() === currentUserAddress.value.toLowerCase());
        let hasPurchased = false;
        
        if (currentUserAddress.value && !isOwner) {
          try {
            hasPurchased = await contract.hasPurchased(currentUserAddress.value, currentId);
          } catch (e) {}
        }

        blogsData.push({
          id: currentId.toString(),
          owner: authorAddress,
          authorDisplay: authorName || formatAddress(authorAddress),
          authorAvatar: avatarCid,
          name: detail[1],
          intro: detail[2],
          ipfsCID: detail[3],
          price: ethers.formatEther(detail[4]),
          viewCount: detail[5].toString(),
          publishDate: new Date(Number(detail[6]) * 1000).toLocaleDateString(),
          isHidden: detail[7],
          hasAccess: isOwner || hasPurchased, 
          isPurchasing: false 
        });
      }
    }
    allBlogs.value = blogsData.reverse();
    currentPage.value = 1; 
  } catch (error) {
    console.error("获取失败:", error);
  } finally {
    loading.value = false;
  }
};

const handleAction = async (blog) => {
  if (blog.isPurchasing) return;
  if (blog.hasAccess) {
    router.push(`/blog/${blog.id}`);
  } else {
    blog.isPurchasing = true;
    try {
      const contract = getContract();
      const tx = await contract.purchaseBlog(blog.id);
      await tx.wait(); 
      blog.hasAccess = true;
      router.push(`/blog/${blog.id}`);
    } catch (error) {
      console.error(error);
    } finally {
      blog.isPurchasing = false;
    }
  }
};

onMounted(() => {
  fetchAllBlogs();
  updateColCount(); 
  window.addEventListener('resize', updateColCount); 
});

onUnmounted(() => {
  window.removeEventListener('resize', updateColCount); 
});
</script>

<style scoped>
.all-blogs-dashboard { max-width: 1200px; margin: 0 auto; padding: 20px; }
.page-header { display: flex; justify-content: space-between; align-items: center; padding-bottom: 20px; border-bottom: 1px solid #e2e8f0; margin-bottom: 30px;}
.title-section h2 { margin-bottom: 5px; color: #1e293b; }
.title-section p { color: #64748b; font-size: 0.9rem; }

.header-actions { display: flex; align-items: center; gap: 15px; flex-wrap: wrap; }
.search-box { position: relative; display: flex; align-items: center; }
.search-icon { position: absolute; left: 10px; font-size: 0.9rem; color: #94a3b8; pointer-events: none; }
.search-input { width: 260px; padding: 8px 12px 8px 32px; border: 1px solid #cbd5e1; border-radius: 6px; font-size: 0.9rem; outline: none; transition: all 0.2s ease; color: #334155; }
.search-input:focus { border-color: #6366f1; box-shadow: 0 0 0 3px rgba(99, 102, 241, 0.1); width: 290px; }

@media (max-width: 600px) {
  .header-actions { width: 100%; justify-content: space-between; margin-top: 15px; }
  .search-box { flex-grow: 1; }
  .search-input { width: 100%; }
  .search-input:focus { width: 100%; }
}

.back-btn { padding: 8px 16px; background: white; border: 1px solid #cbd5e1; border-radius: 6px; cursor: pointer; transition: background 0.2s; white-space: nowrap;}
.back-btn:hover { background: #f8fafc; }

.masonry-layout { display: flex; gap: 24px; align-items: flex-start; }
.masonry-column { flex: 1; display: flex; flex-direction: column; gap: 24px; min-width: 0; }

.blog-card { background: white; border: 1px solid #e2e8f0; padding: 24px; border-radius: 16px; box-shadow: 0 4px 6px rgba(0,0,0,0.02); transition: transform 0.2s, box-shadow 0.2s; display: flex; flex-direction: column; }
.blog-card:hover { transform: translateY(-4px); box-shadow: 0 12px 20px rgba(0,0,0,0.08); }
.blog-card h4 { font-size: 1.25rem; margin-bottom: 12px; color: #0f172a; line-height: 1.4; }

.author-info { display: flex; align-items: center; gap: 8px; margin-bottom: 15px; }
.author-avatar { width: 26px; height: 26px; border-radius: 50%; object-fit: cover; border: 1px solid #f1f5f9; }
.author-name { font-size: 0.85rem; color: #8b5cf6; font-weight: bold; }

/* [修改] 鼠标悬浮在作者栏时的交互样式（仅下划线和变色） */
.clickable-author { cursor: pointer; }
.clickable-author:hover .author-name { color: #6366f1; text-decoration: underline; }

.intro { color: #475569; font-size: 0.95rem; margin-bottom: 20px; line-height: 1.6; word-wrap: break-word; }
.blog-meta { display: flex; justify-content: space-between; font-size: 0.85rem; margin-bottom: 15px; padding: 10px; background: #f8fafc; border-radius: 8px; font-weight: 500;}
.blog-footer { display: flex; justify-content: space-between; align-items: center; border-top: 1px solid #f1f5f9; padding-top: 15px; }
.blog-footer small { color: #94a3b8; font-size: 0.8rem; }

.action-btn { padding: 6px 14px; background: #6366f1; color: white; border: none; border-radius: 6px; cursor: pointer; font-size: 0.9rem; transition: background 0.2s; }
.action-btn:hover { background: #4f46e5; }
.action-btn:disabled { background: #94a3b8; cursor: not-allowed; opacity: 0.8; }
.subscribe-btn { background: #f59e0b; }
.subscribe-btn:hover { background: #d97706; }

.clickable-title { cursor: pointer; transition: color 0.2s ease; }
.clickable-title:hover { color: #6366f1; }

.loading-state, .empty-state { text-align: center; padding: 60px; color: #64748b; background: white; border: 1px dashed #cbd5e1; border-radius: 12px; }
.loader { border: 4px solid #f3f3f3; border-top: 4px solid #6366f1; border-radius: 50%; width: 40px; height: 40px; animation: spin 1s linear infinite; margin: 0 auto 15px; }
@keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }

.pagination { display: flex; justify-content: center; gap: 8px; margin-top: 40px; flex-wrap: wrap; }
.page-btn { padding: 8px 16px; border: 1px solid #cbd5e1; background: #fff; border-radius: 6px; cursor: pointer; color: #475569; font-weight: 500; transition: all 0.2s ease; }
.page-btn:hover:not(:disabled) { border-color: #6366f1; color: #6366f1; }
.page-btn.active { background: #6366f1; color: #fff; border-color: #6366f1; }
.page-btn:disabled { background: #f1f5f9; color: #94a3b8; border-color: #e2e8f0; cursor: not-allowed; }
</style>