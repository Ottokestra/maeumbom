import 'package:flutter/material.dart';
import '../tokens/app_tokens.dart';
import '../tokens/bubbles.dart';

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
///   bgGreen: true, // 민트색 배경, 회색 테두리 적용
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

  /// 배경색 Green(Mint) 모드 여부 (기본값: false - Pink)
  /// true일 경우 Mint 배경 + LightGray 테두리 사용
  final bool bgGreen;

  /// TTS 토글 표시 여부 (기본값: false)
  final bool showTtsToggle;

  /// TTS 활성화 상태
  final bool ttsEnabled;

  /// TTS 토글 콜백
  final ValueChanged<bool>? onTtsToggle;

  const EmotionBubble({
    super.key,
    required this.message,
    this.onTap,
    this.enableTypingAnimation = false,
    this.typingSpeed = 50,
    this.bgGreen = false,
    this.showTtsToggle = false,
    this.ttsEnabled = false,
    this.onTtsToggle,
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

  /// 토글 빌드 헬퍼
  Widget _buildToggle({
    required bool value,
    required ValueChanged<bool>? onChanged,
    required ToggleStyle style,
  }) {
    return Transform.scale(
      scale: style.scale,
      child: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: style.activeThumb,
        activeTrackColor: style.activeTrack,
        inactiveThumbColor: style.inactiveThumb,
        inactiveTrackColor: style.inactiveTrack,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bubbleWidth = screenWidth - (AppSpacing.md * 2); // 좌우 여백 제외

    // 색상 결정 로직
    final Color bgColor =
        widget.bgGreen ? AppColors.bgSoftMint : BubbleTokens.emotionBg;
    final Color borderColor =
        widget.bgGreen ? AppColors.borderLightGray : BubbleTokens.emotionBorder;

    // 삼각형 색상: bgGreen이면 natureGreen, 아니면 기본(userBg)
    final Color triangleColor =
        widget.bgGreen ? AppColors.natureGreen : BubbleTokens.userBg;

    return GestureDetector(
      onTap: widget.onTap,
      child: Center(
        child: Container(
          width: bubbleWidth, // 명확한 너비 지정 (화면 전체 - 좌우 여백)
          constraints: const BoxConstraints(
            minHeight: 60.0, // 최소 높이 (1줄 정도)
            maxHeight: 144.0, // 최대 높이 (4줄 크기)
          ),
          decoration: BoxDecoration(
            color: bgColor,
            border: Border.all(
              color: borderColor,
              width: BubbleTokens.borderWidth,
            ),
            borderRadius:
                BorderRadius.circular(BubbleTokens.emotionRadius), // 12.0
          ),
          child: Stack(
            children: [
              // TTS 토글 (우측 상단)
              if (widget.showTtsToggle)
                Positioned(
                  top: 8,
                  right: 12,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '목소리 듣기',
                        style: AppTypography.caption.copyWith(
                          color: BubbleTokens.emotionText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildToggle(
                        value: widget.ttsEnabled,
                        onChanged: widget.onTtsToggle,
                        style: ToggleStyle.primary(),
                      ),
                    ],
                  ),
                ),

              // 스크롤 가능한 텍스트 영역
              Padding(
                padding: EdgeInsets.only(
                  left: AppSpacing.lg, // 좌측 패딩 (32.0)
                  right: AppSpacing.lg, // 우측 패딩 (32.0)
                  top: widget.showTtsToggle
                      ? 40.0
                      : AppSpacing.md, // TTS 토글 공간 확보
                  bottom: AppSpacing.md, // 하단 패딩 (24.0)
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                  controller: _scrollController,
                  child: Text(
                    _displayedText,
                    textAlign: TextAlign.left, // 왼쪽 정렬
                        maxLines: 4, // 최대 4줄
                        overflow: TextOverflow.visible,
                    style: AppTypography.bodyBold.copyWith(
                      color: BubbleTokens.emotionText, // #233446
                    ),
                  ),
                    );
                  },
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
                          color: triangleColor,
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
