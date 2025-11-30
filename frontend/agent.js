const API_BASE = 'http://localhost:8000';
let currentSessionId = null;
let currentUserId = null;
let isRecording = false;
let mediaRecorder = null;
let audioChunks = [];

// --- Authentication & Settings ---
function getToken() {
    return localStorage.getItem('jwt_token');
}

function updateAuthStatus() {
    const token = getToken();
    const dot = document.getElementById('authDot');
    const text = document.getElementById('authText');

    if (token) {
        dot.classList.add('active');
        text.textContent = '인증됨';
    } else {
        dot.classList.remove('active');
        text.textContent = '인증 필요';
        openSettingsModal();
    }
}

function openSettingsModal() {
    const modal = document.getElementById('settingsModal');
    if (modal) {
        modal.style.display = 'flex';
        document.getElementById('jwtInput').value = getToken() || '';
    }
}

function closeSettingsModal() {
    const modal = document.getElementById('settingsModal');
    if (modal) {
        modal.style.display = 'none';
    }
}

function saveToken() {
    const token = document.getElementById('jwtInput').value.trim();
    if (token) {
        localStorage.setItem('jwt_token', token);
        updateAuthStatus();
        alert('토큰이 저장되었습니다.');
        loadSessions(); // Reload sessions after auth
    } else {
        alert('토큰을 입력해주세요.');
    }
}

async function cleanupHistory() {
    if (!confirm('정말로 모든 대화 내역을 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.')) return;

    const token = getToken();
    try {
        const response = await fetch(`${API_BASE}/api/debug/cleanup/history`, {
            method: 'DELETE',
            headers: { 'Authorization': `Bearer ${token}` }
        });

        if (response.ok) {
            alert('대화 내역이 초기화되었습니다.');
            loadSessions(); // Refresh list
            document.getElementById('chatMessages').innerHTML = ''; // Clear chat
        } else {
            alert('초기화 실패');
        }
    } catch (e) {
        console.error(e);
        alert('오류 발생');
    }
}

async function cleanupMemories() {
    if (!confirm('정말로 모든 기억 데이터를 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.')) return;

    const token = getToken();
    try {
        const response = await fetch(`${API_BASE}/api/debug/cleanup/memories`, {
            method: 'DELETE',
            headers: { 'Authorization': `Bearer ${token}` }
        });

        if (response.ok) {
            alert('기억 데이터가 초기화되었습니다.');
        } else {
            alert('초기화 실패');
        }
    } catch (e) {
        console.error(e);
        alert('오류 발생');
    }
}

// --- Session Management ---
async function loadSessions() {
    const token = getToken();
    if (!token) return;

    try {
        const response = await fetch(`${API_BASE}/api/agent/v2/sessions`, {
            headers: { 'Authorization': `Bearer ${token}` }
        });

        if (response.ok) {
            const data = await response.json();
            if (data.user_id) currentUserId = data.user_id; // Store user_id
            renderSessionList(data.sessions);
        }
    } catch (error) {
        console.error('Failed to load sessions:', error);
    }
}

function renderSessionList(sessions) {
    const list = document.getElementById('sessionList');
    list.innerHTML = '';

    sessions.forEach(session => {
        const div = document.createElement('div');
        div.className = `session-item ${session.session_id === currentSessionId ? 'active' : ''}`;
        div.onclick = () => switchSession(session.session_id);

        const date = new Date(session.last_activity_at).toLocaleDateString();

        // Use first_message for title, fallback to '새로운 대화'
        let title = session.first_message || '새로운 대화';
        if (title.length > 18) title = title.substring(0, 18) + '...';

        div.innerHTML = `
        <div class="session-info">
            <div class="session-title">${title}</div>
            <div class="session-date">${date} • 메시지 ${session.message_count}개</div>
        </div>
        <button class="delete-btn" onclick="deleteSession(event, '${session.session_id}')">🗑️</button>
        `;
        list.appendChild(div);
    });
}

async function createNewSession() {
    if (!currentUserId) {
        // Try to load sessions to get user_id if missing
        await loadSessions();
        if (!currentUserId) {
            alert('사용자 정보를 불러오지 못했습니다. 다시 로그인해주세요.');
            return;
        }
    }

    // Generate new UUID for session with user_id prefix
    const uuid = crypto.randomUUID();
    currentSessionId = `user_${currentUserId}_${uuid}`;

    document.getElementById('currentSessionTitle').textContent = '새로운 대화';
    document.getElementById('chatMessages').innerHTML = `
    <div class="message assistant">
        <div class="message-bubble">
            안녕하세요! 저는 당신의 마음을 돌보는 AI 상담사 봄이입니다. 오늘 하루는 어떠셨나요?
        </div>
        <div class="message-time">방금 전</div>
    </div>
    `;

    // Refresh list to remove active state
    loadSessions();
}

async function switchSession(sessionId) {
    currentSessionId = sessionId;

    // Re-render list to update active state
    loadSessions();

    const chatContainer = document.getElementById('chatMessages');
    chatContainer.innerHTML = '<div class="message assistant"><div class="message-bubble">대화 내역을 불러오는 중...</div></div>';

    try {
        const token = getToken();
        const response = await fetch(`${API_BASE}/api/agent/v2/sessions/${sessionId}`, {
            headers: { 'Authorization': `Bearer ${token}` }
        });

        if (response.ok) {
            const data = await response.json();
            renderHistory(data.messages);

            // Update header title with first message of the session if available
            if (data.messages.length > 0 && data.messages[0].role === 'user') {
                let title = data.messages[0].content;
                if (title.length > 20) title = title.substring(0, 20) + '...';
                document.getElementById('currentSessionTitle').textContent = title;
            } else {
                document.getElementById('currentSessionTitle').textContent = '세션 ' + sessionId.substring(0, 8) + '...';
            }
        }
    } catch (error) {
        console.error('Failed to load history:', error);
        chatContainer.innerHTML = '<div class="message assistant"><div class="message-bubble">대화 내역을 불러오지 못했습니다.</div></div>';
    }
}

function renderHistory(messages) {
    const container = document.getElementById('chatMessages');
    container.innerHTML = '';

    if (messages.length === 0) {
        container.innerHTML = `
        <div class="message assistant">
            <div class="message-bubble">
                안녕하세요! 저는 당신의 마음을 돌보는 AI 상담사 봄이입니다. 오늘 하루는 어떠셨나요?
            </div>
            <div class="message-time">방금 전</div>
        </div>
        `;
        return;
    }

    messages.forEach(msg => {
        appendMessage(msg.role, msg.content, msg.timestamp);
    });

    container.scrollTop = container.scrollHeight;
}

async function deleteSession(event, sessionId) {
    event.stopPropagation();
    if (!confirm('정말 이 세션을 삭제하시겠습니까?')) return;

    const token = getToken();
    try {
        const response = await fetch(`${API_BASE}/api/agent/v2/sessions/${sessionId}`, {
            method: 'DELETE',
            headers: { 'Authorization': `Bearer ${token}` }
        });

        if (response.ok) {
            if (currentSessionId === sessionId) createNewSession();
            loadSessions();
        } else {
            alert('삭제 실패');
        }
    } catch (error) {
        console.error('Error deleting session:', error);
    }
}

// --- WebSocket & STT Logic ---
let sttWebSocket = null;
let audioContext = null;
let scriptProcessor = null;
let mediaStream = null;
let analyser = null;
let animationFrameId = null;
let recognizedFullText = '';

// Timers for debug UI
const timers = {
    emotion: { start: 0, end: 0 },
    routine: { start: 0, end: 0 },
    llm: { start: 0, end: 0 },
    tts: { start: 0, end: 0 }
};

async function toggleRecording() {
    if (isRecording) {
        stopVoiceInput();
    } else {
        await startVoiceInput();
    }
}

async function startVoiceInput() {
    try {
        mediaStream = await navigator.mediaDevices.getUserMedia({
            audio: {
                channelCount: 1,
                sampleRate: 16000,
                echoCancellation: true,
                noiseSuppression: true
            }
        });

        audioContext = new (window.AudioContext || window.webkitAudioContext)({ sampleRate: 16000 });
        const source = audioContext.createMediaStreamSource(mediaStream);

        analyser = audioContext.createAnalyser();
        analyser.fftSize = 256;
        source.connect(analyser);

        scriptProcessor = audioContext.createScriptProcessor(512, 1, 1);

        // Use existing STT WebSocket endpoint
        sttWebSocket = new WebSocket('ws://localhost:8000/stt/stream');

        sttWebSocket.onopen = () => {
            console.log('STT WebSocket connected');
            document.getElementById('micBtn').classList.add('recording');
            isRecording = true;
        };

        sttWebSocket.onmessage = (event) => {
            handleSTTMessage(JSON.parse(event.data));
        };

        sttWebSocket.onerror = (error) => {
            console.error('WebSocket error:', error);
            stopVoiceInput();
        };

        sttWebSocket.onclose = () => {
            console.log('STT WebSocket closed');
            stopVoiceInput();
        };

        scriptProcessor.onaudioprocess = (e) => {
            if (sttWebSocket && sttWebSocket.readyState === WebSocket.OPEN) {
                const inputData = e.inputBuffer.getChannelData(0);
                const float32Array = new Float32Array(inputData);
                sttWebSocket.send(float32Array.buffer);
            }
        };

        source.connect(scriptProcessor);
        scriptProcessor.connect(audioContext.destination);

    } catch (error) {
        console.error('Microphone access error:', error);
        alert('마이크 접근이 거부되었습니다.');
    }
}

function stopVoiceInput() {
    if (sttWebSocket && sttWebSocket.readyState === WebSocket.OPEN) {
        sttWebSocket.send(JSON.stringify({ text: 'force_process' }));
        setTimeout(() => {
            if (sttWebSocket) {
                sttWebSocket.close();
                sttWebSocket = null;
            }
        }, 500);
    }

    if (scriptProcessor) {
        scriptProcessor.disconnect();
        scriptProcessor = null;
    }

    if (mediaStream) {
        mediaStream.getTracks().forEach(track => track.stop());
        mediaStream = null;
    }

    if (audioContext) {
        audioContext.close();
        audioContext = null;
    }

    isRecording = false;
    document.getElementById('micBtn').classList.remove('recording');
}

function handleSTTMessage(data) {
    if (data.status === 'processing') {
        // Show processing state if needed
    } else if (data.text !== undefined) {
        if (data.text && data.text.trim()) {
            document.getElementById('userInput').value = data.text;
            stopVoiceInput();
            // Auto send after short delay
            setTimeout(() => sendMessage(), 500);
        }
    }
}

// --- Debug UI Helpers ---
function updateToolStatus(toolName, status, label) {
    const statusEl = document.getElementById(`${toolName}Status`);
    const cardEl = document.getElementById(`${toolName}Card`);
    const contentEl = document.getElementById(`${toolName}Content`);

    if (statusEl && cardEl) {
        statusEl.textContent = label;

        // Remove all status classes first
        cardEl.classList.remove('pending', 'processing', 'success', 'error');
        cardEl.classList.add(status);
    }
}

function showToolContent(toolName, content) {
    const contentEl = document.getElementById(`${toolName}Content`);
    if (contentEl) {
        contentEl.style.display = 'block';
        if (typeof content === 'object') {
            contentEl.textContent = JSON.stringify(content, null, 2);
        } else {
            contentEl.textContent = content;
        }
    }
}

function resetDebugUI() {
    ['emotion', 'routine', 'llm', 'tts'].forEach(tool => {
        updateToolStatus(tool, 'pending', '대기 중');
        const contentEl = document.getElementById(`${tool}Content`);
        if (contentEl) {
            contentEl.style.display = 'none';
            contentEl.textContent = '';
        }
    });
}

function togglePipeline() {
    const content = document.getElementById('pipelineContent');
    const icon = document.getElementById('pipelineToggleIcon');
    if (content.style.display === 'none') {
        content.style.display = 'block';
        icon.textContent = '▼';
    } else {
        content.style.display = 'none';
        icon.textContent = '▲';
    }
}

// --- Chat Logic ---
function handleEnter(event) {
    if (event.key === 'Enter' && !event.shiftKey) {
        event.preventDefault();
        sendMessage();
    }
}

function appendMessage(role, text, timestamp = null, audioUrl = null) {
    const container = document.getElementById('chatMessages');
    const div = document.createElement('div');
    div.className = `message ${role}`;

    const time = timestamp
        ? new Date(timestamp).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
        : new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });

    // Markdown rendering for assistant
    const content = role === 'assistant' ? marked.parse(text) : text.replace(/\n/g, '<br>');

    let audioButton = '';
    if (audioUrl) {
        audioButton = `
        <button class="replay-btn" onclick="playAudio('${audioUrl}')"
            style="margin-left: 8px; border:none; background:none; cursor:pointer; font-size: 1.1rem;"
            title="다시 듣기">
            🔊
        </button>
        `;
    }

    div.innerHTML = `
    <div class="message-bubble">
        ${content}
        ${audioButton}
    </div>
    <div class="message-time">${time}</div>
    `;

    container.appendChild(div);
    container.scrollTop = container.scrollHeight;
}

function playAudio(url) {
    new Audio(url).play();
}

async function sendMessage() {
    const input = document.getElementById('userInput');
    const text = input.value.trim();
    if (!text) return;

    if (!currentSessionId) await createNewSession();

    appendMessage('user', text);
    input.value = '';

    // Reset and start Debug UI
    resetDebugUI();
    // Ensure pipeline is visible when sending message
    const content = document.getElementById('pipelineContent');
    const icon = document.getElementById('pipelineToggleIcon');
    content.style.display = 'block';
    icon.textContent = '▼';

    try {
        // 1. Emotion Analysis
        timers.emotion.start = performance.now();
        updateToolStatus('emotion', 'processing', '분석 중...');

        // 2. LLM Generation (V2 API calls everything internally, but we simulate steps for UI)
        timers.llm.start = performance.now();
        updateToolStatus('llm', 'processing', '생성 중...');

        const token = getToken();
        const response = await fetch(`${API_BASE}/api/agent/v2/text`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${token}`
            },
            body: JSON.stringify({
                user_text: text,
                session_id: currentSessionId
            })
        });

        const result = await response.json();

        // Update Debug UI with results
        if (result.emotion_result) {
            timers.emotion.end = performance.now();
            const emotionTime = Math.round(timers.emotion.end - timers.emotion.start);
            updateToolStatus('emotion', 'success', `완료 (${emotionTime}ms)`);
            showToolContent('emotion', result.emotion_result);
        }

        if (result.routine_result) {
            updateToolStatus('routine', 'success', '완료');
            showToolContent('routine', result.routine_result);
        } else {
            updateToolStatus('routine', 'pending', '스킵됨');
        }

        timers.llm.end = performance.now();
        const llmTime = Math.round(timers.llm.end - timers.llm.start);
        updateToolStatus('llm', 'success', `완료 (${llmTime}ms)`);
        showToolContent('llm', {
            reply: result.reply_text,
            meta: result.meta
        });

        // 3. TTS Generation
        timers.tts.start = performance.now();
        updateToolStatus('tts', 'processing', '생성 중...');

        try {
            const ttsResponse = await fetch(`${API_BASE}/api/tts`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ text: result.reply_text })
            });

            if (ttsResponse.ok) {
                const blob = await ttsResponse.blob();
                const url = URL.createObjectURL(blob);
                const audio = new Audio(url);
                audio.play();

                // Append message with audio URL for replay
                appendMessage('assistant', result.reply_text, null, url);

                timers.tts.end = performance.now();
                const ttsTime = Math.round(timers.tts.end - timers.tts.start);
                updateToolStatus('tts', 'success', `완료 (${ttsTime}ms)`);
            } else {
                throw new Error('TTS Failed');
            }
        } catch (e) {
            console.error('TTS Error:', e);
            updateToolStatus('tts', 'error', '실패');
            // Append message without audio if TTS fails
            appendMessage('assistant', result.reply_text);
        }

    } catch (error) {
        console.error('Error:', error);
        appendMessage('assistant', '죄송합니다. 오류가 발생했습니다.');
        updateToolStatus('llm', 'error', '오류 발생');
    }
}

// --- Initial Load ---
// Check for token and load sessions
if (getToken()) {
    updateAuthStatus();
    loadSessions();
} else {
    openSettingsModal();
}

// ========================================
// Daily Mood Check JavaScript Functions
// Add these functions to agent.js
// ========================================

// Global state for mood check
let moodCheckState = {
    images: [],
    selectedImageId: null,
    currentSelection: null,
    isProcessing: false,
    pendingChange: null
};

/**
 * Open daily mood check modal
 */
async function openDailyMoodCheckModal() {
    const token = localStorage.getItem('jwt_token');
    if (!token) {
        alert('로그인이 필요합니다.');
        return;
    }

    const modal = document.getElementById('moodModal');
    modal.style.display = 'flex';

    // Reset state
    moodCheckState.images = [];
    moodCheckState.selectedImageId = null;
    moodCheckState.currentSelection = null;
    moodCheckState.isProcessing = false;
    moodCheckState.pendingChange = null;

    // Fetch current status
    try {
        const statusRes = await fetch('/api/service/daily-mood-check/status', {
            headers: {
                'Authorization': `Bearer ${token}`
            }
        });

        if (statusRes.ok) {
            const status = await statusRes.json();
            moodCheckState.currentSelection = status;

            if (status.completed) {
                moodCheckState.selectedImageId = status.selected_image_id;
                updateMoodStatusMessage('일일 기분 체크를 완료 하셨습니다.');
            }
        }
    } catch (error) {
        console.error('Failed to fetch status:', error);
    }

    // Fetch images
    try {
        const imagesRes = await fetch('/api/service/daily-mood-check/images');
        if (imagesRes.ok) {
            const data = await imagesRes.json();
            moodCheckState.images = data.images;
            renderMoodImages();
        } else {
            throw new Error('Failed to fetch images');
        }
    } catch (error) {
        console.error('Failed to load images:', error);
        alert('이미지를 불러오는데 실패했습니다.');
        closeDailyMoodCheckModal();
    }
}

/**
 * Close mood check modal
 */
function closeDailyMoodCheckModal() {
    const modal = document.getElementById('moodModal');
    modal.style.display = 'none';

    // Hide confirmation dialog
    document.getElementById('moodConfirmation').style.display = 'none';
}

/**
 * Update status message
 */
function updateMoodStatusMessage(message) {
    document.getElementById('moodStatusMessage').textContent = message;
}

/**
 * Render mood images
 */
function renderMoodImages() {
    const grid = document.getElementById('moodImagesGrid');
    grid.innerHTML = '';

    moodCheckState.images.forEach(image => {
        const item = document.createElement('div');
        item.className = 'mood-image-item';
        item.dataset.imageId = image.id;
        item.dataset.sentiment = image.sentiment;
        item.dataset.filename = image.filename;

        // Add selected class if this is the current selection
        if (image.id === moodCheckState.selectedImageId) {
            item.classList.add('selected');
        }

        item.innerHTML = `
            <img src="${image.url}" alt="${image.description}">
            <div class="mood-image-description">${image.description}</div>
        `;

        // Add click handler
        item.onclick = () => handleImageClick(image);

        grid.appendChild(item);
    });

    // Add status overlays for selected image
    if (moodCheckState.selectedImageId && moodCheckState.isProcessing) {
        addProcessingOverlay(moodCheckState.selectedImageId);
    } else if (moodCheckState.selectedImageId && moodCheckState.currentSelection?.completed) {
        addCheckmarkOverlay(moodCheckState.selectedImageId);
    }
}

/**
 * Handle image click
 */
function handleImageClick(image) {
    // If already processing, do nothing
    if (moodCheckState.isProcessing) {
        return;
    }

    // If clicking the same selected image, do nothing
    if (image.id === moodCheckState.selectedImageId) {
        return;
    }

    // If already completed, show confirmation
    if (moodCheckState.currentSelection?.completed) {
        moodCheckState.pendingChange = image;
        document.getElementById('moodConfirmation').style.display = 'block';
        return;
    }

    // Otherwise, select directly
    selectMoodImage(image);
}

/**
 * Select mood image
 */
async function selectMoodImage(image) {
    const token = localStorage.getItem('jwt_token');
    if (!token) {
        alert('로그인이 필요합니다.');
        return;
    }

    // Update UI to processing state
    moodCheckState.selectedImageId = image.id;
    moodCheckState.isProcessing = true;
    renderMoodImages();

    try {
        const response = await fetch('/api/service/daily-mood-check/select', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${token}`
            },
            body: JSON.stringify({
                user_id: 0, // Will be ignored, using JWT
                image_id: image.id,
                filename: image.filename,
                sentiment: image.sentiment
            })
        });

        if (!response.ok) {
            throw new Error('Failed to select image');
        }

        const result = await response.json();

        // Update state
        moodCheckState.isProcessing = false;
        moodCheckState.currentSelection = {
            completed: true,
            selected_image_id: image.id
        };

        // Update UI
        updateMoodStatusMessage('일일 기분 체크를 완료 하셨습니다.');
        renderMoodImages();

        // Update sidebar button
        updateSidebarMoodCheckStatus(true);

    } catch (error) {
        console.error('Failed to select image:', error);
        alert('선택에 실패했습니다. 다시 시도해주세요.');

        // Reset state
        moodCheckState.selectedImageId = moodCheckState.currentSelection?.selected_image_id || null;
        moodCheckState.isProcessing = false;
        renderMoodImages();
    }
}

/**
 * Confirm mood change
 */
function confirmMoodChange() {
    if (moodCheckState.pendingChange) {
        document.getElementById('moodConfirmation').style.display = 'none';
        selectMoodImage(moodCheckState.pendingChange);
        moodCheckState.pendingChange = null;
    }
}

/**
 * Cancel mood change
 */
function cancelMoodChange() {
    moodCheckState.pendingChange = null;
    document.getElementById('moodConfirmation').style.display = 'none';
}

/**
 * Add processing overlay to image
 */
function addProcessingOverlay(imageId) {
    const item = document.querySelector(`[data-image-id="${imageId}"]`);
    if (item) {
        const overlay = document.createElement('div');
        overlay.className = 'mood-status-overlay';
        overlay.innerHTML = '<div class="spinner"></div>';
        item.appendChild(overlay);
        item.classList.add('disabled');
    }
}

/**
 * Add checkmark overlay to image
 */
function addCheckmarkOverlay(imageId) {
    const item = document.querySelector(`[data-image-id="${imageId}"]`);
    if (item) {
        const overlay = document.createElement('div');
        overlay.className = 'mood-status-overlay';
        overlay.innerHTML = '<div class="checkmark">✓</div>';
        item.appendChild(overlay);
        item.classList.add('disabled');
    }
}

/**
 * Update sidebar mood check button status
 */
async function updateSidebarMoodCheckStatus(forceCompleted = false) {
    if (forceCompleted) {
        const btn = document.getElementById('moodCheckBtn');
        const icon = document.getElementById('moodCheckIcon');
        btn.classList.add('completed');
        icon.textContent = '✓';
        return;
    }

    const token = localStorage.getItem('jwt_token');
    if (!token) return;

    try {
        const response = await fetch('/api/service/daily-mood-check/status', {
            headers: {
                'Authorization': `Bearer ${token}`
            }
        });

        if (response.ok) {
            const status = await response.json();
            const btn = document.getElementById('moodCheckBtn');
            const icon = document.getElementById('moodCheckIcon');

            if (status.completed) {
                btn.classList.add('completed');
                icon.textContent = '✓';
            } else {
                btn.classList.remove('completed');
                icon.textContent = '💭';
            }
        }
    } catch (error) {
        console.error('Failed to update mood check status:', error);
    }
}

// Initialize on page load
document.addEventListener('DOMContentLoaded', () => {
    updateSidebarMoodCheckStatus();
});

