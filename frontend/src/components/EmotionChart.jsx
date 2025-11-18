function EmotionChart({ emotions, rawDistribution }) {
  // 새로운 형식 (rawDistribution) 처리
  if (rawDistribution && Array.isArray(rawDistribution)) {
    const sortedEmotions = rawDistribution
      .filter(item => item.score > 0.01)  // 1% 이상만
      .sort((a, b) => b.score - a.score)
      .slice(0, 10)  // 상위 10개만
    
    if (sortedEmotions.length === 0) {
      return (
        <div>
          <h2>감정 분포</h2>
          <div style={{ marginTop: '1.5rem', textAlign: 'center', color: '#999' }}>
            표시할 감정 데이터가 없습니다.
          </div>
        </div>
      )
    }

    const maxPercentage = 100

    return (
      <div>
        <h2>감정 분포 (17개 감정 군집)</h2>
        <div style={{ marginTop: '1.5rem' }}>
          <svg width="100%" height="400" viewBox="0 0 400 400">
            {sortedEmotions.map((item, index) => {
              const percentage = Math.round(item.score * 100)
              const barHeight = (percentage / maxPercentage) * 300
              const barWidth = 60
              const spacing = 100
              const x = 40 + index * spacing
              const y = 350 - barHeight
              const color = item.group === 'positive' ? '#4CAF50' : '#F44336'

              return (
                <g key={item.code}>
                  {/* Bar */}
                  <rect
                    x={x}
                    y={y}
                    width={barWidth}
                    height={barHeight}
                    fill={color}
                    opacity="0.8"
                    rx="6"
                  />
                  
                  {/* Value label */}
                  <text
                    x={x + barWidth / 2}
                    y={y - 5}
                    textAnchor="middle"
                    fontSize="12"
                    fill="#333"
                    fontWeight="bold"
                  >
                    {percentage}%
                  </text>
                  
                  {/* Emotion label */}
                  <text
                    x={x + barWidth / 2}
                    y={370}
                    textAnchor="middle"
                    fontSize="11"
                    fill="#333"
                    fontWeight="600"
                  >
                    {item.name_ko}
                  </text>
                </g>
              )
            })}
            
            {/* Y-axis */}
            <line x1="30" y1="50" x2="30" y2="350" stroke="#ccc" strokeWidth="1" />
            
            {/* Y-axis labels */}
            {[0, 25, 50, 75, 100].map((value) => {
              const y = 350 - (value / maxPercentage) * 300
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
          상위 {sortedEmotions.length}개 감정 비율
        </div>
      </div>
    )
  }

  // 기존 형식 (emotions 객체) 처리
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

  // emotions가 없거나 null/undefined인 경우 처리
  if (!emotions || typeof emotions !== 'object') {
    return (
      <div>
        <h2>감정 분포</h2>
        <div style={{ marginTop: '1.5rem', textAlign: 'center', color: '#999' }}>
          감정 데이터가 없습니다.
        </div>
      </div>
    )
  }

  // Sort emotions by percentage
  const sortedEmotions = Object.entries(emotions)
    .filter(([emotion, percentage]) => percentage > 0)  // 0%인 감정 제외
    .sort((a, b) => b[1] - a[1])

  const maxPercentage = 100

  // 감정 데이터가 없는 경우
  if (sortedEmotions.length === 0) {
    return (
      <div>
        <h2>감정 분포</h2>
        <div style={{ marginTop: '1.5rem', textAlign: 'center', color: '#999' }}>
          표시할 감정 데이터가 없습니다.
        </div>
      </div>
    )
  }

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

