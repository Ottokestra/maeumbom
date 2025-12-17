import '../../api/dashboard/dashboard_api_client.dart';
import '../../models/dashboard/emotion_history_model.dart';
import '../../../core/utils/logger.dart';

/// Dashboard Repository
/// API 클라이언트를 래핑하고 요일별 데이터 변환 로직 담당
class DashboardRepository {
  final DashboardApiClient _apiClient;

  DashboardRepository(this._apiClient);

  /// 주간 감정 이력 조회 (날짜 범위 기반)
  Future<List<Map<String, dynamic>>> getDailyEmotions({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      appLogger.d('📊 Fetching daily emotions from $startDate to $endDate');

      final emotions = await _apiClient.getDailyEmotions(
        startDate: startDate,
        endDate: endDate,
      );

      appLogger.d('✅ Successfully fetched ${emotions.length} daily emotion records');

      return emotions;
    } catch (e) {
      appLogger.e('Failed to fetch daily emotions', error: e);
      rethrow;
    }
  }

  Future<List<EmotionHistoryModel>> getWeeklyEmotions({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      appLogger.d('📊 Fetching weekly emotions from $startDate to $endDate');

      final emotions = await _apiClient.getEmotionHistory(
        startDate: startDate,
        endDate: endDate,
      );

      appLogger.d('✅ Successfully fetched ${emotions.length} emotion records');

      return emotions;
    } catch (e) {
      appLogger.e('Failed to fetch weekly emotions', error: e);
      rethrow;
    }
  }

  /// 특정 기간 감정 이력 조회
  Future<List<EmotionHistoryModel>> getEmotionHistory({int limit = 100}) async {
    try {
      appLogger.d('📊 Fetching emotion history (limit: $limit)');
      
      final emotions = await _apiClient.getEmotionHistory(limit: limit);
      
      appLogger.d('✅ Successfully fetched ${emotions.length} emotion records');
      
      return emotions;
    } catch (e) {
      appLogger.e('Failed to fetch emotion history', error: e);
      rethrow;
    }
  }
}
