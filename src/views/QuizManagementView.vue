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

                    <div class="form-group">
                        <label for="topic">Topik</label>
                        <input type="text" id="topic" v-model="formData.topic"
                            placeholder="Masukkan topik kuis (misal: Patriotisme, Demokrasi, dll)" required
                            :disabled="saving" />
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
const API_BASE_URL = `${import.meta.env.VITE_BASE_URL_BACKEND}/quiz`

interface Quiz {
    id: number
    title: string
    description: string
    question_statuses: { status: string }[]
    total_questions: number,
    topic: string,
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
    topic: '',        
    total_questions: 10,
    fact_percentage: 50
})


// Axios instance with default config
const api = axios.create({
    baseURL: API_BASE_URL,
    timeout: 30000,
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
        // if (quizzes.value.length === 0) {
        //     await initializeDefaultQuiz()
        // }
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
// const initializeDefaultQuiz = async () => {
//     const defaultQuiz = {
//         title: 'Quiz Patriotisme',
//         description: 'Ini adalah quiz patriotisme yang dirancang untuk menguji pengetahuan, pemahaman, dan rasa cinta tanah air para peserta. Melalui soal-soal yang telah disusun, kuis ini tidak hanya mengingatkan kita pada peristiwa sejarah penting, tetapi juga membantu merefleksikan nilai-nilai perjuangan dan pengorbanan para pahlawan bangsa.',
//         total_questions: 10,
//         fact_percentage: 50
//     }

//     try {
//         await createQuiz(defaultQuiz)
//     } catch (err) {
//         console.error('Failed to create default quiz:', err)
//     }
// }

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
        topic: quizData.topic,  
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
        topic: quizData.topic,   // ➕ kirim topic
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
        topic: quiz.topic || '',   // ➕ load topic
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
        topic: '',          // reset topic juga
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
    width: 14px;
    height: 14px;
    border: 2px solid transparent;
    border-top: 2px solid currentColor;
    border-radius: 50%;
    animation: spin 0.8s linear infinite;
}

@keyframes spin {
    0% {
        transform: rotate(0deg);
    }

    100% {
        transform: rotate(360deg);
    }
}

/* Fade in and slide up animations */
@keyframes fadeIn {
    from {
        opacity: 0;
    }

    to {
        opacity: 1;
    }
}

@keyframes slideUp {
    from {
        opacity: 0;
        transform: translateY(20px) scale(0.95);
    }

    to {
        opacity: 1;
        transform: translateY(0) scale(1);
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

/* Main layout styles */
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
    color: #062244;
    font-size: 24px;
    font-weight: 700;
}

.header-actions {
    display: flex;
    gap: 12px;
}

/* Button Styles - Enhanced */
.btn {
    display: inline-flex;
    align-items: center;
    padding: 12px 20px;
    border-radius: 8px;
    text-decoration: none;
    border: none;
    cursor: pointer;
    font-size: 14px;
    font-weight: 500;
    transition: all 0.2s ease;
    min-width: fit-content;
    justify-content: center;
    gap: 8px;
}

.btn:disabled {
    opacity: 0.6;
    cursor: not-allowed;
}

.btn-primary {
    background: linear-gradient(135deg, #3b82f6 0%, #2563eb 100%);
    color: white;
    box-shadow: 0 2px 4px rgba(59, 130, 246, 0.2);
}

.btn-primary:hover:not(:disabled) {
    background: linear-gradient(135deg, #2563eb 0%, #1d4ed8 100%);
    box-shadow: 0 4px 8px rgba(59, 130, 246, 0.3);
    transform: translateY(-1px);
}

.btn-secondary {
    background: #f9fafb;
    color: #374151;
    border: 1px solid #d1d5db;
}

.btn-secondary:hover:not(:disabled) {
    background: #f3f4f6;
    border-color: #9ca3af;
}

.btn-icon {
    margin-right: 0;
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

/* Modal Styles - Enhanced */
.modal-overlay {
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: rgba(0, 0, 0, 0.6);
    display: flex;
    align-items: center;
    justify-content: center;
    z-index: 1000;
    backdrop-filter: blur(4px);
    animation: fadeIn 0.2s ease-out;
}

.modal-content {
    background: white;
    border-radius: 16px;
    width: 90%;
    max-width: 520px;
    max-height: 85vh;
    overflow: hidden;
    box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25);
    animation: slideUp 0.3s ease-out;
}

.modal-header {
    padding: 24px 24px 16px 24px;
    display: flex;
    justify-content: space-between;
    align-items: center;
    border-bottom: 1px solid #f3f4f6;
}

.modal-header h2 {
    margin: 0;
    color: #111827;
    font-size: 20px;
    font-weight: 600;
}

.close-btn {
    background: none;
    border: none;
    font-size: 24px;
    cursor: pointer;
    color: #6b7280;
    width: 32px;
    height: 32px;
    display: flex;
    align-items: center;
    justify-content: center;
    border-radius: 6px;
    transition: all 0.2s ease;
}

.close-btn:hover {
    background-color: #f3f4f6;
    color: #374151;
}

.quiz-form {
    padding: 24px;
    max-height: calc(85vh - 100px);
    overflow-y: auto;
}

/* Custom scrollbar for form */
.quiz-form::-webkit-scrollbar {
    width: 6px;
}

.quiz-form::-webkit-scrollbar-track {
    background: #f1f5f9;
    border-radius: 3px;
}

.quiz-form::-webkit-scrollbar-thumb {
    background: #cbd5e1;
    border-radius: 3px;
}

.quiz-form::-webkit-scrollbar-thumb:hover {
    background: #94a3b8;
}

.form-group {
    margin-bottom: 20px;
}

.form-group label {
    display: block;
    margin-bottom: 8px;
    font-weight: 500;
    color: #374151;
    font-size: 14px;
}

.form-group input,
.form-group textarea {
    width: 100%;
    padding: 12px 16px;
    border: 1px solid #d1d5db;
    border-radius: 8px;
    font-size: 14px;
    transition: all 0.2s ease;
    font-family: inherit;
    box-sizing: border-box;
}

.form-group input:focus,
.form-group textarea:focus {
    outline: none;
    border-color: #3b82f6;
    box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1);
}

.form-group input:disabled,
.form-group textarea:disabled {
    background: #f9fafb;
    color: #6b7280;
    cursor: not-allowed;
}

.form-group textarea {
    resize: vertical;
    min-height: 100px;
}

.form-row {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 20px;
    margin-bottom: 20px;
}

/* Enhanced Preview Styles */
.form-preview {
    background: linear-gradient(135deg, #f8fafc 0%, #f1f5f9 100%);
    border: 1px solid #e2e8f0;
    padding: 20px;
    border-radius: 12px;
    margin-bottom: 24px;
}

.form-preview h4 {
    margin: 0 0 16px 0;
    font-size: 15px;
    font-weight: 600;
    color: #374151;
}

.distribution-preview {
    display: flex;
    gap: 16px;
    flex-wrap: wrap;
}

.dist-item {
    flex: 1;
    min-width: 120px;
    padding: 12px 16px;
    border-radius: 8px;
    display: flex;
    flex-direction: column;
    align-items: center;
    text-align: center;
    transition: all 0.2s ease;
}

.dist-item.fact {
    background: linear-gradient(135deg, #dbeafe 0%, #bfdbfe 100%);
    border: 1px solid #93c5fd;
}

.dist-item.non-fact {
    background: linear-gradient(135deg, #fef3c7 0%, #fde68a 100%);
    border: 1px solid #f59e0b;
}

.dist-label {
    font-size: 12px;
    font-weight: 500;
    color: #6b7280;
    text-transform: uppercase;
    letter-spacing: 0.5px;
    margin-bottom: 4px;
}

.dist-count {
    font-size: 16px;
    font-weight: 600;
    color: #111827;
}

.form-actions {
    display: flex;
    justify-content: flex-end;
    gap: 12px;
    margin-top: 24px;
    padding-top: 24px;
    border-top: 1px solid #f3f4f6;
}

/* Responsive Design */
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
        gap: 12px;
    }

    .form-actions {
        flex-direction: column-reverse;
    }

    .btn {
        width: 100%;
    }
}

@media (max-width: 640px) {
    .modal-content {
        width: 95%;
        margin: 20px;
        max-height: 90vh;
    }

    .modal-header {
        padding: 20px 20px 12px 20px;
    }

    .modal-header h2 {
        font-size: 18px;
    }

    .quiz-form {
        padding: 20px;
    }
}

@media (max-width: 480px) {
    .form-row {
        grid-template-columns: 1fr;
        gap: 16px;
    }
}
</style>