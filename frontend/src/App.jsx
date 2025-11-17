import { useState } from 'react'
import EmotionInput from './components/EmotionInput'
import EmotionResult from './components/EmotionResult'
import EmotionChart from './components/EmotionChart'
import './App.css'

function App() {
  const [result, setResult] = useState(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState(null)

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
    } catch (err) {
      setError(err.message)
      console.error('Error:', err)
    } finally {
      setLoading(false)
    }
  }

  const handleReset = () => {
    setResult(null)
    setError(null)
  }

  return (
    <div className="app">
      <header className="header">
        <h1>💜 감정 분석 AI</h1>
        <p>갱년기 여성을 위한 감정 공감 서비스</p>
      </header>

      <div className="main-container">
        <div className="input-section card">
          <EmotionInput 
            onAnalyze={handleAnalyze} 
            onReset={handleReset}
            loading={loading}
          />
          
          {error && (
            <div className="error">
              <strong>오류:</strong> {error}
            </div>
          )}
        </div>

        {loading && (
          <div className="card">
            <div className="loading">
              <div className="loading-spinner"></div>
              <p>감정을 분석하고 있습니다...</p>
            </div>
          </div>
        )}

        {!loading && result && (
          <>
            <div className="card">
              <EmotionResult result={result} />
            </div>
            
            <div className="card">
              <EmotionChart emotions={result.emotions} />
            </div>
            
            {result.similar_contexts && result.similar_contexts.length > 0 && (
              <div className="card contexts-section">
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
          </>
        )}

        {!loading && !result && !error && (
          <div className="card">
            <div className="empty-state">
              <div className="empty-state-icon">💭</div>
              <p>텍스트를 입력하고 분석 버튼을 눌러주세요</p>
            </div>
          </div>
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

