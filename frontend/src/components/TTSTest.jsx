import { useState, useRef } from 'react'

function TTSTest() {
  const [text, setText] = useState('오늘 하루 많이 힘드셨죠.')
  const [tone, setTone] = useState('senior_calm')
  const [speed, setSpeed] = useState(1.0)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState(null)
  const [audioUrl, setAudioUrl] = useState(null)
  
  const audioRef = useRef(null)

  const tones = [
    { value: 'senior_calm', label: '차분한 어머니 톤' },
    { value: 'sad', label: '슬픔' },
    { value: 'angry', label: '화남' },
    { value: 'happy', label: '기쁨' },
    { value: 'neutral', label: '중립' }
  ]

  const handleSynthesize = async () => {
    if (!text.trim()) {
      setError('텍스트를 입력해주세요')
      return
    }

    setLoading(true)
    setError(null)
    setAudioUrl(null)

    // 기존 오디오 정리
    if (audioRef.current) {
      audioRef.current.pause()
      audioRef.current = null
    }
    if (audioUrl) {
      URL.revokeObjectURL(audioUrl)
    }

    try {
      const response = await fetch('http://localhost:8000/api/tts', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          text: text.trim(),
          tone: tone,
          speed: speed,
          engine: 'melo'
        })
      })

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({ detail: 'TTS 생성 실패' }))
        throw new Error(errorData.detail || `HTTP ${response.status}`)
      }

      // 오디오 데이터 받기
      const blob = await response.blob()
      const url = URL.createObjectURL(blob)
      setAudioUrl(url)

      // 자동 재생
      const audio = new Audio(url)
      audioRef.current = audio
      await audio.play()
    } catch (err) {
      console.error('TTS 오류:', err)
      setError(`TTS 생성 실패: ${err.message}`)
    } finally {
      setLoading(false)
    }
  }

  const handlePlay = () => {
    if (audioRef.current) {
      audioRef.current.play()
    }
  }

  const handlePause = () => {
    if (audioRef.current) {
      audioRef.current.pause()
    }
  }

  const handleDownload = () => {
    if (audioUrl) {
      const a = document.createElement('a')
      a.href = audioUrl
      a.download = `tts_${Date.now()}.wav`
      document.body.appendChild(a)
      a.click()
      document.body.removeChild(a)
    }
  }

  const sampleTexts = [
    '오늘 하루 많이 힘드셨죠.',
    '요즘 너무 피곤하고 아무것도 하기 싫어요.',
    '가족들에게 자꾸 화를 내게 돼요.',
    '밤에 잠을 못 자서 너무 불안해요.',
    '오늘 정말 기분이 좋아요!'
  ]

  return (
    <div className="card">
      <h2>Text-to-Speech 테스트</h2>

      {error && (
        <div style={{
          padding: '0.75rem',
          marginBottom: '1rem',
          backgroundColor: '#ffebee',
          color: '#c62828',
          borderRadius: '8px',
          fontSize: '0.9rem'
        }}>
          {error}
        </div>
      )}

      <div className="input-group">
        <label style={{ 
          display: 'block', 
          marginBottom: '0.5rem', 
          fontWeight: 600,
          color: '#333'
        }}>
          텍스트 입력:
        </label>
        <textarea
          value={text}
          onChange={(e) => setText(e.target.value)}
          placeholder="음성으로 변환할 텍스트를 입력하세요..."
          disabled={loading}
          style={{ minHeight: '100px' }}
        />
      </div>

      <div style={{ marginBottom: '1rem' }}>
        <label style={{ 
          display: 'block', 
          marginBottom: '0.5rem', 
          fontWeight: 600,
          color: '#333'
        }}>
          톤 선택:
        </label>
        <select
          value={tone}
          onChange={(e) => setTone(e.target.value)}
          disabled={loading}
          style={{
            width: '100%',
            padding: '0.75rem',
            border: '2px solid #e0e0e0',
            borderRadius: '8px',
            fontSize: '1rem',
            fontFamily: 'inherit'
          }}
        >
          {tones.map(t => (
            <option key={t.value} value={t.value}>
              {t.label}
            </option>
          ))}
        </select>
      </div>

      <div style={{ marginBottom: '1rem' }}>
        <label style={{ 
          display: 'block', 
          marginBottom: '0.5rem', 
          fontWeight: 600,
          color: '#333'
        }}>
          속도: {speed.toFixed(2)}x
        </label>
        <input
          type="range"
          min="0.5"
          max="2.0"
          step="0.1"
          value={speed}
          onChange={(e) => setSpeed(parseFloat(e.target.value))}
          disabled={loading}
          style={{ width: '100%' }}
        />
        <div style={{ 
          display: 'flex', 
          justifyContent: 'space-between', 
          fontSize: '0.85rem',
          color: '#666',
          marginTop: '0.25rem'
        }}>
          <span>0.5x</span>
          <span>1.0x</span>
          <span>2.0x</span>
        </div>
      </div>

      <div className="button-group" style={{ marginBottom: '1rem' }}>
        <button
          className="btn btn-primary"
          onClick={handleSynthesize}
          disabled={!text.trim() || loading}
        >
          {loading ? '생성 중...' : '🔊 음성 생성'}
        </button>
        {audioUrl && (
          <>
            <button
              className="btn btn-secondary"
              onClick={handlePlay}
            >
              ▶️ 재생
            </button>
            <button
              className="btn btn-secondary"
              onClick={handlePause}
            >
              ⏸️ 일시정지
            </button>
            <button
              className="btn btn-secondary"
              onClick={handleDownload}
            >
              💾 다운로드
            </button>
          </>
        )}
      </div>

      {audioUrl && (
        <div style={{ 
          marginTop: '1rem',
          padding: '1rem',
          backgroundColor: '#f5f5f5',
          borderRadius: '8px'
        }}>
          <audio
            ref={audioRef}
            src={audioUrl}
            controls
            style={{ width: '100%' }}
          />
        </div>
      )}

      <div style={{ marginTop: '1rem' }}>
        <p style={{ 
          fontSize: '0.9rem', 
          color: '#666', 
          marginBottom: '0.5rem',
          fontWeight: 600
        }}>
          샘플 텍스트:
        </p>
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: '0.5rem' }}>
          {sampleTexts.map((sample, index) => (
            <button
              key={index}
              type="button"
              onClick={() => setText(sample)}
              disabled={loading}
              style={{
                padding: '0.5rem 1rem',
                fontSize: '0.85rem',
                background: '#f5f5f5',
                border: '1px solid #ddd',
                borderRadius: '20px',
                cursor: 'pointer',
                transition: 'all 0.2s'
              }}
              onMouseEnter={(e) => {
                if (!loading) {
                  e.target.style.background = '#e0e0e0'
                }
              }}
              onMouseLeave={(e) => {
                e.target.style.background = '#f5f5f5'
              }}
            >
              {sample}
            </button>
          ))}
        </div>
      </div>
    </div>
  )
}

export default TTSTest

