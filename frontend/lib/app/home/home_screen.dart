import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ui/app_ui.dart';
import '../../providers/daily_mood_provider.dart';
import '../../core/utils/emotion_classifier.dart';
import '../../core/services/navigation/navigation_service.dart';
import 'components/home_header_section.dart';
import 'components/conversation_temperature_bar.dart';
import 'daily_mood_check_screen.dart';

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
      bottomBar: const HomeBottomBar(),
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
      icon: Icons.favorite_rounded,
      title: '오늘의 기분은 어떠신가요?',
      message: '아직 오늘의 감정 캐릭터를 선택하지 않으셨어요.\n지금 기록하러 가볼까요?',
      primaryButtonText: '기록하기',
      secondaryButtonText: '나중에',
      onPrimaryPressed: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const DailyMoodCheckScreen(),
          ),
        );
      },
      onSecondaryPressed: () => Navigator.pop(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dailyState = ref.watch(dailyMoodProvider);

    // 현재 감정 가져오기 (기본값: 기쁨)
    final currentEmotion = dailyState.selectedEmotion ?? EmotionId.joy;

    // 배경색을 위한 기분 카테고리 가져오기
    final moodCategory = EmotionClassifier.classify(currentEmotion);

    // 배경색 결정
    final backgroundColor = _getBackgroundColor(moodCategory);

    return Container(
      color: backgroundColor,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 상단 콘텐츠 영역 (스크롤 가능)
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. 헤더 영역
                      const HomeHeaderSection(),

                      const SizedBox(height: AppSpacing.xxl),

                      // 2. 캐릭터 (240x240, 중앙)
                      Center(
                        child: EmotionCharacter(
                          id: currentEmotion,
                          size: 240,
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // 3. 대화 온도 막대
                      ConversationTemperatureBar(
                        currentMood: moodCategory,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 기분 카테고리에 따른 배경색 반환
  Color _getBackgroundColor(MoodCategory category) {
    switch (category) {
      case MoodCategory.good:
        return AppColors.moodGoodColor;
      case MoodCategory.neutral:
        return AppColors.moodNormalColor;
      case MoodCategory.bad:
        return AppColors.moodNormalColor; // 디자인 가이드/사용자 요청에 따라 변경
    }
  }
}

/// 홈 화면 하단 네비게이션 바
class HomeBottomBar extends ConsumerWidget {
  const HomeBottomBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationService = NavigationService(context, ref);

    return BottomMenuBar(
      currentIndex: 0,
      onTap: (index) {
        navigationService.navigateToTab(index);
      },
    );
  }
}
