import 'package:flutter/material.dart';
import 'package:frontend/ui/tokens/app_tokens.dart';

/// 시스템 메시지 말풍선 타입
enum SystemBubbleType {
  /// 정보성 메시지
  info,

  /// 성공 메시지
  success,

  /// 경고 메시지
  warning,
}

/// 시스템 메시지를 표시하는 말풍선 위젯
///
/// 시스템 안내, 피드백, 시간 표시 등에 사용합니다.
/// 중앙 정렬되며 작은 크기로 표시됩니다.
///
/// 사용 예시:
/// ```dart
/// // 정보 메시지
/// SystemBubble(
///   text: '금주의 감정: 기쁨 😊',
///   type: SystemBubbleType.info,
/// )
///
/// // 성공 메시지
/// SystemBubble(
///   text: '감정 기록이 저장되었습니다',
///   type: SystemBubbleType.success,
/// )
///
/// // 경고 메시지
/// SystemBubble(
///   text: '네트워크 연결을 확인해주세요',
///   type: SystemBubbleType.warning,
/// )
/// ```
class SystemBubble extends StatelessWidget {
  /// 표시할 텍스트
  final String text;

  /// 말풍선 타입
  final SystemBubbleType type;

  const SystemBubble({
    super.key,
    required this.text,
    this.type = SystemBubbleType.info,
  });

  /// 타입에 따른 배경색 반환
  Color _getBackgroundColor() {
    switch (type) {
      case SystemBubbleType.info:
        return BubbleTokens.systemBgInfo;
      case SystemBubbleType.success:
        return BubbleTokens.systemBgSuccess;
      case SystemBubbleType.warning:
        return BubbleTokens.systemBgWarning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Container(
        padding: BubbleTokens.systemPadding,
        decoration: BoxDecoration(
          color: _getBackgroundColor(),
          borderRadius: BorderRadius.circular(BubbleTokens.systemRadius),
        ),
        child: Text(
          text,
          style: AppTypography.caption.copyWith(
            color: BubbleTokens.systemText,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
