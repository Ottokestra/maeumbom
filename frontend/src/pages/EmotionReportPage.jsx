import { useEffect, useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import CircularGauge from '../components/emotion-report/CircularGauge'
import { API_BASE_URL } from '../config/api'
import { resolveCharacterMeta } from '../config/emotionCharacters'
import './EmotionReportPage.css'

const clamp = (value, min = 0, max = 100) => Math.min(Math.max(value ?? 0, min), max)

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
      {days.map((day) => {
        const meta = resolveCharacterMeta(day.character_code)
        return (
          <div className="weekly-day" key={day.date || day.day}>
            <span className="weekly-day__label">{day.day_label || day.day}</span>
            <span className="weekly-day__emoji">{meta.emoji}</span>
            <span className="weekly-day__name">{meta.label}</span>
          </div>
        )
      })}
    </div>
  )
}

function CoachMessage({ message, character, onClickGoChat }) {
  if (!message) return null

  return (
    <section className="coach-message">
      <div className="coach-avatar" aria-hidden>
        {character.emoji}
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

function ReportLayout({ report, mainCharacter, onClickGoChat }) {
  const gaugeValue = useMemo(() => clamp(report.temperature), [report.temperature])

  return (
    <div className="report-body">
      <section className="report-hero">
        <div className="report-gauge-card">
          <CircularGauge
            value={gaugeValue}
            label={report.temperature_label || '감정 온도'}
            color="#f472b6"
            centerContent={<div className="report-main-emoji">{mainCharacter.emoji}</div>}
          />
          <div className="report-gauge-meta">
            <p className="gauge-caption">{mainCharacter.label}</p>
            <p className="gauge-description">{mainCharacter.description}</p>
          </div>
        </div>

        <div className="report-character-card">
          <p className="character-chip">대표 감정 캐릭터</p>
          <div className="character-emoji">{mainCharacter.emoji}</div>
          <p className="character-name">{mainCharacter.label}</p>
          <p className="character-description">{mainCharacter.description}</p>
        </div>
      </section>

      <section className="report-weekly">
        <div className="section-heading">
          <div>
            <p className="section-caption">요일별 감정 캐릭터</p>
            <h2 className="section-title">한 주를 채운 감정 스티커</h2>
          </div>
          <span className="period-chip">
            {report.start_date} ~ {report.end_date}
          </span>
        </div>
        <ReportDays days={report.days} />
      </section>

      <CoachMessage message={report.coach_message} character={mainCharacter} onClickGoChat={onClickGoChat} />
    </div>
  )
}

export default function EmotionReportPage() {
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [report, setReport] = useState(null)
  const navigate = useNavigate()

  const loadReport = async () => {
    setLoading(true)
    setError('')

    try {
      const response = await fetch(`${API_BASE_URL}/reports/emotion/weekly`)

      if (response.status === 404) {
        setReport(null)
        return
      }

      if (!response.ok) {
        throw new Error('failed to load weekly emotion report')
      }

      const data = await response.json()
      setReport(data)
    } catch (err) {
      console.error(err)
      setError('리포트를 불러오지 못했어요. 네트워크를 확인한 뒤 다시 시도해주세요.')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    loadReport()
  }, [])

  const handleGoHome = () => navigate('/')
  const handleGoChat = () => navigate('/chat')

  const mainCharacter = useMemo(() => resolveCharacterMeta(report?.main_character_code), [report?.main_character_code])

  return (
    <div className="emotion-report-page">
      <div className="emotion-report-surface">
        <header className="report-header">
          <div>
            <p className="report-period">이번 주 정리 · {report?.start_date} ~ {report?.end_date}</p>
            <h1 className="report-title">금주의 너는 '{mainCharacter.label}'</h1>
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

        {loading && (
          <div className="report-state">
            <div className="spinner" aria-label="로딩 중" />
            <p className="state-text">이번 주 감정을 정리하고 있어요...</p>
          </div>
        )}

        {!loading && error && (
          <div className="report-state report-state--error">
            <p className="state-text">잠시 연결이 불안정해요. 다시 시도해볼까요?</p>
            <div className="state-actions">
              <button className="ghost-button" onClick={loadReport}>
                다시 시도하기
              </button>
              <button className="primary-button" onClick={handleGoChat}>
                대화하러 가기
              </button>
            </div>
          </div>
        )}

        {!loading && !error && !report && (
          <EmptyStateCard
            title="이번 주 감정 리포트"
            description="오늘은 아직 데이터가 없어요. 봄이랑 먼저 이야기해볼래?"
            ctaLabel="대화하러 가기"
            onClickCta={handleGoChat}
          />
        )}

        {!loading && !error && report && (
          <ReportLayout report={report} mainCharacter={mainCharacter} onClickGoChat={handleGoChat} />
        )}
      </div>
    </div>
  )
}
