function EmotionChart({ emotions }) {
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

  // Sort emotions by percentage
  const sortedEmotions = Object.entries(emotions)
    .sort((a, b) => b[1] - a[1])

  const maxPercentage = 100

  return (
    <div>
      <h2>감정 분포</h2>
      <div style={{ marginTop: '1.5rem' }}>
        <svg width="100%" height="300" viewBox="0 0 400 300">
          {sortedEmotions.map(([emotion, percentage], index) => {
            const barHeight = (percentage / maxPercentage) * 200
            const barWidth = 80
            const spacing = 120
            const x = 40 + index * spacing
            const y = 250 - barHeight

            return (
              <g key={emotion}>
                {/* Bar */}
                <rect
                  x={x}
                  y={y}
                  width={barWidth}
                  height={barHeight}
                  fill={emotionColors[emotion]}
                  opacity="0.8"
                  rx="6"
                />
                
                {/* Value label */}
                <text
                  x={x + barWidth / 2}
                  y={y - 5}
                  textAnchor="middle"
                  fontSize="14"
                  fill="#333"
                  fontWeight="bold"
                >
                  {percentage}%
                </text>
                
                {/* Emotion label */}
                <text
                  x={x + barWidth / 2}
                  y={270}
                  textAnchor="middle"
                  fontSize="13"
                  fill="#333"
                  fontWeight="600"
                >
                  {emotionLabels[emotion]}
                </text>
              </g>
            )
          })}
          
          {/* Y-axis */}
          <line x1="30" y1="50" x2="30" y2="250" stroke="#ccc" strokeWidth="1" />
          
          {/* Y-axis labels */}
          {[0, 25, 50, 75, 100].map((value) => {
            const y = 250 - (value / maxPercentage) * 200
            return (
              <g key={value}>
                <line x1="25" y1={y} x2="30" y2={y} stroke="#ccc" strokeWidth="1" />
                <text x="20" y={y + 4} textAnchor="end" fontSize="10" fill="#999">
                  {value}%
                </text>
              </g>
            )
          })}
        </svg>
      </div>
      
      <div style={{ marginTop: '1rem', fontSize: '0.85rem', color: '#666', textAlign: 'center' }}>
        상위 3개 감정 비율 (합계 100%)
      </div>
    </div>
  )
}

export default EmotionChart

