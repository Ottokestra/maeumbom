import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/route_utils.dart';
import '../navigation/route_guard.dart';
import '../../config/app_routes.dart';
import '../../../app/common/login_screen.dart';

/// 중앙화된 네비게이션 서비스
class NavigationService {
  final BuildContext context;
  final WidgetRef ref;

  NavigationService(this.context, this.ref);

  /// 탭 인덱스에 따라 화면으로 이동 (인증 체크 포함)
  void navigateToTab(int index) {
    // AppRoutes에서 탭 인덱스로 라우트 찾기
    final routeMetadata = AppRoutes.findByTabIndex(index);

    if (routeMetadata == null) {
      return;
    }

    // 인증 체크 및 네비게이션
    _navigateToRouteMetadata(routeMetadata);
  }

  /// 특정 경로로 이동 (인증 체크 포함)
  void navigateToRoute(String routeName) {
    // AppRoutes에서 경로 이름으로 라우트 찾기
    final routeMetadata = AppRoutes.findByRouteName(routeName);

    if (routeMetadata == null) {
      return;
    }

    // 인증 체크 및 네비게이션
    _navigateToRouteMetadata(routeMetadata);
  }

  /// RouteMetadata를 기반으로 네비게이션 (인증 체크 포함)
  void _navigateToRouteMetadata(RouteMetadata routeMetadata) {
    final routeGuard = ref.read(routeGuardProvider);

    // 인증이 필요한 경로인지 확인
    if (routeMetadata.requiresAuth) {
      // 인증 상태 확인
      if (!routeGuard.canAccess(routeMetadata.routeName)) {
        // 로그인되지 않았으면 로그인 화면으로 리다이렉트
        _redirectToLogin();
        return;
      }
    }

    // 인증이 필요 없거나 인증된 경우 화면 이동
    final targetScreen = routeMetadata.builder();
    TabNavigator.pushReplacement(context, targetScreen);
  }

  /// 로그인 화면으로 리다이렉트
  void _redirectToLogin() {
    TabNavigator.pushReplacement(context, const LoginScreen());
  }
}
