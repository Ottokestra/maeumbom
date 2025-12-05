import { apiClient } from "./client";

export interface AgentCharacter {
  id: string;
  emotion_label: string;
}

export interface AgentResponse {
  reply_text: string;
  input_text: string;
  emotion_result: any;
  routine_result?: any;
  character?: AgentCharacter;
  meta?: any;
}

export async function callAgentText(userText: string, sessionId: string) {
  const resp = await apiClient.post<AgentResponse>("/agent/v2/text", {
    user_text: userText,
    session_id: sessionId,
  });
  return resp.data;
}
