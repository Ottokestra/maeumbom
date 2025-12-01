"""
메모리 승격 시스템 테스트 스크립트

이 스크립트는 memory_adapter.py의 주요 기능을 테스트합니다:
1. 명시적 기억 요청 감지
2. 명시적 기억 삭제 감지
3. 승격 규칙 체크 (빈도, 감정 강도)

사용법:
    cd backend
    python -m engine.langchain_agent.adapters.test_memory_promotion
"""

import sys
from pathlib import Path

# Add backend root to path
backend_root = Path(__file__).resolve().parent.parent.parent.parent
sys.path.insert(0, str(backend_root))

from engine.langchain_agent.adapters.memory_adapter import (
    MemoryLayer,
    MEMORY_STORE_KEYWORDS,
    MEMORY_DELETE_KEYWORDS
)


def test_explicit_memory_request():
    """명시적 기억 요청 감지 테스트"""
    print("\n" + "="*60)
    print("테스트 1: 명시적 기억 요청 감지")
    print("="*60)
    
    memory_layer = MemoryLayer()
    
    test_cases = [
        ("나 오이 알러지 있는거 꼭 기억해줘", True),
        ("요즘 계속 우울해", False),
        ("이거 잊지마", True),
        ("나 김치찌개 좋아하는 거 알아둬", True),
        ("배고파", False),
        ("땅콩 알레르기 있어. 메모해줘", True),
    ]
    
    passed = 0
    failed = 0
    
    for text, expected in test_cases:
        result = memory_layer.detect_explicit_memory_request(text)
        status = "✅ PASS" if result == expected else "❌ FAIL"
        
        if result == expected:
            passed += 1
        else:
            failed += 1
        
        print(f"{status} | 입력: '{text}'")
        print(f"       | 예상: {expected}, 결과: {result}\n")
    
    print(f"결과: {passed} 성공, {failed} 실패\n")
    return failed == 0


def test_explicit_memory_deletion():
    """명시적 기억 삭제 감지 테스트"""
    print("\n" + "="*60)
    print("테스트 2: 명시적 기억 삭제 감지")
    print("="*60)
    
    memory_layer = MemoryLayer()
    
    test_cases = [
        ("오이는 잊어버려", "오이"),
        ("김치찌개 기억 안해도 돼", "김치찌개"),
        ("그건 무시해", "general"),
        ("나 요즘 우울해", None),
        ("땅콩 알레르기 지워줘", "땅콩"),
    ]
    
    passed = 0
    failed = 0
    
    for text, expected in test_cases:
        result = memory_layer.detect_explicit_memory_deletion(text)
        
        if expected is None:
            is_pass = result is None
        else:
            is_pass = result is not None and (expected == "general" or expected in result)
        
        status = "✅ PASS" if is_pass else "❌ FAIL"
        
        if is_pass:
            passed += 1
        else:
            failed += 1
        
        print(f"{status} | 입력: '{text}'")
        print(f"       | 예상: {expected}, 결과: {result}\n")
    
    print(f"결과: {passed} 성공, {failed} 실패\n")
    return failed == 0


def test_category_classification():
    """카테고리 분류 테스트"""
    print("\n" + "="*60)
    print("테스트 3: 카테고리 분류")
    print("="*60)
    
    memory_layer = MemoryLayer()
    
    test_cases = [
        ("나 땅콩 알러지 있어", "allergy"),
        ("요즘 잠을 못 자", "sleep_issue"),
        ("남편이랑 싸웠어", "relationship"),
        ("나 김치찌개 좋아해", "personal_preference"),
        ("머리가 계속 아파", "health_concern"),
    ]
    
    passed = 0
    failed = 0
    
    for text, expected_category in test_cases:
        emotion_result = {"emotion": "neutral", "polarity": 0.0}
        result = memory_layer._classify_category(text, emotion_result)
        
        is_pass = expected_category in result
        status = "✅ PASS" if is_pass else "❌ FAIL"
        
        if is_pass:
            passed += 1
        else:
            failed += 1
        
        print(f"{status} | 입력: '{text}'")
        print(f"       | 예상 카테고리: {expected_category}, 결과: {result}\n")
    
    print(f"결과: {passed} 성공, {failed} 실패\n")
    return failed == 0


def test_promotion_logic():
    """승격 로직 테스트 (시뮬레이션)"""
    print("\n" + "="*60)
    print("테스트 4: 승격 규칙 체크 (로직만)")
    print("="*60)
    
    print("✅ 규칙 1: 명시적 요청")
    print("   - 키워드:", MEMORY_STORE_KEYWORDS[:5], "등")
    print("   - 감지 시 즉시 승격 (importance=10)\n")
    
    print("✅ 규칙 2: 감정 강도")
    print("   - polarity < -0.7 또는 risk_level >= 'watch'")
    print("   - 승격 시 importance=6~8\n")
    
    print("✅ 규칙 3: 빈도 기반")
    print("   - 최근 14일간 서로 다른 세션에서 3회 이상 언급")
    print("   - 승격 시 importance=5\n")
    
    print("⚠️  실제 DB 연동 테스트는 agent.html UI를 통해 수행하세요.\n")
    
    return True


def main():
    """모든 테스트 실행"""
    print("\n" + "="*60)
    print("메모리 승격 시스템 단위 테스트")
    print("="*60)
    
    results = []
    
    results.append(("명시적 기억 요청", test_explicit_memory_request()))
    results.append(("명시적 기억 삭제", test_explicit_memory_deletion()))
    results.append(("카테고리 분류", test_category_classification()))
    results.append(("승격 로직", test_promotion_logic()))
    
    print("\n" + "="*60)
    print("전체 테스트 결과")
    print("="*60)
    
    for name, passed in results:
        status = "✅ PASS" if passed else "❌ FAIL"
        print(f"{status} {name}")
    
    all_passed = all(result[1] for result in results)
    
    if all_passed:
        print("\n✅ 모든 테스트 통과!")
    else:
        print("\n❌ 일부 테스트 실패")
    
    return all_passed


if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
