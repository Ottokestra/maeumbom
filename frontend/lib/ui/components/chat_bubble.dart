import 'package:flutter/material.dart';
import 'package:frontend/ui/tokens/app_tokens.dart';
import 'package:frontend/data/models/chat/chat_message.dart';

/// 채팅 메시지 말풍선 위젯
///
/// 사용자와 봄이(봇)의 메시지를 말풍선 형태로 표시합니다.
/// - 사용자: 우측 정렬, 빨간색 배경, 흰색 텍스트
/// - 봄이: 좌측 정렬, 흰색 배경, 테두리 있음
///
/// 사용 예시:
/// ```dart
/// // 사용자 메시지
/// ChatBubble(
///   message: ChatMessage(
///     text: '오늘 기분이 좋아요!',
///     isUser: true,
///     timestamp: DateTime.now(),
///   ),
/// )
///
/// // 봄이 메시지
/// ChatBubble(
///   message: ChatMessage(
///     text: '좋은 하루를 보내셨군요!',
///     isUser: false,
///     timestamp: DateTime.now(),
///   ),
/// )
/// ```
class ChatBubble extends StatelessWidget {
  /// 표시할 메시지
  final ChatMessage message;

  const ChatBubble({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxBubbleWidth = screenWidth * BubbleTokens.maxWidthRatio;

    return Padding(
      padding: EdgeInsets.only(bottom: BubbleTokens.bubbleSpacing),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxBubbleWidth,
            ),
            child: IntrinsicWidth(
              child: Column(
                crossAxisAlignment: message.isUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Message bubble
                  Container(
                    padding: BubbleTokens.chatPadding,
                    decoration: BoxDecoration(
                      color:
                          message.isUser ? BubbleTokens.userBg : BubbleTokens.botBg,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(BubbleTokens.chatRadius),
                        topRight: Radius.circular(BubbleTokens.chatRadius),
                        bottomLeft: message.isUser
                            ? Radius.circular(BubbleTokens.chatRadius)
                            : Radius.zero,
                        bottomRight: message.isUser
                            ? Radius.zero
                            : Radius.circular(BubbleTokens.chatRadius),
                      ),
                      border: message.isUser
                          ? null
                          : Border.all(
                              color: BubbleTokens.botBorder,
                              width: BubbleTokens.borderWidth,
                            ),
                    ),
                    child: Text(
                      message.text,
                      style: AppTypography.body.copyWith(
                        color: message.isUser
                            ? BubbleTokens.userText
                            : BubbleTokens.botText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
