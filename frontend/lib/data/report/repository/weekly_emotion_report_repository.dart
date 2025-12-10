import '../../../core/config/api_config.dart';
import '../../../core/services/api_client.dart';
import '../models/weekly_emotion_report.dart';

class WeeklyEmotionReportRepository {
  WeeklyEmotionReportRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<WeeklyEmotionReport> fetchWeeklyReport({
    required int userId,
    DateTime? weekStart,
  }) async {
    final queryParameters = <String, dynamic>{
      'user_id': userId,
    };

    if (weekStart != null) {
      final formattedDate = weekStart.toIso8601String().split('T').first;
      queryParameters['week_start'] = formattedDate;
    }

    final response = await _apiClient.get(
      ApiConfig.emotionWeeklyReport,
      queryParameters: queryParameters,
    ) as Map<String, dynamic>;

    return WeeklyEmotionReport.fromJson(response);
  }
}
