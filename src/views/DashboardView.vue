<template>
    <div class="dashboard-wrap">
        <!-- Header -->
        <header class="dashboard-header">
            <div class="container">
                <div class="header-content">
                    <h1>Dashboard Kuis</h1>
                    <div class="user-menu">
                        <span class="welcome">Selamat datang, {{ userName }}</span>
                        <button @click="handleLogout" class="btn-logout">Logout</button>
                    </div>
                </div>
            </div>
        </header>

        <!-- Main Content -->
        <main class="dashboard-main">
            <div class="container">
                <div class="dashboard-grid">
                    <!-- Welcome Card -->
                    <div class="card welcome-card">
                        <div class="card-icon">🎯</div>
                        <h2>Selamat Datang!</h2>
                        <p>Siap untuk mengasah kemampuan Anda dengan kuis menarik?</p>
                        <router-link to="/quiz-management" class="btn btn-primary">Mulai Kuis</router-link>
                    </div>

                </div>

                <!-- Purple Card (baru) -->
                <div class="card purple-card"
                    style="margin-top: 5pt; border-bottom-left-radius: 0; border-bottom-right-radius: 0;">
                    <div class="card-icon">✨</div>
                    <h2>Ringkasan Terbaru</h2>
                    <p>Lihat ringkasan singkat performa Anda dan riwayat kuis terbaru.</p>

                </div>

                <!-- Table card (full width bawah) -->
                <div class="card table-card" style="border-top-left-radius: 0; border-top-right-radius: 0;">
                    <div class="table-header">
                        <h3 class="table-title">📊 Riwayat Kuis Terakhir</h3>
                        <div class="table-subtitle">Pantau perkembangan hasil kuis Anda</div>
                    </div>

                    <div class="table-container">
                        <div class="table-wrapper">
                            <table class="modern-table">
                                <thead>
                                    <tr>
                                        <th class="th-number">#</th>
                                        <th class="th-title">Judul Kuis</th>
                                        <th class="th-date">Tanggal</th>
                                        <th class="th-stat">Benar</th>
                                        <th class="th-stat">Salah</th>
                                        <th class="th-accuracy">Akurasi</th>
                                        <th class="th-action">Aksi</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <tr v-for="(row, i) in tableData" :key="row.id" class="table-row">
                                        <td class="td-number">
                                            <div class="number-badge">{{ i + 1 }}</div>
                                        </td>
                                        <td class="td-title">
                                            <div class="quiz-info">
                                                <span class="quiz-title">{{ row.title }}</span>
                                            </div>
                                        </td>
                                        <td class="td-date">
                                            <div class="date-info">
                                                <span class="date-text">{{ formatDate(row.date) }}</span>
                                            </div>
                                        </td>
                                        <td class="td-correct">
                                            <div class="stat-correct">
                                                <span class="stat-icon">✅</span>
                                                <span class="stat-number">{{ row.correct }}</span>
                                            </div>
                                        </td>
                                        <td class="td-wrong">
                                            <div class="stat-wrong">
                                                <span class="stat-icon">❌</span>
                                                <span class="stat-number">{{ row.wrong }}</span>
                                            </div>
                                        </td>
                                        <td class="td-accuracy">
                                            <span class="accuracy-badge" :class="getBadgeClass(row.accuracy)">
                                                <span class="badge-icon">📈</span>
                                                {{ row.accuracy }}%
                                            </span>
                                        </td>
                                        <td class="td-action">
                                            <button @click="viewDetail(row.id)" class="action-button">
                                                <span class="button-icon">👁️</span>
                                                Lihat
                                            </button>
                                        </td>
                                    </tr>

                                    <tr v-if="tableData.length === 0" class="empty-state-row">
                                        <td colspan="7" class="empty-content">
                                            <div class="empty-illustration">📝</div>
                                            <div class="empty-title">Belum Ada Riwayat</div>
                                            <div class="empty-description">Selesaikan kuis pertama Anda untuk melihat
                                                riwayat di sini!</div>
                                        </td>
                                    </tr>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
        </main>
    </div>
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useRouter } from 'vue-router'
import { jwtDecode } from 'jwt-decode';
import axios from 'axios';
const router = useRouter()

// definisi tipe data dari API
interface Result {
    id: number
    title: string
    date: Date
    correct: number
    wrong: number
    accuracy: string // pakai string karena backend kirim "0.00"
}

const userName = ref<string>('User')
const stats = ref({
    totalQuiz: 0,
    highScore: 0,
    avgScore: 0
})

const activities = ref<Array<{
    id: number
    title: string
    date: Date
    score: number
}>>([])


const token = localStorage.getItem('token')

if (token) {
    const userInfo = jwtDecode<{ id: number; name: string; email: string }>(token)
    userName.value = userInfo.name
} else {
    userName.value = "Guest" // fallback kalau token tidak ada
}

// dummy data untuk tabel (bisa diganti API)
// reactive data
const tableData = ref<Result[]>([])

// ambil base URL dari .env
const BASE_URL = import.meta.env.VITE_BASE_URL_BACKEND

// fetch data dari backend
const fetchResults = async () => {
    try {
        const res = await axios.get(`${BASE_URL}/result/get-results`)
        if (res.data.success) {
            // mapping biar sesuai struktur tabel
            tableData.value = res.data.data.map(item => ({
                id: item.id_session,
                title: item.quiz_title,
                date: new Date(item.completed_at),
                correct: item.jawaban_benar,
                wrong: item.jawaban_salah,
                accuracy: parseFloat(item.akurasi).toFixed(2) // simpan akurasi dari backend
            }))
        }
    } catch (err) {
        console.error("Gagal ambil data result:", err)
    }
}

const hasResults = computed(() => activities.value.length > 0)

onMounted(() => {
    // loadUserData()
    // loadStats()
    // loadActivities()


    fetchResults();
})

// const loadUserData = () => {
//     // Try to get user info from localStorage or API
//     const savedEmail = localStorage.getItem('quiz_demo_email')
//     if (savedEmail) {
//         userName.value = savedEmail.split('@')[0]
//     }
// }

// const loadStats = () => {
//     // Load stats from localStorage (in real app, this would be from API)
//     const savedStats = localStorage.getItem('quiz_stats')
//     if (savedStats) {
//         try {
//             stats.value = JSON.parse(savedStats)
//         } catch (e) {
//             console.error('Failed to load stats:', e)
//         }
//     }
// }

// const loadActivities = () => {
//     // Load activities from localStorage (in real app, this would be from API)
//     const savedActivities = localStorage.getItem('quiz_activities')
//     if (savedActivities) {
//         try {
//             const parsed = JSON.parse(savedActivities)
//             activities.value = parsed.map((activity: any) => ({
//                 ...activity,
//                 date: new Date(activity.date)
//             }))
//         } catch (e) {
//             console.error('Failed to load activities:', e)
//         }
//     }
// }

const formatDate = (date: Date): string => {
    return new Intl.DateTimeFormat('id-ID', {
        day: 'numeric',
        month: 'short',
        hour: '2-digit',
        minute: '2-digit'
    }).format(date)
}



const handleLogout = () => {
    localStorage.removeItem('token')
    localStorage.removeItem('quiz_demo_email')
    router.push('/').catch(() => { })
}


// const calcAccuracy = (row: { correct: number; wrong: number }) => {
//     const total = row.correct + row.wrong
//     if (!total) return 0
//     return Math.round((row.correct / total) * 100)
// }

const getBadgeClass = (accuracy: string) => {
    const acc = Number(accuracy) // ubah ke number
    if (acc >= 80) return 'badge-excellent'
    if (acc >= 60) return 'badge-good'
    return 'badge-poor'
}


const viewDetail = (id: number) => {
    const data = {
        id,
        url: window.location.href
    }

    sessionStorage.setItem('sites_data', JSON.stringify(data))

    router.push('/result-quiz') // navigasi menggunakan router
}

</script>

<style scoped>
.dashboard-wrap {
    min-height: 100vh;
    background: linear-gradient(135deg, #f0fbff 0%, #f7fff4 100%);
    font-family: Inter, system-ui, -apple-system, "Segoe UI", Roboto, "Helvetica Neue", Arial;
}

.dashboard-header {
    background: rgba(255, 255, 255, 0.9);
    backdrop-filter: blur(10px);
    border-bottom: 1px solid rgba(6, 34, 68, 0.08);
    padding: 16px 0;
    position: sticky;
    top: 0;
    z-index: 100;
}

.container {
    max-width: 1200px;
    margin: 0 auto;
    padding: 0 24px;
}

.header-content {
    display: flex;
    justify-content: space-between;
    align-items: center;
}

.header-content h1 {
    margin: 0;
    color: #062244;
    font-size: 24px;
    font-weight: 700;
}

.user-menu {
    display: flex;
    align-items: center;
    gap: 16px;
}

.welcome {
    color: #576674;
    font-size: 14px;
}

.btn-logout {
    padding: 8px 16px;
    border-radius: 8px;
    border: 1px solid rgba(220, 38, 38, 0.2);
    background: rgba(220, 38, 38, 0.05);
    color: #dc2626;
    cursor: pointer;
    font-size: 13px;
    font-weight: 600;
    transition: all 140ms;
}

.btn-logout:hover {
    background: #dc2626;
    color: white;
}

.dashboard-main {
    padding: 32px 0;
}

.dashboard-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
    gap: 24px;
}

.card {
    background: linear-gradient(180deg, rgba(255, 255, 255, 0.96), rgba(255, 255, 255, 0.9));
    border-radius: 16px;
    padding: 24px;
    box-shadow: 0 8px 32px rgba(2, 6, 23, 0.08);
    border: 1px solid rgba(6, 34, 68, 0.04);
    transition: transform 140ms, box-shadow 140ms;
}

.card:hover {
    transform: translateY(-2px);
    box-shadow: 0 12px 40px rgba(2, 6, 23, 0.12);
}

.card-icon {
    font-size: 2em;
    margin-bottom: 16px;
    display: inline-block;
}

.welcome-card {
    grid-column: span 2;
    text-align: center;
    background: linear-gradient(135deg, #3b82f6, #06b6d4);
    color: white;
}

.welcome-card h2 {
    margin: 0 0 12px;
    font-size: 28px;
}

.welcome-card p {
    margin: 0 0 24px;
    opacity: 0.9;
    font-size: 16px;
}

.btn {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    padding: 12px 24px;
    border-radius: 10px;
    border: none;
    font-weight: 700;
    cursor: pointer;
    text-decoration: none;
    transition: transform 140ms, box-shadow 140ms;
}

.btn-primary {
    background: linear-gradient(90deg, #06b6d4, #3b82f6);
    color: white;
}

.btn-primary:hover {
    transform: translateY(-1px);
    box-shadow: 0 8px 25px rgba(59, 130, 246, 0.3);
}

/* Purple card */
.purple-card {
    grid-column: span 2;
    text-align: center;
    background: linear-gradient(135deg, #6d28d9, #8b5cf6);
    color: white;
}

.purple-card h2 {
    margin: 0 0 10px;
    font-size: 24px;
    font-weight: 800;
}

.purple-card p {
    margin: 0 0 18px;
    opacity: 0.95;
}

/* ===== ENHANCED TABLE STYLES ===== */
.table-card {
    grid-column: 1 / -1;
    padding: 32px;
}

.table-header {
    margin-bottom: 24px;
    text-align: left;
}

.table-title {
    margin: 0 0 8px;
    font-size: 22px;
    font-weight: 800;
    color: #0f172a;
    display: flex;
    align-items: center;
    gap: 8px;
}

.table-subtitle {
    color: #64748b;
    font-size: 15px;
    margin: 0;
}

.table-container {
    background: rgba(255, 255, 255, 0.8);
    border-radius: 16px;
    overflow: hidden;
    box-shadow: 0 8px 32px rgba(2, 6, 23, 0.06);
    border: 1px solid rgba(6, 34, 68, 0.04);
}

.table-wrapper {
    overflow-x: auto;
}

.modern-table {
    width: 100%;
    border-collapse: collapse;
    min-width: 800px;
}

/* Header Styles */
.modern-table thead th {
    background: linear-gradient(135deg, #f8fafc 0%, #f1f5f9 100%);
    padding: 20px 16px;
    font-weight: 700;
    font-size: 13px;
    color: #475569;
    text-transform: uppercase;
    letter-spacing: 0.5px;
    border-bottom: 2px solid rgba(6, 34, 68, 0.08);
    position: relative;
}

.th-number {
    width: 60px;
    text-align: center;
}

.th-title {
    width: auto;
    min-width: 200px;
}

.th-date {
    width: 140px;
}

.th-stat {
    width: 80px;
    text-align: center;
}

.th-accuracy {
    width: 100px;
    text-align: center;
}

.th-action {
    width: 100px;
    text-align: center;
}

/* Row Styles */
.table-row {
    transition: all 200ms ease;
    border-bottom: 1px solid rgba(6, 34, 68, 0.04);
}

.table-row:hover {
    background: linear-gradient(90deg, rgba(59, 130, 246, 0.02), rgba(6, 182, 212, 0.02));
    transform: translateY(-1px);
    box-shadow: 0 4px 12px rgba(2, 6, 23, 0.04);
}

.table-row:last-child {
    border-bottom: none;
}

.modern-table tbody td {
    padding: 20px 16px;
    vertical-align: middle;
}

/* Cell Content Styles */
.number-badge {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    width: 32px;
    height: 32px;
    background: linear-gradient(135deg, #3b82f6, #06b6d4);
    color: white;
    border-radius: 50%;
    font-weight: 700;
    font-size: 14px;
}

.quiz-info {
    display: flex;
    flex-direction: column;
}

.quiz-title {
    font-weight: 700;
    color: #0f172a;
    font-size: 15px;
    line-height: 1.4;
}

.date-info {
    display: flex;
    align-items: center;
    gap: 8px;
}

.date-text {
    color: #64748b;
    font-size: 14px;
    font-weight: 600;
}

.stat-correct,
.stat-wrong {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 6px;
    font-weight: 700;
}

.stat-correct {
    color: #16a34a;
}

.stat-wrong {
    color: #dc2626;
}

.stat-icon {
    font-size: 14px;
}

.stat-number {
    font-size: 16px;
}

/* Accuracy Badge */
.accuracy-badge {
    display: inline-flex;
    align-items: center;
    gap: 6px;
    padding: 8px 14px;
    border-radius: 20px;
    font-weight: 800;
    font-size: 13px;
    backdrop-filter: blur(10px);
}

.badge-excellent {
    background: linear-gradient(135deg, rgba(34, 197, 94, 0.15), rgba(34, 197, 94, 0.08));
    color: #16a34a;
    border: 1px solid rgba(34, 197, 94, 0.2);
}

.badge-good {
    background: linear-gradient(135deg, rgba(251, 191, 36, 0.15), rgba(251, 191, 36, 0.08));
    color: #d97706;
    border: 1px solid rgba(251, 191, 36, 0.2);
}

.badge-poor {
    background: linear-gradient(135deg, rgba(220, 38, 38, 0.15), rgba(220, 38, 38, 0.08));
    color: #dc2626;
    border: 1px solid rgba(220, 38, 38, 0.2);
}

.badge-icon {
    font-size: 12px;
}

/* Action Button */
.action-button {
    display: inline-flex;
    align-items: center;
    gap: 6px;
    padding: 10px 16px;
    background: linear-gradient(135deg, #f8fafc, #f1f5f9);
    border: 1px solid rgba(6, 34, 68, 0.1);
    border-radius: 10px;
    color: #475569;
    font-weight: 600;
    font-size: 13px;
    cursor: pointer;
    transition: all 200ms ease;
}

.action-button:hover {
    background: linear-gradient(135deg, #3b82f6, #06b6d4);
    color: white;
    transform: translateY(-1px);
    box-shadow: 0 4px 12px rgba(59, 130, 246, 0.25);
    border-color: transparent;
}

.button-icon {
    font-size: 12px;
}

/* Empty State */
.empty-state-row td {
    padding: 60px 20px;
}

.empty-content {
    text-align: center;
    color: #64748b;
}

.empty-illustration {
    font-size: 3em;
    margin-bottom: 16px;
}

.empty-title {
    font-size: 18px;
    font-weight: 700;
    color: #334155;
    margin-bottom: 8px;
}

.empty-description {
    font-size: 15px;
    color: #64748b;
    line-height: 1.5;
}

/* Responsive Design */
@media (max-width: 768px) {
    .dashboard-grid {
        grid-template-columns: 1fr;
    }

    .welcome-card,
    .purple-card {
        grid-column: span 1;
    }

    .table-card {
        padding: 20px;
    }

    .table-title {
        font-size: 20px;
    }

    .modern-table thead th,
    .modern-table tbody td {
        padding: 16px 12px;
    }

    .header-content {
        flex-direction: column;
        gap: 12px;
        text-align: center;
    }

    .user-menu {
        flex-direction: column;
        gap: 8px;
    }

    .container {
        padding: 0 16px;
    }
}

@media (max-width: 480px) {
    .dashboard-main {
        padding: 20px 0;
    }

    .card {
        padding: 16px;
    }

    .welcome-card h2 {
        font-size: 24px;
    }

    .table-card {
        padding: 16px;
    }

    .modern-table {
        min-width: 600px;
    }
}
</style>