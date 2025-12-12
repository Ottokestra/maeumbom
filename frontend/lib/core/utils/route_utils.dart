import 'package:flutter/material.dart';

/// 탭 전환용 페이드 전환 Route
class FadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  FadePageRoute({required this.page})
      : super(
          pageBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) =>
              page,
          transitionsBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 200),
        );
}

/// 탭 전환 헬퍼 함수
class TabNavigator {
  /// 탭 전환 (페이드 애니메이션)
  static void pushReplacement(BuildContext context, Widget page) {
    Navigator.pushReplacement(
      context,
      FadePageRoute(page: page),
    );
  }

  /// 탭 전환 (라우트 이름으로)
  static void pushReplacementNamed(
    BuildContext context,
    String routeName,
    Widget Function() builder,
  ) {
    Navigator.pushReplacement(
      context,
      FadePageRoute(page: builder()),
    );
  }
}

