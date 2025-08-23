<template>
  <div class="page-wrap">
    <div class="card" role="dialog" aria-labelledby="register-title" aria-modal="true">
      <header class="card-head">
        <h1 id="register-title">Daftar</h1>
        <p class="lead">Buat akun baru untuk mengakses kuis.</p>
      </header>

      <form class="form" @submit.prevent="handleRegister" novalidate>
        <div class="field">
          <label for="name">Nama Lengkap</label>
          <input
            id="name"
            type="text"
            v-model="name"
            autocomplete="name"
            :disabled="loading"
            :aria-invalid="!!error && !name"
            placeholder="Masukkan nama lengkap"
          />
        </div>

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
              autocomplete="new-password"
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

        <div class="field">
          <label for="confirmPassword">Konfirmasi Password</label>
          <div class="password-wrap">
            <input
              id="confirmPassword"
              :type="showConfirmPassword ? 'text' : 'password'"
              v-model="confirmPassword"
              autocomplete="new-password"
              :disabled="loading"
              :aria-invalid="!!error && !confirmPassword"
              placeholder="Konfirmasi password"
            />
            <button
              type="button"
              class="pw-toggle"
              @click="toggleConfirmPassword"
              :aria-pressed="showConfirmPassword"
              :disabled="loading"
              :title="showConfirmPassword ? 'Sembunyikan password' : 'Tampilkan password'"
            >
              <span v-if="showConfirmPassword">👁️</span>
              <span v-else>🙈</span>
            </button>
          </div>
        </div>

        <div class="row">
          <button type="button" class="link" @click="fillDemo" :disabled="loading">Demo data</button>
        </div>

        <p v-if="error" class="error" role="alert" aria-live="assertive">{{ error }}</p>
        <p v-if="success" class="success" role="alert" aria-live="assertive">{{ success }}</p>

        <button class="btn" type="submit" :disabled="loading">
          <span v-if="!loading">Daftar</span>
          <span v-else>Loading…</span>
        </button>
      </form>

      <footer class="card-foot">
        <small class="muted">
          Sudah punya akun? 
          <router-link to="/" class="link">Masuk di sini</router-link>
        </small>
      </footer>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'

const router = useRouter()
const name = ref<string>('')
const email = ref<string>('')
const password = ref<string>('')
const confirmPassword = ref<string>('')
const showPassword = ref<boolean>(false)
const showConfirmPassword = ref<boolean>(false)
const error = ref<string>('')
const success = ref<string>('')
const loading = ref<boolean>(false)

const togglePassword = () => {
  showPassword.value = !showPassword.value
}

const toggleConfirmPassword = () => {
  showConfirmPassword.value = !showConfirmPassword.value
}

// Isi demo data cepat
const fillDemo = () => {
  name.value = 'Rudolf Supratman'
  email.value = 'mantap@mantap.com'
  password.value = '123'
  confirmPassword.value = '123'
  error.value = ''
  success.value = ''
}

const handleRegister = async () => {
  error.value = ''
  success.value = ''

  // Validation
  if (!name.value.trim() || !email.value.trim() || !password.value || !confirmPassword.value) {
    error.value = 'Silakan isi semua field'
    return
  }

  if (name.value.trim().length < 2) {
    error.value = 'Nama minimal 2 karakter'
    return
  }

  // Email validation
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
  if (!emailRegex.test(email.value.trim())) {
    error.value = 'Format email tidak valid'
    return
  }

  if (password.value.length < 3) {
    error.value = 'Password minimal 3 karakter'
    return
  }

  if (password.value !== confirmPassword.value) {
    error.value = 'Password dan konfirmasi password tidak sama'
    return
  }

  loading.value = true

  try {
    const response = await fetch(`${import.meta.env.VITE_BASE_URL_BACKEND}/auth/register`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        name: name.value.trim(),
        email: email.value.trim(),
        password: password.value
      })
    })

    const data = await response.json()

    if (!response.ok) {
      throw new Error(data.message || 'Registrasi gagal')
    }

    success.value = 'Registrasi berhasil! Mengalihkan ke halaman login...'
    
    // Redirect to login after 2 seconds
    setTimeout(() => {
      router.push('/').catch(() => {})
    }, 2000)

  } catch (e) {
    error.value = e instanceof Error ? e.message : 'Terjadi kesalahan saat registrasi. Coba lagi.'
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

/* row for demo button */
.row {
  display: flex;
  justify-content: flex-end;
  align-items: center;
  gap: 12px;
}

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

/* Error, success and button */
.error { color: #dc2626; font-size: 13px; margin: 4px 0; }
.success { color: #16a34a; font-size: 13px; margin: 4px 0; }
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