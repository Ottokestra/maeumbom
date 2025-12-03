import { useState, useEffect } from 'react'
import './ScenarioTest.css'

const API_BASE_URL = 'http://localhost:8000/api/service/relation-training'

function ScenarioTest() {
  // 상태 관리
  const [scenarios, setScenarios] = useState([])
  const [selectedCategory, setSelectedCategory] = useState('ALL')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState(null)
  
  // 시나리오 진행 상태
  const [currentScenario, setCurrentScenario] = useState(null)
  const [startImageUrl, setStartImageUrl] = useState(null)
  const [showStartImage, setShowStartImage] = useState(true)
  const [currentNode, setCurrentNode] = useState(null)
  const [currentPath, setCurrentPath] = useState('')
  const [isFinished, setIsFinished] = useState(false)
  const [result, setResult] = useState(null)
  
  // 인증 상태
  const [isLoggedIn, setIsLoggedIn] = useState(false)

  // 로그인 상태 확인
  useEffect(() => {
    const token = localStorage.getItem('access_token')
    setIsLoggedIn(!!token)
  }, [])

  // 시나리오 목록 로드
  useEffect(() => {
    if (isLoggedIn) {
      loadScenarios()
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [selectedCategory, isLoggedIn])

  const loadScenarios = async () => {
    setLoading(true)
    setError(null)
    
    try {
      const token = localStorage.getItem('access_token')
      const categoryParam = selectedCategory !== 'ALL' ? `?category=${selectedCategory}` : ''
      
      const response = await fetch(`${API_BASE_URL}/scenarios${categoryParam}`, {
        headers: {
          'Authorization': `Bearer ${token}`
        }
      })

      if (response.status === 401) {
        setError('로그인이 필요합니다.')
        setIsLoggedIn(false)
        return
      }

      if (!response.ok) {
        throw new Error('시나리오 목록을 불러오는데 실패했습니다.')
      }

      const data = await response.json()
      const scenariosList = data.scenarios || []
      
      // 제목 기준으로 중복 제거 (같은 제목이면 가장 높은 ID만 유지)
      const titleMap = new Map()
      scenariosList.forEach(scenario => {
        const existing = titleMap.get(scenario.title)
        if (!existing || scenario.id > existing.id) {
          titleMap.set(scenario.title, scenario)
        }
      })
      
      const uniqueScenarios = Array.from(titleMap.values()).sort((a, b) => a.id - b.id)
      setScenarios(uniqueScenarios)
    } catch (err) {
      setError(err.message)
      console.error('Load scenarios error:', err)
    } finally {
      setLoading(false)
    }
  }

  const startScenario = async (scenarioId) => {
    setLoading(true)
    setError(null)
    setIsFinished(false)
    setResult(null)
    setCurrentPath('')
    
    try {
      const token = localStorage.getItem('access_token')
      
      const response = await fetch(`${API_BASE_URL}/scenarios/${scenarioId}/start`, {
        headers: {
          'Authorization': `Bearer ${token}`
        }
      })

      if (response.status === 401) {
        setError('로그인이 필요합니다.')
        setIsLoggedIn(false)
        return
      }

      if (!response.ok) {
        throw new Error('시나리오를 시작하는데 실패했습니다.')
      }

      const data = await response.json()
      setCurrentScenario({
        id: data.scenario_id,
        title: data.scenario_title,
        category: data.category
      })
      const imageUrl = data.start_image_url || null
      setStartImageUrl(imageUrl)
      setShowStartImage(false) // 오버레이 제거 - 바로 시나리오 진행 화면으로 이동
      setCurrentNode(data.first_node)
    } catch (err) {
      setError(err.message)
      console.error('Start scenario error:', err)
    } finally {
      setLoading(false)
    }
  }

  const selectOption = async (optionCode) => {
    setLoading(true)
    setError(null)
    
    try {
      const token = localStorage.getItem('access_token')
      
      const requestBody = {
        scenario_id: currentScenario.id,
        current_node_id: currentNode.id,
        selected_option_code: optionCode,
        current_path: currentPath
      }

      const response = await fetch(`${API_BASE_URL}/progress`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(requestBody)
      })

      if (response.status === 401) {
        setError('로그인이 필요합니다.')
        setIsLoggedIn(false)
        return
      }

      if (!response.ok) {
        throw new Error('진행 처리에 실패했습니다.')
      }

      const data = await response.json()
      setCurrentPath(data.current_path)

      if (data.is_finished) {
        // 시나리오 종료
        setIsFinished(true)
        setResult(data.result)
        setCurrentNode(null)
      } else {
        // 다음 노드로 이동
        setCurrentNode(data.next_node)
      }
    } catch (err) {
      setError(err.message)
      console.error('Select option error:', err)
    } finally {
      setLoading(false)
    }
  }

  const resetScenario = () => {
    setCurrentScenario(null)
    setStartImageUrl(null)
    setShowStartImage(true)
    setCurrentNode(null)
    setCurrentPath('')
    setIsFinished(false)
    setResult(null)
    setError(null)
    loadScenarios()
  }

  const handleStartImageClose = () => {
    setShowStartImage(false)
  }

  // 로그인하지 않은 경우
  if (!isLoggedIn) {
    return (
      <div className="scenario-test">
        <div className="login-required">
          <div className="login-required-icon">🔒</div>
          <h2>로그인이 필요합니다</h2>
          <p>시나리오 테스트를 이용하려면 먼저 로그인해주세요.</p>
        </div>
      </div>
    )
  }

  // 시나리오 진행 중 또는 결과 화면
  if (currentScenario) {
    return (
      <div className="scenario-test">
        <div className="scenario-header">
          <div>
            <h2>{currentScenario.title}</h2>
            <span className={`category-badge ${currentScenario.category.toLowerCase()}`}>
              {currentScenario.category === 'TRAINING' ? '관계 개선 훈련' : '공감 드라마'}
            </span>
          </div>
          <button onClick={resetScenario} className="back-button">
            ← 목록으로
          </button>
        </div>

        {/* 시작 이미지 표시 (한 번만) */}
        {showStartImage && startImageUrl && (
          <div className="start-image-overlay" onClick={handleStartImageClose}>
            <div className="start-image-container" onClick={(e) => e.stopPropagation()}>
              <button className="start-image-close" onClick={handleStartImageClose}>×</button>
              <img 
                src={`http://localhost:8000${startImageUrl}`} 
                alt="시나리오 시작 이미지" 
                className="start-image"
                onError={(e) => {
                  console.warn('시작 이미지 로드 실패:', startImageUrl)
                  e.target.style.display = 'none'
                }}
              />
            </div>
          </div>
        )}

        {/* 경로 표시 */}
        {currentPath && (
          <div className="path-display">
            <span className="path-label">선택 경로:</span>
            <span className="path-value">{currentPath.split('-').join(' → ')}</span>
          </div>
        )}

        {/* 에러 표시 */}
        {error && (
          <div className="error-message">
            <strong>오류:</strong> {error}
          </div>
        )}

        {/* 진행 중 화면 */}
        {!isFinished && currentNode && (
          <div className="scenario-progress">
            <div className="situation-card">
              <div className="step-indicator">Step {currentNode.step_level}</div>
              <div className="situation-text">{currentNode.situation_text}</div>
              {currentNode.image_url && (
                <img src={currentNode.image_url} alt="상황 이미지" className="situation-image" />
              )}
            </div>

            <div className="options-container">
              <h3>어떻게 하시겠습니까?</h3>
              <div className="options-grid">
                {currentNode.options.map((option) => {
                  // 괄호 안의 힌트 제거 (예: "(비난)", "(대안)" 등)
                  const cleanText = option.option_text.replace(/\s*\([^)]*\)\s*/g, '').trim();
                  return (
                    <button
                      key={option.id}
                      onClick={() => selectOption(option.option_code)}
                      disabled={loading}
                      className="option-button"
                    >
                      <span className="option-code">{option.option_code}</span>
                      <span className="option-text">{cleanText}</span>
                    </button>
                  );
                })}
              </div>
            </div>
          </div>
        )}

        {/* 결과 화면 */}
        {isFinished && result && (
          <div className="scenario-result">
            <div className="result-card">
              <div className="result-header">
                <h2>🎭 {result.display_title}</h2>
                {result.score !== null && (
                  <div className="score-display">
                    <span className="score-label">점수</span>
                    <span className="score-value">{result.score}</span>
                  </div>
                )}
              </div>

              <div className="result-content">
                {/* 4컷만화 결과 이미지 */}
                {result.image_url && (
                  <div className="result-image-section">
                    <img 
                      src={`http://localhost:8000${result.image_url}`} 
                      alt="결과 4컷만화" 
                      className="result-comic-image"
                      onError={(e) => {
                        console.warn('결과 이미지 로드 실패:', result.image_url)
                        e.target.style.display = 'none'
                      }}
                    />
                  </div>
                )}

                <div className="analysis-section">
                  <h3>분석</h3>
                  <p>{result.analysis_text}</p>
                </div>

                {result.atmosphere_image_type && (
                  <div className="atmosphere-badge">
                    분위기: {getAtmosphereLabel(result.atmosphere_image_type)}
                  </div>
                )}
              </div>

              {/* 통계 표시 (드라마의 경우) */}
              {result.stats && result.stats.length > 0 && (
                <div className="stats-section">
                  <h3>📊 다른 사용자들의 선택</h3>
                  <div className="stats-list">
                    {result.stats.map((stat) => (
                      <div key={stat.result_id} className="stat-item">
                        <div className="stat-header">
                          <span className="stat-title">{stat.display_title}</span>
                          <span className="stat-percentage">{stat.percentage.toFixed(1)}%</span>
                        </div>
                        <div className="stat-bar-container">
                          <div 
                            className="stat-bar" 
                            style={{ width: `${stat.percentage}%` }}
                          />
                        </div>
                        <div className="stat-count">{stat.count}명</div>
                      </div>
                    ))}
                  </div>
                </div>
              )}

              <button onClick={resetScenario} className="restart-button">
                다른 시나리오 하기
              </button>
            </div>
          </div>
        )}

        {/* 로딩 표시 */}
        {loading && (
          <div className="loading-overlay">
            <div className="loading-spinner"></div>
            <p>처리 중...</p>
          </div>
        )}
      </div>
    )
  }

  // Deep Agent 테스트 함수
  const testDeepAgent = async () => {
    const target = prompt('Target을 입력하세요 (HUSBAND, CHILD, FRIEND, COLLEAGUE):', 'HUSBAND')
    if (!target) return

    const topic = prompt('Topic을 입력하세요 (예: 남편이 밥투정을 합니다):', '남편이 밥투정을 합니다')
    if (!topic) return

    setLoading(true)
    setError(null)

    try {
      const token = localStorage.getItem('access_token')
      
      console.log('🤖 Deep Agent 시나리오 생성 시작...')
      console.log('Target:', target)
      console.log('Topic:', topic)

      const response = await fetch(`${API_BASE_URL}/generate-scenario`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          target: target,
          topic: topic
        })
      })

      if (response.status === 401) {
        setError('로그인이 필요합니다.')
        setIsLoggedIn(false)
        return
      }

      if (!response.ok) {
        const errorData = await response.json()
        throw new Error(errorData.detail || '시나리오 생성에 실패했습니다.')
      }

      const result = await response.json()
      console.log('✅ Deep Agent 결과:', result)
      
      alert(`✅ 시나리오 생성 완료!\n\nScenario ID: ${result.scenario_id}\n이미지 수: ${result.image_count}/17\n폴더명: ${result.folder_name}\n\n시나리오 목록을 새로고침합니다.`)
      
      // 목록 새로고침
      loadScenarios()
    } catch (err) {
      setError(err.message)
      console.error('Deep Agent 오류:', err)
      alert(`❌ 오류: ${err.message}`)
    } finally {
      setLoading(false)
    }
  }

  // 시나리오 삭제 함수
  const deleteScenario = async (scenarioId, scenarioTitle) => {
    if (!confirm(`"${scenarioTitle}" 시나리오를 삭제하시겠습니까?\n\n이 작업은 되돌릴 수 없습니다.`)) {
      return
    }

    setLoading(true)
    setError(null)

    try {
      const token = localStorage.getItem('access_token')
      
      const response = await fetch(`${API_BASE_URL}/scenarios/${scenarioId}`, {
        method: 'DELETE',
        headers: {
          'Authorization': `Bearer ${token}`
        }
      })

      if (response.status === 401) {
        setError('로그인이 필요합니다.')
        setIsLoggedIn(false)
        return
      }

      if (response.status === 404) {
        alert('시나리오를 찾을 수 없거나 삭제 권한이 없습니다.')
        return
      }

      if (!response.ok) {
        const errorData = await response.json()
        throw new Error(errorData.detail || '시나리오 삭제에 실패했습니다.')
      }

      const result = await response.json()
      console.log('✅ 삭제 완료:', result)
      
      alert(`✅ "${scenarioTitle}" 시나리오가 삭제되었습니다.`)
      
      // 목록 새로고침
      loadScenarios()
    } catch (err) {
      setError(err.message)
      console.error('삭제 오류:', err)
      alert(`❌ 오류: ${err.message}`)
    } finally {
      setLoading(false)
    }
  }

  // 시나리오 목록 화면
  return (
    <div className="scenario-test">
      <div className="scenario-list-header">
        <h2>인터랙티브 시나리오</h2>
        <p>관계 개선 훈련과 공감 드라마를 체험해보세요</p>
        <button 
          onClick={testDeepAgent} 
          className="primary-btn"
          style={{
            marginTop: '12px',
            padding: '12px 20px',
            background: 'linear-gradient(135deg, #7a5af8, #9c6bff)',
            color: 'white',
            border: 'none',
            borderRadius: '12px',
            fontWeight: '700',
            cursor: 'pointer',
            fontSize: '15px'
          }}
        >
          🤖 Deep Agent 시나리오 생성
        </button>
      </div>

      {/* 카테고리 필터 */}
      <div className="category-filter">
        <button
          onClick={() => setSelectedCategory('ALL')}
          className={`filter-button ${selectedCategory === 'ALL' ? 'active' : ''}`}
        >
          전체
        </button>
        <button
          onClick={() => setSelectedCategory('TRAINING')}
          className={`filter-button ${selectedCategory === 'TRAINING' ? 'active' : ''}`}
        >
          관계 개선 훈련
        </button>
        <button
          onClick={() => setSelectedCategory('DRAMA')}
          className={`filter-button ${selectedCategory === 'DRAMA' ? 'active' : ''}`}
        >
          공감 드라마
        </button>
      </div>

      {/* 에러 표시 */}
      {error && (
        <div className="error-message">
          <strong>오류:</strong> {error}
        </div>
      )}

      {/* 로딩 표시 */}
      {loading && (
        <div className="loading-container">
          <div className="loading-spinner"></div>
          <p>시나리오를 불러오는 중...</p>
        </div>
      )}

      {/* 시나리오 목록 */}
      {!loading && scenarios.length > 0 && (
        <div className="scenarios-grid">
          {scenarios.map((scenario) => (
            <div key={`scenario-${scenario.id}-${scenario.title}`} className="scenario-card">
              {scenario.start_image_url && (
                <div className="scenario-card-image">
                  <img 
                    src={`http://localhost:8000${scenario.start_image_url}`} 
                    alt={scenario.title}
                    onError={(e) => {
                      e.target.style.display = 'none'
                    }}
                  />
                </div>
              )}
              <div className="scenario-card-header">
                <h3>{scenario.title}</h3>
                <span className={`category-badge ${scenario.category.toLowerCase()}`}>
                  {scenario.category === 'TRAINING' ? '훈련' : '드라마'}
                </span>
              </div>
              <div className="scenario-card-body">
                <p className="target-type">대상: {getTargetTypeLabel(scenario.target_type)}</p>
              </div>
              <div className="scenario-card-actions">
                <button
                  onClick={() => startScenario(scenario.id)}
                  className="start-button"
                >
                  시작하기 →
                </button>
                {scenario.user_id !== null && (
                  <button
                    onClick={(e) => {
                      e.stopPropagation()
                      deleteScenario(scenario.id, scenario.title)
                    }}
                    className="delete-button"
                    title="시나리오 삭제"
                  >
                    🗑️
                  </button>
                )}
              </div>
            </div>
          ))}
        </div>
      )}

      {/* 빈 상태 */}
      {!loading && scenarios.length === 0 && (
        <div className="empty-state">
          <div className="empty-state-icon">📝</div>
          <h3>시나리오가 없습니다</h3>
          <p>아직 등록된 시나리오가 없습니다.</p>
          <p className="empty-state-hint">
            백엔드 README를 참고하여 시나리오 데이터를 추가해주세요.
          </p>
        </div>
      )}
    </div>
  )
}

// 헬퍼 함수들
function getTargetTypeLabel(targetType) {
  const labels = {
    'parent': '부모님',
    'friend': '친구',
    'partner': '배우자',
    'child': '자녀',
    'colleague': '동료'
  }
  return labels[targetType] || targetType
}

function getAtmosphereLabel(atmosphereType) {
  const labels = {
    'positive': '긍정적',
    'negative': '부정적',
    'neutral': '중립적'
  }
  return labels[atmosphereType] || atmosphereType
}

export default ScenarioTest

