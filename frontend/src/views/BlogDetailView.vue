<template>
  <div>
  <TopNavbar/>
  <div class="blog-detail-page">
    <div v-if="loading" class="loading-state">
      <div class="loader"></div>
      <p>正在从区块链和 IPFS 拉取文章数据...</p>
    </div>
    
    <div v-else class="content-layout">
      <div class="blog-main">
        <h1 class="blog-title">{{ blog.title }}</h1>
        <div class="blog-meta">
          <div class="author-info">
             <img 
               class="author-avatar" 
               :src="blog.authorAvatar ? getIpfsUrl(blog.authorAvatar) : defaultAvatar" 
               alt="avatar" 
             />
             <span>{{ blog.authorDisplay }}</span>
          </div>
          <span class="meta-item">发表于 {{ formatDate(blog.timestamp) }}</span>
          <span class="meta-item">阅读: {{ blog.viewCount }}</span>
        </div>
        
        <div class="markdown-body" v-html="renderedContent" ref="contentRef"></div>

        <div class="comments-section" id="comments-section">
          <h3>💬 评论区 ({{ comments.length }})</h3>
          
          <div v-if="commentsLoading" class="comments-loading">
            正在拉取链上评论...
          </div>
          
          <div v-else-if="comments.length === 0" class="no-comments">
            还没有人评论，来抢沙发吧！
          </div>

          <div v-else class="comments-list">
            <div v-for="comment in comments" :key="comment.id" class="comment-item">
              <div class="comment-header">
                <div class="comment-author">
                  <img :src="comment.avatar ? getIpfsUrl(comment.avatar) : defaultAvatar" class="comment-avatar" />
                  <span class="comment-name">{{ comment.displayAuthor }}</span>
                  <span class="author-badge" v-if="comment.isAuthor">作者</span>
                </div>
                <span class="comment-time">{{ formatDate(comment.date) }}</span>
              </div>
              <div class="comment-content">
                {{ comment.content }}
              </div>
            </div>
          </div>

          <div class="comment-input-area">
            <template v-if="!currentUserAddress">
              <div class="login-prompt">请先连接钱包后发表评论</div>
            </template>
            <template v-else>
              <textarea 
                v-model="newComment" 
                placeholder="写下你的想法..." 
                rows="4"
                :disabled="isSubmittingComment"
              ></textarea>
              <div class="comment-actions">
                <button 
                  class="submit-comment-btn" 
                  @click="submitComment" 
                  :disabled="!newComment.trim() || isSubmittingComment"
                >
                  <span v-if="isSubmittingComment">链上确认中...</span>
                  <span v-else>发表评论</span>
                </button>
              </div>
            </template>
          </div>

        </div>
      </div>

      <aside class="blog-sidebar">
        <div class="toc-container" :class="{ 'is-fixed': isTocFixed }">
          <h3>目录</h3>
          <ul class="toc-list" v-if="toc.length > 0">
            <li 
              v-for="item in toc" 
              :key="item.id"
              :style="{ paddingLeft: `${(item.level - 1) * 15}px` }"
              :class="{ active: activeHeading === item.id }"
            >
              <a :href="`#${item.id}`" @click.prevent="scrollToHeading(item.id)">
                {{ item.text }}
              </a>
            </li>
          </ul>
          <div v-else class="no-toc">暂无目录</div>
        </div>
      </aside>
    </div>

    <button 
      class="back-to-top" 
      :class="{ 'show': showBackToTop }"
      @click="scrollToTop"
    >
      ↑ 顶部
    </button>
  </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted, nextTick } from 'vue';
import { useRoute } from 'vue-router';
import { ethers } from 'ethers';
import { marked } from 'marked';
import DOMPurify from 'dompurify';
import TopNavbar from '../components/TopNavbar.vue';
import { getContract } from '../utils/web3'; 
import { getIpfsUrl } from '../utils/ipfs'; 

const route = useRoute();
const blogId = route.params.id; 
const loading = ref(true);
const blog = ref({});
const renderedContent = ref('');
const contentRef = ref(null);

const defaultAvatar = 'https://images.cnblogs.com/cnblogs_com/blogs/784559/galleries/2387286/o_240325050905_tx.png';
const comments = ref([]);
const commentsLoading = ref(true);
const newComment = ref('');
const isSubmittingComment = ref(false);

const currentUserAddress = ref('');
const toc = ref([]);
const activeHeading = ref('');
const isTocFixed = ref(false);
const showBackToTop = ref(false);

const formatAddress = (addr) => {
  if (!addr) return '';
  if (addr.startsWith('0x') && addr.length > 20) {
    return `${addr.slice(0, 6)}...${addr.slice(-4)}`;
  }
  return addr; 
};

const formatDate = (ts) => {
  if (!ts) return '';
  return new Date(ts * 1000).toLocaleString(undefined, {
    year: 'numeric', month: '2-digit', day: '2-digit',
    hour: '2-digit', minute: '2-digit'
  });
};

const getCurrentUser = async () => {
  try {
    const provider = new ethers.BrowserProvider(window.ethereum);
    const signer = await provider.getSigner();
    currentUserAddress.value = await signer.getAddress();
  } catch (error) {
    console.warn("未连接钱包");
  }
};

const fetchBlogDetail = async () => {
  loading.value = true;
  try {
    const contract = getContract();
    const detail = await contract.getBlogDetail(blogId);
    
    if (detail[7]) {
      throw new Error("该博客已被作者隐藏");
    }

    const authorAddress = detail[0];
    let authorName = await contract.getUsername(authorAddress);
    const authorAvatarCid = await contract.getAvatar(authorAddress);
    
    const ipfsCID = detail[3];
    let markdownContent = '';
    if (ipfsCID) {
      try {
        const fileUrl = getIpfsUrl(ipfsCID);
        const response = await fetch(fileUrl);
        if (!response.ok) throw new Error("Fetch failed");
        markdownContent = await response.text(); 
      } catch (ipfsErr) {
        markdownContent = `> **加载失败**：无法从 IPFS 获取正文。`;
      }
    }

    blog.value = {
      title: detail[1],
      authorAddress: authorAddress,
      authorDisplay: authorName || formatAddress(authorAddress),
      authorAvatar: authorAvatarCid,
      timestamp: Number(detail[6]),
      viewCount: detail[5].toString(),
      content: markdownContent
    };

    const rawHtml = marked.parse(blog.value.content);
    renderedContent.value = DOMPurify.sanitize(rawHtml);
    try {
      if(currentUserAddress.value){
        const hasViewed = await contract.hasViewed(currentUserAddress.value, blogId);
        if(!hasViewed){
        }
      }
    } catch(e) {}

    loading.value = false;
    await nextTick();
    generateToc();
    fetchComments();

  } catch (error) {
    console.error("加载文章失败:", error);
    renderedContent.value = `<p style="color:red; text-align:center;">⚠️ 加载失败：${error.message}</p>`;
    loading.value = false; 
  } 
};

const fetchComments = async () => {
  commentsLoading.value = true;
  try {
    const contract = getContract();
    const fetchedComments = [];
    let currentIndex = 0;
    
    while (true) {
      try {
        const commentData = await contract.getComment(blogId, currentIndex);
        const commenterAddress = commentData[0];
        const commenterName = await contract.getUsername(commenterAddress);
        const commenterAvatarCid = await contract.getAvatar(commenterAddress);

        fetchedComments.push({
          id: currentIndex,
          buyer: commenterAddress,
          displayAuthor: commenterName || formatAddress(commenterAddress),
          avatar: commenterAvatarCid,
          date: Number(commentData[1]),
          content: commentData[2],
          isAuthor: commenterAddress.toLowerCase() === blog.value.authorAddress.toLowerCase()
        });
        currentIndex++;
      } catch (e) {
        break; 
      }
    }
    
    comments.value = fetchedComments.reverse();
  } catch (err) {
    console.error("获取评论失败", err);
  } finally {
    commentsLoading.value = false;
  }
};
const submitComment = async () => {
  if (!newComment.value.trim() || isSubmittingComment.value) return;
  
  isSubmittingComment.value = true;
  try {
    const contract = getContract();
    const tx = await contract.addComment(blogId, newComment.value.trim());
    await tx.wait();
    
    newComment.value = '';
    await fetchComments();
    
    const commentSection = document.getElementById('comments-section');
    if (commentSection) {
       commentSection.scrollIntoView({ behavior: 'smooth' });
    }
  } catch (error) {
    console.error("评论失败", error);
    alert(`评论失败: ${error.shortMessage || error.message}`);
  } finally {
    isSubmittingComment.value = false;
  }
};
const generateToc = () => {
  if (!contentRef.value) return;
  const headings = contentRef.value.querySelectorAll('h1, h2, h3, h4, h5, h6');
  const tocArray = [];
  headings.forEach((heading, index) => {
    const id = `heading-${index}`;
    heading.id = id; 
    tocArray.push({
      id,
      text: heading.innerText,
      level: parseInt(heading.tagName.replace('H', ''), 10),
      element: heading
    });
  });
  toc.value = tocArray;
};

const scrollToHeading = (id) => {
  const element = document.getElementById(id);
  if (element) {
    const offset = 80; 
    const top = element.getBoundingClientRect().top + window.scrollY - offset;
    window.scrollTo({ top, behavior: 'smooth' });
  }
};

const scrollToTop = () => {
  window.scrollTo({ top: 0, behavior: 'smooth' });
};

const handleScroll = () => {
  const scrollTop = window.scrollY;
  showBackToTop.value = scrollTop > 300;
  isTocFixed.value = scrollTop > 200;

  if (toc.value.length === 0) return;
  
  let currentActiveId = toc.value[0].id;
  for (let i = 0; i < toc.value.length; i++) {
    const item = toc.value[i];
    const element = document.getElementById(item.id);
    if (element && element.getBoundingClientRect().top <= 100) {
      currentActiveId = item.id;
    }
  }
  activeHeading.value = currentActiveId;
};

onMounted(async () => {
  await getCurrentUser();
  fetchBlogDetail();
  window.addEventListener('scroll', handleScroll);
});

onUnmounted(() => {
  window.removeEventListener('scroll', handleScroll);
});
</script>

<style scoped>
.blog-detail-page { max-width: 1200px; margin: 0 auto; padding: 2rem 1rem; position: relative; }
.content-layout { display: flex; gap: 2rem; align-items: flex-start; }
.blog-main { flex: 1; background: white; padding: 2.5rem; border-radius: 12px; box-shadow: 0 4px 20px rgba(0, 0, 0, 0.05); min-width: 0; }
.blog-title { font-size: 2.2rem; color: #1e293b; margin-bottom: 1rem; }

.blog-meta { color: #64748b; font-size: 0.95rem; margin-bottom: 2rem; padding-bottom: 1.5rem; border-bottom: 1px solid #e2e8f0; display: flex; align-items: center; gap: 2rem; }
.author-info { display: flex; align-items: center; gap: 8px; font-weight: 600; color: #334155; }
.author-avatar { width: 32px; height: 32px; border-radius: 50%; object-fit: cover; border: 1px solid #f1f5f9; }
.meta-item { display: flex; align-items: center; }

.comments-section { margin-top: 4rem; padding-top: 2rem; border-top: 2px dashed #e2e8f0; }
.comments-section h3 { font-size: 1.4rem; color: #1e293b; margin-bottom: 1.5rem; }

.comments-loading, .no-comments { text-align: center; padding: 2rem; color: #94a3b8; background: #f8fafc; border-radius: 8px; margin-bottom: 2rem; }

.comment-item { padding: 1.2rem 0; border-bottom: 1px solid #f1f5f9; }
.comment-item:last-child { border-bottom: none; }

.comment-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 0.8rem; }
.comment-author { display: flex; align-items: center; gap: 10px; }
.comment-avatar { width: 36px; height: 36px; border-radius: 50%; object-fit: cover; }
.comment-name { font-weight: 600; color: #334155; font-size: 0.95rem; }
.author-badge { background: #6366f1; color: white; font-size: 0.7rem; padding: 2px 6px; border-radius: 4px; }
.comment-time { font-size: 0.85rem; color: #94a3b8; }
.comment-content { color: #475569; line-height: 1.6; font-size: 0.95rem; padding-left: 46px; white-space: pre-wrap; }

.comment-input-area { margin-top: 2rem; background: #f8fafc; padding: 1.5rem; border-radius: 8px; border: 1px solid #e2e8f0; }
.login-prompt { text-align: center; color: #64748b; padding: 1rem 0; }
.comment-input-area textarea { width: 100%; border: 1px solid #cbd5e1; border-radius: 6px; padding: 1rem; font-size: 1rem; font-family: inherit; resize: vertical; box-sizing: border-box; transition: border-color 0.2s; }
.comment-input-area textarea:focus { outline: none; border-color: #6366f1; }
.comment-actions { display: flex; justify-content: flex-end; margin-top: 1rem; }
.submit-comment-btn { background: #6366f1; color: white; border: none; padding: 10px 24px; border-radius: 6px; font-weight: 600; cursor: pointer; transition: background 0.2s; }
.submit-comment-btn:hover:not(:disabled) { background: #4f46e5; }
.submit-comment-btn:disabled { background: #cbd5e1; cursor: not-allowed; }

.blog-sidebar { width: 280px; flex-shrink: 0; }
.toc-container { background: white; padding: 1.5rem; border-radius: 12px; box-shadow: 0 4px 20px rgba(0, 0, 0, 0.05); transition: all 0.3s ease; }
.toc-container.is-fixed { position: sticky; top: 20px; }
.toc-container h3 { margin-top: 0; margin-bottom: 1rem; font-size: 1.1rem; color: #334155; border-bottom: 1px solid #f1f5f9; padding-bottom: 0.8rem; }
.toc-list { list-style: none; padding: 0; margin: 0; max-height: calc(100vh - 120px); overflow-y: auto; }
.toc-list li { margin-bottom: 0.6rem; line-height: 1.5; }
.toc-list a { color: #64748b; text-decoration: none; font-size: 0.9rem; transition: color 0.2s; display: block; }
.toc-list a:hover { color: #6366f1; }
.toc-list li.active a { color: #6366f1; font-weight: 600; }

.back-to-top { position: fixed; bottom: 40px; right: 40px; width: 48px; height: 48px; border-radius: 50%; background-color: #6366f1; color: white; border: none; font-weight: bold; cursor: pointer; box-shadow: 0 4px 12px rgba(99, 102, 241, 0.3); opacity: 0; visibility: hidden; transition: all 0.3s ease; z-index: 1000; }
.back-to-top.show { opacity: 1; visibility: visible; }
.back-to-top:hover { background-color: #4f46e5; transform: translateY(-3px); box-shadow: 0 6px 16px rgba(99, 102, 241, 0.4); }

.loading-state { text-align: center; padding: 100px 20px; color: #64748b; }
.loader { border: 4px solid #f3f3f3; border-top: 4px solid #6366f1; border-radius: 50%; width: 40px; height: 40px; animation: spin 1s linear infinite; margin: 0 auto 15px; }
@keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }

.markdown-body { line-height: 1.8; font-size: 1.05rem; color: #334155; }
.markdown-body :deep(h1), .markdown-body :deep(h2), .markdown-body :deep(h3) { margin-top: 1.8rem; margin-bottom: 1rem; color: #0f172a; }
.markdown-body :deep(p) { margin-bottom: 1rem; }
.markdown-body :deep(pre) { background: #f8fafc; padding: 1rem; border-radius: 8px; overflow-x: auto; }
.markdown-body :deep(code) { background: #f1f5f9; padding: 0.2rem 0.4rem; border-radius: 4px; color: #ef4444; }
.markdown-body :deep(pre code) { background: none; color: inherit; padding: 0; }
.markdown-body :deep(img) { max-width: 100%; border-radius: 8px; }
</style>