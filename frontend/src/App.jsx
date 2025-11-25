import { useState, useEffect } from 'react'
import EmotionInput from './components/EmotionInput'
import EmotionResult from './components/EmotionResult'
import EmotionChart from './components/EmotionChart'
import RoutineList from './components/RoutineList'
import STTTest from './components/STTTest'
import TTSTest from './components/TTSTest'
import DailyMoodCheck from './components/DailyMoodCheck'
import WeatherCard from './components/WeatherCard'
import './App.css'

function App() {
  // localStorage에서 activeTab 복원 또는 기본값 사용
  const [activeTab, setActiveTab] = useState(() => {
    const saved = localStorage.getItem('activeTab')
    return saved || 'emotion' // 'emotion', 'routine-test', 'stt-tts-test', 'daily-mood-check'
  })

  // activeTab이 변경될 때마다 localStorage에 저장
  useEffect(() => {
    localStorage.setItem('activeTab', activeTab)
  }, [activeTab])

  // 감정 분석 관련 state
  const [result, setResult] = useState(null)
  const [routines, setRoutines] = useState([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState(null)

  // 루틴 추천 테스트 관련 state
  const [testJson, setTestJson] = useState('')
  const [testRoutines, setTestRoutines] = useState([])
  const [testLoading, setTestLoading] = useState(false)
  const [testError, setTestError] = useState(null)

  const handleAnalyze = async (text) => {
    setLoading(true)
    setError(null)

    try {
      const response = await fetch('http://localhost:8000/api/analyze', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ text }),
      })

      if (!response.ok) {
        throw new Error('분석 요청 실패')
      }

      const data = await response.json()
      setResult(data)

      // 2. 루틴 추천 요청
      try {
        const routineResponse = await fetch('http://localhost:8000/api/engine/routine-recommend-from-emotion', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            user_id: 1,
            emotion_result: data,
            time_of_day: 'morning' // 임시로 아침으로 고정
          }),
        })

        if (routineResponse.ok) {
          const routineData = await routineResponse.json()
          setRoutines(routineData.recommendations)
        }
      } catch (routineErr) {
        console.error('Routine recommendation failed:', routineErr)
        // 루틴 추천 실패해도 감정 분석 결과는 보여줌
      }

    } catch (err) {
      setError(err.message)
      console.error('Error:', err)
    } finally {
      setLoading(false)
    }
  }

  const handleReset = () => {
    setResult(null)
    setRoutines([])
    setError(null)
  }

  // 루틴 추천 테스트 함수들
  const loadSampleJson = () => {
    const sample = {
      "text": "아침에 눈을 뜨자 햇살이 방 안을 가득 채우고 있었고, 오랜만에 상쾌한 기분이 들어 따뜻한 커피를 한 잔 들고 여유롭게 집을 나설 수 있었다.",
      "language": "ko",
      "raw_distribution": [
        { "code": "joy", "name_ko": "기쁨", "group": "positive", "score": 0.8 },
        { "code": "excitement", "name_ko": "흥분", "group": "positive", "score": 0.6 },
        { "code": "confidence", "name_ko": "자신감", "group": "positive", "score": 0.5 },
        { "code": "relief", "name_ko": "안심", "group": "positive", "score": 0.4 },
        { "code": "sadness", "name_ko": "슬픔", "group": "negative", "score": 0.0 },
        { "code": "anger", "name_ko": "분노", "group": "negative", "score": 0.0 }
      ],
      "primary_emotion": {
        "code": "joy",
        "name_ko": "기쁨",
        "group": "positive",
        "intensity": 4,
        "confidence": 0.85
      },
      "secondary_emotions": [
        { "code": "excitement", "name_ko": "흥분", "intensity": 3 },
        { "code": "confidence", "name_ko": "자신감", "intensity": 3 }
      ],
      "sentiment_overall": "positive",
      "service_signals": {
        "need_empathy": true,
        "need_routine_recommend": true,
        "need_health_check": false,
        "need_voice_analysis": false,
        "risk_level": "normal"
      },
      "recommended_response_style": ["cheerful", "warm"],
      "recommended_routine_tags": ["maintain_positive", "gratitude", "social_activity"],
      "report_tags": ["기쁨 경향", "흥분 경향", "자신감 경향"]
    }
    setTestJson(JSON.stringify(sample, null, 2))
  }

  const handleTestRoutine = async () => {
    setTestLoading(true)
    setTestError(null)
    setTestRoutines([])

    try {
      let emotionData
      try {
        emotionData = JSON.parse(testJson)
      } catch (e) {
        throw new Error('JSON 형식이 올바르지 않습니다.')
      }

      const response = await fetch('http://localhost:8000/api/engine/routine-from-emotion', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(emotionData),
      })

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({ detail: response.statusText }))
        throw new Error(errorData.detail || '루틴 추천 요청 실패')
      }

      const data = await response.json()
      setTestRoutines(data)
    } catch (err) {
      setTestError(err.message)
      console.error('Error:', err)
    } finally {
      setTestLoading(false)
    }
  }

  return (
    <div className="app">
      <header className="header">
        <h1>💜 감정 분석 AI</h1>
        <p>갱년기 여성을 위한 감정 공감 서비스</p>
      </header>

      {/* 탭 전환 버튼 */}
      <div style={{ display: 'flex', justifyContent: 'center', gap: '10px', margin: '20px 0', flexWrap: 'wrap' }}>
        <button
          onClick={() => setActiveTab('emotion')}
          style={{
            padding: '10px 20px',
            fontSize: '16px',
            cursor: 'pointer',
            backgroundColor: activeTab === 'emotion' ? '#6366f1' : '#e5e7eb',
            color: activeTab === 'emotion' ? 'white' : '#374151',
            border: 'none',
            borderRadius: '8px',
            fontWeight: activeTab === 'emotion' ? 'bold' : 'normal'
          }}
        >
          감정 분석
        </button>
        <button
          onClick={() => setActiveTab('routine-test')}
          style={{
            padding: '10px 20px',
            fontSize: '16px',
            cursor: 'pointer',
            backgroundColor: activeTab === 'routine-test' ? '#6366f1' : '#e5e7eb',
            color: activeTab === 'routine-test' ? 'white' : '#374151',
            border: 'none',
            borderRadius: '8px',
            fontWeight: activeTab === 'routine-test' ? 'bold' : 'normal'
          }}
        >
          루틴 추천 테스트
        </button>
        <button
          onClick={() => setActiveTab('stt-tts-test')}
          style={{
            padding: '10px 20px',
            fontSize: '16px',
            cursor: 'pointer',
            backgroundColor: activeTab === 'stt-tts-test' ? '#6366f1' : '#e5e7eb',
            color: activeTab === 'stt-tts-test' ? 'white' : '#374151',
            border: 'none',
            borderRadius: '8px',
            fontWeight: activeTab === 'stt-tts-test' ? 'bold' : 'normal'
          }}
        >
          STT/TTS 테스트
        </button>
        <button
          onClick={() => setActiveTab('daily-mood-check')}
          style={{
            padding: '10px 20px',
            fontSize: '16px',
            cursor: 'pointer',
            backgroundColor: activeTab === 'daily-mood-check' ? '#6366f1' : '#e5e7eb',
            color: activeTab === 'daily-mood-check' ? 'white' : '#374151',
            border: 'none',
            borderRadius: '8px',
            fontWeight: activeTab === 'daily-mood-check' ? 'bold' : 'normal'
          }}
        >
          일일 감정 체크
        </button>
      </div>

      <div className="main-container">
        {/* 루틴 추천 테스트 섹션 */}
        {activeTab === 'routine-test' && (
          <>
            <div className="card">
              <h2>루틴 추천 API 테스트</h2>
              <div style={{ marginBottom: '15px' }}>
                <button
                  onClick={loadSampleJson}
                  style={{
                    padding: '8px 16px',
                    backgroundColor: '#10b981',
                    color: 'white',
                    border: 'none',
                    borderRadius: '6px',
                    cursor: 'pointer',
                    marginRight: '10px'
                  }}
                >
                  샘플 JSON 로드
                </button>
                <button
                  onClick={() => setTestJson('')}
                  style={{
                    padding: '8px 16px',
                    backgroundColor: '#6b7280',
                    color: 'white',
                    border: 'none',
                    borderRadius: '6px',
                    cursor: 'pointer'
                  }}
                >
                  초기화
                </button>
              </div>
              <textarea
                value={testJson}
                onChange={(e) => setTestJson(e.target.value)}
                placeholder="감정 분석 결과 JSON을 입력하세요..."
                style={{
                  width: '100%',
                  minHeight: '300px',
                  padding: '12px',
                  fontSize: '14px',
                  fontFamily: 'monospace',
                  border: '1px solid #d1d5db',
                  borderRadius: '6px',
                  marginBottom: '15px'
                }}
              />
              <button
                onClick={handleTestRoutine}
                disabled={testLoading || !testJson.trim()}
                style={{
                  padding: '12px 24px',
                  backgroundColor: testLoading || !testJson.trim() ? '#9ca3af' : '#6366f1',
                  color: 'white',
                  border: 'none',
                  borderRadius: '6px',
                  cursor: testLoading || !testJson.trim() ? 'not-allowed' : 'pointer',
                  fontSize: '16px',
                  fontWeight: 'bold'
                }}
              >
                {testLoading ? '추천 중...' : '루틴 추천 요청'}
              </button>
              {testError && (
                <div style={{
                  marginTop: '15px',
                  padding: '12px',
                  backgroundColor: '#fee2e2',
                  color: '#991b1b',
                  borderRadius: '6px',
                  border: '1px solid #fecaca'
                }}>
                  <strong>오류:</strong> {testError}
                </div>
              )}
            </div>

            {testRoutines && testRoutines.length > 0 && (
              <div className="card">
                <RoutineList recommendations={testRoutines} />
              </div>
            )}

            {!testLoading && !testRoutines.length && !testError && (
              <div className="card">
                <div className="empty-state">
                  <div className="empty-state-icon">📝</div>
                  <p>샘플 JSON을 로드하거나 직접 입력한 후 추천 버튼을 눌러주세요</p>
                </div>
              </div>
            )}
          </>
        )}

        {/* 감정 분석 섹션 */}
        {activeTab === 'emotion' && (
          <>
            {/* 1. 감정 분석 (입력) */}
            <div className="card" style={{ marginBottom: '1rem' }}>
              <h2 style={{ marginBottom: '0.75rem' }}>감정 분석</h2>
              <EmotionInput
                onAnalyze={handleAnalyze}
                onReset={handleReset}
                loading={loading}
              />

              {error && (
                <div className="error" style={{ marginTop: '0.75rem' }}>
                  <strong>오류:</strong> {error}
                </div>
              )}
            </div>

            {/* 2. 분석 결과 */}
            <div className="card" style={{ marginBottom: '1rem' }}>
              <h2 style={{ marginBottom: '0.75rem' }}>분석 결과</h2>

              {loading && (
                <div className="loading">
                  <div className="loading-spinner"></div>
                  <p>감정을 분석하고 있습니다...</p>
                </div>
              )}

              {!loading && result && (
                <EmotionResult result={result} />
              )}

              {!loading && !result && !error && (
                <p style={{ color: '#6b7280', fontSize: '14px' }}>
                  위에 텍스트를 입력하고 분석 버튼을 눌러주세요.
                </p>
              )}
            </div>

            {/* 3. 감정 분포 */}
            <div className="card" style={{ marginBottom: '1rem' }}>
              <h2 style={{ marginBottom: '0.75rem' }}>감정 분포</h2>

              {loading && (
                <p style={{ color: '#6b7280', fontSize: '14px' }}>
                  감정 분포를 계산하는 중입니다...
                </p>
              )}

              {!loading && result && (
                <>
                  {result.raw_distribution ? (
                    <EmotionChart rawDistribution={result.raw_distribution} />
                  ) : (
                    <EmotionChart
                      emotions={result.top_emotions || result.emotions}
                    />
                  )}
                </>
              )}

              {!loading && !result && !error && (
                <p style={{ color: '#6b7280', fontSize: '14px' }}>
                  분석이 완료되면 감정 분포가 여기에서 그래프로 보여져요.
                </p>
              )}
            </div>

            {/* 4. 오늘 날씨 (항상 표시) */}
            <div className="card" style={{ marginBottom: '1rem' }}>
              <h2 style={{ marginBottom: '0.75rem' }}>오늘 날씨</h2>
              {/* 현재 위치 기반 WeatherCard (city prop 없이) */}
              <WeatherCard />
            </div>

            {/* 부가: 유사 문맥 */}
            {!loading && result && result.similar_contexts && result.similar_contexts.length > 0 && (
              <div className="card contexts-section" style={{ marginBottom: '1rem' }}>
                <h2>유사한 감정 표현</h2>
                {result.similar_contexts.map((context, index) => (
                  <div key={index} className="context-item">
                    <div className="context-text">"{context.text}"</div>
                    <div className="context-meta">
                      <span>감정: {getEmotionLabel(context.emotion)}</span>
                      <span>강도: {context.intensity}/5</span>
                      <span>유사도: {(context.similarity * 100).toFixed(1)}%</span>
                    </div>
                  </div>
                ))}
              </div>
            )}

            {/* 부가: 루틴 추천 결과 */}
            {!loading && routines && routines.length > 0 && (
              <div className="card">
                <RoutineList recommendations={routines} />
              </div>
            )}
          </>
        )}

        {/* STT/TTS 테스트 섹션 */}
        {activeTab === 'stt-tts-test' && (
          <>
            <STTTest />
            <TTSTest />
          </>
        )}

        {/* 일일 감정 체크 섹션 */}
        {activeTab === 'daily-mood-check' && (
          <DailyMoodCheck />
        )}
      </div>
    </div>
  )
}

function getEmotionLabel(emotion) {
  const labels = {
    joy: '기쁨',
    calmness: '평온',
    sadness: '슬픔',
    anger: '분노',
    anxiety: '불안',
    loneliness: '외로움',
    fatigue: '피로',
    confusion: '혼란',
    guilt: '죄책감',
    frustration: '좌절'
  }
  return labels[emotion] || emotion
}

export default App