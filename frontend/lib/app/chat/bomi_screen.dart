import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../ui/app_ui.dart';
import '../../ui/layout/bottom_voice_bar.dart';
import '../../ui/components/message_dialog.dart';
import '../../providers/chat_provider.dart';
import '../../providers/routine_provider.dart';
import '../../core/services/navigation/navigation_service.dart';
import '../../core/utils/bomi_reaction_generator.dart';
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
  String? _typingReaction; // 입력 반응 메시지
  String? _generatedReaction; // 생성된 반응 메시지 저장 (재사용용)

  @override
  void initState() {
    super.initState();
    // 루틴 데이터 미리 로드 (백그라운드)
    Future.microtask(() {
      ref.read(routineProvider.notifier).loadLatest();
    });
  }

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

  /// 입력 시작 시 반응 메시지 생성
  void _handleTypingStarted() {
    print('[BomiScreen] 🎯 _handleTypingStarted called!');
    
    // 이미 생성된 반응이 있으면 재사용 (지우고 다시 입력해도 같은 메시지 유지)
    if (_generatedReaction != null) {
      print('[BomiScreen] Reusing existing reaction: $_generatedReaction');
      setState(() {
        _typingReaction = _generatedReaction;
      });
      return;
    }
    
    // 채팅 메시지가 이미 있으면 반응 메시지를 표시하지 않음 (첫 대화에서만 표시)
    final chatState = ref.read(chatProvider);
    if (chatState.messages.isNotEmpty) {
      print('[BomiScreen] Messages exist (${chatState.messages.length}), skipping reaction');
      return;
    }
    
    // 루틴 데이터 조회
    final routineState = ref.read(routineProvider);
    final routineData = routineState.value;
    
    print('[BomiScreen] Routine data: ${routineData?.routines.length ?? 0} routines');

    // 반응 메시지 생성 및 저장
    final reaction = BomiReactionGenerator.generate(routineData: routineData);
    
    print('[BomiScreen] Generated new reaction: $reaction');

    _generatedReaction = reaction; // 저장 (재사용용)
    
    setState(() {
      _typingReaction = reaction;
    });
    
    print('[BomiScreen] State updated with reaction: $_typingReaction');
  }

  /// 텍스트 메시지 전송
  Future<void> _handleSendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final chatNotifier = ref.read(chatProvider.notifier);

    _textController.clear();

    // 반응 메시지 제거 및 생성된 반응 초기화 (다음 대화를 위해)
    setState(() {
      _typingReaction = null;
      _generatedReaction = null; // 초기화
    });

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

  /// 대화 종료 확인 다이얼로그 표시
  /// 
  /// BomiReactionGenerator를 사용하여 랜덤 메시지를 생성합니다.
  /// MessageDialog 컴포넌트를 사용하여 마음봄 디자인 시스템을 준수합니다.
  /// 
  /// 반환: true (나가기), false (계속 대화), null (취소)
  Future<bool?> _showExitDialog(BuildContext context) async {
    final message = BomiReactionGenerator.generateExitConfirmation();
    
    bool? result;
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => MessageDialog(
        title: message['title']!,
        message: message['content']!,
        primaryButtonText: '응, 다음에 봐',
        secondaryButtonText: '조금 더 있을래',
        onPrimaryPressed: () {
          result = true;
          Navigator.pop(context);
        },
        onSecondaryPressed: () {
          result = false;
          Navigator.pop(context);
        },
        type: MessageDialogType.red,
      ),
    );
    
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final navigationService = NavigationService(context, ref);

    return PopScope(
      canPop: false, // 자동 뒤로가기 방지
      onPopInvoked: (bool didPop) async {
        if (didPop) return;
        
        // 대화 내용이 있는 경우에만 팝업 표시
        if (chatState.messages.isNotEmpty) {
          final shouldExit = await _showExitDialog(context);
          if (shouldExit == true) {
            // 세션 리셋 (메시지 삭제 + 새 세션 생성)
            await ref.read(chatProvider.notifier).resetSession();
            
            // 음성 대화 중지 후 홈으로 이동
            if (context.mounted) {
              await _stopVoiceAndNavigate(() => navigationService.navigateToTab(0));
            }
          }
        } else {
          // 대화 내용이 없으면 바로 나가기 (세션 유지)
          await _stopVoiceAndNavigate(() => navigationService.navigateToTab(0));
        }
      },
      child: AppFrame(
        resizeToAvoidBottomInset: false, // 키보드 처리를 수동으로 제어
        backgroundColor: AppColors.basicColor, //**배경색**
        topBar: TopBar(
          title: '',
          leftIcon: Icons.arrow_back_ios,
          rightIcon: Icons.more_horiz,
          onTapLeft: () {
            // PopScope가 처리하도록 Navigator.maybePop 호출
            Navigator.maybePop(context);
          },
          onTapRight: () =>
              _stopVoiceAndNavigate(() => MoreMenuSheet.show(context)),
          backgroundColor: AppColors.basicColor, //**배경색**
          foregroundColor: AppColors.textPrimary,
        ),
      bottomBar: _showInputBar
          ? BottomInputBar(
              controller: _textController,
              hintText: '메시지를 입력하세요',
              backgroundColor: AppColors.basicColor, //**배경색**
              onSend: _handleSendMessage,
              onMicTap: _handleVoiceModeToggle,
              onTypingStarted: _handleTypingStarted, // 🆕 입력 시작 콜백
            )
          : BottomVoiceBar(
              voiceState: chatState.voiceState,
              backgroundColor: AppColors.basicColor,
              onMicTap: _handleVoiceInput,
              onTextModeTap: _handleTextModeToggle,
            ),
        body: Column(
          children: [
            Expanded(
              child: BomiContent(
                showInputBar: _showInputBar,
                onTextInputTap: _handleTextModeToggle,
                onVoiceToggle: _handleVoiceInput,
                typingReaction: _typingReaction, // 🆕 입력 반응 메시지
              ),
            ),
          ],
        ),
      ),
    );
  }
}
