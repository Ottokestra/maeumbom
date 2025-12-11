import 'package:flutter/material.dart';
import 'colors.dart';

/// Toggle 토큰
///
/// 앱 전체에서 사용되는 토글(Switch) 스타일을 정의합니다.
class ToggleTokens {
  ToggleTokens._(); // Private constructor to prevent instantiation

  // ============================================================================
  // Primary Toggle (Red) - 주요 토글
  // ============================================================================

  /// Primary 토글 - 활성화 시 빨간색
  static const Color primaryActiveThumb = AppColors.pureWhite; // 활성화 토글 원 (흰색)
  static const Color primaryActiveTrack = AppColors.accentRed; // 활성화 배경 (빨간색)
  static const Color primaryInactiveThumb =
      AppColors.pureWhite; // 비활성 토글 원 (흰색)
  static const Color primaryInactiveTrack =
      AppColors.borderLightGray; // 비활성 배경 (회색)

  // ============================================================================
  // Secondary Toggle (Green) - 보조 토글
  // ============================================================================

  /// Secondary 토글 - 활성화 시 초록색
  static const Color secondaryActiveThumb =
      AppColors.pureWhite; // 활성화 토글 원 (흰색)
  static const Color secondaryActiveTrack =
      AppColors.natureGreen; // 활성화 배경 (초록색)
  static const Color secondaryInactiveThumb =
      AppColors.pureWhite; // 비활성 토글 원 (흰색)
  static const Color secondaryInactiveTrack =
      AppColors.borderLightGray; // 비활성 배경 (회색)

  // ============================================================================
  // Toggle Scale
  // ============================================================================

  /// 토글 크기 조정 (기본 Switch 크기 대비)
  static const double defaultScale = 0.75;
  static const double largeScale = 0.85;
  static const double smallScale = 0.65;
}

/// Toggle 타입
enum ToggleType {
  primary, // 빨간색 (기본)
  secondary, // 초록색
}

/// Toggle 크기
enum ToggleSize {
  small, // 0.65
  normal, // 0.75
  large, // 0.85
}

/// Toggle 스타일 헬퍼 클래스
class ToggleStyle {
  final Color activeThumb;
  final Color activeTrack;
  final Color inactiveThumb;
  final Color inactiveTrack;
  final double scale;

  const ToggleStyle({
    required this.activeThumb,
    required this.activeTrack,
    required this.inactiveThumb,
    required this.inactiveTrack,
    required this.scale,
  });

  /// Primary 토글 스타일 (빨간색)
  factory ToggleStyle.primary({ToggleSize size = ToggleSize.normal}) {
    return ToggleStyle(
      activeThumb: ToggleTokens.primaryActiveThumb,
      activeTrack: ToggleTokens.primaryActiveTrack,
      inactiveThumb: ToggleTokens.primaryInactiveThumb,
      inactiveTrack: ToggleTokens.primaryInactiveTrack,
      scale: _getScale(size),
    );
  }

  /// Secondary 토글 스타일 (초록색)
  factory ToggleStyle.secondary({ToggleSize size = ToggleSize.normal}) {
    return ToggleStyle(
      activeThumb: ToggleTokens.secondaryActiveThumb,
      activeTrack: ToggleTokens.secondaryActiveTrack,
      inactiveThumb: ToggleTokens.secondaryInactiveThumb,
      inactiveTrack: ToggleTokens.secondaryInactiveTrack,
      scale: _getScale(size),
    );
  }

  static double _getScale(ToggleSize size) {
    switch (size) {
      case ToggleSize.small:
        return ToggleTokens.smallScale;
      case ToggleSize.normal:
        return ToggleTokens.defaultScale;
      case ToggleSize.large:
        return ToggleTokens.largeScale;
    }
  }
}
