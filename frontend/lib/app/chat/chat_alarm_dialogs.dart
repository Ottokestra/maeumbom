import 'package:flutter/material.dart';
import '../../ui/app_ui.dart';

/// 채팅 알림 다이얼로그 헬퍼 클래스
///
/// 봄이 채팅에서 알림 설정 시 사용하는 다이얼로그를 관리합니다.
class ChatAlarmDialogs {
  /// 알림 경고 다이얼로그
  ///
  /// [alarmInfo]: 알림 정보 (message 포함)
  static void showAlarmWarningDialog(
    BuildContext context, {
    required Map<String, dynamic> alarmInfo,
  }) {
    final message =
        alarmInfo['message'] as String? ?? '알림은 한번의 요청에서 세개까지만 등록이 가능합니다.';

    print('[ChatAlarmDialogs] ⚠️ Warning: $message');

    MessageDialogHelper.showRedAlert(
      context,
      icon: Icons.warning_rounded,
      title: '알림 등록 제한',
      message: message,
      primaryButtonText: '확인',
    );
  }
}
