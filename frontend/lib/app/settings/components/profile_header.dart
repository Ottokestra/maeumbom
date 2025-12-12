import 'package:flutter/material.dart';
import '../../../ui/app_ui.dart';
import 'level_progress_card.dart';

/// Profile Header - 프로필 헤더
///
/// 사용자 아바타, 닉네임, 활동 일수, 레벨 진행도를 표시
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.nickname,
    required this.daysWithService,
    required this.levelPercentage,
    required this.conversationsRemaining,
    required this.emotionCharacter,
  });

  /// 사용자 닉네임
  final String nickname;

  /// 서비스 이용 일수
  final int daysWithService;

  /// 레벨 진행률 (0-100)
  final int levelPercentage;

  /// 레벨업까지 남은 대화 수
  final int conversationsRemaining;

  /// 감정 캐릭터 위젯
  final Widget emotionCharacter;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.basicColor,
      padding: const EdgeInsets.only(
        top: AppSpacing.md,
        left: AppSpacing.md,
        right: AppSpacing.md,
        bottom: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 아바타 + 닉네임 + 활동일수
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 아바타 (80x80 원형)
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: Container(
                  width: 80,
                  height: 80,
                  color: AppColors.bgWarm,
                  child: emotionCharacter,
                ),
              ),
              const SizedBox(width: 16),
              // 닉네임 + 활동일수
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nickname,
                      style: AppTypography.h2.copyWith(
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '마음봄과 함께한 지 $daysWithService일',
                      style: AppTypography.body.copyWith(
                        color: const Color(0xFF697282),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // 레벨 진행도 카드
          LevelProgressCard(
            percentage: levelPercentage,
            conversationsRemaining: conversationsRemaining,
          ),
        ],
      ),
    );
  }
}
