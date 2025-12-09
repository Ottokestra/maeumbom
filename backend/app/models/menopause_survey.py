"""
Menopause (갱년기) 라이트 자가 체크 설문 모델 정의

- TB_MENOPAUSE_SURVEY         : 설문 결과 요약 (유저 1회 결과)
- TB_MENOPAUSE_SURVEY_ANSWER  : 각 문항별 상세 답변 기록
"""

from sqlalchemy import (
    Column,
    Integer,
    String,
    DateTime,
    ForeignKey,
    JSON,
    Text,
)
from sqlalchemy.sql import func

# ✅ 프로젝트 공통 Base (app/db/database.py 에서 선언된 것)
from app.db.database import Base


class MenopauseSurvey(Base):
    """
    갱년기 라이트 자가 체크 설문 결과 요약 테이블

    - 한 번 설문을 완료했을 때 1레코드 생성
    - 성별/총점/위험도/세부 JSON(질문별 점수 요약 등)을 저장
    """

    __tablename__ = "TB_MENOPAUSE_SURVEY"

    # 내부적으로는 snake_case 속성명을 쓰고,
    # 실제 DB 컬럼명은 기존 규칙에 맞게 대문자로 매핑
    id = Column("ID", Integer, primary_key=True, index=True, autoincrement=True)

    # ✅ FK 대상: TB_USERS.ID  (대문자 ID 주의)
    user_id = Column(
        "USER_ID",
        Integer,
        ForeignKey("TB_USERS.ID"),
        nullable=False,
        index=True,
    )

    # 'MALE' / 'FEMALE'
    gender = Column("GENDER", String(10), nullable=False)

    # 총 점수 (0~30)
    total_score = Column("TOTAL_SCORE", Integer, nullable=False)

    # 위험도: 'LOW' / 'MID' / 'HIGH'
    risk_level = Column("RISK_LEVEL", String(20), nullable=False)

    # 프론트/서비스에서 쓰는 세부 결과 요약 (문항별 점수, 태그 등)
    detail_json = Column("DETAIL_JSON", JSON, nullable=False)

    created_at = Column(
        "CREATED_AT",
        DateTime(timezone=True),
        server_default=func.now(),
    )

    def __repr__(self) -> str:  # 디버깅용
        return (
            f"<MenopauseSurvey(id={self.id}, user_id={self.user_id}, "
            f"gender={self.gender}, total_score={self.total_score}, "
            f"risk_level={self.risk_level})>"
        )


class MenopauseSurveyAnswer(Base):
    """
    갱년기 설문 문항별 답변 저장 테이블

    - 한 설문 결과(MenopauseSurvey)에 포함된 10개 문항 각각이 1레코드
    """

    __tablename__ = "TB_MENOPAUSE_SURVEY_ANSWER"

    id = Column("ID", Integer, primary_key=True, index=True, autoincrement=True)

    # ✅ FK 대상: TB_MENOPAUSE_SURVEY.ID
    survey_id = Column(
        "SURVEY_ID",
        Integer,
        ForeignKey("TB_MENOPAUSE_SURVEY.ID"),
        nullable=False,
        index=True,
    )

    # 프론트에서 쓰는 문항 코드 (예: "F1", "M3" 등)
    question_code = Column("QUESTION_CODE", String(50), nullable=False)

    # 실제 질문 텍스트
    question_text = Column("QUESTION_TEXT", Text, nullable=False)

    # 점수값 (위험 답변이면 3점, 아니면 0점 등)
    answer_value = Column("ANSWER_VALUE", Integer, nullable=False)

    # 사용자가 택한 라벨 ("맞다" / "아니다")
    answer_label = Column("ANSWER_LABEL", String(20), nullable=False)

    created_at = Column(
        "CREATED_AT",
        DateTime(timezone=True),
        server_default=func.now(),
    )

    def __repr__(self) -> str:
        return (
            f"<MenopauseSurveyAnswer(id={self.id}, survey_id={self.survey_id}, "
            f"question_code={self.question_code}, answer_value={self.answer_value})>"
        )
