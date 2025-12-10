import React, { useEffect, useState, useRef } from "react";
import "./report-chat.css";

// 백엔드에서 내려주는 character_id를 프론트용 UI 정보로 매핑
const CHARACTER_MAP = {
  "worried-cloud": {
    label: "걱정이 구름이",
    emoji: "🌧️",
    bg: "linear-gradient(135deg, #dbeafe, #e0f2fe)",
  },
  "sad-rock": {
    label: "우울한 돌멩이",
    emoji: "🪨",
    bg: "linear-gradient(135deg, #e5e7eb, #d1d5db)",
  },
  "angry-fire": {
    label: "불꽃 화난이",
    emoji: "🔥",
    bg: "linear-gradient(135deg, #fee2e2, #fecaca)",
  },
  "tired-sloth": {
    label: "피곤한 나무늘보",
    emoji: "🦥",
    bg: "linear-gradient(135deg, #fef3c7, #fde68a)",
  },
  "happy-star": {
    label: "반짝이 별이",
    emoji: "⭐",
    bg: "linear-gradient(135deg, #fef9c3, #fef3c7)",
  },
};

const getCharacterUI = (characterId) => {
  if (!characterId) return CHARACTER_MAP["happy-star"];
  return CHARACTER_MAP[characterId] || CHARACTER_MAP["happy-star"];
};

function ReportChatPage() {
  const [session, setSession] = useState(null);
  const [input, setInput] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const messagesEndRef = useRef(null);

  const scrollToBottom = () => {
    if (messagesEndRef.current) {
      messagesEndRef.current.scrollIntoView({ behavior: "smooth" });
    }
  };

  useEffect(() => {
    const startChat = async () => {
      try {
        setIsLoading(true);
        const res = await fetch(
          "http://localhost:8000/api/reports/emotion/weekly/chat",
          {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ user_id: 1 }), // TODO: 로그인 된 유저 id로 교체
          }
        );
        const data = await res.json();
        setSession(data);
      } catch (e) {
        console.error("failed to start report chat", e);
      } finally {
        setIsLoading(false);
      }
    };

    startChat();
  }, []);

  useEffect(() => {
    scrollToBottom();
  }, [session]);

  const handleSend = async () => {
    if (!session || !input.trim()) return;

    const text = input.trim();
    setInput("");

    try {
      setIsLoading(true);
      const res = await fetch(
        `http://localhost:8000/api/reports/emotion/weekly/chat/${session.session_id}/messages`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ text }),
        }
      );
      const data = await res.json();
      setSession(data);
    } catch (e) {
      console.error("failed to send report chat message", e);
    } finally {
      setIsLoading(false);
    }
  };

  const handleKeyDown = (e) => {
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault();
      handleSend();
    }
  };

  return (
    <div className="report-chat-page">
      <div className="report-chat-card">
        <div className="report-chat-header">
          <h2>봄이와 리포트 이야기 나누기</h2>
          <p className="report-chat-subtitle">
            이번 주 감정 리포트를 바탕으로 봄이가 캐릭터와 함께 이야기해 줄게요.
          </p>
        </div>

        <div className="report-chat-body">
          {(!session || !session.messages) && (
            <div className="report-chat-empty">
              <p>대화를 준비하는 중이에요…</p>
            </div>
          )}

          {session && session.messages && (
            <div className="report-chat-messages">
              {session.messages.map((m) => {
                const isAssistant = m.role === "assistant";
                const charUI = isAssistant
                  ? getCharacterUI(m.character_id)
                  : null;

                return (
                  <div
                    key={m.id}
                    className={`chat-row ${
                      isAssistant ? "chat-row-left" : "chat-row-right"
                    }`}
                  >
                    {isAssistant && (
                      <div className="chat-avatar">
                        <div
                          className="chat-avatar-circle"
                          style={{ background: charUI.bg }}
                        >
                          <span className="chat-avatar-emoji">
                            {charUI.emoji}
                          </span>
                        </div>
                      </div>
                    )}

                    <div
                      className={`chat-bubble ${
                        isAssistant ? "chat-bubble-assistant" : "chat-bubble-user"
                      }`}
                    >
                      {isAssistant && (
                        <div className="chat-bubble-name">
                          {m.character_label || charUI.label}
                        </div>
                      )}
                      <div className="chat-bubble-text">
                        {m.text.split("\n").map((line, idx) => (
                          <p key={idx}>{line}</p>
                        ))}
                      </div>
                    </div>
                  </div>
                );
              })}
              <div ref={messagesEndRef} />
            </div>
          )}
        </div>

        <div className="report-chat-input-area">
          <textarea
            value={input}
            onChange={(e) => setInput(e.target.value)}
            onKeyDown={handleKeyDown}
            placeholder="이번 주에 가장 마음에 남는 일이나 감정을 적어볼래요?"
            rows={2}
          />
          <button
            type="button"
            className="report-chat-send-btn"
            onClick={handleSend}
            disabled={isLoading || !session || !input.trim()}
          >
            {isLoading ? "전송 중..." : "보내기"}
          </button>
        </div>

        <div className="report-chat-footer">
          <a href="/home" className="report-chat-home-link">
            봄이 홈으로 돌아가기
          </a>
        </div>
      </div>
    </div>
  );
}

export default ReportChatPage;
