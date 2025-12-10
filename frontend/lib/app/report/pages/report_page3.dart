import 'package:flutter/material.dart';
import '../../../ui/app_ui.dart';

/// 페이지 3: 이번주 감정 분석 상세
class ReportPage3 extends StatelessWidget {
  const ReportPage3({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: API에서 데이터 가져오기
    final EmotionRank topEmotion = EmotionRank(
      rank: 1,
      emotion: EmotionId.joy,
      emotionName: '기쁨',
      percentage: 35,
      count: 12,
    );

    final List<EmotionRank> allEmotions = [
      topEmotion,
      EmotionRank(
        rank: 2,
        emotion: EmotionId.love,
        emotionName: '사랑',
        percentage: 25,
        count: 8,
      ),
      EmotionRank(
        rank: 3,
        emotion: EmotionId.relief,
        emotionName: '안정',
        percentage: 20,
        count: 6,
      ),
      EmotionRank(
        rank: 4,
        emotion: EmotionId.excitement,
        emotionName: '의욕',
        percentage: 15,
        count: 5,
      ),
      EmotionRank(
        rank: 5,
        emotion: EmotionId.interest,
        emotionName: '관심',
        percentage: 10,
        count: 3,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chapter 헤더
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Chapter 배지 (가운데 정렬)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accentRed,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Chapter 3',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.pureWhite,
                    fontWeight: FontWeight.w700,
                    fontSize: 9,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // 타이틀 (가운데 정렬)
              Center(
                child: Text(
                  '상세 마음 리포트',
                  style: AppTypography.h3.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // 상위 감정 카드
          _buildTopEmotionCard(topEmotion),

          const SizedBox(height: AppSpacing.xl),

          // 전체 감정 분포
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.bgBasic,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: AppColors.borderLight,
                width: 1,
              ),
            ),
            child: Column(
              children: allEmotions.skip(1).map((emotion) {
                final emotionColor = getEmotionPrimaryColor(emotion.emotion);
                final isFirst = emotion.rank == 2; // 2위가 리스트의 첫 번째
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: emotion.rank == allEmotions.length ? 0 : AppSpacing.sm,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: isFirst
                          ? emotionColor.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Row(
                      children: [
                        // 순위 배지
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: isFirst
                                ? emotionColor
                                : AppColors.borderLight,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${emotion.rank}',
                            style: AppTypography.caption.copyWith(
                              color: isFirst
                                  ? AppColors.pureWhite
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),

                        const SizedBox(width: AppSpacing.sm),

                        // 감정 캐릭터
                        EmotionCharacter(
                          id: emotion.emotion,
                          use2d: true,
                          size: 32,
                        ),

                        const SizedBox(width: AppSpacing.sm),

                        // 감정 이름
                        Text(
                          emotion.emotionName,
                          style: AppTypography.body.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: isFirst ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),

                        const Spacer(),

                        // 퍼센트
                        Text(
                          '${emotion.percentage}%',
                          style: AppTypography.body.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // 감정 분석 설명
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.bgWarm,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: AppColors.accentRed,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '이번 주 감정 분석',
                      style: AppTypography.body.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '이번 주에는 기쁨 감정을 가장 많이 느끼셨네요! 긍정적인 감정이 주를 이루고 있어 마음이 안정적인 상태입니다. 계속해서 이런 긍정적인 마음을 유지하시면 좋겠어요.',
                  style: AppTypography.body.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 상위 감정 카드
  Widget _buildTopEmotionCard(EmotionRank emotion) {
    final Color emotionColor = getEmotionPrimaryColor(emotion.emotion);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 캐릭터 (오른쪽 정렬)
          Align(
            alignment: Alignment.centerRight,
            child: EmotionCharacter(
              id: emotion.emotion,
              size: 120,
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // 감정 정보 박스 (불투명한 감정 색상)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: emotionColor,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '이번 주 가장 많이 느낀 감정',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.pureWhite.withOpacity(0.9),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  emotion.emotionName,
                  style: AppTypography.h1.copyWith(
                    color: AppColors.pureWhite,
                    fontWeight: FontWeight.w700,
                    fontSize: 32,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${emotion.count}회 기록됨',
                      style: AppTypography.body.copyWith(
                        color: AppColors.pureWhite.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${emotion.percentage}%',
                      style: AppTypography.h1.copyWith(
                        color: AppColors.pureWhite,
                        fontWeight: FontWeight.w700,
                        fontSize: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 감정 순위 아이템
  Widget _buildEmotionRankItem(EmotionRank emotion) {
    final Color emotionColor = getEmotionPrimaryColor(emotion.emotion);

    return Row(
      children: [
        // 순위
        SizedBox(
          width: 32,
          child: Text(
            '${emotion.rank}',
            style: AppTypography.h3.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        const SizedBox(width: AppSpacing.sm),

        // 캐릭터
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: emotionColor.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: EmotionCharacter(
              id: emotion.emotion,
              size: 40,
            ),
          ),
        ),

        const SizedBox(width: AppSpacing.md),

        // 감정 정보 및 진행 바
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    emotion.emotionName,
                    style: AppTypography.body.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${emotion.percentage}%',
                    style: AppTypography.h3.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${emotion.count}회 기록됨',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              // 진행 바
              Stack(
                children: [
                  // 배경
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.borderLight,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  // 진행
                  FractionallySizedBox(
                    widthFactor: emotion.percentage / 100,
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: emotionColor,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 감정 순위 데이터 모델
class EmotionRank {
  final int rank;
  final EmotionId emotion;
  final String emotionName;
  final int percentage;
  final int count;

  EmotionRank({
    required this.rank,
    required this.emotion,
    required this.emotionName,
    required this.percentage,
    required this.count,
  });
}
