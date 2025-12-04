import 'package:flutter/material.dart';
import '../tokens/app_tokens.dart';

enum InputState { normal, focus, success, disabled, error }

class InputTokens {
  static const double height = 44;
  static const double radius = 14;
  static const EdgeInsets padding =
      EdgeInsets.symmetric(horizontal: 16, vertical: 8);

  // Normal
  static const Color normalBg = AppColors.pureWhite;
  static const Color normalBorder = AppColors.borderLightGray;

  // Focus (Red)
  static const Color focusBorder = AppColors.accentRed;
  static const Color focusShadow = AppColors.accentRedShadow;

  // Success (Green)
  static const Color successBorder = AppColors.natureGreen;
  static const Color successShadow = AppColors.natureGreenShadow;

  // Disabled
  static const Color disabledBg = AppColors.disabledBg;
  static const Color disabledBorder = AppColors.disabledBorder;
  static const Color disabledText = AppColors.disabledText;

  // Error
  static const Color errorBorder = AppColors.errorRed;
  static const Color errorShadow = AppColors.errorShadow;

  static final TextStyle textStyle =
      AppTypography.bodyLarge.copyWith(color: AppColors.textPrimary);
}
