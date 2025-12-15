import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 알람 화면의 기준 날짜를 관리하는 Provider
/// 
/// 다른 페이지로 이동 후 돌아와도 선택한 날짜가 유지됩니다.
final alarmBaseDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});
