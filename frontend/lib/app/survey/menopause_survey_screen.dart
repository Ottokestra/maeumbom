import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ui/app_ui.dart';
import '../../data/dtos/menopause/menopause_question_response.dart';
import 'menopause_survey_viewmodel.dart';
import 'menopause_diagnosis_result_screen.dart';
import '../../ui/components/system_bubble.dart';

class MenopauseSurveyScreen extends ConsumerStatefulWidget {
  const MenopauseSurveyScreen({super.key});

  @override
  ConsumerState<MenopauseSurveyScreen> createState() => _MenopauseSurveyScreenState();
}

class _MenopauseSurveyScreenState extends ConsumerState<MenopauseSurveyScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _showWarning = false;

  @override
  void initState() {
    super.initState();
  }

  // Map characterKey to EmotionId
  EmotionId _getEmotionId(String? characterKey) {
    if (characterKey == null || characterKey.isEmpty) {
      return EmotionId.confusion;
    }

    switch (characterKey.toUpperCase()) {
      case 'PEACH_WORRY':
      case 'PEACH_ANXIOUS':
      case 'FIRE_STRESS':
        return EmotionId.sadness;
      case 'PEACH_CALM':
        return EmotionId.relief;
      case 'PEACH_TIRED':
        return EmotionId.boredom;
      case 'PEACH_HEAT':
        return EmotionId.shame;
      case 'FIRE_FOCUS':
        return EmotionId.interest;
      case 'FIRE_ANGRY':
        return EmotionId.anger;
      default:
        return EmotionId.confusion;
    }
  }

  void _showWarningToast() {
    setState(() {
      _showWarning = true;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showWarning = false;
        });
      }
    });
  }

  void _onAnswer(int questionId, int value) {
    ref.read(menopauseSurveyViewModelProvider.notifier).setAnswer(questionId, value);

    final state = ref.read(menopauseSurveyViewModelProvider);
    if (_currentPage < state.questions.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _submitSurvey();
    }
  }

  Future<void> _submitSurvey() async {
    final result = await ref.read(menopauseSurveyViewModelProvider.notifier).submitSurvey();

    if (result != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MenopauseDiagnosisResultScreen(result: result),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(menopauseSurveyViewModelProvider);
    final questions = state.questions;

    if (state.isLoading && questions.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.error != null && questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('오류가 발생했습니다: ${state.error}')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.basicColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Main Content
            Column(
              children: [
                // Top Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back Button
                      GestureDetector(
                        onTap: () {
                          if (_currentPage > 0) {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          } else {
                            Navigator.pop(context);
                          }
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_back, size: 24),
                        ),
                      ),
                      // Close Button
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, size: 24),
                        ),
                      ),
                    ],
                  ),
                ),

                // PageView
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemCount: questions.length,
                    itemBuilder: (context, index) {
                      final question = questions[index];
                      final selectedValue = ref.read(menopauseSurveyViewModelProvider.notifier).getAnswer(question.id);

                      return QuestionProgressView(
                        currentStep: _currentPage,
                        totalSteps: questions.length,
                        questionNumber: 'Q${index + 1}.',
                        questionText: question.questionText,
                        enableToggle: false,
                        content: Column(
                          children: [
                            // 예 버튼
                            GestureDetector(
                              onTap: () => _onAnswer(question.id, 1),
                              child: Container(
                                width: double.infinity,
                                height: 68,
                                decoration: BoxDecoration(
                                  color: selectedValue == 1
                                      ? const Color(0xFFD7454D)
                                      : const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: selectedValue == 1
                                      ? [
                                          const BoxShadow(
                                            color: Color(0x19000000),
                                            blurRadius: 2,
                                            offset: Offset(0, 1),
                                            spreadRadius: -1,
                                          ),
                                          const BoxShadow(
                                            color: Color(0x19000000),
                                            blurRadius: 3,
                                            offset: Offset(0, 1),
                                            spreadRadius: 0,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Center(
                                  child: Text(
                                    question.positiveLabel,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: selectedValue == 1
                                          ? Colors.white
                                          : const Color(0xFF243447),
                                      fontSize: 18,
                                      fontFamily: 'Pretendard',
                                      fontWeight: FontWeight.w700,
                                      height: 1.56,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // 아니오 버튼
                            GestureDetector(
                              onTap: () => _onAnswer(question.id, 0),
                              child: Container(
                                width: double.infinity,
                                height: 68,
                                decoration: BoxDecoration(
                                  color: selectedValue == 0
                                      ? const Color(0xFFD7454D)
                                      : const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: selectedValue == 0
                                      ? [
                                          const BoxShadow(
                                            color: Color(0x19000000),
                                            blurRadius: 2,
                                            offset: Offset(0, 1),
                                            spreadRadius: -1,
                                          ),
                                          const BoxShadow(
                                            color: Color(0x19000000),
                                            blurRadius: 3,
                                            offset: Offset(0, 1),
                                            spreadRadius: 0,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Center(
                                  child: Text(
                                    question.negativeLabel,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: selectedValue == 0
                                          ? Colors.white
                                          : const Color(0xFF243447),
                                      fontSize: 18,
                                      fontFamily: 'Pretendard',
                                      fontWeight: FontWeight.w700,
                                      height: 1.56,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            // Warning Toast
            if (_showWarning)
              const Positioned(
                top: 24,
                left: 0,
                right: 0,
                child: SystemBubble(
                  text: '답변을 선택해주세요',
                  type: SystemBubbleType.warning,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
