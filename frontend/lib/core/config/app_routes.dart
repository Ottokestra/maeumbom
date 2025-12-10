import 'package:flutter/material.dart';
import '../../app/home/home_screen.dart';
import '../../app/alarm/alarm_screen.dart';
import '../../app/chat/chat_screen.dart';
import '../../app/report/report_screen.dart';
import '../../app/settings/mypage_screen.dart';
import '../../app/common/login_screen.dart';
import '../../app/example/example_screen.dart';
import '../../app/sign/sign_up_slide_screen.dart';
import '../../app/sign/sign_up1.dart';
import '../../app/survey/menopause_survey_screen.dart';
import '../../app/example/bubble_screen.dart';
import '../../app/onboarding/splash_screen.dart';
import '../../app/chat/bomi_screen.dart';
import '../../app/training/training_screen.dart';
import '../../app/chat/chat_list_screen.dart';

/// 라우트 메타데이터
class RouteMetadata {
  final String routeName;
  final Widget Function() builder;
  final bool requiresAuth;
  final int? tabIndex; // 탭 메뉴에 표시되는 경우 인덱스

  const RouteMetadata({
    required this.routeName,
    required this.builder,
    this.requiresAuth = false,
    this.tabIndex,
  });
}

/// 앱의 모든 라우트 정의
class AppRoutes {
  // 공개 경로 (인증 불필요)
  static const RouteMetadata splash = RouteMetadata(
    routeName: '/splash',
    builder: SplashScreen.new,
  );

  static const RouteMetadata home = RouteMetadata(
    routeName: '/home',
    builder: HomeScreen.new,
    tabIndex: 0, // BottomMenuBar: 홈 아이콘
  );

  static const RouteMetadata alarm = RouteMetadata(
    routeName: '/alarm',
    builder: AlarmScreen.new,
  );

  static const RouteMetadata bomi = RouteMetadata(
    routeName: '/bomi',
    builder: BomiScreen.new,
    requiresAuth: true,
    tabIndex: 1, // BottomMenuBar: 마이크 버튼 (중앙)
  );

  static const RouteMetadata report = RouteMetadata(
    routeName: '/report',
    builder: ReportScreen.new,
    requiresAuth: true,
  );

  static const RouteMetadata mypage = RouteMetadata(
    routeName: '/mypage',
    builder: MypageScreen.new,
    requiresAuth: true,
  );

  static const RouteMetadata login = RouteMetadata(
    routeName: '/login',
    builder: LoginScreen.new,
  );

  static const RouteMetadata example = RouteMetadata(
    routeName: '/example',
    builder: ExampleScreen.new,
  );

  static const RouteMetadata bubbleTest = RouteMetadata(
    routeName: '/bubble-test',
    builder: BubbleScreen.new,
  );

  static const RouteMetadata training = RouteMetadata(
    routeName: '/training',
    builder: TrainingScreen.new,
  );

  // 보호된 경로 (인증 필요)
  static const RouteMetadata chat = RouteMetadata(
    routeName: '/chat',
    builder: ChatScreen.new,
    requiresAuth: true,
  );

  static const RouteMetadata signUpSlide = RouteMetadata(
    routeName: '/sign_up_slide',
    builder: SignUp1Screen.new,
    requiresAuth: true, // 로그인 직후 진입하므로 인증 필요
  );

  static const RouteMetadata menopauseSurvey = RouteMetadata(
    routeName: '/menopause_survey',
    builder: MenopauseSurveyScreen.new,
    requiresAuth: true,
  );

  static const RouteMetadata chatList = RouteMetadata(
    routeName: '/chat_list',
    builder: ChatListScreen.new,
    requiresAuth: true,
  );

  /// 모든 라우트 목록
  static const List<RouteMetadata> allRoutes = [
    splash,
    home,
    alarm,
    chat,
    chatList,
    report,
    mypage,
    login,
    example,
    signUpSlide,
    bubbleTest,
    bomi,
    training,
    menopauseSurvey,
  ];

  /// 경로 이름으로 라우트 찾기
  static RouteMetadata? findByRouteName(String routeName) {
    try {
      return allRoutes.firstWhere(
        (route) => route.routeName == routeName,
      );
    } catch (e) {
      return null;
    }
  }

  /// 탭 인덱스로 라우트 찾기
  static RouteMetadata? findByTabIndex(int tabIndex) {
    try {
      return allRoutes.firstWhere(
        (route) => route.tabIndex == tabIndex,
      );
    } catch (e) {
      return null;
    }
  }

  /// 인증이 필요한 경로 목록
  static List<String> get protectedRoutes => allRoutes
      .where((route) => route.requiresAuth)
      .map((route) => route.routeName)
      .toList();

  /// MaterialApp의 routes 맵 생성
  static Map<String, Widget Function(BuildContext)> toMaterialRoutes() {
    final Map<String, Widget Function(BuildContext)> routes = {};
    for (final route in allRoutes) {
      routes[route.routeName] = (context) => route.builder();
    }
    // 루트 경로는 스플래시 화면
    routes['/'] = (context) => const SplashScreen();
    return routes;
  }
}
