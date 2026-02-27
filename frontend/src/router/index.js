import { createRouter, createWebHistory } from 'vue-router'
import Home from '../views/Home.vue'
import LandingView from '../views/LandingView.vue'
import BlogListView from '../views/BlogListView.vue'
import AlbumListView from '../views/AlbumListView.vue'
import AlbumDetailView from '../views/AlbumDetailView.vue'
import PublishView from '../views/PublishView.vue'
import BlogDetailView from '../views/BlogDetailView.vue'
import SubscribeView from '../views/SubscribeView.vue';

const routes = [
  { path: '/', name: 'Home', component: Home },
  { path: '/index', name: 'Index', component: LandingView },
  { path: '/blogs', name: 'Blogs', component: BlogListView },
  { path: '/albums', name: 'Albums', component: AlbumListView },
  { path: '/albums/:id', name: 'AlbumDetail', component: AlbumDetailView },
  { path: '/publish', name: 'Publish', component: PublishView },
  { path: '/blog/:id', name: 'BlogDetail', component: BlogDetailView },
  { path: '/subscribe', name: 'Subscribe', component: SubscribeView }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

export default router