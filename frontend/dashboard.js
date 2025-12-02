// Global variables for charts
let emotionDistributionChart = null;
let signalCorrelationChart = null;
let recommendationEffectChart = null;
let emotionTrendChart = null;

// Global data storage
let allEmotionData = [];

document.addEventListener('DOMContentLoaded', () => {
    checkAuth();
    updateDashboard();
});

// Authentication Check
function checkAuth() {
    const token = localStorage.getItem('jwt_token');
    const authDot = document.getElementById('authDot');
    const authText = document.getElementById('authText');

    if (token) {
        authDot.style.backgroundColor = '#4caf50'; // Green
        authText.textContent = '인증됨';
        authText.style.color = '#4caf50';
    } else {
        authDot.style.backgroundColor = '#f44336'; // Red
        authText.textContent = '인증 필요';
        authText.style.color = '#f44336';
        alert('로그인이 필요합니다. Agent 페이지에서 먼저 로그인해주세요.');
        location.href = 'agent.html';
    }
}

// Fetch Data and Update Dashboard
async function updateDashboard() {
    const token = localStorage.getItem('jwt_token');
    if (!token) return;

    try {
        const response = await fetch('http://localhost:8000/api/dashboard/emotion-history?limit=100', {
            headers: {
                'Authorization': `Bearer ${token}`
            }
        });

        if (!response.ok) {
            throw new Error('데이터를 불러오는데 실패했습니다.');
        }

        allEmotionData = await response.json();

        // Filter data based on time range
        const timeRange = document.getElementById('timeRange').value;
        const filteredData = filterDataByTimeRange(allEmotionData, timeRange);

        renderCharts(filteredData);
        updateInsights(filteredData);

    } catch (error) {
        console.error('Dashboard Error:', error);
        alert('데이터 로딩 중 오류가 발생했습니다: ' + error.message);
    }
}

function filterDataByTimeRange(data, range) {
    if (range === 'all') return data;

    const now = new Date();
    const cutoff = new Date();

    if (range === 'week') {
        cutoff.setDate(now.getDate() - 7);
    } else if (range === 'month') {
        cutoff.setMonth(now.getMonth() - 1);
    }

    return data.filter(item => new Date(item.CREATED_AT) >= cutoff);
}

function renderCharts(data) {
    // 1. User Emotion Profile (Pie Chart)
    renderEmotionDistribution(data);

    // 2. Service Signal Context (Bar Chart)
    renderSignalCorrelation(data);

    // 3. Recommendation Effect (Bar Chart)
    renderRecommendationEffect(data);

    // 4. Emotion Trend (Line Chart)
    renderEmotionTrend(data);
}

function renderEmotionDistribution(data) {
    const ctx = document.getElementById('emotionDistributionChart').getContext('2d');

    // Count primary emotions
    const emotionCounts = {};
    data.forEach(item => {
        if (item.PRIMARY_EMOTION && item.PRIMARY_EMOTION.emotion) {
            const emotion = item.PRIMARY_EMOTION.emotion;
            emotionCounts[emotion] = (emotionCounts[emotion] || 0) + 1;
        }
    });

    const labels = Object.keys(emotionCounts);
    const values = Object.values(emotionCounts);

    if (emotionDistributionChart) emotionDistributionChart.destroy();

    emotionDistributionChart = new Chart(ctx, {
        type: 'doughnut',
        data: {
            labels: labels,
            datasets: [{
                data: values,
                backgroundColor: [
                    '#FF6384', '#36A2EB', '#FFCE56', '#4BC0C0', '#9966FF', '#FF9F40', '#C9CBCF'
                ]
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: {
                    position: 'right'
                }
            }
        }
    });
}

function renderSignalCorrelation(data) {
    const ctx = document.getElementById('signalCorrelationChart').getContext('2d');

    // Analyze correlation between signals and negative emotions
    // Simplified: Count negative emotions per signal tag
    const signalCounts = {};

    data.forEach(item => {
        if (item.SENTIMENT_OVERALL === 'negative' && item.SERVICE_SIGNALS) {
            // Assuming SERVICE_SIGNALS is a JSON object with boolean flags or specific keys
            // Adjust based on actual structure. For now, let's assume it has keys like 'is_tired', etc.
            // If SERVICE_SIGNALS is just a dict of signals
            Object.keys(item.SERVICE_SIGNALS).forEach(signal => {
                if (item.SERVICE_SIGNALS[signal]) {
                    signalCounts[signal] = (signalCounts[signal] || 0) + 1;
                }
            });
        }
    });

    const labels = Object.keys(signalCounts);
    const values = Object.values(signalCounts);

    if (signalCorrelationChart) signalCorrelationChart.destroy();

    signalCorrelationChart = new Chart(ctx, {
        type: 'bar',
        data: {
            labels: labels,
            datasets: [{
                label: '부정 감정 유발 신호 빈도',
                data: values,
                backgroundColor: '#FF6384'
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            scales: {
                y: {
                    beginAtZero: true,
                    ticks: {
                        stepSize: 1
                    }
                }
            }
        }
    });
}

function renderRecommendationEffect(data) {
    const ctx = document.getElementById('recommendationEffectChart').getContext('2d');

    // Analyze which recommendation style leads to positive sentiment in *subsequent* interactions?
    // Or just distribution of styles for now since we don't have easy "next interaction" linking here without session logic.
    // Let's show distribution of Recommended Response Styles

    const styleCounts = {};
    data.forEach(item => {
        if (item.RECOMMENDED_RESPONSE_STYLE) {
            // Assuming it's a string or object with a style name
            // If it's a JSON object, we might need to extract a specific field.
            // Let's assume it might be a simple string or a key in the JSON.
            let style = 'Unknown';
            if (typeof item.RECOMMENDED_RESPONSE_STYLE === 'string') {
                style = item.RECOMMENDED_RESPONSE_STYLE;
            } else if (item.RECOMMENDED_RESPONSE_STYLE.style) {
                style = item.RECOMMENDED_RESPONSE_STYLE.style;
            } else {
                // Try to find a key that looks like a style
                style = JSON.stringify(item.RECOMMENDED_RESPONSE_STYLE).slice(0, 20);
            }
            styleCounts[style] = (styleCounts[style] || 0) + 1;
        }
    });

    const labels = Object.keys(styleCounts);
    const values = Object.values(styleCounts);

    if (recommendationEffectChart) recommendationEffectChart.destroy();

    recommendationEffectChart = new Chart(ctx, {
        type: 'bar',
        data: {
            labels: labels,
            datasets: [{
                label: '추천 응답 스타일 분포',
                data: values,
                backgroundColor: '#4BC0C0'
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            indexAxis: 'y', // Horizontal bar chart
        }
    });
}

function renderEmotionTrend(data) {
    const ctx = document.getElementById('emotionTrendChart').getContext('2d');

    // Sort data by date ascending for the line chart
    const sortedData = [...data].sort((a, b) => new Date(a.CREATED_AT) - new Date(b.CREATED_AT));

    const labels = sortedData.map(item => {
        const date = new Date(item.CREATED_AT);
        return `${date.getMonth() + 1}/${date.getDate()} ${date.getHours()}:${date.getMinutes()}`;
    });

    // Map sentiments to numerical values for plotting? Or just plot emotion intensity if available.
    // Let's plot Sentiment Score if we can derive it, or just map Positive=1, Neutral=0, Negative=-1
    const sentimentValues = sortedData.map(item => {
        if (item.SENTIMENT_OVERALL === 'positive') return 1;
        if (item.SENTIMENT_OVERALL === 'negative') return -1;
        return 0;
    });

    if (emotionTrendChart) emotionTrendChart.destroy();

    emotionTrendChart = new Chart(ctx, {
        type: 'line',
        data: {
            labels: labels,
            datasets: [{
                label: '감정 상태 (긍정=1, 중립=0, 부정=-1)',
                data: sentimentValues,
                borderColor: '#36A2EB',
                tension: 0.4,
                fill: false
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            scales: {
                y: {
                    min: -1.5,
                    max: 1.5,
                    ticks: {
                        stepSize: 1,
                        callback: function (value) {
                            if (value === 1) return '긍정';
                            if (value === 0) return '중립';
                            if (value === -1) return '부정';
                            return '';
                        }
                    }
                }
            }
        }
    });
}

function updateInsights(data) {
    // 1. Emotion Insight
    const emotionCounts = {};
    data.forEach(item => {
        if (item.PRIMARY_EMOTION && item.PRIMARY_EMOTION.emotion) {
            const emotion = item.PRIMARY_EMOTION.emotion;
            emotionCounts[emotion] = (emotionCounts[emotion] || 0) + 1;
        }
    });

    // Find dominant emotion
    let dominantEmotion = '없음';
    let maxCount = 0;
    for (const [emotion, count] of Object.entries(emotionCounts)) {
        if (count > maxCount) {
            maxCount = count;
            dominantEmotion = emotion;
        }
    }

    const emotionInsightBox = document.getElementById('emotionInsight');
    emotionInsightBox.innerHTML = `
        <p><strong>주요 감정:</strong> ${dominantEmotion}</p>
        <p>최근 ${data.length}건의 대화 중 <strong>${Math.round((maxCount / data.length) * 100)}%</strong>가 ${dominantEmotion} 감정을 보였습니다.</p>
    `;

    // 2. Tag Cloud (Report Tags)
    const reportTags = {};
    data.forEach(item => {
        if (item.REPORT_TAGS) {
            // Assuming REPORT_TAGS is a list of strings or similar
            // If it's a JSON object, adjust accordingly.
            // Example: ["stress", "work"]
            let tags = [];
            if (Array.isArray(item.REPORT_TAGS)) {
                tags = item.REPORT_TAGS;
            } else if (typeof item.REPORT_TAGS === 'object') {
                tags = Object.keys(item.REPORT_TAGS);
            }

            tags.forEach(tag => {
                reportTags[tag] = (reportTags[tag] || 0) + 1;
            });
        }
    });

    const tagCloud = document.getElementById('reportTagsCloud');
    tagCloud.innerHTML = Object.entries(reportTags)
        .sort((a, b) => b[1] - a[1]) // Sort by frequency
        .slice(0, 10) // Top 10
        .map(([tag, count]) => `<span class="tag">${tag} (${count})</span>`)
        .join('');


    // 3. Top Routines
    const routineCounts = {};
    data.forEach(item => {
        if (item.RECOMMENDED_ROUTINE_TAGS) {
            let routines = [];
            if (Array.isArray(item.RECOMMENDED_ROUTINE_TAGS)) {
                routines = item.RECOMMENDED_ROUTINE_TAGS;
            } else if (typeof item.RECOMMENDED_ROUTINE_TAGS === 'object') {
                // Maybe keys are routines?
                routines = Object.keys(item.RECOMMENDED_ROUTINE_TAGS);
            }

            routines.forEach(r => {
                routineCounts[r] = (routineCounts[r] || 0) + 1;
            });
        }
    });

    const topRoutinesList = document.getElementById('topRoutinesList');
    topRoutinesList.innerHTML = Object.entries(routineCounts)
        .sort((a, b) => b[1] - a[1])
        .slice(0, 5)
        .map(([routine, count]) => `
            <div class="list-item">
                <span>${routine}</span>
                <span style="color: #888;">${count}회 추천</span>
            </div>
        `)
        .join('');

    // 4. Text Stats
    const totalLength = data.reduce((sum, item) => sum + (item.TEXT ? item.TEXT.length : 0), 0);
    const avgLength = data.length ? Math.round(totalLength / data.length) : 0;

    const textStats = document.getElementById('textStats');
    textStats.innerHTML = `
        <div class="stat-item">
            <div class="stat-value">${data.length}</div>
            <div class="stat-label">분석된 대화</div>
        </div>
        <div class="stat-item">
            <div class="stat-value">${avgLength}자</div>
            <div class="stat-label">평균 길이</div>
        </div>
    `;
}
