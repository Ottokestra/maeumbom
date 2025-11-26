"""
사용자 일일 체크 상태 저장 관리
"""
from typing import Dict, Optional
from datetime import datetime, date
from pathlib import Path
import json
import os

# 테스트 모드: 환경변수로 제어 (기본값: True - 테스트 중에는 제한 없음)
# 실서비스 배포 시: DAILY_MOOD_CHECK_TEST_MODE=false로 설정
TEST_MODE = os.getenv("DAILY_MOOD_CHECK_TEST_MODE", "true").lower() == "true"


class DailyCheckStorage:
    """일일 체크 상태 저장소 (파일 기반)"""
    
    def __init__(self, storage_file: Optional[str] = None):
        """
        Args:
            storage_file: 저장 파일 경로 (None이면 기본 경로 사용)
        """
        if storage_file is None:
            # 기본 경로: daily_mood_check 폴더 내
            base_path = Path(__file__).parent
            storage_file = str(base_path / "daily_checks.json")
        
        self.storage_file = Path(storage_file)
        self._data: Dict[int, Dict] = {}
        self._load()
    
    def _load(self):
        """저장된 데이터 로드"""
        if self.storage_file.exists():
            try:
                with open(self.storage_file, 'r', encoding='utf-8') as f:
                    self._data = json.load(f)
            except Exception as e:
                print(f"Warning: Failed to load storage: {e}")
                self._data = {}
        else:
            self._data = {}
    
    def _save(self):
        """데이터 저장"""
        try:
            self.storage_file.parent.mkdir(parents=True, exist_ok=True)
            with open(self.storage_file, 'w', encoding='utf-8') as f:
                json.dump(self._data, f, ensure_ascii=False, indent=2)
        except Exception as e:
            print(f"Warning: Failed to save storage: {e}")
    
    def is_checked_today(self, user_id: int) -> bool:
        """오늘 체크했는지 확인"""
        # 테스트 모드에서는 항상 False 반환 (제한 없음)
        if TEST_MODE:
            return False
        
        if user_id not in self._data:
            return False
        
        last_check = self._data[user_id].get('last_check_date')
        if not last_check:
            return False
        
        try:
            last_date = datetime.fromisoformat(last_check).date()
            today = date.today()
            return last_date == today
        except:
            return False
    
    def get_status(self, user_id: int) -> Dict:
        """사용자의 체크 상태 조회"""
        if user_id not in self._data:
            return {
                "user_id": user_id,
                "completed": False,
                "last_check_date": None,
                "selected_image_id": None
            }
        
        return {
            "user_id": user_id,
            "completed": self.is_checked_today(user_id),
            "last_check_date": self._data[user_id].get('last_check_date'),
            "selected_image_id": self._data[user_id].get('selected_image_id')
        }
    
    def mark_checked(self, user_id: int, image_id: int):
        """체크 완료 표시"""
        if user_id not in self._data:
            self._data[user_id] = {}
        
        self._data[user_id]['last_check_date'] = datetime.now().isoformat()
        self._data[user_id]['selected_image_id'] = image_id
        self._save()
    
    def reset_daily(self):
        """일일 리셋 (자정에 호출 가능)"""
        # 필요시 구현 (현재는 날짜 비교로 처리)
        pass


# 전역 인스턴스
_storage_instance = None


def get_storage() -> DailyCheckStorage:
    """저장소 인스턴스 가져오기"""
    global _storage_instance
    if _storage_instance is None:
        _storage_instance = DailyCheckStorage()
    return _storage_instance

