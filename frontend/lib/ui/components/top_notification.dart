import 'dart:async';
import 'package:flutter/material.dart';
import '../tokens/app_tokens.dart';

enum TopNotificationType {
  red,
  green,
}

/// 상단 알림 배너
///
/// 화면 상단 (TopBar 아래)에 전체 너비로 표시되는 알림입니다.
class TopNotification extends StatelessWidget {
  const TopNotification({
    super.key,
    required this.message,
    this.actionLabel,
    this.onActionTap,
    this.type = TopNotificationType.red,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onActionTap;
  final TopNotificationType type;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: _getBackgroundColor(),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                message,
                style: AppTypography.body.copyWith(
                  color: AppColors.basicColor,
                ),
              ),
            ),
            if (actionLabel != null && onActionTap != null)
              GestureDetector(
                onTap: onActionTap,
                child: Text(
                  actionLabel!,
                  style: AppTypography.body.copyWith(
                    color: AppColors.basicColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (type) {
      case TopNotificationType.red:
        return AppColors.primaryColor;
      case TopNotificationType.green:
        return AppColors.secondaryColor;
    }
  }
}

/// TopNotification 관리자
///
/// 오버레이를 통해 화면 최상단에 알림을 표시하고 관리합니다.
class TopNotificationManager {
  static OverlayEntry? _overlayEntry;
  static Timer? _overlayTimer;

  /// 알림 표시
  static void show(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onActionTap,
    TopNotificationType type = TopNotificationType.red,
    Duration duration = const Duration(milliseconds: 2000),
  }) {
    // 기존 알림 제거
    remove();

    _overlayEntry = OverlayEntry(
      builder: (context) {
        final topPadding = MediaQuery.of(context).padding.top;
        // TopBar 높이(60) + 상단 패딩 아래에 위치
        final positionTop = topPadding + 60.0;

        return Positioned(
          top: positionTop,
          left: 0,
          right: 0,
          child: TopNotification(
            message: message,
            actionLabel: actionLabel,
            onActionTap: () {
              // 액션 실행 시 알림 닫고 콜백 호출
              remove();
              onActionTap?.call();
            },
            type: type,
          ),
        );
      },
    );

    // 오버레이 삽입
    Overlay.of(context).insert(_overlayEntry!);

    // 자동 닫기 타이머
    _overlayTimer = Timer(duration, () {
      remove();
    });
  }

  /// 알림 제거
  static void remove() {
    _overlayTimer?.cancel();
    _overlayTimer = null;
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}
