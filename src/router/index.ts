import { createRouter, createWebHistory } from 'vue-router'
import LoginView from '../views/LoginView.vue'
import RegisterView from '../views/RegisterView.vue'
import DashboardView from '../views/DashboardView.vue'
import QuizManagementView from '../views/QuizManagementView.vue'
import IntroView from '../views/IntroView.vue'
import QuizView from '../views/QuizView.vue'
import ResultView from '../views/ResultView.vue'
import ResultByIdVue from '@/views/ResultByIdVue.vue'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      name: 'login',
      component: LoginView
    },
    {
      path: '/register',
      name: 'register',
      component: RegisterView
    },

    {
      path: '/dashboard',
      name: 'dashboard',
      component: DashboardView,
      meta: { requiresAuth: true }
    },

    {
      path: '/quiz-management',
      name: 'quiz-management',
      component: QuizManagementView,
      meta: { requiresAuth: true }
    },
    {
      path: '/intro',
      name: 'intro',
      component: IntroView,
      meta: { requiresAuth: true }

    },
    {
      path: '/quiz',
      name: 'quiz',
      component: QuizView,
      meta: { requiresAuth: true }

    },
    {
      path: '/result',
      name: 'result',
      component: ResultView,
      meta: { requiresAuth: true }

    },
     {
      path: '/result-quiz',
      name: 'result-quiz',
      component: ResultByIdVue,
      meta: { requiresAuth: true }

    }
  ]
});

// simple auth checker (ganti sesuai implementasimu: Pinia/Vuex/cookie)
const isAuthenticated = () => !!localStorage.getItem('token')

// global guard
router.beforeEach((to, from, next) => {
  if (to.meta.requiresAuth && !isAuthenticated()) {
    // optionally pass redirect target so user bisa kembali setelah login
    next({ name: 'login', query: { redirect: to.fullPath } })
  } else {
    next()
  }
})


export default router