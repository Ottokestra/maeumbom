"""
API 테스트 스크립트
"""
import requests
import json

BASE_URL = "http://localhost:8000"

def test_health():
    """Health check 테스트"""
    print("\n=== Health Check ===")
    response = requests.get(f"{BASE_URL}/api/health")
    print(f"Status: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2, ensure_ascii=False)}")
    return response.status_code == 200

def test_init():
    """Vector DB 초기화 테스트"""
    print("\n=== Initialize Vector DB ===")
    response = requests.post(f"{BASE_URL}/api/init")
    print(f"Status: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2, ensure_ascii=False)}")
    return response.status_code == 200

def test_analyze(text):
    """감정 분석 테스트"""
    print(f"\n=== Analyze: '{text}' ===")
    response = requests.post(
        f"{BASE_URL}/api/analyze",
        json={"text": text}
    )
    print(f"Status: {response.status_code}")
    if response.status_code == 200:
        result = response.json()
        print(f"주요 감정: {result['primary_emotion']} (강도: {result['primary_intensity']})")
        print(f"감정 점수:")
        for emotion, score in sorted(result['emotions'].items(), key=lambda x: x[1], reverse=True):
            print(f"  {emotion}: {score}")
        if result['similar_contexts']:
            print(f"유사 컨텍스트 {len(result['similar_contexts'])}개 발견")
    else:
        print(f"Error: {response.text}")
    return response.status_code == 200

def main():
    """메인 테스트 실행"""
    print("=" * 50)
    print("감정 분석 API 테스트")
    print("=" * 50)
    
    # 1. Health check
    if not test_health():
        print("\n❌ Health check 실패. 서버가 실행 중인지 확인하세요.")
        return
    
    # 2. Vector DB 초기화 (이미 초기화되어 있으면 스킵 가능)
    test_init()
    
    # 3. 감정 분석 테스트
    test_texts = [
        "오늘 정말 기분이 좋아요!",
        "요즘 너무 피곤하고 아무것도 하기 싫어요",
        "가족들에게 자꾸 화를 내게 돼요",
        "밤에 잠을 못 자서 너무 불안해요",
        "아무도 저를 이해해주지 않는 것 같아요"
    ]
    
    for text in test_texts:
        test_analyze(text)
    
    print("\n" + "=" * 50)
    print("✅ 모든 테스트 완료")
    print("=" * 50)

if __name__ == "__main__":
    main()

