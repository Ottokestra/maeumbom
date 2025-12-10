import 'package:flutter/material.dart';
import '../../ui/app_ui.dart';

/// 채팅 알람 다이얼로그 헬퍼 클래스
///
/// 봄이 채팅에서 알람 설정 시 사용하는 다이얼로그를 관리합니다.
class ChatAlarmDialogs {
  /// 알람 설정 확인 다이얼로그
  ///
  /// [alarmInfo]: 알람 정보 (data, message 등)
  /// [replyText]: 봄이의 답변 텍스트
  /// [onConfirm]: 확인 버튼 클릭 시 콜백
  static void showAlarmConfirmDialog(
    BuildContext context, {
    required Map<String, dynamic> alarmInfo,
    required String replyText,
    VoidCallback? onConfirm,
  }) {
    final data = alarmInfo['data'] as List?;

    // 🔍 디버그: 받은 알람 데이터 출력
    print('[ChatAlarmDialogs] 🔔 Alarm Info: $alarmInfo');
    if (data != null) {
      for (var alarm in data) {
        print('[ChatAlarmDialogs] 📅 Alarm Data: $alarm');
      }
    }

    // 알람 정보 텍스트 생성
    final alarmDetailsText = _buildAlarmDetailsText(data);

    MessageDialogHelper.showGreenConfirm(
      context,
      icon: Icons.alarm_rounded,
      title: '알람 설정',
      message: '$replyText\n\n$alarmDetailsText',
      primaryButtonText: '확인',
      secondaryButtonText: '취소',
      onPrimaryPressed: () {
        Navigator.pop(context);

        // 저장 완료 피드백
        TopNotificationManager.show(
          context,
          message: '알람이 설정되었습니다.',
          type: TopNotificationType.green,
          duration: const Duration(milliseconds: 2000),
        );

        // 추가 콜백 실행
        onConfirm?.call();
      },
      onSecondaryPressed: () {
        Navigator.pop(context);
      },
    );
  }

  /// 알람 경고 다이얼로그
  ///
  /// [alarmInfo]: 알람 정보 (message 포함)
  static void showAlarmWarningDialog(
    BuildContext context, {
    required Map<String, dynamic> alarmInfo,
  }) {
    final message =
        alarmInfo['message'] as String? ?? '알람은 한번의 요청에서 세개까지만 등록이 가능합니다.';

    print('[ChatAlarmDialogs] ⚠️ Warning: $message');

    MessageDialogHelper.showRedAlert(
      context,
      icon: Icons.warning_rounded,
      title: '알람 등록 제한',
      message: message,
      primaryButtonText: '확인',
    );
  }

  /// 알람 상세 정보 텍스트 생성
  static String _buildAlarmDetailsText(List? data) {
    if (data == null || data.isEmpty) {
      return '알람 정보가 없습니다.';
    }

    final buffer = StringBuffer();

    for (var i = 0; i < data.length; i++) {
      final alarm = data[i];
      final month = alarm['month'] ?? 0;
      final day = alarm['day'] ?? 0;
      final time = alarm['time'] ?? 0;
      final minute = alarm['minute'] ?? 0;
      final amPm = alarm['am_pm'] ?? 'am';

      // 🔍 디버그: 각 필드 확인
      print(
          '[ChatAlarmDialogs] 📅 month: $month, day: $day, time: $time, minute: $minute, am_pm: $amPm');

      if (time == 0 && minute == 0) {
        buffer.write('$month월 $day일 (시간 정보 없음)');
      } else {
        final amPmText = amPm == 'am' ? '오전' : '오후';
        buffer.write('$month월 $day일 $amPmText $time시 $minute분');
      }

      // 마지막 항목이 아니면 줄바꿈 추가
      if (i < data.length - 1) {
        buffer.write('\n');
      }
    }

    return buffer.toString();
  }
}
