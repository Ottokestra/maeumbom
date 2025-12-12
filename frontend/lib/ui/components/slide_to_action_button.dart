import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../tokens/app_tokens.dart';
import '../../providers/chat_provider.dart';

/// 양방향 슬라이드 액션 버튼
///
/// 좌우로 슬라이딩하여 음성 입력 또는 텍스트 입력을 활성화합니다.
/// 상태에 따른 UI 변화:
/// - Idle: "슬라이드하여 선택"
/// - Listening: "말씀해주세요..." (빨간색)
/// - Processing: "생각하는 중..." (주황색/노란색 계열)
/// - Replying: "대답하는 중..." (파란색 계열)
class SlideToActionButton extends StatefulWidget {
  const SlideToActionButton({
    super.key,
    required this.onVoiceActivated,
    required this.onTextActivated,
    this.onVoiceReset,
    this.onTextReset,
    this.voiceState = VoiceInterfaceState.idle,
    this.isTextMode = false,
  });

  /// 음성 입력 활성화 콜백
  final VoidCallback onVoiceActivated;

  /// 텍스트 입력 활성화 콜백
  final VoidCallback onTextActivated;

  /// 음성 버튼 리셋 콜백
  final VoidCallback? onVoiceReset;

  /// 텍스트 버튼 리셋 콜백
  final VoidCallback? onTextReset;

  /// 현재 보이스 인터페이스 상태
  final VoiceInterfaceState voiceState;

  /// 텍스트 입력 모드 여부 (외부 제어용)
  final bool isTextMode;

  @override
  State<SlideToActionButton> createState() => _SlideToActionButtonState();
}

class _SlideToActionButtonState extends State<SlideToActionButton>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late AnimationController _rippleController;

  double _dragPosition = 0.0; // -1.0 (왼쪽) ~ 1.0 (오른쪽)
  bool _isDragging = false;

  // 어느 버튼을 드래그 중인지 추적
  String? _draggingButton; // 'left' or 'right'

  // 버튼이 도착한 상태 추적
  bool _leftButtonArrived = false;
  bool _rightButtonArrived = false;

  // 타이핑 애니메이션 상태
  String _displayedText = '슬라이드하여 선택';
  int _typingIndex = 0;

  // 슬라이드 임계값 (95% 이상 슬라이드해야 활성화 - 완전히 도착)
  static const double _activationThreshold = 0.95;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    )..addListener(() {
        setState(() {
          _dragPosition = _slideAnimation.value;
        });
      });

    // 파동 애니메이션 컨트롤러
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // 초기 텍스트 설정
    _startTypingAnimation();

    // 초기 파동 상태 설정
    _updateRippleAnimation();
  }

  @override
  void didUpdateWidget(SlideToActionButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 외부에서 텍스트 모드가 변경되었을 때 상태 동기화
    if (widget.isTextMode != oldWidget.isTextMode) {
      if (widget.isTextMode) {
        setState(() {
          _rightButtonArrived = true;
          _dragPosition = -1.0;
        });
      } else {
        if (_rightButtonArrived) {
          _resetRightButton();
        }
      }
    }

    // 상태가 변경되면 텍스트 타이핑 재시작 및 파동 애니메이션 업데이트
    if (widget.voiceState != oldWidget.voiceState) {
      _startTypingAnimation();
      _updateRippleAnimation();

      // 상태에 따라 버튼 위치 강제 조정 (예: 외부에서 종료 시 리셋)
      if (widget.voiceState == VoiceInterfaceState.idle && _leftButtonArrived) {
        _resetLeftButton(notify: false);
      } else if (widget.voiceState != VoiceInterfaceState.idle &&
          !_leftButtonArrived) {
        // 녹음 시작 시 UI 상태 동기화 (만약 외부에서 시작되었다면)
        setState(() {
          _leftButtonArrived = true;
          _dragPosition = 1.0;
        });
      }
    }
  }

  void _updateRippleAnimation() {
    switch (widget.voiceState) {
      case VoiceInterfaceState.loading:
        // Backend 로딩 중 - 느린 펄스
        _rippleController.duration = const Duration(milliseconds: 2500);
        if (!_rippleController.isAnimating) _rippleController.repeat();
        break;
      case VoiceInterfaceState.listening:
        _rippleController.duration = const Duration(milliseconds: 1500);
        if (!_rippleController.isAnimating) _rippleController.repeat();
        break;
      case VoiceInterfaceState.processing:
        _rippleController.duration = const Duration(milliseconds: 3000);
        if (!_rippleController.isAnimating)
          _rippleController.repeat(reverse: true);
        break;
      case VoiceInterfaceState.replying:
        _rippleController.duration = const Duration(milliseconds: 2000);
        if (!_rippleController.isAnimating) _rippleController.repeat();
        break;
      case VoiceInterfaceState.idle:
        _rippleController.stop();
        _rippleController.reset();
        break;
    }
  }

  void _startTypingAnimation() {
    String targetText;
    switch (widget.voiceState) {
      case VoiceInterfaceState.loading:
        targetText = '준비 중...'; // ✅ 새로 추가!
        break;
      case VoiceInterfaceState.listening:
        targetText = '나에게 얘기해줘...';
        break;
      case VoiceInterfaceState.processing:
        targetText = '생각하는 중...';
        break;
      case VoiceInterfaceState.replying:
        targetText = '대답하는 중...';
        break;
      case VoiceInterfaceState.idle:
        targetText = '슬라이드하여 선택';
        break;
    }

    setState(() {
      _displayedText = '';
      _typingIndex = 0;
    });

    // 타이핑 애니메이션
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 50));

      if (!mounted) return false;

      // 텍스트가 변경되었으면 중단 (새로운 애니메이션 시작)
      if (_displayedText.length > _typingIndex &&
          _displayedText != targetText.substring(0, _typingIndex)) {
        return false;
      }

      if (_typingIndex < targetText.length) {
        setState(() {
          _typingIndex++;
          _displayedText = targetText.substring(0, _typingIndex);
        });
        return true;
      }
      return false;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  void _onDragStart(String button) {
    setState(() {
      _isDragging = true;
      _draggingButton = button;
    });
  }

  void _onDragUpdate(DragUpdateDetails details, double maxWidth) {
    if (!_isDragging) return;

    setState(() {
      if (_draggingButton == 'left') {
        // 왼쪽 버튼: 드래그 방향 그대로 이동 (오른쪽으로만 이동 가능)
        _dragPosition += details.delta.dx / (maxWidth / 2);
        _dragPosition = _dragPosition.clamp(0.0, 1.0);
      } else if (_draggingButton == 'right') {
        // 오른쪽 버튼: 드래그 방향 그대로 이동 (왼쪽으로만 이동 가능)
        _dragPosition += details.delta.dx / (maxWidth / 2);
        _dragPosition = _dragPosition.clamp(-1.0, 0.0);
      }
    });
  }

  void _onDragEnd(DragEndDetails details) {
    final wasDragging = _isDragging;
    final draggingButton = _draggingButton;
    final currentPosition = _dragPosition;

    setState(() {
      _isDragging = false;
      _draggingButton = null;
    });

    if (!wasDragging) return;

    // 왼쪽 버튼 슬라이드 (음성 입력) - 오른쪽으로 슬라이드
    if (draggingButton == 'left' && currentPosition > _activationThreshold) {
      // 버튼이 도착 - 위치 고정하고 녹음 대기 상태로 전환
      setState(() {
        _leftButtonArrived = true;
        _dragPosition = 1.0;
      });
      widget.onVoiceActivated();
      return; // 애니메이션 복귀하지 않음
    }
    // 오른쪽 버튼 슬라이드 (텍스트 입력) - 왼쪽으로 슬라이드
    else if (draggingButton == 'right' &&
        currentPosition < -_activationThreshold) {
      // 버튼이 도착 - 위치 고정하고 텍스트 입력 대기 상태로 전환
      setState(() {
        _rightButtonArrived = true;
        _dragPosition = -1.0;
      });
      widget.onTextActivated();
      return; // 애니메이션 복귀하지 않음
    }

    // 원위치로 복귀 애니메이션 (도착하지 못한 경우만)
    _slideAnimation = Tween<double>(
      begin: _dragPosition,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _animationController.forward(from: 0.0);
  }

  void _resetLeftButton({bool notify = true}) {
    // 리셋 콜백 호출
    if (notify) widget.onVoiceReset?.call();

    setState(() {
      _leftButtonArrived = false;
    });

    // 원위치로 복귀 애니메이션
    _slideAnimation = Tween<double>(
      begin: _dragPosition,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _animationController.forward(from: 0.0);
  }

  void _resetRightButton() {
    // 리셋 콜백 호출
    widget.onTextReset?.call();

    setState(() {
      _rightButtonArrived = false;
    });

    // 원위치로 복귀 애니메이션
    _slideAnimation = Tween<double>(
      begin: _dragPosition,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _animationController.forward(from: 0.0);
  }

  // 상태에 따른 왼쪽 버튼 색상 (ProcessIndicator와 동기화)
  Color get _leftButtonColor {
    switch (widget.voiceState) {
      case VoiceInterfaceState.loading:
        return AppColors.primaryColor; // 준비 중 - 빨간색
      case VoiceInterfaceState.listening:
        return AppColors.primaryColor; // 듣는 중 - 빨간색
      case VoiceInterfaceState.processing:
        return Colors.orangeAccent; // 생각 중 - 주황색
      case VoiceInterfaceState.replying:
        return Colors.green; // 답변 중 - 초록색
      case VoiceInterfaceState.idle:
        return AppColors.primaryColor;
    }
  }

  // 마이크 버튼 내부 콘텐츠 (상태별 애니메이션)
  Widget _buildMicButtonContent() {
    switch (widget.voiceState) {
      case VoiceInterfaceState.loading:
        // 준비 중 - 점 3개 타이핑 애니메이션
        return const _MicTypingIndicator();

      case VoiceInterfaceState.listening:
        // 듣는 중 - 파형 애니메이션
        return const _MicWaveformIndicator();

      case VoiceInterfaceState.processing:
        // 생각 중 - 점 3개 타이핑 애니메이션
        return const _MicTypingIndicator();

      case VoiceInterfaceState.replying:
        // 답변 중 - 체크 아이콘
        return const Icon(
          Icons.check,
          color: AppColors.basicColor,
          size: 36,
        );

      case VoiceInterfaceState.idle:
        // 기본 상태 - 마이크 아이콘
        return const Icon(
          Icons.mic,
          color: AppColors.basicColor,
          size: 36,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final isVoiceActive = widget.voiceState != VoiceInterfaceState.idle;

        // 왼쪽 버튼 위치 계산 (왼쪽에서 시작 → 오른쪽으로 이동)
        final leftButtonOffset = _leftButtonArrived
            ? maxWidth - 80.0 // 도착: 오른쪽 끝
            : (_draggingButton == 'left'
                ? _dragPosition * (maxWidth / 2)
                : 0.0); // 기본: 왼쪽 끝

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: SizedBox(
            height: 80,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // 배경 트랙 (항상 전체 너비, 모서리 둥글게) - 맨 아래 레이어
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.borderLight,
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Align(
                          alignment: isVoiceActive
                              ? Alignment.centerLeft
                              : Alignment.center,
                          child: Text(
                            _displayedText,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: isVoiceActive
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // 오른쪽 버튼이 움직이지 않을 때는 왼쪽 버튼을 먼저 배치
                if (_draggingButton != 'right') ...[
                  // 오른쪽 텍스트 입력 버튼 (아래 레이어)
                  Positioned(
                    right: _rightButtonArrived ? null : 0.0,
                    left: _rightButtonArrived ? 0.0 : null,
                    child: GestureDetector(
                      onTap: _rightButtonArrived ? _resetRightButton : null,
                      onHorizontalDragStart: _rightButtonArrived
                          ? null
                          : (details) => _onDragStart('right'),
                      onHorizontalDragUpdate: _rightButtonArrived
                          ? null
                          : (details) => _onDragUpdate(details, maxWidth),
                      onHorizontalDragEnd:
                          _rightButtonArrived ? null : _onDragEnd,
                      child: SizedBox(
                        width: 80,
                        height: 80,
                        child: CustomPaint(
                          painter: _CircleBorderPainter(
                            color: AppColors.primaryColor,
                            strokeWidth: 2,
                          ),
                          child: Center(
                            child: Icon(
                              Icons.edit,
                              color: AppColors.primaryColor,
                              size: 36,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 왼쪽 음성 입력 버튼 (위 레이어)
                  Positioned(
                    left: _leftButtonArrived ? null : 0.0 + leftButtonOffset,
                    right: _leftButtonArrived ? 0.0 : null,
                    child: GestureDetector(
                      onTap: _leftButtonArrived
                          ? () => _resetLeftButton(notify: true)
                          : (_rightButtonArrived
                              ? widget.onVoiceActivated
                              : null),
                      onHorizontalDragStart: _leftButtonArrived
                          ? null
                          : (details) => _onDragStart('left'),
                      onHorizontalDragUpdate: _leftButtonArrived
                          ? null
                          : (details) => _onDragUpdate(details, maxWidth),
                      onHorizontalDragEnd:
                          _leftButtonArrived ? null : _onDragEnd,
                      child: SizedBox(
                        width: 80,
                        height: 80,
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            // 파동 효과 (배경 밖으로 나갈 수 있음)
                            if (isVoiceActive)
                              AnimatedBuilder(
                                animation: _rippleController,
                                builder: (context, child) {
                                  return CustomPaint(
                                    size: const Size(120, 120),
                                    painter: _ButtonRipplePainter(
                                      progress: _rippleController.value,
                                      color: _leftButtonColor,
                                      rippleCount: 3,
                                      state: widget.voiceState,
                                    ),
                                  );
                                },
                              ),
                            // 버튼 (80x80, 배경 안에 위치)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: _leftButtonColor,
                                shape: BoxShape.circle,
                                boxShadow: isVoiceActive
                                    ? [
                                        BoxShadow(
                                          color: _leftButtonColor.withValues(
                                              alpha: 0.5),
                                          blurRadius: 20,
                                          offset: const Offset(0, 6),
                                        ),
                                      ]
                                    : [
                                        BoxShadow(
                                          color: AppColors.primaryColorShadow,
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                              ),
                              child: _buildMicButtonContent(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],

                // 오른쪽 버튼이 움직일 때는 순서를 바꿔서 위에 배치
                if (_draggingButton == 'right') ...[
                  // 왼쪽 음성 입력 버튼 (아래 레이어)
                  Positioned(
                    left: _leftButtonArrived ? null : 0.0 + leftButtonOffset,
                    right: _leftButtonArrived ? 0.0 : null,
                    child: GestureDetector(
                      onTap: _leftButtonArrived
                          ? () => _resetLeftButton(notify: true)
                          : null,
                      onHorizontalDragStart: _leftButtonArrived
                          ? null
                          : (details) => _onDragStart('left'),
                      onHorizontalDragUpdate: _leftButtonArrived
                          ? null
                          : (details) => _onDragUpdate(details, maxWidth),
                      onHorizontalDragEnd:
                          _leftButtonArrived ? null : _onDragEnd,
                      child: SizedBox(
                        width: 80,
                        height: 80,
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            // 파동 효과 (배경 밖으로 나갈 수 있음)
                            if (isVoiceActive)
                              AnimatedBuilder(
                                animation: _rippleController,
                                builder: (context, child) {
                                  return CustomPaint(
                                    size: const Size(120, 120),
                                    painter: _ButtonRipplePainter(
                                      progress: _rippleController.value,
                                      color: _leftButtonColor,
                                      rippleCount: 3,
                                      state: widget.voiceState,
                                    ),
                                  );
                                },
                              ),
                            // 버튼 (80x80, 배경 안에 위치)
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: _leftButtonColor,
                                shape: BoxShape.circle,
                                boxShadow: isVoiceActive
                                    ? [
                                        BoxShadow(
                                          color: _leftButtonColor.withValues(
                                              alpha: 0.5),
                                          blurRadius: 20,
                                          offset: const Offset(0, 6),
                                        ),
                                      ]
                                    : [
                                        BoxShadow(
                                          color: AppColors.primaryColorShadow,
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                              ),
                              child: _buildMicButtonContent(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 오른쪽 텍스트 입력 버튼 (위 레이어)
                  Positioned(
                    right: _rightButtonArrived ? null : 0.0,
                    left: _rightButtonArrived ? 0.0 : null,
                    child: GestureDetector(
                      onTap: _rightButtonArrived ? _resetRightButton : null,
                      onHorizontalDragStart: _rightButtonArrived
                          ? null
                          : (details) => _onDragStart('right'),
                      onHorizontalDragUpdate: _rightButtonArrived
                          ? null
                          : (details) => _onDragUpdate(details, maxWidth),
                      onHorizontalDragEnd:
                          _rightButtonArrived ? null : _onDragEnd,
                      child: SizedBox(
                        width: 80,
                        height: 80,
                        child: CustomPaint(
                          painter: _CircleBorderPainter(
                            color: AppColors.primaryColor,
                            strokeWidth: 2,
                          ),
                          child: Center(
                            child: Icon(
                              Icons.edit,
                              color: AppColors.primaryColor,
                              size: 36,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 버튼용 원형 파동 CustomPainter
class _ButtonRipplePainter extends CustomPainter {
  final double progress;
  final Color color;
  final int rippleCount;
  final VoiceInterfaceState state;

  _ButtonRipplePainter({
    required this.progress,
    required this.color,
    required this.rippleCount,
    required this.state,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    if (state == VoiceInterfaceState.processing) {
      // Breathing effect for processing
      final currentRadius = maxRadius * 0.7 + (maxRadius * 0.3 * progress);
      final opacity = 0.2 + (0.2 * progress);

      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      // Blur effect
      paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);

      canvas.drawCircle(center, currentRadius, paint);
    } else {
      // Ripple effect for listening and replying
      for (int i = 0; i < rippleCount; i++) {
        final rippleDelay = i / rippleCount;
        final rippleProgress = (progress - rippleDelay) % 1.0;

        // Skip if not started yet
        if (progress < rippleDelay) continue;

        final radius = maxRadius * rippleProgress;

        // 투명도: 시작할 때 0.4, 끝날 때 0으로 감소
        final opacity = (1.0 - rippleProgress) * 0.4;

        final paint = Paint()
          ..color = color.withValues(alpha: opacity)
          ..strokeWidth = state == VoiceInterfaceState.listening ? 3 : 2
          ..style = PaintingStyle.stroke;

        canvas.drawCircle(center, radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_ButtonRipplePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.state != state;
  }
}

/// 원형 테두리를 그리는 CustomPainter
class _CircleBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _CircleBorderPainter({
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - (strokeWidth / 2);

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_CircleBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
  }
}

/// 마이크 버튼용 파형 애니메이션 (listening 상태)
class _MicWaveformIndicator extends StatefulWidget {
  const _MicWaveformIndicator();

  @override
  State<_MicWaveformIndicator> createState() => _MicWaveformIndicatorState();
}

class _MicWaveformIndicatorState extends State<_MicWaveformIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 32,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(4, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              double value = _controller.value + (index * 0.5);
              double heightFactor = (math.sin(value * math.pi * 2) + 1) / 2;
              double height = 12 + (16 * heightFactor);

              return Container(
                width: 4,
                height: height,
                decoration: BoxDecoration(
                  color: AppColors.basicColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

/// 마이크 버튼용 타이핑 애니메이션 (loading, processing 상태)
class _MicTypingIndicator extends StatefulWidget {
  const _MicTypingIndicator();

  @override
  State<_MicTypingIndicator> createState() => _MicTypingIndicatorState();
}

class _MicTypingIndicatorState extends State<_MicTypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final double start = index * 0.2;
              final double end = start + 0.4;

              double opacity = 0.3;
              if (_controller.value >= start && _controller.value <= end) {
                final double t = (_controller.value - start) / 0.4;
                final double sineValue = math.sin(t * math.pi);
                opacity = 0.3 + (0.7 * sineValue);
              }

              double scale = 1.0;
              if (_controller.value >= start && _controller.value <= end) {
                final double t = (_controller.value - start) / 0.4;
                final double sineValue = math.sin(t * math.pi);
                scale = 1.0 + (0.4 * sineValue);
              }

              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.basicColor.withValues(alpha: opacity),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
