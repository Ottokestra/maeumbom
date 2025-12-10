import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../ui/app_ui.dart'; // AppColors, AppTypography
import '../../data/api/menopause/menopause_api_client.dart';
import '../../data/dtos/menopause/menopause_survey_request.dart';
import '../../core/config/api_config.dart';
import 'survey_question_model.dart';
import '../../ui/components/system_bubble.dart';
import 'package:frontend/ui/layout/app_frame.dart';


// AppFrame, TopBar가 정의된 파일이 명시되지 않아, 
// 일반적으로 사용되는 위치인 '../../ui/components/app_frame.dart'를 가정하고 import 추가

class MenopauseSurveyScreen extends StatefulWidget {
  const MenopauseSurveyScreen({super.key});

  @override
  State<MenopauseSurveyScreen> createState() => _MenopauseSurveyScreenState();
}

class _MenopauseSurveyScreenState extends State<MenopauseSurveyScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final Map<int, int> _answers = {}; // questionId -> answerValue (1: Yes, 0: No)
  bool _showWarning = false;

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

  void _onAnswer(int value) {
    setState(() {
      _answers[menopauseQuestions[_currentPage].id] = value;
    });

    if (_currentPage < menopauseQuestions.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _submitSurvey();
    }
  }

  Future<void> _submitSurvey() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));
      final client = MenopauseApiClient(dio);

      final request = MenopauseSurveyRequest(
        gender: MenopauseGender.female,
        answers: _answers.entries
            .map((e) => MenopauseAnswerItem(questionId: e.key, answerValue: e.value))
            .toList(),
      );

      final response = await client.submitSurvey(request);

      if (mounted) Navigator.pop(context); // Close loading

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('진단 결과'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('위험도: ${response.riskLevel}'),
                const SizedBox(height: 8),
                Text(response.comment ?? ''),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Close survey screen
                },
                child: const Text('확인'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류 발생: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ----------------------------------------------------------------------
    // 📌 [수정된 부분 A: 111줄 및 340줄 에러 해결]
    // 1. AppFrame( 뒤에 닫는 괄호 )가 없어서 발생한 문법 에러를 수정했습니다.
    // 2. body: Stack(...) 부분이 AppFrame 위젯의 인수로 들어가도록 위치를 조정했습니다.
    // 3. 마지막에 누락된 세미콜론 ; 를 추가했습니다.
    // ----------------------------------------------------------------------
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
          Column(
            children: [
              // Header Frame (Compact)
              Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 10), // Reduced top/bottom padding
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '지금 내 몸 상태,\n가볍게 체크해볼까요?',
                      style: TextStyle(
                        color: Color(0xFF243447),
                        fontSize: 26, // Reduced font size
                        fontFamily: 'Inter',
                        height: 1.2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12), // Reduced spacing
                    const Text(
                      '아래 문항에 예/아니오로만 응답해 주세요.\n결과는 진단이 아니라, 내 몸과 마음의 변화를 돌아보는 참고 정보로만 사용돼요.',
                      style: TextStyle(
                        color: Color(0xFF6B6B6B),
                        fontSize: 14, // Reduced font size
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
                      final currentQuestion = menopauseQuestions[_currentPage];
                      if (_answers[currentQuestion.id] == null) {
                        _showWarningToast();
                      } else {
                        if (_currentPage < menopauseQuestions.length - 1) {
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
                    physics: const NeverScrollableScrollPhysics(), 
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemCount: menopauseQuestions.length,
                    itemBuilder: (context, index) {
                      final question = menopauseQuestions[index];
                      final selectedValue = _answers[question.id];

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Progress
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '${index + 1} / ${menopauseQuestions.length}',
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
                                    // ---------------------------------------------
                                    // 📌 [잠재적 오류 수정 B: 오타 수정 (color)]
                                    // BoxDecoration 내에서 color 속성이 중복 정의되는 문제 방지
                                    // ---------------------------------------------
                                    color: const Color(0xFFF0EAE8), 
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                FractionallySizedBox(
                                  widthFactor: (index + 1) / menopauseQuestions.length,
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
                            
                            const SizedBox(height: 20), // Reduced spacing

                            // Question Text (Flexible to avoid overflow)
                            Flexible(
                              child: SingleChildScrollView(
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(20), // Reduced padding
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
                                        question.text,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Color(0xFF243447),
                                          fontSize: 20,
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w600,
                                          height: 1.3,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        question.description,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Color(0xFF6B6B6B),
                                          fontSize: 14,
                                          fontFamily: 'Inter',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 24), // Reduced spacing

                            // Answer Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: _buildAnswerButton(
                                    text: '예',
                                    isSelected: selectedValue == 1,
                                    onTap: () => _onAnswer(1),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildAnswerButton(
                                    text: '아니오',
                                    isSelected: selectedValue == 0,
                                    onTap: () => _onAnswer(0),
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
    ); // <--- [수정된 부분 A: 누락된 괄호 및 세미콜론 추가]
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
          boxShadow: isSelected ? [
            BoxShadow(
              color: const Color(0xFFD7454D).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ] : null,
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