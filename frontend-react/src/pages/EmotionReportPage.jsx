import React, { useEffect, useState } from "react";
import "../styles/emotion-report.css";

const SAMPLE_WEEKLY_REPORT = {
  user_id: 1,
  week_start: "2025-12-02",
  week_end: "2025-12-08",
  summary_title: "기복은 있었지만, 잘 버틴 한 주였어요",
  summary_text:
    "초반에는 비교적 가볍고 즐거운 감정이 많았지만, 주중으로 갈수록 피로와 불안이 쌓이는 패턴이 보여요. 그래도 주말에 스스로를 돌보려고 노력한 흔적이 보여서 아주 좋아요.",
  dominant_emotion: "기쁨 + 피로",
  character_bubble: {
    character_name: "봄이",
    mood: "cheerful",
    message:
      "이번 주에도 정말 잘 버텼어! 😊\n특히 주말에는 네가 스스로를 잘 돌봐준 게 느껴져.",
  },
  daily_scores: [
    {
      date: "2025-12-02",
      main_emotion: "기쁨",
      score: 0.8,
      subtitle: "가볍게 웃는 일이 많았어요.",
    },
    {
      date: "2025-12-03",
      main_emotion: "기쁨",
      score: 0.7,
      subtitle: "일은 많았지만 잘 버텼어요.",
    },
    {
      date: "2025-12-04",
      main_emotion: "불안",
      score: 0.6,
      subtitle: "내일이 조금 걱정됐던 날이에요.",
    },
    {
      date: "2025-12-05",
      main_emotion: "피곤",
      score: 0.4,
      subtitle: "몸이 많이 피곤했어요.",
    },
    {
      date: "2025-12-06",
      main_emotion: "우울",
      score: 0.3,
      subtitle: "마음이 조금 가라앉았어요.",
    },
    {
      date: "2025-12-07",
      main_emotion: "편안",
      score: 0.5,
      subtitle: "차분하고 편안한 하루였어요.",
    },
    {
      date: "2025-12-08",
      main_emotion: "기쁨",
      score: 0.9,
      subtitle: "스스로가 대견했던 하루였어요.",
    },
  ],
  recommendations: [
    {
      type: "routine",
      title: "수면 루틴 한 가지 정해보기",
      content:
        "피로가 몰리는 날에는 잠들기 30분 전에 휴대폰을 내려놓고, 가벼운 스트레칭이나 음악으로 마음을 풀어보면 좋아요.",
    },
    {
      type: "emotion",
      title: "감정 기록 3줄 남기기",
      content:
        "이번 주에 기뻤던 순간 1개, 힘들었던 순간 1개, 그때의 나에게 해주고 싶은 말 1개만 적어보자. 봄이가 다음 주에 같이 정리해줄게요.",
    },
  ],
};

export function EmotionReportPage() {
  const [report, setReport] = useState(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isError, setIsError] = useState(false);

  useEffect(() => {
    const fetchReport = async () => {
      try {
        setIsLoading(true);
        setIsError(false);

        const res = await fetch(
          "http://localhost:8000/api/reports/emotion/weekly?user_id=1",
        );

        if (!res.ok) {
          throw new Error("Failed to fetch weekly emotion report");
        }

        const data = await res.json();
        setReport(data);
      } catch (error) {
        console.error("failed to load emotion report", error);
        setIsError(true);
        setReport(SAMPLE_WEEKLY_REPORT);
      } finally {
        setIsLoading(false);
      }
    };

    fetchReport();
  }, []);

  return (
    <div className="emotion-report-page">
      <div className="emotion-report-card">
        <h2 className="emotion-report-title">이번 주 감정 리포트</h2>

        {isLoading && <p className="emotion-report-loading">리포트를 불러오는 중이에요…</p>}

        {!isLoading && report && (
          <>
            <div className="emotion-report-hero">
              <div className="emotion-report-character">
                <div className="character-avatar">
                  <span className="character-avatar-eyes">봄</span>
                </div>
                <div className="character-name">AI 봄이</div>
              </div>

              <div className="emotion-report-speech-bubble">
                <div className="speech-bubble-text">
                  {report.character_bubble?.message?.split("\n").map((line, idx) => (
                    <p key={idx}>{line}</p>
                  ))}
                </div>
                <div className="speech-bubble-tail" />
              </div>
            </div>

            <div className="emotion-report-summary">
              <h3>{report.summary_title}</h3>
              <p className="summary-dominant">주요 감정: {report.dominant_emotion}</p>
              <p className="summary-text">{report.summary_text}</p>
            </div>

            <div className="emotion-report-daily">
              <h4>일별 감정 흐름</h4>
              <ul className="daily-list">
                {report.daily_scores?.map((day) => (
                  <li key={day.date} className="daily-item">
                    <div className="daily-date">{day.date}</div>
                    <div className="daily-main">
                      <span className="daily-emotion-badge">{day.main_emotion}</span>
                      <div className="daily-bar-wrapper">
                        <div
                          className="daily-bar-fill"
                          style={{ width: `${Math.round(day.score * 100)}%` }}
                        />
                      </div>
                    </div>
                    {day.subtitle && <p className="daily-subtitle">{day.subtitle}</p>}
                  </li>
                ))}
              </ul>
            </div>

            <div className="emotion-report-reco">
              <h4>봄이가 건네는 이번 주 추천</h4>
              <div className="reco-list">
                {report.recommendations?.map((item, idx) => (
                  <div key={idx} className="reco-card">
                    <div className="reco-tag">{item.type}</div>
                    <h5 className="reco-title">{item.title}</h5>
                    <p className="reco-content">{item.content}</p>
                  </div>
                ))}
              </div>
            </div>
          </>
        )}

        {!isLoading && !report && (
          <div className="emotion-report-empty">
            <p>오늘은 아직 데이터가 없어요. 봄이랑 먼저 이야기해볼래?</p>
            <a href="/chat" className="go-chat-button">
              대화하러 가기
            </a>
          </div>
        )}

        {isError && (
          <p className="emotion-report-error">
            실시간 데이터를 불러오지 못해 샘플 리포트를 보여드려요.
          </p>
        )}
      </div>
    </div>
  );
}
