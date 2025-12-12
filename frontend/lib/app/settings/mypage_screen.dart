import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ui/app_ui.dart';
import '../../core/services/navigation/navigation_service.dart';
import '../../data/dtos/onboarding/onboarding_survey_response.dart';
import '../../providers/auth_provider.dart';
import '../../providers/daily_mood_provider.dart';
import '../../core/utils/logger.dart';
import '../../providers/onboarding_provider.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';
import '../chat/chat_list_screen.dart';
import 'components/profile_header.dart';
import 'components/menu_list_item.dart';

class MypageScreen extends ConsumerStatefulWidget {
  const MypageScreen({super.key});

  @override
  ConsumerState<MypageScreen> createState() => _MypageScreenState();
}

class _MypageScreenState extends ConsumerState<MypageScreen> {
  OnboardingSurveyResponse? _profile;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final onboardingRepository = ref.read(onboardingSurveyRepositoryProvider);
      final profile = await onboardingRepository.getMySurvey();

      if (!mounted) return;
      setState(() {
        _profile = profile;
      });
    } catch (e) {
      appLogger.e('Failed to load profile', error: e);
      if (!mounted) return;
      setState(() {
        _errorMessage = '프로필을 불러오는데 실패했습니다.';
      });
    }
  }

  Future<void> _showProfileInfo() async {
    if (_profile == null) {
      TopNotificationManager.show(
        context,
        message: '프로필 정보를 불러오는 중입니다.',
        type: TopNotificationType.red,
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: AppColors.basicColor,
          body: AppFrame(
            topBar: TopBar(
              title: '회원정보',
              leftIcon: Icons.arrow_back,
              onTapLeft: () => Navigator.pop(context),
            ),
            bottomBar: BottomButtonBar(
              primaryText: '수정',
              onPrimaryTap: () async {
                Navigator.pop(context);
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EditProfileScreen(),
                  ),
                );
                if (result == true) {
                  _loadProfile();
                }
              },
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('닉네임', _profile!.nickname),
                  _buildInfoRow('연령대', _profile!.ageGroup),
                  _buildInfoRow('성별', _profile!.gender),
                  _buildInfoRow('결혼 여부', _profile!.maritalStatus),
                  _buildInfoRow('자녀 유무', _profile!.childrenYn),
                  _buildInfoRow('동거인', _profile!.livingWith.join(', ')),
                  _buildInfoRow('성향', _profile!.personalityType),
                  _buildInfoRow('활동 스타일', _profile!.activityStyle),
                  _buildInfoRow('스트레스 해소법', _profile!.stressRelief.join(', ')),
                  _buildInfoRow('취미', _profile!.hobbies.join(', ')),
                  if (_profile!.atmosphere.isNotEmpty)
                    _buildInfoRow('선호 분위기', _profile!.atmosphere.join(', ')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    // 확인 모달 표시
    final confirm = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BottomAddModalBar(
        title: '로그아웃',
        onClose: () => Navigator.pop(context, false),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '정말 로그아웃하시겠습니까?',
                style: AppTypography.body.copyWith(
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: '취소',
                      variant: ButtonVariant.secondaryRed,
                      onTap: () => Navigator.pop(context, false),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppButton(
                      text: '로그아웃',
                      variant: ButtonVariant.primaryRed,
                      onTap: () => Navigator.pop(context, true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm != true) return;

    try {
      // 로그아웃 실행
      await ref.read(authProvider.notifier).logout();

      if (!mounted) return;

      // 로그인 화면으로 이동
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false, // 모든 이전 라우트 제거
      );
    } catch (e) {
      appLogger.e('로그아웃 실패', error: e);
      if (!mounted) return;
      TopNotificationManager.show(
        context,
        message: '로그아웃 중 오류가 발생했습니다.',
        type: TopNotificationType.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final navigationService = NavigationService(context, ref);
    final dailyState = ref.watch(dailyMoodProvider);
    final authState = ref.watch(authProvider);

    // 현재 감정 (기본값: joy)
    final currentEmotion = dailyState.selectedEmotion ?? EmotionId.joy;

    // 사용자 정보
    final user = authState.value;
    final nickname = _profile?.nickname ?? user?.nickname ?? '사용자';

    // 가입일 계산
    int daysWithService = 0;
    if (user?.createdAt != null) {
      final createdAt = user!.createdAt;
      final now = DateTime.now();
      daysWithService = now.difference(createdAt).inDays;
    }

    // TODO: 실제 대화 수를 chat provider에서 가져오기
    const totalChatCount = 12; // 임시값

    // 레벨 계산 (20회당 레벨업)
    const conversationsPerLevel = 20;
    final currentLevelProgress = totalChatCount % conversationsPerLevel;
    final levelPercentage =
        ((currentLevelProgress / conversationsPerLevel) * 100).round();
    final conversationsRemaining = conversationsPerLevel - currentLevelProgress;

    return AppFrame(
      topBar: TopBar(
        title: '마이페이지',
      ),
      bottomBar: BottomMenuBar(
        currentIndex: 4,
        onTap: (index) {
          navigationService.navigateToTab(index);
        },
      ),
      body: Column(
        children: [
              // 프로필 헤더
              ProfileHeader(
                nickname: nickname,
                daysWithService: daysWithService,
                levelPercentage: levelPercentage,
                conversationsRemaining: conversationsRemaining,
                emotionCharacter: EmotionCharacter(
                  id: currentEmotion,
                  size: 60,
                ),
              ),

              // 스크롤 가능한 콘텐츠 영역
              Expanded(
                child: Container(
                  color: AppColors.basicGray,
                  child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      const SizedBox(height: AppSpacing.sm),

                      // 나의 활동 섹션
                      Container(
                        color: AppColors.basicColor,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                left: AppSpacing.md,
                                top: 12,
                                bottom: 12,
                              ),
                              child: Text(
                                '나의 활동',
                                style: AppTypography.bodySmall.copyWith(
                                  color: const Color(0xFF697282),
                                ),
                              ),
                            ),
                            MenuListItem(
                              icon: Icons.person_outline,
                              label: '회원정보',
                              onTap: _showProfileInfo,
                            ),
                            MenuListItem(
                              icon: Icons.chat_bubble_outline,
                              label: '대화 기록',
                              badgeCount: totalChatCount,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ChatListScreen(),
                                  ),
                                );
                              },
                            ),
                            MenuListItem(
                              icon: Icons.favorite_border,
                              label: '갱년기 테스트',
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/menopause-survey-intro',
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.sm),

                      // 설정 버튼
                      Container(
                        color: AppColors.basicColor,
                        child: MenuListItem(
                          icon: Icons.settings_outlined,
                          label: '설정',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SettingsScreen(),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: AppSpacing.sm),

                      // 계정 관리 섹션
                      Container(
                        color: AppColors.basicColor,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                left: AppSpacing.md,
                                top: 12,
                                bottom: 12,
                              ),
                              child: Text(
                                '계정 관리',
                                style: AppTypography.bodySmall.copyWith(
                                  color: const Color(0xFF697282),
                                ),
                              ),
                            ),
                            MenuListItem(
                              icon: Icons.logout,
                              label: '로그아웃',
                              onTap: _handleLogout,
                            ),
                          ],
                        ),
                      ),

                      // 에러 메시지
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.bgLightPink,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            child: Text(
                              _errorMessage!,
                              style: AppTypography.body
                                  .copyWith(color: AppColors.error),
                            ),
                          ),
                        ),

                      // 하단 여백 (회색 배경이 화면을 채우도록)
                      const SizedBox(height: AppSpacing.lg),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: AppTypography.bodyBold,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.body,
            ),
          ),
        ],
      ),
    );
  }
} // End of class
