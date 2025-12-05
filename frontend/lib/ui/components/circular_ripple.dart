import 'package:flutter/material.dart';
import 'package:frontend/ui/tokens/colors.dart';

/// 원형 파동 효과 위젯
///
/// 마이크 사용 시 캐릭터 주위에 원형 파동 애니메이션을 표시합니다.
/// 중심에서 바깥쪽으로 퍼져나가는 3개의 동심원 파동을 그립니다.
///
/// 사용 예시:
/// ```dart
/// CircularRipple(
///   isActive: isRecording,
///   color: AppColors.accentRed,
///   size: 200,
///   child: YourCharacterWidget(),
/// )
/// ```
class CircularRipple extends StatefulWidget {
  /// 파동 애니메이션 활성화 여부
  final bool isActive;

  /// 파동 색상
  final Color color;

  /// 전체 크기 (파동이 퍼질 최대 반경)
  final double size;

  /// 중앙에 표시할 자식 위젯 (캐릭터 등)
  final Widget child;

  /// 파동 개수 (기본 3개)
  final int rippleCount;

  const CircularRipple({
    super.key,
    required this.child,
    this.isActive = true,
    this.color = AppColors.accentRed,
    this.size = 200,
    this.rippleCount = 3,
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

    if (widget.isActive) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(CircularRipple oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isActive && _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
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
          if (widget.isActive)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: RipplePainter(
                    progress: _controller.value,
                    color: widget.color,
                    rippleCount: widget.rippleCount,
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
///
/// 중심에서 바깥쪽으로 퍼져나가는 동심원을 그립니다.
/// 각 파동은 시간차를 두고 시작하며, 퍼져나갈수록 투명해집니다.
class RipplePainter extends CustomPainter {
  /// 애니메이션 진행 상태 (0.0 ~ 1.0)
  final double progress;

  /// 파동 색상
  final Color color;

  /// 파동 개수
  final int rippleCount;

  RipplePainter({
    required this.progress,
    required this.color,
    required this.rippleCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    for (int i = 0; i < rippleCount; i++) {
      // 각 파동의 시작 시간을 다르게 설정 (균등 분배)
      final rippleDelay = i / rippleCount;
      final rippleProgress = (progress - rippleDelay) % 1.0;

      // 반경: 0에서 maxRadius까지 증가
      final radius = maxRadius * rippleProgress;

      // 투명도: 시작할 때 0.5, 끝날 때 0으로 감소
      final opacity = (1.0 - rippleProgress) * 0.5;

      final paint = Paint()
        ..color = color.withOpacity(opacity)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(RipplePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
