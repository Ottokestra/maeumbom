import 'dart:convert';
import 'package:drift/drift.dart';
import '../../local/database/app_database.dart';
import '../../models/alarm/alarm_model.dart';

/// 알람 Repository
/// Drift DB와 도메인 모델 간의 데이터 변환 및 CRUD 작업 담당
class AlarmRepository {
  final AppDatabase _database;

  AlarmRepository(this._database);

  /// 알람 저장 (표준 필드 포함)
  Future<int> insertAlarm(AlarmModel alarm, {int? userId}) async {
    final companion = AlarmsCompanion.insert(
      year: alarm.year,
      month: alarm.month,
      day: alarm.day,
      week: jsonEncode(alarm.week),
      time: alarm.time,
      minute: alarm.minute,
      amPm: alarm.amPm,
      isValid: alarm.isValid,
      isEnabled: Value(alarm.isEnabled),
      notificationId: alarm.notificationId,
      scheduledDatetime: alarm.scheduledDatetime,
      title: Value(alarm.title),
      content: Value(alarm.content),
      isDeleted: const Value(false),
      createdBy: Value(userId),
      updatedBy: Value(userId),
    );
    return await _database.insertAlarm(companion);
  }

  /// 모든 알람 조회 (삭제되지 않은 것만)
  Future<List<AlarmModel>> getAllAlarms() async {
    final results = await _database.getAllAlarms();
    return results.map((data) => AlarmModel.fromDrift(data)).toList();
  }

  /// 활성화된 알람만 조회
  Future<List<AlarmModel>> getEnabledAlarms() async {
    final results = await _database.getEnabledAlarms();
    return results.map((data) => AlarmModel.fromDrift(data)).toList();
  }

  /// 특정 알람 조회
  Future<AlarmModel?> getAlarmById(int id) async {
    final result = await _database.getAlarmById(id);
    return result != null ? AlarmModel.fromDrift(result) : null;
  }

  /// 알람 수정 (ON/OFF 토글)
  Future<void> updateAlarmEnabled(int id,
      {required bool isEnabled, int? userId}) async {
    final update = AlarmsCompanion(
      isEnabled: Value(isEnabled),
      updatedAt: Value(DateTime.now()),
      updatedBy: Value(userId),
    );
    await _database.updateAlarm(id, update);
  }

  /// 알람 전체 수정
  Future<void> updateAlarm(AlarmModel alarm, {int? userId}) async {
    final update = AlarmsCompanion(
      year: Value(alarm.year),
      month: Value(alarm.month),
      day: Value(alarm.day),
      week: Value(jsonEncode(alarm.week)),
      time: Value(alarm.time),
      minute: Value(alarm.minute),
      amPm: Value(alarm.amPm),
      isValid: Value(alarm.isValid),
      isEnabled: Value(alarm.isEnabled),
      notificationId: Value(alarm.notificationId),
      scheduledDatetime: Value(alarm.scheduledDatetime),
      title: Value(alarm.title),
      content: Value(alarm.content),
      updatedAt: Value(DateTime.now()),
      updatedBy: Value(userId),
    );
    await _database.updateAlarm(alarm.id, update);
  }

  /// 알람 삭제 (소프트 삭제)
  Future<void> deleteAlarm(int id, {int? userId}) async {
    await _database.deleteAlarm(id, userId: userId);
  }

  /// 모든 알람 삭제 (소프트 삭제)
  Future<void> deleteAllAlarms({int? userId}) async {
    final alarms = await getAllAlarms();
    for (final alarm in alarms) {
      await deleteAlarm(alarm.id, userId: userId);
    }
  }

  /// 과거 알람 정리 (소프트 삭제)
  Future<void> cleanupPastAlarms({int? userId}) async {
    final alarms = await getAllAlarms();
    final now = DateTime.now();

    for (final alarm in alarms) {
      if (alarm.scheduledDatetime.isBefore(now)) {
        await deleteAlarm(alarm.id, userId: userId);
      }
    }
  }

  /// 알람 개수 조회
  Future<int> getAlarmCount() async {
    final alarms = await getAllAlarms();
    return alarms.length;
  }

  /// 활성화된 알람 개수 조회
  Future<int> getEnabledAlarmCount() async {
    final alarms = await getEnabledAlarms();
    return alarms.length;
  }
}
