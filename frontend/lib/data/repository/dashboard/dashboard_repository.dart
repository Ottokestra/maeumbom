import '../../api/dashboard/dashboard_api_client.dart';
import '../../dtos/dashboard/emotion_history_entry.dart';
import '../../models/report/weekly_mood_report.dart';

class DashboardRepository {
  DashboardRepository(this._apiClient);

  final DashboardApiClient _apiClient;

  Future<List<EmotionHistoryEntry>> fetchEmotionHistory(int days) {
    return _apiClient.fetchEmotionHistory(days);
  }

  Future<WeeklyMoodReport> fetchWeeklyMoodReport({int weekOffset = 0}) {
    return _apiClient.fetchWeeklyMoodReport(weekOffset: weekOffset);
  }
}
