import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import '../../../ui/app_ui.dart';
import '../../../providers/auth_provider.dart';

/// 스플래시 화면
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  /// 스플래시 화면 표시 후 다음 화면으로 이동
  Future<void> _navigateToNextScreen() async {
    // 최소 2초 대기 (스플래시 화면 표시)
    final minDisplayTime = Future.delayed(const Duration(seconds: 2));

    // 인증 상태 확인이 완료될 때까지 대기
    // authProvider가 로딩 중이면 완료될 때까지 기다림
    while (mounted) {
      final authState = ref.read(authProvider);

      // 로딩이 완료되었는지 확인
      if (!authState.isLoading) {
        // 로딩 완료 - 최소 표시 시간도 기다림
        await minDisplayTime;

        if (!mounted) return;

        // 인증 상태에 따라 화면 분기
        final isLoggedIn = authState.value != null;
        if (isLoggedIn) {
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          Navigator.pushReplacementNamed(context, '/login');
        }
        return;
      }

      // 아직 로딩 중이면 잠시 대기 후 다시 확인
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.basicGray,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 마음봄 로고 Lottie 애니메이션 (한 번만 재생)
              Lottie.asset(
                'assets/images/logo/splash.json',
                width: 256,
                height: 256,
                repeat: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
