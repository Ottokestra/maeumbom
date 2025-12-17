import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/api/routine_recommendations/routine_recommendations_api_client.dart';
import '../data/dtos/routine_recommendations/routine_recommendations_list_response.dart';
import '../core/utils/logger.dart';
import 'auth_provider.dart';

/// Routine Recommendations API Client Provider
final routineRecommendationsApiClientProvider = Provider<RoutineRecommendationsApiClient>((ref) {
  final dio = ref.watch(dioWithAuthProvider);
  return RoutineRecommendationsApiClient(dio);
});

/// 날짜 범위 기반 루틴 추천 데이터 조회 Provider
/// 
/// 사용법: ref.watch(routineRecommendationsProviderFamily((startDate, endDate)))
final routineRecommendationsProviderFamily =
    FutureProvider.family<RoutineRecommendationsListResponse, (DateTime, DateTime)>(
        (ref, dates) async {
  final apiClient = ref.watch(routineRecommendationsApiClientProvider);
  final startDate = dates.$1;
  final endDate = dates.$2;
  
  appLogger.d('🔵 [routineRecommendationsProviderFamily] Loading routine recommendations from $startDate to $endDate');
  
  try {
    final response = await apiClient.getRecommendations(
      startDate: startDate,
      endDate: endDate,
      limit: 7,
    );
    
    appLogger.d('🟢 [routineRecommendationsProviderFamily] Loaded ${response.totalCount} routine recommendations');
    return response;
  } catch (e, stack) {
    appLogger.e('🔴 [routineRecommendationsProviderFamily] Error loading routine recommendations', error: e, stackTrace: stack);
    rethrow;
  }
});

