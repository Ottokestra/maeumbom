import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/api/dashboard/dashboard_api_client.dart';
import '../data/api/recommendation/recommendation_api_client.dart';
import '../data/dtos/dashboard/emotion_history_entry.dart';
import '../data/dtos/recommendation/recommendation_response.dart';
import '../data/dtos/user_phase/user_pattern_setting_response.dart';
import '../data/dtos/user_phase/user_phase_response.dart';
import '../data/repository/dashboard/dashboard_repository.dart';
import '../data/repository/recommendation/recommendation_repository.dart';
import '../data/repository/user_phase/user_phase_repository.dart';
import 'api_client_provider.dart';
import 'auth_provider.dart';

enum EmotionHistoryRange {
  week(7, '7일'),
  month(30, '30일');

  const EmotionHistoryRange(this.days, this.label);
  final int days;
  final String label;
}

final emotionHistoryRangeProvider = StateProvider<EmotionHistoryRange>((ref) {
  return EmotionHistoryRange.week;
});

final reportDashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final dio = ref.watch(baseDioProvider);
  final apiClient = DashboardApiClient(dio);
  return DashboardRepository(apiClient);
});

final userPhaseRepositoryProvider = Provider<UserPhaseRepository>((ref) {
  final apiClient = ref.watch(userPhaseApiClientProvider);
  return UserPhaseRepository(apiClient);
});

final recommendationRepositoryProvider = Provider<RecommendationRepository>((ref) {
  final apiClient = RecommendationApiClient(ref.watch(apiClientProvider));
  return RecommendationRepository(apiClient);
});

final emotionHistoryProvider =
    FutureProvider.autoDispose.family<List<EmotionHistoryEntry>, EmotionHistoryRange>(
  (ref, range) async {
    final repository = ref.watch(reportDashboardRepositoryProvider);
    final emotions = await repository.getEmotionHistory(limit: range.days);
    
    // EmotionHistoryModel을 EmotionHistoryEntry로 변환
    return emotions.map((emotion) {
      return EmotionHistoryEntry(
        createdAt: emotion.createdAt,
        sentimentOverall: emotion.sentimentOverall ?? 'neutral',
        primaryEmotionCode: emotion.primaryEmotion?.code ?? '',
        primaryEmotionLabel: emotion.primaryEmotion?.nameKo ?? '',
        primaryEmotionGroup: emotion.primaryEmotion?.group ?? '',
      );
    }).toList();
  },
);

final currentPhaseProvider = FutureProvider.autoDispose<UserPhaseResponse>((ref) {
  final repository = ref.watch(userPhaseRepositoryProvider);
  return repository.fetchCurrentPhase();
});

final phaseSettingsProvider =
    FutureProvider.autoDispose<UserPatternSettingResponse>((ref) {
  final repository = ref.watch(userPhaseRepositoryProvider);
  return repository.fetchSettings();
});

final quoteRecommendationProvider = FutureProvider.autoDispose
    .family<RecommendationResponse, Map<String, dynamic>>((ref, payload) {
  final repository = ref.watch(recommendationRepositoryProvider);
  return repository.fetchQuote(payload);
});

final musicRecommendationProvider = FutureProvider.autoDispose
    .family<RecommendationResponse, Map<String, dynamic>>((ref, payload) {
  final repository = ref.watch(recommendationRepositoryProvider);
  return repository.fetchMusic(payload);
});

final imageRecommendationProvider = FutureProvider.autoDispose
    .family<RecommendationResponse, Map<String, dynamic>>((ref, payload) {
  final repository = ref.watch(recommendationRepositoryProvider);
  return repository.fetchImage(payload);
});
