"""
Celery tasks for emotion analysis
"""
from celery_app import celery_app
import logging

logger = logging.getLogger(__name__)

@celery_app.task(name="tasks.analyze_emotion")
def analyze_emotion_task(user_text: str, user_id: int):
    """
    Celery task: 감정분석 백그라운드 실행
    
    Args:
        user_text: 사용자 입력 텍스트
        user_id: 사용자 ID
        
    Returns:
        Dict with status and result info
    """
    try:
        logger.info(f"🔍 [Celery] Starting emotion analysis for user {user_id}")
        
        # Import inside task to avoid circular imports
        from engine.langchain_agent.agent_v2 import run_fast_track
        from engine.langchain_agent.db_conversation_store import get_conversation_store
        from engine.langchain_agent.emotion_cache import get_emotion_cache
        import asyncio
        import json
        
        # Run async function in sync context
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        
        try:
            emotion_response = loop.run_until_complete(
                run_fast_track(user_text, user_id=user_id)
            )
            
            if emotion_response.get("skipped"):
                logger.info("ℹ️  [Celery] Emotion analysis skipped")
                return {"status": "skipped"}
            
            emotion_result = emotion_response.get("result")
            if not emotion_result:
                return {"status": "no_result"}
            
            # Save to DB + ChromaDB cache
            if not emotion_response.get("cached"):
                # Sentence Transformer encoding (in executor to avoid blocking)
                def encode_text_sync():
                    from sentence_transformers import SentenceTransformer
                    embedder = SentenceTransformer('jhgan/ko-sroberta-multitask')
                    return embedder.encode(user_text).tolist()
                
                logger.info("🔍 [Celery] Encoding text with SentenceTransformer...")
                embedding = encode_text_sync()
                embedding_json = json.dumps(embedding)
                
                store = get_conversation_store()
                analysis_id = store.save_emotion_analysis(
                    user_id, user_text, emotion_result,
                    check_root="conversation",
                    input_text_embedding=embedding_json
                )
                
                if analysis_id:
                    cache = get_emotion_cache()
                    cache.save(
                        user_id=user_id,
                        input_text=user_text,
                        emotion_result=emotion_result,
                        analysis_id=analysis_id
                    )
                    logger.info(f"💾 [Celery] Saved: Analysis ID {analysis_id}")
            
            return {
                "status": "success",
                "cached": emotion_response.get("cached", False)
            }
            
        finally:
            loop.close()
            
    except Exception as e:
        logger.error(f"❌ [Celery] Task failed: {e}", exc_info=True)
        return {"status": "error", "error": str(e)}
