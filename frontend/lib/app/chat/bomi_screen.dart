import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../ui/app_ui.dart';
import '../../ui/layout/bottom_voice_bar.dart';
import '../../providers/chat_provider.dart';
import '../../core/services/navigation/navigation_service.dart';
import 'components/bomi_content.dart';

/// Bomi Screen - ai 봄이 화면
///
/// AI 봄이와 대화하는 메인 화면입니다.
/// 음성 입력과 텍스트 입력을 모두 지원합니다.
class BomiScreen extends ConsumerStatefulWidget {
  const BomiScreen({super.key});

  @override
  ConsumerState<BomiScreen> createState() => _BomiScreenState();
}

class _BomiScreenState extends ConsumerState<BomiScreen> {
  bool _showInputBar = true; // true: input bar, false: voice bar
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _handleTextModeToggle() async {
    // 🆕 음성 대화가 진행 중이면 중지
    final chatState = ref.read(chatProvider);
    if (chatState.voiceState != VoiceInterfaceState.idle) {
      try {
        await ref.read(chatProvider.notifier).stopAudioRecording();
        print('[BomiScreen] 음성 대화 중지 (텍스트 모드로 전환)');
      } catch (e) {
        print('[BomiScreen] 음성 중지 실패: $e');
      }
    }

    setState(() {
      _showInputBar = true;
    });
  }

  void _handleVoiceModeToggle() {
    setState(() {
      _showInputBar = false;
    });
  }

  Future<void> _handleVoiceInput() async {
    final chatNotifier = ref.read(chatProvider.notifier);
    final chatState = ref.read(chatProvider);

    if (chatState.voiceState == VoiceInterfaceState.listening ||
        chatState.voiceState == VoiceInterfaceState.processing ||
        chatState.voiceState == VoiceInterfaceState.replying) {
      // 진행 중인 작업 중지 (녹음/재생 등)
      try {
        await chatNotifier.stopAudioRecording();
      } catch (e) {
        if (mounted) {
          _showErrorNotification('중지 실패: ${e.toString()}');
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
          _showErrorNotification(e.toString());
        }
      }
    }
  }

  /// 에러 알림 표시 (TopNotification)
  void _showErrorNotification(String message) {
    if (!mounted) return;

    TopNotificationManager.show(
      context,
      message: message,
      type: TopNotificationType.red,
      duration: const Duration(milliseconds: 3000),
    );
  }

  /// 마이크 권한 요청 다이얼로그 표시
  Future<void> _showPermissionDialog() async {
    if (!mounted) return;

    await showAdaptiveDialog(
      context: context,
      builder: (context) => AlertDialog.adaptive(
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

  /// 텍스트 메시지 전송
  Future<void> _handleSendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final chatNotifier = ref.read(chatProvider.notifier);

    _textController.clear();

    try {
      await chatNotifier.sendTextMessage(text);
    } catch (e) {
      if (mounted) {
        _showErrorNotification('메시지 전송 실패: ${e.toString()}');
      }
    }
  }

  /// 🆕 음성 대화 중지 후 네비게이션
  Future<void> _stopVoiceAndNavigate(VoidCallback navigation) async {
    final chatState = ref.read(chatProvider);

    // 음성 대화가 진행 중이면 중지
    if (chatState.voiceState != VoiceInterfaceState.idle) {
      try {
        await ref.read(chatProvider.notifier).stopAudioRecording();
        print('[BomiScreen] 음성 대화 중지 (네비게이션)');
      } catch (e) {
        print('[BomiScreen] 음성 중지 실패: $e');
      }
    }

    // 네비게이션 실행
    navigation();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final navigationService = NavigationService(context, ref);

    return AppFrame(
      resizeToAvoidBottomInset: true, // 키보드 올라올 때 화면 조정
      topBar: TopBar(
        title: '',
        leftIcon: Icons.arrow_back_ios,
        rightIcon: Icons.more_horiz,
        onTapLeft: () =>
            _stopVoiceAndNavigate(() => navigationService.navigateToTab(0)),
        onTapRight: () =>
            _stopVoiceAndNavigate(() => MoreMenuSheet.show(context)),
      ),
      bottomBar: _showInputBar
          ? BottomInputBar(
              controller: _textController,
              hintText: '메시지를 입력하세요',
              onSend: _handleSendMessage,
              onMicTap: _handleVoiceModeToggle,
            )
          : BottomVoiceBar(
              voiceState: chatState.voiceState,
              onMicTap: _handleVoiceInput,
              onTextModeTap: _handleTextModeToggle,
            ),
      body: BomiContent(
        showInputBar: _showInputBar,
        onTextInputTap: _handleTextModeToggle,
        onVoiceToggle: _handleVoiceInput,
      ),
    );
  }
}
