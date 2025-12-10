import 'dart:async';
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

  Future<void> _showPermissionDialog() async {
    if (!mounted) return;

    // 네이티브 스타일의 다이얼로그 표시
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

  Future<void> _handleSendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final chatNotifier = ref.read(chatProvider.notifier);

    _textController.clear();

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
    final chatState = ref.watch(chatProvider);

    return AppFrame(
      topBar: TopBar(
        title: '',
        rightIcon: Icons.more_horiz,
        onTapRight: () => MoreMenuSheet.show(context),
      ),
      bottomBar: BottomInputBar(
        onVoiceActivated: _handleVoiceInput,
        onTextActivated: _handleTextInputToggle,
        onVoiceReset: _handleVoiceInput,
        onTextReset: _handleTextInputToggle,
        voiceState: chatState.voiceState,
        controller: _textController,
        hintText: '메시지를 입력하세요',
        onSend: _handleSendMessage,
      ),
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
  Timer? _textCompletionTimer;
  bool _showTextCompletion = false;
  bool _callbacksRegistered = false; // 🆕 Alarm callback registration flag

  @override
  void dispose() {
    _textCompletionTimer?.cancel();
    super.dispose();
  }

  // 🆕 Alarm dialog display methods
  void _showAlarmDialog(Map<String, dynamic> alarmInfo, String replyText) {
    if (!mounted) return;

    print('[BomiContent] 🔔 Showing alarm dialog!');
    showDialog(
      context: context,
      builder: (context) => _buildAlarmDialog(alarmInfo, replyText),
    );
  }

  void _showWarningDialog(Map<String, dynamic> alarmInfo) {
    if (!mounted) return;

    print('[BomiContent] ⚠️ Showing warning dialog!');
    showDialog(
      context: context,
      builder: (context) => _buildWarningDialog(alarmInfo),
    );
  }

  // 🆕 Alarm dialog builder (copied from alarm_dialog.dart logic)
  Widget _buildAlarmDialog(Map<String, dynamic> alarmInfo, String replyText) {
    final data = alarmInfo['data'] as List?;

    // 🔍 디버그: 받은 알람 데이터 출력
    print('[BomiContent] 🔔 Alarm Info: $alarmInfo');
    if (data != null) {
      for (var alarm in data) {
        print('[BomiContent] 📅 Alarm Data: $alarm');
      }
    }

    return AlertDialog(
      title: const Text('알람 설정'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(replyText),
          const SizedBox(height: 16),
          if (data != null)
            ...data.map((alarm) {
              final month = alarm['month'] ?? 0;
              final day = alarm['day'] ?? 0;
              final time = alarm['time'] ?? 0;
              final minute = alarm['minute'] ?? 0;
              final amPm = alarm['am_pm'] ?? 'am';

              // 🔍 디버그: 각 필드 확인
              print(
                  '[BomiContent] 📅 month: $month, day: $day, time: $time, minute: $minute, am_pm: $amPm');

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  time == 0 && minute == 0
                      ? '$month월 $day일 (시간 정보 없음)'
                      : '$month월 $day일 ${amPm == 'am' ? '오전' : '오후'} $time시 $minute분',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            }),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            // 🆕 저장 완료 피드백 (TopNotification 사용)
            TopNotificationManager.show(
              context,
              message: '알람이 설정되었습니다.',
              type: TopNotificationType.green,
              duration: const Duration(milliseconds: 2000),
            );
          },
          child: const Text('확인'),
        ),
      ],
    );
  }

  Widget _buildWarningDialog(Map<String, dynamic> alarmInfo) {
    final message =
        alarmInfo['message'] as String? ?? '알람은 한번의 요청에서 세개까지만 등록이 가능합니다.';

    return AlertDialog(
      title: const Text('경고'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('확인'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final voiceState = chatState.voiceState;
    final isLoading = chatState.isLoading;

    // 🆕 Register alarm dialog callbacks once
    if (!_callbacksRegistered) {
      ref.read(chatProvider.notifier).onShowAlarmDialog = _showAlarmDialog;
      ref.read(chatProvider.notifier).onShowWarningDialog = _showWarningDialog;
      _callbacksRegistered = true;
      print('[BomiContent] ✅ Alarm dialog callbacks registered');
    }

    // Determine Mode
    ProcessMode mode;
    if (widget.showInputBar ||
        (isLoading && voiceState == VoiceInterfaceState.idle)) {
      mode = ProcessMode.text;
    } else {
      mode = ProcessMode.voice;
    }

    // Determine Step
    ProcessStep currentStep = ProcessStep.standby;

    if (mode == ProcessMode.voice) {
      switch (voiceState) {
        case VoiceInterfaceState.loading:
          currentStep = ProcessStep.standby; // Backend 로딩 중에는 대기 상태로 표시
          break;
        case VoiceInterfaceState.idle:
          currentStep = ProcessStep.standby;
          break;
        case VoiceInterfaceState.listening:
          currentStep = ProcessStep.input;
          break;
        case VoiceInterfaceState.processing:
          currentStep = ProcessStep.analysis;
          break;
        case VoiceInterfaceState.replying:
          currentStep = ProcessStep.completion;
          break;
      }
    } else {
      // Text Mode
      if (isLoading) {
        currentStep = ProcessStep.analysis;
      } else if (_showTextCompletion) {
        currentStep = ProcessStep.completion;
      } else {
        currentStep = ProcessStep.standby;
      }
    }

    // State Listener for Text Completion Transient State
    ref.listen(chatProvider, (previous, next) {
      if (previous?.isLoading == true && next.isLoading == false) {
        // Just finished loading (likely text response if voiceState is idle)
        if (next.voiceState == VoiceInterfaceState.idle) {
          setState(() {
            _showTextCompletion = true;
          });
          _textCompletionTimer?.cancel();
          _textCompletionTimer = Timer(const Duration(seconds: 2), () {
            if (mounted) {
              setState(() {
                _showTextCompletion = false;
              });
            }
          });
        }
      }
    });

    // 가장 최근 AI 메시지 가져오기 (오디오 응답 대체용)
    final latestBotMessage =
        chatState.messages.where((msg) => !msg.isUser).lastOrNull;

    final botMessageText = latestBotMessage?.text ??
        '오늘 하루 어떠셨나요? 대화를 진행해볼까요? 아래 마이크나 텍스트 버튼을 눌러 시작해보세요.';

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
                  // 1. 감정 캐릭터 (중앙, 큰 사이즈) - Lottie 애니메이션
                  AnimatedCharacter(
                    characterId: 'relief',
                    emotion: 'anger', // happiness, sadness, anger, fear
                    size: 300,
                    repeat: true,
                    animate: true,
                  ),

                  const SizedBox(height: AppSpacing.xs),

                  // 2. Process Indicator
                  //tts 사용 여부 추가 예정
                  ProcessIndicator(
                    mode: mode,
                    currentStep: currentStep,
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // 3. AI 봄이 메시지 버블 (최신 AI 응답 표시)
                  EmotionBubble(
                    message: botMessageText,
                    enableTypingAnimation: latestBotMessage != null,
                    key: ValueKey(latestBotMessage?.id ?? 'default'),
                  ),

                  // ✅ Phase 3: STT Partial 결과 표시
                  if (chatState.sttPartialText != null &&
                      chatState.sttPartialText!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.bgLightPink.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(
                            color: AppColors.accentRed.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.mic,
                              size: 16,
                              color: AppColors.accentRed,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(
                                chatState.sttPartialText!,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textSecondary,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
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
