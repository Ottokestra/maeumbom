import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ui/app_ui.dart';
import 'components/conversation_temperature_widget.dart';
import 'components/home_menu_grid.dart';
import '../../providers/daily_mood_provider.dart';
import 'daily_mood_check_screen.dart';

/// Home Screen - 메인 홈 화면
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // NavigationService 인스턴스화 (필요시 사용)
    // final navigationService = NavigationService(context, ref);

    return AppFrame(
      topBar: null, // Custom header used instead
      useSafeArea: false, // Allow background to go behind status bar
      statusBarStyle: SystemUiOverlayStyle.light, // White status bar icons
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
    // 현재 화면이 최상위가 아니면 팝업 띄우지 않음 (예: 온보딩 중)
    if (ModalRoute.of(context)?.isCurrent != true) return;

    final dailyState = ref.read(dailyMoodProvider);
    
    // 아직 기분 체크를 하지 않았다면 팝업 표시
    if (!dailyState.hasChecked) {
      // 화면 진입 후 약간의 딜레이를 두고 표시 (UX 개선 및 안전성)
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
            child: const Text('나중에', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // 팝업 닫기
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DailyMoodCheckScreen(),
                ),
              ).then((_) {
                 // 화면 복귀 후 상태 업데이트가 필요하다면 여기서 처리 (Provider가 관리하므로 자동 반영됨)
              });
            },
            child: const Text('기록하기', style: TextStyle(color: AppColors.accentRed)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // TODO: AuthProvider를 통해 닉네임 가져오기
    // final user = ref.watch(currentUserProvider);
    // final nickname = user?.nickname ?? '봄이';
    const nickname = '김땡땡'; // 임시 하드코딩 (이미지 예시 '홍길동')

    return Container(
      color: AppColors.warmWhite, // Warm white 배경색
      child: Stack(
        children: [
          // 1. Background Layer (Top Red Section)
          Container(
            height: 320, // 높이 조정
            decoration: const BoxDecoration(
              color: AppColors.accentRed,
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(AppRadius.xxl),
              ),
            ),
          ),

          // 2. Content Layer
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.sm),

                  // Header (Title & Greeting)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nickname + " 님,",
                        style: AppTypography.h1.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.pureWhite,
                          fontSize: 32, // 더 큰 폰트 강조
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '오늘 하루도 응원해요!', 
                        // 혹은 이미지처럼 '2021. 10. 15.(금) 오후 03:00에...' 같은 정보가 필요하다면 수정 필요
                        // 여기서는 요청주신 "사용자 닉네임 과 함께 인사를 건내는 문구 표시"에 집중
                        style: AppTypography.h3.copyWith(
                          color: AppColors.pureWhite.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      // 갱년기 설문 진입 버튼 (가시성 확보)
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/menopause_survey'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white, // 흰색 배경
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset:const Offset(0, 2))
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text(
                                '나는 어떤 상태일까?',
                                style: TextStyle(
                                  color: AppColors.accentRed, // 빨간 글씨
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.accentRed),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        width: 40, 
                        height: 2, 
                        color: AppColors.pureWhite.withValues(alpha: 0.5)
                      ), // 구분선 느낌
                      const SizedBox(height: AppSpacing.sm),
                       Text(
                        '마음봄과 함께 오늘의 감정을 나눠보세요.\n당신의 이야기를 들을 준비가 되어있어요.',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.pureWhite.withValues(alpha: 0.8),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md), // 헤더와 본문 사이 간격 최소화

                  // Conversation Temperature Widget (Relocated)
                  // Body 영역(흰색 배경 위)에 위치하도록 배치
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.bgBasic, // 흰색 카드 배경
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF000000).withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Text(
                        //   '마음 대화 온도',
                        //   style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold),
                        // ),
                        // const SizedBox(height: AppSpacing.sm),
                        const ConversationTemperatureWidget(),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: AppSpacing.md),

                  // Menu Grid
                  Text(
                    '마음 챙김 메뉴',
                    style: AppTypography.h3.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const HomeMenuGrid(),

                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
