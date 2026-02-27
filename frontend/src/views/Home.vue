<template>
  <div class="dashboard-page">
    
    <TopNavbar />

    <div class="home_center_box">
      <div class="layout-container">
        
        <div class="left-content">
          <div class="card mobile-card mobile-top-card animate__animated animate__fadeIn">
            <div class="profile-banner"></div>
            <div class="mobile-profile">
              <img class="avatar-img" :src="userAvatar" alt="avatar" />
              <h3>{{ username || shortAddress }}</h3>
              <p class="bio">Web3 内容创作者</p>
            </div>
          </div>

          <div class="article-list-section animate__animated animate__fadeInUp">
            <h3 class="section-title">📚 我发布的文章</h3>
            
            <div v-if="loading" class="loading-state">
              <div class="loader"></div>
              <p>正在同步链上数据...</p>
            </div>
            
            <div v-else-if="myBlogs.length === 0" class="empty-state card">
              <div class="empty-icon">📝</div>
              <p>你还没有在链上发布过文章，快去右侧发布第一篇吧！</p>
            </div>

            <div v-else class="article-list">
              <div v-for="blog in myBlogs" :key="blog.id" class="article-card card card-hover">
                <div class="article-content">
                  <h4 class="article-title">{{ blog.name }}</h4>
                  <p class="article-intro">{{ blog.intro }}</p>
                  <div class="article-meta">
                    <span class="meta-item">👁️ 浏览: {{ blog.viewCount }}</span>
                    <span class="meta-item">💰 价格: {{ blog.price }} BLG</span>
                    <span class="meta-item time">📅 {{ new Date(Number(blog.publishDate) * 1000).toLocaleString() }}</span>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <div class="card mobile-card mobile-bottom-card animate__animated animate__fadeIn">
            <div class="card-inner-padding">
              <h4 class="card-title">📊 数据统计</h4>
              <div class="site-info">
                <div class="info-row">
                  <span>总发布文章：</span>
                  <span class="value">{{ totalArticles }} 篇</span>
                </div>
                <div class="info-row">
                  <span>总计浏览量：</span>
                  <span class="value">{{ totalViews }} 次</span>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div class="right-sidebar animate__animated animate__fadeInRight">
          <div class="card profile-card card-hover">
            <div class="profile-banner"></div>
            <div class="profile-header">
              <img class="avatar-img" :src="userAvatar" alt="avatar" />
              <h3 class="wallet-address">{{ username || shortAddress }}</h3>
              <p class="bio">Web3 内容创作者</p>
            </div>
            <div class="profile-stats">
              <div class="stat-item">
                <span class="stat-value">{{ totalArticles }}</span>
                <span class="stat-label">文章</span>
              </div>
              <div class="stat-item">
                <span class="stat-value">{{ totalViews }}</span>
                <span class="stat-label">总访问</span>
              </div>
            </div>
          </div>

        </div>
        
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue';
import { ethers } from 'ethers';
import { getContract } from '../utils/web3';
import TopNavbar from '../components/TopNavbar.vue'; // 引入刚才抽离的导航栏组件
import { getIpfsUrl } from '../utils/ipfs';

const props = defineProps({
  userAddress: String
});

const emit = defineEmits(['logout', 'go-to-explore']);

// 保留此处的头像，因为中间的主体卡片依然需要展示头像
const defaultAvatar = 'https://images.cnblogs.com/cnblogs_com/blogs/784559/galleries/2387286/o_240325050905_tx.png';
const userAvatar = ref(defaultAvatar);

const shortAddress = computed(() => {
  return props.userAddress ? `${props.userAddress.slice(0, 6)}...${props.userAddress.slice(-4)}` : '';
});

const myBlogs = ref([]);
const loading = ref(true);

const totalArticles = computed(() => myBlogs.value.length);
const totalViews = computed(() => {
  return myBlogs.value.reduce((sum, blog) => sum + Number(blog.viewCount), 0);
});

const username = ref('');
const fetchUserInfo = async () => {
  if (!props.userAddress) return;
  try {
    const contract = getContract();
    // 拉取名字
    username.value = await contract.getUsername(props.userAddress);
    
    // 拉取头像
    const avatarCid = await contract.getAvatar(props.userAddress);
    if (avatarCid) {
      userAvatar.value = getIpfsUrl(avatarCid);
    }
  } catch (error) {
    username.value = props.userAddress;
    userAvatar.value = defaultAvatar;
    console.error("获取用户资料失败:", error);
  }
};

const fetchMyBlogs = async () => {
  try {
    loading.value = true;
    const contract = getContract();
    const blogIds = await contract.getUserPublishedBlogs(props.userAddress);
    
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
        price: ethers.formatEther(detail[4]),
        viewCount: detail[5].toString(),
        publishDate: detail[6].toString(),
        isHidden: detail[7]
      });
    }
    
    myBlogs.value = blogsData.reverse();
  } catch (error) {
    console.error("获取博客列表失败:", error);
  } finally {
    loading.value = false;
  }
};

onMounted(() => {
  fetchUserInfo();
  fetchMyBlogs();
});
</script>

<style scoped>
.dashboard-page {
  min-height: 100vh;
  background-color: #f8fafc; 
}

/* ================= 内容区域样式 ================= */
.home_center_box {
  max-width: 1200px;
  margin: 30px auto; 
  padding: 0 20px;
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
  color: #333;
}

.layout-container { display: flex; gap: 20px; align-items: flex-start; }
.left-content { flex: 3; display: flex; flex-direction: column; gap: 20px; }
.right-sidebar { flex: 1; display: flex; flex-direction: column; gap: 20px; min-width: 300px;}

.card {
  background: #ffffff;
  border: 1px solid #e4e7ed;
  border-radius: 8px;
  box-shadow: 0px 0px 12px rgba(0, 0, 0, 0.05);
  overflow: hidden;
  color: #303133;
  transition: all 0.3s ease;
}
.card-hover:hover {
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.1);
  transform: translateY(-2px);
}
.card-inner-padding { padding: 20px; }
.card-title { margin: 0 0 15px 0; padding-bottom: 10px; border-bottom: 1px solid #ebeef5; font-size: 1.1rem; }

.profile-card { text-align: center; }
.profile-banner {
  width: 100%;
  height: 12rem; 
  background-image: url('https://img-1325177803.cos.ap-nanjing.myqcloud.com/blog/11.jpg');
  background-size: cover;
  background-position: center;
}
.profile-header, .mobile-profile {
  position: relative;
  margin-top: -45px;
  padding: 0 20px 20px;
}
.avatar-img { width: 90px; height: 90px; border-radius: 50%; border: 4px solid #fff; background: #fff; box-shadow: 0 2px 10px rgba(0,0,0,0.1); object-fit: cover; margin: 0 auto 10px; display: block; }
.wallet-address { margin: 0 0 5px 0; font-size: 1.2rem; color: #1e293b; }
.bio { color: #909399; font-size: 0.9rem; margin-bottom: 20px; }
.profile-stats { display: flex; justify-content: space-around; border-top: 1px solid #ebeef5; padding: 20px 0; }
.stat-item { display: flex; flex-direction: column; gap: 5px; }
.stat-value { font-size: 1.2rem; font-weight: 700; color: #1e293b; }
.stat-label { font-size: 0.8rem; color: #909399; }

.section-title { margin-top: 0; margin-bottom: 15px; font-size: 1.3rem; color: #1e293b; }
.article-list { display: flex; flex-direction: column; gap: 15px; }
.article-card { padding: 20px; }
.article-title { margin: 0 0 10px 0; font-size: 1.25rem; color: #1e293b; cursor: pointer; transition: color 0.2s; }
.article-title:hover { color: #6366f1; }
.article-intro { color: #606266; font-size: 0.95rem; line-height: 1.6; margin-bottom: 15px; }
.article-meta { display: flex; gap: 15px; font-size: 0.85rem; color: #909399; align-items: center; flex-wrap: wrap;}
.meta-item { background: #f4f4f5; padding: 4px 10px; border-radius: 4px; }
.meta-item.time { background: transparent; padding: 0; margin-left: auto; }

.empty-state { padding: 60px 20px; text-align: center; color: #909399; background: #fafafa; border-style: dashed;}
.empty-icon { font-size: 3rem; margin-bottom: 15px; }
.loading-state { text-align: center; padding: 50px; color: #909399; }
.loader { border: 3px solid #f3f3f3; border-top: 3px solid #6366f1; border-radius: 50%; width: 30px; height: 30px; animation: spin 1s linear infinite; margin: 0 auto 15px; }

.mobile-card { display: none; margin-bottom: 15px; }
.mobile-profile { text-align: center; }
.info-row { display: flex; justify-content: space-between; margin-bottom: 10px; font-size: 0.95rem; color: #606266; }
.info-row .value { font-weight: 600; color: #303133; }

@keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }

@media (max-width: 900px) {
  .layout-container { flex-direction: column; }
  .right-sidebar { display: none; }
  .mobile-card { display: block; }
  .article-meta { flex-direction: column; align-items: flex-start; gap: 8px;}
  .meta-item.time { margin-left: 0; }
}
</style>