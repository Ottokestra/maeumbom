import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ui/app_ui.dart';
import '../../providers/daily_mood_provider.dart';
import '../../providers/auth_provider.dart';
import '../../data/api/slang_quiz/slang_quiz_api_client.dart';
import '../../data/dtos/slang_quiz/start_game_request.dart';
import '../../data/dtos/slang_quiz/start_game_response.dart';
import '../../data/dtos/slang_quiz/submit_answer_request.dart';

class SlangQuizGameScreen extends ConsumerStatefulWidget {
  final String level;
  final String quizType;

  const SlangQuizGameScreen({
    super.key,
    required this.level,
    required this.quizType,
  });

  @override
  ConsumerState<SlangQuizGameScreen> createState() => _SlangQuizGameScreenState();
}

class _SlangQuizGameScreenState extends ConsumerState<SlangQuizGameScreen> {
  SlangQuizApiClient? _apiClient;
  
  int? _gameId;
  int _currentQuestion = 1;
  int _totalQuestions = 5;
  QuestionData? _questionData;
  int? _selectedIndex;
  int _timeRemaining = 20;
  // ignore: unused_field
  int _totalScore = 0;
  bool _isLoading = true;
  bool _isSubmitting = false;
  Timer? _timer;
  DateTime? _questionStartTime;

  @override
  void initState() {
    super.initState();
    // API 클라이언트는 _startGame에서 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startGame();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _startGame() async {
    try {
      // API 클라이언트 초기화
      final dio = ref.read(dioWithAuthProvider);
      _apiClient = SlangQuizApiClient(dio);
      
      final request = StartGameRequest(
        level: widget.level,
        quizType: widget.quizType,
      );
      
      final response = await _apiClient!.startGame(request);
      
      setState(() {
        _gameId = response.gameId;
        _totalQuestions = response.totalQuestions;
        _currentQuestion = response.currentQuestion;
        _questionData = response.question;
        _timeRemaining = response.question.timeLimit;
        _isLoading = false;
        _questionStartTime = DateTime.now();
      });
      
      _startTimer();
    } catch (e) {
      print('[SlangQuiz] Start game error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('게임 시작 실패: $e')),
        );
        Navigator.pop(context);
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemaining > 0) {
        setState(() => _timeRemaining--);
      } else {
        // 시간 초과 - 자동으로 오답 처리
        _submitAnswer(null);
      }
    });
  }

  Future<void> _submitAnswer(int? answerIndex) async {
    if (_isSubmitting || _gameId == null || _questionData == null || _apiClient == null) return;
    
    setState(() => _isSubmitting = true);
    _timer?.cancel();

    try {
      final responseTime = _questionStartTime != null
          ? DateTime.now().difference(_questionStartTime!).inSeconds
          : 20;

      final isTimeout = answerIndex == null;
      
      final request = SubmitAnswerRequest(
        questionNumber: _currentQuestion,
        userAnswerIndex: answerIndex ?? -1, // -1은 시간 초과
        responseTimeSeconds: responseTime,
      );

      final response = await _apiClient!.submitAnswer(_gameId!, request);

      if (mounted) {
        // 결과 다이얼로그 표시
        await _showResultDialog(
          isCorrect: response.isCorrect,
          correctAnswerIndex: response.correctAnswerIndex,
          earnedScore: response.earnedScore,
          explanation: response.explanation,
          rewardMessage: response.rewardCard.message,
          isTimeout: isTimeout,
        );

        setState(() {
          _totalScore += response.earnedScore;
          _isSubmitting = false;
        });

        // 다음 문제로 이동 또는 게임 종료
        if (_currentQuestion < _totalQuestions) {
          await _loadNextQuestion();
        } else {
          await _endGame();
        }
      }
    } catch (e) {
      print('[SlangQuiz] Submit answer error: $e');
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('답안 제출 실패: $e')),
        );
      }
    }
  }

  Future<void> _loadNextQuestion() async {
    if (_apiClient == null) return;
    
    try {
      setState(() => _isLoading = true);
      
      final nextQuestionNumber = _currentQuestion + 1;
      final questionData = await _apiClient!.getQuestion(_gameId!, nextQuestionNumber);
      
      setState(() {
        _currentQuestion = nextQuestionNumber;
        _questionData = questionData;
        _selectedIndex = null;
        _timeRemaining = questionData.timeLimit;
        _isLoading = false;
        _questionStartTime = DateTime.now();
      });
      
      _startTimer();
    } catch (e) {
      print('[SlangQuiz] Load next question error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('다음 문제 로드 실패: $e')),
        );
      }
    }
  }

  Future<void> _endGame() async {
    if (_apiClient == null) return;
    
    try {
      final response = await _apiClient!.endGame(_gameId!);
      
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/training/slang-quiz/result',
          arguments: response,
        );
      }
    } catch (e) {
      print('[SlangQuiz] End game error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('게임 종료 실패: $e')),
        );
      }
    }
  }

  Future<void> _showResultDialog({
    required bool isCorrect,
    required int correctAnswerIndex,
    required int earnedScore,
    required String explanation,
    required String rewardMessage,
    bool isTimeout = false,
  }) async {
    String title;
    if (isTimeout) {
      title = '시간 초과! ⏰';
    } else if (isCorrect) {
      title = '정답입니다! 🎉';
    } else {
      title = '아쉬워요 😢';
    }
    
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          title,
          style: AppTypography.h3,
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '획득 점수: $earnedScore점',
              style: AppTypography.h2.copyWith(color: AppColors.primaryColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              explanation,
              style: AppTypography.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.bgLightPink,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                rewardMessage,
                style: AppTypography.body,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('다음'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dailyState = ref.watch(dailyMoodProvider);
    final currentEmotion = dailyState.selectedEmotion ?? EmotionId.joy;

    if (_isLoading) {
      return AppFrame(
        topBar: TopBar(title: '신조어 퀴즈'),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_questionData == null) {
      return AppFrame(
        topBar: TopBar(title: '신조어 퀴즈'),
        body: const Center(child: Text('문제를 불러올 수 없습니다.')),
      );
    }

    return AppFrame(
      topBar: TopBar(
        title: '문제 $_currentQuestion/$_totalQuestions  ⏱️ $_timeRemaining초',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            // 캐릭터 (크기 축소)
            EmotionCharacter(
              id: currentEmotion,
              use2d: true,
              size: 120,
            ),
            const SizedBox(height: AppSpacing.md),
            
            // 문제
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.bgLightPink,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                _questionData!.question,
                style: AppTypography.h3,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            
            // 선택지 (4개 모두 표시, 스크롤 없음)
            ...List.generate(_questionData!.options.length, (index) {
              final isSelected = _selectedIndex == index;
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index < _questionData!.options.length - 1 
                      ? AppSpacing.sm 
                      : 0,
                ),
                child: GestureDetector(
                  onTap: _isSubmitting ? null : () {
                    setState(() => _selectedIndex = index);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryColor.withOpacity(0.1)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryColor
                            : AppColors.borderLight,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      _questionData!.options[index],
                      style: AppTypography.body,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: AppSpacing.lg),
            
            // 제출 버튼
            SizedBox(
              width: double.infinity,
              child: AppButton(
                text: _isSubmitting ? '제출 중...' : '답안 제출',
                variant: ButtonVariant.primaryRed,
                onTap: _selectedIndex != null && !_isSubmitting
                    ? () => _submitAnswer(_selectedIndex)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

