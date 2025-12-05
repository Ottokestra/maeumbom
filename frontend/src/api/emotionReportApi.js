export async function fetchWeeklyEmotionReport(baseDate) {
  const params = baseDate ? `?base_date=${encodeURIComponent(baseDate)}` : ''
  const response = await fetch(`/api/reports/emotion/weekly${params}`)
  if (!response.ok) {
    throw new Error('Failed to load weekly emotion report')
  }
  return response.json()
}
