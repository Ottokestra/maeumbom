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
        title: '',
        leftIcon: Icons.arrow_back,
        onTapLeft: () => navigationService.navigateToTab(0),
      ),
      body: Column(
        children: [
          const Expanded(child: TrainingContent()),
          _buildTrainingStats(context),
        ],
      ),
    );
  }

  void _navigateToAddScenario(BuildContext context) {
    Navigator.pushNamed(context, '/training/add-scenario');
  }

  Widget _buildTrainingStats(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primaryColor,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('내 연습 기록',
                    style:
                        AppTypography.h3.copyWith(color: AppColors.textWhite)),
                Text('2개 완료',
                    style:
                        AppTypography.h1.copyWith(color: AppColors.textWhite)),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('전체',
                    style:
                        AppTypography.h3.copyWith(color: AppColors.textWhite)),
                Text('4개',
                    style:
                        AppTypography.h1.copyWith(color: AppColors.textWhite)),
              ],
            ),
          ],
        ),
      ),
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
            badge: '쉬움',
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
            badge: '보통',
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
    required String badge,
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.h2),
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      badge,
                      style: AppTypography.body
                          .copyWith(color: AppColors.textWhite),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
