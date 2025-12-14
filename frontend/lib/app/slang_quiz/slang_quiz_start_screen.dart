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
      backgroundColor: AppColors.bgBasic,
      topBar: TopBar(
        title: '신조어 퀴즈',
        leftIcon: Icons.arrow_back,
        onTapLeft: () => Navigator.pop(context),
        rightIcon: Icons.settings,
        onTapRight: () {
          Navigator.pushNamed(context, '/training/slang-quiz/admin');
        },
      ),
      bottomBar: BottomButtonBar(
        primaryText: '시작하기',
        onPrimaryTap: () => Navigator.pushNamed(
          context,
          '/training/slang-quiz/game',
          arguments: {
            'level': _selectedLevel,
            'quizType': _selectedQuizType,
          },
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  // 메인 화이트 카드 (캐릭터 + 안내 텍스트)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xl,
                      horizontal: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.pureWhite,
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: Column(
                      children: [
                        // 안내 텍스트
                        const Text(
                          '지금 시작해 볼까요?',
                          style: AppTypography.h3,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: AppTypography.body.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            children: [
                              const TextSpan(text: '아래 '),
                              TextSpan(
                                text: '게임 시작',
                                style: AppTypography.bodyBold.copyWith(
                                  color: AppColors.errorRed,
                                ),
                              ),
                              const TextSpan(text: ' 버튼을 눌러 주세요!'),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: AppSpacing.lg),
                        
                        // 캐릭터
                        GestureDetector(
                          onTap: _onCharacterTap,
                          child: EmotionCharacter(
                            id: currentEmotion,
                            use2d: true,
                            size: 180,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: AppSpacing.lg),
                  
                  // 난이도 선택
                  _buildSelectionCard(
                    title: '난이도',
                    value: _getLevelLabel(_selectedLevel),
                    gradientColors: [
                      const Color(0xFFF0F9FF),
                      const Color(0xFFE0F2FE),
                    ],
                    iconColor: const Color(0xFF4A9DFF),
                    textColor: const Color(0xFF4A9DFF),
                    onTap: _showLevelSelectionSheet,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  
                  // 퀴즈 타입 선택
                  _buildSelectionCard(
                    title: '퀴즈 타입',
                    value: _getQuizTypeLabel(_selectedQuizType),
                    gradientColors: [
                      const Color(0xFFF4E6FF),
                      const Color(0xFFFCE8FF),
                    ],
                    iconColor: const Color(0xFF9B6DD6),
                    textColor: const Color(0xFF9B6DD6),
                    onTap: _showQuizTypeSelectionSheet,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionCard({
    required String title,
    required String value,
    required List<Color> gradientColors,
    required Color iconColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: const Alignment(0.50, 0.00),
            end: const Alignment(0.50, 1.00),
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 왼쪽 아이콘 + 타이틀
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  title,
                  style: AppTypography.bodyBold.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            
            // 오른쪽 값 표시
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: AppTypography.bodyBold.copyWith(
                      color: textColor,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: textColor.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getLevelLabel(String level) {
    switch (level) {
      case 'beginner':
        return '초급';
      case 'intermediate':
        return '중급';
      case 'advanced':
        return '고급';
      default:
        return '초급';
    }
  }

  String _getQuizTypeLabel(String type) {
    switch (type) {
      case 'word_to_meaning':
        return '무슨 뜻인지 알아봄';
      case 'meaning_to_word':
        return '어떤 말인지 맞춰봄';
      default:
        return '무슨 뜻인지 알아봄';
    }
  }

  void _showLevelSelectionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '난이도 선택',
              style: AppTypography.h3,
            ),
            const SizedBox(height: 24),
            _buildBottomSheetItem('초급', 'beginner', _selectedLevel, (val) {
              setState(() => _selectedLevel = val);
              Navigator.pop(context);
            }),
            _buildBottomSheetItem('중급', 'intermediate', _selectedLevel, (val) {
              setState(() => _selectedLevel = val);
              Navigator.pop(context);
            }),
            _buildBottomSheetItem('고급', 'advanced', _selectedLevel, (val) {
              setState(() => _selectedLevel = val);
              Navigator.pop(context);
            }),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showQuizTypeSelectionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '퀴즈 타입 선택',
              style: AppTypography.h3,
            ),
            const SizedBox(height: 24),
            _buildBottomSheetItem(
                '무슨 뜻인지 알아봄', 'word_to_meaning', _selectedQuizType, (val) {
              setState(() => _selectedQuizType = val);
              Navigator.pop(context);
            }),
            _buildBottomSheetItem(
                '어떤 말인지 맞춰봄', 'meaning_to_word', _selectedQuizType, (val) {
              setState(() => _selectedQuizType = val);
              Navigator.pop(context);
            }),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSheetItem(
      String label, String value, String selectedValue, Function(String) onTap) {
    final isSelected = value == selectedValue;
    return InkWell(
      onTap: () => onTap(value),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        color: isSelected ? AppColors.bgBasic : Colors.transparent,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: isSelected
                  ? AppTypography.bodyBold.copyWith(color: AppColors.primaryColor)
                  : AppTypography.body,
            ),
            if (isSelected)
              const Icon(Icons.check, color: AppColors.primaryColor),
          ],
        ),
      ),
    );
  }
}

