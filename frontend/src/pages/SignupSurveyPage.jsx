import { useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import './onboarding/SignupSurveyPage.css'

const FEMALE_QUESTIONS = [
  { code: 'F1', text: '일의 집중력이나 기억력이 예전 같지 않다고 느낀다.', riskWhenYes: true },
  { code: 'F2', text: '아무 이유 없이 짜증이 늘고 감정 기복이 심해졌다.', riskWhenYes: true },
  { code: 'F3', text: '잠을 잘 이루지 못하거나 수면에 문제가 있다.', riskWhenYes: true },
  { code: 'F4', text: '얼굴이 달아오르거나 갑작스러운 열감(홍조)을 자주 느낀다.', riskWhenYes: true },
  { code: 'F5', text: '가슴 두근거림, 식은땀, 이유 없는 불안감을 느끼는 편이다.', riskWhenYes: true },
  { code: 'F6', text: '관절통, 근육통 등 몸 여기저기가 자주 쑤시거나 아프다.', riskWhenYes: true },
  { code: 'F7', text: '성욕이 감소했거나 성관계가 예전보다 불편하게 느껴진다.', riskWhenYes: true },
  { code: 'F8', text: '체중 증가나 체형 변화(뱃살 증가 등)가 눈에 띈다.', riskWhenYes: true },
  { code: 'F9', text: '예전보다 우울하고 의욕이 떨어진 느낌이 자주 든다.', riskWhenYes: true },
  { code: 'F10', text: '일상생활이 버겁게 느껴지고 작은 일에도 쉽게 지친다.', riskWhenYes: true },
]

const MALE_QUESTIONS = [
  { code: 'M1', text: '예전보다 쉽게 피로해지고 회복이 더딘 편이다.', riskWhenYes: true },
  { code: 'M2', text: '근력이나 체력이 눈에 띄게 떨어졌다고 느낀다.', riskWhenYes: true },
  { code: 'M3', text: '성욕이나 성 기능이 예전보다 감소했다.', riskWhenYes: true },
  { code: 'M4', text: '짜증이나 분노가 늘고 사소한 일에도 예민해진다.', riskWhenYes: true },
  { code: 'M5', text: '웬일인지 의욕이 없고 무기력한 기분이 자주 든다.', riskWhenYes: true },
  { code: 'M6', text: '집중력 저하나 건망증이 심해진 것 같다.', riskWhenYes: true },
  { code: 'M7', text: '밤에 자주 깨거나 깊은 잠을 자기 어렵다.', riskWhenYes: true },
  { code: 'M8', text: '심장 두근거림, 식은땀, 발열 같은 증상을 경험한다.', riskWhenYes: true },
  { code: 'M9', text: '복부 비만, 체중 증가 등 체형 변화가 눈에 띄게 느껴진다.', riskWhenYes: true },
  { code: 'M10', text: '삶에 대한 자신감이나 의욕이 예전보다 줄었다.', riskWhenYes: true },
]

const STEP = {
  INTRO: 'INTRO',
  GENDER: 'GENDER',
  SURVEY: 'SURVEY',
  RESULT: 'RESULT',
}

function getRiskLevelFromYesCount(yesCount) {
  if (yesCount >= 7) return 'HIGH'
  if (yesCount >= 4) return 'MID'
  return 'LOW'
}

function getRiskCopy(level) {
  if (level === 'HIGH') return '증상이 자주 느껴지고 있어요. 전문가와 상담하거나 검진을 권해요.'
  if (level === 'MID') return '몇 가지 변화가 감지돼요. 생활습관을 살피며 몸을 돌봐 주세요.'
  return '큰 걱정은 없지만 몸과 마음의 신호를 계속 살펴볼게요.'
}

function SignupSurveyPage({ apiBaseUrl = '' }) {
  const [step, setStep] = useState(STEP.INTRO)
  const [gender, setGender] = useState(null)
  const [questions, setQuestions] = useState([])
  const [answers, setAnswers] = useState({})
  const [currentIndex, setCurrentIndex] = useState(0)
  const [submitting, setSubmitting] = useState(false)
  const [result, setResult] = useState(null)

  const navigate = useNavigate()

  const answeredCount = useMemo(
    () => questions.reduce((count, q) => (answers[q.code] ? count + 1 : count), 0),
    [answers, questions]
  )

  const yesCount = useMemo(
    () =>
      questions.reduce((count, q) => {
        if (answers[q.code] === 'yes') return count + 1
        return count
      }, 0),
    [answers, questions]
  )

  const currentQuestion = questions[currentIndex]

  const handleSelectGender = (selectedGender) => {
    setGender(selectedGender)
    const list = selectedGender === '여성' ? FEMALE_QUESTIONS : MALE_QUESTIONS
    setQuestions(list)
    setCurrentIndex(0)
    setAnswers({})
    setStep(STEP.SURVEY)
  }

  const handleAnswer = (value) => {
    if (!currentQuestion) return
    setAnswers((prev) => ({ ...prev, [currentQuestion.code]: value }))
    if (currentIndex < questions.length - 1) {
      setCurrentIndex((idx) => idx + 1)
    }
  }

  const handlePrev = () => {
    setCurrentIndex((idx) => Math.max(0, idx - 1))
  }

  const handleNext = () => {
    setCurrentIndex((idx) => Math.min(questions.length - 1, idx + 1))
  }

  const submitSurvey = async (yes) => {
    const riskLevel = getRiskLevelFromYesCount(yes)
    try {
      setSubmitting(true)
      const token = localStorage.getItem('access_token')
      await fetch(`${apiBaseUrl}/api/onboarding/menopause-survey`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          ...(token ? { Authorization: `Bearer ${token}` } : {}),
        },
        body: JSON.stringify({
          gender,
          answers,
          yes_count: yes,
          risk_level: riskLevel,
        }),
      })
    } catch (err) {
      console.error('failed to submit survey', err)
    } finally {
      setSubmitting(false)
    }
  }

  const handleSubmit = async () => {
    if (answeredCount !== questions.length) return
    const riskLevel = getRiskLevelFromYesCount(yesCount)
    const summary = { yesCount, riskLevel }
    setResult(summary)
    setStep(STEP.RESULT)
    await submitSurvey(yesCount)
  }

  const handleRetake = () => {
    setAnswers({})
    setResult(null)
    setCurrentIndex(0)
    setStep(STEP.SURVEY)
  }

  const handleContinue = () => {
    localStorage.setItem('menopause_onboarding_done', 'true')
    localStorage.setItem('menopause_survey_completed', 'true')
    navigate('/')
  }

  return (
    <div className="mb-page">
      <header className="mb-hero">
        <div>
          <p className="mb-eyebrow">마음봄 온보딩</p>
          <h1 className="mb-title">갱년기 자가테스트</h1>
          <p className="mb-subtitle">모바일 카드 스타일 설문으로 몸과 마음의 신호를 가볍게 점검해보세요.</p>
        </div>
        <div className="mb-hero-actions">
          <button className="mb-ghost" onClick={() => navigate('/')}>마음봄 홈</button>
        </div>
      </header>

      {step === STEP.INTRO && (
        <section className="mb-card mb-intro">
          <div className="mb-intro-copy">
            <p className="mb-badge">4단계 진행</p>
            <h2>어떤 변화가 느껴지시나요?</h2>
            <p>
              간단한 체크리스트로 현재 몸과 마음 상태를 돌아볼 수 있어요. 진단 목적이 아닌 참고용 결과이며,
              원하실 때 언제든 다시 응답할 수 있어요.
            </p>
          </div>
          <div className="mb-intro-actions">
            <button className="mb-primary" onClick={() => setStep(STEP.GENDER)}>
              해볼게요
            </button>
            <button className="mb-ghost" onClick={() => navigate('/')}>다음에 할게요</button>
          </div>
        </section>
      )}

      {step === STEP.GENDER && (
        <section className="mb-card mb-gender">
          <p className="mb-badge">STEP 1 · 성별 선택</p>
          <h2>어떤 성별의 체크리스트를 진행할까요?</h2>
          <div className="mb-gender-grid">
            <button className="mb-gender-card" onClick={() => handleSelectGender('여성')}>
              <span className="mb-gender-emoji" aria-hidden>
                🌷
              </span>
              <strong>여성</strong>
              <small>여성을 위한 10문항</small>
            </button>
            <button className="mb-gender-card" onClick={() => handleSelectGender('남성')}>
              <span className="mb-gender-emoji" aria-hidden>
                🌿
              </span>
              <strong>남성</strong>
              <small>남성을 위한 10문항</small>
            </button>
          </div>
        </section>
      )}

      {step === STEP.SURVEY && currentQuestion && (
        <section className="mb-card mb-question-card">
          <div className="mb-progress">
            <div
              className="mb-progress-fill"
              style={{ width: `${Math.round(((currentIndex + 1) / questions.length) * 100)}%` }}
            />
          </div>
          <div className="mb-progress-label">
            <span>
              {currentIndex + 1} / {questions.length}
            </span>
            <span>{answeredCount}문항 응답 완료</span>
          </div>

          <p className="mb-question-eyebrow">오늘의 질문</p>
          <h3 className="mb-question-text">{currentQuestion.text}</h3>

          <div className="mb-chip-row">
            <button
              className={`mb-chip ${answers[currentQuestion.code] === 'yes' ? 'active' : ''}`}
              onClick={() => handleAnswer('yes')}
            >
              그렇다
            </button>
            <button
              className={`mb-chip ${answers[currentQuestion.code] === 'no' ? 'active' : ''}`}
              onClick={() => handleAnswer('no')}
            >
              아니다
            </button>
          </div>

          <div className="mb-question-actions">
            <button className="mb-ghost" onClick={handlePrev} disabled={currentIndex === 0}>
              이전
            </button>
            {currentIndex < questions.length - 1 && (
              <button className="mb-secondary" onClick={handleNext} disabled={!answers[currentQuestion.code]}>
                다음
              </button>
            )}
            {currentIndex === questions.length - 1 && (
              <button
                className="mb-primary"
                onClick={handleSubmit}
                disabled={answeredCount !== questions.length || submitting}
              >
                {submitting ? '저장 중...' : '결과 보기'}
              </button>
            )}
          </div>
        </section>
      )}

      {step === STEP.RESULT && result && (
        <section className="mb-card mb-result">
          <div className="mb-result-header">
            <div>
              <p className="mb-badge">설문 결과</p>
              <h2>
                체크 {result.yesCount}개 · 위험도 {result.riskLevel}
              </h2>
              <p className="mb-result-copy">{getRiskCopy(result.riskLevel)}</p>
            </div>
            <div className={`mb-risk-pill ${result.riskLevel.toLowerCase()}`}>{result.riskLevel}</div>
          </div>

          <ul className="mb-question-list">
            {questions.map((q) => (
              <li key={q.code}>
                <div className="mb-question-label">
                  <span className="mb-question-code">{q.code}</span>
                  <p>{q.text}</p>
                </div>
                <span className={`mb-answer-pill ${answers[q.code] === 'yes' ? 'yes' : 'no'}`}>
                  {answers[q.code] === 'yes' ? '그렇다' : '아니다'}
                </span>
              </li>
            ))}
          </ul>

          <div className="mb-result-actions">
            <button className="mb-secondary" onClick={handleRetake}>
              같은 성별로 다시 해보기
            </button>
            <button className="mb-primary" onClick={handleContinue}>
              마음봄 계속 이용하기
            </button>
          </div>
        </section>
      )}
    </div>
  )
}

export default SignupSurveyPage
