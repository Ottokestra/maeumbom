import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/dtos/menopause/menopause_question_response.dart';
import '../../data/dtos/menopause/menopause_survey_request.dart';
import '../../data/dtos/menopause/menopause_survey_response.dart';
import '../../data/repositories/menopause_repository.dart';

/// ---------------------------------------------------------------------------
/// State
/// ---------------------------------------------------------------------------
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

/// ---------------------------------------------------------------------------
/// ViewModel Provider
/// ---------------------------------------------------------------------------
final menopauseSurveyViewModelProvider =
    StateNotifierProvider.autoDispose<MenopauseSurveyViewModel, MenopauseSurveyState>(
  (ref) {
    final repository = ref.watch(menopauseRepositoryProvider);

    // OnboardingRepository 의존성 제거된 버전
    return MenopauseSurveyViewModel(repository);
  },
);

/// ---------------------------------------------------------------------------
/// ViewModel
/// ---------------------------------------------------------------------------
class MenopauseSurveyViewModel extends StateNotifier<MenopauseSurveyState> {
  final MenopauseRepository _repository;

  String? _selectedGender; // 선택된 성별 코드 (MALE / FEMALE)

  MenopauseSurveyViewModel(this._repository) : super(MenopauseSurveyState()) {
    // 생성 시 자동 로드
    loadQuestions();
  }

  Future<void> loadQuestions() async {
    if (state.isLoading || state.questions.isNotEmpty) {
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      // ----------------------------------------------------------------------
      // TODO: 실제 구현 시에는 프로필/로컬 저장소에서 성별을 가져오도록 변경
      // 현재는 테스트를 위해 성별을 '여성'으로 하드코딩
      // ----------------------------------------------------------------------
      const genderStr = '여성';

      String genderCode;
      if (genderStr == '남성' || genderStr == 'MALE') {
        genderCode = 'MALE';
      } else if (genderStr == '여성' || genderStr == 'FEMALE') {
        genderCode = 'FEMALE';
      } else {
        genderCode = 'FEMALE';
      }
      _selectedGender = genderCode;

      // 질문 목록 조회
      final questions = await _repository.getQuestions(gender: genderCode);
      questions.sort((a, b) => a.orderNo.compareTo(b.orderNo));

      state = state.copyWith(isLoading: false, questions: questions);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

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
      return null;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      if (_selectedGender == null) {
        throw Exception('Gender not selected');
      }

      final request = MenopauseSurveyRequest(
        gender: _selectedGender == 'MALE'
            ? MenopauseGender.male
            : MenopauseGender.female,
        answers: state.answers.entries
            .map(
              (e) => MenopauseAnswerItem(
                questionId: e.key,
                answerValue: e.value,
              ),
            )
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