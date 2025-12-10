import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ui/app_ui.dart';
import '../../ui/components/chat_bubble.dart';
import '../../ui/widgets/alarm_dialog.dart'; // 🆕
import '../../providers/chat_provider.dart';
import '../../data/models/chat/chat_message.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String? sessionId;

  const ChatScreen({
    super.key,
    this.sessionId,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // 세션 ID가 전달되면 해당 세션 로드
    if (widget.sessionId != null) {
      // 빌드 후 실행되도록 microtask 사용
      Future.microtask(() {
        ref.read(chatProvider.notifier).loadSession(widget.sessionId!);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    // 세션 ID가 전달되어 들어온 경우 나갈 때 리셋
    if (widget.sessionId != null) {
       // ref.read(chatProvider.notifier).resetSession(); 
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // NavigationService에서 이미 인증 체크를 완료했으므로
    // 여기서는 chatProvider를 안전하게 watch할 수 있습니다.
    final chatState = ref.watch(chatProvider);

    return AppFrame(
      topBar: TopBar(
        title: '대화 내용 확인', // Title changed to reflect read-only nature
        leftIcon: Icons.arrow_back,
        rightIcon: null, // Removed more action
        onTapLeft: () => Navigator.pop(context),
      ),
      // bottomBar 제거 (읽기 전용)
      bottomBar: null, 
      body: PopScope(
        onPopInvoked: (didPop) {
          if (didPop && widget.sessionId != null) {
             ref.read(chatProvider.notifier).resetSession();
          }
        },
        child: ChatContent(
          messages: chatState.messages,
          isLoading: chatState.isLoading,
          scrollController: _scrollController,
        ),
      ),
    );
  }
}

/// Chat Content - 채팅 본문
class ChatContent extends StatelessWidget {
  final List<ChatMessage> messages;
  final bool isLoading;
  final ScrollController scrollController;

  const ChatContent({
    super.key,
    required this.messages,
    required this.isLoading,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgBasic,
      child: Scrollbar(
        controller: scrollController,
        thumbVisibility: true,
        thickness: 4.0,
        radius: const Radius.circular(2.0),
        child: ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: messages.length + (isLoading ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == messages.length && isLoading) {
              return const _LoadingBubble();
            }
            return ChatBubble(message: messages[index]);
          },
        ),
      ),
    );
  }
}

/// Loading Bubble
class _LoadingBubble extends StatelessWidget {
  const _LoadingBubble();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.pureWhite,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ],
      ),
    );
  }
}
