import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../tokens/app_tokens.dart';
import '../../providers/chat_provider.dart';

/// Bottom Bar - Voice Bar (음성 입력 전용)
///
/// 음성 입력을 위한 3개 버튼 레이아웃:
/// - 왼쪽: 음성 on/off 토글 (볼륨 아이콘)
/// - 가운데: 마이크 버튼 (크게, 상태별 애니메이션)
/// - 오른쪽: 텍스트 모드 전환 (텍스트 아이콘)
class BottomVoiceBar extends StatefulWidget {
  const BottomVoiceBar({
    super.key,
    required this.voiceState,
    required this.onMicTap,
    required this.onTextModeTap,
    this.isTtsEnabled,
    this.onTtsToggle,
    this.backgroundColor = AppColors.basicColor,
  });

  /// 현재 음성 인터페이스 상태
  final VoiceInterfaceState voiceState;

  /// 마이크 버튼 탭 콜백
  final VoidCallback onMicTap;

  /// 텍스트 모드 전환 콜백
  final VoidCallback onTextModeTap;

  /// TTS 활성화 여부
  final bool? isTtsEnabled;

  /// TTS 토글 콜백
  final VoidCallback? onTtsToggle;

  /// 배경색
  final Color backgroundColor;

  @override
  State<BottomVoiceBar> createState() => _BottomVoiceBarState();
}

class _BottomVoiceBarState extends State<BottomVoiceBar>
    with TickerProviderStateMixin {
  late AnimationController _rippleController;
  late AnimationController _pulseController; // 🆕 펄스 애니메이션

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _updateRippleAnimation();
  }

  @override
  void didUpdateWidget(BottomVoiceBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.voiceState != oldWidget.voiceState) {
      _updateRippleAnimation();
    }
  }

  @override
  void dispose() {
    _rippleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _updateRippleAnimation() {
    switch (widget.voiceState) {
      case VoiceInterfaceState.loading:
        _rippleController.duration = const Duration(milliseconds: 2500);
        if (!_rippleController.isAnimating) _rippleController.repeat();
        _pulseController.stop(); // 펄스 중지
        break;
      case VoiceInterfaceState.listening:
        _rippleController.duration = const Duration(milliseconds: 1500);
        if (!_rippleController.isAnimating) _rippleController.repeat();
        // 🆕 listening 상태에서만 펄스 애니메이션 시작
        if (!_pulseController.isAnimating)
          _pulseController.repeat(reverse: true);
        break;
      case VoiceInterfaceState.processingVoice:
        _rippleController.duration = const Duration(milliseconds: 3000);
        if (!_rippleController.isAnimating) {
          _rippleController.repeat(reverse: true);
        }
        _pulseController.stop(); // 펄스 중지
        break;
      case VoiceInterfaceState.processing:
        _rippleController.duration = const Duration(milliseconds: 3000);
        if (!_rippleController.isAnimating) {
          _rippleController.repeat(reverse: true);
        }
        _pulseController.stop(); // 펄스 중지
        break;
      case VoiceInterfaceState.replying:
        _rippleController.duration = const Duration(milliseconds: 2000);
        if (!_rippleController.isAnimating) _rippleController.repeat();
        _pulseController.stop(); // 펄스 중지
        break;
      case VoiceInterfaceState.idle:
        _rippleController.stop();
        _rippleController.reset();
        _pulseController.stop(); // 펄스 중지
        _pulseController.reset();
        break;
    }
  }

  // 상태에 따른 마이크 버튼 색상
  Color get _micButtonColor {
    switch (widget.voiceState) {
      case VoiceInterfaceState.loading:
        return Colors.orangeAccent; // 🆕 노란색으로 변경
      case VoiceInterfaceState.listening:
        return AppColors.primaryColor;
      case VoiceInterfaceState.processingVoice:
        return Colors.orangeAccent;
      case VoiceInterfaceState.processing:
        return Colors.orangeAccent;
      case VoiceInterfaceState.replying:
        return Colors.green;
      case VoiceInterfaceState.idle:
        return AppColors.primaryColor;
    }
  }

  // 마이크 버튼 내부 콘텐츠 (상태별 애니메이션)
  Widget _buildMicButtonContent() {
    switch (widget.voiceState) {
      case VoiceInterfaceState.loading:
        return const _MicTypingIndicator();
      case VoiceInterfaceState.listening:
        return const _MicWaveformIndicator();
      case VoiceInterfaceState.processingVoice:
        return const _MicTypingIndicator();
      case VoiceInterfaceState.processing:
        return const _MicTypingIndicator();
      case VoiceInterfaceState.replying:
        return const Icon(
          Icons.check,
          color: AppColors.basicColor,
          size: 40,
        );
      case VoiceInterfaceState.idle:
        return const Icon(
          Icons.mic,
          color: AppColors.basicColor,
          size: 40,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isVoiceActive = widget.voiceState != VoiceInterfaceState.idle;

    return Container(
      height: 100 + bottomPadding,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 왼쪽: TTS 토글 버튼 (onTtsToggle이 있을 때만 표시)
                if (widget.onTtsToggle != null) ...[
                  GestureDetector(
                    onTap: widget.onTtsToggle,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: (widget.isTtsEnabled ?? false)
                            ? AppColors.primaryColor.withOpacity(0.1)
                            : AppColors.warmWhite,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: (widget.isTtsEnabled ?? false)
                              ? AppColors.primaryColor
                              : AppColors.borderLight,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        (widget.isTtsEnabled ?? false)
                            ? Icons.volume_up
                            : Icons.volume_off,
                        color: (widget.isTtsEnabled ?? false)
                            ? AppColors.primaryColor
                            : AppColors.textSecondary,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],

                // 가운데: 마이크 버튼 (크게)
                GestureDetector(
                  onTap: widget.onMicTap,
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        // 파동 효과
                        if (isVoiceActive)
                          AnimatedBuilder(
                            animation: _rippleController,
                            builder: (context, child) {
                              return CustomPaint(
                                size: const Size(120, 120),
                                painter: _ButtonRipplePainter(
                                  progress: _rippleController.value,
                                  color: _micButtonColor,
                                  rippleCount: 3,
                                  state: widget.voiceState,
                                ),
                              );
                            },
                          ),
                        // 버튼 (🆕 listening 시 펄스 효과)
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            // listening 상태일 때만 scale 변화
                            final scale = widget.voiceState ==
                                    VoiceInterfaceState.listening
                                ? 1.0 +
                                    (_pulseController.value *
                                        0.08) // 1.0 ~ 1.08
                                : 1.0;

                            return Transform.scale(
                              scale: scale,
                              child: child,
                            );
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: _micButtonColor,
                              shape: BoxShape.circle,
                              boxShadow: isVoiceActive
                                  ? [
                                      BoxShadow(
                                        color: _micButtonColor.withOpacity(0.5),
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
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // 오른쪽: 텍스트 모드 전환 버튼
                GestureDetector(
                  onTap: widget.onTextModeTap,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.warmWhite,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.borderLight,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: AppColors.primaryColor,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
        ..color = color.withOpacity(opacity)
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
          ..color = color.withOpacity(opacity)
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
      width: 44,
      height: 36,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(4, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              double value = _controller.value + (index * 0.5);
              double heightFactor = (math.sin(value * math.pi * 2) + 1) / 2;
              double height = 14 + (18 * heightFactor);

              return Container(
                width: 5,
                height: height,
                decoration: BoxDecoration(
                  color: AppColors.basicColor,
                  borderRadius: BorderRadius.circular(2.5),
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
      width: 44,
      height: 24,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final delay = index * 0.2;
              final value = (_controller.value - delay) % 1.0;
              final opacity = value < 0.5 ? value * 2 : (1 - value) * 2;

              return Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color:
                      AppColors.basicColor.withOpacity(opacity.clamp(0.3, 1.0)),
                  shape: BoxShape.circle,
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
