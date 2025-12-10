import { useNavigate } from 'react-router-dom'
import './EmotionReportPage.css'

export default function ChatPage() {
  const navigate = useNavigate()

  return (
    <div className="emotion-report-page">
      <div className="emotion-report-surface" style={{ alignItems: 'center', textAlign: 'center' }}>
        <h1 className="report-title">봄이와 대화하기</h1>
        <p className="state-text">대화 화면이 여기에 연결됩니다.</p>
        <button className="primary-button" onClick={() => navigate('/')}>홈으로 돌아가기</button>
      </div>
    </div>
  )
}
