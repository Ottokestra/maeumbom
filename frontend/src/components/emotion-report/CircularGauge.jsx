import './CircularGauge.css'

function clamp(value, min = 0, max = 100) {
  return Math.min(Math.max(value, min), max)
}

export default function CircularGauge({ value, label, color = '#ffb3c6', centerContent }) {
  const safeValue = clamp(Number.isFinite(value) ? value : 0)
  const angle = (safeValue / 100) * 360
  const displayColor = color || '#ffb3c6'

  const style = {
    background: `conic-gradient(${displayColor} ${angle}deg, #f3f4f6 ${angle}deg)`
  }

  return (
    <div className="circular-gauge" style={style}>
      <div className="circular-gauge__inner">
        {centerContent}
        <div className="circular-gauge__value">{safeValue.toFixed(0)}°</div>
        {label && <div className="circular-gauge__label">{label}</div>}
      </div>
    </div>
  )
}
