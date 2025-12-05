import { motion } from "framer-motion";
import { useMemo } from "react";
import { AgentCharacter } from "../api/agent";
import { CharacterMeta, getCharacterMeta } from "../characters/characterMap";
import "../styles/characterScene.css";

interface CharacterSceneProps {
  character?: AgentCharacter;
  replyText: string;
  isSpeaking: boolean;
  isLoading?: boolean;
}

export function CharacterScene({
  character,
  replyText,
  isSpeaking,
  isLoading,
}: CharacterSceneProps) {
  const meta: CharacterMeta | undefined = useMemo(
    () => getCharacterMeta(character?.id),
    [character?.id]
  );

  return (
    <div className="scene">
      <div className="scene-card">
        <div className="scene-glow" />
        <div className="character-wrapper">
          <motion.div
            className="character-avatar"
            animate={{ y: isSpeaking ? [0, -8, 0] : [0] }}
            transition={{ duration: isSpeaking ? 1 : 2, repeat: isSpeaking ? Infinity : Infinity, ease: "easeInOut" }}
          >
            {meta ? (
              <motion.img
                src={meta.image}
                alt={meta.labelKo}
                className="character-image"
                initial={{ scale: 0.95 }}
                animate={{ scale: isSpeaking ? 1.05 : 1 }}
                transition={{ duration: 0.6 }}
              />
            ) : (
              <div className="character-placeholder">봄이</div>
            )}
            {isSpeaking && <div className="sparkles" aria-hidden />}
          </motion.div>
        </div>

        <div className="speech-bubble">
          {isLoading ? (
            <div className="loading-text">봄이가 생각 중이에요…</div>
          ) : (
            <p className="speech-text">{replyText || "봄이가 준비됐어요."}</p>
          )}
        </div>
        <div className="emotion-label">
          오늘 봄이의 감정: {character?.emotion_label ?? "미정"}
        </div>
        {meta && (
          <div className="character-meta">
            <div className="character-name">{meta.labelKo}</div>
            <div className="character-desc">{meta.description}</div>
          </div>
        )}
      </div>
    </div>
  );
}
