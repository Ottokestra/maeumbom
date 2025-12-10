import '../../../core/config/api_config.dart';
import '../../../core/services/api_client.dart';
import '../../dtos/dashboard/emotion_history_entry.dart';
import '../../models/report/weekly_mood_report.dart';

class DashboardApiClient {
  DashboardApiClient(this._client);

  final ApiClient _client;

  Future<List<EmotionHistoryEntry>> fetchEmotionHistory(int days) async {
    final response = await _client.get(
      ApiConfig.emotionHistory,
      queryParameters: {'days': days},
    );

    final data = (response as Map<String, dynamic>?)?['data'] as List<dynamic>? ?? [];
    return data
        .map(
          (item) => EmotionHistoryEntry.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<WeeklyMoodReport> fetchWeeklyMoodReport({int weekOffset = 0}) async {
    final response = await _client.get(
      ApiConfig.weeklyMoodReport,
      queryParameters: {'week_offset': weekOffset},
    );

    final data = response is Map<String, dynamic>
        ? (response['data'] as Map<String, dynamic>? ?? response)
        : <String, dynamic>{};

    return WeeklyMoodReport.fromJson(data as Map<String, dynamic>);
  }
}
