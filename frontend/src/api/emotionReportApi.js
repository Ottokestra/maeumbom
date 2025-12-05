import { API_BASE_URL } from '../config/api'

export async function fetchWeeklyEmotionReport(baseDate) {
  const params = baseDate ? `?base_date=${encodeURIComponent(baseDate)}` : ''
  const response = await fetch(`${API_BASE_URL}/reports/emotion/weekly${params}`)
  if (!response.ok) {
    throw new Error('Failed to load weekly emotion report')
  }
  return response.json()
}
