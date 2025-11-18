function EmotionResult({ result }) {
  // 17개 감정 군집 기반 형식 처리
  const isNewFormat = result.primary_emotion && typeof result.primary_emotion === 'object'
  
  // 새로운 형식 (17개 감정 군집)
  let primaryEmotion = null
  let primaryEmotionLabel = '평온'
  let primaryIntensity = 0
  let primaryConfidence = 0
  let sentimentOverall = 'neutral'
  let rawDistribution = []
  let secondaryEmotions = []
  let serviceSignals = null
  
  if (isNewFormat) {
    primaryEmotion = result.primary_emotion
    primaryEmotionLabel = primaryEmotion.name_ko || primaryEmotion.code || '평온'
    primaryIntensity = primaryEmotion.intensity || 0
    primaryConfidence = primaryEmotion.confidence || 0
    sentimentOverall = result.sentiment_overall || 'neutral'
    rawDistribution = result.raw_distribution || []
    secondaryEmotions = result.secondary_emotions || []
    serviceSignals = result.service_signals || {}
  } else {
    // 하위 호환성: 기존 형식
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
    primaryEmotionLabel = emotionLabels[result.primary_emotion] || result.primary_emotion || '평온'
    primaryIntensity = result.percentage || result.primary_percentage || 0
  }
  
  // VA 값 추출 (하위 호환성)
  const valence = result.valence !== undefined ? result.valence : 0
  const arousal = result.arousal !== undefined ? result.arousal : 0
  
  // UI-friendly 라벨 (하위 호환성)
  const moodDirection = result.mood_direction || (sentimentOverall === 'positive' ? '긍정' : sentimentOverall === 'negative' ? '부정' : '중립')
  const emotionIntensity = result.emotion_intensity || (primaryIntensity >= 4 ? '높음' : primaryIntensity >= 2 ? '보통' : '낮음')

  // VA 차원을 2D 좌표로 변환 (0~100% 범위)
  const valencePercent = ((valence + 1) / 2) * 100  // -1~1을 0~100으로 변환
  const arousalPercent = ((arousal + 1) / 2) * 100  // -1~1을 0~100으로 변환

  // Mood direction 색상
  const moodColors = {
    '긍정': '#4CAF50',
    '중립': '#9E9E9E',
    '부정': '#F44336'
  }
  
  // Emotion intensity 색상
  const intensityColors = {
    '높음': '#F44336',
    '보통': '#FF9800',
    '낮음': '#9E9E9E'
  }

  return (
    <div className="result-section">
      <h2>분석 결과</h2>
      
      {/* 새로운 VA + UI-friendly 라벨 형식 (기존 형식일 때만 표시) */}
      {!isNewFormat && result.valence !== undefined && (
        <div className="va-section">
          <h3>감정 차원 분석</h3>
          
          <div className="cluster-info">
            <div className="cluster-badge" style={{ backgroundColor: moodColors[moodDirection] || '#9E9E9E' }}>
              <div className="cluster-label">{primaryEmotionLabel}</div>
              <div className="cluster-id">{moodDirection}</div>
            </div>
            
            <div className="va-values">
              <div className="va-item">
                <span className="va-label">기분 방향 (Mood Direction)</span>
                <span className="va-value">{moodDirection}</span>
                <div className="va-bar">
                  <div 
                    className="va-bar-fill" 
                    style={{ 
                      width: `${valencePercent}%`,
                      backgroundColor: moodColors[moodDirection] || '#9E9E9E'
                    }}
                  />
                </div>
              </div>
              
              <div className="va-item">
                <span className="va-label">감정 강도 (Emotion Intensity)</span>
                <span className="va-value">{emotionIntensity}</span>
                <div className="va-bar">
                  <div 
                    className="va-bar-fill" 
                    style={{ 
                      width: `${arousalPercent}%`,
                      backgroundColor: intensityColors[emotionIntensity] || '#9E9E9E'
                    }}
                  />
                </div>
              </div>
              
              <div className="polarity-badge">
                <span>세부 값: </span>
                <strong>Valence {valence.toFixed(2)}, Arousal {arousal.toFixed(2)}</strong>
              </div>
            </div>
          </div>

          {/* VA 2D 차트 */}
          <div className="va-chart-container">
            <h4>감정 공간 (Valence × Arousal)</h4>
            <div className="va-chart">
              <div className="va-axis-label va-axis-y">고각성</div>
              <div className="va-chart-inner">
                <div className="va-grid">
                  {/* 격자선 */}
                  <div className="va-grid-line va-grid-horizontal" style={{ top: '50%' }}></div>
                  <div className="va-grid-line va-grid-vertical" style={{ left: '50%' }}></div>
                  
                  {/* 좌표축 라벨 */}
                  <div className="va-axis-label va-axis-x-left">불쾌</div>
                  <div className="va-axis-label va-axis-x-right">쾌</div>
                  <div className="va-axis-label va-axis-y-bottom">저각성</div>
                  
                  {/* 감정 점 */}
                  <div 
                    className="va-point"
                    style={{
                      left: `${valencePercent}%`,
                      bottom: `${arousalPercent}%`,
                      backgroundColor: moodColors[moodDirection] || '#9E9E9E'
                    }}
                    title={`${moodDirection} (${emotionIntensity}) - Valence: ${valence.toFixed(2)}, Arousal: ${arousal.toFixed(2)}`}
                  />
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* 17개 감정 군집 형식 */}
      {isNewFormat && (
        <>
          <div className="primary-emotion">
            <h3>주요 감정</h3>
            <div className="emotion-name">{primaryEmotionLabel}</div>
            <div className="intensity">강도: {primaryIntensity}/5 (신뢰도: {(primaryConfidence * 100).toFixed(0)}%)</div>
            <div className="sentiment-overall">
              전반적 감정: {sentimentOverall === 'positive' ? '긍정' : sentimentOverall === 'negative' ? '부정' : '중립'}
            </div>
          </div>

          {/* 보조 감정 */}
          {secondaryEmotions.length > 0 && (
            <div className="secondary-emotions">
              <h4>보조 감정</h4>
              <div className="emotion-list">
                {secondaryEmotions.map((emotion, idx) => (
                  <div key={idx} className="emotion-item">
                    <span className="emotion-name">{emotion.name_ko}</span>
                    <span className="emotion-intensity">강도: {emotion.intensity}/5</span>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* 감정 분포 */}
          {rawDistribution.length > 0 && (
            <div className="emotion-bars">
              <h4>감정 분포</h4>
              {rawDistribution
                .filter(item => item.score > 0.01)  // 1% 이상만 표시
                .sort((a, b) => b.score - a.score)
                .slice(0, 10)  // 상위 10개만
                .map((item, idx) => {
                  const percentage = Math.round(item.score * 100)
                  const color = item.group === 'positive' ? '#4CAF50' : '#F44336'
                  return (
                    <div key={idx} className="emotion-bar">
                      <div className="emotion-label">
                        <strong>{item.name_ko}</strong>
                        <span>{percentage}%</span>
                      </div>
                      <div className="bar-container">
                        <div 
                          className="bar-fill"
                          style={{
                            width: `${percentage}%`,
                            background: color
                          }}
                        >
                          {percentage > 5 && `${percentage}%`}
                        </div>
                      </div>
                    </div>
                  )
                })}
            </div>
          )}

          {/* 서비스 시그널 */}
          {serviceSignals && (
            <div className="service-signals">
              <h4>서비스 추천</h4>
              <div className="signals-list">
                {serviceSignals.need_empathy && <div className="signal-item">💜 공감이 필요합니다</div>}
                {serviceSignals.need_routine_recommend && <div className="signal-item">🏃 루틴 추천이 필요합니다</div>}
                {serviceSignals.need_health_check && <div className="signal-item">🏥 건강 점검이 필요합니다</div>}
                {serviceSignals.need_voice_analysis && <div className="signal-item">🎤 음성 분석이 필요합니다</div>}
                <div className={`risk-level risk-${serviceSignals.risk_level}`}>
                  위험도: {serviceSignals.risk_level === 'critical' ? '심각' : 
                           serviceSignals.risk_level === 'alert' ? '주의' :
                           serviceSignals.risk_level === 'watch' ? '관찰' : '정상'}
                </div>
              </div>
            </div>
          )}
        </>
      )}

      {/* 하위 호환성: 기존 형식 */}
      {!isNewFormat && (
        <>
          <div className="primary-emotion">
            <h3>주요 감정</h3>
            <div className="emotion-name">{primaryEmotionLabel}</div>
            <div className="intensity">{primaryIntensity}%</div>
          </div>

          <div className="emotion-bars">
            {Object.entries(result.top_emotions || result.emotions || {})
              .filter(([emotion, percentage]) => percentage > 0)
              .sort((a, b) => b[1] - a[1])
              .map(([emotion, percentage]) => {
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
                return (
                  <div key={emotion} className="emotion-bar">
                    <div className="emotion-label">
                      <strong>{emotionLabels[emotion] || emotion}</strong>
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
                )
              })}
          </div>
        </>
      )}
    </div>
  )
}

export default EmotionResult

