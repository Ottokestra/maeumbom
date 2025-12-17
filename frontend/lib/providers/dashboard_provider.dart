import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/api/dashboard/dashboard_api_client.dart';
import '../data/repository/dashboard/dashboard_repository.dart';
import '../data/models/dashboard/emotion_history_model.dart';
import 'auth_provider.dart';

// ----- API Client Provider -----

/// Dashboard API Client Provider
final dashboardApiClientProvider = Provider<DashboardApiClient>((ref) {
  final dio = ref.watch(baseDioProvider);
  return DashboardApiClient(dio);
});

// ----- Repository Provider -----

/// Dashboard Repository Provider
final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final apiClient = ref.watch(dashboardApiClientProvider);
  return DashboardRepository(apiClient);
});

// ----- Data Models -----

/// 날짜 범위 클래스
class DateRange {
  final DateTime start;
  final DateTime end;

  DateRange(this.start, this.end);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DateRange && other.start == start && other.end == end;
  }

  @override
  int get hashCode => start.hashCode ^ end.hashCode;
}

// ----- Data Provider -----

/// 일간 감정 Provider (날짜 범위 기반)
/// 
/// TB_DAILY_TARGET_EVENTS의 PRIMARY_EMOTION 데이터 조회
final dailyEmotionsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, DateRange>((ref, dateRange) async {
  final repository = ref.watch(dashboardRepositoryProvider);
  return await repository.getDailyEmotions(
    startDate: dateRange.start,
    endDate: dateRange.end,
  );
});

/// 주간 감정 이력 Provider (날짜 범위 기반)
/// 
/// 주간 리포트 Page 2에서 요일별 감정 캐릭터를 표시하기 위해 사용
final weeklyEmotionsProvider = FutureProvider.autoDispose
    .family<List<EmotionHistoryModel>, DateRange>((ref, dateRange) async {
  final repository = ref.watch(dashboardRepositoryProvider);
  return await repository.getWeeklyEmotions(
    startDate: dateRange.start,
    endDate: dateRange.end,
  );
});

/// 감정 이력 Provider (커스텀 limit)
/// 
/// [limit]: 조회할 레코드 수
final emotionHistoryProvider = FutureProvider.autoDispose
    .family<List<EmotionHistoryModel>, int>((ref, limit) async {
  final repository = ref.watch(dashboardRepositoryProvider);
  return await repository.getEmotionHistory(limit: limit);
});

