import 'package:flutter/material.dart';
import '../../../../ui/tokens/app_tokens.dart';

class TimelineContentCard extends StatelessWidget {
  final String time;
  final String endTime;
  final String title;
  final String subtitle;
  final String tags;
  final String countText;
  final Color backgroundColor;
  final Color titleColor;
  final Color subtitleColor;
  final Color tagColor;

  const TimelineContentCard({
    super.key,
    required this.time,
    required this.endTime,
    required this.title,
    required this.subtitle,
    required this.tags,
    required this.countText,
    required this.backgroundColor,
    this.titleColor = Colors.white,
    this.subtitleColor = const Color(0xCCFFFEFE),
    this.tagColor = const Color(0xCCFFFEFE),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140, // Fixed height from design
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time Column
          Container(
            width: 48,
            padding: const EdgeInsets.only(bottom: 100), // Push text up
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  time,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  endTime,
                  style: AppTypography.caption.copyWith(
                    color: const Color(0xFF999999),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Content Card
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
              decoration: ShapeDecoration(
                color: backgroundColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                shadows: [
                  BoxShadow(
                    color: const Color(0x19000000),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                    spreadRadius: -1,
                  ),
                  BoxShadow(
                    color: const Color(0x19000000),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                    spreadRadius: 0,
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: AppTypography.bodyBold.copyWith(
                              color: titleColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: AppTypography.bodySmall.copyWith(
                              color: subtitleColor,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                      // More Icon
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(
                          Icons.more_horiz,
                          size: 16,
                          color: titleColor.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12), // Spacing
                  // Tags Row
                  Row(
                    children: [
                      Icon(Icons.tag, size: 16, color: tagColor),
                      const SizedBox(width: 8),
                      Text(
                        tags,
                        style: AppTypography.bodySmall.copyWith(
                          color: tagColor,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Count Row
                  Row(
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 16, color: tagColor),
                      const SizedBox(width: 8),
                      Text(
                        countText,
                        style: AppTypography.bodySmall.copyWith(
                          color: tagColor,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
