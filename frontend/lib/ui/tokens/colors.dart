import 'package:flutter/material.dart';

class AppColors {
  static const accentRed = Color(0xFFD8454D);
  static const accentCoral = Color(0xFFE6757A);
  static const natureGreen = Color(0xFF2F6A53);
  static const errorRed = Color(0xFFC62828);
  static const lightPink = Color(0xFFF4E6E4);
  static const softMint = Color(0xFFCDE7DE);
  static const softGray = Color(0xFF8F8F8F);
  static const pureWhite = Color(0xFFFFFFFF);
  static const warmWhite = Color(0xFFFFFBFA);
  static const darkBlack = Color(0xFF000000);

  // Background
  static const bgBasic = pureWhite;
  static const bgWarm = warmWhite;
  static const bgLightPink = lightPink;
  static const bgSoftMint = softMint;
  static const bgRed = accentRed;
  static const bgGreen = natureGreen;

  // Text
  static const textWhite = pureWhite;
  static const textBlack = darkBlack;
  static const textPrimary = Color(0xFF233446);
  static const textSecondary = Color(0xFF6B6B6B);

  // Border
  static const borderLight = Color(0xFFF0EAE8);
  static const borderLightGray = Color(0xFFB0B0B0);

  // status colors
  static const secuess = natureGreen;
  static const error = errorRed;

  // Shadows
  static const accentRedShadow = Color(0x19D8454D); // 10% opacity red
  static const natureGreenShadow = Color(0x192F6A53); // 10% opacity green
  static const errorShadow = Color(0x66C62828); // 40% opacity error red

  // Disabled
  static const disabledBg = Color(0xFFF8F8F8);
  static const disabledBorder = Color(0xFFB0B0B0);
  static const disabledText = Color(0xFFB0B0B0);

  // Variant Text Colors
  static const textSecondaryRed = accentRed; // #D7454D
  static const textSecondaryGreen = natureGreen; // #2E6A52
  static const textDisabledVariant = Color(0xFF98A2B3); // Disabled variant text

  // Mood Category Theme Colors
  static const moodGoodYellow = Color(0xFFFFD749); // 좋음 - 연한 노란색
  static const moodNormalGreen = Color(0xFF8EE89C); // 보통 - 연한 초록색
  static const moodBadBlue = Color(0xFF8AA7E2); // 나쁨 - 연한 파란색

  // 오늘의 마음 상태
  static const homeGoodYellow = Color(0xFFFFB84C); // 좋음
  static const homeNormalGreen = Color(0xFF63C96B); // 보통
  static const homeBadBlue = Color(0xFF6C8CD5); // 나쁨

  // Emotion Colors - Primary & Secondary
  // 기쁨 (Happiness)
  static const emotionHappinessPrimary = Color(0xFFFFB84C);
  static const emotionHappinessSecondary = Color(0xFFFFD749);

  // 사랑 (Love)
  static const emotionLovePrimary = Color(0xFFFF6FAE);
  static const emotionLoveSecondary = Color(0xFFFF8EC3);

  // 안정 (Stability/Peace)
  static const emotionStabilityPrimary = Color(0xFF76D6FF);
  static const emotionStabilitySecondary = Color(0xFFA1E8FF);

  // 의욕 (Motivation)
  static const emotionMotivationPrimary = Color(0xFF63C96B);
  static const emotionMotivationSecondary = Color(0xFF8EE89C);

  // 분노 (Anger)
  static const emotionAngerPrimary = Color(0xFFFF5E4A);
  static const emotionAngerSecondary = Color(0xFFFF7A5C);

  // 걱정/우울 (Worry/Depression)
  static const emotionWorryPrimary = Color(0xFF6C8CD5);
  static const emotionWorrySecondary = Color(0xFF8AA7E2);

  // 혼란 (Confusion)
  static const emotionConfusionPrimary = Color(0xFFB28CFF);
  static const emotionConfusionSecondary = Color(0xFFC7A4FF);
}
