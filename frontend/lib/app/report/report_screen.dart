import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ui/app_ui.dart';
import '../../core/services/navigation/navigation_service.dart';

/// Report Screen - 마음리포트 화면
class ReportScreen extends ConsumerWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationService = NavigationService(context, ref);

    return AppFrame(
      topBar: TopBar(
        title: '마음리포트',
      ),
      bottomBar: BottomMenuBar(
        currentIndex: 3,
        onTap: (index) {
          navigationService.navigateToTab(index);
        },
      ),
      body: const ReportContent(),
    );
  }
}

/// Report Content
class ReportContent extends StatelessWidget {
  const ReportContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          Text(
            '마음리포트',
            style: AppTypography.h2,
          ),
        ],
      ),
    );
  }
}

