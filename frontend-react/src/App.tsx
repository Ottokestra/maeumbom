import { BrowserRouter, Navigate, Route, Routes, Link } from "react-router-dom";
import { CharacterChatPage } from "./components/CharacterChatPage";
import { EmotionReportPage } from "./pages/EmotionReportPage";
import { MenopauseQuestionAdminPage } from "./pages/MenopauseQuestionAdminPage";
import { MenopauseSurveyPage } from "./pages/MenopauseSurveyPage";
import { PracticeStudioPage } from "./pages/PracticeStudioPage";
import { UserJourneyPage } from "./pages/UserJourneyPage";

function App() {
  return (
    <BrowserRouter>
      <div className="app-shell">
        <nav className="app-nav">
          <Link to="/" className="brand">
            마음봄
          </Link>
          <div className="nav-links">
            <Link to="/">갱년기 자가테스트</Link>
            <Link to="/chat">봄이와 대화</Link>
            <Link to="/journey">온보딩 여정</Link>
            <Link to="/practice">마음연습실</Link>
            <Link to="/emotion-report">감정 리포트</Link>
            {/* TODO: 서비스 오픈 전에는 관리자 메뉴를 숨기거나 별도 보호 처리합니다. */}
            <Link to="/admin/menopause-questions">관리자</Link>
          </div>
        </nav>
        <Routes>
          <Route path="/" element={<MenopauseSurveyPage />} />
          <Route path="/chat" element={<CharacterChatPage />} />
          <Route path="/journey" element={<UserJourneyPage />} />
          <Route path="/practice" element={<PracticeStudioPage />} />
          <Route path="/emotion-report" element={<EmotionReportPage />} />
          <Route path="/admin/menopause-questions" element={<MenopauseQuestionAdminPage />} />
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </div>
    </BrowserRouter>
  );
}

export default App;
