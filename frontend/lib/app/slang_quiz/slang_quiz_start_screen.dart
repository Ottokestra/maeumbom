import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ui/app_ui.dart';
import '../../providers/daily_mood_provider.dart';

class SlangQuizStartScreen extends ConsumerStatefulWidget {
  const SlangQuizStartScreen({super.key});

  @override
  ConsumerState<SlangQuizStartScreen> createState() => _SlangQuizStartScreenState();
}

class _SlangQuizStartScreenState extends ConsumerState<SlangQuizStartScreen> {
  String _selectedLevel = 'beginner';
  String _selectedQuizType = 'word_to_meaning';
  int _tapCount = 0;

  void _onCharacterTap() {
    setState(() {
      _tapCount++;
    });

    if (_tapCount >= 5) {
      // 5번 탭하면 관리자 화면으로 이동
      Navigator.pushNamed(context, '/training/slang-quiz/admin');
      setState(() {
        _tapCount = 0;
      });
    }

    // 3초 후 카운트 리셋
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _tapCount = 0;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final dailyState = ref.watch(dailyMoodProvider);
    final currentEmotion = dailyState.selectedEmotion ?? EmotionId.joy;

    return AppFrame(
      topBar: TopBar(
        title: '글자 빨리 누르기',
        leftIcon: Icons.arrow_back,
        onTapLeft: () => Navigator.pop(context),
        rightIcon: Icons.settings,
        onTapRight: () {
          Navigator.pushNamed(context, '/training/slang-quiz/admin');
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 상단 여백
            const SizedBox(height: AppSpacing.xl),
            
            // 캐릭터 (5번 탭하면 관리자 화면)
            Expanded(
              child: Center(
                child: GestureDetector(
                  onTap: _onCharacterTap,
                  child: EmotionCharacter(
                    id: currentEmotion,
                    use2d: true,
                    size: 240,
                  ),
                ),
              ),
            ),
            
            // 하단 컨텐츠
            Column(
              children: [
                // 안내 텍스트
                const Text(
                  '지금 시작해 볼까요?',
                  style: AppTypography.h2,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '아래 게임 시작 버튼을 눌러 주세요',
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                
                // 난이도 선택
                _buildSettingRow(
                  label: '난이도',
                  child: _buildLevelSelector(),
                ),
                const SizedBox(height: AppSpacing.sm),
                
                // 퀴즈 타입 선택
                _buildSettingRow(
                  label: '퀴즈 타입',
                  child: _buildQuizTypeSelector(),
                ),
                const SizedBox(height: AppSpacing.xl),
                
                // 게임 시작 버튼
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    text: '게임 시작',
                    variant: ButtonVariant.primaryRed,
                    onTap: _startGame,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingRow({required String label, required Widget child}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodyBold,
        ),
        child,
      ],
    );
  }

  Widget _buildLevelSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.bgBasic,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: DropdownButton<String>(
        value: _selectedLevel,
        underline: const SizedBox(),
        items: const [
          DropdownMenuItem(value: 'beginner', child: Text('초급')),
          DropdownMenuItem(value: 'intermediate', child: Text('중급')),
          DropdownMenuItem(value: 'advanced', child: Text('고급')),
        ],
        onChanged: (value) {
          if (value != null) {
            setState(() => _selectedLevel = value);
          }
        },
      ),
    );
  }

  Widget _buildQuizTypeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.bgBasic,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: DropdownButton<String>(
        value: _selectedQuizType,
        underline: const SizedBox(),
        items: const [
          DropdownMenuItem(
            value: 'word_to_meaning',
            child: Text('단어 → 뜻'),
          ),
          DropdownMenuItem(
            value: 'meaning_to_word',
            child: Text('뜻 → 단어'),
          ),
        ],
        onChanged: (value) {
          if (value != null) {
            setState(() => _selectedQuizType = value);
          }
        },
      ),
    );
  }

  void _startGame() {
    Navigator.pushNamed(
      context,
      '/training/slang-quiz/game',
      arguments: {
        'level': _selectedLevel,
        'quizType': _selectedQuizType,
      },
    );
  }
}

