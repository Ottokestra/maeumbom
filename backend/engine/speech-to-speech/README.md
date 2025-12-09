<div align="center">
  <img src="logo.png" width="480" />
</div>

# 봄이 음성 상담 데모

Whisper STT + OpenAI LLM + (로컬/ElevenLabs) TTS 를 이용해서  
음성으로 대화하는 감정 상담 데모를 구현한 프로젝트입니다.

기본 파이프라인은 Hugging Face의 [speech-to-speech](https://github.com/huggingface/speech-to-speech) 레포를 참고했고,  
`bomi_s2s_simple.py` 파일에 **봄이 전용 간소화 버전**을 구현했습니다.

---

## ✨ 기능 요약

- 🎙 **음성 입력**
  - 마이크로 10초 단위 녹음 (`sounddevice`)
  - 입력 음량을 기준으로 **침묵 / 발화 자동 구분**

- 🧠 **STT (음성 → 텍스트)**
  - 기본: Hugging Face `openai/whisper-large-v3-turbo` (Transformers 파이프라인)
  - 선택: ElevenLabs STT로 교체 가능 (코드 내 함수 변경)

- 💬 **LLM 상담사 (봄이)**
  - OpenAI `gpt-4o-mini` 사용
  - 시스템 프롬프트로 “따뜻한 한국어 감정 상담사 봄이” 페르소나 설정
  - 항상 3문장 이내로 공감 + 질문 + 작은 행동 제안

- 🔊 **TTS (텍스트 → 음성)**
  - 기본: `pyttsx3` 로컬 TTS (완전 무료)
  - 선택: ElevenLabs TTS + 커스텀 봄이 목소리 사용 가능

- 😶 **침묵 감지 & 대기 멘트**
  - 연속으로 말이 감지되지 않으면:
    > “지금은 잠시 조용한 시간이네요… 준비되시면 편하게 말씀해 주세요.”
  - 자동으로 봄이 음성으로 안내

- 📴 **음성으로 종료**
  - 다음과 같은 말이 인식되면 대화 종료:
    - `종료`, `그만`, `끝`, `나갈게`, `상담종료`, `상담 종료해줘` 등

---

## 🧩 프로젝트 구조(중요 파일)

```bash
speech-to-speech/
├─ bomi_s2s_simple.py     # 봄이 음성 상담 메인 스크립트
├─ bomi_input.wav         # 입력 음성 임시 파일 (gitignore 대상)
├─ bomi_tts.wav           # 출력 음성 임시 파일 (사용 여부에 따라)
├─ .env                   # API 키 저장 (gitignore 대상)
├─ requirements.txt       # 의존성 목록
├─ README.md              # 현재 문서
├─ STT/ LLM/ TTS/ ...     # 원본 speech-to-speech 모듈들
└─ s2s_pipeline.py        # 원본 전체 파이프라인 (선택적으로 사용)


# 1) 새 가상환경
python -m venv .venv
.\.venv\Scripts\activate

# 2) 의존성 설치
pip install --upgrade pip
pip install -r requirements.txt

# 3) .env 파일에 키 넣기
# OPENAI_API_KEY=YOUR_OPENAI_API_KEY_HERE

# 4) 실행
python bomi_s2s_simple.py