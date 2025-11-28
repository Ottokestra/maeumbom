import { useState, useEffect } from 'react'
import EmotionInput from './components/EmotionInput'
import EmotionResult from './components/EmotionResult'
import EmotionChart from './components/EmotionChart'
import RoutineList from './components/RoutineList'
import STTTest from './components/STTTest'
import TTSTest from './components/TTSTest'
import DailyMoodCheck from './components/DailyMoodCheck'
import Login from './components/Login'
import WeatherCard from './components/WeatherCard'
import './App.css'

const API_BASE_URL = 'http://localhost:8000'

function App() {
  // 로그인 상태 관리 (선택사항 - 테스트 중)
  const [isLoggedIn, setIsLoggedIn] = useState(() => {
    return !!localStorage.getItem('access_token')
  })
  const [user, setUser] = useState(null)
  const [showLoginModal, setShowLoginModal] = useState(false)
  const [isProcessingCallback, setIsProcessingCallback] = useState(false)

  // 로그인 성공 핸들러
  const handleLoginSuccess = () => {
    setIsLoggedIn(true)
    setShowLoginModal(false)
    fetchUserInfo()
  }

  // 로그아웃 핸들러
  const handleLogout = async () => {
    const accessToken = localStorage.getItem('access_token')

    try {
      // 서버에 로그아웃 요청
      await fetch(`${API_BASE_URL}/auth/logout`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${accessToken}`
        }
      })
    } catch (err) {
      console.error('Logout error:', err)
    } finally {
      // 로컬 스토리지 정리
      localStorage.removeItem('access_token')
      localStorage.removeItem('refresh_token')
      setIsLoggedIn(false)
      setUser(null)
    }
  }

  // 사용자 정보 조회
  const fetchUserInfo = async () => {
    const accessToken = localStorage.getItem('access_token')
    if (!accessToken) return

    try {
      const response = await fetch(`${API_BASE_URL}/auth/me`, {
        headers: {
          'Authorization': `Bearer ${accessToken}`
        }
      })

      if (response.status === 401) {
        // 토큰 만료 시 재발급 시도
        await refreshToken()
        return
      }

      if (response.ok) {
        const userData = await response.json()
        setUser(userData)
      }
    } catch (err) {
      console.error('Failed to fetch user info:', err)
    }
  }

  // 토큰 재발급
  const refreshToken = async () => {
    const refreshTokenValue = localStorage.getItem('refresh_token')
    if (!refreshTokenValue) {
      handleLogout()
      return
    }

    try {
      const response = await fetch(`${API_BASE_URL}/auth/refresh`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ refresh_token: refreshTokenValue })
      })

      if (response.ok) {
        const data = await response.json()
        localStorage.setItem('access_token', data.access_token)
        localStorage.setItem('refresh_token', data.refresh_token)
        fetchUserInfo()
      } else {
        handleLogout()
      }
    } catch (err) {
      console.error('Token refresh failed:', err)
      handleLogout()
    }
  }

  // OAuth callback 처리 (URL에 code가 있는 경우) - 중복 요청 방지
  useEffect(() => {
    const urlParams = new URLSearchParams(window.location.search)
    const code = urlParams.get('code')
    const state = urlParams.get('state')

    // code가 있고, 아직 로그인되지 않았으며, 이미 처리 중이 아닌 경우만 처리
    if (code && !isLoggedIn && !isProcessingCallback) {
      setIsProcessingCallback(true)

      const handleOAuthCallback = async () => {
        try {
          // URL에서 code를 즉시 제거 (중복 요청 방지)
          window.history.replaceState({}, document.title, window.location.pathname)

          let endpoint = `${API_BASE_URL}/auth/google`
          let requestBody = {
            auth_code: code,
            redirect_uri: `${window.location.origin}/auth/callback`
          }

          // Naver OAuth인 경우 (state 파라미터가 있는 경우)
          if (state) {
            const savedState = sessionStorage.getItem('naver_state')
            if (savedState === state) {
              endpoint = `${API_BASE_URL}/auth/naver`
              requestBody.state = state
              sessionStorage.removeItem('naver_state')
            } else {
              console.error('[OAuth] Naver state mismatch')
              setIsProcessingCallback(false)
              return
            }
          } else {
            // Kakao vs Google 구분: sessionStorage에 kakao_login 플래그 확인
            const isKakaoLogin = sessionStorage.getItem('kakao_login')
            if (isKakaoLogin === 'true') {
              endpoint = `${API_BASE_URL}/auth/kakao`
              sessionStorage.removeItem('kakao_login')
            }
          }

          const response = await fetch(endpoint, {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
            },
            body: JSON.stringify(requestBody)
          })

          if (response.ok) {
            const data = await response.json()
            localStorage.setItem('access_token', data.access_token)
            localStorage.setItem('refresh_token', data.refresh_token)

            // 로그인 상태 업데이트
            setIsLoggedIn(true)
            fetchUserInfo()
          } else {
            const errorData = await response.json().catch(() => ({ detail: '로그인 실패' }))
            console.error('[OAuth] 로그인 실패:', errorData.detail)
          }
        } catch (err) {
          console.error('[OAuth] Callback 처리 오류:', err)
        } finally {
          setIsProcessingCallback(false)
        }
      }

      handleOAuthCallback()
    }
  }, [isLoggedIn, isProcessingCallback])

  // 앱 시작 시 토큰 검증 및 자동 로그인
  useEffect(() => {
    const initializeAuth = async () => {
      const accessToken = localStorage.getItem('access_token')
      const refreshTokenValue = localStorage.getItem('refresh_token')

      // Access Token이 있으면 검증 시도
      if (accessToken) {
        setIsLoggedIn(true)
        // 자동으로 사용자 정보 조회 (만료 시 Refresh Token으로 재발급)
        await fetchUserInfo()
      } else if (refreshTokenValue) {
        // Access Token은 없지만 Refresh Token이 있으면 재발급 시도
        await refreshToken()
      } else {
        // 둘 다 없으면 로그아웃 상태
        setIsLoggedIn(false)
        setUser(null)
      }
    }

    initializeAuth()
  }, []) // 마운트 시 한 번만 실행

  // localStorage 변경 감지하여 로그인 상태 동기화
  useEffect(() => {
    const checkLoginStatus = () => {
      const hasToken = !!localStorage.getItem('access_token')
      if (hasToken !== isLoggedIn) {
        setIsLoggedIn(hasToken)
        if (hasToken) {
          fetchUserInfo()
        } else {
          setUser(null)
        }
      }
    }

    // storage 이벤트 리스너 (다른 탭에서 로그인/로그아웃 시)
    window.addEventListener('storage', checkLoginStatus)

    // 주기적으로 체크 (같은 탭에서 localStorage 변경 감지)
    const interval = setInterval(checkLoginStatus, 1000)

    return () => {
      window.removeEventListener('storage', checkLoginStatus)
      clearInterval(interval)
    }
  }, [isLoggedIn])

  // 로그인 상태 확인 및 사용자 정보 로드
  useEffect(() => {
    if (isLoggedIn) {
      fetchUserInfo()
    }
  }, [isLoggedIn])

  // 로그인은 선택사항이므로 항상 메인 화면 표시 (테스트 중)

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
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', width: '100%' }}>
          <div>
            <h1>💜 감정 분석 AI</h1>
            <p>갱년기 여성을 위한 감정 공감 서비스</p>
          </div>
           <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
             {isLoggedIn && user && (
               <div style={{ textAlign: 'right' }}>
                 <div style={{ fontWeight: '500', color: '#374151' }}>{user.nickname}</div>
                 <div style={{ fontSize: '0.875rem', color: '#6b7280' }}>{user.email}</div>
               </div>
             )}
             {isLoggedIn && (
               <button
                 onClick={async () => {
                   const token = localStorage.getItem('access_token')
                   console.log('🔐 Access Token:', token ? `${token.substring(0, 50)}...` : '없음')
                   console.log('📋 Full Token:', token)

                   // 실제 API 호출로 토큰 전달 확인
                   try {
                     const response = await fetch(`${API_BASE_URL}/auth/me`, {
                       headers: {
                         'Authorization': `Bearer ${token}`
                       }
                     })
                     console.log('✅ API 응답 상태:', response.status)
                     if (response.ok) {
                       const userData = await response.json()
                       console.log('✅ 사용자 정보:', userData)
                       alert(`✅ 토큰 정상 전달됨!\n\n사용자: ${userData.nickname}\n이메일: ${userData.email}`)
                     } else {
                       console.error('❌ API 오류:', response.status)
                       alert(`❌ 토큰 전달 실패 (${response.status})`)
                     }
                   } catch (err) {
                     console.error('❌ 요청 오류:', err)
                     alert('❌ 요청 실패: ' + err.message)
                   }
                 }}
                 style={{
                   padding: '8px 16px',
                   backgroundColor: '#10b981',
                   color: 'white',
                   border: 'none',
                   borderRadius: '8px',
                   cursor: 'pointer',
                   fontSize: '0.875rem',
                   fontWeight: '500'
                 }}
               >
                 토큰 확인
               </button>
             )}
             {!isLoggedIn ? (
               <button
                 onClick={() => setShowLoginModal(true)}
                 style={{
                   padding: '8px 16px',
                   backgroundColor: '#6366f1',
                   color: 'white',
                   border: 'none',
                   borderRadius: '8px',
                   cursor: 'pointer',
                   fontSize: '0.875rem',
                   fontWeight: '500'
                 }}
               >
                 로그인
               </button>
             ) : (
               <button
                 onClick={handleLogout}
                 style={{
                   padding: '8px 16px',
                   backgroundColor: '#ef4444',
                   color: 'white',
                   border: 'none',
                   borderRadius: '8px',
                   cursor: 'pointer',
                   fontSize: '0.875rem',
                   fontWeight: '500'
                 }}
               >
                 로그아웃
               </button>
             )}
           </div>
        </div>
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
          <DailyMoodCheck user={user} />
        )}
      </div>

      {showLoginModal && (
        <div
          style={{
            position: 'fixed',
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            backgroundColor: 'rgba(0, 0, 0, 0.5)',
            display: 'flex',
            justifyContent: 'center',
            alignItems: 'center',
            zIndex: 1000
          }}
          onClick={() => setShowLoginModal(false)}
        >
          <div
            onClick={(e) => e.stopPropagation()}
            style={{
              /* ▼▼▼ 기존의 400px 제한과 흰 배경을 모두 없앴습니다 ▼▼▼ */
              width: '100%',  /* 이제 내용물 크기만큼 시원하게 늘어납니다 */
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              justifyContent: 'center'
            }}
          >
            {/* 로그인 컴포넌트가 이제 자유롭게 크기를 가집니다 */}
            <Login onLoginSuccess={handleLoginSuccess} />

            <button
              onClick={() => setShowLoginModal(false)}
              style={{
                marginTop: '16px',
                padding: '10px 30px',
                backgroundColor: 'white',
                color: '#374151',
                border: 'none',
                borderRadius: '8px',
                cursor: 'pointer',
                fontSize: '1rem',
                fontWeight: 'bold',
                boxShadow: '0 4px 6px rgba(0,0,0,0.1)' // 닫기 버튼이 잘 보이게 그림자 추가
              }}
            >
              닫기
            </button>
          </div>
        </div>
      )}
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

