import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
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
    return AppFrame(
      topBar: TopBar(
        title: '퀴즈 결과',
        leftIcon: Icons.close,
        onTapLeft: () {
          Navigator.popUntil(context, (route) => route.isFirst);
        },
      ),
      bottomBar: BottomButtonBar(
        primaryText: '돌아가기',
        onPrimaryTap: () {
          Navigator.pushReplacementNamed(
            context,
            '/training/slang-quiz/start',
          );
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.xs),
            
            // 결과 캐릭터 (Lottie)
            Lottie.asset(
              result.correctCount >= 3
                  ? 'assets/images/button/game_clear.json'
                  : 'assets/images/button/game_over.json',
              width: 140,
              height: 140,
              fit: BoxFit.contain,
            ),

            // 정답 개수
            Text(
              '${result.totalQuestions}문제 중 ${result.correctCount}문제 성공',
              style: AppTypography.h3,
            ),
            const SizedBox(height: AppSpacing.xs),
            
            // 정확도
            Text(
              '정확도: ${((result.correctCount / result.totalQuestions) * 100).toStringAsFixed(0)}%',
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            
            // 랭킹 정보 (있는 경우에만 표시)
            if (result.ranking != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.bgSoftMint,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      result.ranking!.rankMessage
                          .replaceAll('단어→뜻', '')
                          .replaceAll('뜻→단어', ''),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${result.ranking!.totalGames}명 중 ${result.ranking!.betterThan + 1}위',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            
            // 문제별 요약
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
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
                      child: ListView.builder(
                        itemCount: result.questionsSummary.length,
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
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionSummaryItem(QuestionSummary summary) {
    final isCorrect = summary.isCorrect ?? false;
    final score = summary.earnedScore ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 문제 번호
          Container(
            width: AppSpacing.lg,
            height: AppSpacing.lg,
            decoration: BoxDecoration(
              color: isCorrect
                  ? AppColors.secondaryColor.withValues(alpha: 0.2)
                  : AppColors.errorRed.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '${summary.questionNumber}',
              style: AppTypography.caption.copyWith(
                color:
                    isCorrect ? AppColors.secondaryColor : AppColors.errorRed,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          
          // 문제 단어
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
            size: AppSpacing.md,
          ),
          const SizedBox(width: AppSpacing.xs),
          
          // 획득 점수
          Text(
            '+$score점',
            style: AppTypography.caption.copyWith(
              color: isCorrect ? AppColors.secondaryColor : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
