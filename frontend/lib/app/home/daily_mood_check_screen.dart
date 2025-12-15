import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../ui/app_ui.dart';
import '../../../core/utils/emotion_classifier.dart';
import '../../../core/utils/mood_color_helper.dart';
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

    // ========== 임시 수정: 고정된 감정 사용 ==========
    // TODO: 나중에 원래 로직으로 복구
    _options = [
      EmotionId.love,      // 좋음
      EmotionId.relief,    // 보통
      EmotionId.sadness,   // 나쁨
    ];
    
    /* ========== 원래 로직 (랜덤 선택) ==========
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
    ========== 원래 로직 끝 ========== */
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Color _getThemeColor(EmotionId emotion) {
    return MoodColorHelper.getBackgroundColorFromEmotion(emotion);
  }

  Color _getBorderColor(EmotionId emotion) {
    return MoodColorHelper.getBorderColorFromEmotion(emotion);
  }

  Future<void> _onConfirm() async {
    final selectedEmotion = _options[_currentPage];
    await ref.read(dailyMoodProvider.notifier).selectEmotion(selectedEmotion);
    if (mounted) {
      Navigator.pop(context);
    }
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
        primaryText: '선택하기',
        onPrimaryTap: _onConfirm,
      ),
      body: Column(
        children: [
          const SizedBox(height: AppSpacing.md),
          // 안내 텍스트
          Text(
            '오늘은 어떤게 좋아?',
            style: AppTypography.h2.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '좌우로 넘겨서 선택해줘!',
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
            final textHeight = 100; // 캐릭터 이름 + 설명 + 여백
            final imageHeight =
                (availableHeight - textHeight).clamp(80.0, double.infinity);

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
                Expanded(
                  child: Center(
                    child: EmotionCharacter(
                      id: emotion,
                      size: imageHeight * 0.7, // 여백 고려
                    ),
                  ),
                ),
                // 짧은 설명 (가독성 개선을 위한 배경 추가)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    meta.shortDesc,
                    style: AppTypography.body.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
