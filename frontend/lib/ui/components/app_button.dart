import 'package:flutter/material.dart';
import 'buttons.dart';

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.text,
    required this.variant,
    this.onTap,
  });

  final String text;
  final ButtonVariant variant;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bg = _background();
    final border = _border();
    final textColor = _textColor();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: ButtonTokens.height,
        padding: ButtonTokens.padding,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(ButtonTokens.radius),
          border: border,
        ),
        child: Center(
          child: Text(
            text,
            style: ButtonTokens.textStyle.copyWith(color: textColor),
          ),
        ),
      ),
    );
  }

  Color _background() {
    switch (variant) {
      case ButtonVariant.primaryRed:
        return ButtonTokens.primaryRedBg;
      case ButtonVariant.secondaryRed:
        return ButtonTokens.secondaryRedBg;
      case ButtonVariant.primaryGreen:
        return ButtonTokens.primaryGreenBg;
      case ButtonVariant.secondaryGreen:
        return ButtonTokens.secondaryGreenBg;
    }
  }

  Border? _border() {
    switch (variant) {
      case ButtonVariant.secondaryRed:
        return Border.all(color: ButtonTokens.secondaryRedBorder, width: 2);
      case ButtonVariant.secondaryGreen:
        return Border.all(color: ButtonTokens.secondaryGreenBorder, width: 2);
      default:
        return null;
    }
  }

  Color _textColor() {
    switch (variant) {
      case ButtonVariant.primaryRed:
        return ButtonTokens.primaryRedText;
      case ButtonVariant.secondaryRed:
        return ButtonTokens.secondaryRedText;
      case ButtonVariant.primaryGreen:
        return ButtonTokens.primaryGreenText;
      case ButtonVariant.secondaryGreen:
        return ButtonTokens.secondaryGreenText;
    }
  }
}
