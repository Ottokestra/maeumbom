import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../ui/app_ui.dart';
import '../../../core/utils/emotion_classifier.dart';
import '../../../providers/daily_mood_provider.dart';

/// 일일 감정 체크 풀스크린
class DailyMoodCheckScreen extends ConsumerStatefulWidget {
  const DailyMoodCheckScreen({super.key});

  @override
  ConsumerState<DailyMoodCheckScreen> createState() =>
      _DailyMoodCheckScreenState();
}

class _DailyMoodCheckScreenState extends ConsumerState<DailyMoodCheckScreen> {
  late final PageController _pageController;
  late final List<EmotionId> _options;
  int _currentPage = 1; // 중앙에서 시작

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: 1,
      viewportFraction: 0.85, // 양옆 카드가 살짝 보이도록
    );

    // 각 카테고리에서 랜덤 선택
    final random = Random();
    EmotionId pickRandom(MoodCategory category) {
      final list = EmotionClassifier.getEmotionsByCategory(category);
      return list[random.nextInt(list.length)];
    }

    _options = [
      pickRandom(MoodCategory.good),
      pickRandom(MoodCategory.neutral),
      pickRandom(MoodCategory.bad),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Color _getThemeColor(EmotionId emotion) {
    final category = EmotionClassifier.classify(emotion);
    switch (category) {
      case MoodCategory.good:
        return AppColors.moodGoodYellow;
      case MoodCategory.neutral:
        return AppColors.moodNeutralPink;
      case MoodCategory.bad:
        return AppColors.moodBadBlue;
    }
  }

  Color _getBorderColor(EmotionId emotion) {
    final category = EmotionClassifier.classify(emotion);
    switch (category) {
      case MoodCategory.good:
        return const Color(0xFFFDD835); // 진한 노란색
      case MoodCategory.neutral:
        return const Color(0xFFF06292); // 진한 분홍색
      case MoodCategory.bad:
        return const Color(0xFF42A5F5); // 진한 파란색
    }
  }

  void _onConfirm() {
    final selectedEmotion = _options[_currentPage];
    ref.read(dailyMoodProvider.notifier).selectEmotion(selectedEmotion);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AppFrame(
      topBar: TopBar(
        title: '',
        rightIcon: Icons.close,
        onTapRight: () => Navigator.pop(context),
      ),
      bottomBar: BottomButtonBar(
        primaryText: '이 감정으로 선택',
        onPrimaryTap: _onConfirm,
      ),
      body: Column(
        children: [
          const SizedBox(height: AppSpacing.md),
          // 안내 텍스트
          Text(
            '지금 기분이 어떠신가요?',
            style: AppTypography.h2.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '좌우로 넘겨서 선택해주세요',
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // 카드 영역 - 더 많은 공간 할당
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: _options.length,
              itemBuilder: (context, index) {
                final emotion = _options[index];
                final isSelected = index == _currentPage;

                return _EmotionCard(
                  emotion: emotion,
                  isSelected: isSelected,
                  themeColor: _getThemeColor(emotion),
                  borderColor: _getBorderColor(emotion),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // 페이지 인디케이터
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _options.length,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: index == _currentPage ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: index == _currentPage
                      ? _getBorderColor(_options[index])
                      : AppColors.borderLight,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

/// 개별 감정 카드 위젯
class _EmotionCard extends StatelessWidget {
  final EmotionId emotion;
  final bool isSelected;
  final Color themeColor;
  final Color borderColor;

  const _EmotionCard({
    required this.emotion,
    required this.isSelected,
    required this.themeColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final meta = emotionMetaMap[emotion]!;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: isSelected ? 1.0 : 0.5,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: themeColor,
          border: Border.all(
            color: isSelected ? borderColor : Colors.transparent,
            width: 3,
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: borderColor.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // 사용 가능한 공간 계산
            final availableHeight = constraints.maxHeight;
            final textHeight = 80; // 캐릭터 이름 + 설명 + 여백
            final imageHeight = availableHeight - textHeight;

            return Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 캐릭터 이름 (한글)
                Text(
                  meta.characterKo,
                  style: AppTypography.h3.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                // 캐릭터 이미지 (최대한 크게)
                SizedBox(
                  height: imageHeight,
                  child: Center(
                    child: EmotionCharacter(
                      id: emotion,
                      size: imageHeight * 0.9, // 여백 고려
                    ),
                  ),
                ),
                // 짧은 설명
                Text(
                  meta.shortDesc,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
