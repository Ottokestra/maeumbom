"""
Eleven Labs v3 TTS API 테스트 스크립트

사용법:
    python test_elevenlabs_tts.py

환경 변수:
    ELEVENLABS_API_KEY: .env 파일에 설정되어 있어야 함
"""

import sys
from pathlib import Path

# 프로젝트 루트를 sys.path에 추가
backend_path = Path(__file__).resolve().parent
tts_path = backend_path / "engine" / "text-to-speech"
sys.path.insert(0, str(tts_path))

print("=" * 60)
print("Eleven Labs v3 TTS API 테스트")
print("=" * 60)
print(f"TTS 모듈 경로: {tts_path}")
print()

try:
    from tts_model import synthesize_to_wav
    print("✅ tts_model 모듈 로드 성공")
except ImportError as e:
    print(f"❌ tts_model 모듈 로드 실패: {e}")
    sys.exit(1)

# 테스트 케이스
test_cases = [
    "안녕하세요, 이것은 Eleven Labs API 테스트입니다.",
    "오늘 하루는 어떻게 보내셨나요?",
    "마음이 편안해지는 음악을 들어보시는 건 어떨까요?",
]

print("\n테스트 시작...\n")

for i, text in enumerate(test_cases, 1):
    print(f"[테스트 {i}/{len(test_cases)}] 텍스트: {text}")
    try:
        output_path = synthesize_to_wav(text=text, tone="neutral")
        print(f"✅ 성공! 파일 생성: {output_path}")
        print(f"   파일 크기: {output_path.stat().st_size} bytes")
    except Exception as e:
        print(f"❌ 실패: {e}")
    print()

print("=" * 60)
print("테스트 완료")
print("=" * 60)
