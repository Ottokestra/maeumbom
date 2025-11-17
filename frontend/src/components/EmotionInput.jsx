import { useState } from 'react'

function EmotionInput({ onAnalyze, onReset, loading }) {
  const [text, setText] = useState('')

  const handleSubmit = (e) => {
    e.preventDefault()
    if (text.trim()) {
      onAnalyze(text)
    }
  }

  const handleReset = () => {
    setText('')
    onReset()
  }

  const sampleTexts = [
    "오늘 정말 기분이 좋아요!",
    "요즘 너무 피곤하고 아무것도 하기 싫어요",
    "가족들에게 자꾸 화를 내게 돼요",
    "밤에 잠을 못 자서 너무 불안해요"
  ]

  const handleSampleClick = (sample) => {
    setText(sample)
  }

  return (
    <div>
      <h2>감정 분석</h2>
      <form onSubmit={handleSubmit}>
        <div className="input-group">
          <textarea
            value={text}
            onChange={(e) => setText(e.target.value)}
            placeholder="당신의 감정을 자유롭게 표현해주세요..."
            disabled={loading}
          />
        </div>
        
        <div className="button-group">
          <button 
            type="submit" 
            className="btn btn-primary"
            disabled={!text.trim() || loading}
          >
            {loading ? '분석 중...' : '감정 분석하기'}
          </button>
          <button 
            type="button" 
            className="btn btn-secondary"
            onClick={handleReset}
            disabled={loading}
          >
            초기화
          </button>
        </div>
      </form>

      <div style={{ marginTop: '1rem' }}>
        <p style={{ fontSize: '0.9rem', color: '#666', marginBottom: '0.5rem' }}>
          샘플 텍스트:
        </p>
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: '0.5rem' }}>
          {sampleTexts.map((sample, index) => (
            <button
              key={index}
              type="button"
              onClick={() => handleSampleClick(sample)}
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

export default EmotionInput

