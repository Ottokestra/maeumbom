import 'package:flutter/material.dart';
import 'inputs.dart';
import '../tokens/app_tokens.dart';

class AppInput extends StatelessWidget {
  const AppInput({
    super.key,
    this.caption,
    this.value,
    this.controller,
    this.hintText,
    this.state = InputState.normal,
  });

  final String? caption;
  final String? value;
  final TextEditingController? controller;
  final String? hintText;
  final InputState state;

  @override
  Widget build(BuildContext context) {
    final border = _border();
    final bg = _background();
    final shadow = _shadow();
    final textColor = _textColor();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (caption != null && caption!.isNotEmpty) ...[
          Text(
            caption!,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          height: InputTokens.height,
          padding: InputTokens.padding,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(InputTokens.radius),
            border: border,
            boxShadow: shadow,
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: _buildInnerField(textColor),
          ),
        ),
      ],
    );
  }

  Widget _buildInnerField(Color textColor) {
    // controller가 있으면 실제 입력 가능한 TextField로 동작
    if (controller != null) {
      final bool isDisabled = state == InputState.disabled;
      return TextField(
        controller: controller,
        enabled: !isDisabled,
        style: InputTokens.textStyle.copyWith(color: textColor),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: InputTokens.textStyle.copyWith(
            color: AppColors.textSecondary,
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
      );
    }

    // 그렇지 않으면 정적인 텍스트 출력
    return Text(
      value ?? '',
      style: InputTokens.textStyle.copyWith(color: textColor),
    );
  }

  Border _border() {
    switch (state) {
      case InputState.focus:
        return Border.all(color: InputTokens.focusBorder, width: 1);
      case InputState.success:
        return Border.all(color: InputTokens.successBorder, width: 1);
      case InputState.disabled:
        return Border.all(color: InputTokens.disabledBorder, width: 1);
      case InputState.error:
        return Border.all(color: InputTokens.errorBorder, width: 1);
      default:
        return Border.all(color: InputTokens.normalBorder, width: 1);
    }
  }

  Color _background() {
    if (state == InputState.disabled) return InputTokens.disabledBg;
    return InputTokens.normalBg;
  }

  List<BoxShadow>? _shadow() {
    switch (state) {
      case InputState.focus:
        return [BoxShadow(color: InputTokens.focusShadow, blurRadius: 4)];
      case InputState.success:
        return [BoxShadow(color: InputTokens.successShadow, blurRadius: 4)];
      case InputState.error:
        return [BoxShadow(color: InputTokens.errorShadow, blurRadius: 4)];
      default:
        return null;
    }
  }

  Color _textColor() {
    return state == InputState.disabled
        ? InputTokens.disabledText
        : AppColors.textPrimary;
  }
}
