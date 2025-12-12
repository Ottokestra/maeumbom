import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ui/app_ui.dart';
import '../../ui/components/buttons.dart';
import '../../ui/components/list_bubble.dart';
import 'relation_training_viewmodel.dart';
import '../../data/models/training/relation_training.dart';
import '../../core/config/api_config.dart';

// ViewModel의 상태 타입을 가져와야 하지만, 현재 코드에서는 알 수 없으므로 
// 임시로 dynamic으로 설정합니다. 실제 상태 클래스 이름으로 교체해야 합니다.
typedef RelationTrainingState = dynamic; 


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
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      } else {
        // Fallback to List Screen if history is empty (prevents black screen)
        Navigator.pushReplacementNamed(context, '/training');
      }
    }
  }

  // 💡 [수정 사항] _buildImageError 메서드를 정의하고, 
  // AppColors.backgroundSecondary 대신 Colors.grey[200]을 사용합니다.
  Widget _buildImageError() {
    return Container(
      height: 200, 
      decoration: BoxDecoration(
        // 오류 해결을 위해 AppColors.backgroundSecondary 대신 Colors.grey[200] 사용
        color: Colors.grey[200], 
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_not_supported, color: Colors.grey, size: 40),
          SizedBox(height: 8),
          Text('이미지를 불러올 수 없습니다.', style: AppTypography.body),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(relationTrainingViewModelProvider(widget.scenarioId));
    final state = stateAsync.asData?.value;
    final showResult = state?.isFinished == true && state?.result != null;

    return WillPopScope(
      onWillPop: () async {
        await _handleBack();
        return false;
      },
      child: AppFrame(
        topBar: TopBar(
          title: '마음연습실',
          leftIcon: Icons.arrow_back,
          onTapLeft: _handleBack,
        ),
        bottomBar: showResult
            ? BottomButtonBar(
                primaryText: '홈으로',
                onPrimaryTap: () => Navigator.pop(context),
              )
            : null,
        body: SafeArea(
          child: stateAsync.when(
            data: (state) {
              if (state.isFinished && state.result != null) {
                return _buildResultView(state.result!);
              }

              if (state.currentNode == null) {
                return const Center(child: Text('시나리오를 불러올 수 없습니다.'));
              }

              return _buildScenarioView(state.currentNode!, state);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
          ),
        ),
      ),
    );
  }

  // _buildScenarioView가 state 객체를 인수로 받도록 수정합니다.
  Widget _buildScenarioView(ScenarioNode node, RelationTrainingState state) {
    return Column(
      children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            alignment: Alignment.centerLeft,
            child: Text(
              'Step ${node.stepLevel}',
              style: AppTypography.bodyBold.copyWith(color: AppColors.textSecondary),
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                    // Dynamic Header Image
                    if (state.scenarioImage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Builder(
                            builder: (context) {
                              final imageUrl = state.scenarioImage!;
                              // Check if it is a local asset path (compatability)
                              if (imageUrl.startsWith('assets/')) {
                                return Image.asset(
                                  imageUrl,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      _buildImageError(), 
                                );
                              }
                              // Network image - prepend baseUrl if relative path
                              final fullUrl = imageUrl.startsWith('http')
                                  ? imageUrl
                                  : '${ApiConfig.baseUrl}$imageUrl';

                              return Image.network(
                                fullUrl,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildImageError(), 
                              );
                            },
                          ),
                        ),
                      ),

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
                      style: AppTypography.h3.copyWith(height: 1.4),
                    ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: ListBubble(
                items: node.options.map((e) => e.optionText).toList(),
                selectedIndex: node.options.indexWhere((e) => e.optionCode == _selectedOptionCode),
                onItemSelected: (index, item) {
                  if (_selectedOptionCode != null) return;
                  
                  final option = node.options[index];
                  
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
              ),
          ),
      ],
    );
  }

  Widget _buildResultView(ScenarioResult result) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          // mainAxisAlignment: MainAxisAlignment.center, // ScrollView 내에서는 top alignment가 자연스러움
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
            // Button moved to BottomButtonBar
          ],
        ),
      ),
    );
  }
}