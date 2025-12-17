import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../ui/app_ui.dart';
import '../../../providers/target_events_provider.dart';
import '../../../core/utils/logger.dart';

/// 홈 화면 알림 미리보기 컴포넌트 (위에서 아래로 슬라이드)
class HomeAlarmPreview extends ConsumerStatefulWidget {
  const HomeAlarmPreview({super.key});

  @override
  ConsumerState<HomeAlarmPreview> createState() => _HomeAlarmPreviewState();
}

class _HomeAlarmPreviewState extends ConsumerState<HomeAlarmPreview> {
  int _currentIndex = 0;
  Timer? _timer;
  List<AlarmPreviewItem> _alarms = [];
  bool _isLoading = true;

  // 시뮬레이션용 현재 날짜
  final DateTime _simulatedNow = DateTime(2025, 12, 15, 10, 0); // 예: 오전 10시 가정

  @override
  void initState() {
    super.initState();
    _loadAlarms();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// 알람 데이터 로드
  Future<void> _loadAlarms() async {
    try {
      // API Client 직접 사용 (메인 상태와 분리)
      final apiClient = ref.read(targetEventsApiClientProvider);

      // 2025-12-15 부터 7일간 검색
      final response = await apiClient.getDailyEvents(
        startDate: DateTime(2025, 12, 15),
        endDate: DateTime(2025, 12, 22),
        eventType: 'alarm',
      );

      if (mounted) {
        setState(() {
          _alarms = response.dailyEvents.map((event) {
            final eventTime = event.eventTime ?? 
                DateTime(event.eventDate.year, event.eventDate.month, event.eventDate.day, 12, 0);
            
            return AlarmPreviewItem(
              title: event.eventSummary,
              timeRemaining: _calculateTimeRemaining(eventTime),
            );
          }).toList();

          // 데이터가 있으면 타이머 시작
          if (_alarms.isNotEmpty) {
            _startTimer();
          }
          
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          // 에러 시 빈 리스트 유지
        });
      }
      appLogger.e('HomeAlarmPreview load failed', error: e);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted && _alarms.isNotEmpty) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % _alarms.length;
        });
      }
    });
  }

  String _calculateTimeRemaining(DateTime eventTime) {
    
    // 같은 날짜인지 확인
    final isSameDay = eventTime.year == _simulatedNow.year &&
        eventTime.month == _simulatedNow.month &&
        eventTime.day == _simulatedNow.day;

    if (isSameDay) {
      final hour = eventTime.hour;
      final minute = eventTime.minute;
      final amPm = hour >= 12 ? '오후' : '오전';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      String minStr = minute.toString().padLeft(2, '0');
      return '$amPm $displayHour:$minStr';
    } else {
      // 다른 날짜면 날짜 표시 (M월 d일)
      return '${eventTime.month}월 ${eventTime.day}일';
    }
  }

  @override
  Widget build(BuildContext context) {
    // 로딩 중이거나 알람이 없으면 숨김 처리 (또는 빈 컨테이너)
    if (_isLoading || _alarms.isEmpty) {
      // 데이터가 없을 때 표시할 기본 메시지나 숨김 처리
      // 여기서는 빈 공간을 반환하거나, 안내 메시지를 띄울 수 있음.
      // 디자인 가이드에 따라 '일정이 없습니다'를 띄우거나 숨김.
      // 우선 숨김 처리 대신 '예정된 알림이 없습니다' 표시
      if (!_isLoading && _alarms.isEmpty) {
         return Container(
          height: 50,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: AppColors.accentCoral,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              '예정된 알림이 없습니다',
              style: AppTypography.body.copyWith(
                color: AppColors.basicColor,
              ),
            ),
          ),
        );
      }
      return const SizedBox.shrink(); // 로딩 중에는 깜빡임 방지를 위해 숨김
    }

    return Container(
      height: 50,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.accentCoral,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRect(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (Widget child, Animation<double> animation) {
            final slideAnimation = Tween<Offset>(
              begin: const Offset(0.0, -0.3),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutQuart,
            ));

            final fadeAnimation = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            ));

            return SlideTransition(
              position: slideAnimation,
              child: FadeTransition(
                opacity: fadeAnimation,
                child: child,
              ),
            );
          },
          child: _buildAlarmContent(
            _alarms[_currentIndex],
            key: ValueKey<int>(_currentIndex),
          ),
        ),
      ),
    );
  }

  Widget _buildAlarmContent(AlarmPreviewItem alarm, {Key? key}) {
    return Row(
      key: key,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 왼쪽: 새로고침 아이콘 + 타이틀
        Expanded(
          child: Row(
            children: [
              const SizedBox(width: AppSpacing.xs),
              const Icon(
                Icons.notifications_active, // 아이콘 변경
                color: AppColors.basicColor,
                size: 16,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  alarm.title,
                  style: AppTypography.body.copyWith(
                    color: AppColors.basicColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: AppSpacing.sm),

        // 오른쪽: 남은 시간
        Text(
          alarm.timeRemaining,
          style: AppTypography.body.copyWith(
            color: AppColors.basicColor,
          ),
        ),

        const SizedBox(width: AppSpacing.sm),
      ],
    );
  }
}

/// 알람 미리보기 아이템 데이터 모델
class AlarmPreviewItem {
  final String title;
  final String timeRemaining;

  const AlarmPreviewItem({
    required this.title,
    required this.timeRemaining,
  });
}
