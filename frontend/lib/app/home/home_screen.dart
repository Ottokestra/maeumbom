import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ui/app_ui.dart';
import '../../core/services/navigation/navigation_service.dart';

/// Home Screen - 메인 홈 화면
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationService = NavigationService(context, ref);

    return AppFrame(
      // 상단 바와 하단 바를 포함한 기본 레이아웃
      topBar: TopBar(
        title: '',
      ),
      bottomBar: BottomMenuBar(
        currentIndex: 0,
        onTap: (index) {
          navigationService.navigateToTab(index);
        },
      ),
      // body: 홈 화면의 본문 내용
      body: const HomeContent(),
    );
  }
}

/// Home Content
class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          Text(
            '오늘 하루 어떠셨나요?',
            style: AppTypography.h2,
          ),
        ],
      ),
    );
  }
}
