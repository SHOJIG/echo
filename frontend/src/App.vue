<template>
  <div class="app-container">
    <header class="app-header">
      <div class="title-area">
        <h1>🌐 Web3 去中心化博客</h1>
        <p>基于区块链与 IPFS 的抗审查内容发布平台</p>
      </div>
      <div class="wallet-area">
        <WalletConnect />
      </div>
    </header>

    <main class="app-main">
      <PublishBlog />
    </main>
  </div>
</template>

<script setup>
import WalletConnect from './components/WalletConnect.vue';
import PublishBlog from './components/PublishBlog.vue';
</script>

<style>
/* 基础全局样式重置 */
* { box-sizing: border-box; margin: 0; padding: 0; }
body { font-family: 'Helvetica Neue', Arial, sans-serif; background-color: #f1f5f9; color: #0f172a; }

.app-container { max-width: 900px; margin: 0 auto; padding: 20px; }

.app-header { display: flex; justify-content: space-between; align-items: center; padding-bottom: 20px; border-bottom: 2px solid #e2e8f0; margin-bottom: 20px; }
.title-area h1 { font-size: 24px; color: #1e293b; margin-bottom: 5px; }
.title-area p { font-size: 14px; color: #64748b; }

.wallet-area { min-width: 280px; }

/* 响应式：手机端换行展示 */
@media (max-width: 600px) {
  .app-header { flex-direction: column; align-items: flex-start; gap: 20px; }
  .wallet-area { width: 100%; }
}
</style>