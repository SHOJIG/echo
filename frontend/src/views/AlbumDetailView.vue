<template>
  <div>
    <TopNavbar @logout="$emit('logout')" />
    
    <div class="album-detail-container animate__animated animate__fadeInUp">
      <header class="page-header">
        <button class="back-btn" @click="$router.push('/albums')">⬅ 返回相册列表</button>
        <h2>{{ albumName }}</h2>
      </header>

      <main>
        <div class="photo-grid">
          
          <input 
            type="file" 
            ref="fileInput" 
            style="display: none;" 
            accept="image/*" 
            @change="uploadToIPFS" 
          />

          <div 
            class="photo-card add-photo-card" 
            @click="triggerFileInput"
            :class="{ 'is-uploading': isUploading }"
          >
            <template v-if="isUploading">
              <div class="loader-small"></div>
              <p>上传 IPFS 中...</p>
            </template>
            <template v-else>
              <div class="add-icon">+</div>
              <p>上传照片</p>
            </template>
          </div>

          <div 
            v-for="(pic, index) in pictures" 
            :key="index" 
            class="photo-card picture-item"
          >
            <button class="delete-btn" @click.stop="handleDeletePhoto(index)" title="删除图片">
              −
            </button>
            <img :src="getIpfsUrl(pic)" alt="photo" />
          </div>

        </div>
      </main>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import { useRoute } from 'vue-router';
import { getContract } from '../utils/web3';
import TopNavbar from '../components/TopNavbar.vue';
import { getIpfsUrl } from '../utils/ipfs';

const route = useRoute();
const albumId = route.params.id; 

const albumName = ref('加载中...');
const pictures = ref([]);

// 隐藏的 input 的引用
const fileInput = ref(null);
// 上传状态
const isUploading = ref(false);

const fetchAlbumDetail = async () => {
  try {
    const contract = getContract();
    const info = await contract.albums(albumId);
    albumName.value = info.name;
    const pics = await contract.getAlbumVisiblePictures(albumId);
    pictures.value = pics;
  } catch (e) {
    console.error("获取详情失败", e);
  }
};

// 点击加号格子，触发隐藏的 file input
const triggerFileInput = () => {
  if (isUploading.value) return; // 如果正在上传，禁止再次点击
  fileInput.value.click();
};

// 核心：上传文件到 IPFS，并调用智能合约
const uploadToIPFS = async (event) => {
  const file = event.target.files[0];
  if (!file) return;

  isUploading.value = true;

  try {
    // 1. 组装发给 Pinata 的表单数据
    const formData = new FormData();
    formData.append('file', file);
    
    // 可选：给在 Pinata 的文件做个元数据标记
    const metadata = JSON.stringify({ name: `Album_${albumId}_${file.name}` });
    formData.append('pinataMetadata', metadata);

    // 2. 发起 HTTP 请求上传到 Pinata
    const pinataJwt = import.meta.env.VITE_PINATA_JWT;
    const res = await fetch('https://api.pinata.cloud/pinning/pinFileToIPFS', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${pinataJwt}`
      },
      body: formData
    });

    if (!res.ok) throw new Error("上传到 Pinata 失败");
    
    // 3. 拿到返回的 IPFS CID (哈希值)
    const resData = await res.json();
    const ipfsCID = resData.IpfsHash;
    console.log("IPFS 上传成功！CID:", ipfsCID);

    // 4. 调用智能合约，将这个 CID 存入区块链相册
    const contract = getContract();
    const tx = await contract.addPicture(albumId, ipfsCID);
    
    alert("图片已传至 IPFS，正在等待区块链确认...");
    await tx.wait();
    
    alert("图片添加成功！");
    fetchAlbumDetail(); // 刷新图片列表

  } catch (e) {
    console.error(e);
    alert("上传或上链失败，请查看控制台日志。");
  } finally {
    isUploading.value = false;
    // 清空 input，允许重复上传同一张图片
    if (fileInput.value) fileInput.value.value = '';
  }
};

const handleDeletePhoto = async (index) => {
  const confirmDelete = confirm("确定要删除这张照片吗？");
  if (!confirmDelete) return;

  try {
    const contract = getContract();
    const tx = await contract.deletePicture(albumId, index);
    await tx.wait();
    alert("删除成功！");
    fetchAlbumDetail(); 
  } catch(e) {
    console.error("删除失败:", e);
    alert("删除失败，详情请看控制台报错。");
  }
};

onMounted(() => {
  fetchAlbumDetail();
});
</script>

<style scoped>
/* 保持你原本的样式不变，增加一个简易的 loader-small */
.album-detail-container { max-width: 1200px; margin: 30px auto; padding: 0 20px; }
.page-header { display: flex; align-items: center; gap: 20px; margin-bottom: 30px; padding-bottom: 15px; border-bottom: 1px solid #e2e8f0; }
.back-btn { padding: 6px 12px; background: white; border: 1px solid #cbd5e1; border-radius: 6px; cursor: pointer; transition: background 0.2s; }
.back-btn:hover { background: #f1f5f9; }
.page-header h2 { margin: 0; color: #1e293b; }

.photo-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(180px, 1fr)); gap: 15px; }

.photo-card { 
  width: 100%; 
  aspect-ratio: 1 / 1; 
  border-radius: 12px; 
  overflow: hidden; 
  position: relative; 
  background: #f8fafc;
}

.add-photo-card { 
  border: 2px dashed #cbd5e1; 
  display: flex; flex-direction: column; align-items: center; justify-content: center; 
  cursor: pointer; color: #64748b; transition: all 0.2s; 
}
.add-photo-card:hover:not(.is-uploading) { border-color: #6366f1; color: #6366f1; background: #eef2ff; }
.is-uploading { cursor: not-allowed; opacity: 0.7; }

.add-icon { font-size: 3rem; font-weight: 300; margin-bottom: 5px; line-height: 1;}

.picture-item img { width: 100%; height: 100%; object-fit: cover; }
.picture-item:hover .delete-btn { opacity: 1; transform: scale(1); }

.delete-btn {
  position: absolute;
  top: 8px; right: 8px;
  width: 28px; height: 28px;
  border-radius: 50%;
  background: rgba(239, 68, 68, 0.9);
  color: white; border: none; font-size: 1.2rem; line-height: 1;
  cursor: pointer;
  opacity: 0;
  transform: scale(0.8);
  transition: all 0.2s;
  box-shadow: 0 2px 4px rgba(0,0,0,0.2);
}
.delete-btn:hover { background: #dc2626; transform: scale(1.1) !important;}

/* 上传中的旋转动画 */
.loader-small {
  border: 3px solid #f3f3f3;
  border-top: 3px solid #6366f1;
  border-radius: 50%;
  width: 24px;
  height: 24px;
  animation: spin 1s linear infinite;
  margin-bottom: 10px;
}
@keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }
</style>