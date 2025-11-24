import { useState, useEffect } from 'react'
import EmotionResult from './EmotionResult'
import './DailyMoodCheck.css'

const API_BASE_URL = 'http://localhost:8000/api/service/daily-mood-check'
const USER_ID = 1 // 테스트용 사용자 ID

function DailyMoodCheck() {
  const [status, setStatus] = useState(null)
  const [images, setImages] = useState([])
  const [selectedImage, setSelectedImage] = useState(null)
  const [emotionResult, setEmotionResult] = useState(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState(null)

  // 체크 상태 확인
  useEffect(() => {
    checkStatus()
    loadImages()
  }, [])

  const checkStatus = async () => {
    try {
      const response = await fetch(`${API_BASE_URL}/status/${USER_ID}`)
      if (response.ok) {
        const data = await response.json()
        setStatus(data)
      }
    } catch (err) {
      console.error('Status check error:', err)
    }
  }

  const loadImages = async () => {
    setLoading(true)
    setError(null)
    try {
      // 캐시 방지를 위해 타임스탬프 추가
      const response = await fetch(`${API_BASE_URL}/images?t=${Date.now()}`, {
        cache: 'no-store'
      })
      if (!response.ok) {
        throw new Error('이미지 로드 실패')
      }
      const data = await response.json()
      setImages(data.images || [])
    } catch (err) {
      setError(err.message)
      console.error('Image load error:', err)
    } finally {
      setLoading(false)
    }
  }

  const handleImageSelect = async (imageId) => {
    if (status?.completed) {
      alert('오늘 이미 체크를 완료했습니다.')
      return
    }

    setLoading(true)
    setError(null)
    setSelectedImage(imageId)

    try {
      const response = await fetch(`${API_BASE_URL}/select`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          user_id: USER_ID,
          image_id: imageId
        })
      })

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({ detail: response.statusText }))
        throw new Error(errorData.detail || '이미지 선택 실패')
      }

      const data = await response.json()
      setEmotionResult(data.emotion_result)
      
      // 상태 업데이트
      checkStatus()
    } catch (err) {
      setError(err.message)
      console.error('Image select error:', err)
    } finally {
      setLoading(false)
    }
  }

  const getSentimentColor = (sentiment) => {
    switch (sentiment) {
      case 'negative':
        return '#ef4444' // 빨간색
      case 'neutral':
        return '#6b7280' // 회색
      case 'positive':
        return '#10b981' // 초록색
      default:
        return '#6366f1'
    }
  }

  const getSentimentLabel = (sentiment) => {
    switch (sentiment) {
      case 'negative':
        return '부정'
      case 'neutral':
        return '중립'
      case 'positive':
        return '긍정'
      default:
        return sentiment
    }
  }

  return (
    <div className="daily-mood-check">
      <div className="card">
        <h2>일일 감정 체크</h2>
        
        {status && (
          <div style={{
            padding: '12px',
            backgroundColor: status.completed ? '#d1fae5' : '#fef3c7',
            borderRadius: '8px',
            marginBottom: '20px',
            border: `1px solid ${status.completed ? '#10b981' : '#f59e0b'}`
          }}>
            <p style={{ margin: 0, fontWeight: 'bold' }}>
              {status.completed 
                ? `✅ 오늘 체크 완료 (${status.last_check_date})`
                : '⏰ 오늘 체크가 필요합니다'}
            </p>
          </div>
        )}

        {error && (
          <div style={{
            padding: '12px',
            backgroundColor: '#fee2e2',
            color: '#991b1b',
            borderRadius: '8px',
            marginBottom: '20px',
            border: '1px solid #fecaca'
          }}>
            <strong>오류:</strong> {error}
          </div>
        )}

        {loading && images.length === 0 && (
          <div style={{ textAlign: 'center', padding: '40px' }}>
            <div className="loading-spinner"></div>
            <p>이미지를 불러오는 중...</p>
          </div>
        )}

        {images.length > 0 && (
          <div>
            <h3 style={{ marginBottom: '20px', textAlign: 'center' }}>오늘의 감정을 선택해주세요</h3>
            <div className="image-grid">
              {images.map((image) => (
                <div
                  key={image.id}
                  className={`image-card ${selectedImage === image.id ? 'selected' : ''} ${status?.completed ? 'disabled' : ''}`}
                  onClick={() => !status?.completed && !loading && handleImageSelect(image.id)}
                  style={{
                    cursor: status?.completed || loading ? 'not-allowed' : 'pointer',
                    opacity: status?.completed ? 0.6 : 1
                  }}
                >
                  {image.url ? (
                    <div style={{
                      width: '100%',
                      height: '500px',
                      backgroundColor: '#f3f4f6',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      borderRadius: '8px 8px 0 0',
                      overflow: 'hidden'
                    }}>
                      <img
                        src={`http://localhost:8000${image.url}?t=${Date.now()}`}
                        alt={image.description}
                        onError={(e) => {
                          const placeholderSvg = 'data:image/svg+xml,%3Csvg xmlns="http://www.w3.org/2000/svg" width="200" height="200"%3E%3Crect width="200" height="200" fill="%23e5e7eb"/%3E%3Ctext x="50%25" y="50%25" text-anchor="middle" dy=".3em" fill="%239ca3af"%3E이미지 없음%3C/text%3E%3C/svg%3E'
                          e.target.src = placeholderSvg
                        }}
                        style={{
                          maxWidth: '100%',
                          maxHeight: '100%',
                          width: 'auto',
                          height: 'auto',
                          objectFit: 'contain',
                          borderRadius: '8px 8px 0 0'
                        }}
                      />
                    </div>
                  ) : (
                    <div style={{
                      width: '100%',
                      height: '200px',
                      backgroundColor: '#e5e7eb',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      borderRadius: '8px 8px 0 0',
                      color: '#9ca3af'
                    }}>
                      이미지 없음
                    </div>
                  )}
                </div>
              ))}
            </div>
          </div>
        )}

        {images.length === 0 && !loading && (
          <div style={{
            padding: '40px',
            textAlign: 'center',
            color: '#6b7280'
          }}>
            <p>이미지를 불러올 수 없습니다.</p>
            <p style={{ fontSize: '0.9rem', marginTop: '10px' }}>
              이미지 파일을 <code>backend/service/daily_mood_check/images/</code> 폴더에 추가해주세요.
            </p>
          </div>
        )}
      </div>

      {emotionResult && (
        <div className="card">
          <h2>감정 분석 결과</h2>
          <EmotionResult result={emotionResult} />
        </div>
      )}

      {loading && selectedImage && (
        <div className="card">
          <div className="loading">
            <div className="loading-spinner"></div>
            <p>감정을 분석하고 있습니다...</p>
          </div>
        </div>
      )}
    </div>
  )
}

export default DailyMoodCheck

