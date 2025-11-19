import { useState, useEffect, useRef } from 'react'

function STTTest() {
  const [isRecording, setIsRecording] = useState(false)
  const [isConnected, setIsConnected] = useState(false)
  const [transcript, setTranscript] = useState('')
  const [quality, setQuality] = useState(null)
  const [error, setError] = useState(null)
  
  const wsRef = useRef(null)
  const mediaStreamRef = useRef(null)
  const audioContextRef = useRef(null)
  const processorRef = useRef(null)
  const sourceRef = useRef(null)
  const bufferRef = useRef([])
  const isRecordingRef = useRef(false)

  const SAMPLE_RATE = 16000
  const CHUNK_SIZE = 512

  useEffect(() => {
    return () => {
      // 컴포넌트 언마운트 시 정리
      if (wsRef.current) {
        wsRef.current.close()
      }
      if (mediaStreamRef.current) {
        mediaStreamRef.current.getTracks().forEach(track => track.stop())
      }
      if (audioContextRef.current && audioContextRef.current.state !== 'closed') {
        audioContextRef.current.close()
      }
    }
  }, [])

  const connectWebSocket = () => {
    return new Promise((resolve, reject) => {
      try {
        // Vite 프록시를 통해 WebSocket 연결 (HTTPS 페이지에서도 작동)
        const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:'
        const wsUrl = `${protocol}//${window.location.host}/stt/stream`
        console.log('[STT] WebSocket 연결 시도:', wsUrl)
        const ws = new WebSocket(wsUrl)
        wsRef.current = ws

        ws.onopen = () => {
          console.log('[STT] ✅ WebSocket 연결 성공')
          setIsConnected(true)
          setError(null)
          resolve(ws)
        }

      ws.onmessage = (event) => {
        try {
          const data = JSON.parse(event.data)
          console.log('[STT] 📨 메시지 수신:', data)
          
          if (data.status === 'ready') {
            console.log('[STT] ✅ STT 엔진 준비 완료')
            setError(null)
          } else if (data.status === 'reset') {
            console.log('[STT] 🔄 VAD 리셋 완료')
          } else if (data.error) {
            console.error('[STT] ❌ 서버 오류:', data.error)
            setError(`서버 오류: ${data.error}`)
          } else if (data.text !== undefined) {
            // 인식 결과
            console.log('[STT] 📝 인식 결과:', { text: data.text, quality: data.quality })
            setQuality(data.quality)
            if (data.text) {
              setTranscript(prev => {
                // 중복 방지 및 자연스러운 연결
                const newText = prev && !prev.endsWith(' ') && !data.text.startsWith(' ') 
                  ? prev + ' ' + data.text 
                  : prev + data.text
                console.log('[STT] 📝 텍스트 업데이트:', newText)
                return newText
              })
            } else {
              console.log('[STT] ⚠️ 텍스트 없음 (품질:', data.quality, ')')
            }
          }
        } catch (err) {
          console.error('[STT] ❌ 메시지 파싱 오류:', err, '원본:', event.data)
          setError(`메시지 파싱 오류: ${err.message}`)
        }
      }

        ws.onerror = (error) => {
          console.error('[STT] ❌ WebSocket 오류:', error)
          setError('WebSocket 연결 오류 - 브라우저 콘솔을 확인하세요')
          setIsConnected(false)
          reject(error)
        }

        ws.onclose = (event) => {
          console.log('[STT] 🔌 WebSocket 연결 종료:', { code: event.code, reason: event.reason, wasClean: event.wasClean })
          setIsConnected(false)
          if (isRecordingRef.current) {
            // 녹음 중이면 재연결 시도
            console.log('[STT] 🔄 재연결 시도 중...')
            setTimeout(() => {
              if (isRecordingRef.current) {
                connectWebSocket().catch(err => {
                  console.error('[STT] ❌ 재연결 실패:', err)
                  setError(`재연결 실패: ${err.message}`)
                })
              }
            }, 1000)
          }
        }
      } catch (err) {
        console.error('[STT] ❌ WebSocket 연결 실패:', err)
        setError(`WebSocket 연결 실패: ${err.message}`)
        reject(err)
      }
    })
  }

  const startRecording = async () => {
    try {
      console.log('[STT] 🎤 녹음 시작 시도...')
      setError(null)
      setTranscript('')
      setQuality(null)

      // 마이크 권한 요청
      console.log('[STT] 📱 마이크 권한 요청 중...')
      const stream = await navigator.mediaDevices.getUserMedia({
        audio: {
          sampleRate: SAMPLE_RATE,
          channelCount: 1,
          echoCancellation: true,
          noiseSuppression: true
        }
      })
      
      console.log('[STT] ✅ 마이크 권한 획득:', {
        id: stream.id,
        active: stream.active,
        tracks: stream.getTracks().map(t => ({ id: t.id, kind: t.kind, enabled: t.enabled, readyState: t.readyState }))
      })
      
      mediaStreamRef.current = stream

      // WebSocket 연결 (연결 완료 대기)
      console.log('[STT] 🔌 WebSocket 연결 중...')
      await connectWebSocket()
      console.log('[STT] ✅ WebSocket 연결 완료')

      // AudioContext 생성
      console.log('[STT] 🎵 AudioContext 생성 중...')
      const audioContext = new (window.AudioContext || window.webkitAudioContext)({
        sampleRate: SAMPLE_RATE
      })
      console.log('[STT] ✅ AudioContext 생성 완료:', {
        sampleRate: audioContext.sampleRate,
        state: audioContext.state
      })
      audioContextRef.current = audioContext

      // 마이크 입력 소스 생성
      const source = audioContext.createMediaStreamSource(stream)
      sourceRef.current = source
      console.log('[STT] ✅ 오디오 소스 생성 완료')

      // ScriptProcessorNode 생성 (512 샘플 버퍼)
      const processor = audioContext.createScriptProcessor(CHUNK_SIZE, 1, 1)
      processorRef.current = processor

      let chunkCount = 0
      processor.onaudioprocess = (e) => {
        if (!isRecordingRef.current) {
          return
        }

        if (!wsRef.current || wsRef.current.readyState !== WebSocket.OPEN) {
          if (chunkCount % 100 === 0) { // 100번마다 한 번씩만 로그
            console.warn('[STT] ⚠️ WebSocket이 열려있지 않음:', wsRef.current?.readyState)
          }
          return
        }

        const inputData = e.inputBuffer.getChannelData(0)
        
        // Float32Array로 변환 (이미 Float32Array이지만 명시적으로 복사)
        const float32Array = new Float32Array(inputData.length)
        for (let i = 0; i < inputData.length; i++) {
          float32Array[i] = inputData[i]
        }

        // WebSocket으로 전송
        try {
          wsRef.current.send(float32Array.buffer)
          chunkCount++
          if (chunkCount % 100 === 0) { // 100번마다 한 번씩만 로그
            console.log('[STT] 📤 오디오 청크 전송:', chunkCount, '개 (크기:', float32Array.length, '샘플)')
          }
        } catch (err) {
          console.error('[STT] ❌ 오디오 전송 오류:', err)
          setError(`오디오 전송 오류: ${err.message}`)
        }
      }

      source.connect(processor)
      processor.connect(audioContext.destination)
      console.log('[STT] ✅ 오디오 프로세서 연결 완료')

      isRecordingRef.current = true
      setIsRecording(true)
      console.log('[STT] ✅ 녹음 시작 완료!')
    } catch (err) {
      console.error('[STT] ❌ 녹음 시작 오류:', err)
      setError(`녹음 시작 실패: ${err.message} - 브라우저 콘솔을 확인하세요`)
      isRecordingRef.current = false
      setIsRecording(false)
    }
  }

  const stopRecording = () => {
    console.log('[STT] ⏹️ 녹음 중지 중...')
    isRecordingRef.current = false
    setIsRecording(false)

    // 오디오 스트림 정리
    if (mediaStreamRef.current) {
      console.log('[STT] 🔇 오디오 스트림 정리 중...')
      mediaStreamRef.current.getTracks().forEach(track => {
        track.stop()
        console.log('[STT] ✅ 트랙 정지:', track.id)
      })
      mediaStreamRef.current = null
    }

    // AudioContext 정리
    if (processorRef.current) {
      console.log('[STT] 🔌 프로세서 연결 해제 중...')
      processorRef.current.disconnect()
      processorRef.current = null
    }
    if (sourceRef.current) {
      console.log('[STT] 🔌 소스 연결 해제 중...')
      sourceRef.current.disconnect()
      sourceRef.current = null
    }
    if (audioContextRef.current && audioContextRef.current.state !== 'closed') {
      console.log('[STT] 🔌 AudioContext 종료 중...')
      audioContextRef.current.close()
      audioContextRef.current = null
    }

    // WebSocket은 유지 (재연결을 위해)
    if (wsRef.current) {
      console.log('[STT] 🔌 WebSocket 종료 중...')
      wsRef.current.close()
      wsRef.current = null
    }
    
    console.log('[STT] ✅ 녹음 중지 완료')
  }

  const handleReset = () => {
    if (wsRef.current && wsRef.current.readyState === WebSocket.OPEN) {
      wsRef.current.send('reset')
    }
    setTranscript('')
    setQuality(null)
  }

  const getQualityLabel = (quality) => {
    const labels = {
      success: '성공',
      medium: '보통',
      low_quality: '품질 낮음',
      no_speech: '음성 없음'
    }
    return labels[quality] || quality
  }

  const getQualityColor = (quality) => {
    const colors = {
      success: '#4caf50',
      medium: '#ff9800',
      low_quality: '#f44336',
      no_speech: '#9e9e9e'
    }
    return colors[quality] || '#666'
  }

  return (
    <div className="card">
      <h2>Speech-to-Text 테스트</h2>
      
      <div style={{ marginBottom: '1rem' }}>
        <div style={{ 
          display: 'flex', 
          alignItems: 'center', 
          gap: '0.5rem',
          marginBottom: '0.5rem',
          flexWrap: 'wrap'
        }}>
          <div style={{
            width: '12px',
            height: '12px',
            borderRadius: '50%',
            backgroundColor: isConnected ? '#4caf50' : '#f44336'
          }} />
          <span style={{ fontSize: '0.9rem', color: '#666' }}>
            {isConnected ? '연결됨' : '연결 안 됨'}
          </span>
          {isRecording && (
            <>
              <div style={{
                width: '12px',
                height: '12px',
                borderRadius: '50%',
                backgroundColor: '#f44336',
                animation: 'pulse 1.5s ease-in-out infinite'
              }} />
              <span style={{ 
                fontSize: '0.9rem', 
                color: '#f44336',
                fontWeight: 'bold'
              }}>
                🎤 녹음 중...
              </span>
            </>
          )}
        </div>
        {quality && (
          <div style={{ fontSize: '0.9rem', color: getQualityColor(quality) }}>
            품질: {getQualityLabel(quality)}
          </div>
        )}
      </div>

      <style>{`
        @keyframes pulse {
          0%, 100% {
            opacity: 1;
          }
          50% {
            opacity: 0.5;
          }
        }
      `}</style>

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

      <div className="button-group" style={{ marginBottom: '1rem' }}>
        <button
          className={`btn ${isRecording ? 'btn-danger' : 'btn-primary'}`}
          onClick={isRecording ? stopRecording : startRecording}
          disabled={false}
          style={{
            minWidth: '150px',
            position: 'relative'
          }}
        >
          {isRecording ? (
            <>
              <span style={{ 
                display: 'inline-block',
                width: '8px',
                height: '8px',
                borderRadius: '50%',
                backgroundColor: 'white',
                marginRight: '8px',
                animation: 'pulse 1s ease-in-out infinite'
              }} />
              ⏹️ 녹음 중지
            </>
          ) : (
            '🎤 녹음 시작'
          )}
        </button>
        {isRecording && (
          <button
            className="btn btn-secondary"
            onClick={() => {
              console.log('[STT] 🔨 강제 인식 요청')
              if (wsRef.current && wsRef.current.readyState === WebSocket.OPEN) {
                wsRef.current.send('force_process')
              } else {
                setError('WebSocket이 연결되지 않았습니다')
              }
            }}
            disabled={!isConnected}
            style={{
              backgroundColor: '#ff9800',
              color: 'white'
            }}
          >
            🔨 강제 인식
          </button>
        )}
        <button
          className="btn btn-secondary"
          onClick={handleReset}
          disabled={!isConnected || isRecording}
        >
          리셋
        </button>
      </div>

      <div className="input-group">
        <div style={{ 
          display: 'flex', 
          justifyContent: 'space-between',
          alignItems: 'center',
          marginBottom: '0.5rem'
        }}>
          <label style={{ 
            fontWeight: 600,
            color: '#333'
          }}>
            인식된 텍스트:
          </label>
          {transcript && (
            <button
              onClick={() => setTranscript('')}
              style={{
                padding: '0.25rem 0.75rem',
                fontSize: '0.85rem',
                backgroundColor: '#f5f5f5',
                border: '1px solid #ddd',
                borderRadius: '4px',
                cursor: 'pointer'
              }}
            >
              지우기
            </button>
          )}
        </div>
        <textarea
          value={transcript || ''}
          readOnly
          placeholder={isRecording ? "말씀하시면 여기에 텍스트가 표시됩니다..." : "녹음을 시작하면 인식된 텍스트가 여기에 표시됩니다..."}
          style={{
            minHeight: '150px',
            backgroundColor: isRecording ? '#fff' : '#f5f5f5',
            border: isRecording ? '2px solid #4caf50' : '2px solid #e0e0e0',
            transition: 'all 0.3s'
          }}
        />
        {isRecording && !transcript && (
          <div style={{
            marginTop: '0.5rem',
            fontSize: '0.85rem',
            color: '#666',
            fontStyle: 'italic'
          }}>
            💡 마이크에 말씀해주세요. 발화가 끝나면 자동으로 텍스트가 표시됩니다.
          </div>
        )}
      </div>

      <div style={{ 
        marginTop: '1rem', 
        padding: '1rem', 
        backgroundColor: '#f5f5f5', 
        borderRadius: '8px',
        fontSize: '0.85rem',
        color: '#666'
      }}>
        <strong>사용 방법:</strong>
        <ul style={{ marginTop: '0.5rem', paddingLeft: '1.5rem' }}>
          <li>녹음 시작 버튼을 클릭하여 마이크 권한을 허용하세요</li>
          <li>마이크에 말하면 실시간으로 텍스트로 변환됩니다</li>
          <li>2초 이상 침묵하면 자동으로 발화가 종료됩니다</li>
          <li>리셋 버튼으로 VAD를 초기화할 수 있습니다</li>
        </ul>
        <div style={{ 
          marginTop: '1rem', 
          padding: '0.75rem', 
          backgroundColor: '#e3f2fd', 
          borderRadius: '6px',
          border: '1px solid #90caf9'
        }}>
          <strong>🔍 디버깅:</strong> 문제가 발생하면 브라우저 개발자 도구(F12)의 콘솔 탭을 열어 <code>[STT]</code>로 시작하는 로그를 확인하세요.
        </div>
      </div>
    </div>
  )
}

export default STTTest

