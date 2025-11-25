# backend/melo/text/__init__.py

from .symbols import *  # symbols, language_id_map, language_tone_start_map 등을 포함

# 심볼 → ID 매핑 (공통)
_symbol_to_id = {s: i for i, s in enumerate(symbols)}


def cleaned_text_to_sequence(cleaned_text, tones, language, symbol_to_id=None):
    """
    cleaner.clean_text() 에서 나온 결과를
    (phones, tones, lang_ids) 형태로 변환한다.

    이번 프로젝트에서는 LANGUAGE = "KR" 만 사용하지만,
    혹시 다른 값이 들어와도 기본적으로 'KR' 로 처리하도록 방어 코드를 넣어두었다.
    """
    # 혹시라도 중국어/영어 같은 다른 코드가 들어오면 한국어로 통일
    if language not in language_id_map:
        language = "KR"

    symbol_to_id_map = symbol_to_id if symbol_to_id is not None else _symbol_to_id

    # 텍스트(음소)를 심볼 ID 시퀀스로 변환
    phones = [symbol_to_id_map[symbol] for symbol in cleaned_text]

    # 톤 인덱스에 언어별 시작 offset 적용 (한국어는 0이지만, map에서 안전하게 가져옴)
    tone_start = language_tone_start_map.get(language, 0)
    tones = [t + tone_start for t in tones]

    # 언어 ID 시퀀스 (한국어 한 종류만 사용)
    lang_id = language_id_map.get(language, language_id_map.get("KR", 0))
    lang_ids = [lang_id for _ in phones]

    return phones, tones, lang_ids


def get_bert(norm_text, word2ph, language, device):
    """
    BERT 임베딩을 얻는 함수.

    ※ 한국어 전용 버전
    - 중국어/영어/일본어/프랑스어/스페인어 등은 아예 지원하지 않는다.
    - 항상 korean.py 안의 get_bert_feature 만 사용한다.
    """
    # 혹시 'ZH', 'EN' 같은 값이 들어와도 무시하고 한국어로 고정
    from .korean import get_bert_feature as kr_bert

    # language 인자는 더 이상 분기용으로 쓰지 않고, 한국어만 처리
    return kr_bert(norm_text, word2ph, device)
