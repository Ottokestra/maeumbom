import sys
import os
from engine.routine_recommend.engine import RoutineRecommendFromEmotionEngine
from engine.routine_recommend.models.schemas import EmotionAnalysisResult

# 경로 강제 추가
sys.path.append(os.getcwd())

print("🚀 Start Simple Test")

try:
    from backend.engine.routine_recommend.engine import RoutineRecommendFromEmotionEngine
    print("✅ Import Success")
    
    engine = RoutineRecommendFromEmotionEngine()
    print("✅ Engine Init Success")
    
except Exception as e:
    print(f"❌ Error: {e}")