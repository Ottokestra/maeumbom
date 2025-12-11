import 'package:flutter/material.dart';
import '../../ui/app_ui.dart';

class ScenarioGenerationDialog extends StatefulWidget {
  const ScenarioGenerationDialog({super.key});

  @override
  State<ScenarioGenerationDialog> createState() => _ScenarioGenerationDialogState();
}

class _ScenarioGenerationDialogState extends State<ScenarioGenerationDialog> {
  String? _selectedTarget;
  String _selectedCategory = 'TRAINING'; // 기본값: 관계 개선 훈련
  String? _selectedGenre; // 드라마 선택 시 장르
  bool _isAutoTopic = false; // AI 자동 주제 창작 체크박스 상태
  final TextEditingController _topicController = TextEditingController();
  bool _isGenerating = false;

  final Map<String, String> _targetOptions = {
    'HUSBAND': '남편',
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

  void _generateScenario() {
    // 이미 처리 중이면 무시
    if (_isGenerating) {
      return;
    }
    
    // AUTO 옵션 체크
    final isAutoTarget = _selectedTarget == 'AUTO';
    final isAutoTopic = _isAutoTopic;
    
    // 검증 로직: AUTO가 아닌 경우에만 필수 입력 검증
    if (!isAutoTarget && _selectedTarget == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('관계 대상을 선택해주세요')),
      );
      return;
    }
    
    if (!isAutoTopic && _topicController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('주제를 입력해주세요')),
      );
      return;
    }

    // 드라마 선택 시 장르 필수
    if (_selectedCategory == 'DRAMA' && _selectedGenre == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('드라마 장르를 선택해주세요')),
      );
      return;
    }

    // mounted 체크 및 상태 설정
    if (!mounted) return;
    
    // 즉시 상태를 변경하여 중복 호출 방지
    setState(() {
      _isGenerating = true;
    });
    
    // 다음 프레임에서 pop 실행 (setState 완료 후)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      // AUTO 처리: target이 AUTO이면 그대로, topic은 AUTO 체크 시 "AUTO" 전송
      final target = _selectedTarget ?? 'AUTO';
      final topic = _isAutoTopic ? 'AUTO' : _topicController.text.trim();
      
      final result = <String, String>{
        'target': target,
        'topic': topic,
        'category': _selectedCategory,
      };
      
      // 드라마 선택 시 장르도 전달
      if (_selectedCategory == 'DRAMA' && _selectedGenre != null) {
        result['genre'] = _selectedGenre!;
      }
      
      Navigator.of(context).pop(result);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '시나리오 생성',
                  style: AppTypography.h2,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              '관계 대상',
              style: AppTypography.bodyBold,
            ),
            const SizedBox(height: 8),
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
                    selectedColor: AppColors.accentRed,
                    labelStyle: TextStyle(
                      color: _selectedTarget == 'AUTO' ? Colors.white : AppColors.textPrimary,
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
                    selectedColor: AppColors.accentRed,
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
            const SizedBox(height: 8),
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
                        _selectedTarget = _selectedTarget == 'AUTO' ? null : _selectedTarget;
                      }
                    });
                  },
                  selectedColor: AppColors.accentRed,
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
              const SizedBox(height: 8),
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
                    selectedColor: AppColors.accentRed,
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
            const SizedBox(height: 8),
            // AI 자동 창작 체크박스 (드라마 모드에서만 표시)
            if (_selectedCategory == 'DRAMA') ...[
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'AI가 알아서 주제 창작하기 (Auto)',
                  style: AppTypography.body,
                ),
                value: _isAutoTopic,
                onChanged: _isGenerating ? null : (value) {
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
              const SizedBox(height: 8),
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
              enabled: !_isGenerating && !(_selectedCategory == 'DRAMA' && _isAutoTopic),
            ),
            const SizedBox(height: 24),
            if (_isGenerating)
              const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    '시나리오를 생성하고 있습니다...\n약 20-30초 소요됩니다.',
                    textAlign: TextAlign.center,
                    style: AppTypography.caption,
                  ),
                ],
              )
            else
              AppButton(
                text: '생성하기',
                onTap: _generateScenario,
                variant: ButtonVariant.primaryRed,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

