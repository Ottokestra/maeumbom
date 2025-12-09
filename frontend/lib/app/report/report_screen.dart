import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/navigation/navigation_service.dart';
import '../../data/dtos/dashboard/emotion_history_entry.dart';
import '../../data/dtos/recommendation/recommendation_response.dart';
import '../../data/dtos/report/user_report_response.dart';
import '../../data/dtos/user_phase/user_pattern_setting_update.dart';
import '../../data/dtos/user_phase/user_pattern_setting_response.dart';
import '../../data/dtos/user_phase/user_phase_response.dart';
import '../../providers/report_provider.dart';
import '../../ui/app_ui.dart';
import '../../ui/characters/app_characters.dart';
import 'widgets/top_emotions_chart.dart';

/// Report Screen - 마음리포트 화면
class ReportScreen extends ConsumerWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationService = NavigationService(context, ref);
    final selectedRange = ref.watch(emotionHistoryRangeProvider);
    final historyAsync = ref.watch(emotionHistoryProvider(selectedRange));
    final phaseAsync = ref.watch(currentPhaseProvider);
    final settingsAsync = ref.watch(phaseSettingsProvider);

    return AppFrame(
      topBar: TopBar(
        title: '나의 감정 리포트',
        rightIcon: Icons.refresh,
        onTapRight: () {
          ref.refresh(emotionHistoryProvider(selectedRange));
          ref.refresh(currentPhaseProvider);
          ref.refresh(phaseSettingsProvider);
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
        child: historyAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ReportError(
            message: error.toString(),
            onRetry: () => ref.refresh(emotionHistoryProvider(selectedRange)),
          ),
          data: (history) => _ReportBody(
            history: history,
            selectedRange: selectedRange,
            phase: phaseAsync.valueOrNull,
            settings: settingsAsync.valueOrNull,
          ),
        ),
      ),
    );
  }
}

class _ReportBody extends ConsumerWidget {
  const _ReportBody({
    required this.history,
    required this.selectedRange,
    required this.phase,
    required this.settings,
  });

  final List<EmotionHistoryEntry> history;
  final EmotionHistoryRange selectedRange;
  final UserPhaseResponse? phase;
  final UserPatternSettingResponse? settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = _EmotionSummary.fromHistory(history);

    return RefreshIndicator(
      onRefresh: () async {
        await ref.refresh(emotionHistoryProvider(selectedRange).future);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RangeSelector(selectedRange: selectedRange),
            const SizedBox(height: AppSpacing.md),
            _EmotionHero(summary: summary),
            const SizedBox(height: AppSpacing.md),
            _SectionCard(
              title: '감정 흐름 요약',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PeriodDescription(range: selectedRange, summary: summary),
                  const SizedBox(height: AppSpacing.sm),
                  TopEmotionsChart(emotions: summary.topEmotions),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _SectionCard(
              title: '페이즈 상태',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (phase != null)
                    _PhaseStatusCard(phase: phase!)
                  else
                    _EmptyText('페이즈 정보를 불러오는 중입니다.'),
                  const SizedBox(height: AppSpacing.sm),
                  if (settings != null)
                    _PhaseSettingsCard(
                      settings: settings!,
                      onEdit: () => _showSettingsSheet(context, ref, settings!),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _SectionCard(
              title: '오늘의 맞춤 콘텐츠',
              child: _RecommendationButtons(
                summary: summary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _EmotionHero extends StatelessWidget {
  const _EmotionHero({required this.summary});

  final _EmotionSummary summary;

  @override
  Widget build(BuildContext context) {
    final dominant = summary.dominantEmotion ?? EmotionId.relief;
    final meta = emotionMetaMap[dominant]!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.bgWarm,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          EmotionCharacter(id: dominant, size: 96),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '대표 감정',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  meta.nameKo,
                  style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  summary.dominantLabel,
                  style: AppTypography.body,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _RangeSelector extends ConsumerWidget {
  const _RangeSelector({
    required this.selectedRange,
  });

  final EmotionHistoryRange selectedRange;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ranges = EmotionHistoryRange.values;
    final isSelected = ranges.map((range) => range == selectedRange).toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.warmWhite,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: ToggleButtons(
        isSelected: isSelected,
        onPressed: (index) {
          final range = ranges[index];
          ref.read(emotionHistoryRangeProvider.notifier).state = range;
          ref.refresh(emotionHistoryProvider(range));
        },
        borderRadius: BorderRadius.circular(AppRadius.lg),
        selectedColor: AppColors.pureWhite,
        color: AppColors.textSecondary,
        fillColor: AppColors.accentRed,
        constraints: const BoxConstraints(minHeight: 44),
        children: ranges
            .map(
              (range) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(
                  range.label,
                  style: AppTypography.bodyBold.copyWith(
                    color: selectedRange == range
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

class _PeriodDescription extends StatelessWidget {
  const _PeriodDescription({required this.range, required this.summary});

  final EmotionHistoryRange range;
  final _EmotionSummary summary;

  @override
  Widget build(BuildContext context) {
    final description = summary.totalEntries > 0
        ? '최근 ${range.label} 동안 가장 두드러진 감정 흐름을 요약했어요.'
        : '데이터가 아직 없어요. 감정 기록을 추가해보세요.';
    return Text(
      description,
      style: AppTypography.body.copyWith(color: AppColors.textSecondary),
    );
  }
}

class _PhaseStatusCard extends StatelessWidget {
  const _PhaseStatusCard({required this.phase});

  final UserPhaseResponse phase;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.bgBasic,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('현재 페이즈: ${phase.currentPhase}', style: AppTypography.bodyBold),
          const SizedBox(height: AppSpacing.xs),
          Text(
            phase.message,
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _PhaseSettingsCard extends StatelessWidget {
  const _PhaseSettingsCard({required this.settings, required this.onEdit});

  final UserPatternSettingResponse settings;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('기상/취침 시간', style: AppTypography.bodyBold),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '평일: ${settings.weekdayWakeTime} ~ ${settings.weekdaySleepTime}\n주말: ${settings.weekendWakeTime} ~ ${settings.weekendSleepTime}',
          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          text: '페이즈 설정 수정',
          variant: ButtonVariant.secondaryRed,
          onTap: onEdit,
        ),
      ],
    );
  }
}

class _RecommendationButtons extends ConsumerWidget {
  const _RecommendationButtons({required this.summary});

  final _EmotionSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payloadBase = {
      'emotion_label': summary.dominantLabel,
      'language': 'ko',
      'duration': 60,
      'prompt': 'report-screen',
    };

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: AppButton(
                text: '오늘의 명언',
                variant: ButtonVariant.secondaryRed,
                onTap: () => _requestRecommendation(
                  context,
                  ref,
                  () => ref
                      .read(recommendationRepositoryProvider)
                      .fetchQuote(payloadBase),
                  '오늘의 명언',
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AppButton(
                text: '오늘의 음악',
                variant: ButtonVariant.secondaryRed,
                onTap: () => _requestRecommendation(
                  context,
                  ref,
                  () => ref
                      .read(recommendationRepositoryProvider)
                      .fetchMusic(payloadBase),
                  '오늘의 음악',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          text: '위로 이미지',
          variant: ButtonVariant.secondaryRed,
          onTap: () => _requestRecommendation(
            context,
            ref,
            () => ref
                .read(recommendationRepositoryProvider)
                .fetchImage(payloadBase),
            '위로 이미지',
          ),
        ),
      ],
    );
  }

  Future<void> _requestRecommendation(
    BuildContext context,
    WidgetRef ref,
    Future<RecommendationResponse> Function() request,
    String title,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await request();
      if (context.mounted) Navigator.of(context).pop();
      if (!context.mounted) return;

      showModalBottomSheet(
        context: context,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
        builder: (_) => Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.h3),
              const SizedBox(height: AppSpacing.sm),
              if (response.title.isNotEmpty)
                Text(response.title, style: AppTypography.bodyBold),
              const SizedBox(height: AppSpacing.xs),
              Text(response.content, style: AppTypography.body),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                text: '닫기',
                variant: ButtonVariant.primaryRed,
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) Navigator.of(context).pop();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('추천을 불러오지 못했어요: $e')),
        );
      }
    }
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.h3),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

class _EmptyText extends StatelessWidget {
  const _EmptyText(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: AppTypography.body.copyWith(color: AppColors.textSecondary),
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
          Text(
            message,
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            text: '다시 시도',
            variant: ButtonVariant.primaryRed,
            onTap: onRetry,
          ),
        ],
      ),
    );
  }
}

class _EmotionSummary {
  _EmotionSummary({
    required this.dominantEmotion,
    required this.dominantLabel,
    required this.topEmotions,
    required this.totalEntries,
  });

  final EmotionId? dominantEmotion;
  final String dominantLabel;
  final List<TopEmotionItem> topEmotions;
  final int totalEntries;

  factory _EmotionSummary.fromHistory(List<EmotionHistoryEntry> history) {
    if (history.isEmpty) {
      return _EmotionSummary(
        dominantEmotion: EmotionId.relief,
        dominantLabel: '최근 감정 데이터가 없어요',
        topEmotions: const [],
        totalEntries: 0,
      );
    }

    final counter = <EmotionId, int>{};
    for (final entry in history) {
      final id = _mapEmotion(entry.primaryEmotionCode, entry.primaryEmotionGroup);
      counter.update(id, (value) => value + 1, ifAbsent: () => 1);
    }

    final sorted = counter.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = history.length;
    final topItems = sorted
        .map(
          (e) => TopEmotionItem(
            label: emotionMetaMap[e.key]?.nameKo ?? e.key.name,
            count: e.value,
            ratio: e.value / total,
          ),
        )
        .toList();

    final dominant = sorted.first.key;
    final label = emotionMetaMap[dominant]?.shortDesc ?? dominant.name;

    return _EmotionSummary(
      dominantEmotion: dominant,
      dominantLabel: label,
      topEmotions: topItems,
      totalEntries: total,
    );
  }
}

EmotionId _mapEmotion(String code, String group) {
  final normalized = code.toLowerCase();
  switch (normalized) {
    case 'joy':
    case 'happiness':
    case 'happy':
      return EmotionId.joy;
    case 'sadness':
    case 'sad':
      return EmotionId.sadness;
    case 'anger':
    case 'angry':
      return EmotionId.anger;
    case 'fear':
    case 'anxiety':
      return EmotionId.fear;
    case 'shame':
      return EmotionId.shame;
    case 'boredom':
      return EmotionId.boredom;
    default:
      if (group.toLowerCase() == 'positive') return EmotionId.joy;
      if (group.toLowerCase() == 'negative') return EmotionId.sadness;
      return EmotionId.relief;
  }
}

Future<void> _showSettingsSheet(
  BuildContext context,
  WidgetRef ref,
  UserPatternSettingResponse settings,
) async {
  final weekdayWake = TextEditingController(text: settings.weekdayWakeTime);
  final weekdaySleep = TextEditingController(text: settings.weekdaySleepTime);
  final weekendWake = TextEditingController(text: settings.weekendWakeTime);
  final weekendSleep = TextEditingController(text: settings.weekendSleepTime);
  bool isNightWorker = settings.isNightWorker;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
      ),
      child: StatefulBuilder(
        builder: (context, setState) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('페이즈 설정 수정', style: AppTypography.h3),
            const SizedBox(height: AppSpacing.sm),
            _SettingsField(label: '평일 기상 시간', controller: weekdayWake),
            _SettingsField(label: '평일 취침 시간', controller: weekdaySleep),
            _SettingsField(label: '주말 기상 시간', controller: weekendWake),
            _SettingsField(label: '주말 취침 시간', controller: weekendSleep),
            Row(
              children: [
                Checkbox(
                  value: isNightWorker,
                  onChanged: (value) => setState(() => isNightWorker = value ?? false),
                ),
                const Text('야간 근무자')
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              text: '저장',
              variant: ButtonVariant.primaryRed,
              onTap: () async {
                final update = UserPatternSettingUpdate(
                  weekdayWakeTime: weekdayWake.text,
                  weekdaySleepTime: weekdaySleep.text,
                  weekendWakeTime: weekendWake.text,
                  weekendSleepTime: weekendSleep.text,
                  isNightWorker: isNightWorker,
                );
                try {
                  await ref
                      .read(userPhaseRepositoryProvider)
                      .updateSettings(update);
                  if (context.mounted) {
                    ref.invalidate(phaseSettingsProvider);
                    Navigator.pop(context);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('설정을 저장하지 못했어요: $e')),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    ),
  );
}

class _SettingsField extends StatelessWidget {
  const _SettingsField({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      ),
    );
  }
}
