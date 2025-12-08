import 'package:flutter/material.dart';
import 'package:frontend/ui/tokens/app_tokens.dart';

/// 봄이의 대화 말풍선 위젯
///
/// 봄이(AI)가 사용자에게 전달하는 메시지를 표시합니다.
/// 기존 EmotionBubble 스타일(연분홍 배경)을 유지하되,
/// 감정 캐릭터는 제거하고 텍스트 박스 크기를 명확하게 키웁니다.
/// 타이핑 애니메이션 효과와 스크롤 기능을 지원합니다.
///
/// 사용 예시:
/// ```dart
/// EmotionBubble(
///   message: '오늘 하루 어떠셨나요?',
///   enableTypingAnimation: true,
///   onTap: () => _handleTap(),
/// )
/// ```
class EmotionBubble extends StatefulWidget {
  /// 표시할 메시지
  final String message;

  /// 탭 콜백 (선택사항)
  final VoidCallback? onTap;

  /// 타이핑 애니메이션 활성화 여부 (기본값: false)
  final bool enableTypingAnimation;

  /// 타이핑 애니메이션 속도 (밀리초, 기본값: 50ms)
  final int typingSpeed;

  const EmotionBubble({
    super.key,
    required this.message,
    this.onTap,
    this.enableTypingAnimation = false,
    this.typingSpeed = 50,
  });

  @override
  State<EmotionBubble> createState() => _EmotionBubbleState();
}

class _EmotionBubbleState extends State<EmotionBubble> {
  final ScrollController _scrollController = ScrollController();
  bool _hasMoreContent = false;
  String _displayedText = '';
  int _currentCharIndex = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    if (widget.enableTypingAnimation) {
      _startTypingAnimation();
    } else {
      _displayedText = widget.message;
    }

    // 스크롤 가능 여부 체크를 위해 다음 프레임에서 실행
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkScrollable();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    setState(() {
      _hasMoreContent = _scrollController.position.pixels <
          _scrollController.position.maxScrollExtent - 5;
    });
  }

  void _checkScrollable() {
    if (_scrollController.hasClients) {
      setState(() {
        _hasMoreContent = _scrollController.position.maxScrollExtent > 0;
      });
    }
  }

  void _startTypingAnimation() async {
    for (int i = 0; i < widget.message.length; i++) {
      if (!mounted) return;

      await Future.delayed(Duration(milliseconds: widget.typingSpeed));

      if (!mounted) return;

      setState(() {
        _currentCharIndex = i + 1;
        _displayedText = widget.message.substring(0, _currentCharIndex);
      });

      // 타이핑 중에 스크롤을 맨 아래로 자동 이동
      if (_scrollController.hasClients) {
        // 다음 프레임에서 스크롤 (텍스트 렌더링 완료 후)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients && mounted) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeOut,
            );
            _checkScrollable();
          }
        });
      }
    }
  }

  /// 삼각형 탭 시 아래로 스크롤
  void _scrollDown() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bubbleWidth = screenWidth - (AppSpacing.md * 2); // 좌우 여백 제외
    const bubbleHeight = 120.0; // 기본 높이 설정 (3줄 크기)

    return GestureDetector(
      onTap: widget.onTap,
      child: Center(
        child: Container(
          width: bubbleWidth, // 명확한 너비 지정 (화면 전체 - 좌우 여백)
          height: bubbleHeight, // 고정 높이 (3줄 크기)
          decoration: BoxDecoration(
            color: BubbleTokens.emotionBg, // 연분홍 배경 유지 (#F4E6E4)
            border: Border.all(
              color: BubbleTokens.emotionBorder, // 테두리 유지 (#F0EAE8)
              width: BubbleTokens.borderWidth,
            ),
            borderRadius:
                BorderRadius.circular(BubbleTokens.emotionRadius), // 12.0
          ),
          child: Stack(
            children: [
              // 스크롤 가능한 텍스트 영역
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, // 좌우 패딩 증가 (32.0)
                  vertical: AppSpacing.md, // 상하 패딩 증가 (24.0)
                ),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Text(
                    _displayedText,
                    textAlign: TextAlign.left, // 왼쪽 정렬
                    style: AppTypography.bodyBold.copyWith(
                      color: BubbleTokens.emotionText, // #233446
                    ),
                  ),
                ),
              ),

              // 하단 삼각형 표시 (더 많은 컨텐츠가 있을 때)
              if (_hasMoreContent)
                Positioned(
                  bottom: 8,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: _scrollDown,
                      child: CustomPaint(
                        size: const Size(20, 10),
                        painter: _TrianglePainter(
                          color: BubbleTokens.userBg,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 하단 삼각형 표시를 위한 CustomPainter
class _TrianglePainter extends CustomPainter {
  final Color color;

  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, size.height) // 하단 중앙 (꼭지점)
      ..lineTo(0, 0) // 좌측 상단
      ..lineTo(size.width, 0) // 우측 상단
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TrianglePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
