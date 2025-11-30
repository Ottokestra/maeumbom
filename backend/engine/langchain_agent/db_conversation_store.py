"""
DB-based Conversation Store
Replaces InMemoryConversationStore with database persistence
"""
from typing import List, Dict, Optional, Any
from datetime import datetime
from sqlalchemy.orm import Session
from sqlalchemy import desc, and_, func

from app.db.database import SessionLocal
from app.db.models import Conversation, User

# Import vectorstore for RAG sync
# Note: Using local import inside methods to avoid circular import if necessary, 
# but here we can try top-level if no circular dependency exists.
# However, agent.py imports both, so let's be safe and import inside methods or use a helper.
# Actually, conversation_vectorstore does not import db_conversation_store, so top level is fine.
# But to be absolutely safe against future circular deps, we'll import inside methods or use a getter.

class DBConversationStore:
    """
    Database-backed conversation storage with user isolation
    
    Features:
    - User-based data isolation (USER_ID filtering)
    - Soft delete (IS_DELETED = 'Y'/'N')
    - Automatic session/message limits (LRU/FIFO)
    - Full audit trail (CREATED_BY, UPDATED_BY)
    """
    
    def __init__(
        self,
        max_sessions_per_user: int = 100,
        max_messages_per_session: int = 50
    ):
        """
        Initialize DB conversation store
        
        Args:
            max_sessions_per_user: Maximum sessions per user (default: 100)
            max_messages_per_session: Maximum messages per session (default: 50)
        """
        self.max_sessions = max_sessions_per_user
        self.max_messages = max_messages_per_session
    
    def _get_db(self) -> Session:
        """Get database session"""
        return SessionLocal()
    
    # def _get_vectorstore(self):
    #     """Get vectorstore instance (lazy import)"""
    #     try:
    #         from .conversation_vectorstore import get_conversation_vectorstore
    #         return get_conversation_vectorstore()
    #     except ImportError:
    #         print("[DBConversationStore] ⚠️ VectorStore import failed")
    #         return None

    def add_message(
        self,
        user_id: int,
        session_id: str,
        role: str,
        content: str,
        metadata: Optional[Dict] = None
    ) -> None:
        """
        Add a message to the conversation history
        
        Args:
            user_id: User ID (for data isolation and audit)
            session_id: Session identifier
            role: Message role ("user" or "assistant")
            content: Message content
            metadata: Additional metadata (optional, not stored currently)
        """
        db = self._get_db()
        try:
            # Map role to SPEAKER_TYPE
            # For now, we use "user-A" for all users and "assistant" for AI
            speaker_type = "assistant" if role == "assistant" else "user-A"
            
            # Create conversation record
            conversation = Conversation(
                USER_ID=user_id,
                SESSION_ID=session_id,
                SPEAKER_TYPE=speaker_type,
                CONTENT=content,
                IS_DELETED='N',
                CREATED_BY=user_id,
                UPDATED_BY=None
            )
            
            db.add(conversation)
            db.commit()
            
            # Apply message limit (FIFO - delete oldest)
            self.cleanup_old_messages(user_id, session_id, db)
            
            # Apply session limit (LRU - delete least recently used)
            self.cleanup_old_sessions(user_id, db)
            
        finally:
            db.close()
    
    def get_history(
        self,
        user_id: int,
        session_id: str,
        limit: Optional[int] = None
    ) -> List[Dict]:
        """
        Get conversation history for a session
        
        Args:
            user_id: User ID (for data isolation)
            session_id: Session identifier
            limit: Maximum number of messages to return (most recent)
        
        Returns:
            List of message dictionaries
        """
        db = self._get_db()
        try:
            query = db.query(Conversation).filter(
                and_(
                    Conversation.USER_ID == user_id,
                    Conversation.SESSION_ID == session_id,
                    Conversation.IS_DELETED == 'N'
                )
            ).order_by(Conversation.CREATED_AT.asc())
            
            if limit:
                # Get last N messages
                total = query.count()
                if total > limit:
                    query = query.offset(total - limit)
            
            messages = query.all()
            
            # Convert to dict format
            return [
                {
                    "role": "assistant" if msg.SPEAKER_TYPE == "assistant" else "user",
                    "content": msg.CONTENT,
                    "timestamp": msg.CREATED_AT.isoformat(),
                    "message_id": msg.ID
                }
                for msg in messages
            ]
        finally:
            db.close()
    
    def get_user_sessions(self, user_id: int) -> List[Dict[str, Any]]:
        """
        Get all active sessions for a user
        
        Args:
            user_id: User ID
        
        Returns:
            List of session metadata dictionaries
        """
        db = self._get_db()
        try:
            # Get unique sessions with metadata
            sessions = db.query(
                Conversation.SESSION_ID,
                func.count(Conversation.ID).label('message_count'),
                func.min(Conversation.CREATED_AT).label('created_at'),
                func.max(Conversation.CREATED_AT).label('last_activity_at')
            ).filter(
                and_(
                    Conversation.USER_ID == user_id,
                    Conversation.IS_DELETED == 'N'
                )
            ).group_by(Conversation.SESSION_ID).order_by(desc('last_activity_at')).all()
            
            result = []
            for session in sessions:
                # Get first message for preview (user's first message)
                first_msg = db.query(Conversation.CONTENT).filter(
                    and_(
                        Conversation.USER_ID == user_id,
                        Conversation.SESSION_ID == session.SESSION_ID,
                        Conversation.SPEAKER_TYPE == 'user-A',
                        Conversation.IS_DELETED == 'N'
                    )
                ).order_by(Conversation.CREATED_AT.asc()).first()
                
                preview = first_msg.CONTENT if first_msg else "새로운 대화"
                
                result.append({
                    "session_id": session.SESSION_ID,
                    "message_count": session.message_count,
                    "created_at": session.created_at.isoformat(),
                    "last_activity_at": session.last_activity_at.isoformat(),
                    "first_message": preview,
                    "status": "active"
                })
            
            return result
        finally:
            db.close()
    
    def get_session_metadata(self, user_id: int, session_id: str) -> Optional[Dict]:
        """
        Get metadata for a specific session
        
        Args:
            user_id: User ID
            session_id: Session identifier
        
        Returns:
            Session metadata dictionary or None
        """
        sessions = self.get_user_sessions(user_id)
        for session in sessions:
            if session["session_id"] == session_id:
                return session
        return None
    
    def clear_session(self, user_id: int, session_id: str) -> None:
        """
        Soft delete a session (set IS_DELETED = 'Y')
        
        Args:
            user_id: User ID (for authorization)
            session_id: Session identifier
        """
        db = self._get_db()
        try:
            db.query(Conversation).filter(
                and_(
                    Conversation.USER_ID == user_id,
                    Conversation.SESSION_ID == session_id,
                    Conversation.IS_DELETED == 'N'
                )
            ).update({
                "IS_DELETED": 'Y',
                "UPDATED_BY": user_id,
                "UPDATED_AT": datetime.now()
            })
            db.commit()
            
            # Sync with RAG: Delete session (Legacy V1 제거로 인해 비활성화)
            # vectorstore = self._get_vectorstore()
            # if vectorstore:
            #     vectorstore.delete_session(user_id, session_id)
                
        finally:
            db.close()
    
    def cleanup_old_messages(
        self,
        user_id: int,
        session_id: str,
        db: Session = None
    ) -> None:
        """
        Apply FIFO limit: soft delete oldest messages if exceeds limit
        
        Args:
            user_id: User ID
            session_id: Session identifier
            db: Database session (optional, for transaction)
        """
        close_db = False
        if db is None:
            db = self._get_db()
            close_db = True
        
        try:
            # Count active messages
            count = db.query(Conversation).filter(
                and_(
                    Conversation.USER_ID == user_id,
                    Conversation.SESSION_ID == session_id,
                    Conversation.IS_DELETED == 'N'
                )
            ).count()
            
            if count > self.max_messages:
                # Get oldest messages to delete
                messages_to_delete = db.query(Conversation).filter(
                    and_(
                        Conversation.USER_ID == user_id,
                        Conversation.SESSION_ID == session_id,
                        Conversation.IS_DELETED == 'N'
                    )
                ).order_by(Conversation.CREATED_AT.asc()).limit(
                    count - self.max_messages
                ).all()
                
                # Soft delete
                for msg in messages_to_delete:
                    msg.IS_DELETED = 'Y'
                    msg.UPDATED_BY = user_id
                    msg.UPDATED_AT = datetime.now()
                
                db.commit()
                print(f"[DBConversationStore] Cleaned up {len(messages_to_delete)} old messages (session: {session_id})")
                
                # Sync with RAG: Delete oldest messages (Legacy V1 제거로 인해 비활성화)
                # vectorstore = self._get_vectorstore()
                # if vectorstore:
                #     vectorstore.delete_oldest_messages(user_id, session_id, self.max_messages)
                    
        finally:
            if close_db:
                db.close()
    
    def cleanup_old_sessions(self, user_id: int, db: Session = None) -> None:
        """
        Apply LRU limit: soft delete oldest sessions if exceeds limit
        
        Args:
            user_id: User ID
            db: Database session (optional, for transaction)
        """
        close_db = False
        if db is None:
            db = self._get_db()
            close_db = True
        
        try:
            # Get session last activity times
            session_activities = db.query(
                Conversation.SESSION_ID,
                func.max(Conversation.CREATED_AT).label('last_activity')
            ).filter(
                and_(
                    Conversation.USER_ID == user_id,
                    Conversation.IS_DELETED == 'N'
                )
            ).group_by(Conversation.SESSION_ID).all()
            
            if len(session_activities) > self.max_sessions:
                # Sort by last activity (oldest first)
                sorted_sessions = sorted(
                    session_activities,
                    key=lambda x: x.last_activity
                )
                
                # Delete oldest sessions
                sessions_to_delete = sorted_sessions[:len(session_activities) - self.max_sessions]
                
                for session in sessions_to_delete:
                    # Soft delete all messages in session
                    db.query(Conversation).filter(
                        and_(
                            Conversation.USER_ID == user_id,
                            Conversation.SESSION_ID == session.SESSION_ID,
                            Conversation.IS_DELETED == 'N'
                        )
                    ).update({
                        "IS_DELETED": 'Y',
                        "UPDATED_BY": user_id,
                        "UPDATED_AT": datetime.now()
                    })
                    
                    # Sync with RAG: Delete session (Legacy V1 제거로 인해 비활성화)
                    # vectorstore = self._get_vectorstore()
                    # if vectorstore:
                    #     vectorstore.delete_session(user_id, session.SESSION_ID)
                        
                db.commit()
                print(f"[DBConversationStore] Cleaned up {len(sessions_to_delete)} old sessions (user: {user_id})")
        finally:
            if close_db:
                db.close()
    
    def hard_delete_all_conversations(self, user_id: int) -> int:
        """
        Permanently delete ALL conversations for a user (test/admin only)
        
        Args:
            user_id: User ID
        
        Returns:
            Number of deleted records
        """
        db = self._get_db()
        try:
            count = db.query(Conversation).filter(
                Conversation.USER_ID == user_id
            ).delete()
            db.commit()
            return count
        finally:
            db.close()


# Global instance (singleton pattern)
_db_conversation_store = None


def get_conversation_store() -> DBConversationStore:
    """
    Get global conversation store instance
    
    Returns:
        DBConversationStore instance
    """
    global _db_conversation_store
    if _db_conversation_store is None:
        _db_conversation_store = DBConversationStore()
    return _db_conversation_store
