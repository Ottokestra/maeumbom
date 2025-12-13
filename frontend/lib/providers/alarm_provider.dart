import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/local/database/app_database.dart';
import '../data/repository/alarm/alarm_repository.dart';
import '../data/models/alarm/alarm_model.dart';
import '../core/services/alarm/alarm_manager_service.dart'; // 🆕 AlarmManager 사용
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

/// Alarm Manager Service Provider (🆕 신뢰할 수 있는 AlarmManager)
final alarmManagerServiceProvider = Provider<AlarmManagerService>((ref) {
  return AlarmManagerService();
});

// ----- State Providers -----

/// Alarm State Notifier
class AlarmNotifier extends StateNotifier<AsyncValue<List<AlarmModel>>> {
  final AlarmRepository _repository;
  final AlarmManagerService _alarmService;
  final int? _userId;

  AlarmNotifier(this._repository, this._alarmService, this._userId)
      : super(const AsyncValue.loading()) {
    _initialize();
  }

  /// 초기화: 알람 로드 및 재동기화
  Future<void> _initialize() async {
    await loadAlarms();

    // 🔧 Android AlarmManager 초기화: 오래된 알람 제거 후 DB 기반 재예약
    print('[AlarmProvider] Cleaning up Android AlarmManager...');
    await _alarmService.cancelAllAlarms();

    // 미래 알람만 재예약
    await _rescheduleValidAlarms();

    // 과거 알람 DB 정리
    await cleanupPastAlarms();

    print('[AlarmProvider] Initialization complete');
  }

  /// DB의 유효한 미래 알람만 재예약
  Future<void> _rescheduleValidAlarms() async {
    try {
      final alarms = await _repository.getEnabledAlarms();
      final now = DateTime.now();

      final futureAlarms = alarms
          .where((alarm) => alarm.scheduledDatetime.isAfter(now))
          .toList();

      print(
          '[AlarmProvider] Rescheduling ${futureAlarms.length} future alarms...');

      for (final alarm in futureAlarms) {
        await _alarmService.scheduleAlarm(alarm);
      }

      print('[AlarmProvider] ${futureAlarms.length} alarms rescheduled');
    } catch (e) {
      print('[AlarmProvider] Failed to reschedule valid alarms: $e');
    }
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
      // 권한 체크
      await _alarmService.initialize();

      final hasPermission = await _alarmService.checkPermissions();
      if (!hasPermission) {
        print('[AlarmProvider] ⚠️ Notification permission not granted');
        // 권한 요청
        final granted = await _alarmService.requestPermissions();
        if (!granted) {
          print('[AlarmProvider] ❌ Notification permission denied by user');
          state = AsyncValue.error(
            Exception('알림 권한이 필요합니다.\n설정 → 알림에서 알림을 허용해주세요.'),
            StackTrace.current,
          );
          return;
        }
      }

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
          await _alarmService.scheduleAlarm(savedAlarm);
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
          await _alarmService.scheduleAlarm(alarm);
          print('[AlarmProvider] Alarm enabled and scheduled: $id');
        } else {
          await _alarmService.cancelAlarm(alarm.notificationId);
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
        await _alarmService.cancelAlarm(alarm.notificationId);
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
      // 🆕 AlarmManager는 모두 취소가 없으므로 개별 취소
      // await _alarmService.cancelAllAlarms(); // Method 없음
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

  /// 앱 재시작 시 알람 재스케줄링 (수동 호출 전용)
  /// ⚠️ 일반적으로 필요 없음: android_alarm_manager_plus는 자동으로 알람 유지
  Future<void> rescheduleAllAlarms() async {
    try {
      final alarms = await _repository.getEnabledAlarms();
      final now = DateTime.now();

      // 과거 알람과 미래 알람 분리
      final futureAlarms = alarms
          .where((alarm) => alarm.scheduledDatetime.isAfter(now))
          .toList();

      final pastAlarms = alarms
          .where((alarm) => alarm.scheduledDatetime.isBefore(now))
          .toList();

      print('[AlarmProvider] Total alarms: ${alarms.length}');
      print('[AlarmProvider] Future alarms: ${futureAlarms.length}');
      print('[AlarmProvider] Past alarms: ${pastAlarms.length}');

      // 미래 알람만 재스케줄링
      for (final alarm in futureAlarms) {
        await _alarmService.scheduleAlarm(alarm);
      }

      print('[AlarmProvider] ${futureAlarms.length} alarms rescheduled');
    } catch (e) {
      print('[AlarmProvider] Failed to reschedule alarms: $e');
    }
  }
}

/// Alarm Provider
final alarmProvider =
    StateNotifierProvider<AlarmNotifier, AsyncValue<List<AlarmModel>>>((ref) {
  final repository = ref.watch(alarmRepositoryProvider);
  final alarmService = ref.watch(alarmManagerServiceProvider);
  final currentUser = ref.watch(currentUserProvider);

  return AlarmNotifier(repository, alarmService, currentUser?.id);
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
