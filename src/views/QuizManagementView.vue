<template>
    <div class="quiz-management-wrap">
        <!-- Loading Spinner -->
        <div v-if="loading" class="loading-overlay">
            <div class="spinner"></div>
            <p>Memuat data...</p>
        </div>

        <!-- Header -->
        <header class="quiz-header">
            <div class="container">
                <div class="header-content">
                    <h1>Manajemen Kuis</h1>
                    <div class="header-actions">
                        <router-link to="/dashboard" class="btn btn-secondary">
                            <span class="btn-icon">←</span>
                            Kembali
                        </router-link>
                        <button @click="showAddModal = true" class="btn btn-primary" :disabled="loading">
                            <span class="btn-icon">+</span>
                            Tambah Paket Kuis
                        </button>
                    </div>
                </div>
            </div>
        </header>

        <!-- Main Content -->
        <main class="quiz-main">
            <div class="container">
                <!-- Error Message -->
                <div v-if="error" class="error-message">
                    <p>{{ error }}</p>
                    <button @click="loadQuizzes" class="btn btn-secondary">Coba Lagi</button>
                </div>

                <!-- Quiz Packages Grid -->
                <div v-if="!loading && !error" class="quiz-grid">
                    <div v-for="quiz in quizzes" :key="quiz.id" class="quiz-card" @click="startQuiz(quiz)">
                        <div class="quiz-header">
                            <div class="quiz-icon">📚</div>
                            <div class="quiz-actions">
                                <button @click.stop="editQuiz(quiz)" class="action-btn edit" :disabled="actionLoading">
                                    <span>✏️</span>
                                </button>
                                <button @click.stop="deleteQuiz(quiz.id)" class="action-btn delete"
                                    :disabled="actionLoading">
                                    <span>🗑️</span>
                                </button>
                            </div>
                        </div>

                        <h3>{{ quiz.title }}</h3>
                        <p class="quiz-description">{{ quiz.description }}</p>

                        <div class="quiz-stats">
                            <div class="stat">
                                <span class="stat-label">Total Soal</span>
                                <span class="stat-value">{{ quiz.total_questions }}</span>
                            </div>
                            <div class="stat">
                                <span class="stat-label">Fakta</span>
                                <span class="stat-value">{{ getFactCount(quiz) }}</span>
                            </div>
                            <div class="stat">
                                <span class="stat-label">Bukan Fakta</span>
                                <span class="stat-value">{{ getNonFactCount(quiz) }}</span>
                            </div>
                        </div>

                        <div class="quiz-footer">
                            <span class="quiz-date">
                                Dibuat: {{ formatDate(quiz.created_at) }}
                            </span>
                            <button class="btn-play">
                                Mulai →
                            </button>
                        </div>
                    </div>
                </div>

                <!-- Empty State -->
                <div v-if="!loading && !error && quizzes.length === 0" class="empty-state">
                    <div class="empty-icon">📝</div>
                    <h3>Belum Ada Paket Kuis</h3>
                    <p>Mulai dengan menambahkan paket kuis pertama Anda</p>
                    <button @click="showAddModal = true" class="btn btn-primary">
                        Tambah Paket Kuis
                    </button>
                </div>
            </div>
        </main>

        <!-- Add/Edit Quiz Modal -->
        <div v-if="showAddModal || editingQuiz" class="modal-overlay" @click="closeModal">
            <div class="modal-content" @click.stop>
                <div class="modal-header">
                    <h2>{{ editingQuiz ? 'Edit Paket Kuis' : 'Tambah Paket Kuis Baru' }}</h2>
                    <button @click="closeModal" class="close-btn">×</button>
                </div>

                <form @submit.prevent="saveQuiz" class="quiz-form">
                    <div class="form-group">
                        <label for="title">Judul Kuis</label>
                        <input type="text" id="title" v-model="formData.title" placeholder="Masukkan judul kuis"
                            required :disabled="saving" />
                    </div>

                    <div class="form-group">
                        <label for="description">Deskripsi</label>
                        <textarea id="description" v-model="formData.description" placeholder="Masukkan deskripsi kuis"
                            rows="4" required :disabled="saving"></textarea>
                    </div>

                    <div class="form-row">
                        <div class="form-group">
                            <label for="total-questions">Total Soal</label>
                            <input type="number" id="total-questions" v-model="formData.total_questions" min="5"
                                max="50" required :disabled="saving" />
                        </div>

                        <div class="form-group">
                            <label for="fact-percentage">Persentase Fakta (%)</label>
                            <input type="number" id="fact-percentage" v-model="formData.fact_percentage" min="10"
                                max="90" required :disabled="saving" />
                        </div>
                    </div>

                    <div class="form-preview">
                        <h4>Preview Distribusi:</h4>
                        <div class="distribution-preview">
                            <div class="dist-item fact">
                                <span class="dist-label">Fakta:</span>
                                <span class="dist-count">{{ getPreviewFactCount() }} soal</span>
                            </div>
                            <div class="dist-item non-fact">
                                <span class="dist-label">Bukan Fakta:</span>
                                <span class="dist-count">{{ getPreviewNonFactCount() }} soal</span>
                            </div>
                        </div>
                    </div>

                    <div class="form-actions">
                        <button type="button" @click="closeModal" class="btn btn-secondary" :disabled="saving">
                            Batal
                        </button>
                        <button type="submit" class="btn btn-primary" :disabled="saving">
                            <span v-if="saving" class="spinner-sm"></span>
                            {{ saving ? 'Menyimpan...' : (editingQuiz ? 'Update' : 'Simpan') }}
                        </button>
                    </div>
                </form>
            </div>
        </div>
    </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import axios from 'axios'

const router = useRouter()

// API Base URL
const API_BASE_URL = 'http://localhost:3000/quiz'

interface Quiz {
    id: number
    title: string
    description: string
    question_statuses: { status: string }[]
    total_questions: number
    created_at: string
    updated_at: string
}

// Reactive state
const quizzes = ref<Quiz[]>([])
const showAddModal = ref(false)
const editingQuiz = ref<Quiz | null>(null)
const loading = ref(false)
const saving = ref(false)
const actionLoading = ref(false)
const error = ref<string | null>(null)

const formData = ref({
    title: '',
    description: '',
    total_questions: 10,
    fact_percentage: 50
})

// Axios instance with default config
const api = axios.create({
    baseURL: API_BASE_URL,
    timeout: 10000,
    headers: {
        'Content-Type': 'application/json'
    }
})

// Request interceptor for adding auth token if needed
api.interceptors.request.use(
    (config) => {
        // Add auth token if available
        const token = localStorage.getItem('auth_token')
        if (token) {
            config.headers.Authorization = `Bearer ${token}`
        }
        return config
    },
    (error) => {
        return Promise.reject(error)
    }
)

// Response interceptor for error handling
api.interceptors.response.use(
    (response) => response,
    (error) => {
        console.error('API Error:', error)

        if (error.response?.status === 401) {
            // Handle unauthorized access
            router.push('/login')
        }

        return Promise.reject(error)
    }
)

onMounted(() => {
    loadQuizzes()
})

// Load quizzes from API
const loadQuizzes = async () => {
    loading.value = true
    error.value = null

    try {
        const response = await api.get('/get-quizez')
        quizzes.value = response.data.data || response.data

        // If no quizzes exist, initialize with default quiz
        if (quizzes.value.length === 0) {
            await initializeDefaultQuiz()
        }
    } catch (err: any) {
        console.error('Failed to load quizzes:', err)
        error.value = err.response?.data?.message || 'Gagal memuat data kuis. Silakan coba lagi.'

        // Fallback to localStorage if API fails
        loadFromLocalStorage()
    } finally {
        loading.value = false
    }
}

// Fallback: Load from localStorage
const loadFromLocalStorage = () => {
    const saved = localStorage.getItem('quiz_packages')
    if (saved) {
        try {
            quizzes.value = JSON.parse(saved)
        } catch (e) {
            console.error('Failed to load from localStorage:', e)
        }
    }
}

// Initialize default quiz
const initializeDefaultQuiz = async () => {
    const defaultQuiz = {
        title: 'Quiz Patriotisme',
        description: 'Ini adalah quiz patriotisme yang dirancang untuk menguji pengetahuan, pemahaman, dan rasa cinta tanah air para peserta. Melalui soal-soal yang telah disusun, kuis ini tidak hanya mengingatkan kita pada peristiwa sejarah penting, tetapi juga membantu merefleksikan nilai-nilai perjuangan dan pengorbanan para pahlawan bangsa.',
        total_questions: 10,
        fact_percentage: 50
    }

    try {
        await createQuiz(defaultQuiz)
    } catch (err) {
        console.error('Failed to create default quiz:', err)
    }
}

// Generate question statuses
const generateQuestionStatuses = (totalQuestions: number, factPercentage: number) => {
    const factCount = Math.round((totalQuestions * factPercentage) / 100)
    const statuses = []

    // Add fact statuses
    for (let i = 0; i < factCount; i++) {
        statuses.push({ status: 'fakta' })
    }

    // Add non-fact statuses
    for (let i = factCount; i < totalQuestions; i++) {
        statuses.push({ status: 'bukan_fakta' })
    }

    // Shuffle randomly
    for (let i = statuses.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [statuses[i], statuses[j]] = [statuses[j], statuses[i]]
    }

    return statuses
}

// Create new quiz
const createQuiz = async (quizData: any) => {
    const questionStatuses = generateQuestionStatuses(
        quizData.total_questions,
        quizData.fact_percentage || 50
    )

    const payload = {
        title: quizData.title,
        description: quizData.description,
        total_questions: quizData.total_questions,
        question_statuses: questionStatuses
    }

    const response = await api.post('/create-quizez', payload)
    return response.data
}

// Update quiz
const updateQuiz = async (id: number, quizData: any) => {
    const questionStatuses = generateQuestionStatuses(
        quizData.total_questions,
        quizData.fact_percentage
    )

    const payload = {
        title: quizData.title,
        description: quizData.description,
        total_questions: quizData.total_questions,
        question_statuses: questionStatuses
    }

    const response = await api.put(`/update-quizez/${id}`, { ...payload })
    return response.data
}

// Get quiz by ID
const getQuizById = async (id: number) => {
    const response = await api.get(`/get-quizez/${id}`)
    return response.data
}

// Helper functions
const getFactCount = (quiz: Quiz) => {
    return quiz.question_statuses?.filter(q => q.status === 'fakta').length || 0
}

const getNonFactCount = (quiz: Quiz) => {
    return quiz.question_statuses?.filter(q => q.status === 'bukan_fakta').length || 0
}

const getPreviewFactCount = () => {
    return Math.round((formData.value.total_questions * formData.value.fact_percentage) / 100)
}

const getPreviewNonFactCount = () => {
    return formData.value.total_questions - getPreviewFactCount()
}

const formatDate = (dateString: string) => {
    return new Intl.DateTimeFormat('id-ID', {
        day: 'numeric',
        month: 'short',
        year: 'numeric'
    }).format(new Date(dateString))
}

// Actions
const startQuiz = async (quiz: Quiz) => {
    try {
        
        // Get full quiz data if needed
        const fullQuiz = await getQuizById(quiz.id)
        localStorage.setItem('selected_quiz', JSON.stringify(fullQuiz.data || fullQuiz))
        router.push('/intro')
    } catch (err) {
        console.error('Failed to load quiz details:', err)
        // Fallback: use current quiz data
        localStorage.setItem('selected_quiz', JSON.stringify(quiz))
        router.push('/intro')
    }
}

const editQuiz = (quiz: Quiz) => {
    editingQuiz.value = quiz
    formData.value = {
        title: quiz.title,
        description: quiz.description,
        total_questions: quiz.total_questions,
        fact_percentage: Math.round((getFactCount(quiz) / quiz.total_questions) * 100) || 50
    }
}

const deleteQuiz = async (id: number) => {
    if (!confirm('Yakin ingin menghapus paket kuis ini?')) {
        return
    }

    actionLoading.value = true

    try {
        await api.delete(`/delete-quizez/${id}`)

        // Remove from local state
        quizzes.value = quizzes.value.filter(q => q.id !== id)

        // Update localStorage backup
        localStorage.setItem('quiz_packages', JSON.stringify(quizzes.value))

    } catch (err: any) {
        console.error('Failed to delete quiz:', err)
        alert(err.response?.data?.message || 'Gagal menghapus kuis. Silakan coba lagi.')
    } finally {
        actionLoading.value = false
    }
}

const saveQuiz = async () => {
    saving.value = true

    try {
        let savedQuiz

        if (editingQuiz.value) {
            // Update existing quiz
            savedQuiz = await updateQuiz(editingQuiz.value.id, formData.value)

            // Update local state
            const index = quizzes.value.findIndex(q => q.id === editingQuiz.value!.id)
            if (index !== -1) {
                quizzes.value[index] = savedQuiz.data || savedQuiz
            }
        } else {
            // Create new quiz
            savedQuiz = await createQuiz(formData.value)

            // Add to local state
            quizzes.value.push(savedQuiz.data || savedQuiz)
        }

        // Update localStorage backup
        localStorage.setItem('quiz_packages', JSON.stringify(quizzes.value))

        closeModal()

    } catch (err: any) {
        console.error('Failed to save quiz:', err)
        alert(err.response?.data?.message || 'Gagal menyimpan kuis. Silakan coba lagi.')
    } finally {
        saving.value = false
    }
}

const closeModal = () => {
    showAddModal.value = false
    editingQuiz.value = null
    formData.value = {
        title: '',
        description: '',
        total_questions: 10,
        fact_percentage: 50
    }
}
</script>

<style scoped>
.loading-overlay {
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: rgba(255, 255, 255, 0.9);
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    z-index: 1000;
}

.spinner {
    width: 40px;
    height: 40px;
    border: 4px solid #f3f3f3;
    border-top: 4px solid #007bff;
    border-radius: 50%;
    animation: spin 1s linear infinite;
}

.spinner-sm {
    display: inline-block;
    width: 16px;
    height: 16px;
    border: 2px solid transparent;
    border-top: 2px solid currentColor;
    border-radius: 50%;
    animation: spin 1s linear infinite;
    margin-right: 8px;
}

@keyframes spin {
    0% {
        transform: rotate(0deg);
    }

    100% {
        transform: rotate(360deg);
    }
}

.error-message {
    background: #f8d7da;
    color: #721c24;
    padding: 16px;
    border-radius: 8px;
    margin-bottom: 24px;
    text-align: center;
}

.error-message p {
    margin: 0 0 12px 0;
}

/* Existing styles remain the same */
.quiz-management-wrap {
    min-height: 100vh;
    background: #f5f7fa;
}

.quiz-header {
    background: white;
    border-bottom: 1px solid #e5e7eb;
    padding: 16px 0;
}

.container {
    max-width: 1200px;
    margin: 0 auto;
    padding: 0 16px;
}

.header-content {
    display: flex;
    justify-content: space-between;
    align-items: center;
}

.header-content h1 {
    margin: 0;
    color: #1f2937;
    font-size: 24px;
    font-weight: 600;
}

.header-actions {
    display: flex;
    gap: 12px;
}

.btn {
    display: inline-flex;
    align-items: center;
    padding: 8px 16px;
    border-radius: 6px;
    text-decoration: none;
    border: none;
    cursor: pointer;
    font-size: 14px;
    font-weight: 500;
    transition: all 0.2s;
}

.btn:disabled {
    opacity: 0.6;
    cursor: not-allowed;
}

.btn-primary {
    background: #007bff;
    color: white;
}

.btn-primary:hover:not(:disabled) {
    background: #0056b3;
}

.btn-secondary {
    background: #6c757d;
    color: white;
}

.btn-secondary:hover:not(:disabled) {
    background: #545b62;
}

.btn-icon {
    margin-right: 8px;
}

.quiz-main {
    padding: 32px 0;
}

.quiz-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
    gap: 24px;
}

.quiz-card {
    background: white;
    border-radius: 12px;
    padding: 24px;
    box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
    cursor: pointer;
    transition: all 0.2s;
}

.quiz-card:hover {
    transform: translateY(-2px);
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
}

.quiz-card .quiz-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 16px;
    padding: 0;
    background: none;
    border: none;
}

.quiz-icon {
    font-size: 24px;
}

.quiz-actions {
    display: flex;
    gap: 8px;
}

.action-btn {
    background: #f8f9fa;
    border: none;
    border-radius: 6px;
    padding: 8px;
    cursor: pointer;
    transition: all 0.2s;
}

.action-btn:hover:not(:disabled) {
    background: #e9ecef;
}

.action-btn:disabled {
    opacity: 0.5;
    cursor: not-allowed;
}

.quiz-card h3 {
    margin: 0 0 12px 0;
    font-size: 18px;
    font-weight: 600;
    color: #1f2937;
}

.quiz-description {
    color: #6b7280;
    margin: 0 0 20px 0;
    line-height: 1.5;
    display: -webkit-box;
    -webkit-line-clamp: 3;
    -webkit-box-orient: vertical;
    overflow: hidden;
}

.quiz-stats {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 16px;
    margin-bottom: 20px;
}

.stat {
    text-align: center;
}

.stat-label {
    display: block;
    font-size: 12px;
    color: #6b7280;
    margin-bottom: 4px;
}

.stat-value {
    display: block;
    font-size: 20px;
    font-weight: 600;
    color: #1f2937;
}

.quiz-footer {
    display: flex;
    justify-content: space-between;
    align-items: center;
}

.quiz-date {
    font-size: 12px;
    color: #6b7280;
}

.btn-play {
    background: #10b981;
    color: white;
    border: none;
    padding: 8px 16px;
    border-radius: 6px;
    cursor: pointer;
    font-weight: 500;
    transition: all 0.2s;
}

.btn-play:hover {
    background: #059669;
}

.empty-state {
    text-align: center;
    padding: 64px 16px;
}

.empty-icon {
    font-size: 64px;
    margin-bottom: 16px;
}

.empty-state h3 {
    margin: 0 0 8px 0;
    color: #1f2937;
}

.empty-state p {
    margin: 0 0 24px 0;
    color: #6b7280;
}

.modal-overlay {
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: rgba(0, 0, 0, 0.5);
    display: flex;
    align-items: center;
    justify-content: center;
    z-index: 1000;
}

.modal-content {
    background: white;
    border-radius: 12px;
    width: 90%;
    max-width: 500px;
    max-height: 90vh;
    overflow-y: auto;
}

.modal-header {
    padding: 24px 24px 0 24px;
    display: flex;
    justify-content: space-between;
    align-items: center;
}

.modal-header h2 {
    margin: 0;
    color: #1f2937;
}

.close-btn {
    background: none;
    border: none;
    font-size: 24px;
    cursor: pointer;
    color: #6b7280;
}

.quiz-form {
    padding: 24px;
}

.form-group {
    margin-bottom: 20px;
}

.form-group label {
    display: block;
    margin-bottom: 8px;
    font-weight: 500;
    color: #374151;
}

.form-group input,
.form-group textarea {
    width: 100%;
    padding: 12px;
    border: 1px solid #d1d5db;
    border-radius: 6px;
    font-size: 14px;
}

.form-group input:disabled,
.form-group textarea:disabled {
    background: #f9fafb;
    color: #6b7280;
}

.form-row {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 16px;
}

.form-preview {
    background: #f9fafb;
    padding: 16px;
    border-radius: 8px;
    margin-bottom: 20px;
}

.form-preview h4 {
    margin: 0 0 12px 0;
    font-size: 14px;
    color: #374151;
}

.distribution-preview {
    display: flex;
    gap: 16px;
}

.dist-item {
    flex: 1;
}

.dist-label {
    display: block;
    font-size: 12px;
    color: #6b7280;
    margin-bottom: 4px;
}

.dist-count {
    display: block;
    font-size: 16px;
    font-weight: 600;
    color: #1f2937;
}

.form-actions {
    display: flex;
    gap: 12px;
    justify-content: flex-end;
}

@media (max-width: 768px) {
    .header-content {
        flex-direction: column;
        gap: 16px;
        align-items: stretch;
    }

    .header-actions {
        justify-content: center;
    }

    .quiz-grid {
        grid-template-columns: 1fr;
    }

    .form-row {
        grid-template-columns: 1fr;
    }

    .distribution-preview {
        flex-direction: column;
        gap: 8px;
    }

    .form-actions {
        flex-direction: column;
    }
}
</style>