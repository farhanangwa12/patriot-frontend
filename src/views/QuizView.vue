<template>
  <div class="page-container">
    <div class="decor decor-1" aria-hidden="true"></div>
    <div class="decor decor-2" aria-hidden="true"></div>

    <!-- Loading State -->
    <div v-if="loading" class="card loading-state">
      <div class="loading-spinner"></div>
      <p>Memuat kuis...</p>
    </div>

    <!-- Error State -->
    <div v-else-if="error" class="card error-state">
      <h2>❌ Gagal memuat kuis</h2>
      <p>{{ error }}</p>
      <button @click="loadQuiz" class="btn btn-primary">Coba Lagi</button>
    </div>

    <!-- Quiz Content -->
    <main v-else class="card" role="main" aria-labelledby="quiz-title">
      <!-- Header -->
      <header class="card-header">
        <div class="title-wrap">
          <h1 id="quiz-title">{{ quizData.title }}</h1>
          <p class="subtitle">{{ quizData.description }}</p>
        </div>

        <div class="timer" role="status" aria-live="polite">
          <svg viewBox="0 0 24 24" class="timer-icon" aria-hidden="true">
            <path d="M12 7v6l4 2" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round"
              stroke-linejoin="round" />
            <circle cx="12" cy="12" r="9" fill="none" stroke="currentColor" stroke-width="1.2" />
          </svg>
          <span class="timer-text">Waktu: <strong>{{ timeLeft }}</strong>s</span>
        </div>
      </header>

      <!-- Progress -->
      <section class="progress-wrap" aria-hidden="false">
        <div class="progress-bar" aria-label="progress">
          <div class="progress-fill" :style="{ width: progress + '%' }"></div>
        </div>
        <div class="progress-meta">
          <span>Soal {{ currentQuestion + 1 }} / {{ questions.length }}</span>
          <span>{{ Math.round(progress) }}%</span>
        </div>
      </section>

      <!-- Question -->
      <section class="question">
        <h2 class="question-text">{{ questions[currentQuestion].question_text }}</h2>

        <label class="answer-label" for="answer">Jawaban</label>
        <textarea id="answer" rows="4" :value="answers[currentQuestion] || ''" @input="updateAnswer"
          class="answer-input" placeholder="Ketik jawaban Anda di sini..." aria-describedby="err"></textarea>

        <p v-if="validationError" id="err" class="error-msg" role="alert">{{ validationError }}</p>
      </section>

      <!-- Navigation -->
      <nav class="controls" aria-label="Navigation">
        <button @click="prevQuestion" :disabled="currentQuestion === 0" class="btn btn-muted"
          aria-disabled="currentQuestion === 0">
          ← Sebelumnya
        </button>

        <div class="mid-controls">
          <button class="btn btn-ghost" @click="clearAnswer" title="Hapus jawaban saat ini">Clear</button>
          <button class="btn btn-primary" @click="nextQuestion" :disabled="submitting">
            {{ submitting ? 'Mengirim...' : (currentQuestion < questions.length - 1 ? 'Berikutnya →' : 'Selesai') }}
              </button>
        </div>
      </nav>
    </main>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import axios from "axios"
interface Question {
  id: number
  quiz_id: number
  question_text: string
  fact_answer: string
  question_type: string
  created_by_ai: boolean
  created_at: string
}

interface QuizData {
  id: number
  title: string
  description: string
  question_statuses: Array<{ status: string }>
  total_questions: number
  created_at: string
  updated_at: string
}

interface ApiResponse {
  status: string
  message: string
  data: {
    quiz: QuizData
    questions: Question[]
  }
}

const router = useRouter()

// State variables
const loading = ref<boolean>(true)
const error = ref<string>('')
const quizData = ref<QuizData | null>(null)
const questions = ref<Question[]>([])
const currentQuestion = ref<number>(0)
const answers = ref<string[]>([])
const validationError = ref<string>('')
const timeLeft = ref<number>(30)
const submitting = ref<boolean>(false)
let timer: number | null = null

const progress = computed(() => ((currentQuestion.value + 1) / questions.value.length) * 100)

// Load quiz data from API
const loadQuiz = async () => {
  try {
    loading.value = true
    error.value = ''

    // 🔹 Ambil dari localStorage
    const storedQuiz = localStorage.getItem("selected_quiz")
    const quiz = storedQuiz ? JSON.parse(storedQuiz) : null

    if (!quiz || !quiz.id) {
      throw new Error("Quiz tidak ditemukan di localStorage")
    }

    const id = quiz.id // contoh: 6

    // 🔹 Request POST pakai Axios
    const response = await axios.post("http://localhost:3000/quiz/start", { id })

    const data = response.data

    if (data.status !== "success") {
      throw new Error(data.message || "Gagal memuat data kuis")
    }

    // 🔹 Simpan hasil
    quizData.value = data.data.quiz
    questions.value = data.data.questions
    answers.value = Array(data.data.questions.length).fill("")

  } catch (err) {
    console.error("Error loading quiz:", err)
    error.value = err instanceof Error ? err.message : "Terjadi kesalahan saat memuat kuis"
  } finally {
    loading.value = false
  }
}

// Update answer from textarea
const updateAnswer = (event: Event) => {
  const target = event.target as HTMLTextAreaElement
  answers.value[currentQuestion.value] = target.value
  validationError.value = ''
}

// Submit answers to API
const submitAnswers = async () => {
  try {
    submitting.value = true

    const submissionData = {
      user_id: 1, // sebaiknya ambil dari auth
      quiz_id: quizData.value!.id,
      answers: questions.value.map((question, index) => ({
        question_id: question.id,
        user_answer: (answers.value[index] || '').trim() // ← trim() saat submit saja
      }))
    }

    const response = await axios.post("http://localhost:3000/quiz/submit", submissionData)
    const resp = response.data

    // cek respons sukses (dua kemungkinan struktur)
    const ok = !!(resp?.success || resp?.status === 'success')

    if (!ok) {
      validationError.value = resp?.message || "Gagal mengirim jawaban."
      return
    }

    // ambil objek hasil dari respons (biasanya resp.data)
    const result = resp.data ?? resp

    // simpan ke localStorage (key: 'result_quiz')
    localStorage.setItem('result_quiz', JSON.stringify(result))
    console.log('Quiz result saved to localStorage:', result)

    // redirect ke /result (tidak memakai encoded query)
    if (router && typeof router.push === 'function') {
      await router.push({ name: 'result' }) // atau router.push('/result')
    } else {
      // fallback jika router tidak tersedia
      window.location.href = '/result'
    }
  } catch (err: any) {
    console.error('Error submitting answers:', err)
    validationError.value = err?.response?.data?.message || err?.message || 'Gagal mengirim jawaban. Silakan coba lagi.'
  } finally {
    submitting.value = false
  }
}

// Next question or submit
const nextQuestion = async (force = false) => {
  const currentAns = (answers.value[currentQuestion.value] || '').trim()

  if (!force && currentAns === '') {
    validationError.value = 'Silakan isi jawaban sebelum melanjutkan'
    return
  }

  validationError.value = ''

  if (currentQuestion.value < questions.value.length - 1) {
    currentQuestion.value++
    resetTimer()
  } else {
    // Submit all answers
    await submitAnswers()
  }
}

const prevQuestion = () => {
  if (currentQuestion.value > 0) {
    currentQuestion.value--
    validationError.value = ''
    resetTimer()
  }
}

const clearAnswer = () => {
  answers.value[currentQuestion.value] = ''
  validationError.value = ''
}

// Timer functions
const resetTimer = () => {
  timeLeft.value = 30
}

// Lifecycle hooks
onMounted(() => {
  loadQuiz()

  timer = window.setInterval(() => {
    if (timeLeft.value > 0) {
      timeLeft.value--
    } else {
      // Auto-advance when time runs out
      nextQuestion(true)
    }
  }, 1000)
})

onUnmounted(() => {
  if (timer !== null) {
    clearInterval(timer)
    timer = null
  }
})
</script>

<style scoped>
/* Root layout */
.page-container {
  --bg-a: #f0fbff;
  --bg-b: #f7fff4;
  --glass: rgba(255, 255, 255, 0.82);
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 28px;
  background: linear-gradient(135deg, var(--bg-a), var(--bg-b));
  font-family: Inter, ui-sans-serif, system-ui, -apple-system, "Segoe UI", Roboto, "Helvetica Neue", Arial;
  position: relative;
  overflow: hidden;
}

/* Decorative blobs */
.decor {
  position: absolute;
  filter: blur(36px);
  opacity: 0.45;
  pointer-events: none;
}

.decor-1 {
  left: -100px;
  top: -80px;
  width: 340px;
  height: 340px;
  background: radial-gradient(circle at 30% 30%, rgba(16, 185, 129, 0.18), transparent 30%),
    radial-gradient(circle at 70% 70%, rgba(99, 102, 241, 0.14), transparent 30%);
}

.decor-2 {
  right: -70px;
  bottom: -60px;
  width: 300px;
  height: 300px;
  background: radial-gradient(circle at 20% 20%, rgba(14, 165, 233, 0.18), transparent 30%),
    radial-gradient(circle at 80% 80%, rgba(99, 102, 241, 0.08), transparent 30%);
}

/* Card */
.card {
  width: 100%;
  max-width: 820px;
  background: linear-gradient(180deg, var(--glass), rgba(255, 255, 255, 0.78));
  border-radius: 14px;
  padding: 22px;
  box-shadow: 0 12px 40px rgba(2, 6, 23, 0.08);
  border: 1px solid rgba(255, 255, 255, 0.6);
  backdrop-filter: blur(6px);
  z-index: 1;
}

/* Header */
.card-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  margin-bottom: 12px;
}

.title-wrap h1 {
  margin: 0;
  font-size: 20px;
  color: #062244;
  letter-spacing: -0.2px;
}

.subtitle {
  margin: 4px 0 0;
  font-size: 13px;
  color: #556070;
}

/* Timer */
.timer {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 13px;
  color: #0b6ea8;
}

.timer-icon {
  width: 28px;
  height: 28px;
  color: #0b6ea8;
  opacity: 0.95;
}

/* Progress */
.progress-wrap {
  margin: 12px 0 18px;
}

.progress-bar {
  height: 10px;
  width: 100%;
  background: rgba(6, 34, 68, 0.06);
  border-radius: 999px;
  overflow: hidden;
  border: 1px solid rgba(6, 34, 68, 0.03);
}

.progress-fill {
  height: 100%;
  width: 0%;
  background: linear-gradient(90deg, #06b6d4, #3b82f6);
  transition: width 450ms cubic-bezier(.2, .9, .2, 1);
}

.progress-meta {
  display: flex;
  justify-content: space-between;
  font-size: 12px;
  color: #5b6b78;
  margin-top: 8px;
}

/* Question block */
.question-text {
  margin: 0 0 6px;
  font-size: 18px;
  color: #062244;
}

.question-desc {
  margin: 0 0 12px;
  color: #50606b;
  font-size: 14px;
}

/* Input */
.answer-label {
  display: block;
  font-size: 13px;
  color: #334155;
  margin-bottom: 6px;
}

.answer-input {
  width: 100%;
  resize: vertical;
  min-height: 84px;
  border-radius: 10px;
  padding: 12px;
  font-size: 14px;
  border: 1px solid rgba(6, 34, 68, 0.08);
  background: rgba(255, 255, 255, 0.9);
  box-shadow: inset 0 -1px 0 rgba(0, 0, 0, 0.02);
  transition: box-shadow 160ms, border-color 160ms, transform 160ms;
}

.answer-input:focus {
  outline: none;
  border-color: rgba(59, 130, 246, 0.9);
  box-shadow: 0 8px 30px rgba(59, 130, 246, 0.08);
  transform: translateY(-1px);
}

/* Error */
.error-msg {
  margin-top: 8px;
  color: #dc2626;
  font-size: 13px;
}

/* Controls */
.controls {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  margin-top: 18px;
}

.btn {
  border: none;
  padding: 10px 14px;
  border-radius: 10px;
  cursor: pointer;
  font-weight: 600;
  font-size: 14px;
  transition: transform 140ms, box-shadow 140ms;
}

.btn:active {
  transform: translateY(0)
}

.btn:focus {
  outline: 3px solid rgba(59, 130, 246, 0.14);
  outline-offset: 3px;
}

.btn-primary {
  background: linear-gradient(90deg, #06b6d4, #3b82f6);
  color: white;
  box-shadow: 0 8px 26px rgba(59, 130, 246, 0.12);
}

.btn-muted {
  background: #eef2f7;
  color: #334155;
}

.btn-ghost {
  background: transparent;
  color: #0b6ea8;
  border: 1px solid rgba(11, 110, 168, 0.08);
}

.mid-controls {
  display: flex;
  gap: 8px;
  align-items: center;
}

/* Disabled */
button[disabled],
.btn[aria-disabled="true"] {
  opacity: 0.45;
  cursor: not-allowed;
  transform: none;
  box-shadow: none;
}

/* Responsive */
@media (max-width: 640px) {
  .card {
    padding: 16px;
    border-radius: 12px;
  }

  .title-wrap h1 {
    font-size: 18px;
  }

  .timer-icon {
    width: 22px;
    height: 22px;
  }
}
</style>
