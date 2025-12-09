import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../../dtos/menopause/menopause_survey_request.dart';
import '../../dtos/menopause/menopause_survey_response.dart';

part 'menopause_api_client.g.dart';

/// 갱년기 설문 API 클라이언트
///
/// POST /api/menopause-survey/submit
@RestApi()
abstract class MenopauseApiClient {
  factory MenopauseApiClient(Dio dio, {String baseUrl}) = _MenopauseApiClient;

  /// 갱년기 설문 제출
  ///
  /// 인증은 현재 MVP라 불필요 (백엔드 스펙 기준)
  @POST('/api/menopause-survey/submit')
  Future<MenopauseSurveyResponse> submitSurvey(
    @Body() MenopauseSurveyRequest request,
  );
}
