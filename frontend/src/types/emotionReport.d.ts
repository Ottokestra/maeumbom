export interface DailyEmotionSticker {
  day_label: string;
  date: string;
  emotion_code: string;
  character_key: string;
  label: string;
}

export interface WeeklyEmotionReport {
  week_start: string;
  week_end: string;
  summary_title: string;
  main_emotion_code: string;
  main_character_key: string;
  temperature: number;
  temperature_label: string;
  gauge_color?: string | null;
  daily_stickers: DailyEmotionSticker[];
  badges?: string[];
  decorations?: string[];
}
