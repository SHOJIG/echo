<template>
  <div>
    <TopNavbar/>
    
    <div class="album-detail-container animate__animated animate__fadeInUp">
      <header class="page-header">
        <button class="back-btn" @click="$router.push('/albums')">⬅ 返回相册列表</button>
        
        <div class="album-title-area">
          <h2>{{ albumName }}</h2>
          <div class="album-actions" v-if="!loading">
            <span class="action-edit" @click="handleEditAlbum">编辑名称</span>
            <span class="action-delete" @click="handleDeleteAlbum" title="删除相册">−</span>
          </div>
        </div>
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
            v-for="pic in pictures" 
            :key="pic.originalIndex" 
            class="photo-card picture-item"
          >
            <button class="delete-btn" @click.stop="handleDeletePhoto(pic.originalIndex)" title="删除图片">
              −
            </button>
            <img :src="getIpfsUrl(pic.ipfsCID)" alt="photo" />
          </div>

        </div>
      </main>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { getContract } from '../utils/web3';
import TopNavbar from '../components/TopNavbar.vue';
import { getIpfsUrl } from '../utils/ipfs';

const route = useRoute();
const router = useRouter();
const albumId = route.params.id; 

const albumName = ref('加载中...');
const pictures = ref([]);
const loading = ref(true);
const fileInput = ref(null);
const isUploading = ref(false);

const fetchAlbumDetail = async () => {
  try {
    loading.value = true;
    const contract = getContract();
    const info = await contract.albums(albumId);

    if (info.isDeleted) {
      alert("该相册已被删除！");
      router.push('/albums');
      return;
    }
    
    albumName.value = info.name;
    const rawPics = await contract.getAlbumPictures(albumId);

    pictures.value = rawPics
      .map((pic, index) => ({
        originalIndex: index,
        ipfsCID: pic.ipfsCID,
        isDeleted: pic.isDeleted
      }))
      .filter(pic => !pic.isDeleted);
      
  } catch (e) {
    console.error("获取详情失败", e);
  } finally {
    loading.value = false;
  }
};

const handleEditAlbum = async () => {
  const newName = prompt("请输入新的相册名称：", albumName.value);
  if (!newName || newName.trim() === "" || newName === albumName.value) return;
  
  try {
    const contract = getContract();
    const tx = await contract.updateAlbum(albumId, newName);
    await tx.wait();
    alert("相册名称修改成功！");
    fetchAlbumDetail();
  } catch(e) {
    console.error("修改失败", e);
    alert("修改失败，详情请看控制台报错。");
  }
};

const handleDeleteAlbum = async () => {
  const confirmDelete = confirm("确定要删除这个相册吗？\n注意：相册内的照片也会随之被隐藏！");
  if (!confirmDelete) return;

  try {
    const contract = getContract();
    const tx = await contract.deleteAlbum(albumId);
    await tx.wait();
    alert("相册删除成功！");
    router.push('/albums');
  } catch(e) {
    console.error("删除失败", e);
    alert("删除失败，详情请看控制台报错。");
  }
};

const triggerFileInput = () => {
  if (isUploading.value) return; 
  fileInput.value.click();
};

const uploadToIPFS = async (event) => {
  const file = event.target.files[0];
  if (!file) return;

  isUploading.value = true;

  try {
    const formData = new FormData();
    formData.append('file', file);
    
    const metadata = JSON.stringify({ name: `Album_${albumId}_${file.name}` });
    formData.append('pinataMetadata', metadata);

    const pinataJwt = import.meta.env.VITE_PINATA_JWT;
    const res = await fetch('https://api.pinata.cloud/pinning/pinFileToIPFS', {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${pinataJwt}` },
      body: formData
    });

    if (!res.ok) throw new Error("上传到 Pinata 失败");
    
    const resData = await res.json();
    const ipfsCID = resData.IpfsHash;

    const contract = getContract();
    const tx = await contract.addPicture(albumId, ipfsCID);
    
    alert("图片已传至 IPFS，正在等待区块链确认...");
    await tx.wait();
    
    fetchAlbumDetail(); 

  } catch (e) {
    console.error(e);
    alert("上传或上链失败，请查看控制台日志。");
  } finally {
    isUploading.value = false;
    if (fileInput.value) fileInput.value.value = '';
  }
};

// 传入的是映射时保留的 originalIndex
const handleDeletePhoto = async (originalIndex) => {
  const confirmDelete = confirm("确定要删除这张照片吗？");
  if (!confirmDelete) return;

  try {
    const contract = getContract();
    const tx = await contract.deletePicture(albumId, originalIndex);
    await tx.wait();
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
.album-detail-container { max-width: 1200px; margin: 30px auto; padding: 0 20px; }
.page-header { display: flex; align-items: center; gap: 30px; margin-bottom: 30px; padding-bottom: 15px; border-bottom: 1px solid #e2e8f0; }
.back-btn { padding: 6px 12px; background: white; border: 1px solid #cbd5e1; border-radius: 6px; cursor: pointer; transition: background 0.2s; }
.back-btn:hover { background: #f1f5f9; }

.album-title-area { display: flex; align-items: center; gap: 15px; flex: 1; }
.album-title-area h2 { margin: 0; color: #1e293b; }
.album-actions { display: flex; align-items: center; gap: 12px; }
.action-edit { color: #94a3b8; font-size: 0.9rem; text-decoration: underline; cursor: pointer; transition: color 0.2s; }
.action-edit:hover { color: #64748b; }
.action-delete { color: #ef4444; font-size: 1.8rem; font-weight: 900; cursor: pointer; line-height: 0.5; transition: transform 0.2s, color 0.2s; user-select: none; }
.action-delete:hover { transform: scale(1.2); color: #b91c1c; }

.photo-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(180px, 1fr)); gap: 15px; }
.photo-card { width: 100%; aspect-ratio: 1 / 1; border-radius: 12px; overflow: hidden; position: relative; background: #f8fafc; }

.add-photo-card { border: 2px dashed #cbd5e1; display: flex; flex-direction: column; align-items: center; justify-content: center; cursor: pointer; color: #64748b; transition: all 0.2s; }
.add-photo-card:hover:not(.is-uploading) { border-color: #6366f1; color: #6366f1; background: #eef2ff; }
.is-uploading { cursor: not-allowed; opacity: 0.7; }

.add-icon { font-size: 3rem; font-weight: 300; margin-bottom: 5px; line-height: 1;}
.picture-item img { width: 100%; height: 100%; object-fit: cover; }
.picture-item:hover .delete-btn { opacity: 1; transform: scale(1); }

.delete-btn { position: absolute; top: 8px; right: 8px; width: 28px; height: 28px; border-radius: 50%; background: rgba(239, 68, 68, 0.9); color: white; border: none; font-size: 1.2rem; line-height: 1; cursor: pointer; opacity: 0; transform: scale(0.8); transition: all 0.2s; box-shadow: 0 2px 4px rgba(0,0,0,0.2); }
.delete-btn:hover { background: #dc2626; transform: scale(1.1) !important;}

.loader-small { border: 3px solid #f3f3f3; border-top: 3px solid #6366f1; border-radius: 50%; width: 24px; height: 24px; animation: spin 1s linear infinite; margin-bottom: 10px; }
@keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }
</style>