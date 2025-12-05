import { FormEvent, useCallback, useEffect, useMemo, useRef, useState } from "react";
import { callAgentText, AgentCharacter } from "../api/agent";
import { fetchTtsAudio } from "../api/tts";
import { CharacterScene } from "./CharacterScene";
import { useVoiceInput } from "../hooks/useVoiceInput";
import "../styles/characterChatPage.css";

function formatDateLabel() {
  const date = new Date();
  return date.toLocaleDateString("ko-KR", {
    month: "long",
    day: "numeric",
    weekday: "short",
  });
}

export function CharacterChatPage() {
  const [inputText, setInputText] = useState("");
  const [currentReply, setCurrentReply] = useState("오늘의 이야기를 들려줄래요?");
  const [currentCharacter, setCurrentCharacter] = useState<AgentCharacter>();
  const [isLoading, setIsLoading] = useState(false);
  const [isSpeaking, setIsSpeaking] = useState(false);
  const audioRef = useRef<HTMLAudioElement | null>(null);
  const sessionId = useMemo(() => crypto.randomUUID(), []);

  const dateLabel = useMemo(() => formatDateLabel(), []);

  const stopAudio = useCallback(() => {
    if (audioRef.current) {
      audioRef.current.pause();
      audioRef.current.currentTime = 0;
      audioRef.current = null;
    }
  }, []);

  const playTts = useCallback(
    async (text: string, character?: AgentCharacter) => {
      try {
        const url = await fetchTtsAudio(text, character?.id, character?.emotion_label);
        stopAudio();
        const audio = new Audio(url);
        audioRef.current = audio;
        setIsSpeaking(true);
        audio.onended = () => setIsSpeaking(false);
        await audio.play();
      } catch (err) {
        console.error("TTS playback failed", err);
        setIsSpeaking(false);
      }
    },
    [stopAudio]
  );

  const handleSend = useCallback(
    async (text: string) => {
      if (!text.trim()) return;
      setIsLoading(true);
      setIsSpeaking(false);
      stopAudio();
      try {
        const response = await callAgentText(text, sessionId);
        setCurrentReply(response.reply_text);
        setCurrentCharacter(response.character);
        setInputText("");
        await playTts(response.reply_text, response.character);
      } catch (err) {
        console.error(err);
        setCurrentReply("네트워크에 문제가 생겼어요. 잠시 후 다시 시도해 주세요.");
      } finally {
        setIsLoading(false);
      }
    },
    [playTts, sessionId, stopAudio]
  );

  const onSubmit = (e: FormEvent) => {
    e.preventDefault();
    handleSend(inputText);
  };

  const shortcuts = [
    "오늘 하루를 한 줄로 요약해줘",
    "지금 감정 정리해줘",
  ];

  const { isRecording, startRecording, stopRecording } = useVoiceInput({
    onText: (text) => {
      setInputText(text);
      handleSend(text);
    },
  });

  useEffect(() => {
    return () => stopAudio();
  }, [stopAudio]);

  return (
    <div className="page">
      <header className="page-header">
        <div className="date-label">{dateLabel}</div>
        <div className="subtitle">오늘 마음 날씨를 알려줄게요</div>
      </header>

      <main className="content">
        <CharacterScene
          character={currentCharacter}
          replyText={currentReply}
          isSpeaking={isSpeaking}
          isLoading={isLoading}
        />
      </main>

      <footer className="input-area">
        <form className="input-row" onSubmit={onSubmit}>
          <input
            value={inputText}
            onChange={(e) => setInputText(e.target.value)}
            placeholder="봄이에게 오늘 이야기를 들려줄래요?"
            className="text-input"
            disabled={isLoading}
          />
          <div className="input-actions">
            <button
              type="button"
              className={`mic-btn ${isRecording ? "active" : ""}`}
              onClick={() => (isRecording ? stopRecording() : startRecording())}
              aria-label="음성 입력"
            >
              🎤
            </button>
            <button type="submit" className="send-btn" disabled={isLoading}>
              {isLoading ? "보내는 중" : "보내기"}
            </button>
          </div>
        </form>
        <div className="quick-actions">
          {shortcuts.map((text) => (
            <button key={text} className="quick-btn" onClick={() => handleSend(text)} disabled={isLoading}>
              {text}
            </button>
          ))}
        </div>
      </footer>
    </div>
  );
}
