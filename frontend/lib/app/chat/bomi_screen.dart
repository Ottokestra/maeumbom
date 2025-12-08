import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../ui/app_ui.dart';
import '../../providers/chat_provider.dart';

/// Bomi Screen - ai 봄이 화면
class BomiScreen extends ConsumerStatefulWidget {
  const BomiScreen({super.key});

  @override
  ConsumerState<BomiScreen> createState() => _BomiScreenState();
}

class _BomiScreenState extends ConsumerState<BomiScreen> {
  bool _showInputBar = false;
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _handleTextInputToggle() {
    setState(() {
      _showInputBar = !_showInputBar;
    });
  }

  Future<void> _handleVoiceInput() async {
    final chatNotifier = ref.read(chatProvider.notifier);
    final chatState = ref.read(chatProvider);

    // 음성 입력 시작 시 텍스트 입력 바 닫기
    if (_showInputBar) {
      _handleTextInputToggle(); // Toggle off
    }

    if (chatState.voiceState == VoiceInterfaceState.listening ||
        chatState.voiceState == VoiceInterfaceState.processing ||
        chatState.voiceState == VoiceInterfaceState.replying) {
      // 진행 중인 작업 중지 (녹음/재생 등)
      try {
        await chatNotifier.stopAudioRecording();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('중지 실패: ${e.toString()}'),
              backgroundColor: AppColors.errorRed,
            ),
          );
        }
      }
    } else {
      // 녹음 시작
      try {
        await chatNotifier.startAudioRecording();
      } catch (e) {
        if (!mounted) return;

        if (e.toString().contains('PERMANENTLY_DENIED')) {
          // 영구 거부 - 설정으로 이동 제안
          _showPermissionDialog();
        } else {
          // 일반 에러
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: AppColors.errorRed,
            ),
          );
        }
      }
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('마이크 권한 필요'),
        content: const Text(
          '음성 입력을 위해 마이크 권한이 필요합니다.\n설정에서 권한을 허용해주세요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await openAppSettings();
            },
            child: const Text('설정으로 이동'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final chatNotifier = ref.read(chatProvider.notifier);

    _textController.clear();
    // 텍스트 바 유지 (사용자 요청)

    try {
      await chatNotifier.sendTextMessage(text);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('메시지 전송 실패: ${e.toString()}'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppFrame(
      topBar: TopBar(
        title: '',
        rightIcon: Icons.more_horiz,
        onTapRight: () => MoreMenuSheet.show(context),
      ),
      bottomBar: _showInputBar
          ? BottomInputBar(
              controller: _textController,
              hintText: '메시지를 입력하세요',
              onSend: _handleSendMessage,
              onMicrophoneTap: _handleVoiceInput,
            )
          : null,
      body: BomiContent(
        showInputBar: _showInputBar,
        onTextInputTap: _handleTextInputToggle,
        onVoiceToggle: _handleVoiceInput,
      ),
    );
  }
}

/// Bomi Content - 홈 화면 본문
class BomiContent extends ConsumerStatefulWidget {
  final bool showInputBar;
  final VoidCallback onTextInputTap;
  final VoidCallback onVoiceToggle;

  const BomiContent({
    super.key,
    required this.showInputBar,
    required this.onTextInputTap,
    required this.onVoiceToggle,
  });

  @override
  ConsumerState<BomiContent> createState() => _BomiContentState();
}

class _BomiContentState extends ConsumerState<BomiContent> {
  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final voiceState = chatState.voiceState;

    // 가장 최근 AI 메시지 가져오기 (오디오 응답 대체용)
    final latestBotMessage =
        chatState.messages.where((msg) => !msg.isUser).lastOrNull;

    final botMessageText = latestBotMessage?.text ??
        '오늘 하루 어떠셨나요? 대화를 진행해볼까요? 아래 마이크나 텍스트 버튼을 눌러 시작해보세요.';

    String statusText;
    switch (voiceState) {
      case VoiceInterfaceState.listening:
        statusText = '듣고 있어요...';
        break;
      case VoiceInterfaceState.processing:
        statusText = '생각하는 중...';
        break;
      case VoiceInterfaceState.replying:
        statusText = '대답하는 중...';
        break;
      case VoiceInterfaceState.idle:
        statusText = '봄이와 대화해보세요';
        break;
    }

    return GestureDetector(
      // 화면의 다른 영역 탭 시 input bar 닫기
      onTap: () {
        if (widget.showInputBar) {
          widget.onTextInputTap();
        }
      },
      child: Container(
        color: AppColors.bgBasic,
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: AppSpacing.xs),

                  // 감정 캐릭터 (중앙, 큰 사이즈) - Lottie 애니메이션
                  AnimatedCharacter(
                    characterId: 'relief',
                    emotion: 'fear', // happiness, sedness, anger, fear
                    size: 350,
                    repeat: true,
                    animate: true,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // 봄이 메시지 버블 (최신 AI 응답 표시)
                  EmotionBubble(
                    message: botMessageText,
                    enableTypingAnimation: latestBotMessage != null,
                    key: ValueKey(latestBotMessage?.id ?? 'default'),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // 봄이 상태 표시용
                  Text(
                    statusText,
                    style: AppTypography.caption,
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  // 슬라이드 액션 버튼 (항상 표시, 상태 동기화)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: SlideToActionButton(
                      onVoiceActivated: widget.onVoiceToggle,
                      onTextActivated: widget.onTextInputTap,
                      onVoiceReset: widget.onVoiceToggle,
                      voiceState: voiceState,
                      isTextMode: widget.showInputBar,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
