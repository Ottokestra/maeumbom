import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ui/app_ui.dart';
import '../../providers/daily_mood_provider.dart';
import '../../core/utils/emotion_classifier.dart';
import '../../core/utils/mood_color_helper.dart';
import '../../core/services/navigation/navigation_service.dart';
import 'components/home_header_section.dart';
import 'components/home_gauge_section.dart';
import 'components/home_main_buttons.dart';
import 'components/home_banner_slider.dart';
import 'daily_mood_check_screen.dart';

/// Home Screen - 메인 홈 화면
class HomeNewScreen extends ConsumerWidget {
  const HomeNewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const statusBarStyle = SystemUiOverlayStyle.light;

    return AppFrame(
      topBar: null,
      useSafeArea: false,
      statusBarStyle: statusBarStyle,
      body: const HomeNewContent(),
    );
  }
}

class HomeNewContent extends ConsumerStatefulWidget {
  const HomeNewContent({super.key});

  @override
  ConsumerState<HomeNewContent> createState() => _HomeContentState();
}

class _HomeContentState extends ConsumerState<HomeNewContent> {
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
      title: '오늘의 기분은 어떠신가요?',
      message: '아직 오늘의 감정 캐릭터를 \n선택하지 않으셨어요.\n지금 기록하러 가볼까요?',
      primaryButtonText: '기록하기',
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
    final backgroundColor = MoodColorHelper.getBackgroundColor(moodCategory);
    final contentColor = MoodColorHelper.getContentColor(moodCategory);
    final emotionColor = MoodColorHelper.getEmotionColor(currentEmotion);

    return Container(
      color: backgroundColor,
      child: SafeArea(
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
                HomeHeaderSection(
                  contentColor: contentColor,
                ),

                const SizedBox(height: AppSpacing.md),

                // 2. 반원 게이지 영역
                HomeGaugeSection(
                  temperaturePercentage: 0.75, // 임시 데이터
                  emotionColor: emotionColor,
                ),

                const SizedBox(height: AppSpacing.sm),

                // 3. 메인 버튼 (봄이 대화, 똑똑 알림)
                HomeMainButtons(
                  onChatTap: () => navigationService.navigateToRoute('/bomi'),
                  onAlarmTap: () => navigationService.navigateToRoute('/alarm'),
                ),

                const SizedBox(height: AppSpacing.sm),

                // 4. 배너 슬라이더
                HomeBannerSlider(
                  onTraining1Tap: () =>
                      navigationService.navigateToRoute('/training'),
                  onTraining2Tap: () => navigationService
                      .navigateToRoute('/training'), // TODO: 퀴즈 라우트로 변경
                ),

                // 하단 여백 추가
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
