import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'top_bars.dart';
import 'bottom_menu_bars.dart';

/// AppFrame - 화면의 기본 레이아웃 구조
///
/// Flutter의 Scaffold 패턴을 따르는 간소화된 프레임워크
/// - topBar: 상단 바 (TopBar 위젯 또는 null)
/// - bottomBar: 하단 바 (BottomMenuBar/BottomButtonBar/BottomInputBar 또는 null)
/// - body: 메인 컨텐츠
/// - statusBarStyle: 상태바 스타일 (자동 감지 또는 수동 설정)
/// - resizeToAvoidBottomInset: 키보드가 올라올 때 화면 크기 조정 여부
class AppFrame extends StatelessWidget {
  const AppFrame({
    super.key,
    this.topBar,
    this.bottomBar,
    required this.body,
    this.statusBarStyle,
    this.useSafeArea = true,
    this.resizeToAvoidBottomInset = false,
  });

  final PreferredSizeWidget? topBar;
  final Widget? bottomBar;
  final Widget body;
  final SystemUiOverlayStyle? statusBarStyle;
  final bool useSafeArea;
  final bool resizeToAvoidBottomInset;

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

    // BottomMenuBar일 경우에만 처리 (투명 영역 20px + 불투명 영역 90px)
    // - extendBody: true로 바디를 바텀바 뒤까지 확장
    // - padding-bottom: 90px로 불투명 영역만큼 패딩 처리
    final isBottomMenuBar = bottomBar is BottomMenuBar;
    
final bodyWidget = isBottomMenuBar
    ? Padding(
        padding: const EdgeInsets.only(bottom: 90),
        child: useSafeArea
            ? SafeArea(
                top: true,
                bottom: false,
                child: body,
              )
            : body,
      )
    : (useSafeArea ? SafeArea(child: body) : body);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: effectiveStatusBarStyle,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        appBar: safeTopBar,
        body: bodyWidget,
        bottomNavigationBar: bottomBar,
        extendBody: isBottomMenuBar,
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
