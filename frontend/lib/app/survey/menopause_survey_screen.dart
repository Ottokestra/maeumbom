import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Lottie 사용 시 import 추가
import 'package:lottie/lottie.dart'; 

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
    // 뷰모델이 생성될 때 자동으로 프로필을 조회하고 질문을 불러옵니다.
    // 별도의 호출이 필요 없습니다.
  }

  // =======================================================
  // 🐛 오류 해결: _getCharacterAsset 메서드 추가
  // =======================================================
  String _getCharacterAsset(String? characterKey) {
    if (characterKey == null || characterKey.isEmpty) {
      // 캐릭터 키가 없을 경우, 기본 애니메이션 (Lottie JSON) 경로 반환
      return 'assets/characters/animation/basic/default.json'; 
    }

    // 백엔드에서 받은 characterKey를 실제 Lottie 애니메이션 경로로 매핑
    // (이 경로는 프로젝트의 assets/characters/animation 폴더 구조와 일치해야 합니다)
    switch (characterKey.toUpperCase()) {
      case 'PEACH_WORRY':
        return 'assets/characters/animation/sadness/peach_worry.json';
      case 'PEACH_CALM':
        return 'assets/characters/animation/basic/peach_calm.json';
      case 'PEACH_TIRED':
        return 'assets/characters/animation/basic/peach_tired.json';
      case 'PEACH_HEAT':
        return 'assets/characters/animation/basic/peach_heat.json';
      case 'PEACH_ANXIOUS':
        return 'assets/characters/animation/sadness/peach_anxious.json';
      case 'FIRE_FOCUS':
        return 'assets/characters/animation/basic/fire_focus.json';
      // MALE_CHARACTER_KEYS 예시
      case 'FIRE_ANGRY':
        return 'assets/characters/animation/anger/fire_angry.json';
      case 'FIRE_STRESS':
        return 'assets/characters/animation/sadness/fire_stress.json';
        
      default:
        // 정의되지 않은 키에 대한 기본값 (혹은 에러 애니메이션)
        return 'assets/characters/animation/basic/default.json'; 
    }
  }
  // =======================================================


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
      // 답변 시 다음 페이지로 이동
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // 마지막 질문 답변 시 설문 제출
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

    return AppFrame(
      topBar: TopBar(
        title: '',
        leftIcon: Icons.arrow_back,
        onTapLeft: () {
          if (_currentPage > 0) {
            _pageController.previousPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          } else {
            Navigator.pop(context);
          }
        },
        rightIcon: Icons.close,
        onTapRight: () => Navigator.pop(context),
      ),
      body: Stack(
        children: [
          state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    // Header Frame (Compact)
                    Container(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '지금 내 몸 상태,\n가볍게 체크해볼까요?',
                            style: TextStyle(
                              color: Color(0xFF243447),
                              fontSize: 26,
                              fontFamily: 'Inter',
                              height: 1.2,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '아래 문항에 예/아니오로만 응답해 주세요.\n결과는 진단이 아니라, 내 몸과 마음의 변화를 돌아보는 참고 정보로만 사용돼요.',
                            style: TextStyle(
                              color: Color(0xFF6B6B6B),
                              fontSize: 14,
                              fontFamily: 'Inter',
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Question PageView
                    Expanded(
                      child: GestureDetector(
                        onHorizontalDragEnd: (details) {
                          if (details.primaryVelocity == null) return;

                          // Swipe Left (Next)
                          if (details.primaryVelocity! < 0) {
                            final currentQuestion = questions[_currentPage];
                            // 답변을 선택하지 않았으면 경고 표시
                            if (ref.read(menopauseSurveyViewModelProvider.notifier).getAnswer(currentQuestion.id) == null) {
                              _showWarningToast();
                            } else {
                              if (_currentPage < questions.length - 1) {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              }
                            }
                          }
                          // Swipe Right (Back)
                          else if (details.primaryVelocity! > 0) {
                            if (_currentPage > 0) {
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            } else {
                              Navigator.pop(context);
                            }
                          }
                        },
                        child: PageView.builder(
                          controller: _pageController,
                          // 답변을 강제하기 위해 스크롤 막음
                          physics: const NeverScrollableScrollPhysics(), 
                          onPageChanged: (index) {
                            setState(() {
                              _currentPage = index;
                            });
                          },
                          itemCount: questions.length,
                          itemBuilder: (context, index) {
                            final question = questions[index];
                            final selectedValue = state.answers[question.id];

                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Progress
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      '${index + 1} / ${questions.length}',
                                      style: const TextStyle(
                                        color: Color(0xFF233446),
                                        fontSize: 16,
                                        fontFamily: 'Pretendard',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Progress Bar
                                  Stack(
                                    children: [
                                      Container(
                                        width: double.infinity,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF0EAE8),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                      FractionallySizedBox(
                                        widthFactor: (index + 1) / questions.length,
                                        child: Container(
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFD7454D),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 20),

                                  // Character Image (Lottie 사용)
                                  if (question.characterKey != null) ...[
                                    // Image.asset 대신 Lottie.asset 사용 가정
                                    Lottie.asset(
                                      _getCharacterAsset(question.characterKey),
                                      height: 120,
                                      fit: BoxFit.contain,
                                    ),
                                    const SizedBox(height: 24),
                                  ],

                                  // Question Text (Flexible to avoid overflow)
                                  Flexible(
                                    child: SingleChildScrollView(
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.05),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          children: [
                                            Text(
                                              question.questionText,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                color: Color(0xFF243447),
                                                fontSize: 20,
                                                fontFamily: 'Inter',
                                                fontWeight: FontWeight.w600,
                                                height: 1.3,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 24),

                                  // Answer Buttons
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildAnswerButton(
                                          text: question.positiveLabel,
                                          isSelected: selectedValue == 1,
                                          onTap: () => _onAnswer(question.id, 1),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _buildAnswerButton(
                                          text: question.negativeLabel,
                                          isSelected: selectedValue == 0,
                                          onTap: () => _onAnswer(question.id, 0),
                                        ),
                                      ),
                                    ],
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
    );
  }

  Widget _buildAnswerButton({
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD7454D) : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: const Color(0xFFD7454D),
            width: isSelected ? 0 : 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFD7454D).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFFD7454D),
            fontSize: 16,
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}