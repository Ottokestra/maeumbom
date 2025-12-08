import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ui/app_ui.dart';
import '../../providers/auth_provider.dart';

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
    // 2초 대기 (스플래시 화면 표시)
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // 인증 상태 확인
    final authState = ref.read(authProvider);
    final isLoggedIn = authState.value != null;

    if (!mounted) return;

    // 인증 상태에 따라 화면 분기
    if (isLoggedIn) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light, // Android
        statusBarBrightness: Brightness.dark, // iOS
      ),
      child: Scaffold(
        backgroundColor: AppColors.accentRed,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 마음봄 로고
              Image.asset(
                'assets/images/logo/logo.png',
                width: 256,
                height: 256,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
