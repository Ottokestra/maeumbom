import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/api/target_events/target_events_api_client.dart';
import '../data/models/target_events/daily_event_model.dart';
import 'auth_provider.dart';

// ----- Infrastructure Providers -----

/// Target Events API Client Provider
final targetEventsApiClientProvider = Provider<TargetEventsApiClient>((ref) {
  final dio = ref.watch(baseDioProvider);
  return TargetEventsApiClient(dio);
});

// ----- State Providers -----

/// Target Events State Notifier
class TargetEventsNotifier
    extends StateNotifier<AsyncValue<List<DailyEventModel>>> {
  final TargetEventsApiClient _apiClient;
  final Ref _ref;

  TargetEventsNotifier(this._apiClient, this._ref)
      : super(const AsyncValue.loading());

  /// Access token 가져오기
  Future<String?> _getAccessToken() async {
    final tokenStorage = _ref.read(tokenStorageServiceProvider);
    return await tokenStorage.getAccessToken();
  }

  /// 날짜 범위로 일일 이벤트 조회
  Future<void> loadDailyEvents({
    required DateTime startDate,
    required DateTime endDate,
    String? eventType,
    List<String>? tags,
    String? targetType,
  }) async {
    final accessToken = await _getAccessToken();
    
    if (accessToken == null) {
      state = AsyncValue.error(
        Exception('인증이 필요합니다.'),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncValue.loading();
    try {
      final response = await _apiClient.getDailyEvents(
        accessToken: accessToken,
        startDate: startDate,
        endDate: endDate,
        eventType: eventType,
        tags: tags,
        targetType: targetType,
      );

      state = AsyncValue.data(response.dailyEvents);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// 특정 날짜 분석 실행
  Future<void> analyzeDailyEvents(DateTime targetDate) async {
    final accessToken = await _getAccessToken();
    
    if (accessToken == null) {
      state = AsyncValue.error(
        Exception('인증이 필요합니다.'),
        StackTrace.current,
      );
      return;
    }

    try {
      final response = await _apiClient.analyzeDailyEvents(
        targetDate: targetDate,
        accessToken: accessToken,
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
  return TargetEventsNotifier(apiClient, ref);
});

/// 이벤트 개수 Provider
final dailyEventsCountProvider = Provider<int>((ref) {
  final eventsState = ref.watch(targetEventsProvider);
  return eventsState.maybeWhen(
    data: (events) => events.length,
    orElse: () => 0,
  );
});
