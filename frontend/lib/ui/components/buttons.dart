import 'package:flutter/material.dart';
import '../tokens/app_tokens.dart';

enum ButtonVariant { primaryRed, secondaryRed, primaryGreen, secondaryGreen }

class ButtonTokens {
  // 공통
  static const double height = 44;
  static const double radius = 30;
  static const EdgeInsets padding = EdgeInsets.symmetric(horizontal: 20);

  // ===== Primary - Accent Red =====
  static const Color primaryRedBg = AppColors.accentRed;
  static const Color primaryRedText = AppColors.textWhite;

  // ===== Secondary - Accent Red =====
  static const Color secondaryRedBg = AppColors.pureWhite;
  static const Color secondaryRedBorder = AppColors.accentRed;
  static const Color secondaryRedText = AppColors.accentRed;

  // ===== Primary - Nature Green =====
  static const Color primaryGreenBg = AppColors.natureGreen;
  static const Color primaryGreenText = AppColors.textWhite;

  // ===== Secondary - Nature Green =====
  static const Color secondaryGreenBg = AppColors.pureWhite;
  static const Color secondaryGreenBorder = AppColors.natureGreen;
  static const Color secondaryGreenText = AppColors.natureGreen;

  // 텍스트 스타일
  static final TextStyle textStyle =
      AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700);
}
