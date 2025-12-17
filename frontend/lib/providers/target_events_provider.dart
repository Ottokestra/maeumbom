import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/api/target_events/target_events_api_client.dart';
import '../data/models/target_events/daily_event_model.dart';
import '../data/models/target_events/weekly_event_model.dart';
import '../core/utils/logger.dart';
import 'auth_provider.dart';

// ----- Infrastructure Providers -----

/// Target Events API Client Provider
final targetEventsApiClientProvider = Provider<TargetEventsApiClient>((ref) {
  final dio = ref.watch(dioWithAuthProvider);
  return TargetEventsApiClient(dio);
});

// ----- State Providers -----

/// Target Events State Notifier
class TargetEventsNotifier
    extends StateNotifier<AsyncValue<List<DailyEventModel>>> {
  final TargetEventsApiClient _apiClient;

  TargetEventsNotifier(this._apiClient) : super(const AsyncValue.data([]));

  /// 날짜 범위로 일일 이벤트 조회
  Future<void> loadDailyEvents({
    required DateTime startDate,
    required DateTime endDate,
    String? eventType,
    List<String>? tags,
    String? targetType,
  }) async {
    appLogger.d('🔵 loadDailyEvents called - Start: $startDate, End: $endDate');
    state = const AsyncValue.loading();
    try {
      appLogger.d('🔵 Calling API getDailyEvents...');
      final response = await _apiClient.getDailyEvents(
        startDate: startDate,
        endDate: endDate,
        eventType: eventType,
        tags: tags,
        targetType: targetType,
      );

      appLogger
          .d('🟢 API Success - Events count: ${response.dailyEvents.length}');
      state = AsyncValue.data(response.dailyEvents);
    } catch (e, stack) {
      appLogger.e('🔴 API Error', error: e, stackTrace: stack);
      state = AsyncValue.error(e, stack);
    }
  }

  /// 특정 날짜 분석 실행
  Future<void> analyzeDailyEvents(DateTime targetDate) async {
    try {
      final response = await _apiClient.analyzeDailyEvents(
        targetDate: targetDate,
      );

      // 분석 후 현재 날짜 범위로 다시 로드
      // (분석된 이벤트가 포함되도록)
      final now = DateTime.now();
      final endDate = now.add(const Duration(days: 7));
      await loadDailyEvents(startDate: now, endDate: endDate);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// 새로고침
  Future<void> refresh({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    await loadDailyEvents(startDate: startDate, endDate: endDate);
  }
}

/// Target Events Provider
final targetEventsProvider = StateNotifierProvider<TargetEventsNotifier,
    AsyncValue<List<DailyEventModel>>>((ref) {
  final apiClient = ref.watch(targetEventsApiClientProvider);
  return TargetEventsNotifier(apiClient);
});

/// 이벤트 개수 Provider
final dailyEventsCountProvider = Provider<int>((ref) {
  final eventsState = ref.watch(targetEventsProvider);
  return eventsState.maybeWhen(
    data: (events) => events.length,
    orElse: () => 0,
  );
});

/// Weekly Events State Notifier
class WeeklyEventsNotifier
    extends StateNotifier<AsyncValue<List<WeeklyEventModel>>> {
  final TargetEventsApiClient _apiClient;

  WeeklyEventsNotifier(this._apiClient) : super(const AsyncValue.data([]));

  /// 날짜 범위로 주간 이벤트 조회
  Future<void> loadWeeklyEvents({
    DateTime? startDate,
    DateTime? endDate,
    List<String>? tags,
    String? targetType,
  }) async {
    state = const AsyncValue.loading();
    try {
      final events = await _apiClient.getWeeklyEvents(
        startDate: startDate,
        endDate: endDate,
        tags: tags,
        targetType: targetType,
      );
      state = AsyncValue.data(events);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

/// Weekly Events Provider
final weeklyEventsProvider = StateNotifierProvider<WeeklyEventsNotifier,
    AsyncValue<List<WeeklyEventModel>>>((ref) {
  final apiClient = ref.watch(targetEventsApiClientProvider);
  return WeeklyEventsNotifier(apiClient);
});

/// Weekly Events Provider with Date Range (Family)
/// 날짜 범위를 파라미터로 받아 해당 기간의 주간 이벤트를 자동으로 로드합니다.
final weeklyEventsProviderFamily = FutureProvider.family<List<WeeklyEventModel>,
    (DateTime startDate, DateTime endDate)>((ref, dates) async {
  final apiClient = ref.watch(targetEventsApiClientProvider);
  final (startDate, endDate) = dates;

  return await apiClient.getWeeklyEvents(
    startDate: startDate,
    endDate: endDate,
  );
});
