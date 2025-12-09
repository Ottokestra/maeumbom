import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ui/app_ui.dart';
import '../../core/services/navigation/navigation_service.dart';

// Dummy Model
class AlarmItemModel {
  final String id;
  final String title;
  final String schedule;
  bool isEnabled;

  AlarmItemModel({
    required this.id,
    required this.title,
    required this.schedule,
    this.isEnabled = true,
  });
}

class AlarmScreen extends ConsumerStatefulWidget {
  const AlarmScreen({super.key});

  @override
  ConsumerState<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends ConsumerState<AlarmScreen> {
  // Dummy Data
  final List<AlarmItemModel> _alarms = [
    AlarmItemModel(
      id: '1',
      title: '혈압약 먹기',
      schedule: '매일 09:00',
      isEnabled: true,
    ),
    AlarmItemModel(
      id: '2',
      title: '아침 운동가기',
      schedule: '매주 월, 목 10:00',
      isEnabled: true,
    ),
    AlarmItemModel(
      id: '3',
      title: '비타민 챙겨먹기',
      schedule: '매일 13:00',
      isEnabled: false,
    ),
    AlarmItemModel(
      id: '4',
      title: '저녁 산책',
      schedule: '매일 20:00',
      isEnabled: true,
    ),
  ];

  @override
  void dispose() {
    // 화면 종료 시 알림도 함께 제거
    TopNotificationManager.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final navigationService = NavigationService(context, ref);

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
      body: _alarms.isEmpty
          ? Center(
              child: Text(
                '등록된 알람이 없습니다.',
                style: AppTypography.body.copyWith(color: AppColors.textSecondary),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: _alarms.length,
              itemBuilder: (context, index) {
                final alarm = _alarms[index];
                return _buildAlarmItem(alarm);
              },
            ),
    );
  }

  Widget _buildAlarmItem(AlarmItemModel alarm) {
    return Dismissible(
      key: Key(alarm.id),
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
        setState(() {
          _alarms.removeWhere((item) => item.id == alarm.id);
        });
        // Use reusable TopNotificationManager
        TopNotificationManager.show(
          context,
          message: '${alarm.title} 알람이 삭제되었습니다.',
          actionLabel: '실행취소',
          type: TopNotificationType.red, // 기본값 (삭제 등 경고)
          onActionTap: () {
            setState(() {
              _alarms.add(alarm); 
            });
          },
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
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
                    alarm.title,
                    style: AppTypography.h3.copyWith(
                      color: alarm.isEnabled
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    alarm.schedule,
                    style: AppTypography.body.copyWith(
                      color: alarm.isEnabled
                          ? AppColors.textSecondary // Was grayNavy
                          : AppColors.disabledText, // Was textDisabled
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: alarm.isEnabled,
              activeColor: AppColors.accentRed,
              onChanged: (value) {
                setState(() {
                  alarm.isEnabled = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
