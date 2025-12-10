import json
import os
import logging
from typing import Any, Dict, Optional
from datetime import datetime

from langchain_openai import ChatOpenAI
from openai import OpenAI

from pydantic import BaseModel

from .db_conversation_store import get_conversation_store
from .orchestrator import orchestrator_llm, execute_tools
from .emotion_classifier import get_emotion_classifier
from .response_generator import (
    get_casual_tone_system_prompt,
    generate_response_metadata,
    parse_alarm_request,
)
from app.db.database import SessionLocal

logger = logging.getLogger(__name__)


class CharacterInfo(BaseModel):
    id: str
    emotion_label: str


def select_character_from_emotion(emotion_result: dict[str, Any]) -> tuple[str, str]:
    """
    emotion_result 에서 주요 감정/클러스터를 읽어서 캐릭터 ID와 감정 라벨을 결정한다.

    반환값:
        (character_id, emotion_label)
    예:
        ("sunny_flower", "JOY")
        ("sad_cloud", "SADNESS")
    """
    primary = (
        emotion_result.get("primary_emotion")
        or emotion_result.get("cluster")
        or "NEUTRAL"
    )

    mapping = {
        "JOY": "sunny_flower",  # 해바라기
        "HAPPINESS": "sunny_flower",
        "LOVE": "heart_cat",  # 하트눈 고양이
        "HOPE": "star_friend",  # 별
        "INSIGHT": "idea_bulb",  # 전구
        "ANGER": "fire_spirit",  # 불
        "SADNESS": "rain_cloud",  # 우는 구름
        "FEAR": "ghost_white",  # 유령
        "ANXIETY": "stone_gray",  # 돌
        "TIRED": "sloth_bear",  # 나무늘보
        "STRESS": "devil_red",  # 악마
        "CONFUSION": "alien_green",  # 외계인
        # 기본값
        "NEUTRAL": "cloud_white",
    }

    normalized = str(primary).upper()
    character_id = mapping.get(normalized, "cloud_white")
    return character_id, normalized


async def run_ai_bomi_from_text(
    user_text: str,
    user_id: int,
    session_id: str = "default",
    stt_quality: str = "success",
    speaker_id: Optional[str] = None,
) -> dict[str, Any]:
    """텍스트 입력 기반 AI 봄이 실행 (orchestrator 기반)"""
    
    store = get_conversation_store()
    db_session = SessionLocal()
    
    try:
        # 1. Lightweight Classifier로 감정 분석 필요 여부 판단
        classifier = get_emotion_classifier()
        classifier_hint = classifier.predict(user_text)
        logger.info(f"🎯 [Classifier] Result: {classifier_hint}")
        
        # 2. 대화 히스토리 가져오기
        history = store.get_history(user_id, session_id, limit=10)
        conversation_history = [
            {"role": msg["role"], "content": msg["content"]}
            for msg in history
        ]
        
        # 3. 컨텍스트 구성
        context = {
            "session_id": session_id,
            "user_id": user_id,
            "history": conversation_history,
            "memory": "",  # TODO: 메모리 통합
        }
        
        # 4. Orchestrator로 도구 선택
        tool_calls = await orchestrator_llm(
            user_text=user_text,
            context=context,
            classifier_hint=classifier_hint
        )
        
        # 5. 도구 실행
        tool_results = await execute_tools(
            tool_calls=tool_calls,
            user_id=user_id,
            session_id=session_id,
            user_text=user_text,
            db_session=db_session
        )
        
        # 6. LLM 응답 생성
        client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))
        system_prompt = get_casual_tone_system_prompt()
        
        # 도구 결과를 프롬프트에 포함
        tool_context = ""
        if tool_results.get("emotion"):
            emotion_data = tool_results["emotion"].get("result") or tool_results["emotion"]
            tool_context += f"\n[감정 분석 결과]\n{json.dumps(emotion_data, ensure_ascii=False, indent=2)}\n"
        if tool_results.get("routines"):
            tool_context += f"\n[추천 루틴]\n{json.dumps(tool_results['routines'], ensure_ascii=False, indent=2)}\n"
        
        messages = [
            {"role": "system", "content": system_prompt + tool_context}
        ]
        
        # 대화 히스토리 추가
        for msg in conversation_history[-5:]:  # 최근 5개만
            messages.append({
                "role": msg["role"],
                "content": msg["content"]
            })
        
        # 현재 사용자 메시지
        messages.append({"role": "user", "content": user_text})
        
        # LLM 호출
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=messages,
            temperature=0.7,
        )
        
        reply_text = response.choices[0].message.content.strip()
        
        # 7. 응답 메타데이터 생성
        response_metadata = generate_response_metadata(
            conversation_history=conversation_history,
            llm_response=reply_text,
            user_text=user_text
        )
        
        # 8. 알람 파싱
        alarm_data = parse_alarm_request(
            user_text=user_text,
            llm_response=reply_text,
            current_datetime=datetime.now()
        )
        
        # 9. 감정 결과 추출
        emotion_result = None
        if tool_results.get("emotion"):
            emotion_data = tool_results["emotion"]
            if isinstance(emotion_data, dict):
                emotion_result = emotion_data.get("result") or emotion_data
        
        # 10. DB에 저장
        store.add_message(
            user_id=user_id,
            session_id=session_id,
            role="user-A",
            content=user_text
        )
        store.add_message(
            user_id=user_id,
            session_id=session_id,
            role="assistant",
            content=reply_text
        )
        
        # 11. 결과 반환
        return {
            "reply_text": reply_text,
            "input_text": user_text,
            "emotion_result": emotion_result,
            "routine_result": tool_results.get("routines"),
            "meta": {
                "model": "gpt-4o-mini",
                "used_tools": [tc.function.name for tc in tool_calls],
                "session_id": session_id,
                "stt_quality": stt_quality,
                "user_id": user_id,
                "storage": "database",
                "api_version": "v2",
                "emotion": response_metadata.get("emotion"),
                "response_type": response_metadata.get("response_type"),
                "alarm": alarm_data if alarm_data.get("response_type") == "alarm" else None,
            },
        }
        
    finally:
        db_session.close()


async def run_ai_bomi_from_text_v2(
    user_text: str,
    user_id: int,
    session_id: str = "default",
    stt_quality: str = "success",
    speaker_id: Optional[str] = None,
) -> dict[str, Any]:
    """텍스트 입력 기반 AI 봄이 실행 (v2: 캐릭터 정보 포함)"""

    base_result = await run_ai_bomi_from_text(
        user_text=user_text,
        user_id=user_id,
        session_id=session_id,
        stt_quality=stt_quality,
        speaker_id=speaker_id,
    )

    emotion_result = {}
    if isinstance(base_result.get("emotion_result"), dict):
        emotion_result = base_result.get("emotion_result", {})

    character_id, emotion_label = select_character_from_emotion(emotion_result)

    meta = base_result.get("meta") or {}

    return {
        **base_result,
        "character": {
            "id": character_id,
            "emotion_label": emotion_label,
        },
        "meta": {
            **meta,
            "tts_engine_default": "cute_bomi",
        },
    }


def _get_llm_client() -> ChatOpenAI:
    model_name = os.getenv("OPENAI_MODEL_NAME", "gpt-4o-mini")
    api_key = os.getenv("OPENAI_API_KEY")

    if not api_key:
        raise ValueError("OPENAI_API_KEY 환경변수가 설정되지 않았습니다.")

    return ChatOpenAI(
        model=model_name,
        temperature=0.6,
        api_key=api_key,
    )


def _serialize_weekly_summary(weekly_summary: Any) -> Dict[str, Any]:
    if hasattr(weekly_summary, "model_dump"):
        return weekly_summary.model_dump()
    if hasattr(weekly_summary, "dict"):
        return weekly_summary.dict()
    return dict(weekly_summary)


def generate_weekly_emotion_report_story(weekly_summary: Dict[str, Any]) -> Dict[str, Any]:
    """
    기존 주간 감정 리포트 데이터를 받아 캐릭터 말풍선 리포트로 변환한다.

    Args:
        weekly_summary: 기존 주간 감정 리포트 서비스가 반환하는 딕셔너리 구조

    Returns:
        EmotionReportChatResponse 스키마에 맞는 dict
    """

    llm = _get_llm_client()
    serialized_summary = _serialize_weekly_summary(weekly_summary)

    prompt = f"""
    너는 한국어 감정코치 '봄이'야.
    아래는 사용자의 지난 일주일 감정 요약 데이터야.
    이 데이터를 기반으로 아래 형식의 JSON 을 만들어라.

    - headline: "이번 주의 너는 'OOO'" 형태의 한 줄 제목
    - character:
        - key: 프론트에서 사용할 캐릭터 키 (ex: worried_fox, happy_star 등)
        - display_name: 사용자를 상징하는 캐릭터 이름 (한국어)
        - mood: 영어 한 단어 감정 레이블 (happy, sad, worry, angry 등)
    - bubbles: 캐릭터와 사용자 간의 짧은 대화 말풍선 리스트.
        - 첫 말은 항상 캐릭터가 사용자를 부드럽게 맞이하는 인사
        - 총 4~6개 정도
        - role 은 "character" 또는 "user"

    감정 요약 데이터:
    {serialized_summary}

    반드시 아래 Python dict 형태로만 응답해.
    keys: headline, character, bubbles
    """

    try:
        response = llm.invoke(prompt)
        content = getattr(response, "content", "")
        parsed = json.loads(content)
    except Exception:
        parsed = {}

    headline = parsed.get(
        "headline", serialized_summary.get("summary_title", "이번 주의 너는 '봄이와 함께한 친구'"),
    )
    character = parsed.get(
        "character",
        {"key": "calm_bomi", "display_name": "봄이", "mood": "calm"},
    )
    bubbles = parsed.get(
        "bubbles",
        [
            {
                "role": "character",
                "text": "이번 주에도 잘 버텨줘서 고마워. 기분은 어땠어?",
            },
            {
                "role": "user",
                "text": "기복이 있었지만 나름 괜찮았어.",
            },
            {
                "role": "character",
                "text": "그래도 스스로를 챙기려는 노력이 보여서 든든해!",
            },
        ],
    )

    summary_stats = {
        "dominant_emotion": serialized_summary.get("dominant_emotion"),
        "week_range": {
            "start": serialized_summary.get("week_start"),
            "end": serialized_summary.get("week_end"),
        },
    }

    return {
        "period": "weekly",
        "headline": headline,
        "character": character,
        "bubbles": bubbles,
        "summary_stats": summary_stats,
    }
