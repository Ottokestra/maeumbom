import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ui/app_ui.dart';
import '../../core/services/navigation/navigation_service.dart';

class AlarmScreen extends ConsumerWidget {
  const AlarmScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationService = NavigationService(context, ref);

    return AppFrame(
      topBar: TopBar(
        title: '알람',
      ),
      bottomBar: BottomMenuBar(
        currentIndex: 1,
        onTap: (index) {
          navigationService.navigateToTab(index);
        },
      ),
      body: const AlarmContent(),
    );
  }
}

class AlarmContent extends StatelessWidget {
  const AlarmContent({super.key});

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
