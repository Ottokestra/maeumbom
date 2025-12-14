import 'package:flutter/material.dart';
import 'package:frontend/ui/tokens/colors.dart';
import '../../providers/chat_provider.dart';

/// 원형 파동 효과 위젯
///
/// ⚠️ 참고: 현재 bomi_screen에서는 사용되지 않습니다.
/// 파동 효과는 SlideToActionButton의 음성 입력 버튼에 통합되었습니다.
/// 향후 다른 용도로 사용 가능하므로 보존됩니다.
///
/// 상태에 따라 다른 애니메이션을 보여줍니다:
/// - listening: 빠르고 강한 파동 (사용자 말하는 중)
/// - processing: 느리고 부드러운 호흡 효과 (생각 중)
/// - replying: 중간 속도의 리듬감 있는 파동 (대답 중)
class CircularRipple extends StatefulWidget {
  /// 현재 보이스 인터페이스 상태
  final VoiceInterfaceState voiceState;

  /// 파동 색상
  final Color color;

  /// 전체 크기 (파동이 퍼질 최대 반경)
  final double size;

  /// 중앙에 표시할 자식 위젯 (캐릭터 등)
  final Widget child;

  /// 파동 개수 (기본 4개)
  final int rippleCount;

  const CircularRipple({
    super.key,
    required this.child,
    this.voiceState = VoiceInterfaceState.idle,
    this.color = AppColors.primaryColor,
    this.size = 200,
    this.rippleCount = 4,
  });

  @override
  State<CircularRipple> createState() => _CircularRippleState();
}

class _CircularRippleState extends State<CircularRipple>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _updateAnimationState();
  }

  @override
  void didUpdateWidget(CircularRipple oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.voiceState != oldWidget.voiceState) {
      _updateAnimationState();
    }
  }

  void _updateAnimationState() {
    switch (widget.voiceState) {
      case VoiceInterfaceState.listening:
        _controller.duration = const Duration(milliseconds: 2500); // 더 천천히
        if (!_controller.isAnimating) _controller.repeat();
        break;
      case VoiceInterfaceState.processing:
        _controller.duration = const Duration(milliseconds: 3500); // 더 천천히
        if (!_controller.isAnimating) _controller.repeat(reverse: true);
        break;
      case VoiceInterfaceState.replying:
        _controller.duration = const Duration(milliseconds: 2500); // 더 천천히
        if (!_controller.isAnimating) _controller.repeat();
        break;
      case VoiceInterfaceState.idle:
      default:
        _controller.stop();
        _controller.reset();
        break;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 파동 효과
          if (widget.voiceState != VoiceInterfaceState.idle)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: RipplePainter(
                    progress: _controller.value,
                    color: widget.color,
                    rippleCount: widget.rippleCount,
                    state: widget.voiceState,
                  ),
                );
              },
            ),
          // 중앙 캐릭터
          widget.child,
        ],
      ),
    );
  }
}

/// 원형 파동을 그리는 CustomPainter
class RipplePainter extends CustomPainter {
  /// 애니메이션 진행 상태 (0.0 ~ 1.0)
  final double progress;

  /// 파동 색상
  final Color color;

  /// 파동 개수
  final int rippleCount;

  /// 현재 상태
  final VoiceInterfaceState state;

  RipplePainter({
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
      // Breathing effect for processing - 더 크고 선명하게
      final currentRadius = maxRadius * 0.7 + (maxRadius * 0.5 * progress);
      final opacity = 0.3 + (0.3 * progress);

      final paint = Paint()
        ..color = color.withOpacity(opacity)
        ..style = PaintingStyle.fill;
        
      // Blur effect
      paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

      canvas.drawCircle(center, currentRadius, paint);
    } else {
      // Ripple effect for listening and replying - 명확한 원 두께
      for (int i = 0; i < rippleCount; i++) {
        final rippleDelay = i / rippleCount;
        final rippleProgress = (progress - rippleDelay) % 1.0;

        // Skip if not started yet
        if (progress < rippleDelay) continue;

        // 파동이 더 넓게 퍼지도록
        final radius = maxRadius * rippleProgress * 1.5;
        
        // 투명도: 시작할 때 더 선명하게, 끝날 때 0으로 감소
        final opacity = (1.0 - rippleProgress) * 0.3;

        final paint = Paint()
          ..color = color.withOpacity(opacity)
          ..strokeWidth = state == VoiceInterfaceState.listening ? 20 : 15  // 더 두꺼운 원
          ..style = PaintingStyle.stroke;

        canvas.drawCircle(center, radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(RipplePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.state != state;
  }
}

