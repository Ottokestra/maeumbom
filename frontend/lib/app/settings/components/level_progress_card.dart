import 'package:flutter/material.dart';
import '../../../ui/app_ui.dart';

/// Level Progress Card - 친밀도 진행도 카드
///
/// 사용자의 친밀도 진행도를 표시하는 카드
class LevelProgressCard extends StatelessWidget {
  const LevelProgressCard({
    super.key,
    required this.percentage,
    required this.conversationsRemaining,
  });

  /// 진행률 (0-100)
  final int percentage;

  /// 친밀도 UP까지 남은 대화 수
  final int conversationsRemaining;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFFFAF5FE), Color(0xFFFCF1F7)],
        ),
        border: Border.all(
          color: const Color(0xFFF2E7FE),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단: 친밀도 UP까지 라벨 + 퍼센트
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '친밀도 UP까지',
                style: AppTypography.body.copyWith(
                  color: const Color(0xFF8200DA),
                  fontSize: 14,
                ),
              ),
              Text(
                '$percentage%',
                style: AppTypography.bodyBold.copyWith(
                  color: const Color(0xFF8200DA),
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
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Color(0xFFC17AFF), Color(0xFFFB63B6)],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // 하단: 메시지
          Text(
            '$conversationsRemaining번 더 대화하면 친밀도 UP! ✨',
            style: AppTypography.caption.copyWith(
              color: const Color(0xFF980FFA),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
