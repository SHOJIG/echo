<template>
  <div>
    <TopNavbar @logout="$emit('logout')" />
    
    <div class="album-page-container animate__animated animate__fadeInUp">
      <header class="album-header">
        <button class="create-album-btn" @click="handleCreateAlbum">
          ➕ 新建相册
        </button>
      </header>

      <main>
        <div v-if="loading" class="loading-state">
          <div class="loader"></div>
          <p>正在拉取相册数据...</p>
        </div>

        <div v-else-if="albums.length === 0" class="empty-state">
          你还没有创建任何相册，点击左上角创建一个吧！
        </div>

        <div v-else class="album-grid">
          <div 
            v-for="album in albums" 
            :key="album.id" 
            class="album-card" 
            @click="$router.push(`/albums/${album.id}`)"
          >
            <div class="album-cover">
              <img v-if="album.coverCID" :src="getIpfsUrl(album.coverCID)" alt="Cover" />
              <div v-else class="empty-cover">
                <span class="icon">📸</span>
                <span>空相册</span>
              </div>
            </div>
            <div class="album-info">
              <h3>{{ album.name }}</h3>
            </div>
          </div>
        </div>
      </main>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import { getContract } from '../utils/web3';
import TopNavbar from '../components/TopNavbar.vue';

// 接收 App.vue 传来的当前钱包地址
const props = defineProps({
  userAddress: String
});

const albums = ref([]);
const loading = ref(true);

// IPFS 网关前缀拼接
const getIpfsUrl = (cid) => `https://beige-accepted-amphibian-264.mypinata.cloud/ipfs/${cid}`;

const fetchAlbums = async () => {
  if (!props.userAddress) return;
  loading.value = true;
  
  try {
    const contract = getContract();
    const albumIds = await contract.getUserAlbums(props.userAddress);
    
    const data = [];
    for (let i = 0; i < albumIds.length; i++) {
      const id = albumIds[i];
      const albumInfo = await contract.albums(id); // 获取相册基本信息
      const coverCID = await contract.getAlbumCover(id); // 获取第一张可见图片
      
      data.push({
        id: id.toString(),
        name: albumInfo.name,
        coverCID: coverCID
      });
    }
    albums.value = data.reverse(); // 最新创建的在前面
  } catch (error) {
    console.error("获取相册失败:", error);
  } finally {
    loading.value = false;
  }
};

const handleCreateAlbum = async () => {
  const name = prompt("请输入新相册的名称：");
  if (!name || name.trim() === "") return;
  
  try {
    const contract = getContract();
    const tx = await contract.createAlbum(name);
    await tx.wait(); // 等待区块确认
    alert("相册创建成功！");
    fetchAlbums(); // 重新拉取列表
  } catch(e) {
    console.error(e);
    alert("相册创建失败");
  }
};

onMounted(() => {
  fetchAlbums();
});
</script>

<style scoped>
.album-page-container { max-width: 1200px; margin: 30px auto; padding: 0 20px; }
.album-header { margin-bottom: 25px; }
.create-album-btn { background: #6366f1; color: white; border: none; padding: 10px 20px; border-radius: 8px; font-size: 1rem; cursor: pointer; transition: background 0.2s, transform 0.1s; font-weight: 600;}
.create-album-btn:hover { background: #4f46e5; transform: translateY(-2px); }

.album-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(220px, 1fr)); gap: 25px; }
.album-card { background: white; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 12px rgba(0,0,0,0.05); cursor: pointer; transition: transform 0.2s; border: 1px solid #e2e8f0; }
.album-card:hover { transform: translateY(-5px); box-shadow: 0 8px 20px rgba(0,0,0,0.1); }
.album-cover { width: 100%; aspect-ratio: 1 / 1; background: #f1f5f9; display: flex; align-items: center; justify-content: center; }
.album-cover img { width: 100%; height: 100%; object-fit: cover; }
.empty-cover { display: flex; flex-direction: column; align-items: center; color: #94a3b8; font-size: 0.9rem; }
.empty-cover .icon { font-size: 2rem; margin-bottom: 8px; }
.album-info { padding: 15px; text-align: center; }
.album-info h3 { margin: 0; color: #1e293b; font-size: 1.1rem; }
.empty-state { text-align: center; padding: 60px 20px; color: #64748b; background: white; border: 1px dashed #cbd5e1; border-radius: 12px; }
</style>