import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ui/app_ui.dart';
import '../../ui/components/top_notification.dart';
import 'viewmodel/relation_training_list_viewmodel.dart';

/// 시나리오 생성 화면
///
/// 관계 개선 훈련 또는 드라마 시나리오를 생성하는 화면
class ScenarioGenerationScreen extends ConsumerStatefulWidget {
  const ScenarioGenerationScreen({super.key});

  @override
  ConsumerState<ScenarioGenerationScreen> createState() =>
      _ScenarioGenerationScreenState();
}

class _ScenarioGenerationScreenState
    extends ConsumerState<ScenarioGenerationScreen> {
  String? _selectedTarget;
  String _selectedCategory = 'TRAINING'; // 기본값: 관계 개선 훈련
  String? _selectedGenre; // 드라마 선택 시 장르
  bool _isAutoTopic = false; // AI 자동 주제 창작 체크박스 상태
  final TextEditingController _topicController = TextEditingController();
  bool _isGenerating = false;

  final Map<String, String> _targetOptions = {
    'HUSBAND': '배우자',
    'PARENT': '부모',
    'CHILD': '자식',
    'FRIEND': '친구',
    'COLLEAGUE': '직장동료',
  };

  final Map<String, String> _categoryOptions = {
    'TRAINING': '관계 개선 훈련',
    'DRAMA': '드라마',
  };

  final Map<String, String> _genreOptions = {
    'MAKJANG': '막장',
    'ROMANCE': '로맨스',
    'FAMILY': '가족',
  };

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  Future<void> _generateScenario() async {
    // 이미 처리 중이면 무시
    if (_isGenerating) {
      return;
    }

    // AUTO 옵션 체크
    final isAutoTarget = _selectedTarget == 'AUTO';
    final isAutoTopic = _isAutoTopic;

    // 검증 로직: AUTO가 아닌 경우에만 필수 입력 검증
    if (!isAutoTarget && _selectedTarget == null) {
      TopNotificationManager.show(
        context,
        message: '관계 대상을 선택해주세요',
        type: TopNotificationType.red,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    if (!isAutoTopic && _topicController.text.trim().isEmpty) {
      TopNotificationManager.show(
        context,
        message: '주제를 입력해주세요',
        type: TopNotificationType.red,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    // 드라마 선택 시 장르 필수
    if (_selectedCategory == 'DRAMA' && _selectedGenre == null) {
      TopNotificationManager.show(
        context,
        message: '드라마 장르를 선택해주세요',
        type: TopNotificationType.red,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    // mounted 체크 및 상태 설정
    if (!mounted) return;

    setState(() {
      _isGenerating = true;
    });

    try {
      final viewModel =
          ref.read(relationTrainingListViewModelProvider.notifier);

      // AUTO 처리: target이 AUTO이면 그대로, topic은 AUTO 체크 시 "AUTO" 전송
      final target = _selectedTarget ?? 'AUTO';
      final topic = _isAutoTopic ? 'AUTO' : _topicController.text.trim();

      // 시나리오 생성
      await viewModel.generateScenario(
        target: target,
        topic: topic,
        category: _selectedCategory,
        genre: _selectedGenre,
      );

      if (!mounted) return;

      // 성공 메시지 표시
      TopNotificationManager.show(
        context,
        message: '시나리오 생성이 완료되었습니다!',
        type: TopNotificationType.green,
        duration: const Duration(seconds: 3),
      );

      // 이전 화면으로 돌아가기
      Navigator.of(context).pop(true); // true를 반환하여 새로고침 필요 알림
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isGenerating = false;
      });

      TopNotificationManager.show(
        context,
        message: '오류 발생: $e',
        type: TopNotificationType.red,
        duration: const Duration(seconds: 5),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppFrame(
      topBar: TopBar(
        title: '시나리오 생성',
        leftIcon: Icons.arrow_back,
        onTapLeft: () => Navigator.pop(context),
      ),
      bottomBar: _isGenerating
          ? null
          : BottomButtonBar(
              primaryText: '생성하기',
              onPrimaryTap: _generateScenario,
            ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '관계 대상',
              style: AppTypography.bodyBold,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // 랜덤 배역 버튼 (드라마 모드에서만 표시)
                if (_selectedCategory == 'DRAMA')
                  ChoiceChip(
                    label: const Text('🎲 랜덤 배역'),
                    selected: _selectedTarget == 'AUTO',
                    onSelected: (selected) {
                      setState(() {
                        _selectedTarget = selected ? 'AUTO' : null;
                      });
                    },
                    selectedColor: AppColors.primaryColor,
                    labelStyle: TextStyle(
                      color: _selectedTarget == 'AUTO'
                          ? Colors.white
                          : AppColors.textPrimary,
                    ),
                  ),
                // 기존 관계 대상 버튼들
                ..._targetOptions.entries.map((entry) {
                  final isSelected = _selectedTarget == entry.key;
                  return ChoiceChip(
                    label: Text(entry.value),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedTarget = selected ? entry.key : null;
                      });
                    },
                    selectedColor: AppColors.primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  );
                }).toList(),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              '카테고리',
              style: AppTypography.bodyBold,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categoryOptions.entries.map((entry) {
                final isSelected = _selectedCategory == entry.key;
                return ChoiceChip(
                  label: Text(entry.value),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = entry.key;
                      // 카테고리 변경 시 AUTO 상태 초기화
                      if (entry.key != 'DRAMA') {
                        _isAutoTopic = false;
                        _selectedTarget =
                            _selectedTarget == 'AUTO' ? null : _selectedTarget;
                      }
                    });
                  },
                  selectedColor: AppColors.primaryColor,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                );
              }).toList(),
            ),
            // 드라마 선택 시에만 장르 선택 표시
            if (_selectedCategory == 'DRAMA') ...[
              const SizedBox(height: 24),
              const Text(
                '장르',
                style: AppTypography.bodyBold,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _genreOptions.entries.map((entry) {
                  final isSelected = _selectedGenre == entry.key;
                  return ChoiceChip(
                    label: Text(entry.value),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedGenre = selected ? entry.key : null;
                      });
                    },
                    selectedColor: AppColors.primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 24),
            const Text(
              '주제',
              style: AppTypography.bodyBold,
            ),
            const SizedBox(height: 12),
            // AI 자동 창작 체크박스 (드라마 모드에서만 표시)
            if (_selectedCategory == 'DRAMA') ...[
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'AI가 알아서 주제 창작하기 (Auto)',
                  style: AppTypography.body,
                ),
                value: _isAutoTopic,
                onChanged: _isGenerating
                    ? null
                    : (value) {
                        setState(() {
                          _isAutoTopic = value ?? false;
                          if (_isAutoTopic) {
                            // 자동 창작 선택 시 입력창 비우기
                            _topicController.clear();
                          }
                        });
                      },
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _topicController,
              decoration: InputDecoration(
                hintText: (_selectedCategory == 'DRAMA' && _isAutoTopic)
                    ? 'AI가 장르에 맞춰 가장 재밌는 시나리오를 자동으로 작성합니다.'
                    : '예: 남편이 밥투정을 합니다',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: (_selectedCategory == 'DRAMA' && _isAutoTopic)
                    ? AppColors.bgWarm.withOpacity(0.5)
                    : AppColors.bgWarm,
              ),
              maxLines: 3,
              enabled: !_isGenerating &&
                  !(_selectedCategory == 'DRAMA' && _isAutoTopic),
            ),
            if (_isGenerating) ...[
              const SizedBox(height: 32),
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      '시나리오를 생성하고 있습니다...\n약 20-30초 소요됩니다.',
                      textAlign: TextAlign.center,
                      style: AppTypography.body,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
