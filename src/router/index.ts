import { createRouter, createWebHistory } from 'vue-router'
import LoginView from '../views/LoginView.vue'
import RegisterView from '../views/RegisterView.vue'
import DashboardView from '../views/DashboardView.vue'
import QuizManagementView from '../views/QuizManagementView.vue'
import IntroView from '../views/IntroView.vue'
import QuizView from '../views/QuizView.vue'
import ResultView from '../views/ResultView.vue'

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
      component: QuizManagementView
    },
    {
      path: '/intro',
      name: 'intro',
      component: IntroView
    },
    {
      path: '/quiz',
      name: 'quiz',
      component: QuizView
    },
    {
      path: '/result',
      name: 'result',
      component: ResultView
    }
  ]
})

export default router