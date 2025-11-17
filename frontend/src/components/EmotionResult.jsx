function EmotionResult({ result }) {
  const emotionLabels = {
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

  const emotionColors = {
    joy: '#FFD700',
    calmness: '#87CEEB',
    sadness: '#4682B4',
    anger: '#DC143C',
    anxiety: '#FF8C00',
    loneliness: '#9370DB',
    fatigue: '#708090',
    confusion: '#DDA0DD',
    guilt: '#8B4513',
    frustration: '#B22222'
  }

  const primaryEmotionLabel = emotionLabels[result.primary_emotion] || result.primary_emotion

  return (
    <div className="result-section">
      <h2>분석 결과</h2>
      
      <div className="primary-emotion">
        <h3>주요 감정</h3>
        <div className="emotion-name">{primaryEmotionLabel}</div>
        <div className="intensity">{result.primary_percentage}%</div>
      </div>

      <div className="emotion-bars">
        {Object.entries(result.emotions)
          .sort((a, b) => b[1] - a[1])
          .map(([emotion, percentage]) => (
            <div key={emotion} className="emotion-bar">
              <div className="emotion-label">
                <strong>{emotionLabels[emotion]}</strong>
                <span>{percentage}%</span>
              </div>
              <div className="bar-container">
                <div 
                  className="bar-fill"
                  style={{
                    width: `${percentage}%`,
                    background: emotionColors[emotion] || '#667eea'
                  }}
                >
                  {percentage > 10 && `${percentage}%`}
                </div>
              </div>
            </div>
          ))}
      </div>
    </div>
  )
}

export default EmotionResult

