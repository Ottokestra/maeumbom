import { apiClient } from "./client";

export async function fetchTtsAudio(
  text: string,
  characterId?: string,
  emotionLabel?: string,
  engine?: string
): Promise<string> {
  const resp = await apiClient.post(
    "/api/tts",
    {
      text,
      character_id: characterId,
      emotion_label: emotionLabel,
      engine,
    },
    { responseType: "blob" }
  );

  const blobUrl = URL.createObjectURL(resp.data);
  return blobUrl;
}
