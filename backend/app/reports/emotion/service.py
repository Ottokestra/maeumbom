from datetime import date, timedelta

from .schemas import (
    EmotionCharacterBubble,
    EmotionDailyScore,
    EmotionRecommendation,
    WeeklyEmotionReport,
)


def get_weekly_emotion_report(user_id: int) -> WeeklyEmotionReport:
    # 오늘을 기준으로 지난 7일 구간 계산 (프론트는 어차피 목 데이터용)
    today = date.today()
    start = today - timedelta(days=6)

    daily = [
        EmotionDailyScore(
            date=start + timedelta(days=i),
            main_emotion=["기쁨", "기쁨", "불안", "피곤", "우울", "편안", "기쁨"][i],
            score=[0.8, 0.7, 0.6, 0.4, 0.3, 0.5, 0.9][i],
            subtitle=[
                "가볍게 웃는 일이 많았어요.",
                "일은 많았지만 잘 버텼어요.",
                "내일이 조금 걱정됐던 날이에요.",
                "몸이 많이 피곤했어요.",
                "마음이 조금 가라앉았어요.",
                "차분하고 편안한 하루였어요.",
                "스스로가 대견했던 하루였어요."
            ][i],
        )
        for i in range(7)
    ]

    character_bubble = EmotionCharacterBubble(
        character_name="봄이",
        mood="cheerful",
        message="이번 주에도 정말 잘 버텼어! 😊\n특히 주말에는 네가 스스로를 잘 돌봐준 게 느껴져."
    )

    recommendations = [
        EmotionRecommendation(
            type="routine",
            title="수면 루틴 한 가지 정해보기",
            content="하루 중 가장 피곤했던 날(목·금요일)에 잠들기 30분 전에 휴대폰을 내려놓고, 가벼운 스트레칭이나 찬찬한 음악을 들어보는 건 어때?"
        ),
        EmotionRecommendation(
            type="emotion",
            title="감정 기록 3줄만 남겨보기",
            content="이번 주에 기뻤던 순간 1개, 힘들었던 순간 1개, 그때의 나에게 해주고 싶은 말 1개씩만 적어보자. 봄이가 다음 주 리포트에서 같이 정리해줄게."
        ),
    ]

    return WeeklyEmotionReport(
        user_id=user_id,
        week_start=start,
        week_end=today,
        summary_title="기복은 있었지만, 잘 버틴 한 주였어요",
        summary_text=(
            "초반에는 비교적 가볍고 즐거운 감정이 많았지만, "
            "주중으로 갈수록 피로와 불안이 쌓이는 패턴이 보여요. "
            "그래도 주말에 스스로를 돌보려고 노력한 흔적이 보여서 아주 좋아요. "
            "다음 주에는 피로가 심해지는 날을 미리 예상해서, "
            "조금 더 일찍 쉬는 루틴을 만들어 보면 어때요?"
        ),
        dominant_emotion="기쁨 + 피로",
        character_bubble=character_bubble,
        daily_scores=daily,
        recommendations=recommendations,
    )

    # 나중에 실제 DB/감정분석 엔진이 붙으면
    # 이 함수 내부만 바꾸고 WeeklyEmotionReport 구조는 유지하면 된다.
