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
import 'core/services/alarm/alarm_manager_service.dart'; // 🆕 AlarmManager
import 'debug/db_path_helper.dart';
import 'app/slang_quiz/slang_quiz_game_screen.dart';
import 'app/slang_quiz/slang_quiz_result_screen.dart';
import 'app/slang_quiz/slang_quiz_admin_screen.dart';
import 'data/dtos/slang_quiz/end_game_response.dart';

// GlobalKey for navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Kakao SDK 초기화
  KakaoSdk.init(
    nativeAppKey: OAuthConfig.kakaoNativeAppKey,
    loggingEnabled: true,
  );

  // Kakao origin hash 출력
  final origin = await KakaoSdk.origin;
  debugPrint(':열쇠: Kakao origin hash: $origin');

  // 🔍 DB 파일 경로 출력 (디버그용)
  await DbPathHelper.printDbPath();

  // 🆕 알람 서비스 초기화
  final alarmService = AlarmManagerService(); // 🆕 AlarmManager 사용
  await alarmService.initialize();

  // 🔔 알림 권한 체크
  debugPrint('🔔 Checking notification permissions...');
  final hasPermission = await alarmService.checkPermissions();
  debugPrint('🔔 Notification permission status: $hasPermission');

  if (!hasPermission) {
    debugPrint('⚠️ Notification permission not granted, requesting...');
    final granted = await alarmService.requestPermissions();
    debugPrint('🔔 Permission request result: $granted');

    if (!granted) {
      debugPrint('❌ User denied notification permission!');
      debugPrint('⚠️ Alarms will not work without notification permission!');
    } else {
      debugPrint('✅ Notification permission granted!');
    }
  } else {
    debugPrint('✅ Notification permission already granted');
  }

  // 🆕 AlarmManagerService는 백그라운드에서 자동으로 초기화 시 권한 처리
  // onNotificationTapped 콜백은 AlarmManagerService에 없음

  debugPrint('✅ AlarmManagerService initialized');

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
      navigatorKey: navigatorKey,
      title: 'Maeumbom',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      initialRoute: '/splash',
      onGenerateRoute: (settings) {
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

        // Custom routes with arguments (Slang Quiz)
        if (routeName == '/training/slang-quiz/game') {
          final args = settings.arguments as Map<String, dynamic>?;
          if (args != null) {
            return MaterialPageRoute(
              builder: (context) => SlangQuizGameScreen(
                level: args['level'] as String,
                quizType: args['quizType'] as String,
              ),
              settings: settings,
            );
          }
        }

        if (routeName == '/training/slang-quiz/result') {
          final result = settings.arguments as EndGameResponse?;
          if (result != null) {
            return MaterialPageRoute(
              builder: (context) => SlangQuizResultScreen(result: result),
              settings: settings,
            );
          }
        }

        if (routeName == '/training/slang-quiz/admin') {
          return MaterialPageRoute(
            builder: (context) => const SlangQuizAdminScreen(),
            settings: settings,
          );
        }

        // 표준 라우트 처리
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
