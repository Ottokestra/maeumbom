import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'ui/app_ui.dart';
import 'core/config/app_routes.dart';
import 'core/services/navigation/route_guard.dart';
import 'app/common/login_screen.dart';
import 'app/home/home_screen.dart';
import 'core/config/oauth_config.dart';
import 'package:kakao_flutter_sdk_common/kakao_flutter_sdk_common.dart';


// void main() {
//   // Kakao SDK 초기화
//   KakaoSdk.init(
//     nativeAppKey: OAuthConfig.kakaoNativeAppKey,
//   );

//   runApp(
//     const ProviderScope(
//       child: MaeumBomApp(),
//     ),
//   );
// }

// ✅ 이렇게 변경
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Kakao SDK 초기화
  KakaoSdk.init(
    nativeAppKey: OAuthConfig.kakaoNativeAppKey,
    loggingEnabled: true, // 로그 보기 좋게
  );

  // 🔑 여기서 키 해시(origin) 한 번 출력
  final origin = await KakaoSdk.origin;
  debugPrint('🔑 Kakao origin hash: $origin');

  runApp(
    const ProviderScope(
      child: MaeumBomApp(),
    ),
  );
}

class MaeumBomApp extends ConsumerWidget {
  const MaeumBomApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Maeumbom',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      initialRoute: '/example',
      onGenerateRoute: (settings) {
        // RouteGuard를 사용하여 인증 체크
        final routeGuard = ref.read(routeGuardProvider);
        final routeName = settings.name ?? '/';

        // 인증이 필요한 경로인지 확인
        if (routeGuard.requiresAuth(routeName)) {
          // 인증 상태 확인
          if (!routeGuard.canAccess(routeName)) {
            // 로그인되지 않았으면 로그인 화면으로 리다이렉트
            return MaterialPageRoute(
              builder: (context) => const LoginScreen(),
              settings:
                  RouteSettings(name: '/login', arguments: settings.arguments),
            );
          }
        }

        // 인증이 필요 없거나 인증된 경우 정상 라우트 반환
        final routeMetadata = AppRoutes.findByRouteName(routeName);
        if (routeMetadata != null) {
          return MaterialPageRoute(
            builder: (context) => routeMetadata.builder(),
            settings: settings,
          );
        }

        // 라우트를 찾을 수 없으면 홈으로 리다이렉트
        return MaterialPageRoute(
          builder: (context) => const HomeScreen(),
          settings: RouteSettings(name: '/home', arguments: settings.arguments),
        );
      },
    );
  }
}
