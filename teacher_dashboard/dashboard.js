// =============================================
// SUPABASE CONFIGURATION
// =============================================
const SUPABASE_URL = 'https://hftjoljlsrneyrmiwgyc.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhmdGpvbGpsc3JuZXlybWl3Z3ljIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQ5Njk2ODcsImV4cCI6MjEwMDU0NTY4N30.0iIVhiLezLs_ZW8qwbgbFe3fP2NRmxCNJ9uBvVVodw4';

let supabase;
let currentTeacher = null;

// =============================================
// INITIALIZE
// =============================================
function initSupabase() {
    console.log('🔧 Initializing Supabase...');
    supabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
    console.log('✅ Supabase initialized');
}

// =============================================
// AUTHENTICATION
// =============================================
async function login() {
    const email = document.getElementById('email').value.trim();
    const password = document.getElementById('password').value;

    console.log('🔑 Attempting login with:', email);

    if (!email || !password) {
        alert('⚠️ Please enter both email and password');
        return;
    }

    const loginBtn = document.querySelector('.login-form button');
    loginBtn.textContent = 'Logging in...';
    loginBtn.disabled = true;

    try {
        const { data, error } = await supabase.auth.signInWithPassword({
            email: email,
            password: password,
        });

        if (error) {
            console.error('❌ Login error:', error);
            alert('❌ Login failed: ' + error.message);
            loginBtn.textContent = 'Login';
            loginBtn.disabled = false;
            return;
        }

        if (!data.user) {
            alert('❌ No user data returned');
            loginBtn.textContent = 'Login';
            loginBtn.disabled = false;
            return;
        }

        console.log('✅ Login successful:', data.user.email);
        currentTeacher = data.user;
        document.getElementById('teacherName').textContent = currentTeacher.email;
        
        showScreen('dashboardScreen');
        loadDashboard();
    } catch (error) {
        console.error('❌ Unexpected error:', error);
        alert('❌ Login failed: ' + error.message);
        loginBtn.textContent = 'Login';
        loginBtn.disabled = false;
    }
}

async function logout() {
    console.log('🚪 Logging out...');
    const { error } = await supabase.auth.signOut();
    if (error) {
        console.error('❌ Logout error:', error);
    }
    currentTeacher = null;
    showScreen('loginScreen');
    console.log('✅ Logged out');
}

// =============================================
// SCREEN MANAGEMENT
// =============================================
function showScreen(screenId) {
    document.querySelectorAll('.screen').forEach(s => {
        s.classList.remove('active');
        s.style.display = 'none';
    });
    
    const screen = document.getElementById(screenId);
    screen.classList.add('active');
    screen.style.display = screenId === 'loginScreen' ? 'flex' : 'block';
}

// =============================================
// DASHBOARD DATA
// =============================================
async function loadDashboard() {
    console.log('📊 Loading dashboard...');
    await Promise.all([
        loadStats(),
        loadStudents(),
        loadPacks(),
    ]);
    console.log('✅ Dashboard loaded');
}

// Load overview stats
async function loadStats() {
    try {
        console.log('📈 Loading stats...');
        
        // Get all students
        const { data: students, error: studentError } = await supabase
            .from('students')
            .select('*');

        if (studentError) {
            console.error('❌ Students error:', studentError);
            throw studentError;
        }

        // Get all progress events
        const { data: events, error: eventError } = await supabase
            .from('progress_events')
            .select('*');

        if (eventError) {
            console.error('❌ Events error:', eventError);
            throw eventError;
        }

        console.log(`👨‍🎓 Students: ${students?.length || 0}`);
        console.log(`📝 Events: ${events?.length || 0}`);

        // Calculate stats
        const totalStudents = students?.length || 0;
        const lessonEvents = events?.filter(e => e.event_type === 'lesson_completed') || [];
        const quizEvents = events?.filter(e => e.event_type === 'quiz_submitted') || [];
        
        let totalScore = 0;
        let scoreCount = 0;
        quizEvents.forEach(e => {
            const score = e.payload?.quizScore;
            if (score !== undefined && score !== null) {
                totalScore += score;
                scoreCount++;
            }
        });
        
        const avgScore = scoreCount > 0 ? Math.round((totalScore / (scoreCount * 5)) * 100) : 0;

        document.getElementById('totalStudents').textContent = totalStudents;
        document.getElementById('totalLessons').textContent = lessonEvents.length;
        document.getElementById('totalQuizzes').textContent = quizEvents.length;
        document.getElementById('avgScore').textContent = avgScore + '%';
        
        console.log('✅ Stats loaded');
    } catch (error) {
        console.error('❌ Failed to load stats:', error);
    }
}

// Load student list
async function loadStudents() {
    try {
        console.log('👨‍🎓 Loading students...');
        
        const { data: students, error } = await supabase
            .from('students')
            .select('*')
            .order('created_at', { ascending: false });

        if (error) throw error;

        const { data: events } = await supabase
            .from('progress_events')
            .select('*');

        const studentList = document.getElementById('studentList');
        
        if (!students || students.length === 0) {
            studentList.innerHTML = '<p class="loading">📭 No students found. Students will appear here after they sync from the app.</p>';
            return;
        }

        console.log(`Found ${students.length} students`);

        studentList.innerHTML = students.map(student => {
            const studentEvents = events?.filter(e => e.student_id === student.id) || [];
            const lessonsCompleted = studentEvents.filter(e => e.event_type === 'lesson_completed').length;
            const quizzesTaken = studentEvents.filter(e => e.event_type === 'quiz_submitted').length;
            const lastSynced = student.last_synced_at 
                ? new Date(student.last_synced_at).toLocaleDateString('en-IN') 
                : 'Never';

            return `
                <div class="student-row" onclick="showStudentDetail('${student.id}')">
                    <div>
                        <div class="student-name">👤 ${student.name}</div>
                        <div class="student-class">📚 Class: ${student.class_code || 'N/A'} | 🕐 Last synced: ${lastSynced}</div>
                    </div>
                    <div class="student-stats">
                        <span class="stat-badge green">📖 ${lessonsCompleted} lessons</span>
                        <span class="stat-badge orange">📝 ${quizzesTaken} quizzes</span>
                    </div>
                </div>
            `;
        }).join('');
        
        console.log('✅ Students loaded');
    } catch (error) {
        console.error('❌ Failed to load students:', error);
        document.getElementById('studentList').innerHTML = '<p class="loading">❌ Failed to load students: ' + error.message + '</p>';
    }
}

// Show student detail
async function showStudentDetail(studentId) {
    console.log('🔍 Loading detail for student:', studentId);
    
    try {
        const { data: student, error: studentError } = await supabase
            .from('students')
            .select('*')
            .eq('id', studentId)
            .single();

        if (studentError) throw studentError;

        const { data: events, error: eventError } = await supabase
            .from('progress_events')
            .select('*')
            .eq('student_id', studentId)
            .order('client_created_at', { ascending: false });

        if (eventError) throw eventError;

        const detailPanel = document.getElementById('studentDetail');
        const detailContent = document.getElementById('detailContent');
        
        document.getElementById('detailTitle').textContent = `📊 ${student.name}'s Progress`;

        const lessonEvents = events?.filter(e => e.event_type === 'lesson_completed') || [];
        const quizEvents = events?.filter(e => e.event_type === 'quiz_submitted') || [];

        // Subject progress
        const subjects = {
            'Mathematics': { icon: '📐', completed: 0, total: 3, color: '#2196F3' },
            'Science': { icon: '🔬', completed: 0, total: 3, color: '#4CAF50' },
            'English': { icon: '📖', completed: 0, total: 3, color: '#9C27B0' },
            'History': { icon: '🏛️', completed: 0, total: 3, color: '#FF9800' },
        };

        lessonEvents.forEach(e => {
            if (e.lesson_id?.startsWith('math_')) subjects['Mathematics'].completed++;
            if (e.lesson_id?.startsWith('sci_')) subjects['Science'].completed++;
            if (e.lesson_id?.startsWith('eng_')) subjects['English'].completed++;
            if (e.lesson_id?.startsWith('his_')) subjects['History'].completed++;
        });

        const progressBars = Object.entries(subjects).map(([name, data]) => {
            const percent = Math.round((data.completed / data.total) * 100);
            return `
                <div class="progress-bar-container">
                    <div class="progress-label">
                        <span>${data.icon} ${name}</span>
                        <span>${data.completed}/${data.total}</span>
                    </div>
                    <div class="progress-bar">
                        <div class="progress-fill" style="width: ${percent}%; background: ${data.color}"></div>
                    </div>
                </div>
            `;
        }).join('');

        // Quiz scores
        const quizList = quizEvents.length > 0 
            ? quizEvents.slice(0, 5).map(e => {
                const score = e.payload?.quizScore ?? 0;
                const lessonName = getLessonName(e.lesson_id);
                const date = new Date(e.client_created_at).toLocaleDateString('en-IN');
                const percentage = Math.round((score / 5) * 100);
                return `
                    <div class="quiz-item">
                        <span>📝 ${lessonName}</span>
                        <span style="color: #2e7d32; font-weight: bold;">${score}/5 (${percentage}%)</span>
                        <span style="color: #999; font-size: 11px;">${date}</span>
                    </div>
                `;
            }).join('')
            : '<p style="color: #999; padding: 10px;">No quizzes taken yet</p>';

        detailContent.innerHTML = `
            <div class="detail-section">
                <h3>📚 Subject Progress</h3>
                ${progressBars}
            </div>
            <div class="detail-section">
                <h3>📝 Recent Quiz Scores</h3>
                ${quizList}
            </div>
            <div class="detail-section">
                <p style="font-size: 12px; color: #999; background: #f5f5f5; padding: 10px; border-radius: 8px;">
                    📖 Total Lessons Completed: <b>${lessonEvents.length}</b> | 
                    📝 Total Quizzes Taken: <b>${quizEvents.length}</b><br>
                    🕐 Last Active: <b>${student.last_synced_at ? new Date(student.last_synced_at).toLocaleDateString('en-IN') : 'Never'}</b>
                </p>
            </div>
        `;

        detailPanel.style.display = 'block';
        detailPanel.scrollIntoView({ behavior: 'smooth' });
        console.log('✅ Student detail loaded');
    } catch (error) {
        console.error('❌ Failed to load student detail:', error);
        alert('Failed to load student details: ' + error.message);
    }
}

function closeDetail() {
    document.getElementById('studentDetail').style.display = 'none';
}

// Load lesson packs
async function loadPacks() {
    try {
        console.log('📦 Loading packs...');
        
        const { data: files, error } = await supabase
            .storage
            .from('lesson-packs')
            .list();

        if (error) {
            console.error('❌ Packs error:', error);
            throw error;
        }

        const packList = document.getElementById('packList');
        
        if (!files || files.length === 0) {
            packList.innerHTML = '<p class="loading">📭 No lesson packs uploaded yet</p>';
            return;
        }

        console.log(`Found ${files.length} packs`);

        packList.innerHTML = files.map(file => {
            const name = file.name.replace('_grade5.json', '');
            const sizeKB = file.metadata?.size ? (file.metadata.size / 1024).toFixed(1) : '?';
            return `
                <div class="pack-row">
                    <div class="pack-info">
                        <h4>📦 ${name.charAt(0).toUpperCase() + name.slice(1)}</h4>
                        <p>Size: ${sizeKB} KB | Updated: ${new Date(file.updated_at || file.created_at).toLocaleDateString('en-IN')}</p>
                    </div>
                    <div class="pack-actions">
                        <button onclick="window.open('${SUPABASE_URL}/storage/v1/object/public/lesson-packs/${file.name}', '_blank')">📥 View</button>
                    </div>
                </div>
            `;
        }).join('');
        
        console.log('✅ Packs loaded');
    } catch (error) {
        console.error('❌ Failed to load packs:', error);
        document.getElementById('packList').innerHTML = '<p class="loading">❌ Failed to load packs. Make sure the "lesson-packs" bucket exists.</p>';
    }
}

// Filter students
function filterStudents() {
    const search = document.getElementById('searchInput')?.value?.toLowerCase() || '';
    const rows = document.querySelectorAll('.student-row');
    rows.forEach(row => {
        const name = row.querySelector('.student-name')?.textContent?.toLowerCase() || '';
        row.style.display = name.includes(search) ? '' : 'none';
    });
}

// Refresh packs
function refreshPacks() {
    loadPacks();
}

// Helper functions
function getLessonName(lessonId) {
    const names = {
        'math_1': 'Intro to Fractions',
        'math_2': 'Adding Fractions',
        'math_3': 'Fractions in Daily Life',
        'sci_1': 'Parts of a Plant',
        'sci_2': 'Animals Classification',
        'sci_3': 'Human Body Systems',
        'eng_1': 'Nouns - Naming Words',
        'eng_2': 'Verbs - Action Words',
        'eng_3': 'Simple Sentences',
        'his_1': 'Indus Valley Civilization',
        'his_2': 'Freedom Struggle',
        'his_3': 'Indian Heritage & Culture',
    };
    return names[lessonId] || lessonId || 'Unknown Lesson';
}

// =============================================
// INITIALIZE ON LOAD
// =============================================
window.onload = function() {
    console.log('🚀 Teacher Dashboard starting...');
    initSupabase();
    
    // Check if already logged in
    supabase.auth.getSession().then(({ data }) => {
        if (data.session) {
            console.log('✅ Already logged in as:', data.session.user.email);
            currentTeacher = data.session.user;
            document.getElementById('teacherName').textContent = currentTeacher.email;
            showScreen('dashboardScreen');
            loadDashboard();
        } else {
            console.log('🔐 Not logged in, showing login screen');
            showScreen('loginScreen');
        }
    }).catch(error => {
        console.error('❌ Session check error:', error);
        showScreen('loginScreen');
    });
};

// Listen for auth changes
supabase?.auth?.onAuthStateChange((event, session) => {
    console.log('🔄 Auth state changed:', event);
    if (event === 'SIGNED_OUT') {
        showScreen('loginScreen');
    }
});