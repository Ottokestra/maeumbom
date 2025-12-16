import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../tokens/app_tokens.dart';
import '../components/inputs.dart';

/// Bottom Bar - Input Bar (음성/텍스트 입력)
///
/// 텍스트 입력 필드와 마이크/전송 버튼을 제공합니다.
/// - 기본 상태: 텍스트 입력 필드 + 마이크 버튼
/// - 텍스트 입력 시: 텍스트 입력 필드 + 전송 버튼
class BottomInputBar extends StatefulWidget {
  const BottomInputBar({
    super.key,
    required this.controller,
    this.hintText = '메시지를 입력하세요',
    this.onSend,
    this.onMicTap,
    this.onTypingStarted,
    this.backgroundColor = AppColors.basicColor,
  });

  /// 텍스트 입력 컨트롤러
  final TextEditingController controller;

  /// 힌트 텍스트
  final String hintText;

  /// 전송 버튼 탭 콜백
  final VoidCallback? onSend;

  /// 마이크 버튼 탭 콜백
  final VoidCallback? onMicTap;

  /// 입력 시작 콜백 (첫 글자 입력 시)
  final VoidCallback? onTypingStarted;

  /// 배경색
  final Color backgroundColor;

  @override
  State<BottomInputBar> createState() => _BottomInputBarState();
}

class _BottomInputBarState extends State<BottomInputBar> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _hasText = widget.controller.text.trim().isNotEmpty;
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    if (_hasText != hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  void _handleSend() {
    if (_hasText && widget.onSend != null) {
      widget.onSend!();
    }
  }

  void _handleMicTap() {
    if (widget.onMicTap != null) {
      widget.onMicTap!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      // 키보드 높이(bottomInset)가 있으면 그만큼 올리고, 없으면 기본 하단 패딩 사용
      padding: EdgeInsets.only(
        bottom: bottomInset > 0 ? bottomInset : 0,
      ),
      child: Container(
        // 기본 높이 없이 내용물에 맞춤, 배경색은 패딩을 포함하지 않도록 주의 필요하나
        // AppFrame의 bottomNavigationBar 위치 특성상 배경이 끊길 수 있음.
        // 하지만 사용자 예시는 "Floating" 스타일처럼 보임 (SafeArea + Container margin/padding).
        // 기존 디자인(꽉 찬 배경)을 유지하려면 Container가 바깥에 있어야 하는데...
        // AppFrame의 bottomNavigationBar는 화면 하단 고정임.
        // AnimatedPadding을 주면 내용물이 위로 올라감. Background는?
        // 사용자의 의도는 "Input Bar 위젯 자체가 위로 올라감"임. 
        // 배경색을 이 Container에 주면 키보드 따라 올라가는 Bar가 됨.
        // 키보드 아래 영역(bottomInset)은 비어보일 수 있음 (AppFrame background color가 보임).
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          // 상단 테두리 추가 (기존 스타일 유지 시 필요할 수 있음)
        ),
        child: Padding(
          // 아이폰 하단 인디케이터 영역 처리 (키보드 없을 때)
          // 키보드 있을 때는 bottomInset에 포함되거나 0임.
          padding: EdgeInsets.only(
            bottom: bottomInset > 0 ? 0 : bottomPadding,
            top: 10, // 상단 여백
            left: 20,
            right: 20,
          ),
          child: SizedBox(
            height: 60, // 내부 높이 고정 (기존 100 height - padding 고려)
            child: Row(
              children: [
                // 텍스트 입력 필드
                Expanded(
                  child: _ChatInput(
                    controller: widget.controller,
                    hintText: widget.hintText,
                    onSubmitted: _hasText ? _handleSend : null,
                    onTypingStarted: widget.onTypingStarted,
                  ),
                ),
                const SizedBox(width: 8),
                // 마이크/전송 버튼 (토글)
                GestureDetector(
                  onTap: _hasText ? _handleSend : _handleMicTap,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, animation) {
                          return ScaleTransition(
                            scale: animation,
                            child: child,
                          );
                        },
                        child: _hasText
                            ? SizedBox.fromSize(
                                key: const ValueKey('send'),
                                size: AppIconSizes.xlSize,
                                child: SvgPicture.asset(
                                  'assets/images/icons/icon-send.svg',
                                  fit: BoxFit.contain,
                                  colorFilter: const ColorFilter.mode(
                                    AppColors.textWhite,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              )
                            : Icon(
                                key: const ValueKey('mic'),
                                Icons.mic,
                                size: 28,
                                color: AppColors.textWhite,
                              ),
                      ),
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

/// Chat Input - 엔터 키로 전송 가능한 입력 필드
class _ChatInput extends StatefulWidget {
  const _ChatInput({
    required this.controller,
    required this.hintText,
    this.onSubmitted,
    this.onTypingStarted,
  });

  final TextEditingController controller;
  final String hintText;
  final VoidCallback? onSubmitted;
  final VoidCallback? onTypingStarted;

  @override
  State<_ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<_ChatInput> {
  bool _hasTyped = false;

  @override
  void initState() {
    super.initState();
    // 컨트롤러 리스너 추가하여 텍스트가 비워지면 초기화
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    // 텍스트가 완전히 비워지면 _hasTyped 초기화
    if (widget.controller.text.isEmpty && _hasTyped) {
      setState(() {
        _hasTyped = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: InputTokens.height,
      padding: InputTokens.padding,
      decoration: BoxDecoration(
        color: InputTokens.normalBg,
        borderRadius: BorderRadius.circular(InputTokens.radius),
        border: Border.all(color: InputTokens.normalBorder, width: 1),
      ),
      child: TextField(
        controller: widget.controller,
        style: InputTokens.textStyle.copyWith(
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: InputTokens.textStyle.copyWith(
            color: AppColors.textSecondary,
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
        textInputAction: TextInputAction.send,
        onChanged: (text) {
          print('[BottomInputBar] onChanged: text.length=${text.length}, _hasTyped=$_hasTyped');
          // 첫 글자 입력 시 콜백 호출
          if (!_hasTyped && text.isNotEmpty && widget.onTypingStarted != null) {
            print('[BottomInputBar] 🎯 Calling onTypingStarted!');
            _hasTyped = true;
            widget.onTypingStarted!();
          }
        },
        onSubmitted: (_) {
          if (widget.onSubmitted != null) {
            widget.onSubmitted!();
          }
        },
      ),
    );
  }
}
