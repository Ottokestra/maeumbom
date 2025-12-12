import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/api_config.dart';
import '../api/menopause/menopause_api_client.dart';
import '../dtos/menopause/menopause_question_response.dart';
import '../dtos/menopause/menopause_survey_request.dart';
import '../dtos/menopause/menopause_survey_response.dart';

final menopauseRepositoryProvider = Provider<MenopauseRepository>((ref) {
  final dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));
  // Add auth interceptor if needed later
  return MenopauseRepository(MenopauseApiClient(dio));
});

class MenopauseRepository {
  final MenopauseApiClient _client;

  MenopauseRepository(this._client);

  Future<List<MenopauseQuestionResponse>> getQuestions({String? gender}) async {
    return _client.getQuestions(gender: gender);
  }

  Future<MenopauseSurveyResponse> submitSurvey(MenopauseSurveyRequest request) async {
    return _client.submitSurvey(request);
  }
}
