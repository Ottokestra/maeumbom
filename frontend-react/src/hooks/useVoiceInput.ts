import { useCallback, useEffect, useRef, useState } from "react";

interface UseVoiceInputOptions {
  onText: (text: string) => void;
}

export function useVoiceInput({ onText }: UseVoiceInputOptions) {
  const wsRef = useRef<WebSocket | null>(null);
  const [isRecording, setIsRecording] = useState(false);

  const stopRecording = useCallback(() => {
    if (wsRef.current) {
      wsRef.current.close();
      wsRef.current = null;
    }
    setIsRecording(false);
  }, []);

  const startRecording = useCallback(() => {
    try {
      const ws = new WebSocket("ws://localhost:8000/stt/stream");
      wsRef.current = ws;
      ws.onopen = () => setIsRecording(true);
      ws.onmessage = (event) => {
        try {
          const data = JSON.parse(event.data);
          const text = data?.text ?? data?.result ?? event.data;
          if (text) {
            onText(String(text));
          }
        } catch (err) {
          console.error("Failed to parse STT message", err);
        }
      };
      ws.onclose = () => setIsRecording(false);
      ws.onerror = () => setIsRecording(false);
    } catch (err) {
      console.error("Failed to start recording", err);
      setIsRecording(false);
    }
  }, [onText]);

  useEffect(() => {
    return () => stopRecording();
  }, [stopRecording]);

  return { isRecording, startRecording, stopRecording };
}
