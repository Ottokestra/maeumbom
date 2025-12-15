import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ui/app_ui.dart';
import '../../providers/daily_mood_provider.dart';
import '../../core/services/navigation/navigation_service.dart';
import 'relation_training_list_screen.dart';

/// 마음연습실 시작 화면
///
/// PROMPT_GUIDE 준수:
/// - AppFrame 기반 구조
/// - 감정 캐릭터를 시각적 중심으로 배치
/// - 대화체 텍스트 사용
/// - 여백이 충분한 레이아웃
class TrainingScreen extends ConsumerWidget {
  const TrainingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyState = ref.watch(dailyMoodProvider);
    final currentEmotion = dailyState.selectedEmotion ?? EmotionId.joy;
    final navigationService = NavigationService(context, ref);

    return AppFrame(
      backgroundColor: AppColors.bgBasic,
      topBar: TopBar(
        title: '마음연습실',
        leftIcon: Icons.arrow_back,
        onTapLeft: () => navigationService.navigateToTab(0),
      ),
      bottomBar: BottomButtonBar(
        primaryText: '시작하기',
        onPrimaryTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RelationTrainingListScreen(),
            ),
          ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              // 메인 화이트 카드 (캐릭터 + 안내 텍스트)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.xl,
                  horizontal: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: AppColors.pureWhite,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Column(
                  children: [
                    // 안내 텍스트 (대화체)
                    const Text(
                      '오늘도 함께 연습해볼까요?',
                      style: AppTypography.h3,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: AppTypography.body.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        children: [
                          const TextSpan(text: '아래 '),
                          TextSpan(
                            text: '시작하기',
                            style: AppTypography.bodyBold.copyWith(
                              color: AppColors.errorRed,
                            ),
                          ),
                          const TextSpan(text: ' 버튼을 눌러 주세요!'),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // 캐릭터 (시각적 중심)
                    EmotionCharacter(
                      id: currentEmotion,
                      use2d: false,
                      size: 180,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // 설명 카드
              _buildInfoCard(
                title: '관계 연습하기',
                description: '어려운 상황에서\n어떻게 대화할지 연습해봐요',
                gradientColors: [
                  const Color(0xFFFFF9E6),
                  const Color(0xFFFFF3D6),
                ],
                iconColor: const Color(0xFFFFB84C),
                textColor: const Color(0xFFE69500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 정보 카드 빌더
  Widget _buildInfoCard({
    required String title,
    required String description,
    required List<Color> gradientColors,
    required Color iconColor,
    required Color textColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: const Alignment(0.50, 0.00),
          end: const Alignment(0.50, 1.00),
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // 아이콘
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.self_improvement,
              size: 28,
              color: AppColors.pureWhite,
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // 텍스트
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.h3.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  description,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
