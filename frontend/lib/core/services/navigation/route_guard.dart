import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/auth_provider.dart';
import '../../config/app_routes.dart';

/// Route Guard 서비스
class RouteGuard {
  final Ref ref;

  RouteGuard(this.ref);

  /// 인증이 필요한 경로에 접근 가능한지 확인
  bool canAccess(String route) {
    if (!requiresAuth(route)) {
      return true; // 인증이 필요 없는 경로는 항상 접근 가능
    }

    // 인증이 필요한 경로는 로그인 상태 확인
    final isAuthenticated = ref.read(isAuthenticatedProvider);
    return isAuthenticated;
  }

  /// 인증이 필요한 경로인지 확인
  bool requiresAuth(String route) {
    final routeMetadata = AppRoutes.findByRouteName(route);
    return routeMetadata?.requiresAuth ?? false;
  }
}

/// Route Guard Provider
final routeGuardProvider = Provider<RouteGuard>((ref) {
  return RouteGuard(ref);
});
