<template>
  <div class="page-container">
    <div class="decor-blob blob-1" aria-hidden="true"></div>
    <div class="decor-blob blob-2" aria-hidden="true"></div>

    <div class="card">
      <header class="card-head">
        <h1>{{ quizData.title || 'Selamat Datang di Kuis' }}</h1>
        <p class="subtitle">Coba jawab beberapa pertanyaan singkat — semoga menyenangkan!</p>
      </header>

      <main class="card-body">
        <div v-if="loading" class="loading-state">
          <p>Memuat data kuis...</p>
        </div>

        <div v-else-if="error" class="error-state">
          <p>{{ error }}</p>
          <button class="btn-ghost" @click="fetchQuizData">Coba Lagi</button>
        </div>

        <div v-else>
          <p>
            {{ quizData.description || 'Kuis ini terdiri dari beberapa pertanyaan pilihan ganda. Silakan baca setiap pertanyaan dengan cermat dan pilih jawaban yang paling tepat.' }}
          </p>

          <div class="quiz-info" v-if="quizData.total_questions">
            <p><strong>Total Pertanyaan:</strong> {{ quizData.total_questions }}</p>
          </div>

          <div class="cta-row">
            <button class="btn-primary" @click="startQuiz" :disabled="loading">Mulai Kuis</button>
            <button class="btn-ghost" @click="showInfo" aria-haspopup="dialog">Info</button>
          </div>
        </div>
      </main>

      <footer class="card-foot">
        <small>Tip: gunakan keyboard (Tab / Enter) untuk navigasi.</small>
      </footer>
    </div>
  </div>
</template>

<script setup lang="ts">
import { useRouter } from 'vue-router'
import { ref, onMounted } from 'vue'
import axios from 'axios';


interface QuestionStatus {
  status: string
}

interface QuizData {
  id: number
  title: string
  description: string
  question_statuses: QuestionStatus[]
  total_questions: number
  created_at: string
  updated_at: string
}

interface ApiResponse {
  status: string
  message: string
  data: QuizData
}

const router = useRouter()
const loading = ref(true)
const error = ref<string | null>(null)
const quizData = ref<Partial<QuizData>>({})

const fetchQuizData = async () => {
  loading.value = true
  error.value = null

  try {
    // Ambil dari localStorage
    const storedQuiz = localStorage.getItem("selected_quiz")
    const quiz = storedQuiz ? JSON.parse(storedQuiz) : null

    if (!quiz || !quiz.id) {
      throw new Error("Quiz tidak ditemukan di localStorage")
    }

    const id = quiz.id // contoh: 6

    // Kalau pakai TS -> gunakan generic
    // const response = await axios.get<ApiResponse>(`http://localhost:3000/quiz/intro/${id}`)
    // Kalau pakai JS biasa -> hapus generic
    const response = await axios.get(`http://localhost:3000/quiz/intro/${id}`)

    console.log("Response quiz intro:", response)

    if (response.data.status === "success") {
      quizData.value = response.data.data
    } else {
      error.value = "Gagal memuat data kuis"
    }
  } catch (err) {
    console.error("Error fetching quiz data:", err)
    error.value =
      "Tidak dapat menghubungi server. Pastikan server berjalan di localhost:3000"
  } finally {
    loading.value = false
  }
}


const startQuiz = () => {
  // jika router tersedia, pindah ke halaman /quiz
  if (router && typeof router.push === 'function') {
    router.push('/quiz')
  } else {
    // fallback bila belum ada router — masih kelihatan selama development
    alert('Kuis dimulai! (router belum terpasang)')
  }
}

const showInfo = () => {
  const infoMessage = quizData.value.title
    ? `${quizData.value.title}\n\nTotal pertanyaan: ${quizData.value.total_questions || 'N/A'}\n\nGood luck!`
    : 'Kuis ini dibuat untuk latihan singkat. Good luck!'

  alert(infoMessage)
}

// Fetch data ketika component dimount
onMounted(() => {
  fetchQuizData()
})
</script>

<style scoped>
/* Variables (component-scoped) */
.page-container {
  --bg-1: #e8fbff;
  --bg-2: #f0fff4;
  --primary: #0ea5e9;
  /* sky-500 */
  --primary-dark: #0284c7;
  --muted: #6b7280;
  --glass: rgba(255, 255, 255, 0.75);
  font-family: Inter, ui-sans-serif, system-ui, -apple-system, "Segoe UI", Roboto, "Helvetica Neue", Arial;
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 28px;
  position: relative;
  background: linear-gradient(135deg, var(--bg-1) 0%, var(--bg-2) 100%);
  overflow: hidden;
}

/* decorative blobs */
.decor-blob {
  position: absolute;
  filter: blur(40px);
  opacity: 0.55;
  transform: translateZ(0);
  pointer-events: none;
}

.blob-1 {
  width: 340px;
  height: 340px;
  left: -80px;
  top: -80px;
  background: radial-gradient(circle at 30% 30%, rgba(14, 165, 233, 0.35), transparent 40%),
    radial-gradient(circle at 70% 70%, rgba(16, 185, 129, 0.22), transparent 40%);
}

.blob-2 {
  width: 280px;
  height: 280px;
  right: -60px;
  bottom: -60px;
  background: radial-gradient(circle at 20% 20%, rgba(99, 102, 241, 0.18), transparent 40%),
    radial-gradient(circle at 80% 80%, rgba(14, 165, 233, 0.12), transparent 40%);
}

/* card */
.card {
  width: 100%;
  max-width: 720px;
  background: linear-gradient(180deg, rgba(255, 255, 255, 0.9), rgba(255, 255, 255, 0.82));
  border-radius: 16px;
  box-shadow: 0 10px 30px rgba(16, 24, 40, 0.08);
  padding: 28px;
  backdrop-filter: blur(6px);
  border: 1px solid rgba(255, 255, 255, 0.6);
  position: relative;
  z-index: 1;
}

/* header */
.card-head {
  text-align: center;
  margin-bottom: 18px;
}

.card-head h1 {
  font-size: 28px;
  margin: 0;
  color: #0f172a;
  letter-spacing: -0.2px;
}

.subtitle {
  margin-top: 6px;
  color: var(--muted);
  font-size: 14px;
}

/* body */
.card-body {
  color: #374151;
  line-height: 1.6;
  font-size: 15px;
  padding: 6px 10px 18px 10px;
}

/* CTA row */
.cta-row {
  margin-top: 20px;
  display: flex;
  gap: 12px;
  justify-content: center;
  align-items: center;
  flex-wrap: wrap;
}

/* Buttons */
button {
  font-family: inherit;
  border: none;
  outline: none;
  cursor: pointer;
  transition: transform 180ms cubic-bezier(.2, .9, .2, 1), box-shadow 160ms;
}

.btn-primary {
  background: linear-gradient(90deg, var(--primary), var(--primary-dark));
  color: white;
  padding: 12px 20px;
  border-radius: 10px;
  font-weight: 600;
  box-shadow: 0 6px 18px rgba(14, 165, 233, 0.18), inset 0 -1px 0 rgba(255, 255, 255, 0.06);
}

.btn-primary:focus {
  box-shadow: 0 8px 24px rgba(14, 165, 233, 0.22);
  transform: translateY(-2px);
}

.btn-primary:active {
  transform: translateY(0);
}

.btn-ghost {
  background: transparent;
  color: var(--primary-dark);
  padding: 10px 16px;
  border-radius: 10px;
  border: 1px solid rgba(14, 165, 233, 0.12);
  font-weight: 600;
}

.btn-ghost:focus {
  box-shadow: 0 6px 18px rgba(14, 165, 233, 0.12);
  transform: translateY(-2px);
}

/* footer */
.card-foot {
  margin-top: 18px;
  text-align: center;
  color: var(--muted);
  font-size: 13px;
}

/* responsive */
@media (max-width: 640px) {
  .card {
    padding: 20px;
    border-radius: 12px;
  }

  .card-head h1 {
    font-size: 22px;
  }

  .cta-row {
    gap: 8px;
  }
}

/* small accessibility focus style for keyboard users */
:focus {
  outline: 3px solid rgba(14, 165, 233, 0.18);
  outline-offset: 2px;
  border-radius: 8px;
}
</style>
