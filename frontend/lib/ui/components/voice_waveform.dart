import 'dart:math';
import 'package:flutter/material.dart';
import 'package:frontend/ui/tokens/colors.dart';

/// 음성 입력 중 파동을 시각화하는 위젯
///
/// 음성 입력 중에 실시간으로 파동 애니메이션을 표시합니다.
/// Sine wave 형태의 부드러운 애니메이션으로 음성 입력 상태를 시각적으로 피드백합니다.
///
/// 사용 예시:
/// ```dart
/// VoiceWaveform(
///   isActive: isRecording,
///   color: AppColors.primaryColor,
///   height: 40,
/// )
/// ```
class VoiceWaveform extends StatefulWidget {
  /// 파동 애니메이션 활성화 여부
  final bool isActive;

  /// 파동 색상
  final Color color;

  /// 파동 높이
  final double height;

  const VoiceWaveform({
    super.key,
    this.isActive = true,
    this.color = AppColors.primaryColor,
    this.height = 40,
  });

  @override
  State<VoiceWaveform> createState() => _VoiceWaveformState();
}

class _VoiceWaveformState extends State<VoiceWaveform>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    if (widget.isActive) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(VoiceWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isActive && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(double.infinity, widget.height),
          painter: WaveformPainter(
            progress: _controller.value,
            color: widget.color,
            isActive: widget.isActive,
          ),
        );
      },
    );
  }
}

/// 파동을 그리는 CustomPainter
///
/// Sine wave 형태로 5개 주기의 파동을 그립니다.
class WaveformPainter extends CustomPainter {
  /// 애니메이션 진행 상태 (0.0 ~ 1.0)
  final double progress;

  /// 파동 색상
  final Color color;

  /// 활성화 여부
  final bool isActive;

  WaveformPainter({
    required this.progress,
    required this.color,
    required this.isActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isActive) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final waveHeight = size.height * 0.3; // 진폭: 높이의 30%
    final waveCount = 5; // 파동 개수

    for (var i = 0; i < size.width; i++) {
      final x = i.toDouble();
      final phase = progress * 2 * pi;
      final y = size.height / 2 +
          sin((x / size.width) * waveCount * 2 * pi + phase) * waveHeight;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isActive != isActive;
  }
}
