import { createRouter, createWebHistory } from 'vue-router'

// 路由配置
const router = createRouter({
  history: createWebHistory(),
  routes: [
    {
      path: '/login',
      component: () => import('./views/Login.vue'),
      meta: { requiresAuth: false }
    },
    {
      path: '/init',
      component: () => import('./views/Init.vue'),
      meta: { requiresAuth: false }
    },
    {
      path: '/',
      redirect: '/dashboard',
      meta: { requiresAuth: true }
    },
    {
      path: '/dashboard',
      component: () => import('./views/Dashboard.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/nodes',
      component: () => import('./views/Nodes.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/nodes/:name',
      component: () => import('./views/NodeDetail.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/mappings',
      component: () => import('./views/Mappings.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/mappings/:name',
      component: () => import('./views/MappingDetail.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/advanced-mapping',
      component: () => import('./views/AdvancedMapping.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/advanced-mapping/:name',
      component: () => import('./views/AdvancedMappingDetail.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/logs',
      component: () => import('./views/Logs.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/settings',
      component: () => import('./views/Settings.vue'),
      meta: { requiresAuth: true }
    }
  ]
})

// 路由守卫
router.beforeEach((to, from, next) => {
  const token = localStorage.getItem('token')
  const requiresAuth = to.matched.some(record => record.meta.requiresAuth)

  if (requiresAuth && !token) {
    next('/login')
  } else if (to.path === '/login' && token) {
    next('/')
  } else {
    next()
  }
})

export default router 