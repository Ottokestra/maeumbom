# backend/melo/app.py
"""
MeloTTS 원본 저장소의 Gradio WebUI 스크립트였던 파일.

AI-BOMI-TTS 프로젝트에서는
- FastAPI + tts_model.py 만 사용하고
- 이 WebUI는 사용하지 않으므로

외부 의존성(gradio, click 등)을 없애기 위해
더미 파일로 남겨둔 상태입니다.
"""


def main():
    print(
        "[MeloTTS WebUI] 이 프로젝트에서는 Gradio WebUI를 사용하지 않습니다.\n"
        "FastAPI 서버(main.py)만 실행하면 됩니다."
    )


if __name__ == "__main__":
    main()
