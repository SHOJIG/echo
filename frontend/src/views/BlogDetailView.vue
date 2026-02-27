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
          <span>👤 作者: {{ formatAddress(blog.author) }}</span>
          <span>📅 时间: {{ formatDate(blog.timestamp) }}</span>
        </div>
        <div class="markdown-body" v-html="renderedContent" ref="contentRef"></div>
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
import { marked } from 'marked';
import DOMPurify from 'dompurify';
import TopNavbar from '../components/TopNavbar.vue';
// 引入真实的 Web3 和 IPFS 工具
import { getContract } from '../utils/web3'; 
// 1. 替换为正确的导入方法
import { getIpfsUrl } from '../utils/ipfs'; 

const route = useRoute();
const loading = ref(true);
const blog = ref({});
const renderedContent = ref('');
const contentRef = ref(null);

// 目录相关
const toc = ref([]);
const activeHeading = ref('');
const isTocFixed = ref(false);

// 返回顶部相关
const showBackToTop = ref(false);

// 格式化地址
const formatAddress = (addr) => {
  if (!addr) return '';
  if (addr.startsWith('0x') && addr.length > 20) {
    return `${addr.slice(0, 6)}...${addr.slice(-4)}`;
  }
  return addr; 
};

// 格式化时间戳
const formatDate = (ts) => {
  if (!ts) return '';
  return new Date(ts * 1000).toLocaleString();
};

// 真实的获取文章详情逻辑
const fetchBlogDetail = async () => {
  loading.value = true;
  try {
    const blogId = route.params.id; // 从路由获取 URL 上的 ID
    const contract = getContract();
    
    // 1. 从合约获取博客元数据
    const detail = await contract.getBlogDetail(blogId);
    
    // 如果文章被隐藏，抛出错误
    if (detail[7]) {
      throw new Error("该博客已被作者隐藏");
    }

    // 2. 尝试获取作者用户名
    let displayAuthor = detail[0];
    try {
      const authorName = await contract.getUsername(detail[0]);
      if (authorName) {
        displayAuthor = authorName;
      }
    } catch (e) {
      console.warn("获取用户名失败，降级显示钱包地址");
    }

    // 3. 从 IPFS 拉取正文内容
    const ipfsCID = detail[3];
    let markdownContent = '';
    if (ipfsCID) {
      try {
        // [修改处]：先通过 getIpfsUrl 拿到完整的 HTTP 链接
        const fileUrl = getIpfsUrl(ipfsCID);
        // [修改处]：使用浏览器自带的 fetch API 请求这个链接拿回文本
        const response = await fetch(fileUrl);
        if (!response.ok) {
          throw new Error(`网络请求响应不是 OK，状态码: ${response.status}`);
        }
        // 解析文本内容 (因为存上去的是 markdown 纯文本)
        markdownContent = await response.text(); 
      } catch (ipfsErr) {
        console.error("拉取 IPFS 文件失败:", ipfsErr);
        markdownContent = `> **加载失败**：无法从 IPFS 获取文章内容。可能是网关访问不稳定，请稍后再试或更换网关。\n\nCID: \`${ipfsCID}\``;
      }
    } else {
      markdownContent = '*这篇文章没有正文内容 (CID 为空)*';
    }

    // 4. 组装数据
    blog.value = {
      title: detail[1],
      author: displayAuthor,
      timestamp: Number(detail[6]),
      content: markdownContent
    };

    // 5. 将 Markdown 转为 HTML，并进行消毒防 XSS
    const rawHtml = marked.parse(blog.value.content);
    renderedContent.value = DOMPurify.sanitize(rawHtml);

    // ==================【关键修改区域】==================
    // 先把 loading 设置为 false，让模板里的 v-else 区域开始渲染
    loading.value = false;

    // 等待 DOM 真正渲染完毕
    await nextTick();
    
    // 这时候再去抓取 h1~h6 标题，就能抓到了！
    generateToc();
    // =================================================

  } catch (error) {
    console.error("加载文章失败:", error);
    renderedContent.value = `<p style="color:red; text-align:center;">⚠️ 加载文章失败：${error.message || '请检查网络或确认该文章是否存在'}</p>`;
    // 出错时也要确保关闭 loading
    loading.value = false; 
  } 
  // 【注意】删除了原来的 finally { loading.value = false; } 代码块
};

// 生成目录树 (H1~H6)
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

// 点击目录平滑滚动
const scrollToHeading = (id) => {
  const element = document.getElementById(id);
  if (element) {
    const offset = 80; 
    const top = element.getBoundingClientRect().top + window.scrollY - offset;
    window.scrollTo({ top, behavior: 'smooth' });
  }
};

// 返回顶部
const scrollToTop = () => {
  window.scrollTo({ top: 0, behavior: 'smooth' });
};

// 监听滚动事件处理高亮
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

onMounted(() => {
  fetchBlogDetail();
  window.addEventListener('scroll', handleScroll);
});

onUnmounted(() => {
  window.removeEventListener('scroll', handleScroll);
});
</script>
<style scoped>
.blog-detail-page {
  max-width: 1200px;
  margin: 0 auto;
  padding: 2rem 1rem;
  position: relative;
}

.content-layout {
  display: flex;
  gap: 2rem;
  align-items: flex-start;
}

.blog-main {
  flex: 1;
  background: white;
  padding: 2.5rem;
  border-radius: 12px;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.05);
  min-width: 0; 
}

.blog-title {
  font-size: 2.2rem;
  color: #1e293b;
  margin-bottom: 1rem;
}

.blog-meta {
  color: #64748b;
  font-size: 0.95rem;
  margin-bottom: 2rem;
  padding-bottom: 1rem;
  border-bottom: 1px solid #e2e8f0;
  display: flex;
  gap: 2rem;
}

/* 右侧侧边栏 */
.blog-sidebar {
  width: 280px;
  flex-shrink: 0;
}

.toc-container {
  background: white;
  padding: 1.5rem;
  border-radius: 12px;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.05);
  transition: all 0.3s ease;
}

.toc-container.is-fixed {
  position: sticky;
  top: 20px; /* 吸顶距离 */
}

.toc-container h3 {
  margin-top: 0;
  margin-bottom: 1rem;
  font-size: 1.1rem;
  color: #334155;
  border-bottom: 1px solid #f1f5f9;
  padding-bottom: 0.8rem;
}

.toc-list {
  list-style: none;
  padding: 0;
  margin: 0;
  max-height: calc(100vh - 120px);
  overflow-y: auto;
}

.toc-list li {
  margin-bottom: 0.6rem;
  line-height: 1.5;
}

.toc-list a {
  color: #64748b;
  text-decoration: none;
  font-size: 0.9rem;
  transition: color 0.2s;
  display: block;
}

.toc-list a:hover {
  color: #6366f1;
}

.toc-list li.active a {
  color: #6366f1;
  font-weight: 600;
}

/* 返回顶部按钮 */
.back-to-top {
  position: fixed;
  bottom: 40px;
  right: 40px;
  width: 48px;
  height: 48px;
  border-radius: 50%;
  background-color: #6366f1;
  color: white;
  border: none;
  font-weight: bold;
  cursor: pointer;
  box-shadow: 0 4px 12px rgba(99, 102, 241, 0.3);
  opacity: 0;
  visibility: hidden;
  transition: all 0.3s ease;
  z-index: 1000;
}

.back-to-top.show {
  opacity: 1;
  visibility: visible;
}

.back-to-top:hover {
  background-color: #4f46e5;
  transform: translateY(-3px);
  box-shadow: 0 6px 16px rgba(99, 102, 241, 0.4);
}

.loading-state { text-align: center; padding: 100px 20px; color: #64748b; }
.loader { border: 4px solid #f3f3f3; border-top: 4px solid #6366f1; border-radius: 50%; width: 40px; height: 40px; animation: spin 1s linear infinite; margin: 0 auto 15px; }
@keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }

/* Markdown 样式 */
.markdown-body {
  line-height: 1.8;
  font-size: 1.05rem;
  color: #334155;
}
.markdown-body :deep(h1), .markdown-body :deep(h2), .markdown-body :deep(h3) {
  margin-top: 1.8rem;
  margin-bottom: 1rem;
  color: #0f172a;
}
.markdown-body :deep(p) { margin-bottom: 1rem; }
.markdown-body :deep(pre) { background: #f8fafc; padding: 1rem; border-radius: 8px; overflow-x: auto; }
.markdown-body :deep(code) { background: #f1f5f9; padding: 0.2rem 0.4rem; border-radius: 4px; color: #ef4444; }
.markdown-body :deep(pre code) { background: none; color: inherit; padding: 0; }
.markdown-body :deep(img) { max-width: 100%; border-radius: 8px; }
</style>