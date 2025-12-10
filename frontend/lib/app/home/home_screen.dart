import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ui/app_ui.dart';
import '../../providers/daily_mood_provider.dart';
import '../../core/utils/emotion_classifier.dart';
import 'components/home_header_section.dart';
import 'components/conversation_temperature_bar.dart';
import 'components/home_bottom_menu.dart';
import 'daily_mood_check_screen.dart';

/// Home Screen - 메인 홈 화면
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppFrame(
      topBar: null,
      useSafeArea: false,
      statusBarStyle: SystemUiOverlayStyle.light, // 흰색 상태 바 아이콘
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('오늘의 기분은 어떠신가요?'),
        content: const Text('아직 오늘의 감정 캐릭터를 선택하지 않으셨어요.\n지금 기록하러 가볼까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '나중에',
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DailyMoodCheckScreen(),
                ),
              );
            },
            child: Text(
              '기록하기',
              style: AppTypography.body.copyWith(
                color: AppColors.accentRed,
              ),
            ),
          ),
        ],
      ),
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
            // 상단 콘텐츠 영역
            Expanded(
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

            // 4. 하단 메뉴
            const HomeBottomMenu(),
          ],
        ),
      ),
    );
  }

  /// 기분 카테고리에 따른 배경색 반환
  Color _getBackgroundColor(MoodCategory category) {
    switch (category) {
      case MoodCategory.good:
        return AppColors.homeGoodYellow;
      case MoodCategory.neutral:
        return AppColors.homeNormalGreen;
      case MoodCategory.bad:
        return AppColors.homeBadBlue;
    }
  }
}
