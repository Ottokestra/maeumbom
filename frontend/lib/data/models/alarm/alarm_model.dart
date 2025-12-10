import 'dart:convert';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:drift/drift.dart' hide JsonKey;
import '../../local/database/app_database.dart';

part 'alarm_model.freezed.dart';
part 'alarm_model.g.dart';

/// 알람 도메인 모델
/// Drift의 AlarmData를 래핑하여 비즈니스 로직에서 사용
@freezed
class AlarmModel with _$AlarmModel {
  const AlarmModel._();

  const factory AlarmModel({
    required int id,
    required int year,
    required int month,
    required int day,
    required List<String> week,
    required int time,
    required int minute,
    required String amPm,
    required bool isValid,
    required bool isEnabled,
    required int notificationId,
    required DateTime scheduledDatetime,
    String? title,
    String? content,
    required bool isDeleted,
    required DateTime createdAt,
    int? createdBy,
    required DateTime updatedAt,
    int? updatedBy,
  }) = _AlarmModel;

  /// Drift AlarmData에서 변환
  factory AlarmModel.fromDrift(AlarmData data) {
    return AlarmModel(
      id: data.id,
      year: data.year,
      month: data.month,
      day: data.day,
      week: _parseWeek(data.week),
      time: data.time,
      minute: data.minute,
      amPm: data.amPm,
      isValid: data.isValid,
      isEnabled: data.isEnabled,
      notificationId: data.notificationId,
      scheduledDatetime: data.scheduledDatetime,
      title: data.title,
      content: data.content,
      isDeleted: data.isDeleted,
      createdAt: data.createdAt,
      createdBy: data.createdBy,
      updatedAt: data.updatedAt,
      updatedBy: data.updatedBy,
    );
  }

  /// 백엔드 alarm_info 데이터에서 생성
  factory AlarmModel.fromAlarmInfo(
    Map<String, dynamic> alarmData, {
    int? userId,
  }) {
    final scheduledTime = _calculateScheduledTime(
      year: alarmData['year'] as int,
      month: alarmData['month'] as int,
      day: alarmData['day'] as int,
      time: alarmData['time'] as int,
      minute: alarmData['minute'] as int? ?? 0,
      amPm: alarmData['am_pm'] as String,
    );

    return AlarmModel(
      id: 0, // Auto-increment
      year: alarmData['year'] as int,
      month: alarmData['month'] as int,
      day: alarmData['day'] as int,
      week: (alarmData['week'] as List).cast<String>(),
      time: alarmData['time'] as int,
      minute: alarmData['minute'] as int? ?? 0,
      amPm: alarmData['am_pm'] as String,
      isValid: alarmData['is_valid_alarm'] as bool? ?? false,
      isEnabled: true,
      notificationId: DateTime.now().millisecondsSinceEpoch % 2147483647,
      scheduledDatetime: scheduledTime,
      title: null, // 백엔드에서 제공 예정
      content: null,
      isDeleted: false,
      createdAt: DateTime.now(),
      createdBy: userId,
      updatedAt: DateTime.now(),
      updatedBy: userId,
    );
  }

  /// JSON 직렬화 (필요시)
  factory AlarmModel.fromJson(Map<String, dynamic> json) =>
      _$AlarmModelFromJson(json);

  /// Drift Companion으로 변환 (DB 삽입용)
  AlarmsCompanion toCompanion({int? userId}) {
    return AlarmsCompanion.insert(
      year: year,
      month: month,
      day: day,
      week: jsonEncode(week),
      time: time,
      minute: minute,
      amPm: amPm,
      isValid: isValid,
      isEnabled: Value(isEnabled),
      notificationId: notificationId,
      scheduledDatetime: scheduledDatetime,
      title: Value(title),
      content: Value(content),
      isDeleted: Value(isDeleted),
      createdBy: Value(userId),
      updatedBy: Value(userId),
    );
  }

  /// 알람 시간 문자열 (UI 표시용)
  String get timeString {
    final amPmKr = amPm == 'am' ? '오전' : '오후';
    final minuteStr = minute.toString().padLeft(2, '0');
    return '$amPmKr $time:$minuteStr';
  }

  /// 날짜 문자열 (UI 표시용)
  String get dateString {
    return '$year년 $month월 $day일';
  }

  /// 요일 문자열 (UI 표시용)
  String get weekString {
    const weekMap = {
      'Monday': '월',
      'Tuesday': '화',
      'Wednesday': '수',
      'Thursday': '목',
      'Friday': '금',
      'Saturday': '토',
      'Sunday': '일',
    };
    return week.map((w) => weekMap[w] ?? w).join(', ');
  }

  /// Week JSON 문자열 파싱
  static List<String> _parseWeek(String weekJson) {
    try {
      return (jsonDecode(weekJson) as List).cast<String>();
    } catch (e) {
      return [];
    }
  }

  /// 12시간 형식을 24시간 DateTime으로 변환
  static DateTime _calculateScheduledTime({
    required int year,
    required int month,
    required int day,
    required int time,
    required int minute,
    required String amPm,
  }) {
    int hour24 = time;
    if (amPm == 'pm' && time != 12) {
      hour24 = time + 12;
    } else if (amPm == 'am' && time == 12) {
      hour24 = 0;
    }
    return DateTime(year, month, day, hour24, minute);
  }
}
