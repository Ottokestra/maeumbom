import 'package:flutter/material.dart';
import '../../../data/models/report/weekly_mood_report.dart';
import '../../../ui/app_ui.dart';
import 'report_page_utils.dart';

/// 페이지 3: 이번주 감정 분석 상세
class ReportPage3 extends StatelessWidget {
  const ReportPage3({super.key, required this.report});

  final WeeklyMoodReport report;

  @override
  Widget build(BuildContext context) {
    final topEmotionId = mapEmotionFromCode(
      report.dominantEmotion.characterCode,
      emotionLabel: report.dominantEmotion.label,
    );
    final topEmotion = report.dominantEmotion;
    final List<WeeklyEmotionRanking> allEmotions = report.emotionRankings;

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
          _buildTopEmotionCard(topEmotion, topEmotionId),

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
                final emotionId = mapEmotionFromCode(
                  emotion.characterCode,
                  emotionLabel: emotion.label,
                );
                final emotionColor = getEmotionPrimaryColor(emotionId);
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
                          id: emotionId,
                          use2d: true,
                          size: 32,
                        ),

                        const SizedBox(width: AppSpacing.sm),

                        // 감정 이름
                        Text(
                          emotion.label,
                          style: AppTypography.body.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: isFirst ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),

                        const Spacer(),

                        // 퍼센트
                        Text(
                          '${emotion.percent.toStringAsFixed(0)}%',
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
                  report.analysisText.isNotEmpty
                      ? report.analysisText
                      : '이번 주에는 ${report.dominantEmotion.label} 감정을 가장 많이 느끼셨네요! 긍정적인 감정이 주를 이루고 있어 마음이 안정적인 상태입니다. 계속해서 이런 긍정적인 마음을 유지하시면 좋겠어요.',
                  style: AppTypography.body.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          _HighlightConversationsList(
            conversations: report.highlightConversations,
          ),
        ],
      ),
    );
  }

  /// 상위 감정 카드
  Widget _buildTopEmotionCard(
    WeeklyEmotionRanking emotion,
    EmotionId emotionId,
  ) {
    final Color emotionColor = getEmotionPrimaryColor(emotionId);

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
              id: emotionId,
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
                  emotion.label,
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
                      '${emotion.percent.toStringAsFixed(0)}%',
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
}

class _HighlightConversationsList extends StatelessWidget {
  const _HighlightConversationsList({required this.conversations});

  final List<HighlightConversation> conversations;

  @override
  Widget build(BuildContext context) {
    if (conversations.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.bgBasic,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Text(
          '이번 주 하이라이트 대화가 아직 없어요.',
          style: AppTypography.body.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '주간 하이라이트 대화',
          style: AppTypography.h4.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '이번 주 감정에 영향을 준 대화를 모았어요.',
          style: AppTypography.body.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ...conversations.map(
          (conversation) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _HighlightConversationTile(conversation: conversation),
          ),
        ),
      ],
    );
  }
}

class _HighlightConversationTile extends StatelessWidget {
  const _HighlightConversationTile({required this.conversation});

  final HighlightConversation conversation;

  @override
  Widget build(BuildContext context) {
    final emotionId = mapEmotionFromCode(
      conversation.primaryEmotionCode,
      emotionLabel: conversation.primaryEmotionLabel,
    );
    final sentimentLabel = _mapSentiment(conversation.sentimentOverall);
    final emotionColor = getEmotionPrimaryColor(emotionId);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.bgBasic,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EmotionCharacter(
            id: emotionId,
            use2d: true,
            size: 48,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: emotionColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        conversation.primaryEmotionLabel,
                        style: AppTypography.caption.copyWith(
                          color: emotionColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _SentimentTag(sentimentLabel: sentimentLabel),
                    if (conversation.riskLevel != null) ...[
                      const SizedBox(width: AppSpacing.xs),
                      _RiskBadge(level: conversation.riskLevel!),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  conversation.text,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: conversation.reportTags
                      .map((tag) => _TagChip(label: tag))
                      .toList(),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  formatDateTimeLabel(conversation.createdAt),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
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

class _SentimentTag extends StatelessWidget {
  const _SentimentTag({required this.sentimentLabel});

  final String sentimentLabel;

  @override
  Widget build(BuildContext context) {
    Color background = AppColors.bgWarm;
    Color textColor = AppColors.textSecondary;

    switch (sentimentLabel) {
      case '긍정':
        background = AppColors.natureGreen.withOpacity(0.12);
        textColor = AppColors.natureGreen;
        break;
      case '부정':
        background = AppColors.accentRed.withOpacity(0.12);
        textColor = AppColors.accentRed;
        break;
      default:
        background = AppColors.bgBasic;
        textColor = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        sentimentLabel,
        style: AppTypography.caption.copyWith(
          color: textColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _RiskBadge extends StatelessWidget {
  const _RiskBadge({required this.level});

  final String level;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.accentRed.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        level.toUpperCase(),
        style: AppTypography.caption.copyWith(
          color: AppColors.accentRed,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.borderLight.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

String _mapSentiment(String overall) {
  switch (overall.toLowerCase()) {
    case 'positive':
      return '긍정';
    case 'negative':
      return '부정';
    default:
      return '중립';
  }
}
