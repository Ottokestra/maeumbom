import { useEffect, useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import CircularGauge from '../components/emotion-report/CircularGauge'
import { API_BASE_URL } from '../config/api'
import './EmotionReportPage.css'

const clamp = (value, min = 0, max = 100) => Math.min(Math.max(value ?? 0, min), max)

const initialState = {
  loading: true,
  error: null,
  data: null,
}

function EmptyStateCard({ title, description, ctaLabel, onClickCta }) {
  return (
    <div className="report-state report-state--empty">
      <div className="state-text-group">
        <p className="state-title">{title}</p>
        <p className="state-subtext">{description}</p>
      </div>
      <button className="primary-button" onClick={onClickCta}>
        {ctaLabel}
      </button>
    </div>
  )
}

function ReportDays({ days = [] }) {
  if (!days.length) return null

  return (
    <div className="report-weekly-row">
      {days.map((day) => (
        <div className="weekly-day" key={`${day.day}-${day.code}`}>
          <span className="weekly-day__label">{day.day}</span>
          <span className="weekly-day__emoji">{day.emoji}</span>
          <span className="weekly-day__name">{day.code}</span>
        </div>
      ))}
    </div>
  )
}

function CoachMessage({ message, emoji, onClickGoChat }) {
  if (!message) return null

  return (
    <section className="coach-message">
      <div className="coach-avatar" aria-hidden>
        {emoji}
      </div>
      <div className="coach-copy">
        <p className="coach-label">봄이의 메모</p>
        <p className="coach-text">{message}</p>
        <button className="ghost-button" onClick={onClickGoChat}>
          봄이랑 더 이야기하기
        </button>
      </div>
    </section>
  )
}

function ReportLayout({ report, onClickGoChat }) {
  const gaugeValue = useMemo(() => clamp(report.temperature), [report.temperature])
  const mainCharacter = {
    emoji: report.main_character_emoji,
    name: report.main_character_name,
  }

  return (
    <div className="report-body">
      <section className="report-hero">
        <div className="report-gauge-card">
          <CircularGauge
            value={gaugeValue}
            label={report.temperature_label}
            color="#f472b6"
            centerContent={<div className="report-main-emoji">{mainCharacter.emoji}</div>}
          />
          <div className="report-gauge-meta">
            <p className="gauge-caption">{mainCharacter.name}</p>
            <p className="gauge-description">이번 주 대표 감정 캐릭터</p>
          </div>
        </div>

        <div className="report-character-card">
          <p className="character-chip">대표 감정 캐릭터</p>
          <div className="character-emoji">{mainCharacter.emoji}</div>
          <p className="character-name">{mainCharacter.name}</p>
          <p className="character-description">{report.title}</p>
        </div>
      </section>

      <section className="report-weekly">
        <div className="section-heading">
          <div>
            <p className="section-caption">요일별 감정 캐릭터</p>
            <h2 className="section-title">한 주를 채운 감정 스티커</h2>
          </div>
          <span className="period-chip">{report.week_label}</span>
        </div>
        <ReportDays days={report.weekly_emotions} />
      </section>

      <CoachMessage message={report.suggestion} emoji={mainCharacter.emoji} onClickGoChat={onClickGoChat} />
    </div>
  )
}

export default function EmotionReportPage({ apiBaseUrl = API_BASE_URL }) {
  const [state, setState] = useState(initialState)
  const navigate = useNavigate()

  useEffect(() => {
    async function fetchReport() {
      try {
        const res = await fetch(`${apiBaseUrl}/reports/emotion/weekly`)
        if (!res.ok) {
          throw new Error(`status ${res.status}`)
        }
        const json = await res.json()
        setState({ loading: false, error: null, data: json })
      } catch (err) {
        console.error('failed to load emotion report', err)
        setState({ loading: false, error: err, data: null })
      }
    }
    fetchReport()
  }, [apiBaseUrl])

  const handleGoHome = () => navigate('/')
  const handleGoChat = () => navigate('/chat')

  if (state.loading) {
    return (
      <div className="emotion-report-page">
        <div className="emotion-report-surface">
          <div className="report-state">
            <div className="spinner" aria-label="로딩 중" />
            <p className="state-text">이번 주 감정을 정리하고 있어요...</p>
          </div>
        </div>
      </div>
    )
  }

  if (state.error || !state.data) {
    return (
      <div className="emotion-report-page">
        <div className="emotion-report-surface">
          <EmptyStateCard
            title="이번 주 감정 리포트"
            description="오늘은 아직 데이터가 없어요. 봄이랑 먼저 이야기해볼래?"
            ctaLabel="대화하러 가기"
            onClickCta={handleGoChat}
          />
        </div>
      </div>
    )
  }

  const report = state.data

  return (
    <div className="emotion-report-page">
      <div className="emotion-report-surface">
        <header className="report-header">
          <div>
            <p className="report-period">{report.week_label}</p>
            <h1 className="report-title">{report.title}</h1>
          </div>
          <div className="report-actions">
            <button className="ghost-button" onClick={handleGoHome}>
              봄이 홈으로
            </button>
            <button className="primary-button" onClick={handleGoChat}>
              대화하러 가기
            </button>
          </div>
        </header>

        <ReportLayout report={report} onClickGoChat={handleGoChat} />
      </div>
    </div>
  )
}
