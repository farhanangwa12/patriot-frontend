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

          <div class="questions-list">
            <div v-for="(answer, i) in quizResult.answers_detail" :key="answer.id" class="question-item">
              <!-- Question Header -->
              <div class="question-header">
                <div class="question-number">#{{ i + 1 }}</div>
                <div class="question-status">
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
                  <div class="score-display">
                    <span class="score-label">Poin:</span>
                    <span class="score-value">{{ answer.score }}</span>
                  </div>
                </div>
              </div>

              <!-- Question Content -->
              <div class="question-content">
                <div class="question-text">
                  <h3 class="question-title">Pertanyaan:</h3>
                  <p class="question-body">{{ answer.question }}</p>
                </div>

                <div class="answer-section">
                  <div class="user-answer-block">
                    <h4 class="answer-title">Jawaban Anda:</h4>
                    <p class="user-answer" :class="{ empty: !answer.user_answer }">
                      {{ answer.user_answer || '(tidak dijawab)' }}
                    </p>
                  </div>

                  <div class="fact-answer-block">
                    <h4 class="fact-title">
                      <svg viewBox="0 0 24 24" class="fact-icon" aria-hidden="true">
                        <path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
                      </svg>
                      Fakta & Penjelasan:
                    </h4>
                    <p class="fact-answer">{{ answer.fact_answer }}</p>
                  </div>
                </div>
              </div>
            </div>
          </div>
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
  fact_answer: string
  question: string
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
    const stored = sessionStorage.getItem('sites_data')
    let id = route.params.id ?? null

    if (stored) {
      try {
        const parsed = JSON.parse(stored)
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

    // Update URL sesuai format baru
    const response = await fetch(`http://localhost:3000/result/get-result/${id}`)

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`)
    }

    const data = await response.json()

    if (data.success) {
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
  max-width: 920px;
  border-radius: 14px;
  padding: 22px;
  background: linear-gradient(180deg, rgba(255, 255, 255, 0.95), rgba(255, 255, 255, 0.9));
  box-shadow: 0 14px 40px rgba(2, 6, 23, 0.08);
  border: 1px solid rgba(0, 0, 0, 0.04);
}

/* Loading & Error States */
.loading-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 16px;
  padding: 40px 20px;
  text-align: center;
}

.spinner {
  width: 40px;
  height: 40px;
  border: 4px solid #e2e8f0;
  border-left-color: #3b82f6;
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

.error-state {
  text-align: center;
  padding: 40px 20px;
}

.error-state h2 {
  color: #ef4444;
  margin-bottom: 12px;
}

.error-state p {
  color: #6b7280;
  margin-bottom: 24px;
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

.motivation {
  font-size: 14px;
  font-weight: 600;
  padding: 8px 12px;
  border-radius: 8px;
  margin-top: 8px;
}

.motivation-poor {
  background: linear-gradient(135deg, #fef3c7, #fde68a);
  color: #92400e;
}

.motivation-low {
  background: linear-gradient(135deg, #fed7c3, #f9a8a8);
  color: #c53030;
}

.motivation-medium {
  background: linear-gradient(135deg, #dbeafe, #bfdbfe);
  color: #1e40af;
}

.motivation-good {
  background: linear-gradient(135deg, #d1fae5, #a7f3d0);
  color: #065f46;
}

.motivation-excellent {
  background: linear-gradient(135deg, #fdf4ff, #f3e8ff);
  color: #7c3aed;
}

.motivation-default {
  background: linear-gradient(135deg, #f1f5f9, #e2e8f0);
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

/* Summary Stats */
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

/* Questions List - New Styles */
.questions-list {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.question-item {
  border-radius: 16px;
  background: linear-gradient(180deg, rgba(255, 255, 255, 0.95), rgba(250, 250, 255, 0.9));
  border: 1px solid rgba(6, 34, 68, 0.06);
  box-shadow: 0 8px 32px rgba(3, 10, 25, 0.05);
  overflow: hidden;
  transition: all 0.3s ease;
}

.question-item:hover {
  transform: translateY(-2px);
  box-shadow: 0 12px 40px rgba(3, 10, 25, 0.08);
}

.question-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 18px 24px;
  background: linear-gradient(135deg, rgba(248, 250, 252, 0.8), rgba(241, 245, 249, 0.6));
  border-bottom: 1px solid rgba(6, 34, 68, 0.04);
}

.question-number {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 48px;
  height: 48px;
  border-radius: 12px;
  background: linear-gradient(135deg, #3b82f6, #1d4ed8);
  color: white;
  font-weight: 700;
  font-size: 16px;
  box-shadow: 0 6px 20px rgba(59, 130, 246, 0.2);
}

.question-status {
  display: flex;
  align-items: center;
  gap: 16px;
}

.result-badge {
  width: 48px;
  height: 48px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
  box-shadow: 0 6px 20px rgba(0, 0, 0, 0.15);
}

.result-badge.ok {
  background: linear-gradient(135deg, #10b981, #059669);
}

.result-badge.bad {
  background: linear-gradient(135deg, #ef4444, #dc2626);
}

.result-badge .icon {
  width: 22px;
  height: 22px;
  stroke: currentColor;
  stroke-width: 2.5;
  fill: none;
}

.score-display {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 2px;
}

.score-label {
  font-size: 12px;
  color: #6b7280;
  font-weight: 500;
}

.score-value {
  font-size: 18px;
  font-weight: 700;
  color: #0b2540;
}

.question-content {
  padding: 24px;
}

.question-text {
  margin-bottom: 24px;
}

.question-title {
  font-size: 15px;
  font-weight: 700;
  color: #0f172a;
  margin: 0 0 8px 0;
  display: flex;
  align-items: center;
  gap: 8px;
}

.question-title::before {
  content: "❓";
  font-size: 16px;
}

.question-body {
  font-size: 15px;
  line-height: 1.6;
  color: #334155;
  margin: 0;
  padding: 16px;
  background: linear-gradient(135deg, #f8fafc, #f1f5f9);
  border-radius: 12px;
  border-left: 4px solid #3b82f6;
}

.answer-section {
  display: grid;
  gap: 18px;
}

.user-answer-block,
.fact-answer-block {
  padding: 18px;
  border-radius: 12px;
  border: 1px solid rgba(6, 34, 68, 0.06);
}

.user-answer-block {
  background: linear-gradient(135deg, #fefefe, #f9fafb);
}

.fact-answer-block {
  background: linear-gradient(135deg, #f0f9ff, #e0f2fe);
  border-left: 4px solid #0ea5e9;
}

.answer-title {
  font-size: 14px;
  font-weight: 700;
  color: #475569;
  margin: 0 0 8px 0;
  display: flex;
  align-items: center;
  gap: 8px;
}

.answer-title::before {
  content: "✍️";
  font-size: 14px;
}

.fact-title {
  font-size: 14px;
  font-weight: 700;
  color: #0c4a6e;
  margin: 0 0 12px 0;
  display: flex;
  align-items: center;
  gap: 8px;
}

.fact-icon {
  width: 16px;
  height: 16px;
  fill: #0ea5e9;
  stroke: none;
}

.user-answer {
  font-size: 14px;
  line-height: 1.5;
  color: #1e293b;
  margin: 0;
  font-weight: 500;
}

.user-answer.empty {
  color: #94a3b8;
  font-style: italic;
}

.fact-answer {
  font-size: 14px;
  line-height: 1.6;
  color: #0c4a6e;
  margin: 0;
  font-weight: 500;
}

/* Footer */
.card-foot {
  margin-top: 32px;
  display: flex;
  flex-direction: column;
  gap: 16px;
  align-items: stretch;
}

.actions {
  display: flex;
  gap: 12px;
  justify-content: flex-end;
}

.btn {
  padding: 12px 20px;
  border-radius: 10px;
  font-weight: 700;
  font-size: 14px;
  border: none;
  cursor: pointer;
  transition: all 0.2s ease;
}

.btn-outline {
  background: transparent;
  border: 2px solid rgba(6, 34, 68, 0.1);
  color: #0b2540;
}

.btn-outline:hover {
  background: rgba(6, 34, 68, 0.04);
  border-color: rgba(6, 34, 68, 0.2);
}

.btn-primary {
  background: linear-gradient(135deg, #06b6d4, #3b82f6);
  color: white;
  box-shadow: 0 8px 24px rgba(59, 130, 246, 0.12);
}

.btn-primary:hover {
  transform: translateY(-1px);
  box-shadow: 0 12px 32px rgba(59, 130, 246, 0.16);
}

.small {
  font-size: 12px;
  color: #6b7280;
  text-align: center;
  margin-top: 8px;
}

/* Responsive */
@media (max-width: 768px) {
  .summary-stats {
    grid-template-columns: 1fr;
    gap: 12px;
  }
  
  .question-header {
    flex-direction: column;
    gap: 12px;
    text-align: center;
  }
  
  .question-status {
    justify-content: center;
  }
  
  .question-content {
    padding: 16px;
  }
}

@media (max-width: 640px) {
  .page-root {
    padding: 16px;
  }
  
  .card {
    padding: 16px;
  }

  .score-area {
    flex-direction: column;
    align-items: flex-start;
    gap: 16px;
  }

  .actions {
    justify-content: space-between;
    flex-wrap: wrap;
  }

  .btn {
    flex: 1;
    min-width: 120px;
  }

  .stat-number {
    font-size: 20px;
  }
  
  .question-number,
  .result-badge {
    width: 40px;
    height: 40px;
  }
  
  .question-number {
    font-size: 14px;
  }
  
  .result-badge .icon {
    width: 18px;
    height: 18px;
  }
}
</style>