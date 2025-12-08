from datetime import date, timedelta
from fastapi import APIRouter

router = APIRouter(prefix="/api/reports", tags=["reports"])


@router.get("/emotion/weekly")
async def get_weekly_emotion_report():
    today = date.today()
    start = today - timedelta(days=6)
    return {
        "has_data": True,
        "period": "WEEKLY",
        "date_range": {
            "start": start.isoformat(),
            "end": today.isoformat(),
        },
        "title": "금주의 너는 '걱정이 복숭아'",
        "summary": "데모용 주간 감정 리포트입니다.",
        "characters": [
            {"id": "bomi", "name": "봄이"},
            {"id": "coach", "name": "코치봄"},
            {"id": "guardian", "name": "수호봄"},
        ],
        "dialog": [
            {
                "speaker_id": "bomi",
                "type": "opening",
                "emotion": "bright",
                "text": "이번 주 마음을 같이 돌아봤어요. 솔직하게 나눠줘서 고마워요.",
            },
            {
                "speaker_id": "coach",
                "type": "analysis",
                "emotion": "calm",
                "text": "이번 주에는 걱정과 피곤이 섞여 있었지만, 잘 버티고 있는 모습이 보여요.",
            },
        ],
    }
