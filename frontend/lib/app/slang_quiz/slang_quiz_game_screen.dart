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
        TopNotificationManager.show(
          context,
          message: '게임 시작 실패: $e',
          type: TopNotificationType.red,
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
        userAnswerIndex: answerIndex ?? -1,
        responseTimeSeconds: responseTime,
      );

      final response = await _apiClient!.submitAnswer(_gameId!, request);

      if (mounted) {
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
        TopNotificationManager.show(
          context,
          message: '답안 제출 실패: $e',
          type: TopNotificationType.red,
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
        TopNotificationManager.show(
          context,
          message: '다음 문제 로드 실패: $e',
          type: TopNotificationType.red,
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
        TopNotificationManager.show(
          context,
          message: '게임 종료 실패: $e',
          type: TopNotificationType.red,
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
    if (isTimeout) {
      final correctAnswer = _questionData?.options[correctAnswerIndex] ?? '';
      await MessageDialogHelper.showRedAlert(
        context,
        icon: Icons.timer_off_outlined,
        title: '시간 초과! ⏰',
        message: '정답은 "$correctAnswer"였어요.\n\n$explanation',
        primaryButtonText: '다음 문제',
        onPressed: () => Navigator.pop(context),
      );
    } else if (isCorrect) {
      await MessageDialogHelper.showGreenAlert(
        context,
        icon: Icons.check_circle_outline,
        title: '정답이에요! 🎉',
        message: '$explanation\n\n획득 점수: $earnedScore점\n\n$rewardMessage',
        primaryButtonText: '다음 문제',
        onPressed: () => Navigator.pop(context),
      );
    } else {
      await MessageDialogHelper.showRedAlert(
        context,
        icon: Icons.close_outlined,
        title: '아쉬워요 😢',
        message: '$explanation\n\n획득 점수: $earnedScore점\n\n$rewardMessage',
        primaryButtonText: '다음 문제',
        onPressed: () => Navigator.pop(context),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dailyState = ref.watch(dailyMoodProvider);
    final currentEmotion = dailyState.selectedEmotion ?? EmotionId.joy;

    if (_isLoading) {
      return AppFrame(
        backgroundColor: AppColors.bgBasic,
        topBar: TopBar(
          title: '신조어 퀴즈',
          backgroundColor: AppColors.bgBasic,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_questionData == null) {
      return AppFrame(
        backgroundColor: AppColors.bgBasic,
        topBar: TopBar(
          title: '신조어 퀴즈',
          backgroundColor: AppColors.bgBasic,
        ),
        body: const Center(child: Text('문제를 불러올 수 없습니다.')),
      );
    }

    return AppFrame(
      backgroundColor: AppColors.bgBasic,
      topBar: TopBar(
        title: '',
        rightIcon: Icons.close,
        onTapRight: () => Navigator.pop(context),
        backgroundColor: AppColors.bgBasic,
      ),
      body: QuestionProgressView.withoutModal(
        currentStep: _currentQuestion - 1,
        totalSteps: _totalQuestions,
        topWidget: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '문제 $_currentQuestion/$_totalQuestions',
                    style: AppTypography.h3.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                  _TimerBadge(seconds: _timeRemaining),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: LinearProgressIndicator(
                  value: _currentQuestion / _totalQuestions,
                  backgroundColor: AppColors.bgWarm,
                  color: AppColors.primaryColor,
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ),
        questionText: _questionData!.question,
        questionTextStyle: AppTypography.h3.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        content: ChoiceButtonGroup(
          choices: _questionData!.options,
          selectedIndex: _selectedIndex,
          layout: ChoiceLayout.vertical,
          mode: ChoiceButtonMode.basic,
          showBorder: true,
          showNumber: true,
          onChoiceSelected: (index, choice) {
            if (_isSubmitting) return;

            setState(() => _selectedIndex = index);

            // Auto-submit with visual feedback delay
            Future.delayed(const Duration(milliseconds: 200), () {
              _submitAnswer(index);
            });
          },
        ),
      ),
    );
  }
}

/// Timer Badge Widget
class _TimerBadge extends StatelessWidget {
  final int seconds;

  const _TimerBadge({required this.seconds});

  @override
  Widget build(BuildContext context) {
    final isWarning = seconds <= 10;
    final badgeColor =
        isWarning ? AppColors.errorRed : AppColors.secondaryColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_outlined,
            size: AppSpacing.sm,
            color: badgeColor,
          ),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            '$seconds초',
            style: AppTypography.caption.copyWith(
              color: badgeColor,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
