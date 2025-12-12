import os
from pathlib import Path

import numpy as np
import sounddevice as sd
import soundfile as sf
from dotenv import load_dotenv

import torch
from transformers import AutoModelForSpeechSeq2Seq, AutoProcessor, pipeline
from openai import OpenAI

from melo.api import TTS as MeloTTS


# ===== 0. 기본 설정 & 환경 변수 =====
load_dotenv()

OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
if not OPENAI_API_KEY:
    print("❌ .env에 OPENAI_API_KEY를 설정해주세요.")
    raise SystemExit(1)

openai_client = OpenAI(api_key=OPENAI_API_KEY)

SAMPLE_RATE = 16000
CHANNELS = 1
BLOCK_SEC = 10  # 한 번에 10초씩 녹음

# 🔊 무음 감지 설정
SILENCE_THRESHOLD = 500  # 이 값보다 작으면 거의 무음으로 간주
SILENT_ROUNDS_FOR_HINT = 2  # 연속 몇 번 무음일 때 대기 멘트

# 종료 키워드
END_KEYWORDS = [
    "종료",
    "그만",
    "끝",
    "나갈게",
    "나갈게 진짜",
    "상담종료",
    "상담종료해줘",
    "상담 종료",
    "상담 종료해줘",
]


def is_end_command(text: str) -> bool:
    """사용자 발화에 종료 관련 표현이 들어있는지 확인"""
    if not text:
        return False
    t = text.strip().replace(" ", "")  # '상담 종료' → '상담종료'
    for kw in END_KEYWORDS:
        if kw.replace(" ", "") in t:
            return True
    return False


# ===== 1. Whisper large-v3-turbo 로딩 (STT) =====
WHISPER_MODEL_ID = "openai/whisper-large-v3-turbo"

whisper_device = "cuda:0" if torch.cuda.is_available() else "cpu"
whisper_dtype = torch.float16 if torch.cuda.is_available() else torch.float32

print(
    f"[Whisper] {WHISPER_MODEL_ID} 로딩 중... (device={whisper_device}, dtype={whisper_dtype})"
)

whisper_model = AutoModelForSpeechSeq2Seq.from_pretrained(
    WHISPER_MODEL_ID,
    torch_dtype=whisper_dtype,
    low_cpu_mem_usage=True,
).to(whisper_device)

whisper_processor = AutoProcessor.from_pretrained(WHISPER_MODEL_ID)

whisper_pipe = pipeline(
    task="automatic-speech-recognition",
    model=whisper_model,
    tokenizer=whisper_processor.tokenizer,
    feature_extractor=whisper_processor.feature_extractor,
    torch_dtype=whisper_dtype,
    device=0 if torch.cuda.is_available() else -1,
    chunk_length_s=20,
    batch_size=4 if torch.cuda.is_available() else 1,
    return_timestamps=False,
)


# ===== 2. MeloTTS 로딩 (3-7 봄이 목소리) =====
MELO_DEVICE = "cuda" if torch.cuda.is_available() else "cpu"
print(f"[MeloTTS] device = {MELO_DEVICE}")

melo_tts = MeloTTS(language="KR", device=MELO_DEVICE)
MELO_SPEAKER_ID = 0  # 3-7에서 쓰던 speaker_id 값으로 필요시 조정


# ===== 3. 마이크에서 한 번 녹음 =====
def record_once(seconds: int = BLOCK_SEC):
    """
    마이크에서 seconds초 만큼 녹음하고,
    소리 크기가 너무 작으면 None을 리턴해서 '침묵'으로 처리한다.
    """
    print(f"\n🎙 {seconds}초 동안 말씀해 주세요...")
    audio = sd.rec(
        int(seconds * SAMPLE_RATE),
        samplerate=SAMPLE_RATE,
        channels=CHANNELS,
        dtype="int16",
    )
    sd.wait()

    audio_int16 = audio.flatten()

    # 최대 진폭으로 무음 여부 판단
    max_amp = int(np.max(np.abs(audio_int16)))
    # print(f"[DEBUG] max_amp={max_amp}")

    if max_amp < SILENCE_THRESHOLD:
        print("😶 거의 소리가 감지되지 않았습니다. (대기모드 후보)")
        return None

    return audio_int16


# ===== 4. Whisper STT =====
def stt_whisper(audio_int16: np.ndarray) -> str:
    """
    마이크에서 받은 int16 PCM 배열을 그대로 Whisper에 넣어서
    한국어 텍스트로 변환한다. (ffmpeg 필요 X)
    """
    print("🧠 STT(Whisper): 변환 중...")

    # int16 → float32, -1.0 ~ 1.0 범위로 스케일링
    audio_float = audio_int16.astype(np.float32) / 32768.0

    result = whisper_pipe(
        audio_float,
        generate_kwargs={"task": "transcribe", "language": "ko"},
    )

    text = (result["text"] or "").strip()
    print(f"📝 인식 결과: {text}")
    return text


# ===== 5. 봄이 TTS (MeloTTS) =====
def tts_bomi(text: str):
    """봄이 TTS: MeloTTS(3-7 봄이 목소리)"""
    if not text:
        return

    print("🔊 TTS(Melo 봄이): 재생 중...")

    out_path = "bomi_tts.wav"

    melo_tts.tts_to_file(
        text,
        speaker_id=MELO_SPEAKER_ID,
        output_path=out_path,
        speed=1.0,  # 필요하면 0.9, 1.1 이런 식으로 조정
    )

    audio_np, sr = sf.read(out_path, dtype="int16")
    sd.play(audio_np, sr)
    sd.wait()


# ===== 6. LLM (OpenAI) - 봄이 상담사 =====
SYSTEM_PROMPT = (
    "당신은 '봄이'라는 이름의 따뜻한 한국어 감정 상담사입니다. "
    "대답은 항상 3문장 이내로, 다음 형식을 지킵니다. "
    "1) 사용자의 감정을 한 문장으로 공감하며 요약합니다. "
    "2) 왜 그런 감정을 느끼게 되었는지 부드럽게 한 가지 질문을 합니다. "
    "3) 오늘 당장 해볼 수 있는 작은 행동 한 가지를 제안합니다. "
    "항상 한국어 존댓말을 사용하고, 뉴스나 계절 설명은 하지 마세요."
)

history = []  # 최근 몇 턴만 유지


def chat_with_bomi(user_text: str) -> str:
    global history

    messages = [{"role": "system", "content": SYSTEM_PROMPT}]
    messages.extend(history)
    messages.append({"role": "user", "content": user_text})

    print("🤖 LLM: 상담 답변 생성 중...")
    resp = openai_client.chat.completions.create(
        model="gpt-4o-mini",
        messages=messages,
        max_tokens=200,
        temperature=0.7,
    )
    answer = resp.choices[0].message.content.strip()
    print(f"💬 봄이: {answer}")

    history.append({"role": "user", "content": user_text})
    history.append({"role": "assistant", "content": answer})
    history[:] = history[-10:]  # 최근 10 메시지만 유지

    return answer


# ===== 7. 메인 루프 =====
def main():
    print("=== 봄이 음성 상담 데모 (Whisper STT + MeloTTS + OpenAI LLM) ===")
    print("종료하려면 '종료', '그만', '끝' 같이 말씀해 주세요.\n")

    silent_rounds = 0  # 연속 무음 횟수

    while True:
        try:
            # 1) 녹음
            audio_int16 = record_once(BLOCK_SEC)

            # 2) 침묵이면 -> STT/LLM 호출 안 하고 ‘대기 멘트’ 관리
            if audio_int16 is None:
                silent_rounds += 1

                if silent_rounds >= SILENT_ROUNDS_FOR_HINT:
                    wait_msg = (
                        "지금은 잠시 조용한 시간이네요. "
                        "혹시 더 대화하고 싶으신 내용이 있으실까요? "
                        "천천히 생각해 보시고, 준비되시면 편하게 말씀해 주세요."
                    )
                    print(f"💬 봄이(대기): {wait_msg}")
                    tts_bomi(wait_msg)
                    silent_rounds = 0
                continue

            # 말이 감지되면 카운터 리셋
            silent_rounds = 0

            # 3) STT (Whisper)
            text = stt_whisper(audio_int16)
            if not text:
                print("❗ 인식된 텍스트가 없습니다. 다시 시도해 주세요.")
                continue

            # 4) 종료 키워드
            if is_end_command(text):
                bye_msg = (
                    "오늘 대화는 여기까지 할게요. 함께 이야기 나눠 주셔서 감사합니다."
                )
                print(f"💬 봄이: {bye_msg}")
                tts_bomi(bye_msg)
                break

            # 5) LLM 상담
            reply = chat_with_bomi(text)

            # 6) 봄이 TTS로 바로 읽어주기
            tts_bomi(reply)

        except KeyboardInterrupt:
            print("\n👋 Ctrl+C로 대화를 종료합니다.")
            break


if __name__ == "__main__":
    main()
