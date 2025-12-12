import 'package:flutter/material.dart';
import '../tokens/app_tokens.dart';

enum ButtonVariant { primaryRed, secondaryRed, primaryGreen, secondaryGreen }

class ButtonTokens {
  // 공통
  static const double height = 48;
  static const double radius = 30;
  static const EdgeInsets padding = EdgeInsets.symmetric(horizontal: 20);

  // ===== Primary - Accent Red =====
  static const Color primaryRedBg = AppColors.primaryColor;
  static const Color primaryRedText = AppColors.textWhite;

  // ===== Secondary - Accent Red =====
  static const Color secondaryRedBg = AppColors.basicColor;
  static const Color secondaryRedBorder = AppColors.primaryColor;
  static const Color secondaryRedText = AppColors.primaryColor;

  // ===== Primary - Nature Green =====
  static const Color primaryGreenBg = AppColors.secondaryColor;
  static const Color primaryGreenText = AppColors.textWhite;

  // ===== Secondary - Nature Green =====
  static const Color secondaryGreenBg = AppColors.basicColor;
  static const Color secondaryGreenBorder = AppColors.secondaryColor;
  static const Color secondaryGreenText = AppColors.secondaryColor;

  // 텍스트 스타일
  static final TextStyle textStyle =
      AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700);
}
