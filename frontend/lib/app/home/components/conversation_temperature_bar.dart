import 'package:flutter/material.dart';
import '../../../ui/app_ui.dart';
import '../../../core/utils/emotion_classifier.dart';

/// 봄이와의 대화 온도를 시각화하는 막대 컴포넌트
///
/// 3단계 (나쁨/보통/좋음)로 대화 품질을 표시합니다.
class ConversationTemperatureBar extends StatelessWidget {
  final MoodCategory currentMood;

  const ConversationTemperatureBar({
    super.key,
    this.currentMood = MoodCategory.good, // 기본값: 좋음
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 제목
        Text(
          '봄이와의 대화 온도',
          style: AppTypography.bodyBold.copyWith(
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: AppSpacing.sm),

        // 3개 가로 막대
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: _buildBar(
                  isActive: currentMood == MoodCategory.bad,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: _buildBar(
                  isActive: currentMood == MoodCategory.neutral,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: _buildBar(
                  isActive: currentMood == MoodCategory.good,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.xs),

        // 라벨
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '나쁨',
                  style: AppTypography.caption.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: Text(
                  '보통',
                  style: AppTypography.caption.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: Text(
                  '좋음',
                  style: AppTypography.caption.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 온도 막대 빌더
  Widget _buildBar({required bool isActive}) {
    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: isActive ? 0.9 : 0.3),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
    );
  }
}
