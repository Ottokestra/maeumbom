import 'package:flutter/material.dart';
import '../../../../ui/tokens/app_tokens.dart';

class TimelineEmptyCard extends StatelessWidget {
  const TimelineEmptyCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 88,
      padding: const EdgeInsets.only(left: 16),
      decoration: ShapeDecoration(
        color: Colors.white.withValues(alpha: 0.50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: ShapeDecoration(
              color: const Color(0xFFF3F4F6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            child: Center(
              child: Text(
                '📭',
                style: const TextStyle(
                  fontSize: 18,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                  height: 1.56,
                  letterSpacing: -0.44,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '이 날은 기록이 없어요',
            style: AppTypography.body.copyWith(
              color: const Color(0xFF999999),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
