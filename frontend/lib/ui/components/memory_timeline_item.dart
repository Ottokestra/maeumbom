import 'package:flutter/material.dart';
import '../../data/models/memory/memory_item.dart';
import '../tokens/app_tokens.dart';
import 'tag_badge.dart';

/// 기억서랍 타임라인 아이템
/// 과거 기억과 미래 일정을 타임라인 형식으로 표시하는 컴포넌트
///
/// PROMPT_GUIDE.md 준수:
/// - Card/ListTile 사용 금지
/// - 디자인 토큰만 사용
/// - 감정적 UI (과거=회색, 미래=핑크)
/// - 세로 연결선으로 이야기 흐름 표현
class MemoryTimelineItem extends StatelessWidget {
  final MemoryItem memory;
  final bool showTopLine; // 이전 항목과 연결
  final bool showBottomLine; // 다음 항목과 연결
  final VoidCallback? onTap;

  const MemoryTimelineItem({
    super.key,
    required this.memory,
    this.showTopLine = false,
    this.showBottomLine = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 왼쪽: 타임라인 인디케이터 (날짜 뱃지 + 세로 연결선)
          _buildTimelineIndicator(),
          SizedBox(width: AppSpacing.sm),
          // 오른쪽: 메모리 버블
          Expanded(
            child: _buildMemoryBubble(context),
          ),
        ],
      ),
    );
  }

  /// 타임라인 인디케이터 (왼쪽)
  /// 날짜 뱃지와 세로 연결선으로 구성
  Widget _buildTimelineIndicator() {
    return SizedBox(
      width: 64,
      child: Column(
        children: [
          // 위쪽 연결선
          if (showTopLine)
            Container(
              width: 2,
              height: AppSpacing.sm,
              color: AppColors.borderLightGray.withOpacity(0.5),
            ),

          // 날짜 인디케이터 뱃지 (예: "16화")
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.xxs,
            ),
            decoration: BoxDecoration(
              color: memory.isPast
                  ? AppColors.textSecondary.withOpacity(0.1)
                  : AppColors.bgLightPink,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(
                color: AppColors.borderLightGray,
                width: 1,
              ),
            ),
            child: Text(
              memory.dateIndicator,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // 아래쪽 연결선
          if (showBottomLine)
            Expanded(
              child: Container(
                width: 2,
                color: AppColors.borderLightGray.withOpacity(0.5),
                margin: EdgeInsets.only(top: AppSpacing.xs),
              ),
            ),
        ],
      ),
    );
  }

  /// 메모리 버블 (오른쪽)
  /// 시간 + 카테고리 배지 + 내용 텍스트
  Widget _buildMemoryBubble(BuildContext context) {
    // 배경색: 과거=연한 회색, 미래=핑크
    final bgColor = memory.isPast
        ? AppColors.basicGray.withOpacity(0.3)
        : AppColors.bgLightPink;

    final borderColor = memory.isPast
        ? AppColors.borderLightGray
        : AppColors.borderLight;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: AppSpacing.sm),
        padding: EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(
            color: borderColor,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단: 시간 표시 + 카테고리 배지
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 시간 표시 (예: "오후 2:30")
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(width: 6),
                    Text(
                      memory.timeString,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                // 카테고리 배지 (TagBadge 사용)
                TagBadge(
                  text: memory.category.label,
                  emotionId: memory.category.emotionId,
                ),
              ],
            ),

            SizedBox(height: AppSpacing.xs),

            // 내용 텍스트
            Text(
              memory.content,
              style: AppTypography.body.copyWith(
                color: AppColors.textPrimary,
                height: 1.5,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
