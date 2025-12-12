import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/typography.dart';
import '../tokens/spacing.dart';
import '../tokens/radius.dart';

/// 메시지 다이얼로그 타입
enum MessageDialogType {
  red,
  green,
}

/// 메시지 다이얼로그
///
/// 이미지의 UI를 참고하여 만든 팝업 메시지 창입니다.
/// - 중앙 원형 아이콘
/// - 제목 및 본문 텍스트
/// - 메인 버튼 (accentRed 또는 secondaryColor)
/// - 보조 버튼 (회색)
class MessageDialog extends StatelessWidget {
  const MessageDialog({
    super.key,
    this.icon,
    required this.title,
    required this.message,
    required this.primaryButtonText,
    this.secondaryButtonText,
    this.onPrimaryPressed,
    this.onSecondaryPressed,
    this.type = MessageDialogType.red,
  });

  /// 상단 아이콘 (선택사항)
  final IconData? icon;

  /// 제목
  final String title;

  /// 본문 메시지
  final String message;

  /// 메인 버튼 텍스트
  final String primaryButtonText;

  /// 보조 버튼 텍스트 (선택사항)
  final String? secondaryButtonText;

  /// 메인 버튼 콜백
  final VoidCallback? onPrimaryPressed;

  /// 보조 버튼 콜백
  final VoidCallback? onSecondaryPressed;

  /// 다이얼로그 타입 (red 또는 green)
  final MessageDialogType type;

  @override
  Widget build(BuildContext context) {
    final primaryColor = type == MessageDialogType.red
        ? AppColors.primaryColor
        : AppColors.secondaryColor;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 아이콘 (선택사항)
            if (icon != null) ...[
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 40,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // 제목
            Text(
              title,
              style: AppTypography.h3.copyWith(
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),

            // 본문 메시지
            Text(
              message,
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),

            // 버튼들
            Column(
              children: [
                // 메인 버튼
                _PrimaryButton(
                  text: primaryButtonText,
                  color: primaryColor,
                  onPressed: onPrimaryPressed,
                ),

                // 보조 버튼 (있을 경우)
                if (secondaryButtonText != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  _SecondaryButton(
                    text: secondaryButtonText!,
                    onPressed: onSecondaryPressed,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 메인 버튼 (색상 배경)
class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.text,
    required this.color,
    this.onPressed,
  });

  final String text;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: AppColors.textWhite,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: AppTypography.bodyBold,
        ),
        child: Text(text),
      ),
    );
  }
}

/// 보조 버튼 (회색 배경)
class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.text,
    this.onPressed,
  });

  final String text;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.disabledBg,
          foregroundColor: AppColors.textSecondary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: AppTypography.bodyBold,
        ),
        child: Text(text),
      ),
    );
  }
}

/// MessageDialog를 표시하는 헬퍼 함수
class MessageDialogHelper {
  // ========================================
  // Confirm 다이얼로그 (2개 버튼)
  // ========================================

  /// Red 타입 Confirm 다이얼로그 (확인 필요)
  /// 예: 삭제 확인, 권한 요청 등
  static Future<void> showRedConfirm(
    BuildContext context, {
    IconData? icon,
    required String title,
    required String message,
    required String primaryButtonText,
    required String secondaryButtonText,
    VoidCallback? onPrimaryPressed,
    VoidCallback? onSecondaryPressed,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => MessageDialog(
        icon: icon,
        title: title,
        message: message,
        primaryButtonText: primaryButtonText,
        secondaryButtonText: secondaryButtonText,
        onPrimaryPressed: onPrimaryPressed,
        onSecondaryPressed: onSecondaryPressed,
        type: MessageDialogType.red,
      ),
    );
  }

  /// Green 타입 Confirm 다이얼로그 (확인 필요)
  /// 예: 저장 확인, 공유 선택 등
  static Future<void> showGreenConfirm(
    BuildContext context, {
    IconData? icon,
    required String title,
    required String message,
    required String primaryButtonText,
    required String secondaryButtonText,
    VoidCallback? onPrimaryPressed,
    VoidCallback? onSecondaryPressed,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => MessageDialog(
        icon: icon,
        title: title,
        message: message,
        primaryButtonText: primaryButtonText,
        secondaryButtonText: secondaryButtonText,
        onPrimaryPressed: onPrimaryPressed,
        onSecondaryPressed: onSecondaryPressed,
        type: MessageDialogType.green,
      ),
    );
  }

  // ========================================
  // Alert 다이얼로그 (1개 버튼)
  // ========================================

  /// Red 타입 Alert 다이얼로그 (단순 알림)
  /// 예: 에러 메시지, 경고 알림 등
  static Future<void> showRedAlert(
    BuildContext context, {
    IconData? icon,
    required String title,
    required String message,
    String primaryButtonText = '확인',
    VoidCallback? onPressed,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => MessageDialog(
        icon: icon,
        title: title,
        message: message,
        primaryButtonText: primaryButtonText,
        onPrimaryPressed: onPressed ?? () => Navigator.pop(context),
        type: MessageDialogType.red,
      ),
    );
  }

  /// Green 타입 Alert 다이얼로그 (단순 알림)
  /// 예: 성공 메시지, 완료 알림 등
  static Future<void> showGreenAlert(
    BuildContext context, {
    IconData? icon,
    required String title,
    required String message,
    String primaryButtonText = '확인',
    VoidCallback? onPressed,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => MessageDialog(
        icon: icon,
        title: title,
        message: message,
        primaryButtonText: primaryButtonText,
        onPrimaryPressed: onPressed ?? () => Navigator.pop(context),
        type: MessageDialogType.green,
      ),
    );
  }

  // ========================================
  // 레거시 메서드 (하위 호환성)
  // ========================================

  /// Red 타입 다이얼로그 표시
  /// @deprecated showRedConfirm 또는 showRedAlert 사용 권장
  static Future<void> showRed(
    BuildContext context, {
    IconData? icon,
    required String title,
    required String message,
    required String primaryButtonText,
    String? secondaryButtonText,
    VoidCallback? onPrimaryPressed,
    VoidCallback? onSecondaryPressed,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => MessageDialog(
        icon: icon,
        title: title,
        message: message,
        primaryButtonText: primaryButtonText,
        secondaryButtonText: secondaryButtonText,
        onPrimaryPressed: onPrimaryPressed,
        onSecondaryPressed: onSecondaryPressed,
        type: MessageDialogType.red,
      ),
    );
  }

  /// Green 타입 다이얼로그 표시
  /// @deprecated showGreenConfirm 또는 showGreenAlert 사용 권장
  static Future<void> showGreen(
    BuildContext context, {
    IconData? icon,
    required String title,
    required String message,
    required String primaryButtonText,
    String? secondaryButtonText,
    VoidCallback? onPrimaryPressed,
    VoidCallback? onSecondaryPressed,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => MessageDialog(
        icon: icon,
        title: title,
        message: message,
        primaryButtonText: primaryButtonText,
        secondaryButtonText: secondaryButtonText,
        onPrimaryPressed: onPrimaryPressed,
        onSecondaryPressed: onSecondaryPressed,
        type: MessageDialogType.green,
      ),
    );
  }

  /// 일반 다이얼로그 표시 (타입 선택 가능)
  /// @deprecated 명확한 메서드 사용 권장
  static Future<void> show(
    BuildContext context, {
    IconData? icon,
    required String title,
    required String message,
    required String primaryButtonText,
    String? secondaryButtonText,
    VoidCallback? onPrimaryPressed,
    VoidCallback? onSecondaryPressed,
    MessageDialogType type = MessageDialogType.red,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => MessageDialog(
        icon: icon,
        title: title,
        message: message,
        primaryButtonText: primaryButtonText,
        secondaryButtonText: secondaryButtonText,
        onPrimaryPressed: onPrimaryPressed,
        onSecondaryPressed: onSecondaryPressed,
        type: type,
      ),
    );
  }
}
