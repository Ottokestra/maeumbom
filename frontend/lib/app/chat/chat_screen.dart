import 'package:flutter/material.dart';
import '../../ui/app_ui.dart';

/// Chat Screen - 채팅 화면
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [
    ChatMessage(
      text: '안녕하세요! 오늘 하루는 어떠셨나요?',
      isUser: false,
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
    ChatMessage(
      text: '오늘은 조금 힘든 하루였어요.',
      isUser: true,
      timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
    ),
    ChatMessage(
      text: '힘드셨군요. 어떤 일이 있으셨는지 편하게 이야기해 주세요.',
      isUser: false,
      timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
    ),
    ChatMessage(
      text: '업무가 많아서 스트레스를 많이 받았어요. 그래도 이야기를 나누니 조금 나아지는 것 같아요.',
      isUser: true,
      timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
    ),
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _handleSend() {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      _messages.add(
        ChatMessage(
          text: _messageController.text,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
    });

    _messageController.clear();

    // 자동 응답 시뮬레이션
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(
              text: '말씀해 주셔서 감사합니다. 계속 이야기 나눠요.',
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppFrame(
      topBar: TopBar(
        title: '채팅',
        leftIcon: Icons.arrow_back,
        rightIcon: Icons.more_horiz,
        onTapLeft: () => Navigator.pop(context),
        onTapRight: () {
          // TODO: 더보기 메뉴 표시
        },
      ),
      bottomBar: BottomInputBar(
        controller: _messageController,
        hintText: '메시지를 입력하세요',
        onSend: _handleSend,
      ),
      body: const ChatContent(),
    );
  }
}

/// Chat Content - 채팅 본문
class ChatContent extends StatelessWidget {
  const ChatContent({super.key});

  @override
  Widget build(BuildContext context) {
    // 부모 위젯의 state 접근
    final chatState = context.findAncestorStateOfType<_ChatScreenState>();
    final messages = chatState?._messages ?? [];

    return Container(
      color: AppColors.bgBasic,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        reverse: false,
        itemCount: messages.length,
        itemBuilder: (context, index) {
          return ChatBubble(message: messages[index]);
        },
      ),
    );
  }
}

/// Chat Bubble - 말풍선
class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.message,
  });

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser) ...[
            // 상대방 프로필 아이콘
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppColors.accentRed,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.person,
                  color: AppColors.textWhite,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          // 말풍선
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: message.isUser
                    ? AppColors.accentRed
                    : AppColors.pureWhite,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(AppRadius.md),
                  topRight: const Radius.circular(AppRadius.md),
                  bottomLeft: message.isUser
                      ? const Radius.circular(AppRadius.md)
                      : Radius.zero,
                  bottomRight: message.isUser
                      ? Radius.zero
                      : const Radius.circular(AppRadius.md),
                ),
                border: message.isUser
                    ? null
                    : Border.all(
                        color: AppColors.borderLight,
                        width: 1,
                      ),
              ),
              child: Text(
                message.text,
                style: AppTypography.body.copyWith(
                  color: message.isUser
                      ? AppColors.textWhite
                      : AppColors.textPrimary,
                ),
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: AppSpacing.xs),
            // 내 프로필 아이콘
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppColors.natureGreen,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.person,
                  color: AppColors.textWhite,
                  size: 20,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Chat Message Model
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
