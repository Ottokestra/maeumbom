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
  int _selectedListIndex = -1; // 선택된 리스트 항목 인덱스
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _textCompletionTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  /// Alarm 다이얼로그 표시 → TopNotification으로 변경
  void _showAlarmDialog(Map<String, dynamic> alarmInfo, String replyText) {
    if (!mounted) return;

    // 알람 정보 파싱
    final data = alarmInfo['data'] as List?;
    if (data == null || data.isEmpty) return;

    // 첫 번째 알람 정보 추출
    final firstAlarm = data[0];
    final name = firstAlarm['name'] as String? ?? '알람';
    final month = firstAlarm['month'] ?? 0;
    final day = firstAlarm['day'] ?? 0;
    final time = firstAlarm['time'] ?? 0;
    final minute = firstAlarm['minute'] ?? 0;
    final amPm = firstAlarm['am_pm'] ?? 'am';
    final amPmText = amPm == 'am' ? '오전' : '오후';

    // 간단한 알람 메시지 생성
    final alarmMessage = data.length > 1
        ? '$name 외 ${data.length - 1}개 | $month/$day $amPmText $time:${minute.toString().padLeft(2, '0')}'
        : '$name | $month/$day $amPmText $time:${minute.toString().padLeft(2, '0')}';

    // TopNotification으로 표시 (확인 버튼 누를 때까지 유지)
    TopNotificationManager.show(
      context,
      message: alarmMessage,
      actionLabel: '확인',
      type: TopNotificationType.green,
      duration: const Duration(hours: 1), // 매우 긴 시간 (사실상 수동으로만 제거)
      onActionTap: () {
        // 확인 버튼 클릭 시 알림 제거
        TopNotificationManager.remove();
      },
    );
  }

  /// 알람 확인 처리 (제거)
  // void _confirmAlarm() { ... }

  /// 알람 취소 처리 (제거)
  // void _cancelAlarm() { ... }

  /// Warning 다이얼로그 표시
  void _showWarningDialog(Map<String, dynamic> alarmInfo) {
    if (!mounted) return;

    ChatAlarmDialogs.showAlarmWarningDialog(
      context,
      alarmInfo: alarmInfo,
    );
  }

  /// 리스트 항목 선택 핸들러
  Future<void> _handleListItemSelected(String item) async {
    if (!mounted) return;

    // 선택한 항목을 서버로 전송
    try {
      await ref.read(chatProvider.notifier).sendTextMessage(item);
    } catch (e) {
      print('[BomiContent] ❌ Error sending list item: $e');
      if (mounted) {
        TopNotificationManager.show(
          context,
          message: '전송 실패: ${e.toString()}',
          type: TopNotificationType.red,
        );
      }
    }
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

      // 새 메시지가 추가되면 선택 상태 초기화
      if (previous != null &&
          previous.messages.length != next.messages.length) {
        setState(() {
          _selectedListIndex = -1;
        });
      }
    });

    // 최신 AI 메시지
    final latestBotMessage =
        chatState.messages.where((msg) => !msg.isUser).lastOrNull;

    final botMessageText = latestBotMessage?.text ??
        '오늘 하루 어떠셨나요? 대화를 진행해볼까요? 아래 마이크나 텍스트 버튼을 눌러 시작해보세요.';

    // response_type 확인
    final responseType = latestBotMessage?.responseType;
    final isListType = responseType == 'list';

    // list 타입일 때 요약 텍스트 추출 (첫 번째 줄 또는 번호 리스트 이전 텍스트)
    String getSummaryText(String fullText) {
      if (!isListType) return fullText;

      final lines = fullText.split('\n');
      final summaryLines = <String>[];

      for (final line in lines) {
        final trimmed = line.trim();
        // 번호 리스트가 시작되면 중단
        if (RegExp(r'^\d+\.\s+').hasMatch(trimmed)) {
          break;
        }
        // 빈 줄이 아니면 추가
        if (trimmed.isNotEmpty) {
          summaryLines.add(trimmed);
        }
      }

      return summaryLines.isEmpty ? fullText : summaryLines.join('\n');
    }

    final displayText = getSummaryText(botMessageText);

    // 디버깅 로그
    if (latestBotMessage != null) {
      print('[BomiContent] 🔍 Latest message meta: ${latestBotMessage.meta}');
      print('[BomiContent] 🔍 responseType: $responseType');
      print('[BomiContent] 🔍 isListType: $isListType');
      if (isListType) {
        print('[BomiContent] 📝 Summary text: $displayText');
      }
    }

    // 키보드 높이 감지
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    // 키보드가 나타날 때 스크롤 이동
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (keyboardHeight > 0 && _scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });

    return GestureDetector(
      onTap: () {
        if (widget.showInputBar) {
          widget.onTextInputTap();
        }
      },
      child: Container(
        color: AppColors.bgBasic,
        child: SafeArea(
          child: Scrollbar(
            thumbVisibility: isListType, // list 타입일 때만 스크롤바 표시
            thickness: 4.0,
            radius: const Radius.circular(8.0),
            controller: _scrollController,
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.md,
                  right: AppSpacing.md,
                  top: AppSpacing.sm,
                  bottom: AppSpacing.sm,
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

                    // 2. AI 봄이 메시지 버블 (일반 답변)
                    if (!isListType) ...[
                      // TTS 토글
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '목소리 듣기',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildToggle(
                            value: chatState.ttsEnabled,
                            onChanged: (value) {
                              ref
                                  .read(chatProvider.notifier)
                                  .toggleTtsEnabled();
                            },
                            style: ToggleStyle.primary(),
                          ),
                        ],
                      ),
                      // 메시지 버블
                      EmotionBubble(
                        message: displayText,
                        enableTypingAnimation: latestBotMessage != null,
                        key: ValueKey(latestBotMessage?.id ?? 'default'),
                        showTtsToggle: false,
                      ),
                    ],

                    // 2-1. 선택형 답변 (response_type: list)
                    if (isListType) ...[
                      // TTS 토글
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '목소리 듣기',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildToggle(
                            value: chatState.ttsEnabled,
                            onChanged: (value) {
                              ref
                                  .read(chatProvider.notifier)
                                  .toggleTtsEnabled();
                            },
                            style: ToggleStyle.primary(),
                          ),
                        ],
                      ),
                      // 안내 메시지 버블 (요약만 표시)
                      EmotionBubble(
                        message: displayText,
                        enableTypingAnimation: latestBotMessage != null,
                        key: ValueKey(
                            '${latestBotMessage?.id ?? 'default'}_intro'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      // 선택 가능한 리스트 버블
                      Builder(
                        builder: (context) {
                          final items = parseListItems(botMessageText);
                          print('[BomiContent] 📋 Parsed list items: $items');
                          print(
                              '[BomiContent] 📋 Items count: ${items.length}');

                          return ListBubble(
                            items: items,
                            selectedIndex: _selectedListIndex,
                            disabled: _selectedListIndex != -1,
                            onItemSelected: (index, item) {
                              setState(() {
                                _selectedListIndex = index;
                              });
                              // 선택한 항목을 서버로 전송
                              _handleListItemSelected(item);
                            },
                          );
                        },
                      ),
                    ],

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
      height: 350, // Stack 전체 높이 (캐릭터 300 + 여유 60)
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // 배경색 유지 (전환 중 하얀 화면 방지)
          Positioned.fill(
            child: Container(
              color: AppColors.bgBasic,
            ),
          ),

          // 캐릭터 애니메이션
          Positioned(
            top: 20, // 캐릭터를 아래로 이동
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
                size: 350,
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
            color: AppColors.primaryColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.mic,
              size: 16,
              color: AppColors.primaryColor,
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

  /// 토글 빌드 헬퍼
  Widget _buildToggle({
    required bool value,
    required ValueChanged<bool>? onChanged,
    required ToggleStyle style,
  }) {
    return Transform.scale(
      scale: style.scale,
      child: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: style.activeThumb,
        activeTrackColor: style.activeTrack,
        inactiveThumbColor: style.inactiveThumb,
        inactiveTrackColor: style.inactiveTrack,
      ),
    );
  }
}
