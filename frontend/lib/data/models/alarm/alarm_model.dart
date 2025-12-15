import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:drift/drift.dart' hide JsonKey;
import '../../local/database/app_database.dart';

part 'alarm_model.freezed.dart';
part 'alarm_model.g.dart';

/// 아이템 타입 enum
enum ItemType {
  memory,  // 기억
  alarm,   // 알림
  event;   // 이벤트

  String get label {
    switch (this) {
      case ItemType.memory:
        return '기억';
      case ItemType.alarm:
        return '알림';
      case ItemType.event:
        return '이벤트';
    }
  }

  /// 타입별 배경색
  Color get backgroundColor {
    switch (this) {
      case ItemType.memory:
        return const Color(0xFFFFE8EA); // 연한 핑크
      case ItemType.alarm:
        return const Color(0xFFFFF4E6); // 연한 노랑/오렌지
      case ItemType.event:
        return const Color(0xFFE8F0FF); // 연한 파랑
    }
  }

  /// 타입별 텍스트 색상
  Color get textColor {
    switch (this) {
      case ItemType.memory:
        return const Color(0xFFD7454D); // 진한 핑크
      case ItemType.alarm:
        return const Color(0xFFFFB84C); // 진한 노랑/오렌지
      case ItemType.event:
        return const Color(0xFF6C8CD5); // 진한 파랑
    }
  }

  /// 토글 필요 여부
  bool get needsToggle {
    return this == ItemType.alarm;
  }
}

/// 알림 도메인 모델
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
    @Default(ItemType.alarm) ItemType itemType, // 기본값: 알림
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
      itemType: ItemType.alarm, // 기본값
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

    // itemType 파싱 (기본값: alarm)
    ItemType itemType = ItemType.alarm;
    if (alarmData['item_type'] != null) {
      final typeStr = alarmData['item_type'] as String;
      itemType = ItemType.values.firstWhere(
        (e) => e.name == typeStr,
        orElse: () => ItemType.alarm,
      );
    }

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
      title: alarmData['name'] as String? ?? '마음봄 알림', // 🆕 백엔드에서 name 사용
      content: '알림 시간입니다.',
      isDeleted: false,
      createdAt: DateTime.now(),
      createdBy: userId,
      updatedAt: DateTime.now(),
      updatedBy: userId,
      itemType: itemType,
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

  /// 알림 시간 문자열 (UI 표시용)
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
