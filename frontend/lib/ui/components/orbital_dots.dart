import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../../providers/chat_provider.dart';

/// 궤도 회전 점 효과 위젯
/// 
/// 캐릭터 주위를 작은 원들이 차례로 빙빙 도는 애니메이션 효과
/// 음성 인식 중이거나 처리 중일 때 시각적 피드백 제공
/// 
/// 사용 예시:
/// ```dart
/// OrbitalDots(
///   child: EmotionCharacter(id: EmotionId.joy),
///   voiceState: VoiceInterfaceState.listening,
/// )
/// ```
class OrbitalDots extends StatefulWidget {
  /// 현재 보이스 인터페이스 상태
  final VoiceInterfaceState voiceState;

  /// 점 색상
  final Color dotColor;

  /// 궤도 반경 (중심에서 점까지의 거리)
  final double orbitRadius;

  /// 점 크기
  final double dotSize;

  /// 점 개수
  final int dotCount;

  /// 회전 속도 (초 단위)
  final Duration rotationDuration;

  /// 중앙에 표시할 자식 위젯 (캐릭터 등)
  final Widget child;

  const OrbitalDots({
    super.key,
    required this.child,
    this.voiceState = VoiceInterfaceState.idle,
    this.dotColor = AppColors.accentRed,
    this.orbitRadius = 120,
    this.dotSize = 8,
    this.dotCount = 12,
    this.rotationDuration = const Duration(seconds: 3),
  });

  @override
  State<OrbitalDots> createState() => _OrbitalDotsState();
}

class _OrbitalDotsState extends State<OrbitalDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.rotationDuration,
    );

    _updateAnimationState();
  }

  @override
  void didUpdateWidget(OrbitalDots oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.voiceState != oldWidget.voiceState) {
      _updateAnimationState();
    }
    if (widget.rotationDuration != oldWidget.rotationDuration) {
      _controller.duration = widget.rotationDuration;
    }
  }

  void _updateAnimationState() {
    switch (widget.voiceState) {
      case VoiceInterfaceState.listening:
      case VoiceInterfaceState.processing:
      case VoiceInterfaceState.processingVoice:
      case VoiceInterfaceState.replying:
        // 마이크 활성 상태일 때 회전 시작
        if (!_controller.isAnimating) {
          _controller.repeat();
        }
        break;
      case VoiceInterfaceState.idle:
      default:
        // 마이크 비활성 상태일 때 정지
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
      width: widget.orbitRadius * 2 + widget.dotSize * 2,
      height: widget.orbitRadius * 2 + widget.dotSize * 2,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 궤도 회전 점들 (마이크 활성 시에만 표시)
          if (widget.voiceState != VoiceInterfaceState.idle)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  size: Size(
                    widget.orbitRadius * 2 + widget.dotSize * 2,
                    widget.orbitRadius * 2 + widget.dotSize * 2,
                  ),
                  painter: OrbitalDotsPainter(
                    progress: _controller.value,
                    dotColor: widget.dotColor,
                    orbitRadius: widget.orbitRadius,
                    dotSize: widget.dotSize,
                    dotCount: widget.dotCount,
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

/// 궤도 회전 점을 그리는 CustomPainter
class OrbitalDotsPainter extends CustomPainter {
  /// 애니메이션 진행 상태 (0.0 ~ 1.0)
  final double progress;

  /// 점 색상
  final Color dotColor;

  /// 궤도 반경
  final double orbitRadius;

  /// 점 크기
  final double dotSize;

  /// 점 개수
  final int dotCount;

  /// 현재 상태
  final VoiceInterfaceState state;

  OrbitalDotsPainter({
    required this.progress,
    required this.dotColor,
    required this.orbitRadius,
    required this.dotSize,
    required this.dotCount,
    required this.state,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // 각 점의 각도 간격
    final angleStep = (2 * math.pi) / dotCount;

    for (int i = 0; i < dotCount; i++) {
      // 현재 점의 기본 각도
      final baseAngle = i * angleStep;
      
      // 회전 애니메이션 적용 (시계 방향)
      final rotationAngle = progress * 2 * math.pi;
      final currentAngle = baseAngle + rotationAngle;

      // 점의 위치 계산
      final x = center.dx + orbitRadius * math.cos(currentAngle);
      final y = center.dy + orbitRadius * math.sin(currentAngle);

      // 점의 투명도 계산 (순차적으로 밝아지는 효과)
      // 현재 회전 위치에 가까운 점일수록 밝게
      final normalizedAngle = (currentAngle % (2 * math.pi)) / (2 * math.pi);
      final dotProgress = (i / dotCount + progress) % 1.0;
      
      // 투명도: 앞쪽 점들은 밝고, 뒤쪽 점들은 어둡게
      final opacity = _calculateOpacity(dotProgress, state);

      // 점 크기: 상태에 따라 약간 변화
      final currentDotSize = _calculateDotSize(dotProgress, state);

      final paint = Paint()
        ..color = dotColor.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), currentDotSize, paint);
    }
  }

  /// 점의 투명도 계산
  double _calculateOpacity(double dotProgress, VoiceInterfaceState state) {
    switch (state) {
      case VoiceInterfaceState.listening:
        // 듣는 중: 선명하고 균일하게
        return 0.2 + (0.7 * dotProgress);
      case VoiceInterfaceState.processing:
      case VoiceInterfaceState.processingVoice:
        // 처리 중: 부드럽게 페이드
        return 0.2 + (0.5 * dotProgress);
      case VoiceInterfaceState.replying:
        // 답변 중: 중간 밝기
        return 0.25 + (0.6 * dotProgress);
      default:
        return 0.2;
    }
  }

  /// 점의 크기 계산
  double _calculateDotSize(double dotProgress, VoiceInterfaceState state) {
    switch (state) {
      case VoiceInterfaceState.listening:
        // 듣는 중: 약간 펄스 효과
        return dotSize * (0.9 + 0.2 * dotProgress);
      case VoiceInterfaceState.processing:
      case VoiceInterfaceState.processingVoice:
        // 처리 중: 균일한 크기
        return dotSize;
      case VoiceInterfaceState.replying:
        // 답변 중: 약간 크게
        return dotSize * 1.1;
      default:
        return dotSize;
    }
  }

  @override
  bool shouldRepaint(OrbitalDotsPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.state != state;
  }
}
