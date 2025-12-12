import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ui/app_ui.dart';
import '../../core/services/navigation/navigation_service.dart';
import '../../data/api/user_phase/user_phase_api_client.dart';
import '../../data/dtos/user_phase/user_pattern_setting_update.dart';
import '../../data/dtos/user_phase/user_pattern_setting_response.dart';
import '../../data/dtos/user_phase/health_sync_request.dart';
import '../../providers/auth_provider.dart';
import '../../core/utils/logger.dart';
import 'components/menu_list_item.dart';

/// 설정 화면
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  Future<void> _syncHealthData() async {
    final result = await _showHealthDataInputDialog();
    if (result == null) return;

    if (!mounted) return;

    try {
      final dio = ref.read(dioWithAuthProvider);
      final apiClient = UserPhaseApiClient(dio);

      final sleepStartTime = DateTime.parse(result.sleepStartTime!);
      final sleepEndTime = DateTime.parse(result.sleepEndTime!);
      final sleepStartHour = sleepStartTime.hour.toString().padLeft(2, '0');
      final sleepStartMinute =
          sleepStartTime.minute.toString().padLeft(2, '0');
      final sleepEndHour = sleepEndTime.hour.toString().padLeft(2, '0');
      final sleepEndMinute = sleepEndTime.minute.toString().padLeft(2, '0');

      // 기상/취침 시간 문자열 생성
      final wakeTimeStr = '$sleepEndHour:$sleepEndMinute';
      final sleepTimeStr = '$sleepStartHour:$sleepStartMinute';

      final today = DateTime.now();
      final isWeekend = today.weekday >= 6;

      UserPatternSettingResponse? currentSettings;
      try {
        currentSettings = await apiClient.getSettings();
      } catch (e) {
        appLogger
            .i('User settings not found, creating settings from input data');
        try {
          await apiClient.updateSettings(
            UserPatternSettingUpdate(
              weekdayWakeTime: isWeekend ? '07:00' : wakeTimeStr,
              weekdaySleepTime: isWeekend ? '23:00' : sleepTimeStr,
              weekendWakeTime: isWeekend ? wakeTimeStr : '09:00',
              weekendSleepTime: isWeekend ? sleepTimeStr : '01:00',
              isNightWorker: false,
            ),
          );
          appLogger.i('Settings created from input data');
        } catch (createError) {
          appLogger.e('Failed to create settings', error: createError);
          if (!mounted) return;
          TopNotificationManager.show(
            context,
            message: '사용자 설정 생성 실패',
            type: TopNotificationType.red,
          );
          return;
        }
      }

      if (currentSettings != null) {
        try {
          await apiClient.updateSettings(
            UserPatternSettingUpdate(
              weekdayWakeTime:
                  isWeekend ? currentSettings.weekdayWakeTime : wakeTimeStr,
              weekdaySleepTime:
                  isWeekend ? currentSettings.weekdaySleepTime : sleepTimeStr,
              weekendWakeTime:
                  isWeekend ? wakeTimeStr : currentSettings.weekendWakeTime,
              weekendSleepTime:
                  isWeekend ? sleepTimeStr : currentSettings.weekendSleepTime,
              isNightWorker: false,
            ),
          );
          appLogger.i('Settings updated with input data');
        } catch (updateError) {
          appLogger.e('Failed to update settings', error: updateError);
        }
      }

      await apiClient.syncHealthData(result);

      if (mounted) {
        TopNotificationManager.show(
          context,
          message: '건강 데이터가 동기화되었습니다.',
          type: TopNotificationType.green,
        );
      }
    } catch (e) {
      appLogger.e('Failed to sync health data', error: e);
      if (mounted) {
        TopNotificationManager.show(
          context,
          message: '건강 데이터 동기화 실패',
          type: TopNotificationType.red,
        );
      }
    }
  }

  Future<HealthSyncRequest?> _showHealthDataInputDialog() async {
    final now = DateTime.now();
    final today =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    // 기본값: 8시간 전 취침, 지금 기상
    final defaultSleepStart = now.subtract(const Duration(hours: 8));
    final defaultSleepEnd = now;

    final sleepStartController = TextEditingController(
      text:
          '${defaultSleepStart.hour.toString().padLeft(2, '0')}:${defaultSleepStart.minute.toString().padLeft(2, '0')}',
    );
    final sleepEndController = TextEditingController(
      text:
          '${defaultSleepEnd.hour.toString().padLeft(2, '0')}:${defaultSleepEnd.minute.toString().padLeft(2, '0')}',
    );
    final stepCountController = TextEditingController(text: '8500');
    final sleepDurationController = TextEditingController(text: '7.5');
    final heartRateAvgController = TextEditingController(text: '72');
    final heartRateRestingController = TextEditingController(text: '65');

    return showDialog<HealthSyncRequest>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('건강 데이터 입력'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: sleepStartController,
                decoration: const InputDecoration(
                  labelText: '취침 시간 (HH:MM)',
                  hintText: '23:00',
                ),
              ),
              TextField(
                controller: sleepEndController,
                decoration: const InputDecoration(
                  labelText: '기상 시간 (HH:MM)',
                  hintText: '07:00',
                ),
              ),
              TextField(
                controller: stepCountController,
                decoration: const InputDecoration(
                  labelText: '걸음 수',
                  hintText: '8500',
                ),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: sleepDurationController,
                decoration: const InputDecoration(
                  labelText: '수면 시간 (시간)',
                  hintText: '7.5',
                ),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: heartRateAvgController,
                decoration: const InputDecoration(
                  labelText: '평균 심박수',
                  hintText: '72',
                ),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: heartRateRestingController,
                decoration: const InputDecoration(
                  labelText: '안정시 심박수',
                  hintText: '65',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              try {
                // 시간 파싱
                final sleepStartParts = sleepStartController.text.split(':');
                final sleepEndParts = sleepEndController.text.split(':');

                final sleepStartHour = int.parse(sleepStartParts[0]);
                final sleepStartMinute = int.parse(sleepStartParts[1]);
                final sleepEndHour = int.parse(sleepEndParts[0]);
                final sleepEndMinute = int.parse(sleepEndParts[1]);

                // 날짜 계산 (취침 시간이 자정을 넘기면 전날)
                DateTime sleepStart = DateTime(now.year, now.month, now.day,
                    sleepStartHour, sleepStartMinute);
                if (sleepStartHour >= 12) {
                  // 오후 시간이면 전날로 간주
                  sleepStart = sleepStart.subtract(const Duration(days: 1));
                }

                DateTime sleepEnd = DateTime(
                    now.year, now.month, now.day, sleepEndHour, sleepEndMinute);
                if (sleepEndHour < sleepStartHour) {
                  // 기상 시간이 취침 시간보다 작으면 다음날
                  sleepEnd = sleepEnd.add(const Duration(days: 1));
                }

                final request = HealthSyncRequest(
                  logDate: today,
                  sleepStartTime: '${sleepStart.toIso8601String()}Z',
                  sleepEndTime: '${sleepEnd.toIso8601String()}Z',
                  stepCount: stepCountController.text.isNotEmpty
                      ? int.parse(stepCountController.text)
                      : null,
                  sleepDurationHours: sleepDurationController.text.isNotEmpty
                      ? double.parse(sleepDurationController.text)
                      : null,
                  heartRateAvg: heartRateAvgController.text.isNotEmpty
                      ? int.parse(heartRateAvgController.text)
                      : null,
                  heartRateResting: heartRateRestingController.text.isNotEmpty
                      ? int.parse(heartRateRestingController.text)
                      : null,
                  sourceType: 'manual',
                );

                // 다이얼로그 닫기 (controller는 다이얼로그가 닫힌 후 자동으로 정리됨)
                Navigator.pop(context, request);

                // 다이얼로그가 닫힌 후에 controller dispose
                Future.microtask(() {
                  sleepStartController.dispose();
                  sleepEndController.dispose();
                  stepCountController.dispose();
                  sleepDurationController.dispose();
                  heartRateAvgController.dispose();
                  heartRateRestingController.dispose();
                });
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('입력 형식이 올바르지 않습니다: ${e.toString()}')),
                );
              }
            },
            child: const Text('동기화'),
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final navigationService = NavigationService(context, ref);

    return AppFrame(
      topBar: TopBar(
        title: '설정',
        leftIcon: Icons.arrow_back,
        onTapLeft: () => Navigator.pop(context),
      ),
      bottomBar: BottomMenuBar(
        currentIndex: 4,
        onTap: (index) {
          navigationService.navigateToTab(index);
        },
      ),
      body: Container(
        color: AppColors.basicGray,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.sm),

                    // 연동 설정 섹션
                    Container(
                      color: AppColors.basicColor,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              left: AppSpacing.md,
                              top: 12,
                              bottom: 12,
                            ),
                            child: Text(
                              '서비스 연동',
                              style: AppTypography.bodySmall.copyWith(
                                color: const Color(0xFF697282),
                              ),
                            ),
                          ),
                          MenuListItem(
                            icon: Icons.monitor_heart_outlined,
                            label: '건강 데이터 연동',
                            onTap: _syncHealthData,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    // 약관 및 정책 섹션
                    Container(
                      color: AppColors.basicColor,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              left: AppSpacing.md,
                              top: 12,
                              bottom: 12,
                            ),
                            child: Text(
                              '약관 및 정책',
                              style: AppTypography.bodySmall.copyWith(
                                color: const Color(0xFF697282),
                              ),
                            ),
                          ),
                          MenuListItem(
                            icon: Icons.description_outlined,
                            label: '서비스 이용 약관',
                            onTap: () {
                              navigationService.navigateToRoute('/settings/terms');
                            },
                          ),
                          MenuListItem(
                            icon: Icons.privacy_tip_outlined,
                            label: '개인 정보 처리 방침',
                            onTap: () {
                              navigationService.navigateToRoute('/settings/privacy');
                            },
                          ),
                        ],
                      ),
                    ),

                    // 하단 여백
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
