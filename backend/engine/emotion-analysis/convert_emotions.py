"""
sample_emotions.json의 감정을 10개에서 17개로 변환하는 스크립트
"""
import json
from pathlib import Path

# 17개 감정 코드
EMOTION_CODES_17 = [
    "joy", "excitement", "confidence", "love", "relief", "enlightenment", "interest",
    "discontent", "shame", "sadness", "guilt", "depression", "boredom", "contempt", "anger", "fear", "confusion"
]

def map_emotion_to_17(old_emotion: str, text: str) -> str:
    """
    기존 10개 감정을 17개 감정으로 매핑
    
    Args:
        old_emotion: 기존 감정 코드
        text: 텍스트 내용
        
    Returns:
        새로운 17개 감정 코드
    """
    text_lower = text.lower()
    
    # 직접 매핑
    if old_emotion == "joy":
        # 기쁨 관련 키워드에 따라 excitement 또는 joy
        if any(kw in text_lower for kw in ["흥분", "신나", "설레", "두근", "떨려"]):
            return "excitement"
        return "joy"
    
    elif old_emotion == "calmness":
        # 평온/안심 → relief
        return "relief"
    
    elif old_emotion == "sadness":
        # 슬픔 → sadness 또는 depression
        if any(kw in text_lower for kw in ["우울", "무기력", "절망", "의미 없", "아무것도"]):
            return "depression"
        return "sadness"
    
    elif old_emotion == "anger":
        return "anger"
    
    elif old_emotion == "anxiety":
        # 불안 → fear
        return "fear"
    
    elif old_emotion == "loneliness":
        # 외로움 → sadness 또는 depression
        if any(kw in text_lower for kw in ["우울", "무기력", "절망"]):
            return "depression"
        return "sadness"
    
    elif old_emotion == "fatigue":
        # 피로 → depression 또는 boredom
        if any(kw in text_lower for kw in ["지루", "무료", "재미없", "싫증"]):
            return "boredom"
        if any(kw in text_lower for kw in ["우울", "무기력", "의미 없", "아무것도"]):
            return "depression"
        return "depression"  # 기본값
    
    elif old_emotion == "confusion":
        return "confusion"
    
    elif old_emotion == "guilt":
        return "guilt"
    
    elif old_emotion == "frustration":
        # 좌절 → discontent
        return "discontent"
    
    # 기본값 (없어야 하지만 안전장치)
    return "sadness"


def convert_sample_emotions():
    """sample_emotions.json 파일을 변환"""
    # 파일 경로
    script_dir = Path(__file__).parent
    data_file = script_dir / "data" / "raw" / "sample_emotions.json"
    
    # 데이터 로드
    print(f"Loading {data_file}...")
    with open(data_file, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    print(f"Total items: {len(data)}")
    
    # 기존 감정 분포 확인
    old_emotions = {}
    for item in data:
        old_emotion = item.get('emotion', '')
        old_emotions[old_emotion] = old_emotions.get(old_emotion, 0) + 1
    
    print("\n기존 감정 분포:")
    for emotion, count in sorted(old_emotions.items()):
        print(f"  {emotion}: {count}")
    
    # 변환
    converted_count = 0
    new_emotions = {}
    
    for item in data:
        old_emotion = item.get('emotion', '')
        text = item.get('text', '')
        
        new_emotion = map_emotion_to_17(old_emotion, text)
        item['emotion'] = new_emotion
        
        new_emotions[new_emotion] = new_emotions.get(new_emotion, 0) + 1
        
        if old_emotion != new_emotion:
            converted_count += 1
    
    print(f"\n변환된 항목 수: {converted_count}")
    print("\n새로운 감정 분포:")
    for emotion in EMOTION_CODES_17:
        count = new_emotions.get(emotion, 0)
        print(f"  {emotion}: {count}")
    
    # 백업 파일 생성
    backup_file = data_file.with_suffix('.json.backup')
    print(f"\n백업 파일 생성: {backup_file}")
    with open(backup_file, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    # 변환된 데이터 저장
    print(f"변환된 데이터 저장: {data_file}")
    with open(data_file, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    print("\n변환 완료!")


if __name__ == "__main__":
    convert_sample_emotions()

