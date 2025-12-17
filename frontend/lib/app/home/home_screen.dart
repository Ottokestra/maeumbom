import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ui/app_ui.dart';
import '../../providers/daily_mood_provider.dart';
import '../../core/utils/emotion_classifier.dart';
import '../../core/utils/mood_color_helper.dart';
import '../../core/services/navigation/navigation_service.dart';
import 'components/home_header_section.dart';
import 'components/home_card_section.dart';
import 'components/home_main_buttons.dart';
import 'components/home_banner_slider.dart';
import 'daily_mood_check_screen.dart';
import 'components/home_recommendation_cards.dart';

/// Home Screen - 메인 홈 화면
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const statusBarStyle = SystemUiOverlayStyle.light;

    return AppFrame(
      topBar: null,
      useSafeArea: false,
      statusBarStyle: statusBarStyle,
      body: const HomeContent(),
    );
  }
}

class HomeContent extends ConsumerStatefulWidget {
  const HomeContent({super.key});

  @override
  ConsumerState<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends ConsumerState<HomeContent> {
  @override
  void initState() {
    super.initState();
    // 화면 진입 시 기분 체크 상태 확인 후 팝업 표시
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkMoodStatus();
    });
  }

  void _checkMoodStatus() {
    // 현재 화면이 최상위가 아니면 팝업 띄우지 않음
    if (ModalRoute.of(context)?.isCurrent != true) return;

    final dailyState = ref.read(dailyMoodProvider);

    // 아직 기분 체크를 하지 않았다면 팝업 표시
    if (!dailyState.hasChecked) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && ModalRoute.of(context)?.isCurrent == true) {
          _showMoodCheckDialog();
        }
      });
    }
  }

  void _showMoodCheckDialog() {
    MessageDialogHelper.showRedConfirm(
      context,
      icon: Icons.sentiment_satisfied_rounded,
      title: '오늘의 기분은 어때?',
      message: '아직 오늘의 감정 캐릭터를 \n선택하지 않았어.\n지금 가볼까?',
      primaryButtonText: '선택하기',
      secondaryButtonText: '나중에 할게',
      onPrimaryPressed: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const DailyMoodCheckScreen(),
          ),
        );
      },
      onSecondaryPressed: () {
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dailyState = ref.watch(dailyMoodProvider);
    final navigationService = NavigationService(context, ref);

    // 현재 감정 가져오기 (기본값: 기쁨)
    final currentEmotion = dailyState.selectedEmotion ?? EmotionId.joy;

    // 배경색을 위한 기분 카테고리 가져오기
    final moodCategory = EmotionClassifier.classify(currentEmotion);

    // MoodColorHelper를 사용하여 일관된 색상 적용
    final contentColor = MoodColorHelper.getContentColor(moodCategory);
    final emotionColor = MoodColorHelper.getEmotionColor(currentEmotion);

    return Container(
      color: AppColors.primaryColor,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 헤더 영역 (primaryColor 배경)
            Container(
              color: AppColors.primaryColor,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. 헤더 섹션
                  HomeHeaderSection(
                    contentColor: contentColor,
                  ),
                ],
              ),
            ),

            // 컨텐츠 영역 (basicGray 배경, 입체감 효과)
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.basicGray,
                  ),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ).copyWith(top: AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 2. 통합 카드 섹션 (감정 차트 + 기억 알림)
                          const HomeCardSection(),

                          const SizedBox(height: AppSpacing.xs),

                          // 4. 메인 버튼 그리드
                          const HomeMainButtons(),

                          // 5. 오늘의 추천 카드
                          //const HomeRecommendationCards(),

                          SizedBox(
                            height: MediaQuery.of(context).padding.bottom +
                                AppSpacing.sm,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
