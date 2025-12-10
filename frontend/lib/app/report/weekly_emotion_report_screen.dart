import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/navigation/navigation_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/report/weekly_emotion_report_provider.dart';
import '../../ui/app_ui.dart';
import 'widgets/weekly_emotion_badges.dart';
import 'widgets/weekly_summary_bubbles.dart';
import 'widgets/weekly_temperature_gauge.dart';

class WeeklyEmotionReportScreen extends ConsumerWidget {
  const WeeklyEmotionReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationService = NavigationService(context, ref);
    final authState = ref.watch(authProvider);

    WeeklyEmotionReportQuery? query;
    authState.whenOrNull(data: (user) {
      if (user != null) {
        query = (userId: user.id, weekStart: null);
      }
    });

    return AppFrame(
      topBar: TopBar(
        title: '마음 리포트',
        leftIcon: Icons.arrow_back,
        onTapLeft: () => Navigator.of(context).maybePop(),
        rightIcon: query != null ? Icons.refresh : null,
        onTapRight: query == null
            ? null
            : () => ref.refresh(weeklyEmotionReportProvider(query!)),
      ),
      bottomBar: BottomMenuBar(
        currentIndex: 3,
        onTap: (index) => navigationService.navigateToTab(index),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: authState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ReportError(
            message: error.toString(),
            onRetry: () => ref.read(authProvider.notifier).refreshUser(),
          ),
          data: (user) {
            if (user == null || query == null) {
              return _ReportError(
                message: '사용자 정보를 불러오지 못했어요.',
                onRetry: () => ref.read(authProvider.notifier).refreshUser(),
              );
            }

            final params = query!;
            final reportAsync = ref.watch(weeklyEmotionReportProvider(params));

            return reportAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _ReportError(
                message: error.toString(),
                onRetry: () =>
                    ref.refresh(weeklyEmotionReportProvider(params)),
              ),
              data: (report) => RefreshIndicator(
                onRefresh: () => ref
                    .refresh(weeklyEmotionReportProvider(params).future),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _WeekRangeHeader(
                        start: report.weekStart,
                        end: report.weekEnd,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      WeeklyTemperatureGauge(
                        temperature: report.temperature,
                        mainEmotion: report.mainEmotion,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      WeeklyEmotionBadges(
                        badge: report.badge,
                        mainEmotion: report.mainEmotion,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      WeeklySummaryBubbles(
                        summaryBubbles: report.summaryBubbles,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _WeekRangeHeader extends StatelessWidget {
  const _WeekRangeHeader({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.bgLightPink,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '주간 감정 리포트',
            style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${_formatDate(start)} - ${_formatDate(end)}',
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportError extends StatelessWidget {
  const _ReportError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            color: AppColors.accentRed,
            size: 48,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.body,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            text: '다시 시도',
            variant: ButtonVariant.secondaryRed,
            onTap: onRetry,
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year.$month.$day';
}
