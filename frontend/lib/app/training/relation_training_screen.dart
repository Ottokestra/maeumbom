import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ui/app_ui.dart';
import 'viewmodel/relation_training_viewmodel.dart';
import '../../data/models/training/relation_training.dart';
import '../../core/config/api_config.dart';
import '../../core/utils/text_formatter.dart';
import 'relation_training_list_screen.dart';
import 'training_ending_screen.dart';
import '../../core/services/navigation/navigation_service.dart';

class RelationTrainingScreen extends ConsumerStatefulWidget {
  final int scenarioId;

  const RelationTrainingScreen({
    super.key,
    required this.scenarioId,
  });

  @override
  ConsumerState<RelationTrainingScreen> createState() =>
      _RelationTrainingScreenState();
}

class _RelationTrainingScreenState
    extends ConsumerState<RelationTrainingScreen> {
  String? _selectedOptionCode;

  // 선택지 개수에 따른 감정 ID 패턴 반환
  List<EmotionId> _getEmotionIdsForOptions(int count) {
    // 기본 패턴: relief(파랑), joy(노랑), love(핑크), interest(보라), confidence(골드)
    const pattern = [
      EmotionId.relief,
      EmotionId.joy,
      EmotionId.love,
      EmotionId.interest,
      EmotionId.confidence
    ];
    return pattern.take(count).toList();
  }

  // 트레이닝 텍스트를 RichText로 변환 (볼드 처리 포함)
  Widget _buildTrainingText(String text, TextStyle baseStyle,
      {TextAlign textAlign = TextAlign.center}) {
    final formattedText = TextFormatter.formatTrainingText(text);
    final spans = <TextSpan>[];

    // **볼드** 패턴을 찾아서 TextSpan으로 분리
    final regex = RegExp(r'\*\*([^\*]+?)\*\*');
    int lastIndex = 0;

    for (final match in regex.allMatches(formattedText)) {
      // 볼드 이전의 일반 텍스트
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: formattedText.substring(lastIndex, match.start),
          style: baseStyle,
        ));
      }

      // 볼드 텍스트
      spans.add(TextSpan(
        text: match.group(1),
        style: baseStyle.copyWith(fontWeight: FontWeight.w700),
      ));

      lastIndex = match.end;
    }

    // 남은 텍스트
    if (lastIndex < formattedText.length) {
      spans.add(TextSpan(
        text: formattedText.substring(lastIndex),
        style: baseStyle,
      ));
    }

    return RichText(
      textAlign: textAlign,
      text: TextSpan(children: spans),
    );
  }

  Future<void> _handleBack() async {
    final viewModel =
        ref.read(relationTrainingViewModelProvider(widget.scenarioId).notifier);
    final wentBack = viewModel.navigateBack();
    if (!wentBack) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      } else {
        // Fallback to List Screen
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => const RelationTrainingListScreen()));
      }
    }
  }

  void _handleExit() {
    // 트레이닝 목록 화면으로 돌아가기 (히스토리 무시하고 종료)
    // 탭 네비게이션을 사용하여 전체 네비게이션 스택을 정리하고 트레이닝 메인으로 이동
    NavigationService(context, ref).navigateToTab(3);
  }

  Widget _buildImageError() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
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
    final stateAsync =
        ref.watch(relationTrainingViewModelProvider(widget.scenarioId));

    // Navigation logic for completion
    ref.listen(relationTrainingViewModelProvider(widget.scenarioId), (previous, next) {
      if (next.asData?.value.isFinished == true && next.asData?.value.result != null) {
        final result = next.asData!.value.result!;
        // Go to Ending Screen
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => RelationTrainingEndingScreen(
                    result: result,
                )
            )
        );
      }
    });

    return WillPopScope(
      onWillPop: () async {
        await _handleBack();
        return false;
      },
      child: AppFrame(
        backgroundColor: AppColors.bgBasic,
        useSafeArea: false,
        topBar: TopBar(
          title: '',
          leftIcon: Icons.arrow_back,
          onTapLeft: _handleBack,
          rightIcon: Icons.close,
          onTapRight: _handleExit,
          backgroundColor: AppColors.bgBasic,
        ),
        body: stateAsync.when(
          data: (state) {
            // Note: Result view is now handled via navigation listener above.
            // We only render scenario while active.
            
            if (state.currentNode == null) {
               // If finished but waiting for navigation or empty
               if (state.isFinished) return const Center(child: CircularProgressIndicator());
               return const Center(child: Text('시나리오를 불러올 수 없습니다.'));
            }

            return _buildScenarioView(state.currentNode!, state);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }

  // _buildScenarioView가 state 객체를 인수로 받도록 수정합니다.
  Widget _buildScenarioView(ScenarioNode node, RelationTrainingState state) {
    return QuestionProgressView(
      currentStep: node.stepLevel - 1,
      totalSteps: 5, // TODO: Get actual total steps from API
      questionNumber: 'STEP${node.stepLevel}.',
      enableToggle: true,
      initiallyExpanded: false,
      toggleTitle: "문항 보기",
      enableAnimation: true,
      questionText: TextFormatter.formatTrainingText(node.situationText),
      questionTextStyle: AppTypography.bodyLarge.copyWith(
        height: 1.4,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF243447),
      ),
      // titleWidget removed to use questionText with typing effect
      media: Column(
        children: [
          // 1. Header Image
          if (state.scenarioImage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: SizedBox(
                height: 250,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Builder(
                    builder: (context) {
                      final imageUrl = state.scenarioImage!;
                      // Check if it is a local asset path (compatability)
                      if (imageUrl.startsWith('assets/')) {
                        return Image.asset(
                          imageUrl,
                          fit: BoxFit.cover,
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
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildImageError(),
                      );
                    },
                  ),
                ),
              ),
            ),

          if (node.imageUrl != null && node.imageUrl!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  node.imageUrl!,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 150,
                      color: Colors.grey[100],
                      alignment: Alignment.center,
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        color: AppColors.primaryColor,
                      ),
                    );
                  },
                  errorBuilder: (ctx, err, stack) {
                    // 404 등 이미지 로드 실패 시 표시
                    return Container(
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_not_supported_outlined,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '이미지를 불러올 수 없습니다',
                            style: AppTypography.caption.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
      content: ChoiceButtonGroup(
        choices: node.options
            .map((e) => TextFormatter.formatTrainingText(e.optionText))
            .toList(),
        selectedIndex:
            node.options.indexWhere((e) => e.optionCode == _selectedOptionCode),
        layout: ChoiceLayout.vertical,
        mode: ChoiceButtonMode.color, // 컬러 모드 적용
        emotionIds: _getEmotionIdsForOptions(node.options.length),
        showBorder: true,
        showNumber: true,
        onChoiceSelected: (index, choice) {
          if (_selectedOptionCode != null) return;

          final option = node.options[index];

          setState(() {
            _selectedOptionCode = option.optionCode;
          });

          Future.delayed(const Duration(milliseconds: 200), () {
            ref
                .read(relationTrainingViewModelProvider(widget.scenarioId)
                    .notifier)
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
    );
  }
}
