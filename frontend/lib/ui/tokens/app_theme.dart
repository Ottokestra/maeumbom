import 'package:flutter/material.dart';
import 'app_tokens.dart';

class AppTheme {
  /// -----------------------
  /// 🌕 LIGHT THEME
  /// -----------------------
  static ThemeData light = ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    fontFamily: 'Pretendard',

    // 배경 색상
    scaffoldBackgroundColor: AppColors.bgBasic,

    // 텍스트 스타일
    textTheme: const TextTheme(
      displayLarge: AppTypography.display,
      headlineLarge: AppTypography.h1,
      headlineMedium: AppTypography.h2,
      headlineSmall: AppTypography.h3,
      bodyLarge: AppTypography.bodyLarge,
      bodyMedium: AppTypography.body,
      bodySmall: AppTypography.caption,
    ),

    // 색상 시스템
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.accentRed,
      onPrimary: AppColors.bgBasic,
      secondary: AppColors.accentCoral,
      onSecondary: Colors.white,
      error: AppColors.error,
      onError: AppColors.pureWhite,
      surface: AppColors.bgBasic,
      onSurface: AppColors.textPrimary,
      outline: AppColors.borderLight,
      shadow: Colors.black12,

      // 그 외 기본값
      surfaceTint: Colors.transparent,
    ),

    // 버튼 스타일
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accentRed,
        foregroundColor: AppColors.pureWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        textStyle: AppTypography.bodyLarge,
      ),
    ),

    // 아이콘 기본색
    iconTheme: const IconThemeData(
      color: AppColors.textPrimary,
      size: 24,
    ),

    // AppBar 스타일
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.accentRed,
      foregroundColor: AppColors.pureWhite,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: AppTypography.h2,
    ),

    // SnackBar 스타일 (Global)
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating, // 플로팅 스타일
      backgroundColor: AppColors.darkBlack, // 다크 배경
      contentTextStyle: AppTypography.body, // 텍스트 스타일
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
      ),
    ),
  );

  /// -----------------------
  /// 🌑 DARK THEME
  /// -----------------------
  static ThemeData dark = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    fontFamily: 'Pretendard',
    scaffoldBackgroundColor: AppColors.darkBlack,
  );
}
