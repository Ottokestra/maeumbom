import 'package:flutter/material.dart';
import '../app_ui.dart';

/// 하단 추가 모달 바

/// Bottom Sheet 컴포넌트입니다.
/// 타이틀과 컨텐츠를 주입받아 모달 형태로 표시합니다.
class BottomAddModalBar extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback? onClose;

  const BottomAddModalBar({
    super.key,
    required this.title,
    required this.child,
    this.onClose,
  });

  /// 모달 표시 헬퍼 메서드
  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required Widget child,
    bool isScrollControlled = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: isScrollControlled,
      builder: (context) => BottomAddModalBar(
        title: title,
        onClose: () => Navigator.pop(context),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.basicColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppRadius.xxl),
          topRight: Radius.circular(AppRadius.xxl),
        ),
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: AppSpacing.md + MediaQuery.of(context).viewInsets.bottom, // 키보드 대응
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 헤더 (타이틀 + 닫기 핸들/버튼)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 타이틀에 맞는 여백 유지를 위한 빈 아이콘
              const SizedBox(width: 24),
              Text(
                title,
                style: AppTypography.h3.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              // 닫기 버튼 (옵션)
              GestureDetector(
                onTap: onClose,
                child: const Icon(
                  Icons.close_rounded,
                  color: AppColors.textSecondary,
                  size: 24,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.lg),

          // 컨텐츠
          child,
          
          // 하단 안전 영역
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
