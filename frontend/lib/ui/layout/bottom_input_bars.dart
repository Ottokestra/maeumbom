import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../tokens/app_tokens.dart';
import '../components/app_component.dart';
import '../components/inputs.dart';

/// Bottom Bar - Input Bar (텍스트 입력 + 전송)
class BottomInputBar extends StatefulWidget {
  const BottomInputBar({
    super.key,
    required this.controller,
    this.hintText = '메시지를 입력하세요',
    this.onSend,
    this.onMicrophoneTap,
    this.backgroundColor = AppColors.pureWhite,
    this.iconColor = AppColors.textPrimary,
  });

  final TextEditingController controller;
  final String hintText;
  final VoidCallback? onSend;
  final VoidCallback? onMicrophoneTap;
  final Color backgroundColor;
  final Color iconColor;

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

  void _handleMicrophoneTap() {
    if (widget.onMicrophoneTap != null) {
      widget.onMicrophoneTap!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      height: 100 + bottomPadding,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: Stack(
          children: [
            Positioned(
              left: 20,
              top: 24,
              right: 20,
              child: Row(
                children: [
                  Expanded(
                    child: _ChatInput(
                      controller: widget.controller,
                      hintText: widget.hintText,
                      onSubmitted: _hasText ? _handleSend : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _hasText ? _handleSend : _handleMicrophoneTap,
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: Center(
                        child: SizedBox.fromSize(
                          size: AppIconSizes.xlSize,
                          child: SvgPicture.asset(
                            _hasText
                                ? 'assets/images/icons/icon-send.svg'
                                : 'assets/images/icons/icon-simple-mic.svg',
                            fit: BoxFit.contain,
                            colorFilter: ColorFilter.mode(
                              _hasText
                                  ? AppColors.accentRed
                                  : widget.iconColor,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Chat Input - 엔터 키로 전송 가능한 입력 필드
class _ChatInput extends StatelessWidget {
  const _ChatInput({
    required this.controller,
    required this.hintText,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hintText;
  final VoidCallback? onSubmitted;

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
        controller: controller,
        style: InputTokens.textStyle.copyWith(
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: InputTokens.textStyle.copyWith(
            color: AppColors.textSecondary,
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
        textInputAction: TextInputAction.send,
        onSubmitted: (_) {
          if (onSubmitted != null) {
            onSubmitted!();
          }
        },
      ),
    );
  }
}
