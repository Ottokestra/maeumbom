# backend/melo/text/cleaner.py
"""
MeloTTS용 최소 cleaner – 한국어 전용 버전.

원래 MeloTTS는 chinese / japanese / english 등 여러 모듈을 한 번에 import 하는데,
일본어(japanese) 쪽에서 MeCab + unidic 사전이 필요해서 Windows 환경에서 자주 터진다.

이번 프로젝트는 LANGUAGE="KR" (한국어)만 사용할 것이므로,
다국어 처리는 과감히 제거하고, 한국어 텍스트에 대한
최소한의 전처리만 수행하는 clean_text 함수만 남긴다.
"""


def clean_text(text: str, language: str) -> str:
    """
    한국어 전용 텍스트 정리 함수.

    Parameters
    ----------
    text : str
        입력 텍스트 (한국어 문장)
    language : str
        언어 코드. 이번 프로젝트에서는 "KR" 만 쓴다.

    Returns
    -------
    str
        간단히 앞뒤 공백만 제거한 텍스트.
        (MeloTTS 한국어 모델은 추가 형태소 분석 없이도 잘 동작한다.)
    """
    if not isinstance(text, str):
        text = str(text)

    # language 인자는 인터페이스 맞추기용. KR만 허용.
    lang = (language or "").upper()
    if lang not in ("KR", "KO", "KOR"):
        # 혹시 잘못 호출되면 바로 알려주기
        raise ValueError(f"한국어만 지원합니다. 받은 language={language!r}")

    return text.strip()
