<template>
  <div class="page-root">
    <div class="card" role="region" aria-labelledby="result-title">
      <header class="card-head">
        <h1 id="result-title">Hasil Kuis</h1>
        <p class="muted">Berikut ringkasan jawaban Anda.</p>
      </header>

      <section class="score-area" aria-live="polite">
        <div class="score-circle" :aria-valuenow="percentage" role="img" :title="`${percentage.toFixed(1)}%`">
          <strong>{{ score }}</strong>
          <small>/ {{ questions.length }}</small>
        </div>

        <div class="score-meta">
          <div class="percent">{{ percentage.toFixed(2) }}%</div>
          <div class="detail">Skor: <strong>{{ score }}</strong> dari <strong>{{ questions.length }}</strong></div>
        </div>
      </section>

      <section class="breakdown" aria-label="Rincian jawaban">
        <h2 class="breakdown-title">Rincian</h2>
        <ul class="list">
          <li v-for="(q, i) in questions" :key="i" class="item">
            <div class="item-left">
              <div class="q-index">#{{ i + 1 }}</div>
              <div class="q-body">
                <div class="q-label">Jawaban Anda</div>
                <div class="user-answer">
                  <template v-if="userAnswers[i] !== undefined && userAnswers[i] !== ''">
                    {{ userAnswers[i] }}
                  </template>
                  <template v-else>
                    <em class="empty">(kosong)</em>
                  </template>
                </div>
              </div>
            </div>

            <div class="item-right">
              <div class="result-badge" :class="{ ok: isCorrect(i), bad: !isCorrect(i) }" :aria-label="isCorrect(i) ? 'Benar' : 'Salah'">
                <svg v-if="isCorrect(i)" viewBox="0 0 24 24" class="icon" aria-hidden="true"><path d="M20 6L9 17l-5-5" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg>
                <svg v-else viewBox="0 0 24 24" class="icon" aria-hidden="true"><path d="M18 6L6 18M6 6l12 12" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg>
              </div>

              <div class="correct">
                <div class="label">Kunci</div>
                <div class="value">{{ formatCorrect(q.correct) }}</div>
              </div>
            </div>
          </li>
        </ul>
      </section>

      <footer class="card-foot">
        <div class="actions">
          <button class="btn btn-outline" @click="restartQuiz">Ulangi Kuis</button>
          <button class="btn btn-primary" @click="goHome">Beranda</button>
        </div>
        <p class="small muted">Jika jawaban tampak salah karena format, pastikan pemisah jawaban yang dikirim dari halaman quiz cocok (`,` atau `|`).</p>
      </footer>
    </div>
  </div>
</template>

<script setup lang="ts">
import { useRoute, useRouter } from 'vue-router'
import { computed } from 'vue'

const route = useRoute()
const router = useRouter()

// Raw answers from query (robust handling)
// supports: encoded strings, separators '|' or ',' or single value
const raw = route.query.answers ? String(route.query.answers) : ''
const decoded = raw ? decodeURIComponent(raw) : ''
let parts: string[] = []

if (decoded) {
  if (decoded.includes('|')) parts = decoded.split('|')
  else if (decoded.includes(',')) parts = decoded.split(',')
  else parts = [decoded]
}
// trim all parts
const userAnswers = parts.map(p => p.trim())

// QUESTIONS: adapt sesuai struktur aplikasi (example minimal)
const questions = [
  { correct: 0 },
  { correct: 1 }
]

// helper: normalize + compare values (supports number and string keys)
function isCorrectAt(index: number): boolean {
  const userRaw = userAnswers[index]
  const q = questions[index]
  if (userRaw === undefined || userRaw === '') return false

  // If correct key is number, compare numeric
  if (typeof q.correct === 'number') {
    const parsed = Number(userRaw)
    // If user input cannot be parsed to number, treat as incorrect
    return !Number.isNaN(parsed) && parsed === q.correct
  }

  // Else compare as case-insensitive trimmed string
  return String(userRaw).trim().toLowerCase() === String(q.correct).trim().toLowerCase()
}

const score = computed(() => {
  return questions.reduce((acc, _q, idx) => (isCorrectAt(idx) ? acc + 1 : acc), 0)
})
const percentage = computed(() => (questions.length ? (score.value / questions.length) * 100 : 0))

// Small wrappers for template usage
const isCorrect = (i: number) => isCorrectAt(i)
const formatCorrect = (val: unknown) => (typeof val === 'number' ? String(val) : String(val))

const restartQuiz = () => {
  // push to intro or route you use for starting quiz
  router.push('/intro').catch(() => {})
}
const goHome = () => {
  router.push('/').catch(() => {})
}
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
  background: linear-gradient(180deg, rgba(255,255,255,0.95), rgba(255,255,255,0.9));
  box-shadow: 0 14px 40px rgba(2,6,23,0.08);
  border: 1px solid rgba(0,0,0,0.04);
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
.muted { color: #6b7280; font-size: 13px; }

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
  box-shadow: 0 8px 24px rgba(6,34,68,0.06);
  border: 1px solid rgba(6,34,68,0.05);
}
.score-circle strong { font-size: 26px; display: block; line-height: 1; }
.score-circle small { font-size: 12px; color: #6b7280; }

.score-meta { display: flex; flex-direction: column; gap: 4px; }
.percent { font-size: 20px; font-weight: 700; color: #0b6ea8; }
.detail { font-size: 13px; color: #475569; }

/* Breakdown */
.breakdown { margin-top: 6px; }
.breakdown-title { margin: 10px 0; font-size: 15px; color: #0b2540; }
.list { list-style: none; padding: 0; margin: 0; display: grid; gap: 12px; }
.item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 12px;
  border-radius: 12px;
  background: linear-gradient(180deg, rgba(250,250,255,0.9), rgba(250,250,255,0.85));
  border: 1px solid rgba(6,34,68,0.03);
  box-shadow: 0 6px 18px rgba(3,10,25,0.03);
}
.item-left { display: flex; gap: 12px; align-items: center; }
.q-index {
  width: 44px;
  height: 44px;
  border-radius: 10px;
  background: rgba(6,34,68,0.04);
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 700;
  color: #062244;
}
.q-body .q-label { font-size: 12px; color: #475569; }
.user-answer { margin-top: 4px; font-weight: 600; color: #062244; }

/* Item right */
.item-right { display: flex; align-items: center; gap: 12px; }
.result-badge {
  width: 44px;
  height: 44px;
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
}
.result-badge.ok { background: linear-gradient(90deg,#10b981,#059669); }
.result-badge.bad { background: linear-gradient(90deg,#ef4444,#b91c1c); }

.icon { width: 20px; height: 20px; stroke: currentColor; stroke-width: 1.8; fill: none; }

.correct { text-align: right; }
.correct .label { font-size: 12px; color: #475569; }
.correct .value { font-weight: 700; color: #0b2540; margin-top: 4px; }

/* Footer */
.card-foot { margin-top: 16px; display: flex; flex-direction: column; gap: 10px; align-items: stretch; }
.actions { display: flex; gap: 10px; justify-content: flex-end; }
.btn {
  padding: 9px 14px;
  border-radius: 10px;
  font-weight: 700;
  border: none;
  cursor: pointer;
}
.btn-outline {
  background: transparent;
  border: 1px solid rgba(6,34,68,0.06);
  color: #0b2540;
}
.btn-primary {
  background: linear-gradient(90deg,#06b6d4,#3b82f6);
  color: white;
  box-shadow: 0 8px 24px rgba(59,130,246,0.12);
}

/* small */
.small { font-size: 12px; color: #6b7280; text-align: right; }

/* Responsive */
@media (max-width: 640px) {
  .card { padding: 16px; }
  .score-area { flex-direction: column; align-items: flex-start; gap: 10px; }
  .item { flex-direction: column; align-items: flex-start; gap: 8px; }
  .item-right { width: 100%; justify-content: space-between; }
  .actions { justify-content: space-between; }
}
</style>
