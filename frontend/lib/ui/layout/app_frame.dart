import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'top_bars.dart';

/// AppFrame - 화면의 기본 레이아웃 구조
///
/// Flutter의 Scaffold 패턴을 따르는 간소화된 프레임워크
/// - topBar: 상단 바 (TopBar 위젯 또는 null)
/// - bottomBar: 하단 바 (BottomMenuBar/BottomButtonBar/BottomInputBar 또는 null)
/// - body: 메인 컨텐츠
/// - statusBarStyle: 상태바 스타일 (자동 감지 또는 수동 설정)
class AppFrame extends StatelessWidget {
  const AppFrame({
    super.key,
    this.topBar,
    this.bottomBar,
    required this.body,
    this.statusBarStyle,
    this.useSafeArea = true,
  });

  final PreferredSizeWidget? topBar;
  final Widget? bottomBar;
  final Widget body;
  final SystemUiOverlayStyle? statusBarStyle;
  final bool useSafeArea;

  @override
  Widget build(BuildContext context) {
    final PreferredSizeWidget? safeTopBar = topBar != null
        ? PreferredSize(
            preferredSize: Size(
              MediaQuery.of(context).size.width,
              topBar!.preferredSize.height,
            ),
            child: SafeArea(child: topBar!),
          ) as PreferredSizeWidget
        : null;

    // 상태바 스타일 자동 감지
    final effectiveStatusBarStyle = statusBarStyle ?? _getStatusBarStyle();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: effectiveStatusBarStyle,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        resizeToAvoidBottomInset: false, // 키보드가 올라와도 화면 크기 유지
        appBar: safeTopBar,
        body: useSafeArea ? SafeArea(child: body) : body,
        bottomNavigationBar: bottomBar,
      ),
    );
  }

  /// TopBar의 배경색을 기반으로 상태바 스타일 자동 결정
  SystemUiOverlayStyle _getStatusBarStyle() {
    if (topBar == null) {
      // TopBar가 없으면 기본 스타일 (어두운 배경용)
      return const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      );
    }

    // TopBar가 있으면 배경색에 따라 결정
    if (topBar is TopBar) {
      final topBarWidget = topBar as TopBar;
      final bgColor = topBarWidget.backgroundColor;

      // 밝은 배경 (흰색 계열) → 어두운 아이콘
      if (_isLightColor(bgColor)) {
        return const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark, // Android
          statusBarBrightness: Brightness.light, // iOS
        );
      }
      // 어두운 배경 (빨간색 등) → 밝은 아이콘
      else {
        return const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light, // Android
          statusBarBrightness: Brightness.dark, // iOS
        );
      }
    }

    // 기본값
    return const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    );
  }

  /// 색상이 밝은지 어두운지 판단
  bool _isLightColor(Color color) {
    // 휘도(Luminance) 기반 판단
    // 0.5 이상이면 밝은 색으로 간주
    return color.computeLuminance() > 0.5;
  }
}
