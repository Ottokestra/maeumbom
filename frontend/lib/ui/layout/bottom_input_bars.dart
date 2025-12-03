import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../tokens/app_tokens.dart';
import '../components/app_component.dart';

/// Bottom Bar - Input Bar (텍스트 입력 + 전송)
class BottomInputBar extends StatelessWidget {
  const BottomInputBar({
    super.key,
    required this.controller,
    this.hintText = '메시지를 입력하세요',
    this.onSend,
    this.backgroundColor = AppColors.pureWhite,
    this.iconColor = AppColors.textPrimary,
  });

  final TextEditingController controller;
  final String hintText;
  final VoidCallback? onSend;
  final Color backgroundColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      height: 100 + bottomPadding,
      decoration: BoxDecoration(
        color: backgroundColor,
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
                    child: AppInput(
                      controller: controller,
                      hintText: hintText,
                      state: InputState.normal,
                    ),
                  ),
                  const SizedBox(width: 0),
                  GestureDetector(
                    onTap: onSend,
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: Center(
                        child: SizedBox.fromSize(
                          size: AppIconSizes.xlSize,
                          child: SvgPicture.asset(
                            'assets/images/icons/icon-simple-mic.svg',
                            fit: BoxFit.contain,
                            colorFilter: ColorFilter.mode(
                              iconColor,
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
