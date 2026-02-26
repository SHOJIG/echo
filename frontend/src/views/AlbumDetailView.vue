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
          
          <div class="photo-card add-photo-card" @click="handleAddPhoto">
            <div class="add-icon">+</div>
            <p>上传照片</p>
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

const route = useRoute();
const albumId = route.params.id; // 从 URL 中获取相册 ID

const albumName = ref('加载中...');
const pictures = ref([]);

const getIpfsUrl = (cid) => `https://gateway.pinata.cloud/ipfs/${cid}`;

const fetchAlbumDetail = async () => {
  try {
    const contract = getContract();
    
    // 获取相册名称
    const info = await contract.albums(albumId);
    albumName.value = info.name;

    // 获取相册内所有可见图片的 CID
    const pics = await contract.getAlbumVisiblePictures(albumId);
    pictures.value = pics;
  } catch (e) {
    console.error("获取详情失败", e);
  }
};

const handleAddPhoto = async () => {
  // 按照你的要求，具体的上传功能以后再做，这里用 prompt 模拟拿到一个 CID
  const mockCID = prompt("【模拟上传】请输入图片的 IPFS CID:\n（后期我们会替换成真实的图片文件上传组件）");
  if (!mockCID || mockCID.trim() === "") return;

  try {
    const contract = getContract();
    const tx = await contract.addPicture(albumId, mockCID);
    await tx.wait();
    alert("图片添加成功！");
    fetchAlbumDetail(); // 刷新图片列表
  } catch(e) {
    console.error(e);
    alert("图片添加失败");
  }
};

const handleDeletePhoto = async (index) => {
  const confirmDelete = confirm("确定要删除这张照片吗？");
  if (!confirmDelete) return;

  try {
    const contract = getContract();
    // 💡 提示：目前我们直接传了前端数组的 index。如果合约里有图片被删除，
    // 合约里的绝对 index 可能会和前端看到的相对 index 有出入，需要注意！
    const tx = await contract.deletePicture(albumId, index);
    await tx.wait();
    alert("删除成功！");
    fetchAlbumDetail(); // 刷新图片列表
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
  position: relative; /* 为了能把删除按钮定位在右上角 */
  background: #f8fafc;
}

/* 上传占位格子 */
.add-photo-card { 
  border: 2px dashed #cbd5e1; 
  display: flex; flex-direction: column; align-items: center; justify-content: center; 
  cursor: pointer; color: #64748b; transition: all 0.2s; 
}
.add-photo-card:hover { border-color: #6366f1; color: #6366f1; background: #eef2ff; }
.add-icon { font-size: 3rem; font-weight: 300; margin-bottom: 5px; line-height: 1;}

/* 图片格子 */
.picture-item img { width: 100%; height: 100%; object-fit: cover; }
.picture-item:hover .delete-btn { opacity: 1; transform: scale(1); }

/* 删除按钮样式 */
.delete-btn {
  position: absolute;
  top: 8px; right: 8px;
  width: 28px; height: 28px;
  border-radius: 50%;
  background: rgba(239, 68, 68, 0.9); /* 红色半透明背景 */
  color: white; border: none; font-size: 1.2rem; line-height: 1;
  cursor: pointer;
  opacity: 0; /* 默认隐藏 */
  transform: scale(0.8);
  transition: all 0.2s;
  box-shadow: 0 2px 4px rgba(0,0,0,0.2);
}
.delete-btn:hover { background: #dc2626; transform: scale(1.1) !important;}
</style>