# backend/melo/text/korean.py
"""
Korean text processing & BERT features for MeloTTS.

- 한글 → 음소(g2pkk + jamo) 변환
- kyKim 한국어 BERT(kykim/bert-kor-base)로 phone-level feature 추출
"""

import re
import sys
from typing import List

import torch
from transformers import AutoTokenizer, AutoModelForMaskedLM

from . import punctuation, symbols
from melo.text.ko_dictionary import english_dictionary, etc_dictionary
from jamo import hangul_to_jamo


# ----------------------------------------------------------------------
# 기본 정규화
# ----------------------------------------------------------------------
def normalize(text: str) -> str:
    text = text.strip()
    # 한자/일본어 범위 제거 (원본 MeloTTS 로직 유지)
    text = re.sub(
        "[⺀-⺙⺛-⻳⼀-⿕々〇〡-〩〸-〺〻㐀-䶵一-鿃豈-鶴侮-頻並-龎]", "", text
    )
    text = normalize_with_dictionary(text, etc_dictionary)
    text = normalize_english(text)
    text = text.lower()
    return text


def normalize_with_dictionary(text: str, dic: dict) -> str:
    if any(key in text for key in dic.keys()):
        pattern = re.compile("|".join(re.escape(key) for key in dic.keys()))
        return pattern.sub(lambda x: dic[x.group()], text)
    return text


def normalize_english(text: str) -> str:
    def fn(m):
        word = m.group()
        if word in english_dictionary:
            return english_dictionary.get(word)
        return word

    text = re.sub("([A-Za-z]+)", fn, text)
    return text


# ----------------------------------------------------------------------
# g2pkk 기반 한글 → 자모 변환
# ----------------------------------------------------------------------
g2p_kr = None


def korean_text_to_phonemes(text: str) -> str:
    """
    '하늘' 같은 문자열을 자모 단위 문자열로 변환.

        input  = '하늘'
        output = '하늘' (ᄒ + ᅡ + ᄂ + ᅳ + ᆯ)
    """
    global g2p_kr  # pylint: disable=global-statement
    if g2p_kr is None:
        from g2pkk import G2p

        g2p_kr = G2p()

    text = normalize(text)
    text = g2p_kr(text)
    text = list(hangul_to_jamo(text))  # '하늘' -> ['ᄒ','ᅡ','ᄂ','ᅳ','ᆯ']
    return "".join(text)


def text_normalize(text: str) -> str:
    return normalize(text)


def distribute_phone(n_phone: int, n_word: int) -> List[int]:
    """
    한 단어에 몇 개의 음소를 배분할지 결정하는 helper.
    """
    phones_per_word = [0] * n_word
    for _ in range(n_phone):
        min_tasks = min(phones_per_word)
        min_index = phones_per_word.index(min_tasks)
        phones_per_word[min_index] += 1
    return phones_per_word


# ----------------------------------------------------------------------
# BERT 토크나이저 / 모델
# ----------------------------------------------------------------------
model_id = "kykim/bert-kor-base"
tokenizer = AutoTokenizer.from_pretrained(model_id)

_bert_models: dict[str, AutoModelForMaskedLM] = {}  # device별 캐시


def g2p(norm_text: str):
    """
    norm_text(정규화된 문장)를 받아서
    - phones : 음소 시퀀스
    - tones  : 각 음소의 톤 (지금은 전부 0)
    - word2ph: BERT 토큰 1개당 몇 개의 음소가 연결되는지
    를 계산.
    """
    tokenized = tokenizer.tokenize(norm_text)

    phs: List[str] = []
    ph_groups: List[List[str]] = []

    # BERT 토큰 기준 그룹 분리
    for t in tokenized:
        if not t.startswith("#"):
            ph_groups.append([t])
        else:
            ph_groups[-1].append(t.replace("#", ""))

    word2ph: List[int] = []

    for group in ph_groups:
        text = "".join(group)

        if text == "[UNK]":
            phs.append("_")
            word2ph.append(1)
            continue
        elif text in punctuation:
            phs.append(text)
            word2ph.append(1)
            continue

        phonemes = korean_text_to_phonemes(text)
        phone_len = len(phonemes)
        word_len = len(group)

        aaa = distribute_phone(phone_len, word_len)
        assert len(aaa) == word_len

        word2ph += aaa
        phs += list(phonemes)

    phones = ["_"] + phs + ["_"]
    tones = [0 for _ in phones]
    # [CLS], [SEP] 역할의 앞뒤 1개씩 추가
    word2ph = [1] + word2ph + [1]

    assert len(word2ph) == len(tokenized) + 2
    return phones, tones, word2ph


def get_bert_feature(text: str, word2ph, device: str = "cuda"):
    """
    text, word2ph 를 받아서 phone-level BERT feature 를 반환.

    반환 형태: [hidden_dim, phone_len]
    """

    # Mac + MPS 환경 보정 (원본 japanese_bert 로직과 유사)
    if (
        sys.platform == "darwin"
        and torch.backends.mps.is_available()
        and device == "cpu"
    ):
        device = "mps"

    if not device:
        device = "cuda" if torch.cuda.is_available() else "cpu"

    # 디바이스별 BERT 모델 캐시
    if device not in _bert_models:
        model = AutoModelForMaskedLM.from_pretrained(model_id).to(device)
        _bert_models[device] = model
    else:
        model = _bert_models[device]

    with torch.no_grad():
        inputs = tokenizer(text, return_tensors="pt")
        for k in inputs:
            inputs[k] = inputs[k].to(device)

        res = model(**inputs, output_hidden_states=True)
        # 마지막 몇 개 레이어를 concat (원본과 비슷한 방식)
        res = torch.cat(res["hidden_states"][-3:-2], -1)[0].cpu()

    assert (
        inputs["input_ids"].shape[-1] == len(word2ph)
    ), f"{inputs['input_ids'].shape[-1]}/{len(word2ph)}"

    word2phone = word2ph
    phone_level_feature = []

    for i in range(len(word2phone)):
        repeat_feature = res[i].repeat(word2phone[i], 1)
        phone_level_feature.append(repeat_feature)

    phone_level_feature = torch.cat(phone_level_feature, dim=0)  # [T, hidden]
    return phone_level_feature.T  # [hidden, T]


if __name__ == "__main__":
    sample_text = "전 제 일의 가치와 폰타인 대중들이 한 일의 의미를 잘 압니다. 앞으로도 전 제 일에 자부심을 갖고 살아갈 겁니다"
    sample_text = text_normalize(sample_text)
    phones, tones, word2ph = g2p(sample_text)
    bert = get_bert_feature(sample_text, word2ph)

    print("phones[:30]:", phones[:30])
    print("len(tones):", len(tones))
    print("len(word2ph):", len(word2ph))
    print("bert.shape:", bert.shape)
