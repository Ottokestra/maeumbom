import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math' as math;
import '../tokens/app_tokens.dart';

/// ProcessIndicator의 상호작용 모드
enum ProcessMode {
  voice,
  text,
}

/// ProcessIndicator의 진행 단계
enum ProcessStep {
  preparation, // 준비 단계 (음성 전용)
  standby, // 대기 단계
  input, // 입력 단계 (사용자 입력 중 - 음성/텍스트)
  analysis, // 분석/처리 단계 (AI 생각 중)
  completion, // 완료 단계 (답변 중/완료)
}

/// 진행 상태 표시 위젯
class ProcessIndicator extends StatelessWidget {
  final ProcessMode mode;
  final ProcessStep currentStep;

  const ProcessIndicator({
    super.key,
    required this.mode,
    required this.currentStep,
  });

  // 상태에 따른 색상 결정
  Color _getIconColor() {
    switch (currentStep) {
      case ProcessStep.preparation:
        return AppColors.primaryColor; // 준비 중 - 빨간색
      case ProcessStep.input:
        return AppColors.primaryColor; // 입력 중 - 빨간색
      case ProcessStep.analysis:
        return Colors.orangeAccent; // 분석 중 - 주황색
      case ProcessStep.completion:
        return Colors.green; // 완료 - 초록색
      case ProcessStep.standby:
        return AppColors.primaryColor;
    }
  }

  Color _getBgColor() {
    switch (currentStep) {
      case ProcessStep.preparation:
        return AppColors.bgLightPink;
      case ProcessStep.input:
        return AppColors.bgLightPink;
      case ProcessStep.analysis:
        return Colors.orange.withOpacity(0.1);
      case ProcessStep.completion:
        return Colors.green.withOpacity(0.1);
      case ProcessStep.standby:
        return AppColors.bgLightPink;
    }
  }

  @override
  Widget build(BuildContext context) {
    Color iconColor = _getIconColor();
    Color bgColor = _getBgColor();

    // 기본 아이콘 크기
    const double iconSize = 40.0;

    // 대기 상태는 아이콘 대신 텍스트 표시
    if (currentStep == ProcessStep.standby) {
      return Container(
        height: 64,
        alignment: Alignment.center,
        child: Text(
          '',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    Widget content;

    switch (currentStep) {
      case ProcessStep.preparation:
        content = SvgPicture.asset(
          mode == ProcessMode.voice
              ? 'assets/images/icons/icon-mic.svg'
              : 'assets/images/icons/icon-message.svg',
          width: iconSize,
          height: iconSize,
          colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
        );
        break;
      case ProcessStep.input:
        if (mode == ProcessMode.voice) {
          content = _WaveformIndicator(color: iconColor);
        } else {
          content = SvgPicture.asset(
            'assets/images/icons/icon-message.svg',
            width: iconSize,
            height: iconSize,
            colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
          );
        }
        break;
      case ProcessStep.analysis:
        content = _TypingIndicator(color: iconColor);
        break;
      case ProcessStep.completion:
        content = SvgPicture.asset(
          'assets/images/icons/icon-simple-check.svg',
          width: 56,
          height: 56,
          colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
        );
        break;
      default:
        content = const SizedBox();
        break;
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      transitionBuilder: (Widget child, Animation<double> animation) {
        // completion에서 input으로 전환 시 부드러운 페이드 효과
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(animation),
            child: child,
          ),
        );
      },
      child: Container(
        key: ValueKey(currentStep),
        width: 72,
        height: 72,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: iconColor.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: content,
      ),
    );
  }
}

/// 분석/처리 중 점 3개 타이핑 애니메이션
class _TypingIndicator extends StatefulWidget {
  final Color color;

  const _TypingIndicator({this.color = AppColors.primaryColor});

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
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
      width: 48,
      height: 24,
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
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: opacity),
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

/// 음성 입력 중 파형 애니메이션
class _WaveformIndicator extends StatefulWidget {
  final Color color;

  const _WaveformIndicator({this.color = AppColors.primaryColor});

  @override
  State<_WaveformIndicator> createState() => _WaveformIndicatorState();
}

class _WaveformIndicatorState extends State<_WaveformIndicator>
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
      width: 48,
      height: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(4, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              double value = _controller.value + (index * 0.5);
              double heightFactor =
                  (math.sin(value * math.pi * 2) + 1) / 2; // 0~1

              double height = 16 + (20 * heightFactor);

              return Container(
                width: 5,
                height: height,
                decoration: BoxDecoration(
                  color: widget.color,
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
