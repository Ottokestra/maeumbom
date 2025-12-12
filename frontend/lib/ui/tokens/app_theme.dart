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
      primary: AppColors.primaryColor,
      secondary: AppColors.secondaryColor,
      error: AppColors.error,
      surface: AppColors.bgBasic,
      outline: AppColors.borderLight,
      shadow: Colors.black12,
      onPrimary: AppColors.bgBasic,
      onSecondary: AppColors.bgWarm,
      onError: AppColors.basicColor,
      onSurface: AppColors.textPrimary,

      // 그 외 기본값
      surfaceTint: Colors.transparent,
    ),

    // 버튼 스타일
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: AppColors.basicColor,
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
      backgroundColor: AppColors.primaryColor,
      foregroundColor: AppColors.basicColor,
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

    scaffoldBackgroundColor: AppColors.surfaceDark,

    textTheme: TextTheme(
      displayLarge: AppTypography.display.copyWith(
        color: AppColors.textPrimaryDark,
      ),
      headlineLarge: AppTypography.h1.copyWith(
        color: AppColors.textPrimaryDark,
      ),
      headlineMedium: AppTypography.h2.copyWith(
        color: AppColors.textPrimaryDark,
      ),
      headlineSmall: AppTypography.h3.copyWith(
        color: AppColors.textPrimaryDark,
      ),
      bodyLarge: AppTypography.bodyLarge.copyWith(
        color: AppColors.textPrimaryDark,
      ),
      bodyMedium: AppTypography.body.copyWith(
        color: AppColors.textPrimaryDark,
      ),
      bodySmall: AppTypography.caption.copyWith(
        color: AppColors.textSecondaryDark,
      ),
    ),

    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.accentRed,
      secondary: AppColors.natureGreen,
      error: AppColors.error,
      surface: AppColors.cardDark,          
      onPrimary: AppColors.basicColor,
      onSecondary: AppColors.basicColor,
      onError: AppColors.basicColor,
      onSurface: AppColors.textPrimaryDark,
      outline: AppColors.borderDark,        
      shadow: Colors.black,
      surfaceTint: Colors.transparent,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accentRed,
        foregroundColor: AppColors.basicColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        textStyle: AppTypography.bodyLarge.copyWith(
          color: AppColors.basicColor,
        ),
      ),
    ),

    iconTheme: const IconThemeData(
      color: AppColors.textPrimaryDark,
      size: 24,
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.cardDark,
      foregroundColor: AppColors.basicColor,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: AppTypography.h2.copyWith(
        color: AppColors.basicColor,
      ),
    ),

    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Color(0xFF000000),
      contentTextStyle: TextStyle(
        color: AppColors.basicColor,
        fontSize: 15,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
      ),
    ),
  );
}
