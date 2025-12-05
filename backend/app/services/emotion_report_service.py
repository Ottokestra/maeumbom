from datetime import date
from sqlalchemy.orm import Session

from app.emotion_report.models import EmotionWeeklyReport
from app.emotion_report.schemas import WeeklyEmotionReport, WeeklyEmotionItem

EMOTION_CHARACTERS = {
    "SUN_FLOWER": {"emoji": "🌻", "name": "해바라기 기쁨이"},
    "STAR_HOPE": {"emoji": "⭐", "name": "반짝이는 희망이"},
    "CAT_LOVE": {"emoji": "😺", "name": "두근두근 설렘이"},
    "BULB_IDEA": {"emoji": "💡", "name": "아이디어 번뜩이"},
    "CLOUD_SOFT": {"emoji": "☁️", "name": "몽글몽글 평온이"},
    "FISH_SURPRISE": {"emoji": "🐟", "name": "깜짝이"},
    "FIRE_ANGER": {"emoji": "🔥", "name": "활활 화남이"},
    "RAIN_SAD": {"emoji": "🌧️", "name": "촉촉이 슬픔"},
    "PEACH_WORRY": {"emoji": "🍑", "name": "걱정이 복숭아"},
    "GHOST_FEAR": {"emoji": "👻", "name": "소심이"},
    "ROCK_HEAVY": {"emoji": "🪨", "name": "답답이"},
    "PUMPKIN_TRICK": {"emoji": "🎃", "name": "장난꾸러기"},
    "SLOTH_TIRED": {"emoji": "🦥", "name": "피곤이"},
    "DEVIL_ANGER": {"emoji": "😈", "name": "폭발이"},
    "ALIEN_CONFUSED": {"emoji": "👽", "name": "어리둥절이"},
    "ROBOT_OVERLOAD": {"emoji": "🤖", "name": "과부하 로봇"},
}


def _ensure_sample_report(db: Session, user_id: int) -> EmotionWeeklyReport:
    """데이터가 없을 경우, 디자인에 맞는 샘플 한 건을 생성해 주는 임시 함수."""
    report = (
        db.query(EmotionWeeklyReport)
        .filter(EmotionWeeklyReport.user_id == user_id)
        .order_by(EmotionWeeklyReport.week_start.desc())
        .first()
    )
    if report:
        return report

    week_start = date(2025, 11, 29)
    week_end = date(2025, 12, 5)

    weekly_emotions = [
        {"day": "토", "emoji": "🍑", "code": "PEACH_WORRY"},
        {"day": "일", "emoji": "🍑", "code": "PEACH_WORRY"},
        {"day": "월", "emoji": "🍑", "code": "PEACH_WORRY"},
        {"day": "화", "emoji": "🍑", "code": "PEACH_WORRY"},
        {"day": "수", "emoji": "🍑", "code": "PEACH_WORRY"},
        {"day": "목", "emoji": "🍑", "code": "PEACH_WORRY"},
        {"day": "금", "emoji": "🍑", "code": "PEACH_WORRY"},
    ]

    report = EmotionWeeklyReport(
        user_id=user_id,
        week_start=week_start,
        week_end=week_end,
        main_character_code="PEACH_WORRY",
        main_emotion_label="금주의 너는 '걱정이 복숭아'",
        temperature=72,
        weekly_emotions=weekly_emotions,
        suggestion="이번 주엔 걱정이 조금 많았어요. 특히 마음에 남는 일이 있다면, 봄이에게 먼저 털어놓아볼래요?",
    )
    db.add(report)
    db.commit()
    db.refresh(report)
    return report


def get_weekly_emotion_report(db: Session, user_id: int) -> WeeklyEmotionReport:
    report = _ensure_sample_report(db, user_id=user_id)

    char_meta = EMOTION_CHARACTERS.get(report.main_character_code, {})
    emoji = char_meta.get("emoji", "💜")
    name = char_meta.get("name", report.main_character_code)

    week_label = f"이번 주 정리 · {report.week_start} ~ {report.week_end}"
    temperature_label = f"따뜻함 {report.temperature}°"

    weekly_items = [WeeklyEmotionItem(**item) for item in report.weekly_emotions]

    return WeeklyEmotionReport(
        week_label=week_label,
        title=report.main_emotion_label,
        temperature=report.temperature,
        temperature_label=temperature_label,
        main_character_code=report.main_character_code,
        main_character_emoji=emoji,
        main_character_name=name,
        weekly_emotions=weekly_items,
        suggestion=report.suggestion,
    )
