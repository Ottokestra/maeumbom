# backend/app/menopause_survey/router.py
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.menopause_survey import schemas

router = APIRouter(
    prefix="/api/menopause-survey",
    tags=["MenopauseSurvey"],
)


@router.post("/submit", response_model=schemas.MenopauseSurveyResultOut)
def submit_menopause_survey(
    payload: schemas.MenopauseSurveySubmitRequest,
    db: Session = Depends(get_db),
):
    """
    ⚠️ MVP / 테스트용:
    - 지금은 로그인/유저 연동이 깨져 있어서, 일단 인증 없이도 설문 제출 가능하게 만든 버전.
    - total_score / risk_level / comment 계산만 해서 프론트에 내려준다.
    - DB 저장은 모델 구조를 정확히 봐야 해서, 지금은 건드리지 않고 남겨둠.
      (나중에 dev 병합 후 models 확인하면서 record 저장 로직만 추가하면 됨.)
    """
    try:
        # 1) 점수 계산
        total_score = sum(a.answer_value for a in payload.answers)

        if total_score < 10:
            risk_level = "LOW"
            comment = (
                "현재 상태는 비교적 안정적인 편입니다. "
                "가벼운 루틴 점검과 휴식을 꾸준히 유지해 주세요."
            )
        elif total_score < 20:
            risk_level = "MID"
            comment = (
                "몇 가지 갱년기 관련 신호가 보입니다. "
                "수면·식습관·운동 루틴을 조정하고, 변화가 지속되면 전문의 상담을 고려해 보세요."
            )
        else:
            risk_level = "HIGH"
            comment = (
                "여러 항목에서 강한 신호가 보입니다. "
                "생활에 불편이 크다면, 가까운 시일 내에 산부인과/내분비내과 등 전문의 상담을 권장드립니다."
            )

        # 2) (나중에) DB 저장 부분 — 지금은 주석만 남겨둠
        # from app.menopause_survey import models
        # record = models.MenopauseSurveyResult(
        #     user_id=None,  # 로그인 연동 후 current_user.id 로 교체
        #     gender=payload.gender,
        #     total_score=total_score,
        #     risk_level=risk_level,
        #     raw_answers=payload.model_dump(),
        # )
        # db.add(record)
        # db.commit()
        # db.refresh(record)
        #
        # return schemas.MenopauseSurveyResultOut(
        #     id=record.id,
        #     total_score=total_score,
        #     risk_level=risk_level,
        #     comment=comment,
        # )

        # 지금은 DB 없이도 프론트가 쓰기 편하도록, 더미 id=0 으로 내려줌
        return schemas.MenopauseSurveyResultOut(
            id=0,
            total_score=total_score,
            risk_level=risk_level,
            comment=comment,
        )

    except Exception as e:
        print("[ERROR] submit_menopause_survey:", repr(e))
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"설문 저장 중 서버 오류가 발생했습니다: {e}",
        )
