import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../tokens/app_tokens.dart';
import '../components/app_component.dart';
import '../components/inputs.dart';
import '../components/slide_to_action_button.dart';
import '../../providers/chat_provider.dart';

/*
 * ORIGINAL IMPLEMENTATION (BACKUP)
 * 
 * 기존 BottomInputBar 구현 (2025-12-08 백업)
 * - TextEditingController 기반 텍스트 입력
 * - 마이크/전송 아이콘 토글
 * 
 * 새로운 구현으로 SlideToActionButton 통합
 */

/// Bottom Bar - Input Bar (음성/텍스트 입력 통합)
///
/// SlideToActionButton을 기반으로 음성 입력과 텍스트 입력을 통합 관리합니다.
/// - 기본 상태: SlideToActionButton 표시
/// - 텍스트 모드: TextField + 전송 버튼 표시
/// - 음성 모드: 음성 상태에 따른 UI 표시
class BottomInputBar extends StatefulWidget {
  const BottomInputBar({
    super.key,
    required this.onVoiceActivated,
    required this.onTextActivated,
    this.onVoiceReset,
    this.onTextReset,
    this.voiceState = VoiceInterfaceState.idle,
    this.controller,
    this.hintText = '메시지를 입력하세요',
    this.onSend,
    this.backgroundColor = AppColors.pureWhite,
  });

  // SlideToActionButton 관련
  final VoidCallback onVoiceActivated;
  final VoidCallback onTextActivated;
  final VoidCallback? onVoiceReset;
  final VoidCallback? onTextReset;
  final VoiceInterfaceState voiceState;

  // 텍스트 입력 관련 (옵션)
  final TextEditingController? controller;
  final String hintText;
  final VoidCallback? onSend;
  final Color backgroundColor;

  @override
  State<BottomInputBar> createState() => _BottomInputBarState();
}

class _BottomInputBarState extends State<BottomInputBar> {
  bool _isTextMode = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _hasText = widget.controller!.text.trim().isNotEmpty;
      widget.controller!.addListener(_onTextChanged);
    }
  }

  @override
  void dispose() {
    if (widget.controller != null) {
      widget.controller!.removeListener(_onTextChanged);
    }
    super.dispose();
  }

  void _onTextChanged() {
    if (widget.controller == null) return;
    final hasText = widget.controller!.text.trim().isNotEmpty;
    if (_hasText != hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  void _handleVoiceActivated() {
    setState(() {
      _isTextMode = false;
    });
    widget.onVoiceActivated();
  }

  void _handleTextActivated() {
    setState(() {
      _isTextMode = true;
    });
    widget.onTextActivated();
  }

  void _handleVoiceReset() {
    setState(() {
      _isTextMode = false;
    });
    if (widget.onVoiceReset != null) {
      widget.onVoiceReset!();
    }
  }

  void _handleTextReset() {
    setState(() {
      _isTextMode = false;
    });
    if (widget.onTextReset != null) {
      widget.onTextReset!();
    }
  }

  void _handleSend() {
    if (_hasText && widget.onSend != null) {
      widget.onSend!();
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
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.3),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: _isTextMode ? _buildTextInputMode() : _buildSlideMode(),
        ),
      ),
    );
  }

  Widget _buildSlideMode() {
    return Padding(
      key: const ValueKey('slide_mode'),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Center(
        child: SlideToActionButton(
          onVoiceActivated: _handleVoiceActivated,
          onTextActivated: _handleTextActivated,
          onVoiceReset: _handleVoiceReset,
          onTextReset: _handleTextReset,
          voiceState: widget.voiceState,
          isTextMode: false,
        ),
      ),
    );
  }

  Widget _buildTextInputMode() {
    return Padding(
      key: const ValueKey('text_mode'),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Center(
        child: Row(
          children: [
            // 뒤로가기 버튼
            GestureDetector(
              onTap: _handleTextReset,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.warmWhite,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: const Center(
                  child: Icon(
                    Icons.arrow_back,
                    size: 24,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // 텍스트 입력 필드
            Expanded(
              child: _ChatInput(
                controller: widget.controller ?? TextEditingController(),
                hintText: widget.hintText,
                onSubmitted: _hasText ? _handleSend : null,
              ),
            ),
            const SizedBox(width: 8),
            // 전송 버튼
            GestureDetector(
              onTap: _hasText ? _handleSend : null,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _hasText ? AppColors.accentRed : AppColors.warmWhite,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Center(
                  child: SizedBox.fromSize(
                    size: AppIconSizes.xlSize,
                    child: SvgPicture.asset(
                      'assets/images/icons/icon-send.svg',
                      fit: BoxFit.contain,
                      colorFilter: ColorFilter.mode(
                        _hasText
                            ? AppColors.textWhite
                            : AppColors.textSecondary,
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
