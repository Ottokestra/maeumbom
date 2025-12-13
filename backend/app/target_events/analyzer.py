"""
LLM 기반 대상별 이벤트 분석 엔진
Analyzes conversations to extract target-specific events using LLM
"""
import os
import json
from datetime import datetime, date, timedelta
from typing import List, Dict, Any, Optional
from openai import OpenAI

from .constants import (
    TARGET_TAGS,
    EVENT_TYPE_TAGS,
    TIME_TAGS,
    IMPORTANCE_TAGS,
    EMOTION_TAGS,
)


class TargetEventAnalyzer:
    """대화 내용에서 대상별 이벤트를 추출하는 분석기"""

    def __init__(self):
        api_key = os.getenv("OPENAI_API_KEY")
        if not api_key:
            raise ValueError("OPENAI_API_KEY environment variable is not set")
        self.client = OpenAI(api_key=api_key)
        self.model = "gpt-4o-mini"

    def analyze_daily_conversations(
        self, conversations: List[Dict[str, Any]], target_date: date
    ) -> List[Dict[str, Any]]:
        """
        하루치 대화를 분석하여 대상별 이벤트 추출

        Args:
            conversations: 대화 내역 리스트 [{id, content, speaker_type, created_at}, ...]
            target_date: 분석 대상 날짜

        Returns:
            추출된 이벤트 리스트 (태그 포함)
        """
        if not conversations:
            return []

        # 대화 내용을 텍스트로 변환
        conversation_text = self._format_conversations(conversations)

        # LLM 프롬프트 구성
        system_prompt = self._create_system_prompt()
        user_prompt = self._create_user_prompt(conversation_text, target_date)

        try:
            response = self.client.chat.completions.create(
                model=self.model,
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_prompt},
                ],
                temperature=0.1,
                max_tokens=2000,
                response_format={"type": "json_object"},
            )

            result_text = response.choices[0].message.content.strip()
            result = json.loads(result_text)

            # 이벤트 리스트 추출 및 후처리
            events = result.get("events", [])
            processed_events = self._post_process_events(
                events, conversations, target_date
            )

            return processed_events

        except Exception as e:
            print(f"[ERROR] LLM analysis failed: {e}")
            return []

    def summarize_weekly_events(
        self, daily_events: List[Dict[str, Any]], target_type: str, week_start: date
    ) -> Dict[str, Any]:
        """
        주간 이벤트를 대상별로 요약

        Args:
            daily_events: 일간 이벤트 리스트
            target_type: 대상 유형 (husband/son/friend/colleague)
            week_start: 주 시작일

        Returns:
            주간 요약 및 통합 태그
        """
        if not daily_events:
            return {
                "events_summary": [],
                "total_events": 0,
                "tags": [],
            }

        # 이벤트 정보를 텍스트로 변환
        events_text = self._format_events_for_summary(daily_events)

        # LLM 프롬프트 구성
        system_prompt = self._create_weekly_summary_system_prompt()
        user_prompt = self._create_weekly_summary_user_prompt(
            events_text, target_type, week_start
        )

        try:
            response = self.client.chat.completions.create(
                model=self.model,
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_prompt},
                ],
                temperature=0.2,
                max_tokens=1500,
                response_format={"type": "json_object"},
            )

            result_text = response.choices[0].message.content.strip()
            result = json.loads(result_text)

            # 통합 태그 추출
            all_tags = []
            for event in daily_events:
                if event.get("tags"):
                    all_tags.extend(event["tags"])

            # 빈도 높은 태그 추출 (상위 10개)
            tag_counts = {}
            for tag in all_tags:
                tag_counts[tag] = tag_counts.get(tag, 0) + 1

            popular_tags = sorted(tag_counts.items(), key=lambda x: x[1], reverse=True)
            top_tags = [tag for tag, _ in popular_tags[:10]]

            return {
                "events_summary": result.get("summary", []),
                "total_events": len(daily_events),
                "tags": top_tags,
            }

        except Exception as e:
            print(f"[ERROR] Weekly summary failed: {e}")
            return {
                "events_summary": [
                    {"date": event.get("event_date"), "summary": event.get("event_summary")}
                    for event in daily_events[:5]
                ],
                "total_events": len(daily_events),
                "tags": [],
            }

    def _format_conversations(self, conversations: List[Dict[str, Any]]) -> str:
        """대화 내역을 텍스트로 포맷팅"""
        lines = []
        for conv in conversations:
            speaker = conv.get("speaker_type", "user")
            content = conv.get("content", "")
            created_at = conv.get("created_at", "")

            if speaker == "assistant":
                speaker_label = "봄이"
            else:
                speaker_label = "사용자"

            lines.append(f"[{speaker_label}] {content}")

        return "\n".join(lines)

    def _create_system_prompt(self) -> str:
        """일일 분석용 시스템 프롬프트 생성"""
        target_tags_str = ", ".join(TARGET_TAGS.values())
        event_type_tags_str = ", ".join(EVENT_TYPE_TAGS)
        time_tags_str = ", ".join(TIME_TAGS)

        return f"""당신은 대화 내용을 분석하여 주요 대상(가족, 친구, 동료 등)과의 이벤트, 약속, 중요한 기억을 추출하는 전문가입니다.

대화에서 다음 정보를 추출하세요:
1. **대상 관계**: 대화에서 언급된 사람과의 관계 (남편, 아들, 딸, 친구, 직장동료 등)
2. **이벤트 내용**: 약속, 픽업, 만남, 식사, 통화 예정, 기념일, 알림 요청 등
3. **시간 정보**: 날짜와 시간 (구체적으로 언급된 경우)
4. **중요도**: 1-5점 (5점이 가장 중요)
5. **태그**: 프론트엔드 필터링을 위한 태그

**태그 카테고리**:
- 대상 태그: {target_tags_str}
- 이벤트 유형: {event_type_tags_str}
- 시간 태그: {time_tags_str}
- 중요도: #매우중요, #중요, #보통

**추출 규칙**:
- 명확한 약속이나 일정이 있는 경우만 추출
- 과거의 일반적인 대화는 제외
- 미래에 대한 계획이나 약속을 우선
- 대상이 명확하지 않으면 "가족"으로 분류
- 시간 정보가 없으면 null로 설정

JSON 형식으로 응답하세요:
{{
  "events": [
    {{
      "target_type": "husband|son|daughter|friend|colleague|family|acquaintance",
      "event_summary": "이벤트 요약 (한 문장)",
      "event_time": "YYYY-MM-DDTHH:MM:SS 또는 null",
      "importance": 1-5,
      "is_future_event": true/false,
      "tags": ["#남편", "#약속", "#이번주", "#중요"],
      "conversation_ids": [대화 ID 리스트]
    }}
  ]
}}"""

    def _create_user_prompt(self, conversation_text: str, target_date: date) -> str:
        """일일 분석용 사용자 프롬프트 생성"""
        return f"""분석 날짜: {target_date.strftime('%Y년 %m월 %d일')}

다음 대화에서 주요 이벤트를 추출하세요:

{conversation_text}

위 대화에서 대상별 이벤트, 약속, 중요한 기억을 JSON 형식으로 추출하세요."""

    def _create_weekly_summary_system_prompt(self) -> str:
        """주간 요약용 시스템 프롬프트"""
        return """당신은 일주일간의 이벤트를 요약하는 전문가입니다.

주어진 일간 이벤트들을 분석하여 주간 요약을 생성하세요.

JSON 형식으로 응답하세요:
{
  "summary": [
    {
      "date": "YYYY-MM-DD",
      "summary": "해당 날짜의 주요 이벤트 요약"
    }
  ]
}"""

    def _create_weekly_summary_user_prompt(
        self, events_text: str, target_type: str, week_start: date
    ) -> str:
        """주간 요약용 사용자 프롬프트"""
        target_name = TARGET_TAGS.get(target_type, target_type)
        week_end = week_start + timedelta(days=6)

        return f"""대상: {target_name}
기간: {week_start.strftime('%Y년 %m월 %d일')} ~ {week_end.strftime('%Y년 %m월 %d일')}

일간 이벤트 목록:
{events_text}

위 이벤트들을 날짜별로 요약하세요."""

    def _format_events_for_summary(self, events: List[Dict[str, Any]]) -> str:
        """이벤트를 요약용 텍스트로 포맷팅"""
        lines = []
        for event in events:
            event_date = event.get("event_date", "")
            event_summary = event.get("event_summary", "")
            event_time = event.get("event_time", "")

            time_str = ""
            if event_time:
                try:
                    if isinstance(event_time, str):
                        dt = datetime.fromisoformat(event_time.replace("Z", "+00:00"))
                        time_str = f" {dt.strftime('%H:%M')}"
                except:
                    pass

            lines.append(f"- {event_date}{time_str}: {event_summary}")

        return "\n".join(lines)

    def _post_process_events(
        self,
        events: List[Dict[str, Any]],
        conversations: List[Dict[str, Any]],
        target_date: date,
    ) -> List[Dict[str, Any]]:
        """이벤트 후처리 (대화 ID 매핑, 날짜 검증 등)"""
        processed = []

        for event in events:
            # 대화 ID 매핑 (모든 대화 ID 포함)
            if not event.get("conversation_ids"):
                event["conversation_ids"] = [conv.get("id") for conv in conversations if conv.get("id")]

            # 이벤트 날짜 설정 (event_time이 있으면 해당 날짜, 없으면 target_date)
            if event.get("event_time"):
                try:
                    if isinstance(event["event_time"], str):
                        event_dt = datetime.fromisoformat(
                            event["event_time"].replace("Z", "+00:00")
                        )
                        event["event_date"] = event_dt.date()
                    else:
                        event["event_date"] = target_date
                except:
                    event["event_date"] = target_date
            else:
                event["event_date"] = target_date

            # 미래 이벤트 여부 확인
            if event.get("event_date"):
                event["is_future_event"] = event["event_date"] >= date.today()

            # 태그 검증 및 정리
            if event.get("tags"):
                event["tags"] = [tag for tag in event["tags"] if tag.startswith("#")]
            else:
                event["tags"] = []

            processed.append(event)

        return processed

