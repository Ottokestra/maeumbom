import { API_BASE_URL } from '../config/api'

export async function fetchWeeklyEmotionReport(baseDate) {
  const params = baseDate ? `?base_date=${encodeURIComponent(baseDate)}` : ''
  const response = await fetch(`${API_BASE_URL}/reports/emotion/weekly${params}`)

  if (response.status === 404) {
    return null
  }

  if (!response.ok) {
    const error = new Error('Failed to load weekly emotion report')
    error.status = response.status
    throw error
  }

  return response.json()
}
