# backend/melo/api.py

import os
import re
import json
from typing import List

import numpy as np
import torch
import torch.nn as nn
from tqdm import tqdm
import soundfile  # wav 저장용

from . import utils
from . import commons
from .models import SynthesizerTrn
from .split_utils import split_sentence
from .mel_processing import spectrogram_torch, spectrogram_torch_conv
from .download_utils import load_or_download_config, load_or_download_model


class TTS(nn.Module):
    def __init__(
        self,
        language: str,
        device: str = "auto",
        use_hf: bool = True,
        config_path: str | None = None,
        ckpt_path: str | None = None,
    ):
        super().__init__()

        # ---------------------------------
        # 디바이스 선택
        # ---------------------------------
        if device == "auto":
            device = "cpu"
            if torch.cuda.is_available():
                device = "cuda"
            if torch.backends.mps.is_available():
                device = "mps"
        if "cuda" in device:
            assert torch.cuda.is_available()

        # ---------------------------------
        # 설정 / 모델 로드
        # ---------------------------------
        hps = load_or_download_config(
            language, use_hf=use_hf, config_path=config_path
        )

        num_languages = hps.num_languages
        num_tones = hps.num_tones
        symbols = hps.symbols

        model = SynthesizerTrn(
            len(symbols),
            hps.data.filter_length // 2 + 1,
            hps.train.segment_size // hps.data.hop_length,
            n_speakers=hps.data.n_speakers,
            num_tones=num_tones,
            num_languages=num_languages,
            **hps.model,
        ).to(device)

        model.eval()
        self.model = model
        self.symbol_to_id = {s: i for i, s in enumerate(symbols)}
        self.hps = hps
        self.device = device

        # 가중치 로드
        checkpoint_dict = load_or_download_model(
            language, device, use_hf=use_hf, ckpt_path=ckpt_path
        )
        self.model.load_state_dict(checkpoint_dict["model"], strict=True)

        language = language.split("_")[0]
        # 중국어는 ZH_MIX_EN 모델 사용
        self.language = "ZH_MIX_EN" if language == "ZH" else language

    # ------------------------------------------------------------------
    # 유틸 함수들
    # ------------------------------------------------------------------
    @staticmethod
    def audio_numpy_concat(
        segment_data_list: List[np.ndarray], sr: int, speed: float = 1.0
    ) -> np.ndarray:
        audio_segments = []
        for segment_data in segment_data_list:
            audio_segments += segment_data.reshape(-1).tolist()
            # 문장 사이에 약간의 공백 추가
            audio_segments += [0] * int((sr * 0.05) / speed)
        audio_segments = np.array(audio_segments).astype(np.float32)
        return audio_segments

    @staticmethod
    def split_sentences_into_pieces(text: str, language: str, quiet: bool = False):
        texts = split_sentence(text, language_str=language)
        if not quiet:
            print(" > Text split to sentences.")
            print("\n".join(texts))
            print(" > ===========================")
        return texts

    # ------------------------------------------------------------------
    # 메인 추론 함수
    # ------------------------------------------------------------------
    def tts_to_file(
        self,
        text: str,
        speaker_id: int,
        output_path: str | None = None,
        sdp_ratio: float = 0.2,
        noise_scale: float = 0.6,
        noise_scale_w: float = 0.8,
        speed: float = 1.0,
        pbar=None,
        format: str | None = None,
        position: int | None = None,
        quiet: bool = False,
    ):
        language = self.language
        texts = self.split_sentences_into_pieces(text, language, quiet)
        audio_list: list[np.ndarray] = []

        if pbar:
            tx = pbar(texts)
        else:
            if position:
                tx = tqdm(texts, position=position)
            elif quiet:
                tx = texts
            else:
                tx = tqdm(texts)

        for t in tx:
            if language in ["EN", "ZH_MIX_EN"]:
                t = re.sub(r"([a-z])([A-Z])", r"\1 \2", t)

            device = self.device
            bert, ja_bert, phones, tones, lang_ids = utils.get_text_for_tts_infer(
                t, language, self.hps, device, self.symbol_to_id
            )

            with torch.no_grad():
                x_tst = phones.to(device).unsqueeze(0)
                tones = tones.to(device).unsqueeze(0)
                lang_ids = lang_ids.to(device).unsqueeze(0)
                bert = bert.to(device).unsqueeze(0)
                ja_bert = ja_bert.to(device).unsqueeze(0)
                x_tst_lengths = torch.LongTensor([phones.size(0)]).to(device)
                del phones

                speakers = torch.LongTensor([speaker_id]).to(device)

                audio = (
                    self.model.infer(
                        x_tst,
                        x_tst_lengths,
                        speakers,
                        tones,
                        lang_ids,
                        bert,
                        ja_bert,
                        sdp_ratio=sdp_ratio,
                        noise_scale=noise_scale,
                        noise_scale_w=noise_scale_w,
                        length_scale=1.0 / speed,
                    )[0][0, 0]
                    .data.cpu()
                    .float()
                    .numpy()
                )

                del x_tst, tones, lang_ids, bert, ja_bert, x_tst_lengths, speakers

            audio_list.append(audio)

        torch.cuda.empty_cache()
        audio = self.audio_numpy_concat(
            audio_list, sr=self.hps.data.sampling_rate, speed=speed
        )

        if output_path is None:
            return audio

        # wav 파일로 저장
        if format:
            soundfile.write(
                output_path, audio, self.hps.data.sampling_rate, format=format
            )
        else:
            soundfile.write(output_path, audio, self.hps.data.sampling_rate)
