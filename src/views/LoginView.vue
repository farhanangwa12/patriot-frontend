<template>
  <div class="page-wrap">
    <div class="card" role="dialog" aria-labelledby="login-title" aria-modal="true">
      <header class="card-head">
        <h1 id="login-title">Masuk</h1>
        <p class="lead">Akses kuis dengan akun Anda.</p>
      </header>

      <form class="form" @submit.prevent="handleLogin" novalidate>
        <div class="field">
          <label for="email">Email</label>
          <input
            id="email"
            type="email"
            v-model="email"
            autocomplete="email"
            :disabled="loading"
            :aria-invalid="!!error && !email"
            placeholder="Masukkan email"
          />
        </div>

        <div class="field">
          <label for="password">Password</label>
          <div class="password-wrap">
            <input
              id="password"
              :type="showPassword ? 'text' : 'password'"
              v-model="password"
              autocomplete="current-password"
              :disabled="loading"
              :aria-invalid="!!error && !password"
              placeholder="Masukkan password"
            />
            <button
              type="button"
              class="pw-toggle"
              @click="togglePassword"
              :aria-pressed="showPassword"
              :disabled="loading"
              :title="showPassword ? 'Sembunyikan password' : 'Tampilkan password'"
            >
              <span v-if="showPassword">👁️</span>
              <span v-else>🙈</span>
            </button>
          </div>
        </div>

        <div class="row">
          <label class="checkbox">
            <input type="checkbox" v-model="remember" :disabled="loading" />
            <span>Remember me</span>
          </label>
          <button type="button" class="link" @click="fillDemo" :disabled="loading">Demo creds</button>
        </div>

        <p v-if="error" class="error" role="alert" aria-live="assertive">{{ error }}</p>

        <button class="btn" type="submit" :disabled="loading">
          <span v-if="!loading">Login</span>
          <span v-else>Loading…</span>
        </button>
      </form>

      <footer class="card-foot">
        <small class="muted">
          Belum punya akun? 
          <router-link to="/register" class="link">Daftar di sini</router-link>
        </small>
      </footer>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'

const router = useRouter()
const email = ref<string>('')
const password = ref<string>('')
const showPassword = ref<boolean>(false)
const remember = ref<boolean>(false)
const error = ref<string>('')
const loading = ref<boolean>(false)

const togglePassword = () => {
  showPassword.value = !showPassword.value
}

// Isi demo credentials cepat
const fillDemo = () => {
  email.value = 'test@test.com'
  password.value = '123'
  error.value = ''
}

onMounted(() => {
  try {
    const saved = localStorage.getItem('quiz_demo_email')
    if (saved) {
      email.value = saved
      remember.value = true
    }
  } catch (e) {
    // ignore localStorage errors (private mode)
  }
})

const handleLogin = async () => {
  error.value = ''

  // simple validation
  if (!email.value.trim() || !password.value) {
    error.value = 'Silakan isi email dan password'
    return
  }

  // email validation
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
  if (!emailRegex.test(email.value.trim())) {
    error.value = 'Format email tidak valid'
    return
  }

  if (password.value.length < 3) {
    error.value = 'Password minimal 3 karakter'
    return
  }

  loading.value = true

  try {
    const response = await fetch(`${import.meta.env.VITE_BASE_URL_BACKEND}/auth/login`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        email: email.value.trim(),
        password: password.value
      })
    })

    const data = await response.json()

    if (!response.ok) {
      throw new Error(data.message || 'Login gagal')
    }

    // Store token if provided
    if (data.token) {
      localStorage.setItem('token', data.token)
    }

    // "Remember me" handling
    try {
      if (remember.value) {
        localStorage.setItem('quiz_demo_email', email.value.trim())
      } else {
        localStorage.removeItem('quiz_demo_email')
      }
    } catch (e) {
      // ignore storage errors
    }

    // success -> navigate to dashboard
    router.push('/dashboard').catch(() => {})
  } catch (e) {
    error.value = e instanceof Error ? e.message : 'Terjadi kesalahan saat login. Coba lagi.'
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.page-wrap {
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
  max-width: 420px;
  background: linear-gradient(180deg, rgba(255,255,255,0.96), rgba(255,255,255,0.9));
  padding: 22px;
  border-radius: 12px;
  box-shadow: 0 12px 36px rgba(2,6,23,0.08);
  border: 1px solid rgba(6,34,68,0.04);
}

/* Header */
.card-head {
  text-align: left;
  margin-bottom: 12px;
}
.card-head h1 { margin: 0; font-size: 20px; color: #062244; }
.lead { margin: 6px 0 0; color: #576674; font-size: 13px; }

/* Form */
.form { display: flex; flex-direction: column; gap: 12px; }
.field { display: flex; flex-direction: column; gap: 6px; }

/* Labels and inputs */
label { font-size: 13px; color: #334155; }
input[type="text"],
input[type="password"],
input[type="email"],
textarea {
  padding: 10px 12px;
  border-radius: 10px;
  border: 1px solid rgba(6,34,68,0.08);
  background: #fff;
  font-size: 14px;
  outline: none;
  transition: box-shadow 160ms, border-color 160ms, transform 140ms;
}
input:focus {
  border-color: rgba(59,130,246,0.9);
  box-shadow: 0 10px 30px rgba(59,130,246,0.06);
  transform: translateY(-1px);
}

/* password input + toggle */
.password-wrap {
  display: flex;
  gap: 8px;
  align-items: center;
}
.password-wrap input {
  flex: 1 1 auto;
}
.pw-toggle {
  display: inline-grid;
  place-items: center;
  padding: 8px;
  border-radius: 10px;
  border: 1px solid rgba(6,34,68,0.06);
  background: #fafafa;
  cursor: pointer;
  font-size: 14px;
  line-height: 1;
}
.pw-toggle:disabled { opacity: 0.6; cursor: not-allowed; }
.pw-toggle:focus { outline: 3px solid rgba(59,130,246,0.12); outline-offset: 2px; }

/* row for remember + demo */
.row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 12px;
}
.checkbox { display: inline-flex; align-items: center; gap: 8px; font-size: 14px; color: #334155; }
.link {
  background: transparent;
  border: none;
  color: #0b6ea8;
  cursor: pointer;
  font-weight: 700;
  font-size: 13px;
  text-decoration: none;
}
.link:disabled { opacity: 0.6; cursor: not-allowed; }
.link:hover { text-decoration: underline; }

/* Error and button */
.error { color: #dc2626; font-size: 13px; margin: 4px 0; }
.btn {
  width: 100%;
  padding: 12px;
  border-radius: 10px;
  border: none;
  background: linear-gradient(90deg,#06b6d4,#3b82f6);
  color: #fff;
  font-weight: 700;
  cursor: pointer;
  transition: transform 140ms, box-shadow 140ms;
}
.btn:disabled { opacity: 0.6; cursor: not-allowed; transform: none; }
.btn:focus { outline: 3px solid rgba(59,130,246,0.12); outline-offset: 3px; }

/* Footer */
.card-foot { margin-top: 12px; text-align: center; }
.muted { color: #6b7280; font-size: 13px; }

/* Responsive */
@media (max-width: 480px) {
  .card { padding: 16px; border-radius: 10px; }
  .pw-toggle { padding: 6px; }
}
</style>