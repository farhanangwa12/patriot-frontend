<template>
  <div class="page-root">
    <div class="card" role="region" aria-labelledby="result-title">
      <!-- Loading State -->
      <div v-if="loading" class="loading-state">
        <div class="spinner"></div>
        <p>Memuat hasil kuis...</p>
      </div>

      <!-- Error State -->
      <div v-else-if="error" class="error-state">
        <h2>Oops! Terjadi Kesalahan</h2>
        <p>{{ error }}</p>
        <button class="btn btn-primary" @click="goQuizManagement">Kembali ke menu Quiz</button>
      </div>

      <!-- Success State -->
      <div v-else-if="quizResult">
        <header class="card-head">
          <h1 id="result-title">Hasil Kuis: {{ quizResult.quiz.title }}</h1>
          <p class="muted">Berikut ringkasan jawaban Anda.</p>
        </header>

        <section class="score-area" aria-live="polite">
          <div class="score-circle" :aria-valuenow="quizResult.percentage" role="img"
            :title="`${quizResult.percentage}%`">
            <strong>{{ quizResult.summary.correct_answers }}</strong>
            <small>/ {{ quizResult.summary.total_questions }}</small>
          </div>

          <div class="score-meta">
            <div class="percent">{{ quizResult.percentage }}%</div>
            <div class="detail">
              Skor: <strong>{{ quizResult.summary.correct_answers }}</strong> dari <strong>{{
                quizResult.summary.total_questions }}</strong>
            </div>
            <div class="motivation" :class="getMotivationClass(quizResult.percentage)">
              {{ getMotivationMessage(quizResult.percentage) }}
            </div>
          </div>
        </section>

        <section class="breakdown" aria-label="Rincian jawaban">
          <h2 class="breakdown-title">Rincian Jawaban</h2>
          <div class="summary-stats">
            <div class="stat-item correct-stat">
              <div class="stat-icon">
                <svg viewBox="0 0 24 24" class="icon" aria-hidden="true">
                  <path d="M20 6L9 17l-5-5" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" />
                </svg>
              </div>
              <div class="stat-content">
                <div class="stat-number">{{ quizResult.summary.correct_answers }}</div>
                <div class="stat-label">Benar</div>
              </div>
            </div>
            
            <div class="stat-item incorrect-stat">
              <div class="stat-icon">
                <svg viewBox="0 0 24 24" class="icon" aria-hidden="true">
                  <path d="M18 6L6 18M6 6l12 12" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" />
                </svg>
              </div>
              <div class="stat-content">
                <div class="stat-number">{{ quizResult.summary.incorrect_answers }}</div>
                <div class="stat-label">Salah</div>
              </div>
            </div>
            
            <div class="stat-item accuracy-stat">
              <div class="stat-icon">
                <svg viewBox="0 0 24 24" class="icon" aria-hidden="true">
                  <path d="M9 12l2 2 4-4M21 12a9 9 0 11-18 0 9 9 0 0118 0z" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" />
                </svg>
              </div>
              <div class="stat-content">
                <div class="stat-number">{{ quizResult.summary.accuracy_percentage }}%</div>
                <div class="stat-label">Akurasi</div>
              </div>
            </div>
          </div>

          <ul class="list">
            <li v-for="(answer, i) in quizResult.answers_detail" :key="answer.id" class="item">
              <div class="item-left">
                <div class="q-index">#{{ i + 1 }}</div>
                <div class="q-body">
                  <div class="q-label">Jawaban Anda</div>
                  <div class="user-answer">
                    {{ answer.user_answer || '(kosong)' }}
                  </div>
                </div>
              </div>

              <div class="item-right">
                <div class="result-badge" :class="{ ok: answer.is_correct, bad: !answer.is_correct }"
                  :aria-label="answer.is_correct ? 'Benar' : 'Salah'">
                  <svg v-if="answer.is_correct" viewBox="0 0 24 24" class="icon" aria-hidden="true">
                    <path d="M20 6L9 17l-5-5" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"
                      stroke-linejoin="round" />
                  </svg>
                  <svg v-else viewBox="0 0 24 24" class="icon" aria-hidden="true">
                    <path d="M18 6L6 18M6 6l12 12" fill="none" stroke="currentColor" stroke-width="2"
                      stroke-linecap="round" stroke-linejoin="round" />
                  </svg>
                </div>

                <div class="score-info">
                  <div class="label">Poin</div>
                  <div class="value">{{ answer.score }}</div>
                </div>
              </div>
            </li>
          </ul>
        </section>

        <footer class="card-foot">
          <div class="actions">
            <button class="btn btn-outline" @click="restartQuiz">Ulangi Kuis</button>
            <button class="btn btn-primary" @click="goQuizManagement">Beranda Quiz</button>
          </div>
          <p class="small muted">
            Kuis diselesaikan pada: {{ formatDate(quizResult.completed_at) }}
          </p>
        </footer>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'

const route = useRoute()
const router = useRouter()

interface QuizAnswer {
  id: number
  question_id: number
  user_answer: string
  is_correct: boolean
  score: number
  answered_at: string
}

interface QuizResult {
  quiz: {
    id: number
    title: string
    total_questions: number
  }
  quiz_session_id: number
  user_id: number
  total_score: number
  percentage: number
  completed_at: string
  answers_detail: QuizAnswer[]
  summary: {
    total_questions: number
    correct_answers: number
    incorrect_answers: number
    accuracy_percentage: number
  }
}

const loading = ref(true)
const error = ref<string | null>(null)
const quizResult = ref<QuizResult | null>(null)

const fetchQuizResult = async () => {
  try {
    loading.value = true
    error.value = null

    // Ambil dari localStorage terlebih dahulu
    const stored = localStorage.getItem('result_quiz')
    let id = route.params.id ?? null

    if (stored) {
      try {
        const parsed = JSON.parse(stored)
        // object contoh: { id:184, user_id:1, quiz_id:6, ... }
        // gunakan parsed.id jika ada (id result), kalau mau pakai quiz_id ganti ke parsed.quiz_id
        if (parsed && (parsed.id || parsed.quiz_id)) {
          id = parsed.id ?? parsed.quiz_id ?? id
        }
      } catch (parseErr) {
        console.warn('Failed to parse result_quiz from localStorage', parseErr)
      }
    }

    if (!id) {
      throw new Error('ID tidak ditemukan di localStorage atau route params')
    }

    const response = await fetch(`http://localhost:3000/quiz/result/${id}`)

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`)
    }

    const data = await response.json()

    if (data.status === 'success') {
      quizResult.value = data.data
    } else {
      throw new Error(data.message || 'Gagal memuat hasil kuis')
    }
  } catch (err) {
    console.error('Error fetching quiz result:', err)
    error.value = err instanceof Error ? err.message : 'Terjadi kesalahan yang tidak diketahui'
  } finally {
    loading.value = false
  }
}

const getMotivationMessage = (percentage: number): string => {
  if (percentage === 0) {
    return "Apakah kamu benar-benar menjawab dengan benar? 🤔"
  } else if (percentage < 25) {
    return "Wah kamu belum terlalu patriotisme 😅"
  } else if (percentage === 50) {
    return "Oke tidak apa-apa yang penting mengetahui beberapa 👍"
  } else if (percentage >= 75 && percentage < 100) {
    return "Wah hebat banget keren! 🎉"
  } else if (percentage === 100) {
    return "Kamu sangat keren banget, merupakan patriotisme sejati! 🇮🇩✨"
  } else {
    return "Terus belajar dan tingkatkan pengetahuan patriotisme! 📚"
  }
}

const getMotivationClass = (percentage: number): string => {
  if (percentage === 0) return 'motivation-poor'
  if (percentage < 25) return 'motivation-low'
  if (percentage === 50) return 'motivation-medium'
  if (percentage >= 75 && percentage < 100) return 'motivation-good'
  if (percentage === 100) return 'motivation-excellent'
  return 'motivation-default'
}

const formatDate = (dateString: string): string => {
  const date = new Date(dateString)
  return date.toLocaleDateString('id-ID', {
    weekday: 'long',
    year: 'numeric',
    month: 'long',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  })
}

const restartQuiz = () => {
  router.push('/intro').catch(() => { })
}

const goQuizManagement = () => {
  router.push('/quiz-management').catch(() => { })
}

onMounted(() => {
  fetchQuizResult()
})
</script>

<style scoped>
.page-root {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 28px;
  background: linear-gradient(135deg, #f0fbff 0%, #f7fff4 100%);
  font-family: Inter, system-ui, -apple-system, "Segoe UI", Roboto, "Helvetica Neue", Arial;
}

/* Card */
.card {
  width: 100%;
  max-width: 820px;
  border-radius: 14px;
  padding: 22px;
  background: linear-gradient(180deg, rgba(255, 255, 255, 0.95), rgba(255, 255, 255, 0.9));
  box-shadow: 0 14px 40px rgba(2, 6, 23, 0.08);
  border: 1px solid rgba(0, 0, 0, 0.04);
}

/* Head */
.card-head {
  display: flex;
  flex-direction: column;
  gap: 6px;
  text-align: left;
  margin-bottom: 12px;
}

.card-head h1 {
  margin: 0;
  font-size: 20px;
  color: #062244;
}

.muted {
  color: #6b7280;
  font-size: 13px;
}

/* Score area */
.score-area {
  display: flex;
  gap: 18px;
  align-items: center;
  margin: 8px 0 18px;
}

.score-circle {
  width: 96px;
  height: 96px;
  border-radius: 999px;
  background: linear-gradient(180deg, #ffffff, #f1fbff);
  display: flex;
  align-items: center;
  justify-content: center;
  flex-direction: column;
  font-size: 22px;
  color: #062244;
  box-shadow: 0 8px 24px rgba(6, 34, 68, 0.06);
  border: 1px solid rgba(6, 34, 68, 0.05);
}

.score-circle strong {
  font-size: 26px;
  display: block;
  line-height: 1;
}

.score-circle small {
  font-size: 12px;
  color: #6b7280;
}

.score-meta {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.percent {
  font-size: 20px;
  font-weight: 700;
  color: #0b6ea8;
}

.detail {
  font-size: 13px;
  color: #475569;
}

/* Breakdown */
.breakdown {
  margin-top: 6px;
}

.breakdown-title {
  margin: 10px 0 18px;
  font-size: 15px;
  color: #0b2540;
}

/* Summary Stats - Improved */
.summary-stats {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
  gap: 16px;
  margin-bottom: 24px;
}

.stat-item {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 16px 18px;
  border-radius: 12px;
  background: linear-gradient(135deg, rgba(255, 255, 255, 0.9), rgba(250, 250, 255, 0.85));
  border: 1px solid rgba(6, 34, 68, 0.08);
  box-shadow: 0 6px 20px rgba(3, 10, 25, 0.06);
  transition: all 0.2s ease;
}

.stat-item:hover {
  transform: translateY(-1px);
  box-shadow: 0 8px 24px rgba(3, 10, 25, 0.1);
}

.stat-icon {
  width: 44px;
  height: 44px;
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.correct-stat .stat-icon {
  background: linear-gradient(135deg, #10b981, #059669);
  color: white;
}

.incorrect-stat .stat-icon {
  background: linear-gradient(135deg, #ef4444, #dc2626);
  color: white;
}

.accuracy-stat .stat-icon {
  background: linear-gradient(135deg, #3b82f6, #1d4ed8);
  color: white;
}

.stat-icon .icon {
  width: 20px;
  height: 20px;
  stroke: currentColor;
  fill: none;
}

.stat-content {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.stat-number {
  font-size: 24px;
  font-weight: 700;
  color: #0b2540;
  line-height: 1;
}

.stat-label {
  font-size: 13px;
  color: #6b7280;
  font-weight: 500;
}

/* List styles */
.list {
  list-style: none;
  padding: 0;
  margin: 0;
  display: grid;
  gap: 12px;
}

.item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 12px;
  border-radius: 12px;
  background: linear-gradient(180deg, rgba(250, 250, 255, 0.9), rgba(250, 250, 255, 0.85));
  border: 1px solid rgba(6, 34, 68, 0.03);
  box-shadow: 0 6px 18px rgba(3, 10, 25, 0.03);
}

.item-left {
  display: flex;
  gap: 12px;
  align-items: center;
}

.q-index {
  width: 44px;
  height: 44px;
  border-radius: 10px;
  background: rgba(6, 34, 68, 0.04);
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 700;
  color: #062244;
}

.q-body .q-label {
  font-size: 12px;
  color: #475569;
}

.user-answer {
  margin-top: 4px;
  font-weight: 600;
  color: #062244;
}

/* Item right */
.item-right {
  display: flex;
  align-items: center;
  gap: 12px;
}

.result-badge {
  width: 44px;
  height: 44px;
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
}

.result-badge.ok {
  background: linear-gradient(90deg, #10b981, #059669);
}

.result-badge.bad {
  background: linear-gradient(90deg, #ef4444, #b91c1c);
}

.result-badge .icon {
  width: 20px;
  height: 20px;
  stroke: currentColor;
  stroke-width: 1.8;
  fill: none;
}

.score-info {
  text-align: right;
}

.score-info .label {
  font-size: 12px;
  color: #475569;
}

.score-info .value {
  font-weight: 700;
  color: #0b2540;
  margin-top: 4px;
}

/* Footer */
.card-foot {
  margin-top: 16px;
  display: flex;
  flex-direction: column;
  gap: 10px;
  align-items: stretch;
}

.actions {
  display: flex;
  gap: 10px;
  justify-content: flex-end;
}

.btn {
  padding: 9px 14px;
  border-radius: 10px;
  font-weight: 700;
  border: none;
  cursor: pointer;
  transition: all 0.2s ease;
}

.btn-outline {
  background: transparent;
  border: 1px solid rgba(6, 34, 68, 0.06);
  color: #0b2540;
}

.btn-outline:hover {
  background: rgba(6, 34, 68, 0.04);
}

.btn-primary {
  background: linear-gradient(90deg, #06b6d4, #3b82f6);
  color: white;
  box-shadow: 0 8px 24px rgba(59, 130, 246, 0.12);
}

.btn-primary:hover {
  transform: translateY(-1px);
  box-shadow: 0 10px 28px rgba(59, 130, 246, 0.16);
}

/* small */
.small {
  font-size: 12px;
  color: #6b7280;
  text-align: right;
}

/* Responsive */
@media (max-width: 768px) {
  .summary-stats {
    grid-template-columns: 1fr;
    gap: 12px;
  }
}

@media (max-width: 640px) {
  .card {
    padding: 16px;
  }

  .score-area {
    flex-direction: column;
    align-items: flex-start;
    gap: 10px;
  }

  .item {
    flex-direction: column;
    align-items: flex-start;
    gap: 8px;
  }

  .item-right {
    width: 100%;
    justify-content: space-between;
  }

  .actions {
    justify-content: space-between;
  }

  .stat-number {
    font-size: 20px;
  }
}
</style>