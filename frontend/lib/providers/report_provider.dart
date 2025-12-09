import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/api/report/report_api_client.dart';
import '../data/dtos/report/user_report_response.dart';
import 'auth_provider.dart';

enum ReportPeriod {
  daily,
  weekly,
  monthly,
}

extension ReportPeriodX on ReportPeriod {
  String get label {
    switch (this) {
      case ReportPeriod.daily:
        return '일간';
      case ReportPeriod.weekly:
        return '주간';
      case ReportPeriod.monthly:
        return '월간';
    }
  }

  String get description {
    switch (this) {
      case ReportPeriod.daily:
        return '일간 리포트';
      case ReportPeriod.weekly:
        return '주간 리포트';
      case ReportPeriod.monthly:
        return '월간 리포트';
    }
  }
}

final reportApiClientProvider = Provider<ReportApiClient>((ref) {
  final dio = ref.watch(dioWithAuthProvider);
  return ReportApiClient(dio);
});

final reportPeriodProvider = StateProvider<ReportPeriod>((ref) {
  return ReportPeriod.daily;
});

final userReportProvider =
    FutureProvider.autoDispose.family<UserReportResponse, ReportPeriod>(
  (ref, period) {
    final apiClient = ref.watch(reportApiClientProvider);

    switch (period) {
      case ReportPeriod.daily:
        return apiClient.fetchDailyReport();
      case ReportPeriod.weekly:
        return apiClient.fetchWeeklyReport();
      case ReportPeriod.monthly:
        return apiClient.fetchMonthlyReport();
    }
  },
);
