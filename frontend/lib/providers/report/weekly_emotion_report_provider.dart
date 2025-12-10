import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/report/models/weekly_emotion_report.dart';
import '../../data/report/repository/weekly_emotion_report_repository.dart';
import '../api_client_provider.dart';

typedef WeeklyEmotionReportQuery = ({int userId, DateTime? weekStart});

final weeklyEmotionReportRepositoryProvider =
    Provider<WeeklyEmotionReportRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return WeeklyEmotionReportRepository(apiClient);
});

final weeklyEmotionReportProvider = FutureProvider.autoDispose
    .family<WeeklyEmotionReport, WeeklyEmotionReportQuery>((ref, params) {
  final repository = ref.watch(weeklyEmotionReportRepositoryProvider);
  return repository.fetchWeeklyReport(
    userId: params.userId,
    weekStart: params.weekStart,
  );
});
