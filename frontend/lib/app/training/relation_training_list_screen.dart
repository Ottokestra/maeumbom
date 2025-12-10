import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ui/app_ui.dart';
import '../../data/models/training/relation_training.dart';
import 'relation_training_list_screen_viewmodel.dart';
import 'relation_training_screen.dart';

class RelationTrainingListScreen extends ConsumerWidget {
  const RelationTrainingListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listState = ref.watch(relationTrainingListViewModelProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: TopBar(
        title: '관계 훈련',
        leftIcon: Icons.arrow_back,
        onTapLeft: () => Navigator.pop(context),
      ),
      body: listState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('오류가 발생했습니다: $error')),
        data: (scenarios) {
          if (scenarios.isEmpty) {
            return const Center(child: Text('사용 가능한 시나리오가 없습니다.'));
          }
          return _buildScenarioGrid(context, scenarios);
        },
      ),
    );
  }

  Widget _buildScenarioGrid(BuildContext context, List<TrainingScenario> scenarios) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '시나리오를 선택해주세요',
            style: AppTypography.h2,
          ),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.8, // Adjust based on content
            ),
            itemCount: scenarios.length,
            itemBuilder: (context, index) {
              return _buildScenarioCard(context, scenarios[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildScenarioCard(BuildContext context, TrainingScenario scenario) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RelationTrainingScreen(scenarioId: scenario.id),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: scenario.imageUrl != null
                    ? Image.network(
                        scenario.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => Container(
                          color: AppColors.borderLight,
                          child: const Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      )
                    : Container(
                        color: AppColors.moodGoodYellow.withOpacity(0.5), // Fallback color
                        child: const Icon(Icons.people, size: 40, color: AppColors.natureGreen),
                      ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scenario.title,
                      style: AppTypography.bodyBold.copyWith(fontSize: 16),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      scenario.category,
                      style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
