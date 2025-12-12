import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ui/app_ui.dart';
import '../../providers/daily_mood_provider.dart';
import '../../core/utils/emotion_classifier.dart';
import '../../core/services/navigation/navigation_service.dart';
import 'components/home_header_section.dart';
import 'components/home_gauge_section.dart';
import 'components/home_main_buttons.dart';
import 'components/home_banner_slider.dart';
import 'daily_mood_check_screen.dart';

/// Home Screen - 메인 홈 화면
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 배경색이 항상 밝은 계열이므로 상태바 아이콘은 어둡게 설정
    // 추후 배경색이 어두워지는 경우가 생긴다면 여기서 로직 추가
    const statusBarStyle = SystemUiOverlayStyle.dark;

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

    // 배경색 결정
    final backgroundColor = _getBackgroundColor(moodCategory);

    // 텍스트/아이콘 색상 결정
    final contentColor = _getContentColor(moodCategory);

    // 감정 색상 가져오기 (게이지용)
    final emotionColor = _getEmotionColor(currentEmotion);

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
                  onTraining1Tap: () => navigationService.navigateToRoute('/training'),
                  onTraining2Tap: () => navigationService.navigateToRoute('/training'), // TODO: 퀴즈 라우트로 변경
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

  /// 기분 카테고리에 따른 텍스트/아이콘 색상 반환
  Color _getContentColor(MoodCategory category) {
    // 모든 배경이 밝은 계열이므로 가독성을 위해 어두운 텍스트 색상 사용
    switch (category) {
      case MoodCategory.good:
        return AppColors.textWhite;
      case MoodCategory.neutral:
        return AppColors.textWhite;
      case MoodCategory.bad:
        return AppColors.textWhite;
    }
  }

  /// 기분 카테고리에 따른 포인트 색상
  Color _getPointColor(MoodCategory category) {
    switch (category) {
      case MoodCategory.good:
        return AppColors.moodGoodbgColor;
      case MoodCategory.neutral:
        return AppColors.moodGoodbgColor;
      case MoodCategory.bad:
        return AppColors.moodGoodbgColor;
    }
  }

  /// 감정 ID에 따른 메인 색상 반환
  Color _getEmotionColor(EmotionId emotion) {
    switch (emotion) {
      case EmotionId.joy:
        return AppColors.emotionHappinessPrimary;
      case EmotionId.love:
        return AppColors.emotionLovePrimary;
      case EmotionId.relief:
        return AppColors.emotionStabilityPrimary;
      case EmotionId.excitement:
        return AppColors.emotionMotivationPrimary; // 임시 매핑
      case EmotionId.anger:
        return AppColors.emotionAngerPrimary;
      case EmotionId.fear:
        return AppColors.emotionWorryPrimary;
      case EmotionId.sadness:
        return AppColors.emotionWorryPrimary; // 임시 매핑
      case EmotionId.boredom:
        return AppColors.emotionConfusionPrimary; // 임시 매핑
       // 기타 등등... 기본값
      default:
        return AppColors.primaryColor;
    }
  }
}
