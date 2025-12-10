import '../../api/dashboard/dashboard_api_client.dart';
import '../../dtos/dashboard/emotion_history_entry.dart';

class DashboardRepository {
  DashboardRepository(this._apiClient);

  final DashboardApiClient _apiClient;

  Future<List<EmotionHistoryEntry>> fetchEmotionHistory(int days) {
    return _apiClient.fetchEmotionHistory(days);
  }
}
