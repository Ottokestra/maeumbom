import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ui/app_ui.dart';
import '../../data/models/training/relation_training.dart';
import 'relation_training_list_screen_viewmodel.dart';
import 'relation_training_screen.dart';
import 'scenario_generation_dialog.dart';

class RelationTrainingListScreen extends ConsumerWidget {
  const RelationTrainingListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listState = ref.watch(relationTrainingListViewModelProvider);

    return AppFrame(
      topBar: TopBar(
        title: '관계 훈련',
        leftIcon: Icons.arrow_back,
        onTapLeft: () => Navigator.pop(context),
        rightIcon: Icons.settings,
        onTapRight: () => _showGenerationDialog(context, ref),
      ),
      body: listState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('오류가 발생했습니다: $error')),
        data: (scenarios) {
          if (scenarios.isEmpty) {
            return const Center(child: Text('사용 가능한 시나리오가 없습니다.'));
          }
          return _buildScenarioGrid(context, ref, scenarios);
        },
      ),
    );
  }

  Future<void> _showGenerationDialog(BuildContext context, WidgetRef ref) async {
    print('[DEBUG] Opening scenario generation dialog');
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => const ScenarioGenerationDialog(),
    );

    print('[DEBUG] Dialog closed with result: $result');
    
    if (result != null && context.mounted) {
      print('[DEBUG] Result is not null and context is mounted');
      try {
        final viewModel = ref.read(relationTrainingListViewModelProvider.notifier);
        
        // 비동기로 시나리오 생성 시작 (즉시 응답)
        await viewModel.generateScenario(
          target: result['target']!,
          topic: result['topic']!,
          category: result['category'] ?? 'TRAINING',
          genre: result['genre'], // 드라마 선택 시에만 있음
        );
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('시나리오 생성이 시작되었습니다. 잠시 후 목록을 새로고침해주세요.'),
              duration: Duration(seconds: 5),
            ),
          );
          
          // 3초 후 자동으로 목록 새로고침
          Future.delayed(const Duration(seconds: 3), () {
            if (context.mounted) {
              viewModel.getScenarios();
            }
          });
          
          // 10초 후 다시 한 번 새로고침 (생성 완료 확인)
          Future.delayed(const Duration(seconds: 10), () {
            if (context.mounted) {
              viewModel.getScenarios();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('시나리오 생성이 완료되었을 수 있습니다. 목록을 확인해주세요.'),
                  duration: Duration(seconds: 3),
                ),
              );
            }
          });
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('오류 발생: $e'),
              backgroundColor: AppColors.errorRed,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

  Widget _buildScenarioGrid(BuildContext context, WidgetRef ref, List<TrainingScenario> scenarios) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '시나리오를 선택해주세요',
            style: AppTypography.h2,
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.builder(
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.7, // Adjust based on content
              ),
              itemCount: scenarios.length,
              itemBuilder: (context, index) {
                return _buildScenarioCard(context, ref, scenarios[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScenarioCard(BuildContext context, WidgetRef ref, TrainingScenario scenario) {
    final isUserScenario = scenario.userId != null;
    
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
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: (isUserScenario || scenario.imageUrl == null || scenario.imageUrl!.isEmpty)
                        ? Image.asset(
                            'assets/training_images/randomQ.png',
                            fit: BoxFit.cover,
                          )
                        : Image.network(
                            scenario.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => Image.asset(
                              'assets/training_images/randomQ.png',
                              fit: BoxFit.cover,
                            ),
                          )
                      // 1212뱡합 에러 확인 필요
                        : Container(
                            color: AppColors.moodGoodYellow.withOpacity(0.5),
                            child: const Icon(Icons.people, size: 40, color: AppColors.secondaryColor),
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
                          style: AppTypography.bodyBold,
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
            // Badge: 공용 vs 내 시나리오
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isUserScenario ? AppColors.primaryColor : Colors.grey[600],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isUserScenario ? '내 시나리오' : '공용',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            // Delete button for user scenarios
            if (isUserScenario)
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => _confirmDelete(context, ref, scenario),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, TrainingScenario scenario) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('시나리오 삭제'),
        content: Text('${scenario.title} 시나리오를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final viewModel = ref.read(relationTrainingListViewModelProvider.notifier);
      await viewModel.deleteScenario(scenario.id);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('시나리오가 삭제되었습니다')),
        );
      }
    }
  }
}
