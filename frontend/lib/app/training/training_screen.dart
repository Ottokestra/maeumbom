import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ui/app_ui.dart';
import 'relation_training_list_screen.dart';
import '../../core/services/navigation/navigation_service.dart';

class TrainingScreen extends ConsumerWidget {
  const TrainingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationService = NavigationService(context, ref);
    
    return AppFrame(
      topBar: TopBar(
        title: '마음연습실',
        leftIcon: Icons.arrow_back,
        onTapLeft: () => navigationService.navigateToTab(0),
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
          _buildMenuCard(
            context,
            title: '관계 연습하기',
            icon: Icons.people,
            color: AppColors.moodGoodYellow,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RelationTrainingListScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          _buildMenuCard(
            context,
            title: '신조어 퀴즈',
            icon: Icons.quiz,
            color: AppColors.moodNormalGreen,
            onTap: () {
              Navigator.pushNamed(context, '/training/slang-quiz/start');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(title, style: AppTypography.h2),
          ],
        ),
      ),
    );
  }
}
