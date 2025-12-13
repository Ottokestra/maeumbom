import 'package:flutter/material.dart';
import 'dart:async';
import '../tokens/app_tokens.dart';

class QuestionProgressView extends StatefulWidget {
  final int currentStep;
  final int totalSteps;
  final String? questionNumber; // 예: "Q1."
  final String? questionText;
  final TextStyle? questionTextStyle; // 질문 텍스트 스타일
  final Widget? titleWidget;
  final Widget? media; // 이미지/미디어 위젯 (질문 텍스트 아래 표시)
  final Widget content;
  final bool enableToggle; // 토글 기능 활성화 여부
  final bool initiallyExpanded; // 초기 확장 상태
  final bool enableAnimation; // 텍스트 애니메이션 활성화 여부
  final String? toggleTitle; // 토글 버튼 텍스트 (null이면 아이콘 표시)

  const QuestionProgressView({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.questionNumber,
    this.questionText,
    this.questionTextStyle,
    this.titleWidget,
    this.media,
    required this.content,
    this.enableToggle = true,
    this.initiallyExpanded = true,
    this.enableAnimation = false,
    this.toggleTitle,
  }) : assert(questionText != null || titleWidget != null,
            'questionText 또는 titleWidget 중 하나는 반드시 제공되어야 합니다.');

  @override
  State<QuestionProgressView> createState() => _QuestionProgressViewState();
}

class _QuestionProgressViewState extends State<QuestionProgressView> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    // 토글이 비활성화되어 있으면 항상 확장 상태로 시작
    _isExpanded = widget.enableToggle ? widget.initiallyExpanded : true;
  }

  void _toggleExpand() {
    if (!widget.enableToggle) return;
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 0-based index를 디스플레이용 1-based index로 변환
    final displayStep = widget.currentStep + 1;
    final progress = (displayStep / widget.totalSteps).clamp(0.0, 1.0);
    final percentage = (progress * 100).toInt();

    return Column(
      children: [
        // 진행률 바 영역 (Progress Bar Section)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              // 진행률 바 (Progress Bar)
              Container(
                width: double.infinity,
                height: 6,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: FractionallySizedBox(
                  widthFactor: progress,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // 진행률 텍스트 (Progress Text)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$displayStep / ${widget.totalSteps}',
                    style: const TextStyle(
                      color: Color(0xFF99A1AE),
                      fontSize: 12,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  Text(
                    '$percentage%',
                    style: const TextStyle(
                      color: Color(0xFFD7454D),
                      fontSize: 12,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // 질문 콘텐츠 (Question Content)
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 질문 번호 (Question Number)
                  if (widget.questionNumber != null) ...[
                    Text(
                      widget.questionNumber!,
                      style: const TextStyle(
                        color: Color(0xFFD7454D),
                        fontSize: 16,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w700,
                        height: 1.50,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  // 질문 텍스트 (Question Text)
                  if (widget.titleWidget != null)
                    widget.titleWidget!
                  else if (widget.enableAnimation)
                    FadeSlideRichText(
                      text: widget.questionText!,
                      style: widget.questionTextStyle ??
                          const TextStyle(
                            color: Color(0xFF243447),
                            fontSize: 24,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                          ),
                    )
                  else
                    Text(
                      widget.questionText!,
                      style: widget.questionTextStyle ??
                          const TextStyle(
                            color: Color(0xFF243447),
                            fontSize: 24,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                          ),
                    ),
                  
                  // 미디어 영역 (Media Area) - 질문 텍스트 아래로 이동
                  if (widget.media != null) ...[
                    const SizedBox(height: 24),
                    widget.media!,
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),

        // 하단 고정 콘텐츠 (Sticky Bottom Content) - Toggle 기능 추가
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: AppColors.basicColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(AppRadius.xxl),
              topRight: Radius.circular(AppRadius.xxl),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: widget.enableToggle ? 12 : 24, // 토글 활성화 시 버튼 공간 확보, 아니면 일반 패딩
            bottom: 24 + MediaQuery.of(context).padding.bottom, // Safe Area 대응
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 토글 버튼 (Toggle Button) - 활성화된 경우에만 표시
              if (widget.enableToggle)
                GestureDetector(
                  onTap: _toggleExpand,
                  behavior: HitTestBehavior.translucent,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(top: 8, bottom: 12),
                    child: Center(
                      child: widget.toggleTitle != null
                          ? Text(
                              _isExpanded ? '닫기' : widget.toggleTitle!,
                              style: AppTypography.bodyBold.copyWith(
                                color: AppColors.primaryColor,
                              ),
                            )
                          : Icon(
                              _isExpanded
                                  ? Icons.keyboard_arrow_down_rounded
                                  : Icons.keyboard_arrow_up_rounded,
                              color: AppColors.textSecondary,
                              size: 28,
                            ),
                    ),
                  ),
                ),
              
              // 콘텐츠 영역 (확장 상태이거나 토글이 비활성화된 경우 표시)
              if (_isExpanded || !widget.enableToggle)
                  widget.content,
            ],
          ),
        ),
      ],
    );
  }
}

/// Fade In + Slide Up 효과를 적용한 RichText 위젯
class FadeSlideRichText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Duration duration;

  const FadeSlideRichText({
    super.key,
    required this.text,
    required this.style,
    this.duration = const Duration(milliseconds: 800),
  });

  @override
  State<FadeSlideRichText> createState() => _FadeSlideRichTextState();
}

class _FadeSlideRichTextState extends State<FadeSlideRichText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;
  List<TextSpan> _spans = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    
    _offset = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _parseText();
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant FadeSlideRichText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != oldWidget.text) {
      _controller.reset();
      _parseText();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _parseText() {
    final spans = <TextSpan>[];
    final regex = RegExp(r'\*\*([^\*]+?)\*\*');
    int lastIndex = 0;

    for (final match in regex.allMatches(widget.text)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: widget.text.substring(lastIndex, match.start),
          style: widget.style,
        ));
      }

      final boldText = match.group(1)!;
      spans.add(TextSpan(
        text: boldText,
        style: widget.style.copyWith(fontWeight: FontWeight.w700),
      ));

      lastIndex = match.end;
    }

    if (lastIndex < widget.text.length) {
      spans.add(TextSpan(
        text: widget.text.substring(lastIndex),
        style: widget.style,
      ));
    }
    _spans = spans;
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offset,
      child: FadeTransition(
        opacity: _opacity,
        child: RichText(
          text: TextSpan(children: _spans),
        ),
      ),
    );
  }
}
