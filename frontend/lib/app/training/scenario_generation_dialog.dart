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
    'PARENT': '부모',
    'FRIEND': '친구',
    'PARTNER': '파트너',
    'HUSBAND': '남편',
    'WIFE': '아내',
  };

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  void _generateScenario() {
    if (_selectedTarget == null || _topicController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('관계 대상과 주제를 모두 입력해주세요')),
      );
      return;
    }

    Navigator.of(context).pop({
      'target': _selectedTarget,
      'topic': _topicController.text.trim(),
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
    );
  }
}

