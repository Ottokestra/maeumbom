# 🌸 마음봄(MaumBom) STT 프로토타입

갱년기 여성을 위한 감정 공감 AI 서비스의 실시간 음성 인식 프로토타입입니다.

## 📋 프로젝트 개요

마음봄은 음성 기반 감정 대화를 통해 사용자의 감정을 이해하고 공감하는 AI 서비스입니다.
이 프로토타입은 실시간 STT(Speech-to-Text) 기능을 2가지 방식으로 구현합니다.

### 페르소나
- **대상**: 54세 전업주부 (이정화)
- **니즈**: 감정을 이해받고, 말하지 않아도 마음을 알아주는 존재
- **목표**: 음성 대화를 통한 감정 공감 및 가족과의 소통 매개

## 🎯 프로토타입 구성

### 프로토타입 1: OpenAI Realtime API
- **특징**: WebSocket 기반 실시간 음성 스트리밍
- **VAD**: OpenAI 내장 VAD (Server VAD)
- **STT**: OpenAI Whisper (실시간 스트리밍)
- **장점**: 빠른 응답 속도, 높은 정확도
- **지연 시간**: 평균 200~500ms

### 프로토타입 2: Silero VAD + Faster-Whisper + Ollama
- **특징**: 오픈소스 기반 로컬 처리
- **VAD**: Silero VAD (발화 시작/종료 감지)
- **STT**: Faster-Whisper (실시간 세그먼트 스트리밍)
- **후처리**: Ollama (llama3.2:latest)
- **장점**: 로컬 처리, 실시간 스트리밍, 커스터마이징 가능
- **지연 시간**: 평균 200~700ms (STT) + 200ms (후처리)

## 🚀 설치 방법

### 1. 환경 준비

```bash
# Conda 환경 생성
conda create -n maumbom python=3.11
conda activate maumbom

# 프로젝트 클론 또는 이동
cd maumbom-prj-prototype

# 의존성 설치
pip install -r requirements.txt
```

### 2. 프로토타입 1 설정 (OpenAI Realtime API)

```bash
cd prototype1
```

`config.yaml` 파일에서 OpenAI API 키를 설정하세요:

```yaml
openai:
  api_key: "YOUR_OPENAI_API_KEY_HERE"  # 실제 API 키로 교체
```

### 3. 프로토타입 2 설정 (Silero VAD + Whisper + Ollama)

#### 3.1 Ollama 설치 및 실행

```bash
# Ollama 설치 (https://ollama.ai/)
# Windows: ollama-windows-amd64.exe 다운로드 및 실행

# 모델 다운로드
ollama pull llama3.2:latest

# Ollama 서버 실행
ollama serve
```

#### 3.2 Faster-Whisper 설치

Faster-Whisper는 자동으로 모델을 다운로드합니다:

```bash
pip install faster-whisper
```

첫 실행 시 자동으로 base 모델을 다운로드합니다 (약 142MB).

## 💻 실행 방법

### 프로토타입 1 실행

```bash
cd prototype1
python main.py
```

**출력 예시:**
```
🌸 마음봄(MaumBom) STT 프로토타입 1
   OpenAI Realtime API 기반
============================================================

🔗 OpenAI Realtime API에 연결 중...
✅ 연결 완료!

🎤 마이크 준비 완료 (샘플레이트: 24000Hz)
💬 대화를 시작하세요...

[발화 감지] 000.000초
[실시간] 안녕하
[실시간] 안녕하세요
[실시간] 안녕하세요 오늘
[발화 종료] 003.200초
[STT 완료] 003.450초 (지연: 250ms)

[최종 텍스트] 안녕하세요 오늘 기분이 좋지 않아요

📊 지연 시간 분석
============================================================
🎤 발화 지속 시간: 3200ms
⚡ STT 처리 시간: 250ms
📈 전체 처리 시간: 250ms
============================================================
```

### 프로토타입 2 실행

```bash
cd prototype2
python main.py
```

**출력 예시:**
```
🌸 마음봄(MaumBom) STT 프로토타입 2
   Silero VAD + Whisper.cpp + Ollama
============================================================

📥 Silero VAD 모델 로딩 중...
✅ Silero VAD 모델 로드 완료
📥 Whisper 모델 로딩 중...
✅ OpenAI Whisper 로드 완료
🔗 Ollama 연결: http://localhost:11434/v1
🤖 모델: llama3.2:latest
✅ Ollama 연결 성공

🎤 마이크 준비 완료. 말씀해주세요...
   (Ctrl+C로 종료)
============================================================

[발화 종료] 003.200초

🔄 음성 인식 중...
[실시간] 안녕하세요
[실시간] 안녕하세요 오늘
[실시간] 안녕하세요 오늘 기분이 좋지 않아요

[STT 완료] 안녕하세요 오늘 기분이 좋지 않아요
   (처리 시간: 450ms)

🔄 텍스트 후처리 중...
[후처리 완료] 안녕하세요. 오늘 기분이 좋지 않아요.
   (처리 시간: 180ms)

📊 지연 시간 분석
============================================================
🎤 발화 지속 시간: 3200ms
⚡ STT 처리 시간: 450ms
🔄 후처리 시간: 180ms
📈 전체 처리 시간: 630ms
⏱️  첫 부분 텍스트까지: 120ms
============================================================
```

## 📊 성능 비교

| 항목 | 프로토타입 1 (OpenAI) | 프로토타입 2 (로컬) |
|------|---------------------|-------------------|
| VAD | Server VAD | Silero VAD |
| STT 지연 | 200~500ms | 200~700ms |
| 후처리 | - | 200ms |
| 총 지연 | 200~500ms | 400~900ms |
| 실시간 스트리밍 | ✅ 지원 | ⚠️ 부분 지원 |
| 인터넷 필요 | ✅ 필요 | ❌ 불필요 (Ollama만) |
| 비용 | API 사용료 | 무료 (로컬) |
| 커스터마이징 | ❌ 제한적 | ✅ 자유로움 |

## 🔧 설정 커스터마이징

### VAD 임계값 조정
무음 감지가 너무 빠르거나 느리면 `config.yaml`에서 조정하세요:

```yaml
# 프로토타입 2
vad:
  threshold: 0.5  # 음성 감지 민감도 (0.3~0.7 권장)
  min_silence_duration_ms: 2000  # 무음 감지 시간 (2000~3000ms)
```

### Whisper 모델 변경
더 높은 정확도가 필요하면 모델 크기를 변경하세요:

```yaml
whisper:
  model_size: "small"  # tiny, base, small, medium, large
```

## 📁 프로젝트 구조

```
maumbom-prj-prototype/
├── README.md                 # 이 파일
├── requirements.txt          # 의존성 패키지
├── common/                   # 공통 모듈
│   ├── audio_handler.py     # 마이크 입력 처리
│   └── latency_tracker.py   # 지연 시간 측정
├── prototype1/               # 프로토타입 1
│   ├── main.py              # OpenAI Realtime API
│   └── config.yaml          # 설정 파일
└── prototype2/               # 프로토타입 2
    ├── main.py              # 통합 메인
    ├── vad_engine.py        # Silero VAD
    ├── whisper_engine.py    # Whisper STT
    ├── llm_processor.py     # Ollama 후처리
    └── config.yaml          # 설정 파일
```

## ⚠️ 문제 해결

### 마이크 입력 오류
```bash
# PyAudio 설치 실패 시 (Windows)
pip install pipwin
pipwin install pyaudio
```

### Ollama 연결 실패
```bash
# Ollama 서버 실행 확인
ollama serve

# 모델 다운로드 확인
ollama list
ollama pull llama3.2:latest
```

### Faster-Whisper 설치 문제
```bash
# Faster-Whisper 재설치
pip uninstall faster-whisper -y
pip install faster-whisper
```

## 🔮 향후 개발 계획

- [ ] Flutter 앱 통합 (WebSocket 통신)
- [ ] 감정 분석 기능 추가
- [ ] 대화 히스토리 저장
- [ ] 감정 리포트 생성
- [ ] 가족 공유 기능
- [ ] 감정 회복 루틴 추천

## 📝 라이센스

이 프로젝트는 MIT 라이센스를 따릅니다.

## 👥 개발자

마음봄(MaumBom) 프로젝트 팀

---

**마음봄**: 당신의 마음에 봄이 찾아옵니다 🌸

