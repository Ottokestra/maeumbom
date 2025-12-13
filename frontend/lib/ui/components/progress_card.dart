import 'package:flutter/material.dart';
import '../tokens/app_tokens.dart';

/// Progress Card Theme - 진행도 카드 테마
enum ProgressCardTheme {
  /// 핑크 테마 (primaryColor 기반)
  pink,
  
  /// 퍼플 테마 (마이페이지 친밀도 원본 스타일)
  purple,
}

/// Progress Card - 공통 진행도 카드
///
/// 진행도를 표시하는 재사용 가능한 카드 컴포넌트
/// 마이페이지 친밀도, 트레이닝 기록 등에 사용됩니다.
///
/// 사용 예시:
/// ```dart
/// // 기본 사용 (핑크 테마)
/// ProgressCard(
///   topLabel: '친밀도 UP까지',
///   currentValue: 60,
///   totalValue: 100,
///   bottomMessage: '8번 더 대화하면 친밀도 UP! ✨',
/// )
///
/// // 퍼플 테마 사용
/// ProgressCard(
///   topLabel: '친밀도 UP까지',
///   currentValue: 60,
///   totalValue: 100,
///   bottomMessage: '8번 더 대화하면 친밀도 UP! ✨',
///   theme: ProgressCardTheme.purple,
/// )
///
/// // 캐릭터와 함께 사용
/// ProgressCard(
///   topLabel: '내 연습 기록',
///   currentValue: 2,
///   totalValue: 4,
///   leadingWidget: EmotionCharacter(...),
/// )
/// ```
class ProgressCard extends StatelessWidget {
  /// 상단 라벨 (예: "친밀도 UP까지", "내 연습 기록")
  final String topLabel;

  /// 현재 값 (완료 개수 or 진행도)
  final int currentValue;

  /// 전체 값
  final int totalValue;

  /// 하단 메시지 (null이면 기본 메시지: "n개 완료 / 전체 m개")
  final String? bottomMessage;

  /// 선택적 왼쪽 위젯 (캐릭터 등)
  final Widget? leadingWidget;

  /// 카드 패딩
  final EdgeInsets? padding;

  /// 테마 (pink 또는 purple)
  final ProgressCardTheme theme;

  const ProgressCard({
    super.key,
    required this.topLabel,
    required this.currentValue,
    required this.totalValue,
    this.bottomMessage,
    this.leadingWidget,
    this.padding,
    this.theme = ProgressCardTheme.pink,
  });

  @override
  Widget build(BuildContext context) {
    // 퍼센트 계산
    final percentage = totalValue > 0
        ? ((currentValue / totalValue) * 100).round()
        : 0;

    // 기본 메시지
    final message = bottomMessage ?? '$currentValue개 완료 / 전체 $totalValue개';

    // 테마별 색상
    final colors = _getThemeColors();

    return Container(
      padding: padding ?? const EdgeInsets.all(17),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: colors.backgroundGradient,
        ),
        border: Border.all(
          color: colors.border,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: leadingWidget != null
          ? _buildWithLeadingWidget(percentage, message, colors)
          : _buildDefault(percentage, message, colors),
    );
  }

  /// 테마별 색상 가져오기
  _ThemeColors _getThemeColors() {
    switch (theme) {
      case ProgressCardTheme.pink:
        return _ThemeColors(
          backgroundGradient: const [
            Color(0xFFFDE8EB), // 연한 빨강-핑크
            Color(0xFFFCF1F7), // 연한 핑크
          ],
          border: const Color(0xFFFFD6DC), // 핑크 보더
          labelText: const Color(0xFFD84560), // primaryColor 계열
          progressGradient: const [
            AppColors.primaryColor, // #D8454D
            Color(0xFFFB63B6), // 밝은 핑크
          ],
          messageText: const Color(0xFFD8454D), // primaryColor
        );
      
      case ProgressCardTheme.purple:
        return _ThemeColors(
          backgroundGradient: const [
            Color(0xFFFAF5FE), // 연한 퍼플
            Color(0xFFFCF1F7), // 연한 핑크
          ],
          border: const Color(0xFFF2E7FE), // 퍼플 보더
          labelText: const Color(0xFF8200DA), // 진한 퍼플
          progressGradient: const [
            Color(0xFFC17AFF), // 밝은 퍼플
            Color(0xFFFB63B6), // 밝은 핑크
          ],
          messageText: const Color(0xFF980FFA), // 중간 퍼플
        );
    }
  }

  /// 캐릭터가 있는 레이아웃
  Widget _buildWithLeadingWidget(
      int percentage, String message, _ThemeColors colors) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 왼쪽: 캐릭터
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.all(4),
          child: leadingWidget,
        ),
        const SizedBox(width: 12),
        // 오른쪽: 진행도 정보
        Expanded(
          child: _buildProgressInfo(percentage, message, colors),
        ),
      ],
    );
  }

  /// 기본 레이아웃 (캐릭터 없이)
  Widget _buildDefault(int percentage, String message, _ThemeColors colors) {
    return _buildProgressInfo(percentage, message, colors);
  }

  /// 진행도 정보 (상단 라벨 + 진행 바 + 하단 메시지)
  Widget _buildProgressInfo(
      int percentage, String message, _ThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 상단: 라벨 + 퍼센트
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              topLabel,
              style: AppTypography.body.copyWith(
                color: colors.labelText,
                fontSize: 14,
              ),
            ),
            Text(
              '$percentage%',
              style: AppTypography.bodyBold.copyWith(
                color: colors.labelText,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // 중간: 진행 바
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: Container(
            height: 8,
            color: AppColors.basicColor,
            child: FractionallySizedBox(
              widthFactor: percentage / 100,
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: colors.progressGradient,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // 하단: 메시지
        Text(
          message,
          style: AppTypography.caption.copyWith(
            color: colors.messageText,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

/// 테마 색상 데이터 클래스
class _ThemeColors {
  final List<Color> backgroundGradient;
  final Color border;
  final Color labelText;
  final List<Color> progressGradient;
  final Color messageText;

  const _ThemeColors({
    required this.backgroundGradient,
    required this.border,
    required this.labelText,
    required this.progressGradient,
    required this.messageText,
  });
}

