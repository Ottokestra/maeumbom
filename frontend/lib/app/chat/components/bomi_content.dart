import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../ui/app_ui.dart';
import '../../../providers/chat_provider.dart';
import '../../../providers/daily_mood_provider.dart';
import '../../../core/utils/text_formatter.dart';
import '../chat_alarm_dialogs.dart';
import '../helpers/animation_state_helper.dart';
import '../helpers/process_state_helper.dart';
import '../helpers/status_message_helper.dart';
import '../../../ui/components/speech_bubble.dart';
import '../../../ui/components/choice_button.dart';
import '../../../ui/components/list_bubble.dart'; // parseListItems 함수를 위해 유지

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

  /// 감정에 따른 캐릭터 ID 결정
  /// - 긍정적 감정 (joy, excitement, confidence, love) → 'love'
  /// - 중립적 감정 (relief, enlightenment, interest) → 'relief'
  /// - 부정적 감정 (나머지) → 'sadness'
  String _getCharacterIdFromEmotion(EmotionId? emotion) {
    if (emotion == null) return 'love'; // 기본값

    switch (emotion) {
      // 긍정적 감정 → love 캐릭터
      case EmotionId.joy:
      case EmotionId.excitement:
      case EmotionId.confidence:
      case EmotionId.love:
        return 'love';

      // 중립적 감정 → relief 캐릭터
      case EmotionId.relief:
      case EmotionId.enlightenment:
      case EmotionId.interest:
        return 'relief';

      // 부정적 감정 → sadness 캐릭터
      case EmotionId.discontent:
      case EmotionId.shame:
      case EmotionId.sadness:
      case EmotionId.guilt:
      case EmotionId.depression:
      case EmotionId.boredom:
      case EmotionId.contempt:
      case EmotionId.anger:
      case EmotionId.fear:
      case EmotionId.confusion:
        return 'sadness';
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final dailyMoodState = ref.watch(dailyMoodProvider);
    final voiceState = chatState.voiceState;
    final isLoading = chatState.isLoading;

    // 선택된 감정에 따른 캐릭터 ID 결정
    final characterId = _getCharacterIdFromEmotion(dailyMoodState.selectedEmotion);

    // Alarm dialog callbacks 등록 (한 번만)
    if (!_callbacksRegistered) {
      ref.read(chatProvider.notifier).onShowAlarmDialog = _showAlarmDialog;
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

    // 🆕 상태 메시지 결정
    final statusMessage = StatusMessageHelper.getStatusMessage(
      voiceState: voiceState,
      isLoading: isLoading,
    );

    // 디버깅 로그
    if (latestBotMessage != null) {
      print('[BomiContent] 🔍 Latest message meta: ${latestBotMessage.meta}');
      print('[BomiContent] 🔍 responseType: $responseType');
      print('[BomiContent] 🔍 isListType: $isListType');
      if (isListType) {
        print('[BomiContent] 📝 Summary text: $displayText');
      }
    }
    // 상태 메시지 로그 제거 (말풍선으로만 표시됨)

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
        color: AppColors.bgLightPink, // **배경색**
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
                  top: AppSpacing.xxs,
                  bottom: AppSpacing.xxs,
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
                      characterId: characterId,
                    ),

                    // 2. AI 봄이 메시지 버블 (상태 메시지는 말풍선으로만 표시)
                    // 음성 모드가 아닐 때만 상태 메시지를 답변 박스에 표시
                    if (statusMessage != null && mode == ProcessMode.text) ...[
                      // 🆕 텍스트 모드에서만 상태 메시지 표시
                      EmotionBubble(
                        message: statusMessage,
                        enableTypingAnimation: true,
                        key: ValueKey('status_$statusMessage'),
                        bgWhite: true,
                        showTtsToggle: false,
                      ),
                    ],

                    // 🆕 음성 모드: 말풍선과 독립적으로 항상 답변 표시
                    // 텍스트 모드: statusMessage 없을 때만 답변 표시
                    if (!isListType &&
                        (mode == ProcessMode.voice ||
                            statusMessage == null)) ...[
                      // 일반 답변 메시지 버블 (🆕 마크다운 정제 적용)
                      EmotionBubble(
                        message: TextFormatter.formatBasicMarkdown(displayText),
                        enableTypingAnimation: latestBotMessage != null,
                        key: ValueKey(latestBotMessage?.id ?? 'default'),
                        bgWhite: true,
                        showTtsToggle: false,
                      ),
                    ],

                    // 2-1. 선택형 답변 (response_type: list)
                    // 음성 모드: statusMessage와 독립적으로 표시
                    if (isListType &&
                        (mode == ProcessMode.voice ||
                            statusMessage == null)) ...[
                      // 안내 메시지 버블 (요약만 표시, 🆕 마크다운 정제 적용)
                      EmotionBubble(
                        message: TextFormatter.formatBasicMarkdown(displayText),
                        enableTypingAnimation: latestBotMessage != null,
                        key: ValueKey(
                            '${latestBotMessage?.id ?? 'default'}_intro'),
                        bgWhite: true,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      // 선택 가능한 리스트 - ChoiceButtonGroup 사용
                      Builder(
                        builder: (context) {
                          final items = parseListItems(botMessageText);
                          print('[BomiContent] 📋 Parsed list items: $items');
                          print(
                              '[BomiContent] 📋 Items count: ${items.length}');

                          return ChoiceButtonGroup(
                            choices: items,
                            selectedIndex: _selectedListIndex,
                            layout: ChoiceLayout.vertical,
                            mode: ChoiceButtonMode.basic,
                            showBorder: false,
                            showNumber: true,
                            customColor: AppColors.primaryColor,
                            onChoiceSelected: _selectedListIndex != -1
                                ? null // 이미 선택된 경우 비활성화
                                : (index, choice) {
                                    setState(() {
                                      _selectedListIndex = index;
                                    });
                                    // 선택한 항목을 서버로 전송
                                    _handleListItemSelected(choice);
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
    required String characterId,
  }) {
    return Consumer(
      builder: (context, ref, child) {
        final chatState = ref.watch(chatProvider);

        return SizedBox(
          height: 400, // Stack 전체 높이 (원형 400)
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // 1. 흰색 원형 배경 + 캐릭터 애니메이션
              Center(
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: const BoxDecoration(
                    color: AppColors.basicColor,
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        switchInCurve: Curves.easeInOut,
                        switchOutCurve: Curves.easeInOut,
                        transitionBuilder:
                            (Widget child, Animation<double> animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: ScaleTransition(
                              scale: Tween<double>(begin: 0.95, end: 1.0)
                                  .animate(animation),
                              child: child,
                            ),
                          );
                        },
                        child: AnimatedCharacter(
                          key: ValueKey('${characterId}_$animationState'),
                          characterId: characterId,
                          emotion: animationState,
                          size: 350,
                          repeat: true,
                          animate: true,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // 2. TTS 토글 (캐릭터 원형 하단 오른쪽에 표시)
              Positioned(
                bottom: 0,
                right: MediaQuery.of(context).size.width / 2 - 200,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.bgLightPink,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '봄이 목소리',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      GestureDetector(
                        onTap: () {
                          ref.read(chatProvider.notifier).toggleTtsEnabled();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xxs,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            chatState.ttsEnabled ? '켜기' : '끄기',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.bgBasic,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
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

              // 🆕 Speech Bubble (listening/processing 상태일 때 캐릭터 위에 표시)
              if (chatState.voiceState == VoiceInterfaceState.listening)
                const Positioned(
                  top: -10, // 캐릭터 위에 배치
                  child: SpeechBubble(
                    message: '편하게 말해봐~ 나 다 듣고 있어!',
                    displayDuration: Duration(seconds: 5), // 🆕 5초로 연장
                  ),
                ),

              // 🆕 processingVoice/processing 상태: "음.. 생각해볼게!"
              if (chatState.voiceState == VoiceInterfaceState.processingVoice ||
                  chatState.voiceState == VoiceInterfaceState.processing)
                const Positioned(
                  top: -10,
                  child: SpeechBubble(
                    message: '음.. 생각해볼게! 잠시만 기다려줘!',
                    displayDuration: Duration(seconds: 5),
                  ),
                ),
            ],
          ),
        );
      },
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
}
