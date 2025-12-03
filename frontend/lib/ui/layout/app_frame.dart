import 'package:flutter/material.dart';

/// AppFrame - 화면의 기본 레이아웃 구조
///
/// Flutter의 Scaffold 패턴을 따르는 간소화된 프레임워크
/// - topBar: 상단 바 (TopBar 위젯 또는 null)
/// - bottomBar: 하단 바 (BottomMenuBar/BottomButtonBar/BottomInputBar 또는 null)
/// - body: 메인 컨텐츠
class AppFrame extends StatelessWidget {
  const AppFrame({
    super.key,
    this.topBar,
    this.bottomBar,
    required this.body,
  });

  final PreferredSizeWidget? topBar;
  final Widget? bottomBar;
  final Widget body;

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

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: safeTopBar,
      body: SafeArea(child: body),
      bottomNavigationBar: bottomBar,
    );
  }
}
