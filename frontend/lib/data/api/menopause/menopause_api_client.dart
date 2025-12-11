import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../../dtos/menopause/menopause_survey_request.dart';
import '../../dtos/menopause/menopause_survey_response.dart';
import '../../dtos/menopause/menopause_question_response.dart';

part 'menopause_api_client.g.dart';

/// 갱년기 설문 API 클라이언트
///
/// **주의: `baseUrl`에는 `/api/menopause-survey`까지 포함되어야 합니다.**
@RestApi()
abstract class MenopauseApiClient {
  factory MenopauseApiClient(Dio dio, {String baseUrl}) = _MenopauseApiClient;

  /// 갱년기 설문 제출
  @POST('/api/menopause-survey/submit')
  Future<MenopauseSurveyResponse> submitSurvey(
    @Body() MenopauseSurveyRequest request,
  );

  /// 설문 문항 목록 조회
  @GET('/api/menopause-survey/questions')
  Future<List<MenopauseQuestionResponse>> getQuestions({
    @Query('gender') String? gender,
  });
}