// src/pages/MenopauseSurveyPage.jsx
import React, { useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import { submitMenopauseSurvey } from "../api/menopauseSurvey";
import LoginPage from "./LoginPage";
import "./MenopauseSurveyPage.css";

/**
 * 질문 정의
 * - riskWhenYes: true  => "맞다"가 갱년기 위험 쪽
 * - riskWhenYes: false => "아니다"가 갱년기 위험 쪽
 */
const FEMALE_QUESTIONS = [
  {
    code: "F1",
    text: "일의 집중력이나 기억력이 예전 같지 않다고 느낀다.",
    riskWhenYes: true,
  },
  {
    code: "F2",
    text: "아무 이유 없이 짜증이 늘고 감정 기복이 심해졌다.",
    riskWhenYes: true,
  },
  {
    code: "F3",
    text: "잠을 잘 이루지 못하거나 수면에 문제가 있다.",
    riskWhenYes: true,
  },
  {
    code: "F4",
    text: "얼굴이 달아오르거나 갑작스러운 열감(홍조)을 자주 느낀다.",
    riskWhenYes: true,
  },
  {
    code: "F5",
    text: "가슴 두근거림, 식은땀, 이유 없는 불안감을 느끼는 편이다.",
    riskWhenYes: true,
  },
  {
    code: "F6",
    text: "관절통, 근육통 등 몸 여기저기가 자주 쑤시거나 아프다.",
    riskWhenYes: true,
  },
  {
    code: "F7",
    text: "성욕이 감소했거나 성관계가 예전보다 불편하게 느껴진다.",
    riskWhenYes: true,
  },
  {
    code: "F8",
    text: "체중 증가나 체형 변화(뱃살 증가 등)가 눈에 띈다.",
    riskWhenYes: true,
  },
  {
    code: "F9",
    text: "예전보다 우울하고 의욕이 떨어진 느낌이 자주 든다.",
    riskWhenYes: true,
  },
  {
    code: "F10",
    text: "일상생활이 버겁게 느껴지고 작은 일에도 쉽게 지친다.",
    riskWhenYes: true,
  },
];

const MALE_QUESTIONS = [
  {
    code: "M1",
    text: "예전보다 쉽게 피로해지고 회복이 더딘 편이다.",
    riskWhenYes: true,
  },
  {
    code: "M2",
    text: "근력이나 체력이 눈에 띄게 떨어졌다고 느낀다.",
    riskWhenYes: true,
  },
  {
    code: "M3",
    text: "성욕이나 성 기능이 예전보다 감소했다.",
    riskWhenYes: true,
  },
  {
    code: "M4",
    text: "짜증이나 분노가 늘고 사소한 일에도 예민해진다.",
    riskWhenYes: true,
  },
  {
    code: "M5",
    text: "웬일인지 의욕이 없고 무기력한 기분이 자주 든다.",
    riskWhenYes: true,
  },
  {
    code: "M6",
    text: "집중력 저하나 건망증이 심해진 것 같다.",
    riskWhenYes: true,
  },
  {
    code: "M7",
    text: "밤에 자주 깨거나 깊은 잠을 자기 어렵다.",
    riskWhenYes: true,
  },
  {
    code: "M8",
    text: "심장 두근거림, 식은땀, 발열 같은 증상을 경험한다.",
    riskWhenYes: true,
  },
  {
    code: "M9",
    text: "복부 비만, 체중 증가 등 체형 변화가 눈에 띄게 느껴진다.",
    riskWhenYes: true,
  },
  {
    code: "M10",
    text: "삶에 대한 자신감이나 의욕이 예전보다 줄었다.",
    riskWhenYes: true,
  },
];

const STEP = {
  INTRO: "intro",
  GENDER: "gender",
  QUESTIONS: "questions",
  RESULT: "result",
};

function MenopauseSurveyPage() {
  const navigate = useNavigate();

  // // ✅ 로그인 안 되어 있으면 바로 로그인 페이지로 돌려보내기
  // const accessToken = localStorage.getItem("access_token");
  // if (!accessToken) {
  //   alert("로그인 후에 설문을 진행해 주세요.");
  //   return <LoginPage />;
  // }

  const [step, setStep] = useState(STEP.INTRO);
  const [gender, setGender] = useState(null); // "FEMALE" | "MALE"
  const [currentIndex, setCurrentIndex] = useState(0);
  const [answers, setAnswers] = useState([]);
  const [submitting, setSubmitting] = useState(false);
  const [result, setResult] = useState(null);

  const questions = useMemo(() => {
    if (gender === "MALE") return MALE_QUESTIONS;
    if (gender === "FEMALE") return FEMALE_QUESTIONS;
    return [];
  }, [gender]);

  const totalQuestions = questions.length;
  const currentQuestion =
    totalQuestions > 0 ? questions[currentIndex] : null;
  const currentAnswer = answers[currentIndex] || null;

  const progressPercent =
    step === STEP.QUESTIONS && totalQuestions > 0
      ? Math.round(((currentIndex + 1) / totalQuestions) * 100)
      : 0;

  const displayGenderLabel =
    gender === "MALE" ? "남성" : gender === "FEMALE" ? "여성" : "";

  /* ---------- 핸들러들 ---------- */

  const handleIntroStart = () => {
    setStep(STEP.GENDER);
  };

  const handleIntroSkip = () => {
    localStorage.setItem("menopause_onboarding_done", "true");
    localStorage.setItem("menopauseSurveySkip", "true");
    navigate("/dashboard");
  };

  const handleSelectGender = (selectedGender) => {
    setGender(selectedGender);
    setCurrentIndex(0);
    setAnswers([]);
    setResult(null);
    setStep(STEP.QUESTIONS);
  };

  const submitSurveyToBackend = async (finalAnswers) => {
    try {
      setSubmitting(true);

      const payload = {
        gender: gender === "MALE" ? "MALE" : "FEMALE",
        // is_risk, choice는 백엔드로 안 보냄
        answers: finalAnswers.map(({ is_risk, choice, ...rest }) => rest),
      };

      const res = await submitMenopauseSurvey(payload);
      setResult(res);
      localStorage.setItem("menopause_survey_completed", "true");
      localStorage.setItem("menopause_onboarding_done", "true");
      setStep(STEP.RESULT);
    } catch (err) {
      console.error(err);
      alert("설문 저장 중 오류가 발생했습니다.");
    } finally {
      setSubmitting(false);
    }
  };

  const handleAnswer = async (choice) => {
    if (!currentQuestion || submitting) return;

    const { code, text, riskWhenYes } = currentQuestion;

    const isYes = choice === "YES";
    const isRisk = (isYes && riskWhenYes) || (!isYes && !riskWhenYes);

    const answerValue = isRisk ? 3 : 0;
    const answerLabel = isYes ? "맞다" : "아니다";

    const answerObj = {
      question_code: code,
      question_text: text,
      answer_value: answerValue,
      answer_label: answerLabel,
      is_risk: isRisk,
      choice,
    };

    const nextAnswers = [...answers];
    nextAnswers[currentIndex] = answerObj;
    setAnswers(nextAnswers);

    if (currentIndex >= totalQuestions - 1) {
      await submitSurveyToBackend(nextAnswers);
    } else {
      setCurrentIndex((prev) => prev + 1);
    }
  };

  const handlePrev = () => {
    if (submitting) return;

    if (currentIndex === 0) {
      setStep(STEP.GENDER);
      return;
    }
    setCurrentIndex((prev) => prev - 1);
  };

  const handleFinish = () => {
    navigate("/dashboard");
  };

  /* ---------- JSX ---------- */

  return (
    <div className="mb-landing">
      <div className="mb-mobile-frame">
        {/* 상단 헤더 */}
        <header className="mb-header">
          {step === STEP.INTRO && (
            <>
              <p className="mb-header__eyebrow">마음봄 갱년기 온보딩</p>
              <h1 className="mb-header__title">나도 혹시 갱년기일까?</h1>
              <p className="mb-header__desc">
                몇 가지 가벼운 문항으로 지금 나의 변화를 함께 살펴봐요.
              </p>
            </>
          )}

          {step === STEP.GENDER && (
            <>
              <p className="mb-header__eyebrow">1단계 · 기본 정보</p>
              <h1 className="mb-header__title">성별을 선택해 주세요.</h1>
              <p className="mb-header__desc">
                성별에 따라 갱년기 양상과 설문 문항이 조금씩 달라집니다.
              </p>
            </>
          )}

          {step === STEP.QUESTIONS && (
            <>
              <p className="mb-header__eyebrow">
                {displayGenderLabel} 갱년기 라이트 자가 체크
              </p>
              <h1 className="mb-header__title">
                최근 몇 달 사이의 나를 떠올리며 솔직하게 선택해 주세요.
              </h1>
              <p className="mb-header__desc">
                최근 나의 상태와 가장 가까운 쪽을 선택해 주세요.
              </p>
            </>
          )}

          {step === STEP.RESULT && (
            <>
              <p className="mb-header__eyebrow">갱년기 신호 요약</p>
              <h1 className="mb-header__title">지금 나의 몸과 마음 상태는?</h1>
            </>
          )}
        </header>

        {/* INTRO STEP */}
        {step === STEP.INTRO && (
          <section className="mb-card mb-card--intro">
            <p className="mb-intro-text">
              아래 설문은 Menopause Rating Scale, Greene Climacteric
              Scale, MENQOL-K, AMS 등 갱년기 증상을 평가하는 연구용 설문에서
              공통으로 다루는 증상 영역을 참고해, 마음봄이
              <br />
              <strong>라이트 버전으로 재구성한 자가 체크 도구</strong>입니다.
            </p>
            <p className="mb-intro-disclaimer">
              이 결과는 <strong>의학적 진단이 아니라</strong> 현재 상태를
              가볍게 점검해 보는 참고용이며, 실제 진단과 치료는 반드시
              전문 의료진과의 상담을 통해 이루어져야 합니다.
            </p>

            <div className="mb-nav-row mb-nav-row--intro">
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
        )}

        {/* GENDER STEP */}
        {step === STEP.GENDER && (
          <section className="mb-card mb-card--gender">
            <p className="mb-gender-subtitle">체크할 대상 선택</p>
            <div className="mb-gender-grid">
              <button
                type="button"
                className="mb-gender-card"
                onClick={() => handleSelectGender("FEMALE")}
              >
                <div className="mb-gender-icon mb-gender-icon--female">♀</div>
                <div>
                  <div className="mb-gender-label">여성</div>
                  <p className="mb-gender-desc">
                    안면홍조, 수면, 기분 변화 등 대표적인 여성 갱년기 증상을
                    중심으로 체크합니다.
                  </p>
                </div>
              </button>
              <button
                type="button"
                className="mb-gender-card"
                onClick={() => handleSelectGender("MALE")}
              >
                <div className="mb-gender-icon mb-gender-icon--male">♂</div>
                <div>
                  <div className="mb-gender-label">남성</div>
                  <p className="mb-gender-desc">
                    성욕 변화, 피로감, 기분·집중력 저하 등 남성 갱년기에서 자주
                    나타나는 변화를 살펴봅니다.
                  </p>
                </div>
              </button>
            </div>
          </section>
        )}

        {/* QUESTIONS STEP */}
        {step === STEP.QUESTIONS && currentQuestion && (
          <section className="mb-card mb-card--survey">
            <div className="mb-progress">
              <div className="mb-progress__label">
                <span className="mb-step">
                  Q{currentIndex + 1} / {totalQuestions}
                </span>
                <span className="mb-percent">{progressPercent}%</span>
              </div>
              <div className="mb-progress__track">
                <div
                  className="mb-progress__fill"
                  style={{ width: `${progressPercent}%` }}
                />
              </div>
            </div>

            <div className="mb-question">
              <p className="mb-question__eyebrow">
                {displayGenderLabel} 갱년기 라이트 체크
              </p>
              <p className="mb-question__text">{currentQuestion.text}</p>
            </div>

            <div className="mb-answer-row">
              <button
                type="button"
                className={
                  "mb-chip" +
                  (currentAnswer?.choice === "YES" ? " mb-chip--active" : "")
                }
                onClick={() => handleAnswer("YES")}
                disabled={submitting}
              >
                맞다
              </button>
              <button
                type="button"
                className={
                  "mb-chip" +
                  (currentAnswer?.choice === "NO" ? " mb-chip--active" : "")
                }
                onClick={() => handleAnswer("NO")}
                disabled={submitting}
              >
                아니다
              </button>
            </div>

            <div className="mb-nav-row">
              <button
                type="button"
                className="mb-btn mb-btn--ghost"
                onClick={handlePrev}
                disabled={submitting}
              >
                이전
              </button>
            </div>
          </section>
        )}

        {/* RESULT STEP */}
        {step === STEP.RESULT && result && (
          <section className="mb-card mb-card--result">
            <div className="mb-result-top">
              <span className="mb-result-badge">
                {result.risk_level === "LOW" && "안정"}
                {result.risk_level === "MID" && "주의"}
                {result.risk_level === "HIGH" && "집중 케어 필요"}
              </span>
              <p className="mb-result-title">
                총점 {result.total_score}점, 위험도 {result.risk_level}
              </p>
              <p className="mb-result-desc">{result.comment}</p>
            </div>

            <p className="mb-result-desc">
              이 결과는 참고용이며, 증상이 지속되거나 일상에 불편을 줄 경우
              전문 의료진과의 상담을 권장드립니다.
            </p>

            <div className="mb-nav-row mb-nav-row--result">
              <button
                type="button"
                className="mb-btn mb-btn--primary-outline"
                onClick={handleFinish}
                disabled={submitting}
              >
                마음봄 계속 이용하기
              </button>
            </div>
          </section>
        )}
      </div>
    </div>
  );
}

export default MenopauseSurveyPage;
