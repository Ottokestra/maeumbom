import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ui/app_ui.dart';
import '../../ui/components/chat_bubble.dart';
import '../../ui/widgets/alarm_dialog.dart'; // 🆕
import '../../providers/chat_provider.dart';
import '../../data/models/chat/chat_message.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSend() {
    if (_messageController.text.trim().isEmpty) return;

    // Send message via provider
    ref.read(chatProvider.notifier).sendTextMessage(
          _messageController.text,
        );

    _messageController.clear();

    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollToBottom();
    });
  }

  void _handleMicrophoneToggle() async {
    final chatState = ref.read(chatProvider);

    if (chatState.isRecording) {
      // Stop recording
      try {
        await ref.read(chatProvider.notifier).stopAudioRecording();
      } catch (e) {
        _showError('녹음 중지 중 오류가 발생했습니다.');
      }
    } else {
      // Check permission first
      final hasPermission =
          await ref.read(chatProvider.notifier).hasMicrophonePermission();

      if (hasPermission) {
        // 권한이 있으면 바로 녹음 시작
        try {
          await ref.read(chatProvider.notifier).startAudioRecording();
        } catch (e) {
          _showError('녹음을 시작할 수 없습니다.');
        }
      } else {
        // 권한이 없으면 상태 확인
        final isPermanentlyDenied =
            await ref.read(chatProvider.notifier).isPermanentlyDenied();
        final isNeverRequested =
            await ref.read(chatProvider.notifier).isNeverRequested();

        if (isPermanentlyDenied) {
          // 영구적으로 거부된 경우 설정으로 이동 다이얼로그
          _showPermissionDialog();
        } else if (isNeverRequested) {
          // 처음 요청하는 경우 안내 다이얼로그 표시
          _showPermissionRequestDialog();
        } else {
          // 한 번 거부된 경우 다시 요청
          try {
            await ref.read(chatProvider.notifier).startAudioRecording();
          } catch (e) {
            _showPermissionDeniedDialog();
          }
        }
      }
    }
  }

  void _showPermissionRequestDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Text(
          '마음봄이(가) 마이크에 접근하려고 합니다.',
          style: AppTypography.h2,
          textAlign: TextAlign.center,
        ),
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Text(
            '음성 대화를 이용할 수 있습니다.\n(필수권한)',
            style: AppTypography.body,
            textAlign: TextAlign.center,
          ),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  ),
                  child: Text(
                    '허용 안 함',
                    style: AppTypography.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    // 권한 상태 다시 확인
                    final isPermanentlyDenied = await ref
                        .read(chatProvider.notifier)
                        .isPermanentlyDenied();

                    if (isPermanentlyDenied) {
                      // 이미 영구적으로 거부된 경우 설정 다이얼로그 표시
                      _showPermissionDialog();
                    } else {
                      // 시스템 권한 요청
                      try {
                        await ref
                            .read(chatProvider.notifier)
                            .startAudioRecording();
                      } catch (e) {
                        final errorMessage =
                            e.toString().replaceAll('Exception: ', '');
                        if (errorMessage.contains('PERMANENTLY_DENIED')) {
                          _showPermissionDialog();
                        } else if (errorMessage.contains('permission') ||
                            errorMessage.contains('권한') ||
                            errorMessage.contains('거부')) {
                          _showPermissionDeniedDialog();
                        } else {
                          _showError('녹음을 시작할 수 없습니다.');
                        }
                      }
                    }
                  },
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  ),
                  child: Text(
                    '허용',
                    style: AppTypography.body.copyWith(
                      color: AppColors.accentRed,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showPermissionDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '마이크 권한 필요',
          style: AppTypography.h2,
        ),
        content: Text(
          '음성 대화를 사용하려면 마이크 권한이 필요합니다.\n'
          '설정에서 마이크 권한을 허용해주세요.',
          style: AppTypography.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '취소',
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // 설정 화면으로 이동
              await ref.read(chatProvider.notifier).openAppSettings();
            },
            child: Text(
              '설정으로 이동',
              style: AppTypography.body.copyWith(
                color: AppColors.accentRed,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '마이크 권한 필요',
          style: AppTypography.h2,
        ),
        content: Text(
          '음성 대화를 사용하려면 마이크 권한이 필요합니다.\n'
          '권한을 허용해주세요.',
          style: AppTypography.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '확인',
              style: AppTypography.body.copyWith(
                color: AppColors.accentRed,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.errorRed,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // NavigationService에서 이미 인증 체크를 완료했으므로
    // 여기서는 chatProvider를 안전하게 watch할 수 있습니다.
    final chatState = ref.watch(chatProvider);

    return AppFrame(
      topBar: TopBar(
        title: '봄이와 대화',
        leftIcon: Icons.arrow_back,
        rightIcon: Icons.more_horiz,
        onTapLeft: () => Navigator.pop(context),
        onTapRight: () {
          // TODO: 더보기 메뉴 표시
        },
      ),
      bottomBar: BottomInputBar(
        onVoiceActivated: _handleMicrophoneToggle,
        onTextActivated: () {}, // 텍스트 모드 활성화 (자동 전환)
        onVoiceReset: _handleMicrophoneToggle,
        voiceState: chatState.voiceState,
        controller: _messageController,
        hintText: '메시지를 입력하세요',
        onSend: _handleSend,
      ),
      body: ChatContent(
        messages: chatState.messages,
        isLoading: chatState.isLoading,
        scrollController: _scrollController,
      ),
    );
  }

  // _buildRecordingBar() - 더 이상 사용하지 않음
  // 새로운 BottomInputBar가 녹음 상태를 자동으로 처리합니다.
  /*
  Widget _buildRecordingBar() {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      height: 100 + bottomPadding,
      padding: EdgeInsets.only(bottom: bottomPadding),
      color: AppColors.pureWhite,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.mic, color: AppColors.accentRed, size: 32),
          const SizedBox(width: 12),
          Text('녹음 중...', style: AppTypography.body),
          const SizedBox(width: 16),
          AppButton(
            text: '중지',
            variant: ButtonVariant.secondaryRed,
            onTap: _handleMicrophoneToggle,
          ),
        ],
      ),
    );
  }
  */
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
