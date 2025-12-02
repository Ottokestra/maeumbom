// src/pages/SignupSurveyPage.jsx
import { useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import './SignupSurveyPage.css'

const API_BASE_URL = 'http://localhost:8000'

// 남/여 갱년기 관련 문항 풀
const ALL_QUESTIONS = [
  // 남성
  {
    id: 'm1',
    gender: '남성',
    text: '최근 성적 관심이나 욕구가 눈에 띄게 줄었다.',
  },
  {
    id: 'm2',
    gender: '남성',
    text: '예전보다 체력이나 지구력이 많이 떨어진 느낌이다.',
  },
  {
    id: 'm3',
    gender: '남성',
    text: '일상에 대한 의욕과 재미가 예전만 못하다.',
  },
  {
    id: 'm4',
    gender: '남성',
    text: '쉽게 우울해지거나 이유 없이 불안한 때가 잦다.',
  },
  // 여성
  {
    id: 'w1',
    gender: '여성',
    text: '갑작스러운 열감이나 안면홍조가 자주 올라온다.',
  },
  {
    id: 'w2',
    gender: '여성',
    text: '잠이 잘 오지 않거나, 자주 깨는 편이다.',
  },
  {
    id: 'w3',
    gender: '여성',
    text: '평소보다 예민해지고, 기분 기복이 심한 편이다.',
  },
  {
    id: 'w4',
    gender: '여성',
    text: '관절통·근육통 같은 몸의 뻐근함이 자주 느껴진다.',
  },
]

// 성별별 랜덤 N개 뽑기
const pickRandomQuestionsByGender = (gender, count = 4) => {
  const pool = ALL_QUESTIONS.filter((q) => q.gender === gender)
  const shuffled = [...pool].sort(() => Math.random() - 0.5)
  return shuffled.slice(0, count)
}

const getRiskLabel = (yesCount) => {
  if (yesCount <= 1) return '가볍게 체크된 수준이에요.'
  if (yesCount === 2)
    return '몇 가지 변화가 보여요. 몸 신호를 한 번 더 살펴보면 좋아요.'
  if (yesCount === 3)
    return '변화가 제법 뚜렷해요. 전문의 상담을 고려해 보셔도 좋아요.'
  return '여러 항목에서 신호가 보여요. 가까운 병원이나 전문가 상담을 꼭 받아보세요.'
}

const getRiskLevel = (yesCount) => {
  if (yesCount <= 1) return 'LOW'
  if (yesCount === 2) return 'MID'
  return 'HIGH'
}

const RISK_COLORS = {
  LOW: {
    badge: '#5b8c5b',
    bg: '#f0f9f1',
  },
  MID: {
    badge: '#c5535a',
    bg: '#fbe9eb',
  },
  HIGH: {
    badge: '#c5535a',
    bg: '#fbe9eb',
  },
}

const ProgressBar = ({ current, total }) => {
  const percent = total === 0 ? 0 : ((current + 1) / total) * 100
  return (
    <div className="mb-progress">
      <div className="mb-progress__label">
        <span className="mb-step">
          {current + 1} / {total}
        </span>
      </div>
      <div className="mb-progress__track">
        <div className="mb-progress__fill" style={{ width: `${percent}%` }} />
      </div>
    </div>
  )
}

const ChoiceChip = ({ label, active, onClick }) => (
  <button
    type="button"
    className={`mb-chip ${active ? 'mb-chip--active' : ''}`}
    onClick={onClick}
  >
    {label}
  </button>
)

function SignupSurveyPage() {
  const navigate = useNavigate()

  // step: 'intro' | 'gender' | 'survey'
  const [step, setStep] = useState('intro')

  const [gender, setGender] = useState(null) // '남성' | '여성'
  const [questions, setQuestions] = useState([])
  const [currentIndex, setCurrentIndex] = useState(0)
  const [answers, setAnswers] = useState({})
  const [finished, setFinished] = useState(false)

  const yesCount = useMemo(
    () =>
      Object.values(answers).reduce(
        (sum, v) => (v === 'YES' ? sum + 1 : sum),
        0
      ),
    [answers]
  )

  const riskLevel = getRiskLevel(yesCount)
  const riskColor = RISK_COLORS[riskLevel]

  const handleIntroStart = () => {
    setStep('gender')
  }

  const handleIntroSkip = () => {
    // 나중에 마이페이지 등 별도 경로가 생기면 이 부분만 수정하면 됨
    navigate('/')
  }

  const handleSelectGender = (g) => {
    setGender(g)
    setQuestions(pickRandomQuestionsByGender(g, 4))
    setCurrentIndex(0)
    setAnswers({})
    setFinished(false)
    setStep('survey')
  }

  const handleSelect = (questionId, value) => {
    setAnswers((prev) => ({ ...prev, [questionId]: value }))
  }

  const handleNext = () => {
    const current = questions[currentIndex]
    if (!current || !answers[current.id]) return

    if (currentIndex === questions.length - 1) {
      setFinished(true)
    } else {
      setCurrentIndex((prev) => prev + 1)
    }
  }

  const handlePrev = () => {
    if (currentIndex === 0) return
    setCurrentIndex((prev) => prev - 1)
  }

  const handleRestart = () => {
    if (!gender) return
    setQuestions(pickRandomQuestionsByGender(gender, 4))
    setCurrentIndex(0)
    setAnswers({})
    setFinished(false)
    setStep('survey')
  }

  /**
   * 설문 완료 버튼 클릭 시:
   * 1) 백엔드에 완료 정보 전송 (/api/onboarding/menopause-survey)
   * 2) localStorage 에 완료 플래그 저장 -> 다음부터는 자동 온보딩 안 뜨게
   * 3) 메인 화면으로 이동
   */
  const handleFinishSurvey = async () => {
    try {
      const token = localStorage.getItem('access_token')

      if (token) {
        await fetch(`${API_BASE_URL}/api/onboarding/menopause-survey`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${token}`,
          },
          body: JSON.stringify({
            gender,
            answers,
            yes_count: yesCount,
            risk_level: riskLevel,
          }),
        })
      }
    } catch (e) {
      console.error('설문 완료 저장 실패:', e)
    } finally {
      // 이 기기에서는 설문 완료로 처리
      localStorage.setItem('menopause_survey_completed', 'true')
      navigate('/')
    }
  }

  // -------------------------
  // 0단계: 인트로 화면
  // -------------------------
  if (step === 'intro') {
    return (
      <div className="mb-landing">
        <div className="mb-mobile-frame">
          <header className="mb-header">
            <p className="mb-header__eyebrow">마음봄 갱년기 온보딩</p>
            <h1 className="mb-header__title">나도 혹시 갱년기일까?</h1>
            <p className="mb-header__desc">
              몇 가지 간단한 질문으로 지금 내 몸과 마음의 변화를
              가볍게 살펴볼 수 있어요. 1분 정도면 충분해요.
            </p>
          </header>

          <section className="mb-card">
            <p className="mb-intro-question">
              &lsquo;나도 혹시 갱년기?&rsquo; 설문을 한 번 테스트해
              보시겠어요?
            </p>

            <ul className="mb-intro-bullets">
              <li>성별에 따라 맞춤 문항 4개만 체크해요.</li>
              <li>의료 진단이 아닌, 자기 점검용 참고 결과예요.</li>
              <li>언제든지 마음봄 내에서 다시 진행하실 수 있어요.</li>
            </ul>

            <div className="mb-nav-row">
              <button
                type="button"
                className="mb-btn mb-btn--primary"
                onClick={handleIntroStart}
              >
                해볼게요!
              </button>
              <button
                type="button"
                className="mb-btn mb-btn--ghost"
                onClick={handleIntroSkip}
              >
                아니요, 다음에 할게요
              </button>
            </div>
          </section>
        </div>
      </div>
    )
  }

  // -------------------------
  // 1단계: 성별 선택 화면
  // -------------------------
  if (!gender) {
    return (
      <div className="mb-landing">
        <div className="mb-mobile-frame">
          <header className="mb-header">
            <p className="mb-header__eyebrow">마음봄 갱년기 온보딩</p>
            <h1 className="mb-header__title">
              먼저, 누구의 변화를 살펴볼까요?
            </h1>
            <p className="mb-header__desc">
              아래에서 체크하려는 대상의 성별을 선택해 주세요. 이후에
              나오는 문항은 선택한 성별에 맞게 구성돼요.
            </p>
          </header>

          <section className="mb-card mb-card--gender">
            <p className="mb-gender-subtitle">체크할 대상 선택</p>
            <div className="mb-gender-grid">
              <button
                type="button"
                className="mb-gender-card"
                onClick={() => handleSelectGender('남성')}
              >
                <div className="mb-gender-icon mb-gender-icon--male">♂</div>
                <div className="mb-gender-label">남성</div>
                <p className="mb-gender-desc">
                  기력·지구력·의욕 변화, 무기력감 등을 간단히 점검해요.
                </p>
              </button>

              <button
                type="button"
                className="mb-gender-card"
                onClick={() => handleSelectGender('여성')}
              >
                <div className="mb-gender-icon mb-gender-icon--female">
                  ♀
                </div>
                <div className="mb-gender-label">여성</div>
                <p className="mb-gender-desc">
                  안면홍조·수면·감정기복·통증 등 상태 변화를 살펴봐요.
                </p>
              </button>
            </div>
          </section>
        </div>
      </div>
    )
  }

  if (!questions.length) {
    return null
  }

  const current = questions[currentIndex]

  // -------------------------
  // 2단계: 설문 & 결과 화면
  // -------------------------
  return (
    <div className="mb-landing">
      <div className="mb-mobile-frame">
        {!finished ? (
          <>
            <header className="mb-header">
              <p className="mb-header__eyebrow">마음봄 갱년기 온보딩</p>
              <h1 className="mb-header__title">
                지금 내 몸 상태, 가볍게 체크해볼까요?
              </h1>
              <p className="mb-header__desc">
                아래 문항에 예/아니오로만 응답해 주세요. 결과는 진단이
                아니라, 내 몸과 마음의 변화를 돌아보는 참고 정보로만
                사용돼요.
              </p>
            </header>

            <section className="mb-card">
              <ProgressBar
                current={currentIndex}
                total={questions.length}
              />

              <div className="mb-question-meta">
                <span className="mb-tag">{gender} 갱년기 관련</span>
              </div>

              <div className="mb-question-body">
                <div className="mb-question-index">
                  <span>{currentIndex + 1}</span>
                </div>
                <div className="mb-question-text">{current.text}</div>
              </div>

              <div className="mb-choice-row">
                <ChoiceChip
                  label="예"
                  active={answers[current.id] === 'YES'}
                  onClick={() => handleSelect(current.id, 'YES')}
                />
                <ChoiceChip
                  label="아니오"
                  active={answers[current.id] === 'NO'}
                  onClick={() => handleSelect(current.id, 'NO')}
                />
              </div>

              <div className="mb-nav-row">
                <button
                  type="button"
                  className="mb-btn mb-btn--ghost"
                  onClick={handlePrev}
                  disabled={currentIndex === 0}
                >
                  이전
                </button>
                <button
                  type="button"
                  className="mb-btn mb-btn--primary"
                  onClick={handleNext}
                  disabled={!answers[current.id]}
                >
                  {currentIndex === questions.length - 1
                    ? '결과 보기'
                    : '다음'}
                </button>
              </div>
            </section>
          </>
        ) : (
          <>
            <header className="mb-header">
              <p className="mb-header__eyebrow">결과 요약</p>
              <h1 className="mb-header__title">
                응답을 기반으로 이렇게 정리했어요.
              </h1>
              <p className="mb-header__desc">
                자기 점검일 뿐이니, 결과에 너무 매달릴 필요는 없어요. 다만
                몸의 신호를 한 번 더 챙겨보는 계기로 삼아보면 좋겠어요.
              </p>
            </header>

            <section
              className="mb-card mb-card--result"
              style={{ backgroundColor: riskColor.bg }}
            >
              <div className="mb-result-top">
                <span
                  className="mb-result-badge"
                  style={{ backgroundColor: riskColor.badge }}
                >
                  {gender} · YES {yesCount}개 / NO{' '}
                  {questions.length - yesCount}개
                </span>
                <p className="mb-result-title">
                  {riskLevel === 'LOW' &&
                    '현재로서는 가벼운 체크 수준이에요.'}
                  {riskLevel === 'MID' &&
                    '몇 가지 변화가 뚜렷하게 느껴져요.'}
                  {riskLevel === 'HIGH' &&
                    '여러 문항에서 갱년기 신호가 보여요.'}
                </p>
                <p className="mb-result-desc">{getRiskLabel(yesCount)}</p>
              </div>

              <div className="mb-result-list">
                {questions.map((q, idx) => (
                  <div key={q.id} className="mb-result-item">
                    <div className="mb-result-item__left">
                      <span className="mb-result-number">{idx + 1}</span>
                      <span className="mb-result-text">{q.text}</span>
                    </div>
                    <span
                      className={`mb-result-chip ${
                        answers[q.id] === 'YES'
                          ? 'mb-result-chip--yes'
                          : 'mb-result-chip--no'
                      }`}
                    >
                      {answers[q.id] === 'YES' ? '예' : '아니오'}
                    </span>
                  </div>
                ))}
              </div>

              <div className="mb-nav-row mb-nav-row--result">
                <button
                  type="button"
                  className="mb-btn mb-btn--ghost"
                  onClick={handleRestart}
                >
                  같은 성별로 다시 해보기
                </button>
                <button
                  type="button"
                  className="mb-btn mb-btn--primary-outline"
                  onClick={handleFinishSurvey}
                >
                  마음봄 계속 이용하기
                </button>
              </div>
            </section>
          </>
        )}
      </div>
    </div>
  )
}

export default SignupSurveyPage
