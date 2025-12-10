import 'package:flutter/material.dart';

/// 알람 정보 팝업
/// response_type이 "alarm"일 때 표시되는 다이얼로그
class AlarmDialog extends StatelessWidget {
  final Map<String, dynamic> alarmInfo;
  final String? replyText;

  const AlarmDialog({
    super.key,
    required this.alarmInfo,
    this.replyText,
  });

  @override
  Widget build(BuildContext context) {
    final count = alarmInfo['count'] ?? 0;
    final data = (alarmInfo['data'] as List<dynamic>?) ?? [];
    final message = alarmInfo['message'] as String?;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 알람 카드들
            if (data.isNotEmpty) ...[
              ...data.map((alarm) => _buildAlarmCard(alarm)).toList(),
              const SizedBox(height: 16),
            ],

            // 경고 메시지 또는 일반 메시지
            if (message != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.pink.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            else if (replyText != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.pink.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  replyText!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            const SizedBox(height: 16),

            // 버튼들 (나중에 등록 기능 추가 예정)
            const Text(
              '불이엔 대화해볼세요',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlarmCard(Map<String, dynamic> alarm) {
    final year = alarm['year'] ?? 2025;
    final month = alarm['month'] ?? 1;
    final day = alarm['day'] ?? 1;
    final week = (alarm['week'] as List?)?.first ?? 'Mon';
    final isValid = alarm['is_valid_alarm'] ?? false;

    // 요일 한글 변환
    final weekKr = _convertWeekdayToKorean(week);

    String timeDisplay = '';
    if (isValid && alarm['time'] != null) {
      final time = alarm['time'];
      final minute = alarm['minute'] ?? 0;
      final amPm = alarm['am_pm'] ?? 'AM';
      timeDisplay =
          '${time.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} ${amPm.toUpperCase()}';
    } else {
      timeDisplay = '과거 날짜';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isValid ? Colors.pink.withOpacity(0.3) : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // 날짜 정보
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                year.toString(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${month.toString().padLeft(2, '0')}/${day.toString().padLeft(2, '0')} $weekKr',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Spacer(),
          // 시간 정보
          Text(
            timeDisplay,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: isValid ? Colors.black : Colors.grey.shade600,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  String _convertWeekdayToKorean(String week) {
    const weekMap = {
      'Monday': '월',
      'Tuesday': '화',
      'Wednesday': '수',
      'Thursday': '목',
      'Friday': '금',
      'Saturday': '토',
      'Sunday': '일',
    };
    return weekMap[week] ?? week;
  }
}

/// Warning 다이얼로그 (알람 3개 초과)
class AlarmWarningDialog extends StatelessWidget {
  final Map<String, dynamic> alarmInfo;

  const AlarmWarningDialog({
    super.key,
    required this.alarmInfo,
  });

  @override
  Widget build(BuildContext context) {
    final message =
        alarmInfo['message'] as String? ?? '알람은 한번의 요청에서 세개까지만 등록이 가능합니다.';
    final count = alarmInfo['count'] ?? 0;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 60,
            color: Colors.orange,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '요청하신 알람: ${count}개',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('확인'),
        ),
      ],
    );
  }
}
