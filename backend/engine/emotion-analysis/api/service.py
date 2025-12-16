"""
Emotion Analysis Service Layer
Reusable business logic for session-based emotion analysis
"""
import sys
from pathlib import Path
from typing import Optional, Dict, Any
import json
from sentence_transformers import SentenceTransformer

# Path setup
api_path = Path(__file__).parent
emotion_analysis_path = api_path.parent
backend_path = emotion_analysis_path.parent.parent

if str(backend_path) not in sys.path:
    sys.path.insert(0, str(backend_path))

# Import dependencies
from engine.langchain_agent.db_conversation_store import get_conversation_store
from app.db.models import AnalyzedSession
from app.db.database import SessionLocal

# Import emotion analysis pipeline
import importlib.util
rag_pipeline_path = emotion_analysis_path / "src" / "rag_pipeline.py"
spec = importlib.util.spec_from_file_location("rag_pipeline", rag_pipeline_path)
rag_pipeline_module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(rag_pipeline_module)
get_rag_pipeline = rag_pipeline_module.get_rag_pipeline


def analyze_session_emotion(user_id: int, session_id: str) -> Optional[Dict[str, Any]]:
    """
    Analyze emotion for a session (reusable by API and scheduler)
    
    Args:
        user_id: User ID
        session_id: Session identifier
        
    Returns:
        Analysis result dictionary with:
        - All emotion analysis fields (primary_emotion, sentiment_overall, etc.)
        - analysis_id: ID of created TB_EMOTION_ANALYSIS record
        - message_count: Number of messages analyzed
        
        Returns None if no messages found or session already analyzed
    """
    store = get_conversation_store()
    db = SessionLocal()
    
    try:
        # Check if already analyzed
        existing = db.query(AnalyzedSession).filter(
            AnalyzedSession.SESSION_ID == session_id
        ).first()
        
        if existing:
            print(f"⚠️ [Service] Session already analyzed: {session_id}")
            return None
        
        # Get user messages from session
        messages = store.get_session_messages(
            user_id=user_id,
            session_id=session_id,
            role="user"
        )
        
        if not messages:
            print(f"⚠️ [Service] No messages found in session: {session_id}")
            return None
        
        # Combine all messages
        combined_text = ". ".join([msg["content"] for msg in messages])
        text_stripped = combined_text.strip()
        
        # ⛔ CRITICAL: Emergency keyword bypass (NEVER skip these)
        # 심리 케어 서비스에서 절대 놓치면 안 되는 위험 신호
        emergency_keywords = [
            # 자살/자해 관련
            "죽고", "자살", "자해", "끝내", "사라지",
            # 심각한 감정
            "힘들", "우울", "불안", "괴로", "고통",
            # 극단적 표현
            "못 살", "살기 싫", "의미 없", "포기",
            # 도움 요청
            "도와줘", "살려줘", "SOS"
        ]
        
        has_emergency = any(keyword in text_stripped for keyword in emergency_keywords)
        
        if has_emergency:
            print(f"🚨 [EMERGENCY] Critical keywords detected in session {session_id} - MUST ANALYZE")
        
        # 🔍 Filter 1: Remove pure consonant/vowel noise (ㅎㅎㅎ, ㅋㅋㅋ)
        import re
        is_pure_noise = bool(re.match(r'^[ㄱ-ㅎㅏ-ㅣ\s.!?]+$', text_stripped))
        
        if is_pure_noise and not has_emergency:
            print(f"⏭️ [Service] Skipping session {session_id}: Pure consonant/vowel noise")
            analyzed_session = AnalyzedSession(SESSION_ID=session_id, USER_ID=user_id)
            db.add(analyzed_session)
            db.commit()
            return None
        
        # 🔍 Filter 2: Exact match with meaningless replies (정확히 일치할 때만)
        # "안녕, 나 이제 끝낼래" 같은 메시지가 스킵되는 것을 방지
        meaningless_exact = ["안녕", "ㅎㅎ", "ㅋㅋ", "네", "응", "ㅇㅇ", "ㄴㄴ", "okay", "ok", "yes", "no"]
        is_exact_match = text_stripped.lower() in meaningless_exact
        
        if is_exact_match and not has_emergency:
            print(f"⏭️ [Service] Skipping session {session_id}: Exact match with meaningless reply '{text_stripped}'")
            analyzed_session = AnalyzedSession(SESSION_ID=session_id, USER_ID=user_id)
            db.add(analyzed_session)
            db.commit()
            return None
        
        # 🔍 Filter 3: Ultra-short text (3자 미만) - but NEVER skip emergency keywords
        if len(text_stripped) < 3 and not has_emergency:
            print(f"⏭️ [Service] Skipping session {session_id}: Ultra-short text ({len(text_stripped)} chars)")
            analyzed_session = AnalyzedSession(SESSION_ID=session_id, USER_ID=user_id)
            db.add(analyzed_session)
            db.commit()
            return None
        
        print(f"📊 [Service] Analyzing session {session_id} with {len(messages)} messages")
        if has_emergency:
            print(f"🚨 [Service] PRIORITY ANALYSIS - Emergency keywords present")
        
        # 💾 Try cache first (캐시도 emergency는 건너뛰지 않음)
        cached_result = None
        try:
            from engine.langchain_agent.emotion_cache import get_emotion_cache
            cache = get_emotion_cache()
            cached_result = cache.search(
                query_text=combined_text,
                user_id=user_id,
                threshold=0.85,  # 85% similarity
                freshness_days=30
            )
            
            if cached_result:
                print(f"💾 [Service] Cache hit! Similarity: {cached_result['similarity']:.2%}, Age: {cached_result['age_days']} days")
                result = cached_result['result']
                
                # Save to TB_EMOTION_ANALYSIS (with cache flag)
                analysis_id = store.save_emotion_analysis(
                    user_id,
                    combined_text,
                    result,
                    check_root="conversation",
                    input_text_embedding=None  # Skip embedding generation for cached results
                )
                
                # Mark as analyzed
                analyzed_session = AnalyzedSession(SESSION_ID=session_id, USER_ID=user_id)
                db.add(analyzed_session)
                db.commit()
                
                return {
                    **result,
                    "analysis_id": analysis_id,
                    "message_count": len(messages),
                    "cached": True,
                    "cache_similarity": cached_result['similarity']
                }
        except Exception as cache_error:
            print(f"⚠️ [Service] Cache lookup error (proceeding with analysis): {cache_error}")
        
        # Run emotion analysis
        pipeline = get_rag_pipeline()
        result = pipeline.analyze_emotion(combined_text)
        
        # Generate embedding
        embedder = SentenceTransformer('jhgan/ko-sroberta-multitask')
        embedding = embedder.encode(combined_text).tolist()
        embedding_json = json.dumps(embedding)
        
        # Save to TB_EMOTION_ANALYSIS
        analysis_id = store.save_emotion_analysis(
            user_id,
            combined_text,
            result,
            check_root="conversation",
            input_text_embedding=embedding_json
        )
        
        # 💾 Save to cache for future reuse
        try:
            from engine.langchain_agent.emotion_cache import get_emotion_cache
            cache = get_emotion_cache()
            cache.save(user_id, combined_text, result, analysis_id)
            print(f"💾 [Service] Saved to cache: analysis_id={analysis_id}")
        except Exception as cache_error:
            print(f"⚠️ [Service] Failed to save cache: {cache_error}")
        
        # Mark as analyzed in TB_ANALYZED_SESSIONS
        analyzed_session = AnalyzedSession(
            SESSION_ID=session_id,
            USER_ID=user_id
        )
        db.add(analyzed_session)
        db.commit()
        
        print(f"✅ [Service] Analysis complete: session={session_id}, analysis_id={analysis_id}")
        
        # Return result with metadata
        return {
            **result,
            "analysis_id": analysis_id,
            "message_count": len(messages)
        }
        
    except Exception as e:
        db.rollback()
        print(f"❌ [Service] Analysis failed for session {session_id}: {e}")
        import traceback
        traceback.print_exc()
        raise
    finally:
        db.close()


def get_unanalyzed_sessions(limit: int = 100) -> list:
    """
    Get sessions that have not been analyzed yet
    
    Args:
        limit: Maximum number of sessions to return (default: 100)
        
    Returns:
        List of dicts with 'session_id' and 'user_id' keys
    """
    db = SessionLocal()
    
    try:
        from app.db.models import Conversation
        from sqlalchemy import distinct, and_
        
        # Get distinct sessions from conversations
        all_sessions = db.query(
            distinct(Conversation.SESSION_ID).label('session_id'),
            Conversation.USER_ID.label('user_id')
        ).filter(
            Conversation.IS_DELETED == 'N'
        ).group_by(
            Conversation.SESSION_ID,
            Conversation.USER_ID
        ).subquery()
        
        # Exclude already analyzed sessions
        unanalyzed = db.query(
            all_sessions.c.session_id,
            all_sessions.c.user_id
        ).outerjoin(
            AnalyzedSession,
            AnalyzedSession.SESSION_ID == all_sessions.c.session_id
        ).filter(
            AnalyzedSession.ID.is_(None)  # Not in analyzed sessions
        ).limit(limit).all()
        
        result = [
            {"session_id": row.session_id, "user_id": row.user_id}
            for row in unanalyzed
        ]
        
        print(f"📋 [Service] Found {len(result)} unanalyzed sessions")
        return result
        
    finally:
        db.close()
