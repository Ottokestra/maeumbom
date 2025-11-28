import { useEffect, useMemo, useState } from 'react'

const RISK_COLORS = {
  LOW: {
    background: '#f0f9f4',
    text: '#146c43',
    accent: '#22c55e',
  },
  MID: {
    background: '#fff7e6',
    text: '#92400e',
    accent: '#f59e0b',
  },
  HIGH: {
    background: '#fff2e7',
    text: '#9a3412',
    accent: '#f97316',
  },
}

const EMOJI_POOL = ['😌', '🌿', '💭', '☕', '🌤️', '🍃', '🌷', '🍊', '🧡']

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

const SurveyProgress = ({ current, total, answered }) => {
  const percent = total === 0 ? 0 : Math.round(((current + 1) / total) * 100)

  return (
    <div className="survey-progress">
      <div className="survey-progress__label">
        <span className="survey-progress__step">{current + 1} / {total}</span>
        <span className="survey-progress__hint">{answered}문항 응답 완료</span>
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
  const [errorType, setErrorType] = useState(null)
  const [submitting, setSubmitting] = useState(false)
  const [result, setResult] = useState(null)
  const [currentIndex, setCurrentIndex] = useState(0)

  const answeredCount = useMemo(() => {
    return questions.reduce((count, q) => (answers[q.question_id] ? count + 1 : count), 0)
  }, [answers, questions])

  const allAnswered = questions.length > 0 && answeredCount === questions.length

  const authHeader = () => {
    const token = localStorage.getItem('access_token')
    if (!token) return {}
    return {
      Authorization: `Bearer ${token}`,
    }
  }

  const fetchQuestions = async () => {
    setLoading(true)
    setError('')
    setErrorType(null)
    try {
      const response = await fetch(`${apiBaseUrl}/api/routine-survey/questions`, {
        headers: {
          ...authHeader(),
        },
      })

      if (!response.ok) {
        const detail = await response.json().catch(() => ({}))
        if (response.status === 404) {
          setError('준비 중인 설문이에요. 곧 더 재밌는 질문으로 찾아올게요!')
          setErrorType('inactive')
          return
        }
        throw new Error(detail?.detail || '설문 문항을 불러오지 못했습니다.')
      }

      const data = await response.json()
      setQuestions(data)
      setAnswers({})
      setCurrentIndex(0)
      setStep('intro')
    } catch (err) {
      setError(err.message || '설문 문항을 불러오지 못했습니다.')
      setErrorType('network')
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
      [questionId]: prev[questionId] === value ? undefined : value,
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
          answer_value: answers[question.question_id] || 'N',
        })),
      }

      const response = await fetch(`${apiBaseUrl}/api/routine-survey/submit`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          ...authHeader(),
        },
        body: JSON.stringify(payload),
      })

      if (!response.ok) {
        const detail = await response.json().catch(() => ({}))
        throw new Error(detail?.detail || '제출에 실패했습니다.')
      }

      const data = await response.json()
      setResult(data)
      setStep('result')
    } catch (err) {
      setError(err.message || '제출에 실패했습니다.')
      setErrorType('network')
    } finally {
      setSubmitting(false)
    }
  }

  const handleRestart = () => {
    setAnswers({})
    setResult(null)
    setCurrentIndex(0)
    setStep('survey')
  }

  const handleStart = () => {
    setStep('survey')
    setCurrentIndex(0)
  }

  const handlePrev = () => {
    setCurrentIndex((prev) => Math.max(prev - 1, 0))
  }

  const handleNext = () => {
    setCurrentIndex((prev) => Math.min(prev + 1, questions.length - 1))
  }

  const currentQuestion = questions[currentIndex]
  const riskStyle = getRiskStyle(result?.risk_level)

  const renderQuestion = (question, index) => {
    const emoji = EMOJI_POOL[index % EMOJI_POOL.length]
    const selected = answers[question.question_id]

    return (
      <div key={question.question_id} className="survey-card question-card">
        <SurveyProgress current={index} total={questions.length} answered={answeredCount} />
        <div className="survey-question__header">
          <span className="question-emoji" aria-hidden="true">{emoji}</span>
          <div>
            <p className="survey-eyebrow">오늘의 질문</p>
            <p className="survey-question__title">{question.title}</p>
            {question.description && <p className="survey-question__desc">{question.description}</p>}
          </div>
        </div>
        <div className="survey-chip-row">
          <ChoiceChip
            label="예, 그런 편이에요"
            active={selected === 'Y'}
            onClick={() => handleSelect(question.question_id, 'Y')}
          />
          <ChoiceChip
            label="아니오 / 해당 없음"
            active={selected === 'N'}
            onClick={() => handleSelect(question.question_id, 'N')}
          />
        </div>
      </div>
    )
  }

  return (
    <div className="survey-page survey-shell">
      <header className="survey-hero">
        <div>
          <p className="survey-eyebrow">마음봄 온보딩 1-4-1</p>
          <h1>오늘 마음과 루틴, 가볍게 점검해볼까요?</h1>
          <p className="survey-subtitle">
            5분 정도면 끝나는 간단한 설문이에요. 결과는 진단이 아니라 오늘의 마음 상태를 돌아보는 참고 정보로만 사용돼요.
          </p>
        </div>
        <div className="survey-hero__actions">
          {step === 'intro' ? (
            <button className="survey-primary" onClick={handleStart} disabled={loading}>
              지금 시작하기
            </button>
          ) : (
            <button className="survey-secondary" onClick={handleRestart}>
              다시 설문하기
            </button>
          )}
        </div>
      </header>

      {loading && (
        <div className="survey-card loading-card">
          <div className="loader" aria-hidden="true" />
          <p className="survey-subtitle">오늘의 질문들을 가져오는 중이에요…</p>
          <div className="skeleton-row">
            <span className="skeleton-chip" />
            <span className="skeleton-chip" />
            <span className="skeleton-chip" />
          </div>
        </div>
      )}

      {error && !loading && errorType === 'inactive' && (
        <div className="survey-card empty-card">
          <div className="empty-visual">😴</div>
          <p className="survey-question__title">현재 활성화된 설문이 없습니다.</p>
          <p className="survey-subtitle">준비 중인 설문이에요. 곧 더 재밌는 질문으로 찾아올게요!</p>
          <div className="survey-actions centered">
            <button className="survey-secondary" onClick={fetchQuestions}>
              다시 시도하기
            </button>
          </div>
        </div>
      )}

      {error && !loading && errorType && errorType !== 'inactive' && (
        <div className="survey-card gentle-error">
          <p className="survey-question__title">잠시 연결이 불안정해요.</p>
          <p className="survey-subtitle">새로고침 후 다시 시도해 주세요.</p>
          <div className="survey-actions centered">
            <button className="survey-secondary" onClick={fetchQuestions}>
              다시 시도하기
            </button>
          </div>
        </div>
      )}

      {!loading && !error && step === 'intro' && (
        <div className="survey-card intro-card">
          <p>가볍게 체크해보고 싶은 날, 언제든 다시 시작할 수 있어요.</p>
          <div className="survey-chip-row muted-row">
            <span className="survey-chip muted">예/아니오로 간단히 응답</span>
            <span className="survey-chip muted">오늘 컨디션 확인</span>
            <span className="survey-chip muted">루틴 점검</span>
          </div>
        </div>
      )}

      {!loading && !error && step === 'survey' && currentQuestion && (
        <>
          {renderQuestion(currentQuestion, currentIndex)}

          <div className="survey-actions question-actions">
            <button className="survey-secondary" onClick={handlePrev} disabled={currentIndex === 0}>
              이전
            </button>
            {currentIndex < questions.length - 1 && (
              <button
                className="survey-primary"
                onClick={handleNext}
                disabled={!answers[currentQuestion.question_id]}
              >
                다음
              </button>
            )}
            {currentIndex === questions.length - 1 && (
              <button
                className="survey-primary"
                onClick={handleSubmit}
                disabled={!allAnswered || submitting}
              >
                {submitting ? '제출 중…' : '결과 보기'}
              </button>
            )}
          </div>
        </>
      )}

      {step === 'result' && result && (
        <div
          className="survey-card result-card"
          style={{ backgroundColor: riskStyle.background, borderColor: riskStyle.accent }}
        >
          <div className="survey-result__header">
            <div>
              <p className="survey-eyebrow">오늘의 루틴/마음 상태</p>
              <h2 style={{ color: riskStyle.text }}>전체 점수 {result.total_score}점</h2>
              {result.comment && <p className="survey-result__comment">{result.comment}</p>}
            </div>
            <span
              className="survey-result__pill"
              style={{ color: riskStyle.text, backgroundColor: '#ffffffaa', border: `1px solid ${riskStyle.accent}` }}
            >
              위험도 {result.risk_level}
            </span>
          </div>

          <div className="badge-row">
            <span className="survey-chip accent" style={{ borderColor: riskStyle.accent, color: riskStyle.text }}>
              스트레스 지수 · {result.total_score}
            </span>
            <span className="survey-chip accent" style={{ borderColor: riskStyle.accent, color: riskStyle.text }}>
              에너지 상태 · {result.risk_level}
            </span>
            <span className="survey-chip accent" style={{ borderColor: riskStyle.accent, color: riskStyle.text }}>
              오늘의 루틴 힌트
            </span>
          </div>

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
              메인으로 돌아가기
            </button>
          </div>
        </div>
      )}
    </div>
  )
}

export default SignupSurveyPage
