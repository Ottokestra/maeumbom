import 'package:dio/dio.dart';
import '../../../core/config/api_config.dart';
import '../../dtos/slang_quiz/start_game_request.dart';
import '../../dtos/slang_quiz/start_game_response.dart';
import '../../dtos/slang_quiz/submit_answer_request.dart';
import '../../dtos/slang_quiz/submit_answer_response.dart';
import '../../dtos/slang_quiz/end_game_response.dart';

class SlangQuizApiClient {
  final Dio _dio;

  SlangQuizApiClient(this._dio);

  /// 게임 시작
  Future<StartGameResponse> startGame(StartGameRequest request) async {
    try {
      final response = await _dio.post(
        ApiConfig.slangQuizStartGame,
        data: request.toJson(),
      );
      print('[SlangQuiz API] Start Game Response: ${response.data}');
      return StartGameResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 특정 문제 조회
  Future<QuestionData> getQuestion(int gameId, int questionNumber) async {
    try {
      final response = await _dio.get(
        ApiConfig.slangQuizGetQuestion(gameId, questionNumber),
      );
      print('[SlangQuiz API] Get Question Response: ${response.data}');
      return QuestionData.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 답안 제출
  Future<SubmitAnswerResponse> submitAnswer(
    int gameId,
    SubmitAnswerRequest request,
  ) async {
    try {
      final response = await _dio.post(
        ApiConfig.slangQuizSubmitAnswer(gameId),
        data: request.toJson(),
      );
      print('[SlangQuiz API] Submit Answer Response: ${response.data}');
      return SubmitAnswerResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 게임 종료
  Future<EndGameResponse> endGame(int gameId) async {
    try {
      final response = await _dio.post(
        ApiConfig.slangQuizEndGame(gameId),
      );
      print('[SlangQuiz API] End Game Response: ${response.data}');
      return EndGameResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 관리자용 문제 생성 (개발용)
  Future<Map<String, dynamic>> generateQuestionsAdmin({
    required String level,
    required String quizType,
    required int count,
  }) async {
    try {
      final response = await _dio.post(
        ApiConfig.slangQuizAdminGenerate,
        queryParameters: {
          'level': level,
          'quiz_type': quizType,
          'count': count,
        },
      );
      print('[SlangQuiz API] Admin Generate Response: ${response.data}');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException e) {
    if (e.response != null) {
      final message = e.response!.data?['detail'] ?? 'Unknown error';
      return Exception('API Error: $message');
    }
    return Exception('Network error: ${e.message}');
  }
}

