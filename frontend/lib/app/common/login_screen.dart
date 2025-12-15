import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ui/app_ui.dart';
import '../../providers/auth_provider.dart';
import '../../providers/onboarding_provider.dart';

/// 로그인 화면
///
/// 3개의 슬라이드 페이지와 소셜 로그인 버튼을 포함합니다.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _hasCheckedAuth = false;

  @override
  void initState() {
    super.initState();
    // 인증 상태 확인을 다음 프레임으로 지연하여 위젯 트리가 완전히 빌드된 후 실행
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthStatus();
    });
  }

  /// 이미 로그인된 상태인지 확인하고 적절한 화면으로 이동
  Future<void> _checkAuthStatus() async {
    if (_hasCheckedAuth) return;
    _hasCheckedAuth = true;

    final authState = ref.read(authProvider);
    
    // 로딩 중이면 잠시 대기
    if (authState.isLoading) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      final updatedAuthState = ref.read(authProvider);
      if (updatedAuthState.isLoading) {
        // 여전히 로딩 중이면 다시 확인
        _hasCheckedAuth = false;
        return;
      }
    }

    // 이미 로그인된 상태라면 적절한 화면으로 이동
    authState.whenData((user) {
      if (user != null && mounted) {
        _navigateAfterLogin();
      }
    });
  }

  /// 설문 상태 확인 후 적절한 화면으로 이동
  Future<void> _navigateAfterLogin() async {
    try {
      // Access token 가져오기
      final authService = ref.read(authServiceProvider);
      final accessToken = await authService.getAccessToken();

      if (accessToken == null) {
        // 토큰이 없으면 설문 화면으로 이동 (안전장치)
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/sign_up_slide');
        }
        return;
      }

      // 설문 상태 확인
      final onboardingRepository = ref.read(onboardingSurveyRepositoryProvider);
      final statusResponse = await onboardingRepository.getSurveyStatus();

      if (!mounted) return;

      // 설문 완료 여부에 따라 분기
      if (statusResponse.hasProfile) {
        // 설문 완료된 사용자는 홈으로 이동
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        // 설문 미완료 사용자는 설문 화면으로 이동
        Navigator.pushReplacementNamed(context, '/sign_up_slide');
      }
    } catch (e) {
      // 에러 발생 시 기본값으로 설문 화면으로 이동 (안전장치)
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/sign_up_slide');
      }
    }
  }

  /// 로그인 에러 핸들링 (사용자 취소는 무시)
  void _handleLoginError(BuildContext context, Object error) {
    final errorMsg = error.toString();

    // 사용자 취소는 무시 (정상 동작)
    if (errorMsg.contains('CANCELED') || errorMsg.contains('User canceled')) {
      return;
    }

    // 실제 에러만 다이얼로그 표시
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그인 실패'),
        content: Text(errorMsg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppFrame(
      body: Stack(
        children: [
          // 상단 페이지 인디케이터 (고정)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: _currentPage == index
                          ? AppColors.primaryColor
                          : AppColors.borderLightGray,
                    ),
                  );
                }),
              ),
            ),
          ),

          // 이미지 영역 (상단부터 전체 화면)
          Positioned.fill(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              children: const [
                _FeatureSlide(imagePath: 'assets/images/button/ai_chating.png'),
                _FeatureSlide(imagePath: 'assets/images/button/memory_list.png'),
                _FeatureSlide(imagePath: 'assets/images/button/heart_report.png'),
                _FeatureSlide(imagePath: 'assets/images/button/relation_training.png'),
                _FeatureSlide(imagePath: 'assets/images/button/slang_quiz.png'),
              ],
            ),
          ),

          // 하단 로그인 버튼 (이미지 위에 오버레이)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                left: AppSpacing.md,
                right: AppSpacing.md,
                bottom: MediaQuery.of(context).padding.bottom,
              ),
              decoration: const BoxDecoration(
                color: AppColors.basicColor,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 카카오
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        await ref.read(authProvider.notifier).loginWithKakao();
                        final result = ref.read(authProvider);
                        if (!context.mounted) return;
                        result.when(
                          data: (user) {
                            if (user != null) {
                              _navigateAfterLogin();
                            }
                          },
                          error: (error, stack) => _handleLoginError(context, error),
                          loading: () {},
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFEE500),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: Color(0xFF3C1E1E),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '카카오톡으로 시작하기',
                            style: AppTypography.bodyLarge.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  // 네이버
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        await ref.read(authProvider.notifier).loginWithNaver();
                        final result = ref.read(authProvider);
                        if (!context.mounted) return;
                        result.when(
                          data: (user) {
                            if (user != null) {
                              _navigateAfterLogin();
                            }
                          },
                          error: (error, stack) => _handleLoginError(context, error),
                          loading: () {},
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF03C75A),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '네이버로 시작하기',
                            style: AppTypography.bodyLarge.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  // 구글
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        await ref.read(authProvider.notifier).loginWithGoogle();
                        final result = ref.read(authProvider);
                        if (!context.mounted) return;
                        result.when(
                          data: (user) {
                            if (user != null) {
                              _navigateAfterLogin();
                            }
                          },
                          error: (error, stack) => _handleLoginError(context, error),
                          loading: () {},
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        elevation: 0,
                        side: const BorderSide(color: AppColors.borderLight),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.blue[700],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '구글로 시작하기',
                            style: AppTypography.bodyLarge.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 기능 소개 슬라이드
class _FeatureSlide extends StatelessWidget {
  final String imagePath;

  const _FeatureSlide({
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: FractionalTranslation(
        translation: const Offset(0, -0.10),
        child: Transform.scale(
          scale: 0.8,
          child: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Image.asset(
              imagePath,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}

/// 소셜 로그인 버튼 그룹
class _SocialLoginButtons extends ConsumerWidget {
  const _SocialLoginButtons();

  /// 로그인 에러 핸들링 (사용자 취소는 무시)
  void _handleLoginError(BuildContext context, Object error) {
    final errorMsg = error.toString();

    // 사용자 취소는 무시 (정상 동작)
    if (errorMsg.contains('CANCELED') || errorMsg.contains('User canceled')) {
      return;
    }

    // 실제 에러만 다이얼로그 표시
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그인 실패'),
        content: Text(errorMsg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  /// 설문 상태 확인 후 적절한 화면으로 이동
  Future<void> _navigateAfterLogin(
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
      // Access token 가져오기
      final authService = ref.read(authServiceProvider);
      final accessToken = await authService.getAccessToken();

      if (accessToken == null) {
        // 토큰이 없으면 설문 화면으로 이동 (안전장치)
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/sign_up_slide');
        }
        return;
      }

      // 설문 상태 확인
      final onboardingRepository = ref.read(onboardingSurveyRepositoryProvider);
      final statusResponse = await onboardingRepository.getSurveyStatus();

      if (!context.mounted) return;

      // 설문 완료 여부에 따라 분기
      if (statusResponse.hasProfile) {
        // 설문 완료된 사용자는 홈으로 이동
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        // 설문 미완료 사용자는 설문 화면으로 이동
        Navigator.pushReplacementNamed(context, '/sign_up_slide');
      }
    } catch (e) {
      // 에러 발생 시 기본값으로 설문 화면으로 이동 (안전장치)
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/sign_up_slide');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 카카오
        _SocialButton(
          color: const Color(0xFFFEE500),
          text: authState.isLoading ? '...' : 'K',
          textColor: const Color(0xFF3C1E1E),
          onTap: authState.isLoading
              ? () {} // 로딩 중 비활성화
              : () async {
                  // Kakao 로그인 실행
                  await ref.read(authProvider.notifier).loginWithKakao();

                  // 결과 확인
                  final result = ref.read(authProvider);
                  if (!context.mounted) return;

                  result.when(
                    data: (user) {
                      if (user != null) {
                        // 성공 - 설문 상태 확인 후 적절한 화면으로 이동
                        _navigateAfterLogin(context, ref);
                      }
                    },
                    error: (error, stack) => _handleLoginError(context, error),
                    loading: () {},
                  );
                },
        ),
        const SizedBox(width: 40),
        // 네이버
        _SocialButton(
          color: const Color(0xFF03C75A),
          text: authState.isLoading ? '...' : 'N',
          textColor: Colors.white,
          onTap: authState.isLoading
              ? () {} // 로딩 중 비활성화
              : () async {
                  // Naver 로그인 실행
                  await ref.read(authProvider.notifier).loginWithNaver();

                  // 결과 확인
                  final result = ref.read(authProvider);
                  if (!context.mounted) return;

                  result.when(
                    data: (user) {
                      if (user != null) {
                        // 성공 - 설문 상태 확인 후 적절한 화면으로 이동
                        _navigateAfterLogin(context, ref);
                      }
                    },
                    error: (error, stack) => _handleLoginError(context, error),
                    loading: () {},
                  );
                },
        ),
        const SizedBox(width: 40),
        // 구글
        _SocialButton(
          color: Colors.white,
          text: authState.isLoading ? '...' : 'G',
          textColor: const Color(0xFF5F6368),
          hasBorder: true,
          onTap: authState.isLoading
              ? () {} // 로딩 중 비활성화
              : () async {
                  // Google 로그인 실행
                  await ref.read(authProvider.notifier).loginWithGoogle();

                  // 결과 확인
                  final result = ref.read(authProvider);
                  if (!context.mounted) return;

                  result.when(
                    data: (user) {
                      if (user != null) {
                        // 성공 - 설문 상태 확인 후 적절한 화면으로 이동
                        _navigateAfterLogin(context, ref);
                      }
                    },
                    error: (error, stack) => _handleLoginError(context, error),
                    loading: () {},
                  );
                },
        ),
      ],
    );
  }
}

/// 소셜 로그인 원형 버튼
class _SocialButton extends StatelessWidget {
  final Color color;
  final String text;
  final Color textColor;
  final VoidCallback onTap;
  final bool hasBorder;

  const _SocialButton({
    required this.color,
    required this.text,
    required this.textColor,
    required this.onTap,
    this.hasBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: hasBorder
              ? Border.all(color: AppColors.borderLight, width: 1)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: AppTypography.h2.copyWith(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
