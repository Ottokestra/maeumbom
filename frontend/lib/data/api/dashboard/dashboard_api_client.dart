import '../../../core/config/api_config.dart';
import '../../../core/services/api_client.dart';
import '../../dtos/dashboard/emotion_history_entry.dart';

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
}
