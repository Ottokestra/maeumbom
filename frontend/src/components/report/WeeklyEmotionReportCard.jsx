import { useEffect, useState } from "react";

const API_BASE = import.meta.env.VITE_API_BASE_URL ?? "http://localhost:8000";

export default function WeeklyEmotionReportCard({ onClickCta }) {
  const [report, setReport] = useState(null);
  const [loading, setLoading] = useState(false);
  const [visibleCount, setVisibleCount] = useState(0);

  useEffect(() => {
    let timer;

    async function fetchReport() {
      try {
        setLoading(true);
        const res = await fetch(`${API_BASE}/api/reports/emotion/weekly`, {
          credentials: "include",
        });
        if (!res.ok) {
          throw new Error(`Server error: ${res.status}`);
        }
        const data = await res.json();
        setReport(data);

        if (data.dialog && data.dialog.length > 0) {
          setVisibleCount(1);
          timer = window.setInterval(() => {
            setVisibleCount((prev) => {
              if (prev >= data.dialog.length) {
                if (timer) window.clearInterval(timer);
                return prev;
              }
              return prev + 1;
            });
          }, 700);
        }
      } catch (e) {
        console.error("weekly report error", e);
        setReport(null);
      } finally {
        setLoading(false);
      }
    }

    fetchReport();
    return () => {
      if (timer) window.clearInterval(timer);
    };
  }, []);

  if (loading) {
    return (
      <div className="report-card">
        <p>이번 주 감정 리포트를 불러오는 중이에요...</p>
      </div>
    );
  }

  if (!report || !report.has_data) {
    return (
      <div className="report-card">
        <h3>이번 주 감정 리포트</h3>
        <p>오늘은 아직 데이터가 없어요. 봄이랑 먼저 이야기해볼래?</p>
        {onClickCta && (
          <button className="primary-button" onClick={onClickCta}>
            대화하러 가기
          </button>
        )}
      </div>
    );
  }

  const charactersById = new Map(report.characters.map((c) => [c.id, c]));
  const dialogLines = report.dialog ?? [];

  return (
    <div className="report-card">
      <div className="report-header">
        <span className="report-subtitle">
          이번 주 정리 · {report.date_range?.start} ~ {report.date_range?.end}
        </span>
        <h3>{report.title ?? "이번 주 감정 리포트"}</h3>
      </div>

      {report.summary && <p className="report-summary">{report.summary}</p>}

      <div className="report-dialog-list">
        {dialogLines.slice(0, visibleCount).map((line, idx) => {
          const char = charactersById.get(line.speaker_id);
          const isMain = line.speaker_id === "bomi";

          return (
            <div
              key={idx}
              className={`dialog-row ${isMain ? "left" : "right"}`}
            >
              {isMain && (
                <div className="avatar">
                  <div className="avatar-circle">{char?.name?.[0] ?? "?"}</div>
                </div>
              )}

              <div className="bubble">
                <div className="bubble-name">{char?.name}</div>
                <div className="bubble-text">{line.text}</div>
              </div>

              {!isMain && (
                <div className="avatar">
                  <div className="avatar-circle">{char?.name?.[0] ?? "?"}</div>
                </div>
              )}
            </div>
          );
        })}
      </div>
    </div>
  );
}
