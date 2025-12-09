import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/navigation/navigation_service.dart';
import '../../data/dtos/report/user_report_response.dart';
import '../../providers/report_provider.dart';
import '../../ui/app_ui.dart';
import 'widgets/report_metric_card.dart';
import 'widgets/top_emotions_chart.dart';

/// Report Screen - 마음리포트 화면
class ReportScreen extends ConsumerWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationService = NavigationService(context, ref);
    final selectedPeriod = ref.watch(reportPeriodProvider);
    final reportAsync = ref.watch(userReportProvider(selectedPeriod));

    return AppFrame(
      topBar: TopBar(
        title: '나의 감정 리포트',
        rightIcon: Icons.refresh,
        onTapRight: () {
          ref.refresh(userReportProvider(selectedPeriod));
        },
      ),
      bottomBar: BottomMenuBar(
        currentIndex: 3,
        onTap: (index) {
          navigationService.navigateToTab(index);
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PeriodSelector(selectedPeriod: selectedPeriod),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: reportAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, stackTrace) => _ReportError(
                  message: error.toString(),
                  onRetry: () => ref.refresh(
                    userReportProvider(selectedPeriod),
                  ),
                ),
                data: (report) => _ReportDetail(
                  report: report,
                  period: selectedPeriod,
                  onRefresh: () async {
                    await ref.refresh(
                      userReportProvider(selectedPeriod).future,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodSelector extends ConsumerWidget {
  const _PeriodSelector({
    required this.selectedPeriod,
  });

  final ReportPeriod selectedPeriod;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final periods = ReportPeriod.values;
    final isSelected = periods.map((period) => period == selectedPeriod).toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.warmWhite,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: ToggleButtons(
        isSelected: isSelected,
        onPressed: (index) {
          final period = periods[index];
          ref.read(reportPeriodProvider.notifier).state = period;
          ref.refresh(userReportProvider(period));
        },
        borderRadius: BorderRadius.circular(AppRadius.lg),
        selectedColor: AppColors.pureWhite,
        color: AppColors.textSecondary,
        fillColor: AppColors.accentRed,
        constraints: const BoxConstraints(minHeight: 44),
        children: periods
            .map(
              (period) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(
                  period.label,
                  style: AppTypography.bodyBold.copyWith(
                    color: selectedPeriod == period
                        ? AppColors.pureWhite
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ReportDetail extends StatelessWidget {
  const _ReportDetail({
    required this.report,
    required this.period,
    this.onRefresh,
  });

  final UserReportResponse report;
  final ReportPeriod period;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh ?? () async {},
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PeriodSummary(
              period: period,
              report: report,
            ),
            const SizedBox(height: AppSpacing.md),
            _MetricsSection(metrics: report.metrics),
            const SizedBox(height: AppSpacing.md),
            _SectionCard(
              title: '주요 감정 비율',
              child: TopEmotionsChart(emotions: report.metrics.topEmotions),
            ),
            const SizedBox(height: AppSpacing.md),
            _SectionCard(
              title: '최근 하이라이트',
              child: _HighlightsList(highlights: report.recentHighlights),
            ),
            const SizedBox(height: AppSpacing.md),
            _SectionCard(
              title: '오늘의 제안',
              child: Text(
                report.recommendation,
                style: AppTypography.body.copyWith(height: 1.5),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}

class _PeriodSummary extends StatelessWidget {
  const _PeriodSummary({
    required this.period,
    required this.report,
  });

  final ReportPeriod period;
  final UserReportResponse report;

  @override
  Widget build(BuildContext context) {
    final rangeText =
        '${_formatDate(report.periodStart)} ~ ${_formatDate(report.periodEnd)}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.bgWarm,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            report.metrics.totalSessions > 0
                ? report.metrics.topEmotions.isNotEmpty
                    ? '이번 기간의 주요 감정 흐름을 살펴봤어요'
                    : '이 기간의 대화를 정리했어요'
                : '아직 데이터가 없어요',
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            rangeText,
            style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            period.description,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricsSection extends StatelessWidget {
  const _MetricsSection({required this.metrics});

  final EmotionMetric metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - AppSpacing.sm * 2) / 3;

        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            SizedBox(
              width: itemWidth,
              child: ReportMetricCard(
                title: '대화 세션 수',
                value: metrics.totalSessions.toString(),
                icon: Icons.chat_bubble_outline,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: ReportMetricCard(
                title: '대화 메시지 수',
                value: metrics.totalMessages.toString(),
                icon: Icons.message_outlined,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: ReportMetricCard(
                title: '평균 감정 점수',
                value: metrics.avgSentiment.toStringAsFixed(2),
                icon: Icons.favorite_border,
                subtitle: '1에 가까울수록 긍정적',
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HighlightsList extends StatelessWidget {
  const _HighlightsList({required this.highlights});

  final List<String> highlights;

  @override
  Widget build(BuildContext context) {
    if (highlights.isEmpty) {
      return Text(
        '최근 하이라이트가 아직 없어요.',
        style: AppTypography.body.copyWith(
          color: AppColors.textSecondary,
        ),
      );
    }

    return Column(
      children: highlights.map((text) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: AppSpacing.xs),
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.bgWarm,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Text(
            text,
            style: AppTypography.body.copyWith(height: 1.4),
          ),
        );
      }).toList(),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

class _ReportError extends StatelessWidget {
  const _ReportError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '리포트를 불러오지 못했어요.',
            style: AppTypography.bodyBold,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentRed,
              foregroundColor: AppColors.pureWhite,
            ),
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}.$month.$day';
}

