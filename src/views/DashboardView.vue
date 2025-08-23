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

                    <!-- Stats Cards -->
                    <!-- <div class="card stats-card">
                        <div class="card-icon">📊</div>
                        <h3>Total Kuis</h3>
                        <div class="stat-number">{{ stats.totalQuiz }}</div>
                        <p>Kuis telah diselesaikan</p>
                    </div>

                    <div class="card stats-card">
                        <div class="card-icon">⭐</div>
                        <h3>Skor Tertinggi</h3>
                        <div class="stat-number">{{ stats.highScore }}%</div>
                        <p>Pencapaian terbaik Anda</p>
                    </div>

                    <div class="card stats-card">
                        <div class="card-icon">🏆</div>
                        <h3>Rata-rata</h3>
                        <div class="stat-number">{{ stats.avgScore }}%</div>
                        <p>Skor rata-rata</p>
                    </div> -->

                    <!-- Recent Activity -->
                    <!-- <div class="card activity-card">
                        <h3><span class="card-icon">📝</span> Aktivitas Terakhir</h3>
                        <div class="activity-list">
                            <div v-if="activities.length === 0" class="empty-state">
                                <p>Belum ada aktivitas. Mulai kuis pertama Anda!</p>
                            </div>
                            <div v-else class="activity-item" v-for="activity in activities" :key="activity.id">
                                <div class="activity-info">
                                    <span class="activity-title">{{ activity.title }}</span>
                                    <span class="activity-date">{{ formatDate(activity.date) }}</span>
                                </div>
                                <div class="activity-score" :class="getScoreClass(activity.score)">
                                    {{ activity.score }}%
                                </div>
                            </div>
                        </div>
                    </div> -->

                    <!-- Quick Actions -->
                    <!-- <div class="card actions-card">
                        <h3><span class="card-icon">⚡</span> Aksi Cepat</h3>
                        <div class="actions-grid">
                            <router-link to="/intro" class="action-btn">
                                <span class="action-icon">🚀</span>
                                <span>Mulai Kuis Baru</span>
                            </router-link>
                            <button @click="viewResults" class="action-btn" :disabled="!hasResults">
                                <span class="action-icon">📈</span>
                                <span>Lihat Hasil</span>
                            </button>
                            <button @click="resetStats" class="action-btn secondary">
                                <span class="action-icon">🔄</span>
                                <span>Reset Statistik</span>
                            </button>
                        </div>
                    </div> -->
                </div>
            </div>
        </main>
    </div>
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useRouter } from 'vue-router'

const router = useRouter()

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

const hasResults = computed(() => activities.value.length > 0)

onMounted(() => {
    loadUserData()
    loadStats()
    loadActivities()
})

const loadUserData = () => {
    // Try to get user info from localStorage or API
    const savedEmail = localStorage.getItem('quiz_demo_email')
    if (savedEmail) {
        userName.value = savedEmail.split('@')[0]
    }
}

const loadStats = () => {
    // Load stats from localStorage (in real app, this would be from API)
    const savedStats = localStorage.getItem('quiz_stats')
    if (savedStats) {
        try {
            stats.value = JSON.parse(savedStats)
        } catch (e) {
            console.error('Failed to load stats:', e)
        }
    }
}

const loadActivities = () => {
    // Load activities from localStorage (in real app, this would be from API)
    const savedActivities = localStorage.getItem('quiz_activities')
    if (savedActivities) {
        try {
            const parsed = JSON.parse(savedActivities)
            activities.value = parsed.map((activity: any) => ({
                ...activity,
                date: new Date(activity.date)
            }))
        } catch (e) {
            console.error('Failed to load activities:', e)
        }
    }
}

const formatDate = (date: Date): string => {
    return new Intl.DateTimeFormat('id-ID', {
        day: 'numeric',
        month: 'short',
        hour: '2-digit',
        minute: '2-digit'
    }).format(date)
}

const getScoreClass = (score: number): string => {
    if (score >= 80) return 'score-excellent'
    if (score >= 60) return 'score-good'
    return 'score-poor'
}

const viewResults = () => {
    if (hasResults.value) {
        router.push('/result')
    }
}

const resetStats = () => {
    if (confirm('Yakin ingin mereset semua statistik? Tindakan ini tidak dapat dibatalkan.')) {
        stats.value = { totalQuiz: 0, highScore: 0, avgScore: 0 }
        activities.value = []
        localStorage.removeItem('quiz_stats')
        localStorage.removeItem('quiz_activities')
        localStorage.removeItem('quiz_results')
    }
}

const handleLogout = () => {
    localStorage.removeItem('quiz_token')
    localStorage.removeItem('quiz_demo_email')
    router.push('/').catch(() => { })
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

.stats-card {
    text-align: center;
}

.stats-card h3 {
    margin: 0 0 8px;
    color: #334155;
    font-size: 16px;
}

.stat-number {
    font-size: 2.5em;
    font-weight: 800;
    color: #3b82f6;
    margin: 8px 0;
}

.stats-card p {
    margin: 0;
    color: #6b7280;
    font-size: 14px;
}

.activity-card {
    grid-column: span 2;
}

.activity-card h3 {
    margin: 0 0 20px;
    color: #334155;
    font-size: 18px;
    display: flex;
    align-items: center;
    gap: 8px;
}

.activity-list {
    display: flex;
    flex-direction: column;
    gap: 12px;
}

.empty-state {
    text-align: center;
    padding: 40px 20px;
    color: #6b7280;
}

.activity-item {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 16px;
    background: rgba(249, 250, 251, 0.8);
    border-radius: 12px;
    border: 1px solid rgba(6, 34, 68, 0.04);
}

.activity-info {
    display: flex;
    flex-direction: column;
    gap: 4px;
}

.activity-title {
    font-weight: 600;
    color: #334155;
}

.activity-date {
    font-size: 13px;
    color: #6b7280;
}

.activity-score {
    font-weight: 700;
    font-size: 16px;
    padding: 4px 12px;
    border-radius: 20px;
}

.score-excellent {
    background: rgba(34, 197, 94, 0.1);
    color: #16a34a;
}

.score-good {
    background: rgba(251, 191, 36, 0.1);
    color: #d97706;
}

.score-poor {
    background: rgba(220, 38, 38, 0.1);
    color: #dc2626;
}

.actions-card h3 {
    margin: 0 0 20px;
    color: #334155;
    font-size: 18px;
    display: flex;
    align-items: center;
    gap: 8px;
}

.actions-grid {
    display: grid;
    gap: 12px;
}

.action-btn {
    display: flex;
    align-items: center;
    gap: 12px;
    padding: 16px;
    border-radius: 12px;
    border: 1px solid rgba(6, 34, 68, 0.08);
    background: rgba(249, 250, 251, 0.8);
    color: #334155;
    text-decoration: none;
    font-weight: 600;
    cursor: pointer;
    transition: all 140ms;
}

.action-btn:hover:not(:disabled) {
    background: #f3f4f6;
    transform: translateY(-1px);
}

.action-btn:disabled {
    opacity: 0.5;
    cursor: not-allowed;
}

.action-btn.secondary {
    background: rgba(220, 38, 38, 0.05);
    border-color: rgba(220, 38, 38, 0.2);
    color: #dc2626;
}

.action-btn.secondary:hover:not(:disabled) {
    background: rgba(220, 38, 38, 0.1);
}

.action-icon {
    font-size: 1.2em;
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

/* Responsive */
@media (max-width: 768px) {
    .dashboard-grid {
        grid-template-columns: 1fr;
    }

    .welcome-card,
    .activity-card {
        grid-column: span 1;
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

    .stat-number {
        font-size: 2em;
    }
}
</style>