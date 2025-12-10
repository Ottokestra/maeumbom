import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ui/app_ui.dart';
import '../../ui/components/buttons.dart'; // Import for ButtonVariant
import 'relation_training_viewmodel.dart';
import '../../data/models/training/relation_training.dart';

class RelationTrainingScreen extends ConsumerStatefulWidget {
  final int scenarioId;

  const RelationTrainingScreen({
    super.key,
    required this.scenarioId,
  });

  @override
  ConsumerState<RelationTrainingScreen> createState() => _RelationTrainingScreenState();
}

class _RelationTrainingScreenState extends ConsumerState<RelationTrainingScreen> {
  String? _selectedOptionCode;

  Future<void> _handleBack() async {
    final viewModel = ref.read(relationTrainingViewModelProvider(widget.scenarioId).notifier);
    final wentBack = viewModel.navigateBack();
    if (!wentBack) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(relationTrainingViewModelProvider(widget.scenarioId));

    return WillPopScope(
      onWillPop: () async {
        await _handleBack();
        return false;
      },
      child: AppFrame(
        topBar: TopBar(
          title: '관계 훈련',
          leftIcon: Icons.arrow_back,
          onTapLeft: _handleBack,
        ),
        body: stateAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('오류가 발생했습니다: $error')),
          data: (state) {
            if (state.isFinished && state.result != null) {
              return _buildResultView(state.result!);
            }
  
            if (state.currentNode == null) {
              return const Center(child: Text('시나리오를 불러올 수 없습니다.'));
            }
  
            return _buildScenarioView(state.currentNode!);
          },
        ),
      ),
    );
  }

  Widget _buildScenarioView(ScenarioNode node) {
    return Column(
      children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            alignment: Alignment.centerLeft,
            child: Text(
              'Step ${node.stepLevel}',
              style: AppTypography.h3.copyWith(color: AppColors.textSecondary),
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                   if (node.imageUrl != null && node.imageUrl!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          node.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => Container(
                            height: 200,
                            color: Colors.grey[200],
                            alignment: Alignment.center,
                            child: const Icon(Icons.image_not_supported, color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                  
                  Text(
                    node.situationText,
                    textAlign: TextAlign.center,
                    style: AppTypography.h2.copyWith(height: 1.4),
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: node.options.map((option) {
                final isSelected = _selectedOptionCode == option.optionCode;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppButton(
                    text: option.optionText,
                    onTap: () {
                      if (_selectedOptionCode != null) return;
                      
                      setState(() {
                         _selectedOptionCode = option.optionCode;
                      });

                      Future.delayed(const Duration(milliseconds: 200), () {
                        ref.read(relationTrainingViewModelProvider(widget.scenarioId).notifier)
                           .selectOption(option)
                           .then((_) {
                             if (mounted) {
                               setState(() {
                                 _selectedOptionCode = null;
                               });
                             }
                           });
                      });
                    },
                    variant: isSelected ? ButtonVariant.primaryRed : ButtonVariant.secondaryRed,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      );
  }

  Widget _buildResultView(ScenarioResult result) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
            Text(
              result.title,
              textAlign: TextAlign.center,
              style: AppTypography.h1, 
            ),
            const SizedBox(height: 32),
            if (result.resultImageUrl != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(result.resultImageUrl!),
                ),
              ),
            Text(
              result.resultText,
              textAlign: TextAlign.center,
              style: AppTypography.h3.copyWith(height: 1.5),
            ),
            const SizedBox(height: 48),
            AppButton(
              text: '홈으로',
              onTap: () => Navigator.pop(context),
              variant: ButtonVariant.primaryRed,
            ),
          ],
        ),
      );
  }
}
