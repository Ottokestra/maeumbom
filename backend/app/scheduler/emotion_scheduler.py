"""
Emotion Analysis Scheduler
Runs daily at 3AM to analyze unprocessed chat sessions
"""
import sys
import importlib.util
from pathlib import Path
from apscheduler.schedulers.background import BackgroundScheduler
from apscheduler.triggers.cron import CronTrigger

# Path setup
backend_path = Path(__file__).parent.parent.parent
if str(backend_path) not in sys.path:
    sys.path.insert(0, str(backend_path))

# Import service module from emotion-analysis (hyphenated directory)
service_path = backend_path / "engine" / "emotion-analysis" / "api" / "service.py"
spec = importlib.util.spec_from_file_location("emotion_service", service_path)
emotion_service = importlib.util.module_from_spec(spec)
spec.loader.exec_module(emotion_service)

# Import functions from service module
analyze_session_emotion = emotion_service.analyze_session_emotion
get_unanalyzed_sessions = emotion_service.get_unanalyzed_sessions

# Create scheduler instance
scheduler = BackgroundScheduler()


def analyze_unprocessed_sessions():
    """
    Batch process all unanalyzed sessions
    Called daily at 3AM
    """
    print("=" * 80)
    print("🕒 [Scheduler] Starting daily emotion analysis batch job")
    print("=" * 80)
    
    try:
        # Get all unanalyzed sessions
        unanalyzed_sessions = get_unanalyzed_sessions(limit=1000)
        
        if not unanalyzed_sessions:
            print("✅ [Scheduler] No sessions to analyze")
            return
        
        print(f"📊 [Scheduler] Found {len(unanalyzed_sessions)} sessions to analyze")
        
        success_count = 0
        error_count = 0
        skip_count = 0
        
        # Process each session
        for session_data in unanalyzed_sessions:
            session_id = session_data['session_id']
            user_id = session_data['user_id']
            
            # Skip default sessions
            if session_id.endswith('_default'):
                print(f"⏭️  [Scheduler] Skipping default session: {session_id}")
                skip_count += 1
                continue
            
            try:
                result = analyze_session_emotion(user_id, session_id)
                
                if result:
                    success_count += 1
                    print(f"✅ [Scheduler] [{success_count}/{len(unanalyzed_sessions)}] Analyzed: {session_id}")
                else:
                    skip_count += 1
                    print(f"⏭️  [Scheduler] Skipped (no messages or duplicate): {session_id}")
                    
            except Exception as e:
                error_count += 1
                print(f"❌ [Scheduler] Error analyzing {session_id}: {e}")
        
        # Summary
        print("=" * 80)
        print(f"📈 [Scheduler] Batch job complete:")
        print(f"   ✅ Success: {success_count}")
        print(f"   ⏭️  Skipped: {skip_count}")
        print(f"   ❌ Errors:  {error_count}")
        print("=" * 80)
        
    except Exception as e:
        print(f"❌ [Scheduler] Fatal error in batch job: {e}")
        import traceback
        traceback.print_exc()


# Schedule daily at 3AM
scheduler.add_job(
    analyze_unprocessed_sessions,
    trigger=CronTrigger(hour=3, minute=0),
    id='emotion_analysis_daily',
    name='Daily Emotion Analysis',
    replace_existing=True
)


def start_scheduler():
    """Start the scheduler"""
    if not scheduler.running:
        scheduler.start()
        print("🚀 [Scheduler] Emotion analysis scheduler started")
        print("⏰ [Scheduler] Next run: Daily at 3:00 AM")


def shutdown_scheduler():
    """Shutdown the scheduler"""
    if scheduler.running:
        scheduler.shutdown()
        print("🛑 [Scheduler] Emotion analysis scheduler stopped")


# For manual testing
if __name__ == "__main__":
    print("🧪 [Test] Running manual emotion analysis batch job")
    analyze_unprocessed_sessions()
