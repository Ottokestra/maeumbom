import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ui/app_ui.dart';
import 'relation_training_screen.dart';

class TrainingScreen extends ConsumerWidget {
  const TrainingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppFrame(
      topBar: TopBar(
        title: '마음연습실',
        rightIcon: Icons.more_horiz,
        onTapRight: () => MoreMenuSheet.show(context),
      ),
      body: const TrainingContent(),
    );
  }
}

class TrainingContent extends StatelessWidget {
  const TrainingContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RelationTrainingScreen(scenarioId: 1),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Text(
                '관계 연습하기',
                textAlign: TextAlign.center,
                style: AppTypography.h2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
