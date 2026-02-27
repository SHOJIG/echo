<template>
  <div>
    <TopNavbar />

    <div class="publish-page animate__animated animate__fadeIn">
      <div class="editor-container">
        <div class="header-actions">
          <h2>{{ isEditMode ? '✏️ 编辑文章' : '📝 创作新文章' }}</h2>
        </div>

        <div class="input-group">
          <input v-model="form.name" type="text" class="title-input" placeholder="输入炫酷的标题..." />
        </div>
        <div class="input-group">
          <input v-model="form.intro" type="text" class="intro-input" placeholder="输入一句话简介（选填）..." />
        </div>

        <div class="toolbar">
          <div class="tools-left">
            <div class="emoji-container">
              <button class="tool-btn" @click.stop="toggleEmojiPicker" title="插入表情">😀</button>
              <transition name="dropdown-fade">
                <div v-show="showEmojiPicker" class="emoji-picker" @click.stop>
                  <span v-for="emoji in emojiList" :key="emoji" class="emoji-item" @click="insertEmoji(emoji)">
                    {{ emoji }}
                  </span>
                </div>
              </transition>
            </div>
            
            <button class="tool-btn" @click="triggerImageUpload" title="上传本地图片" :disabled="isUploadingImage">
              {{ isUploadingImage ? '⏳' : '🖼️' }}
            </button>
            
            <div class="divider"></div>
            <button class="tool-btn" @click="applyFormat('**', '**')" v-show="isMarkdown" title="加粗"><b>B</b></button>
            <button class="tool-btn" @click="applyFormat('*', '*')" v-show="isMarkdown" title="斜体"><i>I</i></button>
            <div class="divider" v-show="isMarkdown"></div>
            
            <button class="tool-btn preview-btn" :class="{ 'active-preview': showPreview }" @click="togglePreview" v-show="isMarkdown">
              {{ showPreview ? '🚫 关闭预览' : '👀 实时预览' }}
            </button>
          </div>
          
          <div class="tools-right">
            <button class="mode-toggle-btn" @click="toggleEditorMode">
              <span class="icon">{{ isMarkdown ? '👁️' : '👨‍💻' }}</span>
              {{ isMarkdown ? '切换至富文本' : '切换至 Markdown' }}
            </button>
          </div>
        </div>

        <input type="file" ref="imageInput" style="display: none;" accept="image/*" @change="handleImageUpload" />

        <div class="editor-area" :class="{ 'split-mode': showPreview && isMarkdown }">
          <textarea 
            ref="contentInput"
            v-model="form.content" 
            class="content-textarea" 
            :class="{ 'markdown-font': isMarkdown }"
            :placeholder="isMarkdown ? '支持 Markdown 语法，开始你的创作...' : '在这里写下你的故事...'"
            @keydown="handleKeydown" 
          ></textarea>

          <div v-show="showPreview && isMarkdown" class="markdown-preview" v-html="compiledMarkdown"></div>
        </div>

        <div class="publish-footer">
          <div class="price-setting" v-if="!isEditMode">
            <label>阅读价格 (BLG) :</label>
            <input v-model="form.price" type="number" min="0" step="1" />
          </div>
          <div v-else class="price-setting">
            <span style="font-size: 0.9rem; color: #94a3b8;">* 链上文章价格设定后不可更改</span>
          </div>
          
          <button class="publish-btn" :disabled="loading" @click="publishArticle">
            <template v-if="loading">上链中 (请稍候)...</template>
            <template v-else>{{ isEditMode ? '💾 保存修改' : '🚀 确认发布' }}</template>
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { reactive, ref, computed, nextTick, onMounted, onUnmounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { ethers } from 'ethers';
import { getContract } from '../utils/web3';
import { getIpfsUrl } from '../utils/ipfs'; 
import TopNavbar from '../components/TopNavbar.vue'; 
import { marked } from 'marked'; 

const route = useRoute();
const router = useRouter();

const loading = ref(false);
const isMarkdown = ref(true); 
const showPreview = ref(false); 
const contentInput = ref(null);
const imageInput = ref(null);
const isUploadingImage = ref(false);
const isEditMode = ref(false);
const editBlogId = ref(null);

const form = reactive({
  name: '',
  intro: '',
  content: '',
  price: 0
});

const compiledMarkdown = computed(() => {
  if (!form.content) return '<p class="empty-preview">预览区：输入 Markdown 即可查看效果</p>';
  return marked.parse(form.content);
});

const toggleEditorMode = () => {
  isMarkdown.value = !isMarkdown.value;
  if (!isMarkdown.value) showPreview.value = false;
};

const togglePreview = () => {
  showPreview.value = !showPreview.value;
};

const insertText = (text) => {
  const textarea = contentInput.value;
  if (!textarea) return;
  
  const start = textarea.selectionStart;
  const end = textarea.selectionEnd;
  form.content = form.content.substring(0, start) + text + form.content.substring(end);
  
  nextTick(() => {
    textarea.focus();
    textarea.selectionStart = textarea.selectionEnd = start + text.length;
  });
};

const showEmojiPicker = ref(false);
const emojiList = [
  '😀','😂','🤣','😊','😍','😘','😜','😎','🤩','🥳',
  '😏','😒','😔','😢','😭','😤','😡','🤯','😳','😱',
  '😨','🤔','🙄','😬','🤐','🤢','🤮','🤧','😷','😈',
  '💩','👻','👽','🤖','🎃','👍','👎','👏','🙌','🙏',
  '💪','🎉','✨','🔥','🚀','💡','❤️','💔','💯','✅'
];

const toggleEmojiPicker = () => {
  showEmojiPicker.value = !showEmojiPicker.value;
};

const insertEmoji = (emoji) => {
  insertText(emoji);
  showEmojiPicker.value = false; 
};

const closeDropdowns = () => {
  showEmojiPicker.value = false;
};

onMounted(async () => {
  document.addEventListener('click', closeDropdowns);

  if (route.query.editMode === 'true') {
    isEditMode.value = true;
    editBlogId.value = route.query.blogId;
    form.name = route.query.name;
    form.intro = route.query.intro;
    loading.value = true;
    form.content = "正在从 IPFS 拉取文章正文，请稍候...";
    try {
      const fileUrl = getIpfsUrl(route.query.ipfsCID);
      const response = await fetch(fileUrl);
      if (response.ok) {
        form.content = await response.text();
      } else {
        form.content = "> ⚠️ 获取文章内容失败。可能是 IPFS 网关延迟，请重试。";
      }
    } catch(e) {
      console.error("拉取 IPFS 失败", e);
      form.content = "> ⚠️ 网络错误导致拉取文章正文失败。";
    } finally {
      loading.value = false;
    }
  }
});

onUnmounted(() => {
  document.removeEventListener('click', closeDropdowns);
});

const applyFormat = (prefix, suffix) => {
  const textarea = contentInput.value;
  if (!textarea) return;

  const start = textarea.selectionStart;
  const end = textarea.selectionEnd;
  const selectedText = form.content.substring(start, end);
  const textToWrap = selectedText;
  const newText = prefix + textToWrap + suffix;

  form.content = form.content.substring(0, start) + newText + form.content.substring(end);

  nextTick(() => {
    textarea.focus();
    if (selectedText.length > 0) {
      textarea.selectionStart = textarea.selectionEnd = start + newText.length;
    } else {
      textarea.selectionStart = start + prefix.length;
      textarea.selectionEnd = start + prefix.length;
    }
  });
};

const handleKeydown = (e) => {
  const isModifierPressed = e.ctrlKey || e.metaKey;
  if (isModifierPressed && isMarkdown.value) {
    if (e.key.toLowerCase() === 'b') { e.preventDefault(); applyFormat('**', '**'); }
    else if (e.key.toLowerCase() === 'i') { e.preventDefault(); applyFormat('*', '*'); }
  }
};

const triggerImageUpload = () => {
  if (isUploadingImage.value) return;
  imageInput.value.click(); 
};

const handleImageUpload = async (event) => {
  const file = event.target.files[0];
  if (!file) return;

  isUploadingImage.value = true;
  try {
    const formData = new FormData();
    formData.append('file', file);
    formData.append('pinataMetadata', JSON.stringify({ name: `BlogImage_${Date.now()}` }));

    const pinataJwt = import.meta.env.VITE_PINata_JWT;
    const res = await fetch('https://api.pinata.cloud/pinning/pinFileToIPFS', {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${pinataJwt}` },
      body: formData
    });

    if (!res.ok) throw new Error("图片上传到 Pinata 失败");
    const resData = await res.json();
    const imageUrl = getIpfsUrl(resData.IpfsHash);

    if (isMarkdown.value) {
      insertText(`\n![图片说明](${imageUrl})\n`);
      if (!showPreview.value) showPreview.value = true;
    } else {
      insertText(`\n[图片链接: ${imageUrl}]\n`);
    }
  } catch (e) {
    console.error("图片上传失败:", e);
    alert("图片上传失败，请检查网络或 Pinata 配置。");
  } finally {
    isUploadingImage.value = false;
    if (imageInput.value) imageInput.value.value = ''; 
  }
};

const uploadContentToIPFS = async (content) => {
  const blob = new Blob([content], { type: 'text/markdown' });
  const file = new File([blob], `article_${Date.now()}.md`, { type: 'text/markdown' });

  const formData = new FormData();
  formData.append('file', file);
  formData.append('pinataMetadata', JSON.stringify({ name: `BlogContent_${form.name}` }));

  const pinataJwt = import.meta.env.VITE_PINATA_JWT;
  const res = await fetch('https://api.pinata.cloud/pinning/pinFileToIPFS', {
    method: 'POST',
    headers: { 'Authorization': `Bearer ${pinataJwt}` },
    body: formData
  });

  if (!res.ok) throw new Error("文章内容上传到 Pinata 失败");
  const resData = await res.json();
  return resData.IpfsHash; 
};

const publishArticle = async () => {
  if (!form.name || !form.content) {
    return alert("⚠️ 标题和正文内容不能为空！");
  }

  try {
    loading.value = true;
    const contentCID = await uploadContentToIPFS(form.content);
    const contract = getContract();
    
    let tx;
    if (isEditMode.value) {
      tx = await contract.updateBlog(
        editBlogId.value,
        form.name,
        form.intro || "暂无简介",
        contentCID
      );
    } else {
      const priceInWei = ethers.parseEther(form.price.toString());
      tx = await contract.publishBlog(
        form.name, 
        form.intro || "暂无简介", 
        contentCID, 
        priceInWei
      );
    }
    
    alert("上链请求已发送，请在 MetaMask 中确认并等待...");
    await tx.wait();
    
    alert(isEditMode.value ? "🎉 修改成功！您的修改已记录上链！" : "🎉 发布成功！你的文章已永久记录在区块链上！");
    router.push('/'); 
    
  } catch (error) {
    console.error("提交失败:", error);
    alert(`操作失败: ${error.reason || error.message}`);
  } finally {
    loading.value = false;
  }
};
</script>

<style scoped>
.publish-page { padding: 40px 20px; display: flex; justify-content: center; background-color: #f8fafc; min-height: calc(100vh - 60px); }
.editor-container { width: 100%; max-width: 1000px; background: white; border-radius: 12px; box-shadow: 0 4px 20px rgba(0, 0, 0, 0.05); padding: 30px; display: flex; flex-direction: column; gap: 20px; transition: max-width 0.3s; }
.header-actions h2 { margin: 0; color: #1e293b; font-size: 1.5rem; }
.input-group input { width: 100%; border: none; border-bottom: 1px solid #e2e8f0; padding: 10px 0; background: transparent; transition: border-color 0.2s; box-sizing: border-box; }
.input-group input:focus { outline: none; border-bottom-color: #6366f1; }
.title-input { font-size: 1.8rem; font-weight: bold; color: #0f172a; }
.title-input::placeholder { color: #cbd5e1; font-weight: bold; }
.intro-input { font-size: 1.1rem; color: #475569; }

.toolbar { display: flex; justify-content: space-between; align-items: center; padding: 10px; background: #f1f5f9; border-radius: 8px 8px 0 0; border: 1px solid #e2e8f0; border-bottom: none; }
.tools-left { display: flex; align-items: center; gap: 8px; }
.tool-btn { background: white; border: 1px solid #cbd5e1; border-radius: 6px; padding: 6px 10px; cursor: pointer; font-size: 0.95rem; transition: all 0.2s; color: #334155; }
.tool-btn:hover:not(:disabled) { background: #e0e7ff; border-color: #a5b4fc; }
.tool-btn:disabled { opacity: 0.5; cursor: not-allowed; }
.active-preview { background: #e0e7ff; border-color: #6366f1; color: #4f46e5; font-weight: bold; }
.divider { width: 1px; height: 20px; background: #cbd5e1; margin: 0 5px; }
.mode-toggle-btn { background: #4f46e5; color: white; border: none; border-radius: 6px; padding: 6px 12px; font-size: 0.85rem; cursor: pointer; display: flex; align-items: center; gap: 6px; transition: background 0.2s; }
.mode-toggle-btn:hover { background: #4338ca; }

.emoji-container { position: relative; display: flex; }
.emoji-picker { position: absolute; top: 42px; left: 0; width: 520px; background: #ffffff; border: 1px solid #e2e8f0; border-radius: 8px; box-shadow: 0 8px 24px rgba(0, 0, 0, 0.12); padding: 12px; display: grid; grid-template-columns: repeat(10, 1fr); gap: 6px; z-index: 100; }
.emoji-item { text-align: center; cursor: pointer; font-size: 1.25rem; padding: 4px; border-radius: 6px; transition: background 0.2s, transform 0.2s; user-select: none; }
.emoji-item:hover { background: #f1f5f9; transform: scale(1.2); }
.dropdown-fade-enter-active, .dropdown-fade-leave-active { transition: opacity 0.2s ease, transform 0.2s ease; }
.dropdown-fade-enter-from, .dropdown-fade-leave-to { opacity: 0; transform: translateY(-10px); }

.editor-area { flex-grow: 1; display: flex; height: 600px; border: 1px solid #e2e8f0; border-radius: 0 0 8px 8px; overflow: hidden; }
.content-textarea { width: 100%; height: 100%; resize: none; padding: 20px; border: none; font-size: 1.05rem; line-height: 1.6; color: #334155; box-sizing: border-box; outline: none; overflow-y: auto; }
.markdown-font { font-family: 'Courier New', Courier, monospace; background-color: #fafaf9; }
.split-mode .content-textarea { width: 50%; border-right: 1px solid #e2e8f0; }
.markdown-preview { width: 50%; height: 100%; padding: 20px; background: #ffffff; overflow-y: auto; box-sizing: border-box; color: #1e293b; line-height: 1.7; }
.empty-preview { color: #94a3b8; text-align: center; margin-top: 50px; }

.content-textarea::-webkit-scrollbar, .markdown-preview::-webkit-scrollbar { width: 8px; }
.content-textarea::-webkit-scrollbar-track, .markdown-preview::-webkit-scrollbar-track { background: #f8fafc; border-radius: 4px; }
.content-textarea::-webkit-scrollbar-thumb, .markdown-preview::-webkit-scrollbar-thumb { background: #cbd5e1; border-radius: 4px; }
.content-textarea::-webkit-scrollbar-thumb:hover, .markdown-preview::-webkit-scrollbar-thumb:hover { background: #94a3b8; }

.markdown-preview :deep(img) { max-width: 100%; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.1); margin: 10px 0; }
.markdown-preview :deep(h1), .markdown-preview :deep(h2), .markdown-preview :deep(h3) { margin-top: 0; border-bottom: 1px solid #e2e8f0; padding-bottom: 5px; }
.markdown-preview :deep(p) { margin-bottom: 15px; }
.markdown-preview :deep(blockquote) { border-left: 4px solid #cbd5e1; padding-left: 15px; color: #64748b; background: #f8fafc; margin: 0; padding: 10px 15px; border-radius: 0 4px 4px 0;}

.publish-footer { display: flex; justify-content: space-between; align-items: center; padding-top: 20px; border-top: 1px solid #e2e8f0; }
.price-setting { display: flex; align-items: center; gap: 10px; font-weight: bold; color: #475569; }
.price-setting input { width: 80px; padding: 8px; border: 1px solid #cbd5e1; border-radius: 6px; text-align: center; font-size: 1rem; }
.publish-btn { background: #10b981; color: white; border: none; padding: 12px 30px; border-radius: 8px; font-size: 1.1rem; font-weight: bold; cursor: pointer; transition: transform 0.2s, background 0.2s; }
.publish-btn:hover:not(:disabled) { background: #059669; transform: translateY(-2px); box-shadow: 0 4px 12px rgba(16, 185, 129, 0.3); }
.publish-btn:disabled { background: #94a3b8; cursor: not-allowed; }
</style>