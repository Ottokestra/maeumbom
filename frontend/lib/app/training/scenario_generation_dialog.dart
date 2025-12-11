import 'package:flutter/material.dart';
import '../../ui/app_ui.dart';

class ScenarioGenerationDialog extends StatefulWidget {
  const ScenarioGenerationDialog({super.key});

  @override
  State<ScenarioGenerationDialog> createState() => _ScenarioGenerationDialogState();
}

class _ScenarioGenerationDialogState extends State<ScenarioGenerationDialog> {
  String? _selectedTarget;
  final TextEditingController _topicController = TextEditingController();
  bool _isGenerating = false;

  final Map<String, String> _targetOptions = {
    'HUSBAND': '남편',
    'CHILD': '자식',
    'FRIEND': '친구',
    'COLLEAGUE': '직장동료',
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
    
    if (_selectedTarget == null || _topicController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('관계 대상과 주제를 모두 입력해주세요')),
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
      
      final target = _selectedTarget!;
      final topic = _topicController.text.trim();
      
      Navigator.of(context).pop(<String, String>{
        'target': target,
        'topic': topic,
      });
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
              children: _targetOptions.entries.map((entry) {
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
            ),
            const SizedBox(height: 24),
            const Text(
              '주제',
              style: AppTypography.bodyBold,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _topicController,
              decoration: InputDecoration(
                hintText: '예: 남편이 밥투정을 합니다',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppColors.bgWarm,
              ),
              maxLines: 3,
              enabled: !_isGenerating,
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

