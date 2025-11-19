import React from 'react';
import './RoutineList.css';

const RoutineList = ({ recommendations }) => {
  if (!recommendations || recommendations.length === 0) {
    return null;
  }

  return (
    <div className="routine-list-container">
      <h2>✨ 추천 루틴</h2>
      <div className="routine-grid">
        {recommendations.map((item) => (
          <div key={item.routine_id} className="routine-card">
            <div className="routine-header">
              <span className="routine-category">{getCategoryLabel(item.category)}</span>
              <h3 className="routine-title">{item.title}</h3>
            </div>
            
            <div className="routine-body">
              <p className="routine-reason">💡 {item.reason}</p>
              <p className="routine-message">"{item.ui_message}"</p>
            </div>
            
            <div className="routine-footer">
              {item.duration_min && (
                <span className="routine-tag">⏱️ {item.duration_min}분</span>
              )}
              {item.suggested_time_window && (
                <span className="routine-tag">🕒 {getTimeLabel(item.suggested_time_window)}</span>
              )}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

function getCategoryLabel(category) {
  if (category.startsWith('EMOTION_')) return '감정 케어';
  if (category.startsWith('TIME_')) return '시간대 루틴';
  if (category.startsWith('BODY_')) return '신체 건강';
  return '추천 루틴';
}

function getTimeLabel(time) {
  const map = {
    morning: '아침',
    day: '낮',
    evening: '저녁',
    pre_sleep: '자기 전',
    any: '언제나'
  };
  return map[time] || time;
}

export default RoutineList;
