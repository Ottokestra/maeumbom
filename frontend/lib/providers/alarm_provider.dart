import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/local/database/app_database.dart';
import '../data/repository/alarm/alarm_repository.dart';
import '../data/models/alarm/alarm_model.dart';
import '../core/services/alarm/alarm_notification_service.dart';
import 'auth_provider.dart';

// ----- Infrastructure Providers -----

/// Database Provider
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

/// Alarm Repository Provider
final alarmRepositoryProvider = Provider<AlarmRepository>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return AlarmRepository(database);
});

/// Alarm Notification Service Provider
final alarmNotificationServiceProvider =
    Provider<AlarmNotificationService>((ref) {
  return AlarmNotificationService();
});

// ----- State Providers -----

/// Alarm State Notifier
class AlarmNotifier extends StateNotifier<AsyncValue<List<AlarmModel>>> {
  final AlarmRepository _repository;
  final AlarmNotificationService _notificationService;
  final int? _userId;

  AlarmNotifier(this._repository, this._notificationService, this._userId)
      : super(const AsyncValue.loading()) {
    loadAlarms();
  }

  /// 알람 목록 로드
  Future<void> loadAlarms() async {
    state = const AsyncValue.loading();
    try {
      final alarms = await _repository.getAllAlarms();
      state = AsyncValue.data(alarms);
    } catch (e, stack) {
      print('[AlarmProvider] Failed to load alarms: $e');
      state = AsyncValue.error(e, stack);
    }
  }

  /// 알람 추가 (백엔드 alarm_info에서)
  Future<void> addAlarms(List<Map<String, dynamic>> alarmDataList) async {
    try {
      for (final alarmData in alarmDataList) {
        // 유효한 알람만 저장
        final isValid = alarmData['is_valid_alarm'] as bool? ?? false;
        if (!isValid) {
          print('[AlarmProvider] Skipping invalid alarm: $alarmData');
          continue;
        }

        final alarm = AlarmModel.fromAlarmInfo(alarmData, userId: _userId);

        // DB 저장
        final id = await _repository.insertAlarm(alarm, userId: _userId);
        print('[AlarmProvider] Alarm saved with ID: $id');

        // 푸시 알림 예약
        final savedAlarm = await _repository.getAlarmById(id);
        if (savedAlarm != null) {
          await _notificationService.scheduleAlarm(savedAlarm);
          print('[AlarmProvider] Notification scheduled for alarm ID: $id');
        }
      }

      // 목록 새로고침
      await loadAlarms();
    } catch (e, stack) {
      print('[AlarmProvider] Failed to add alarms: $e');
      state = AsyncValue.error(e, stack);
    }
  }

  /// 알람 ON/OFF 토글
  Future<void> toggleAlarm(int id, bool isEnabled) async {
    try {
      await _repository.updateAlarmEnabled(
        id,
        isEnabled: isEnabled,
        userId: _userId,
      );

      final alarm = await _repository.getAlarmById(id);
      if (alarm != null) {
        if (isEnabled) {
          await _notificationService.scheduleAlarm(alarm);
          print('[AlarmProvider] Alarm enabled and scheduled: $id');
        } else {
          await _notificationService.cancelAlarm(alarm.notificationId);
          print('[AlarmProvider] Alarm disabled and cancelled: $id');
        }
      }

      await loadAlarms();
    } catch (e, stack) {
      print('[AlarmProvider] Failed to toggle alarm: $e');
      state = AsyncValue.error(e, stack);
    }
  }

  /// 알람 삭제 (소프트 삭제)
  Future<void> deleteAlarm(int id) async {
    try {
      final alarm = await _repository.getAlarmById(id);
      if (alarm != null) {
        await _notificationService.cancelAlarm(alarm.notificationId);
        print('[AlarmProvider] Notification cancelled for alarm ID: $id');
      }

      await _repository.deleteAlarm(id, userId: _userId);
      print('[AlarmProvider] Alarm deleted: $id');

      await loadAlarms();
    } catch (e, stack) {
      print('[AlarmProvider] Failed to delete alarm: $e');
      state = AsyncValue.error(e, stack);
    }
  }

  /// 모든 알람 삭제
  Future<void> deleteAllAlarms() async {
    try {
      await _notificationService.cancelAllAlarms();
      await _repository.deleteAllAlarms(userId: _userId);
      print('[AlarmProvider] All alarms deleted');

      await loadAlarms();
    } catch (e, stack) {
      print('[AlarmProvider] Failed to delete all alarms: $e');
      state = AsyncValue.error(e, stack);
    }
  }

  /// 과거 알람 정리
  Future<void> cleanupPastAlarms() async {
    try {
      await _repository.cleanupPastAlarms(userId: _userId);
      print('[AlarmProvider] Past alarms cleaned up');

      await loadAlarms();
    } catch (e, stack) {
      print('[AlarmProvider] Failed to cleanup past alarms: $e');
      state = AsyncValue.error(e, stack);
    }
  }

  /// 앱 재시작 시 알람 재스케줄링
  Future<void> rescheduleAllAlarms() async {
    try {
      final alarms = await _repository.getEnabledAlarms();
      print('[AlarmProvider] Rescheduling ${alarms.length} alarms');

      for (final alarm in alarms) {
        // 과거 시간이 아닌 경우만 재스케줄링
        if (alarm.scheduledDatetime.isAfter(DateTime.now())) {
          await _notificationService.scheduleAlarm(alarm);
        }
      }

      print('[AlarmProvider] All alarms rescheduled');
    } catch (e) {
      print('[AlarmProvider] Failed to reschedule alarms: $e');
    }
  }
}

/// Alarm Provider
final alarmProvider =
    StateNotifierProvider<AlarmNotifier, AsyncValue<List<AlarmModel>>>((ref) {
  final repository = ref.watch(alarmRepositoryProvider);
  final notificationService = ref.watch(alarmNotificationServiceProvider);
  final currentUser = ref.watch(currentUserProvider);

  return AlarmNotifier(repository, notificationService, currentUser?.id);
});

/// Convenience Providers

/// 활성화된 알람만 조회
final enabledAlarmsProvider = Provider<List<AlarmModel>>((ref) {
  final alarmState = ref.watch(alarmProvider);
  return alarmState.maybeWhen(
    data: (alarms) => alarms.where((alarm) => alarm.isEnabled).toList(),
    orElse: () => [],
  );
});

/// 알람 개수
final alarmCountProvider = Provider<int>((ref) {
  final alarmState = ref.watch(alarmProvider);
  return alarmState.maybeWhen(
    data: (alarms) => alarms.length,
    orElse: () => 0,
  );
});

/// 활성화된 알람 개수
final enabledAlarmCountProvider = Provider<int>((ref) {
  final enabledAlarms = ref.watch(enabledAlarmsProvider);
  return enabledAlarms.length;
});
