import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ui/app_ui.dart';
import '../../data/dtos/slang_quiz/end_game_response.dart';

class SlangQuizResultScreen extends ConsumerWidget {
  final EndGameResponse result;

  const SlangQuizResultScreen({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultEmotion = _getResultEmotion(result.correctCount);

    return AppFrame(
      topBar: TopBar(
        title: '퀴즈 결과',
        leftIcon: Icons.close,
        onTapLeft: () {
          Navigator.popUntil(context, (route) => route.isFirst);
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.xl),
            
            // 결과 캐릭터
            EmotionCharacter(
              id: resultEmotion,
              use2d: true,
              size: 200,
            ),
            const SizedBox(height: AppSpacing.xl),
            
            // 총점
            Text(
              '${result.totalScore}점',
              style: AppTypography.display.copyWith(
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            
            // 정답 개수
            Text(
              '${result.totalQuestions}문제 중 ${result.correctCount}문제 정답!',
              style: AppTypography.h2,
            ),
            const SizedBox(height: AppSpacing.xs),
            
            // 정확도
            Text(
              '정확도: ${((result.correctCount / result.totalQuestions) * 100).toStringAsFixed(0)}%',
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            
            // 문제별 요약
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.bgWarm,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '문제별 결과',
                      style: AppTypography.bodyBold,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Expanded(
                      child: ListView.separated(
                        itemCount: result.questionsSummary.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final summary = result.questionsSummary[index];
                          return _buildQuestionSummaryItem(summary);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            
            // 버튼들
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: '나가기',
                    variant: ButtonVariant.secondaryRed,
                    onTap: () {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppButton(
                    text: '다시 하기',
                    variant: ButtonVariant.primaryRed,
                    onTap: () {
                      Navigator.pushReplacementNamed(
                        context,
                        '/training/slang-quiz/start',
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionSummaryItem(QuestionSummary summary) {
    final isCorrect = summary.isCorrect ?? false;
    final score = summary.earnedScore ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          // 문제 번호
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isCorrect
                  ? AppColors.secondaryColor.withOpacity(0.2)
                  : AppColors.errorRed.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${summary.questionNumber}',
                style: AppTypography.bodyBold.copyWith(
                  color: isCorrect ? AppColors.secondaryColor : AppColors.errorRed,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          
          // 단어
          Expanded(
            child: Text(
              summary.word,
              style: AppTypography.body,
            ),
          ),
          
          // 결과 아이콘
          Icon(
            isCorrect ? Icons.check_circle : Icons.cancel,
            color: isCorrect ? AppColors.secondaryColor : AppColors.errorRed,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.xs),
          
          // 점수
          Text(
            '$score점',
            style: AppTypography.bodyBold.copyWith(
              color: isCorrect ? AppColors.secondaryColor : AppColors.errorRed,
            ),
          ),
        ],
      ),
    );
  }

  EmotionId _getResultEmotion(int correctCount) {
    if (correctCount >= 4) return EmotionId.joy;
    if (correctCount >= 3) return EmotionId.relief;
    if (correctCount >= 2) return EmotionId.interest;
    return EmotionId.sadness;
  }
}

