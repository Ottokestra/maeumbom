import React from "react";

export default function WeeklyEmotionReportCard() {
  return (
    <div className="report-card">
      <div className="report-header">
        <span className="report-subtitle">이번 주 정리 · ~</span>
        <h3>이번 주 감정 리포트</h3>
      </div>
      <p className="report-summary">
        데모용 컴포넌트입니다. 백엔드 /api/reports/emotion/weekly API를 연결하면
        캐릭터와 말풍선 리포트가 이 영역에 표현되도록 확장할 수 있습니다.
      </p>
    </div>
  );
}
