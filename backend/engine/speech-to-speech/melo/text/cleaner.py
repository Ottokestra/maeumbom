# backend/melo/text/cleaner.py
"""
한국어 전용 간소화 버전.

- 일본어 / 중국어 등은 전혀 import 하지 않음 (MeCab 일본어 사전 X)
- MeloTTS에서 기대하는 인터페이스(4개 값 반환)를 그대로 맞춰 줌.
"""

from __future__ import annotations

import copy
from typing import List, Tuple

from . import korean          # ✅ 한국어 모듈만 사용
from . import cleaned_text_to_sequence

LANGUAGE_KR = "KR"


def clean_text(text: str, language: str = LANGUAGE_KR):
    """
    MeloTTS 내부에서 호출하는 기본 정제 함수.

    원래는 다국어 모듈에서 골라 쓰지만,
    이 프로젝트에서는 한국어만 쓸 거라서
    넘어온 language 값과 상관없이 항상 korean 모듈만 사용한다.

    반환:
        norm_text: 정규화된 텍스트 (str)
        phones: 음소 시퀀스 (list[str])
        tones: 각 음소에 대한 tone 정보 (list[int] 등)
        word2ph: 단어 → 음소 index 매핑 (list[int])
    """
    text = str(text or "").strip()
    if not text:
        # 완전 빈 텍스트일 때는 안전한 기본값
        return "", [], [], [0]

    # 한국어 전용 정규화 + g2p
    norm_text = korean.text_normalize(text)
    phones, tones, word2ph = korean.g2p(norm_text)

    # g2p 구현이 문자열을 돌려줄 수도 있으니 방어적으로 처리
    if isinstance(phones, str):
        phones = phones.split()
    if isinstance(tones, str):
        tones = [int(t) for t in tones.split()] if tones else []
    if isinstance(word2ph, str):
        word2ph = [int(w) for w in word2ph.split()] if word2ph else []

    return norm_text, phones, tones, word2ph


def clean_text_bert(text: str, language: str = LANGUAGE_KR, device=None):
    """
    학습용 BERT prosody 인터페이스를 위한 더미 구현.

    지금 프로젝트에서는 BERT 특징을 실제로 쓰지 않으니까
    bert 는 None 으로만 돌려주고, 시그니처만 맞춰 둔다.
    """
    norm_text, phones, tones, word2ph = clean_text(text, language)
    word2ph_bak = copy.deepcopy(word2ph)
    bert = None
    return norm_text, phones, tones, word2ph_bak, bert


def text_to_sequence(text: str, language: str = LANGUAGE_KR):
    """
    (훈련 코드 호환용) 텍스트를 정수 시퀀스로 변환.
    런타임 TTS에서는 거의 안 쓰이지만, 원래 인터페이스를 유지.
    """
    norm_text, phones, tones, word2ph = clean_text(text, language)
    return cleaned_text_to_sequence(phones, tones, language)


if __name__ == "__main__":
    # 간단 수동 테스트용
    sample = "오늘 하루 어떠셨나요? 피곤하지는 않으셨어요?"
    print(clean_text(sample, "KR"))
