import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../ui/app_ui.dart';
import '../../data/api/slang_quiz/slang_quiz_api_client.dart';

class SlangQuizAdminScreen extends ConsumerStatefulWidget {
  const SlangQuizAdminScreen({super.key});

  @override
  ConsumerState<SlangQuizAdminScreen> createState() => _SlangQuizAdminScreenState();
}

class _SlangQuizAdminScreenState extends ConsumerState<SlangQuizAdminScreen> {
  late SlangQuizApiClient _apiClient;
  
  String _selectedLevel = 'beginner';
  String _selectedQuizType = 'word_to_meaning';
  int _count = 5;
  bool _isGenerating = false;
  String? _resultMessage;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _apiClient = SlangQuizApiClient(Dio());
  }

  Future<void> _generateQuestions() async {
    setState(() {
      _isGenerating = true;
      _resultMessage = null;
    });

    try {
      final result = await _apiClient.generateQuestionsAdmin(
        level: _selectedLevel,
        quizType: _selectedQuizType,
        count: _count,
      );

      if (mounted) {
        setState(() {
          _isGenerating = false;
          _isSuccess = true;
          _resultMessage = '✅ ${result['count']}개 문제가 생성되었습니다!\n\n'
              '레벨: ${_getLevelName(_selectedLevel)}\n'
              '타입: ${_getTypeName(_selectedQuizType)}';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _isSuccess = false;
          _resultMessage = '❌ 문제 생성 실패\n\n$e';
        });
      }
    }
  }

  String _getLevelName(String level) {
    switch (level) {
      case 'beginner':
        return '초급';
      case 'intermediate':
        return '중급';
      case 'advanced':
        return '고급';
      default:
        return level;
    }
  }

  String _getTypeName(String type) {
    switch (type) {
      case 'word_to_meaning':
        return '단어 → 뜻';
      case 'meaning_to_word':
        return '뜻 → 단어';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppFrame(
      topBar: TopBar(
        title: '문제 생성 (개발용)',
        leftIcon: Icons.arrow_back,
        onTapLeft: () => Navigator.pop(context),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 안내 메시지
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.bgLightPink,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Text(
                '⚠️ 개발용 기능입니다\n\n'
                'OpenAI API를 사용하여 신조어 퀴즈 문제를 생성합니다.\n'
                '생성 시간: 약 10-30초 소요',
                style: AppTypography.body,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // 난이도 선택
            const Text('난이도', style: AppTypography.bodyBold),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.bgBasic,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: DropdownButton<String>(
                value: _selectedLevel,
                isExpanded: true,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'beginner', child: Text('초급')),
                  DropdownMenuItem(value: 'intermediate', child: Text('중급')),
                  DropdownMenuItem(value: 'advanced', child: Text('고급')),
                ],
                onChanged: _isGenerating ? null : (value) {
                  if (value != null) {
                    setState(() => _selectedLevel = value);
                  }
                },
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // 퀴즈 타입 선택
            const Text('퀴즈 타입', style: AppTypography.bodyBold),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.bgBasic,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: DropdownButton<String>(
                value: _selectedQuizType,
                isExpanded: true,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(
                    value: 'word_to_meaning',
                    child: Text('단어 → 뜻 (교육 중심)'),
                  ),
                  DropdownMenuItem(
                    value: 'meaning_to_word',
                    child: Text('뜻 → 단어 (말장난 오답)'),
                  ),
                ],
                onChanged: _isGenerating ? null : (value) {
                  if (value != null) {
                    setState(() => _selectedQuizType = value);
                  }
                },
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // 생성 개수
            const Text('생성 개수', style: AppTypography.bodyBold),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.bgBasic,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: DropdownButton<int>(
                value: _count,
                isExpanded: true,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 5, child: Text('5개 (테스트용)')),
                  DropdownMenuItem(value: 10, child: Text('10개')),
                  DropdownMenuItem(value: 20, child: Text('20개')),
                  DropdownMenuItem(value: 30, child: Text('30개')),
                ],
                onChanged: _isGenerating ? null : (value) {
                  if (value != null) {
                    setState(() => _count = value);
                  }
                },
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // 생성 버튼
            SizedBox(
              height: 56,
              child: AppButton(
                text: _isGenerating ? '생성 중...' : '문제 생성',
                variant: ButtonVariant.primaryRed,
                onTap: _isGenerating ? null : _generateQuestions,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // 로딩 인디케이터
            if (_isGenerating)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: AppSpacing.md),
                    Text(
                      'OpenAI API로 문제 생성 중...\n잠시만 기다려주세요',
                      style: AppTypography.body,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

            // 결과 메시지
            if (_resultMessage != null && !_isGenerating)
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: _isSuccess
                      ? AppColors.natureGreen.withOpacity(0.1)
                      : AppColors.errorRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: _isSuccess ? AppColors.natureGreen : AppColors.errorRed,
                  ),
                ),
                child: Text(
                  _resultMessage!,
                  style: AppTypography.body,
                ),
              ),

            const SizedBox(height: AppSpacing.xl),

            // 빠른 생성 가이드
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.bgWarm,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '💡 빠른 생성 가이드',
                    style: AppTypography.bodyBold,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    '모든 조합을 생성하려면:\n\n'
                    '1. beginner + word_to_meaning (5개)\n'
                    '2. beginner + meaning_to_word (5개)\n'
                    '3. intermediate + word_to_meaning (5개)\n'
                    '4. intermediate + meaning_to_word (5개)\n'
                    '5. advanced + word_to_meaning (5개)\n'
                    '6. advanced + meaning_to_word (5개)\n\n'
                    '총 30개 문제 생성 완료!',
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

