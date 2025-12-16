import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/routine/routine_service.dart';
import '../data/api/routine/routine_api_client.dart';
import '../data/models/routine/routine_recommendation.dart';
import '../data/repository/routine/routine_repository.dart';
import 'api_client_provider.dart';

// ----- Infrastructure Providers -----

/// Routine API Client provider
final routineApiClientProvider = Provider<RoutineApiClient>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return RoutineApiClient(apiClient);
});

/// Routine Repository provider
final routineRepositoryProvider = Provider<RoutineRepository>((ref) {
  final apiClient = ref.watch(routineApiClientProvider);
  return RoutineRepository(apiClient);
});

/// Routine Service provider
final routineServiceProvider = Provider<RoutineService>((ref) {
  final repository = ref.watch(routineRepositoryProvider);
  return RoutineService(repository);
});

// ----- State Providers -----

/// 루틴 추천 상태 관리 Provider
final routineProvider =
    StateNotifierProvider<RoutineNotifier, AsyncValue<RoutineRecommendation?>>(
  (ref) => RoutineNotifier(ref.watch(routineServiceProvider)),
);

/// 루틴 추천 상태 관리 Notifier
class RoutineNotifier extends StateNotifier<AsyncValue<RoutineRecommendation?>> {
  RoutineNotifier(this._service) : super(const AsyncValue.data(null));

  final RoutineService _service;

  /// 최근 루틴 추천 데이터 로드
  Future<void> loadLatest() async {
    // 이미 로딩 중이면 중복 요청 방지
    if (state.isLoading) return;

    state = const AsyncValue.loading();
    
    try {
      final recommendation = await _service.getLatestRecommendation();
      state = AsyncValue.data(recommendation);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      // 에러 발생 시에도 빈 데이터로 폴백
      state = const AsyncValue.data(RoutineRecommendation(routines: []));
    }
  }

  /// 데이터 초기화
  void reset() {
    state = const AsyncValue.data(null);
  }
}

