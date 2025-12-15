import 'package:flutter/material.dart';
import '../../../../ui/tokens/app_tokens.dart';
import 'timeline_content_card.dart';
import 'timeline_empty_card.dart';

class DailyTimelineItem extends StatelessWidget {
  final int day;
  final String weekday; // "Sunday", "Monday" etc.
  final bool isToday;
  final List<TimelineEventData> events; // If empty, show EmptyCard

  const DailyTimelineItem({
    super.key,
    required this.day,
    required this.weekday,
    this.isToday = false,
    required this.events,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Header
          Container(
            width: double.infinity,
            height: 32,
            margin: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                // Day Number (e.g., "21")
                Text(
                  '$day',
                  style: const TextStyle(
                    color: Color(0xFF243447),
                    fontSize: 24,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w700,
                    height: 1.33,
                  ),
                ),
                const SizedBox(width: 8),
                // Weekday (e.g., "일요일")
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    weekday,
                    style: const TextStyle(
                      color: Color(0xFF999999),
                      fontSize: 16,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w500,
                      height: 1.50,
                    ),
                  ),
                ),
                // Today Badge
                if (isToday) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: ShapeDecoration(
                      color: const Color(0xFFE8F5F5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                    child: const Text(
                      '오늘',
                      style: TextStyle(
                        color: Color(0xFF4ECDC4),
                        fontSize: 12,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w600,
                        height: 1.33,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Content
          if (events.isEmpty)
             const TimelineEmptyCard()
          else
            Column(
              children: events.map((event) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TimelineContentCard(
                  time: event.time,
                  endTime: event.endTime,
                  title: event.title,
                  subtitle: event.subtitle,
                  tags: event.tags,
                  countText: event.countText,
                  backgroundColor: event.backgroundColor,
                  titleColor: event.titleColor,
                  subtitleColor: event.subtitleColor,
                  tagColor: event.tagColor,
                ),
              )).toList(),
            ),
        ],
      ),
    );
  }
}

class TimelineEventData {
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

  TimelineEventData({
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
}
