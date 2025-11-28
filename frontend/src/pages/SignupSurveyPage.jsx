import { useEffect, useMemo, useState } from 'react'

const RISK_COLORS = {
  LOW: {
    background: '#e8f5e9',
    text: '#1b5e20',
    accent: '#22c55e'
  },
  MID: {
    background: '#fff7e6',
    text: '#92400e',
    accent: '#f59e0b'
  },
  HIGH: {
    background: '#fff2e7',
    text: '#9a3412',
    accent: '#f97316'
  }
}

const getRiskStyle = (level) => RISK_COLORS[level?.toUpperCase()] || RISK_COLORS.MID

const ChoiceChip = ({ label, active, onClick }) => {
  return (
    <button
      className={`survey-chip ${active ? 'active' : ''}`}
      type="button"
      onClick={onClick}
    >
      {label}
    </button>
  )
}

const SurveyProgress = ({ current, total }) => {
  const percent = total === 0 ? 0 : Math.round((current / total) * 100)

  return (
    <div className="survey-progress">
      <div className="survey-progress__label">
        {current} / {total} 문항 완료
      </div>
      <div className="survey-progress__bar">
        <div className="survey-progress__bar-fill" style={{ width: `${percent}%` }} />
      </div>
    </div>
  )
}

function SignupSurveyPage({ apiBaseUrl = '' }) {
  const [step, setStep] = useState('intro')
  const [questions, setQuestions] = useState([])
  const [answers, setAnswers] = useState({})
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [submitting, setSubmitting] = useState(false)
  const [result, setResult] = useState(null)

  const answeredCount = useMemo(() => {
    return Object.values(answers).filter(Boolean).length
  }, [answers])

  const allAnswered = questions.length > 0 && answeredCount === questions.length

  const authHeader = () => {
    const token = localStorage.getItem('access_token')
    if (!token) return {}
    return {
      Authorization: `Bearer ${token}`
    }
  }

  const fetchQuestions = async () => {
    setLoading(true)
    setError('')
    try {
      const response = await fetch(`${apiBaseUrl}/api/routine-survey/questions`, {
        headers: {
          ...authHeader()
        }
      })

      if (!response.ok) {
        const detail = await response.json().catch(() => ({}))
        throw new Error(detail?.detail || '설문 문항을 불러오지 못했습니다.')
      }

      const data = await response.json()
      setQuestions(data)
      setAnswers({})
    } catch (err) {
      setError(err.message || '설문 문항을 불러오지 못했습니다.')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchQuestions()
  }, [])

  const handleSelect = (questionId, value) => {
    setAnswers((prev) => ({
      ...prev,
      [questionId]: prev[questionId] === value ? undefined : value
    }))
  }

  const handleSubmit = async () => {
    if (!allAnswered || submitting) return
    setSubmitting(true)
    setError('')

    try {
      const surveyId = questions[0]?.survey_id
      const payload = {
        survey_id: surveyId,
        answers: questions.map((question) => ({
          question_id: question.question_id,
          answer_value: answers[question.question_id] || 'N'
        }))
      }

      const response = await fetch(`${apiBaseUrl}/api/routine-survey/submit`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          ...authHeader()
        },
        body: JSON.stringify(payload)
      })

      if (!response.ok) {
        const detail = await response.json().catch(() => ({}))
        throw new Error(detail?.detail || '제출에 실패했습니다. 다시 시도해주세요.')
      }

      const data = await response.json()
      setResult(data)
      setStep('result')
    } catch (err) {
      setError(err.message || '제출에 실패했습니다.')
    } finally {
      setSubmitting(false)
    }
  }

  const handleRestart = () => {
    setAnswers({})
    setResult(null)
    setStep('survey')
  }

  const riskStyle = getRiskStyle(result?.risk_level)

  return (
    <div className="survey-page">
      <header className="survey-hero">
        <div>
          <p className="survey-eyebrow">마음봄 온보딩 1-4-1</p>
          <h1>오늘 마음과 루틴, 가볍게 점검해볼까요?</h1>
          <p className="survey-subtitle">
            5분 정도면 끝나는 간단한 설문이에요. 결과는 진단이 아니라 오늘의 마음 상태를 돌아보는 참고 정보로만 사용돼요.
          </p>
        </div>
        <div className="survey-hero__actions">
          {step === 'intro' && (
            <button className="survey-primary" onClick={() => setStep('survey')} disabled={loading}>
              지금 시작하기
            </button>
          )}
          {step !== 'intro' && (
            <button className="survey-secondary" onClick={handleRestart}>
              다시 설문하기
            </button>
          )}
        </div>
      </header>

      {loading && (
        <div className="survey-card">
          <div className="survey-loading">문항을 불러오는 중이에요...</div>
        </div>
      )}

      {error && !loading && (
        <div className="survey-card error">
          <p>{error}</p>
          <button className="survey-secondary" onClick={fetchQuestions}>
            다시 시도하기
          </button>
        </div>
      )}

      {!loading && !error && step === 'intro' && (
        <div className="survey-card">
          <p>가볍게 체크해보고 싶은 날, 언제든 다시 시작할 수 있어요.</p>
          <div className="survey-chip-row">
            <span className="survey-chip muted">예/아니오로 간단히 응답</span>
            <span className="survey-chip muted">오늘 컨디션 확인</span>
            <span className="survey-chip muted">루틴 점검</span>
          </div>
        </div>
      )}

      {!loading && !error && step === 'survey' && (
        <>
          <div className="survey-card">
            <SurveyProgress current={answeredCount} total={questions.length} />
            <div className="survey-question-list">
              {questions.map((question) => (
                <div key={question.question_id} className="survey-question">
                  <div className="survey-question__meta">
                    <span className="survey-question__no">Q{question.question_no}</span>
                    <div>
                      <p className="survey-question__title">{question.title}</p>
                      {question.description && <p className="survey-question__desc">{question.description}</p>}
                    </div>
                  </div>
                  <div className="survey-chip-row">
                    <ChoiceChip
                      label="예, 그런 편이에요"
                      active={answers[question.question_id] === 'Y'}
                      onClick={() => handleSelect(question.question_id, 'Y')}
                    />
                    <ChoiceChip
                      label="아니오 / 해당 없음"
                      active={answers[question.question_id] === 'N'}
                      onClick={() => handleSelect(question.question_id, 'N')}
                    />
                  </div>
                </div>
              ))}
            </div>
          </div>

          <div className="survey-actions">
            <button className="survey-primary" onClick={handleSubmit} disabled={!allAnswered || submitting}>
              {submitting ? '제출 중...' : '결과 보기'}
            </button>
            {!allAnswered && (
              <p className="survey-hint">모든 문항에 답변하면 결과를 볼 수 있어요.</p>
            )}
          </div>
        </>
      )}

      {step === 'result' && result && (
        <div className="survey-card" style={{ backgroundColor: riskStyle.background, borderColor: riskStyle.accent }}>
          <div className="survey-result__header">
            <p className="survey-eyebrow">오늘의 마음봄 진단</p>
            <span className="survey-result__pill" style={{ color: riskStyle.text, backgroundColor: '#ffffffaa' }}>
              위험도 {result.risk_level}
            </span>
          </div>
          <h2 style={{ color: riskStyle.text }}>
            전체 점수 {result.total_score}점
          </h2>
          {result.comment && <p className="survey-result__comment">{result.comment}</p>}
          <p className="survey-result__time">측정 시각: {new Date(result.taken_at).toLocaleString('ko-KR')}</p>
          <div className="survey-actions">
            <button className="survey-secondary" onClick={handleRestart}>
              다시 설문하기
            </button>
            <button
              className="survey-primary ghost"
              onClick={() => {
                // TODO: 봄이와 대화 페이지 경로가 확정되면 이동하도록 연결합니다.
                console.log('봄이와 대화 시작하기 클릭')
              }}
            >
              봄이와 대화 시작하기
            </button>
          </div>
        </div>
      )}
    </div>
  )
}

export default SignupSurveyPage
