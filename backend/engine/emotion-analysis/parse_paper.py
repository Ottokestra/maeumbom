"""
PDF 논문 파싱 스크립트
논문에서 감정 분석 기준을 추출하여 현재 구현과 비교
"""
import PyPDF2
from pathlib import Path
import re
import json

# 경로 설정
script_dir = Path(__file__).parent
# emotion-analysis -> engine -> backend -> 프로젝트 루트
project_root = script_dir.parent.parent.parent
pdf_path = project_root / "감정분석(최신).pdf"

# 파일이 없으면 glob으로 찾기
if not pdf_path.exists():
    pdf_files = list(project_root.glob("*.pdf"))
    if pdf_files:
        pdf_path = pdf_files[0]
        print(f"PDF 파일 자동 발견: {pdf_path}")


def extract_text_from_pdf(pdf_path):
    """PDF에서 텍스트 추출"""
    try:
        with open(pdf_path, 'rb') as file:
            pdf_reader = PyPDF2.PdfReader(file)
            num_pages = len(pdf_reader.pages)
            
            print(f"PDF 파일 로드 완료: 총 {num_pages}페이지\n")
            
            full_text = ""
            for page_num in range(num_pages):
                page = pdf_reader.pages[page_num]
                text = page.extract_text()
                full_text += f"\n--- 페이지 {page_num + 1} ---\n{text}\n"
            
            return full_text, num_pages
    except Exception as e:
        print(f"PDF 읽기 오류: {e}")
        return None, 0


def search_emotion_keywords(text):
    """감정 관련 키워드 검색"""
    keywords = [
        '17개', '감정', 'emotion', '군집', 'cluster', 
        '긍정', '부정', 'positive', 'negative',
        'Valence', 'Arousal', 'VA', 'valence', 'arousal',
        '기쁨', '슬픔', '화', '공포', '불안', '우울',
        'joy', 'sadness', 'anger', 'fear', 'depression'
    ]
    
    found_sections = {}
    
    for keyword in keywords:
        pattern = re.compile(re.escape(keyword), re.IGNORECASE)
        matches = list(pattern.finditer(text))
        if matches:
            found_sections[keyword] = []
            for match in matches[:5]:  # 최대 5개만
                start = max(0, match.start() - 300)
                end = min(len(text), match.end() + 500)
                context = text[start:end]
                found_sections[keyword].append({
                    'position': match.start(),
                    'context': context
                })
    
    return found_sections


def extract_emotion_list(text):
    """17개 감정 목록 추출 시도"""
    # 다양한 패턴으로 감정 목록 찾기
    patterns = [
        r'17개\s*감정[:\s]*([^0-9]{50,2000})',
        r'감정\s*목록[:\s]*([^0-9]{50,2000})',
        r'emotion\s*list[:\s]*([^0-9]{50,2000})',
        r'긍정\s*그룹[:\s]*([^부정]{100,1000})',
        r'부정\s*그룹[:\s]*([^긍정]{100,1000})',
    ]
    
    emotion_sections = []
    for pattern in patterns:
        matches = re.finditer(pattern, text, re.IGNORECASE)
        for match in matches:
            emotion_sections.append(match.group(1))
    
    return emotion_sections


def extract_va_coordinates(text):
    """VA 좌표값 추출 시도"""
    # Valence, Arousal 좌표 패턴 찾기
    va_patterns = [
        r'valence[:\s]*([-]?[0-9.]+)[\s,]*arousal[:\s]*([-]?[0-9.]+)',
        r'V[:\s]*([-]?[0-9.]+)[\s,]*A[:\s]*([-]?[0-9.]+)',
        r'\(([-]?[0-9.]+)[\s,]*([-]?[0-9.]+)\)',  # (V, A) 형식
    ]
    
    va_coordinates = []
    for pattern in va_patterns:
        matches = re.finditer(pattern, text, re.IGNORECASE)
        for match in matches:
            try:
                v = float(match.group(1))
                a = float(match.group(2))
                if -1.0 <= v <= 1.0 and -1.0 <= a <= 1.0:
                    va_coordinates.append({
                        'valence': v,
                        'arousal': a,
                        'context': text[max(0, match.start()-100):min(len(text), match.end()+100)]
                    })
            except:
                pass
    
    return va_coordinates


def analyze_paper():
    """논문 분석 메인 함수"""
    print("=" * 80)
    print("논문 분석 시작")
    print("=" * 80)
    
    if not pdf_path.exists():
        print(f"오류: PDF 파일을 찾을 수 없습니다: {pdf_path}")
        return None
    
    # PDF 텍스트 추출
    text, num_pages = extract_text_from_pdf(pdf_path)
    if not text:
        return None
    
    print(f"\n텍스트 추출 완료: {len(text)} 문자\n")
    
    # 키워드 검색
    print("키워드 검색 중...")
    keywords_found = search_emotion_keywords(text)
    
    # 감정 목록 추출
    print("감정 목록 추출 중...")
    emotion_sections = extract_emotion_list(text)
    
    # VA 좌표 추출
    print("VA 좌표 추출 중...")
    va_coordinates = extract_va_coordinates(text)
    
    # 결과 정리
    result = {
        'total_pages': num_pages,
        'text_length': len(text),
        'keywords_found': keywords_found,
        'emotion_sections': emotion_sections,
        'va_coordinates': va_coordinates,
        'full_text': text[:50000] if len(text) > 50000 else text  # 처음 50000자만 저장
    }
    
    # 결과를 JSON으로 저장
    output_path = script_dir / "paper_analysis.json"
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(result, f, ensure_ascii=False, indent=2)
    
    print(f"\n분석 결과 저장: {output_path}")
    print(f"키워드 발견: {len(keywords_found)}개")
    print(f"감정 섹션 발견: {len(emotion_sections)}개")
    print(f"VA 좌표 발견: {len(va_coordinates)}개")
    
    return result


if __name__ == "__main__":
    result = analyze_paper()
    if result:
        print("\n분석 완료!")
    else:
        print("\n분석 실패!")

