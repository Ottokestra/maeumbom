import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../ui/app_ui.dart';
import '../../../providers/chat_provider.dart';
import '../chat_alarm_dialogs.dart';
import '../helpers/animation_state_helper.dart';
import '../helpers/process_state_helper.dart';

/// Bomi Content - 봄이 화면 본문
///
/// 캐릭터 애니메이션, ProcessIndicator, 메시지 버블을 포함하는
/// 봄이 화면의 메인 콘텐츠 위젯입니다.
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
  bool _callbacksRegistered = false;

  @override
  void dispose() {
    _textCompletionTimer?.cancel();
    super.dispose();
  }

  /// Alarm 다이얼로그 표시
  void _showAlarmDialog(Map<String, dynamic> alarmInfo, String replyText) {
    if (!mounted) return;

    ChatAlarmDialogs.showAlarmConfirmDialog(
      context,
      alarmInfo: alarmInfo,
      replyText: replyText,
    );
  }

  /// Warning 다이얼로그 표시
  void _showWarningDialog(Map<String, dynamic> alarmInfo) {
    if (!mounted) return;

    ChatAlarmDialogs.showAlarmWarningDialog(
      context,
      alarmInfo: alarmInfo,
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final voiceState = chatState.voiceState;
    final isLoading = chatState.isLoading;

    // Alarm dialog callbacks 등록 (한 번만)
    if (!_callbacksRegistered) {
      ref.read(chatProvider.notifier).onShowAlarmDialog = _showAlarmDialog;
      ref.read(chatProvider.notifier).onShowWarningDialog = _showWarningDialog;
      _callbacksRegistered = true;
      print('[BomiContent] ✅ Alarm dialog callbacks registered');
    }

    // Process 모드 및 단계 결정
    final mode = ProcessStateHelper.determineMode(
      showInputBar: widget.showInputBar,
      isLoading: isLoading,
      voiceState: voiceState,
    );

    final currentStep = ProcessStateHelper.determineStep(
      mode: mode,
      voiceState: voiceState,
      isLoading: isLoading,
      showTextCompletion: _showTextCompletion,
      hasRecentMessage: chatState.messages.isNotEmpty,
    );

    // 애니메이션 상태 결정
    final animationState = AnimationStateHelper.determineState(
      voiceState: voiceState,
      isLoading: isLoading,
      error: chatState.error,
      messages: chatState.messages,
    );

    // 텍스트 완료 상태 리스너
    ref.listen(chatProvider, (previous, next) {
      if (previous?.isLoading == true && next.isLoading == false) {
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

    // 최신 AI 메시지
    final latestBotMessage =
        chatState.messages.where((msg) => !msg.isUser).lastOrNull;

    final botMessageText = latestBotMessage?.text ??
        '오늘 하루 어떠셨나요? 대화를 진행해볼까요? 아래 마이크나 텍스트 버튼을 눌러 시작해보세요.';

    return GestureDetector(
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
                  // 1. 캐릭터 + Process Indicator 레이어
                  _buildCharacterLayer(
                    mode: mode,
                    currentStep: currentStep,
                    animationState: animationState,
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // 2. AI 봄이 메시지 버블
                  EmotionBubble(
                    message: botMessageText,
                    enableTypingAnimation: latestBotMessage != null,
                    key: ValueKey(latestBotMessage?.id ?? 'default'),
                  ),

                  // 3. STT Partial 결과 표시
                  if (chatState.sttPartialText != null &&
                      chatState.sttPartialText!.isNotEmpty)
                    _buildSttPartialText(chatState.sttPartialText!),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 캐릭터 + ProcessIndicator 레이어 빌드
  Widget _buildCharacterLayer({
    required ProcessMode mode,
    required ProcessStep currentStep,
    required String animationState,
  }) {
    return SizedBox(
      height: 360, // Stack 전체 높이 (캐릭터 300 + 여유 60)
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // 캐릭터 애니메이션
          Positioned(
            top: 50, // 캐릭터를 아래로 이동
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeInOut,
              switchOutCurve: Curves.easeInOut,
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale:
                        Tween<double>(begin: 0.95, end: 1.0).animate(animation),
                    child: child,
                  ),
                );
              },
              child: AnimatedCharacter(
                key: ValueKey(animationState),
                characterId: 'relief',
                emotion: animationState,
                size: animationState == 'basic' ? 270 : 300,
                repeat: true,
                animate: true,
              ),
            ),
          ),

          // Process Indicator (텍스트 모드일 때만 표시)
          if (mode == ProcessMode.text)
            Positioned(
              top: 0,
              child: ProcessIndicator(
                mode: mode,
                currentStep: currentStep,
              ),
            ),
        ],
      ),
    );
  }

  /// STT Partial 텍스트 빌드
  Widget _buildSttPartialText(String text) {
    return Padding(
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
                text,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
