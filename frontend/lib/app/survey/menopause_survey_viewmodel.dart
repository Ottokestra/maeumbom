import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/dtos/menopause/menopause_question_response.dart';
import '../../data/dtos/menopause/menopause_survey_request.dart';
import '../../data/dtos/menopause/menopause_survey_response.dart';
import '../../data/repositories/menopause_repository.dart';

// State class for the ViewModel
class MenopauseSurveyState {
  final bool isLoading;
  final List<MenopauseQuestionResponse> questions;
  final Map<int, int> answers; // questionId -> answerValue (1: Yes, 0: No)
  final MenopauseSurveyResponse? result;
  final String? error;

  MenopauseSurveyState({
    this.isLoading = false,
    this.questions = const [],
    this.answers = const {},
    this.result,
    this.error,
  });

  MenopauseSurveyState copyWith({
    bool? isLoading,
    List<MenopauseQuestionResponse>? questions,
    Map<int, int>? answers,
    MenopauseSurveyResponse? result,
    String? error,
  }) {
    return MenopauseSurveyState(
      isLoading: isLoading ?? this.isLoading,
      questions: questions ?? this.questions,
      answers: answers ?? this.answers,
      result: result ?? this.result,
      error: error ?? this.error,
    );
  }
}

// ViewModel Provider
final menopauseSurveyViewModelProvider =
    StateNotifierProvider.autoDispose<MenopauseSurveyViewModel, MenopauseSurveyState>((ref) {
  final repository = ref.watch(menopauseRepositoryProvider);
  return MenopauseSurveyViewModel(repository);
});

class MenopauseSurveyViewModel extends StateNotifier<MenopauseSurveyState> {
  final MenopauseRepository _repository;

  MenopauseSurveyViewModel(this._repository) : super(MenopauseSurveyState()) {
    // 💡 ViewModel 생성 시 질문을 즉시 로드합니다.
    loadQuestions(); 
  }

  // =======================================================
  // 🐛 오류 해결: Private _loadQuestions()를 Public loadQuestions()로 변경
  // =======================================================
  Future<void> loadQuestions() async {
    // 로딩 중이거나 이미 질문이 있으면 다시 로드하지 않음 (선택 사항)
    if (state.isLoading || state.questions.isNotEmpty) {
      return; 
    }
    
    state = state.copyWith(isLoading: true, error: null);
    try {
      // TODO: Get actual gender from user profile if needed. defaulting to FEMALE for now as per screen.
      final questions = await _repository.getQuestions(gender: 'FEMALE');
      // Sort by orderNo
      questions.sort((a, b) => a.orderNo.compareTo(b.orderNo));
      state = state.copyWith(isLoading: false, questions: questions);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
  // =======================================================

  void setAnswer(int questionId, int value) {
    final newAnswers = Map<int, int>.from(state.answers);
    newAnswers[questionId] = value;
    state = state.copyWith(answers: newAnswers);
  }

  int? getAnswer(int questionId) {
    return state.answers[questionId];
  }

  bool get isAllAnswered {
    if (state.questions.isEmpty) return false;
    return state.questions.every((q) => state.answers.containsKey(q.id));
  }

  Future<MenopauseSurveyResponse?> submitSurvey() async {
      if (!isAllAnswered) {
        // Should be handled by UI, but guard here
        return null;
      }

    state = state.copyWith(isLoading: true, error: null);
    try {
      // TODO: Replace MenopauseGender.female with actual gender derived from user profile or state
      final request = MenopauseSurveyRequest(
        gender: MenopauseGender.female,
        answers: state.answers.entries
            .map((e) => MenopauseAnswerItem(questionId: e.key, answerValue: e.value))
            .toList(),
      );

      final result = await _repository.submitSurvey(request);
      state = state.copyWith(isLoading: false, result: result);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }
}