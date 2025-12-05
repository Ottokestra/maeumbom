import { useEffect, useMemo, useState } from "react";
import { apiClient } from "../api/client";
import { getCharacterByKey } from "../utils/emotionCharacters";
import "../styles/menopauseSurvey.css";

export function MenopauseSurveyPage() {
  const [gender, setGender] = useState("FEMALE");
  const [questions, setQuestions] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [currentIndex, setCurrentIndex] = useState(0);
  const [answers, setAnswers] = useState([]);
  const [showSummary, setShowSummary] = useState(false);

  const fetchQuestions = async (selectedGender) => {
    setLoading(true);
    setError(null);
    try {
      const resp = await apiClient.get("/menopause/questions", {
        params: { gender: selectedGender },
      });
      const list = Array.isArray(resp.data)
        ? resp.data.map((item) => ({
            id: item.id,
            questionText: item.question_text,
            characterKey: item.character_key,
            positiveLabel: item.positive_label || "예",
            negativeLabel: item.negative_label || "아니오",
          }))
        : [];
      setQuestions(list);
      setCurrentIndex(0);
      setAnswers([]);
      setShowSummary(false);
    } catch (err) {
      console.error(err);
      setError("잠시 연결이 불안정해요. 나중에 다시 시도해 주세요.");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchQuestions(gender);
  }, [gender]);

  const currentQuestion = useMemo(() => questions[currentIndex], [questions, currentIndex]);
  const progressLabel = useMemo(() => {
    if (!questions.length) return "0 / 0";
    return `${currentIndex + 1} / ${questions.length}`;
  }, [currentIndex, questions.length]);

  const handleAnswer = (value) => {
    const question = currentQuestion;
    if (!question) return;

    setAnswers((prev) => {
      const filtered = prev.filter((item) => item.id !== question.id);
      return [...filtered, { ...question, answer: value }];
    });

    if (currentIndex < questions.length - 1) {
      setCurrentIndex((idx) => idx + 1);
    } else {
      setShowSummary(true);
      // TODO: 응답 저장 API가 준비되면 여기에서 전체 응답 배열을 POST 합니다.
    }
  };

  const handlePrev = () => {
    if (currentIndex > 0) {
      setCurrentIndex((idx) => idx - 1);
    }
  };

  const handleSkip = () => {
    if (currentIndex < questions.length - 1) {
      setCurrentIndex((idx) => idx + 1);
    } else {
      setShowSummary(true);
    }
  };

  const retry = () => fetchQuestions(gender);

  const renderQuestionCard = () => {
    if (loading) {
      return <div className="info-card">문항을 불러오는 중이에요...</div>;
    }

    if (error) {
      return (
        <div className="info-card error">
          <p>{error}</p>
          <button className="primary-btn" onClick={retry}>
            다시 시도
          </button>
        </div>
      );
    }

    if (!currentQuestion) {
      return <div className="info-card">준비된 문항이 없어요.</div>;
    }

    const character = getCharacterByKey(currentQuestion.characterKey) || {
      emoji: "🐹",
      label: "봄이",
    };

    return (
      <div className="question-card">
        <div className="character-row">
          <div className="character-badge" aria-label={character.label}>
            <span className="emoji" role="img" aria-hidden>
              {character.emoji}
            </span>
            <div className="character-name">{character.label}</div>
          </div>
          <div className="speech-bubble">
            <p>"{currentQuestion.questionText}"</p>
          </div>
        </div>

        <div className="answer-row">
          <button className="answer-btn yes" onClick={() => handleAnswer(true)}>
            {currentQuestion.positiveLabel || "예"}
          </button>
          <button className="answer-btn no" onClick={() => handleAnswer(false)}>
            {currentQuestion.negativeLabel || "아니오"}
          </button>
        </div>

        <div className="nav-row">
          <button className="ghost-btn" onClick={handlePrev} disabled={currentIndex === 0}>
            이전
          </button>
          <div className="progress">{progressLabel}</div>
          <button className="ghost-btn" onClick={handleSkip}>
            {currentIndex === questions.length - 1 ? "건너뛰고 종료" : "건너뛰기"}
          </button>
        </div>
      </div>
    );
  };

  const renderSummary = () => {
    const positiveCount = answers.filter((item) => item.answer).length;
    return (
      <div className="summary-card">
        <h3>오늘 너의 컨디션은 이래요</h3>
        <p className="muted">
          아직 답변 저장 API 연동 전입니다. 아래 선택 내용을 검토 후 저장 로직을 추가해주세요.
        </p>
        <div className="summary-list">
          {answers.map((item) => (
            <div key={item.id} className="summary-item">
              <div className="summary-question">{item.questionText}</div>
              <div className={`pill ${item.answer ? "yes" : "no"}`}>
                {item.answer ? item.positiveLabel || "예" : item.negativeLabel || "아니오"}
              </div>
            </div>
          ))}
        </div>
        <div className="summary-footer">
          <div className="score">Yes 응답 {positiveCount} / {questions.length}</div>
          <button className="primary-btn" onClick={() => setShowSummary(false)}>
            다시 돌아가기
          </button>
        </div>
      </div>
    );
  };

  return (
    <div className="survey-page">
      <header className="survey-header">
        <div>
          <p className="eyebrow">갱년기 자가테스트</p>
          <h1>봄이와 함께 컨디션 체크</h1>
          <p className="description">
            캐릭터와 말풍선으로 하나씩 문항을 확인하세요. 성별은 임시 셀렉트에서 선택하며, 추후 회원
            정보에서 자동으로 가져오도록 TODO를 남겨두었습니다.
          </p>
        </div>
        <div className="gender-select">
          <label>성별 선택 (임시)</label>
          <select
            value={gender}
            onChange={(e) => {
              setGender(e.target.value);
              // TODO: 추후 회원 프로필 기반으로 gender 값을 자동 설정합니다.
            }}
          >
            <option value="FEMALE">여성</option>
            <option value="MALE">남성</option>
          </select>
        </div>
      </header>

      <main className="survey-main">
        <div className="card-stage">
          {!showSummary && renderQuestionCard()}
          {showSummary && renderSummary()}
        </div>
        <aside className="helper-panel">
          <div className="helper-card">
            <h3>사용 시나리오</h3>
            <ol>
              <li>관리자는 /admin/menopause-questions 에서 문항을 등록/수정/삭제합니다.</li>
              <li>사용자는 이 화면에서 캐릭터와 함께 한 문항씩 읽으며 예/아니오로 답변합니다.</li>
              <li>마지막에 선택 내용을 확인하고, 추후 마련될 답변 저장 API와 연동해 결과를 저장합니다.</li>
            </ol>
          </div>
        </aside>
      </main>
    </div>
  );
}
