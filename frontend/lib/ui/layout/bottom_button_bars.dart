import 'package:flutter/material.dart';
import '../tokens/app_tokens.dart';
import '../components/app_component.dart';

enum BottomButtonBarStyle {
  pill, // 기존 스타일 (현재 사용 중)
  block, // Figma의 129/246 split block 스타일
}

/// Bottom Bar - Button Bar (1~2개 버튼)
class BottomButtonBar extends StatelessWidget {
  const BottomButtonBar({
    super.key,
    this.primaryText = '확인',
    this.secondaryText,
    this.onPrimaryTap,
    this.onSecondaryTap,
    this.style = BottomButtonBarStyle.pill,
    this.backgroundColor = AppColors.basicColor,
    this.primaryButtonColor = AppColors.primaryColor,
  });

  final String primaryText;
  final String? secondaryText;
  final VoidCallback? onPrimaryTap;
  final VoidCallback? onSecondaryTap;
  final BottomButtonBarStyle style;
  final Color backgroundColor;
  final Color primaryButtonColor;

  @override
  Widget build(BuildContext context) {
    switch (style) {
      case BottomButtonBarStyle.block:
        return _buildBlockBar(context);
      case BottomButtonBarStyle.pill:
        return _buildPillBar(context);
    }
  }

  Widget _buildPillBar(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      height: 96 + bottomPadding,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm + bottomPadding,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
      ),
      child: Row(
        children: [
          if (secondaryText != null) ...[
            Expanded(
              flex: 1,
              child: AppButton(
                text: secondaryText!,
                variant: ButtonVariant.secondaryRed,
                onTap: onSecondaryTap,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          Expanded(
            flex: 2,
            child: AppButton(
              text: primaryText,
              variant: ButtonVariant.primaryRed,
              onTap: onPrimaryTap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockBar(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      height: 70 + bottomPadding,
      width: double.infinity,
      decoration: BoxDecoration(
        color: backgroundColor,
      ),
      child: Row(
        children: [
          if (secondaryText != null) ...[
            Expanded(
              flex: 1,
              child: Material(
                color: const Color(0xFF6B6B6B),
                child: InkWell(
                  onTap: onSecondaryTap,
                  child: Container(
                    height: double.infinity,
                    padding: EdgeInsets.only(bottom: bottomPadding + 10),
                    child: Center(
                      child: SizedBox(
                        height: 64,
                        child: Center(
                          child: Text(
                            secondaryText!,
                            textAlign: TextAlign.center,
                            style: AppTypography.bodyLarge.copyWith(
                              color: AppColors.textWhite,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
          Expanded(
            flex: 2,
            child: Material(
              color: primaryButtonColor,
              child: InkWell(
                onTap: onPrimaryTap,
                child: Container(
                  height: double.infinity,
                  padding: EdgeInsets.only(bottom: bottomPadding + 10),
                  child: Center(
                    child: SizedBox(
                      height: 64,
                      child: Center(
                        child: Text(
                          primaryText,
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyLarge.copyWith(
                            color: AppColors.textWhite,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
