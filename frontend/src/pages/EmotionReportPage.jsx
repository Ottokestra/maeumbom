import { useEffect, useMemo, useState } from 'react'
import { fetchWeeklyEmotionReport } from '../api/emotionReportApi'
import CircularGauge from '../components/emotion-report/CircularGauge'
import { getCharacterEmoji } from '../utils/characterMap'
import './EmotionReportPage.css'

const emojiFallback = '🤍'

export default function EmotionReportPage() {
  const [report, setReport] = useState(null)
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState('')

  useEffect(() => {
    const loadReport = async () => {
      setIsLoading(true)
      setError('')
      try {
        const data = await fetchWeeklyEmotionReport()
        setReport(data)
      } catch (err) {
        setError(err.message || '데이터를 불러오지 못했어요')
      } finally {
        setIsLoading(false)
      }
    }

    loadReport()
  }, [])

  const mainCharacterEmoji = useMemo(() => {
    return getCharacterEmoji(report?.main_character_key) || emojiFallback
  }, [report?.main_character_key])

  const gaugeColor = report?.gauge_color || '#f9c6d6'

  const renderDailyStickers = () => {
    if (!report?.daily_stickers?.length) return null
    return (
      <div className="daily-sticker-row">
        {report.daily_stickers.map((item) => (
          <div key={item.date} className="daily-sticker" title={item.label}>
            <div className="daily-sticker__day">{item.day_label}</div>
            <div className="daily-sticker__emoji">{getCharacterEmoji(item.character_key)}</div>
          </div>
        ))}
      </div>
    )
  }

  return (
    <div className="emotion-report-page">
      <div className="emotion-report-card">
        <header className="emotion-report-header">
          <div className="report-meta">
            <p className="report-meta__caption">이번 주 정리 · {report?.week_start} ~ {report?.week_end}</p>
            <h1 className="report-title">{report?.summary_title || '이번 주 감정 리포트'}</h1>
          </div>
          <button className="nav-button" onClick={() => (window.location.href = '/')}>봄이 홈으로</button>
        </header>

        {isLoading && (
          <div className="report-state">
            <div className="spinner" aria-label="로딩 중" />
            <p className="state-text">이번 주 감정을 정리하고 있어요...</p>
          </div>
        )}

        {!isLoading && error && (
          <div className="report-state report-state--error">
            <p className="state-text">오늘은 아직 데이터가 없어요. 봄이랑 먼저 이야기해볼래?</p>
            <button className="primary-button" onClick={() => (window.location.href = '/')}>대화하러 가기</button>
          </div>
        )}

        {!isLoading && !error && report && (
          <>
            <section className="main-emotion">
              <div className="main-emotion__copy">🧡 금주의 너는 '{report.summary_title}'</div>
              <div className="main-emotion__visual">
                <CircularGauge
                  value={report.temperature}
                  label={report.temperature_label}
                  color={gaugeColor}
                  centerContent={<div className="main-character">{mainCharacterEmoji}</div>}
                />
                <div className="main-emotion__info">
                  <p className="main-emotion__badge">대표 감정 캐릭터</p>
                  <div className="main-emotion__emoji">{mainCharacterEmoji}</div>
                  <p className="main-emotion__temperature">온도 {report.temperature}°</p>
                </div>
              </div>
            </section>

            <section className="daily-section">
              <div className="section-heading">
                <h2>요일별 감정 캐릭터</h2>
                <p className="section-subtext">매일의 감정을 스티커처럼 모았어요</p>
              </div>
              {renderDailyStickers()}
            </section>
          </>
        )}
      </div>
    </div>
  )
}
