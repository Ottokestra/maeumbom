import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ui/app_ui.dart';
import '../../core/services/navigation/navigation_service.dart';
import '../../providers/alarm_provider.dart';
import '../../data/models/alarm/alarm_model.dart';

class AlarmScreen extends ConsumerStatefulWidget {
  const AlarmScreen({super.key});

  @override
  ConsumerState<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends ConsumerState<AlarmScreen> {
  @override
  void initState() {
    super.initState();
    // 알람 목록 로드
    Future.microtask(() => ref.read(alarmProvider.notifier).loadAlarms());
  }

  @override
  void dispose() {
    // 화면 종료 시 알림도 함께 제거
    TopNotificationManager.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final navigationService = NavigationService(context, ref);
    final alarmState = ref.watch(alarmProvider);

    return AppFrame(
      topBar: TopBar(
        title: '알람',
      ),
      bottomBar: BottomMenuBar(
        currentIndex: 2,
        onTap: (index) {
          navigationService.navigateToTab(index);
        },
      ),
      body: alarmState.when(
        data: (alarms) => _buildAlarmList(alarms),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(
            '오류가 발생했습니다: $error',
            style: AppTypography.body.copyWith(color: AppColors.errorRed),
          ),
        ),
      ),
    );
  }

  Widget _buildAlarmList(List<AlarmModel> alarms) {
    if (alarms.isEmpty) {
      return Center(
        child: Text(
          '등록된 알람이 없습니다.',
          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: alarms.length,
      itemBuilder: (context, index) {
        final alarm = alarms[index];
        return _buildAlarmItem(alarm);
      },
    );
  }

  Widget _buildAlarmItem(AlarmModel alarm) {
    return Dismissible(
      key: Key(alarm.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.md),
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.errorRed,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: const Icon(Icons.delete, color: AppColors.pureWhite),
      ),
      onDismissed: (direction) {
        ref.read(alarmProvider.notifier).deleteAlarm(alarm.id);
        TopNotificationManager.show(
          context,
          message: '알람이 삭제되었습니다.',
          actionLabel: '실행취소',
          type: TopNotificationType.red,
          onActionTap: () {
            // TODO: 실행취소 구현 (삭제된 알람 복구)
          },
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alarm.timeString,
                    style: AppTypography.h3.copyWith(
                      color: alarm.isEnabled
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    alarm.dateString,
                    style: AppTypography.body.copyWith(
                      color: alarm.isEnabled
                          ? AppColors.textSecondary
                          : AppColors.disabledText,
                    ),
                  ),
                  if (alarm.week.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      alarm.weekString,
                      style: AppTypography.caption.copyWith(
                        color: alarm.isEnabled
                            ? AppColors.textSecondary
                            : AppColors.disabledText,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Switch(
              value: alarm.isEnabled,
              activeTrackColor: AppColors.accentRed,
              onChanged: (value) {
                ref.read(alarmProvider.notifier).toggleAlarm(alarm.id, value);
              },
            ),
          ],
        ),
      ),
    );
  }
}
