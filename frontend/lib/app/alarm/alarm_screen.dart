import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ui/app_ui.dart';
import '../../ui/components/date_range_selector.dart';
import '../../core/services/navigation/navigation_service.dart';
import '../../core/utils/logger.dart';
import '../../providers/target_events_provider.dart';
import '../../providers/daily_mood_provider.dart';
import '../../data/models/alarm/alarm_model.dart';
import '../../data/models/target_events/daily_event_model.dart';
import 'components/alarm_list_item.dart';
import 'components/timeline_empty_card.dart';

/// 필터 타입
enum AlarmFilterType {
  all('전체'),
  memory('기억'),
  event('이벤트'),
  alarm('알림');

  const AlarmFilterType(this.label);
  final String label;
}

class AlarmScreen extends ConsumerStatefulWidget {
  const AlarmScreen({super.key});

  @override
  ConsumerState<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends ConsumerState<AlarmScreen> {
  // 조회 기준 날짜 (기본값: 오늘)
  late DateTime _startDate;
  late DateTime _endDate;
  
  // 필터 선택 상태
  AlarmFilterType _selectedFilter = AlarmFilterType.all;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // 초기 범위: 오늘부터 +7일
    _startDate = DateTime(now.year, now.month, now.day);
    _endDate = DateTime(now.year, now.month, now.day).add(const Duration(days: 7));

    // 화면 진입 시 이벤트 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEvents();
    });
  }

  @override
  void dispose() {
    // 화면 종료 시 알림도 함께 제거
    TopNotificationManager.remove();
    super.dispose();
  }

  /// 이벤트 로드
  void _loadEvents() {
    ref.read(targetEventsProvider.notifier).loadDailyEvents(
          startDate: _startDate,
          endDate: _endDate,
        );
  }

  /// 이전 기간으로 이동
  void _goToPreviousRange() {
    setState(() {
      final duration = _endDate.difference(_startDate).inDays + 1;
      _startDate = _startDate.subtract(Duration(days: duration));
      _endDate = _endDate.subtract(Duration(days: duration));
    });
    _loadEvents();
  }

  /// 다음 기간으로 이동
  void _goToNextRange() {
    setState(() {
      final duration = _endDate.difference(_startDate).inDays + 1;
      _startDate = _startDate.add(Duration(days: duration));
      _endDate = _endDate.add(Duration(days: duration));
    });
    _loadEvents();
  }

  /// 날짜 범위 선택기 표시
  Future<void> _showDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryColor,
              onPrimary: AppColors.pureWhite,
              onSurface: AppColors.textPrimary,
              surface: AppColors.pureWhite,
            ),
            datePickerTheme: DatePickerThemeData(
              rangeSelectionBackgroundColor: AppColors.accentCoral.withOpacity(0.3),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadEvents();
    }
  }

  /// 월 구분선 위젯
  Widget _buildMonthSeparator(DateTime date) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0, top: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.basicGray.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${date.year}년 ${date.month}월',
              style: AppTypography.caption.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Divider(
              color: AppColors.borderLight,
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }

  /// 날짜 헤더 위젯
  Widget _buildDateHeader(DateTime date, bool isToday) {
    return Row(
      children: [
        Text(
          '${date.day}',
          style: const TextStyle(
            color: Color(0xFF243447),
            fontSize: 24,
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w700,
            height: 1.33,
          ),
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(top: 0),
          child: Text(
            _getWeekdayString(date.weekday),
            style: const TextStyle(
              color: Color(0xFF999999),
              fontSize: 16,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w500,
              height: 1.50,
            ),
          ),
        ),
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
    );
  }

  String _getWeekdayString(int weekday) {
    const weekdays = ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'];
    return weekdays[weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final navigationService = NavigationService(context, ref);
    final eventsState = ref.watch(targetEventsProvider);
    final dailyState = ref.watch(dailyMoodProvider);

    // 현재 감정 가져오기 (기본값: 기쁨)
    final currentEmotion = dailyState.selectedEmotion ?? EmotionId.joy;

    // primaryColor 사용
    const backgroundColor = AppColors.primaryColor;

    // 표시할 날짜 리스트 생성
    final dayCount = _endDate.difference(_startDate).inDays + 1;
    final datesToShow = List.generate(
      dayCount,
      (index) => _startDate.add(Duration(days: index)),
    );
    final now = DateTime.now();

    return AppFrame(
      statusBarStyle: const SystemUiOverlayStyle(
        statusBarColor: AppColors.primaryColor,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      topBar: null,
      useSafeArea: false,
      body: Container(
        color: backgroundColor,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // A. 상단 바 (수동 추가)
              TopBar(
                title: '기억서랍',
                leftIcon: Icons.arrow_back_ios,
                // rightIcon: Icons.history,
                onTapLeft: () => navigationService.navigateToTab(0),
                // onTapRight: () =>
                //     navigationService.navigateToRoute('/alarm/memory'),
                backgroundColor: Colors.transparent,
                foregroundColor: AppColors.basicColor,
              ),

              // C. 날짜 선택기 (기간 표시 및 선택)
              DateRangeSelector(
                selectedDate: _startDate,
                endDate: _endDate,
                onPreviousDay: _goToPreviousRange,
                onNextDay: _goToNextRange,
                onDateTap: _showDateRangePicker,
              ),

              // C-2. 필터 버튼 (전체, 기억, 이벤트, 알림)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.basicColor,
                ),
                child: Row(
                  children: AlarmFilterType.values.map((filter) {
                    final isSelected = _selectedFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedFilter = filter;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryColor
                                : AppColors.basicGray,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primaryColor
                                  : AppColors.borderLight,
                            ),
                          ),
                          child: Text(
                            filter.label,
                            style: AppTypography.body.copyWith(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textSecondary,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // D. 이벤트 리스트 영역 (타임라인 형식)
              Expanded(
                child: ClipRRect(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.basicColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 20,
                          offset: Offset(0, -5),
                        ),
                      ],
                    ),
                    child: eventsState.when(
                      data: (events) => _buildEventsList(events, datesToShow, now),
                      loading: () =>
                          const Center(child: CircularProgressIndicator(
                            color: AppColors.primaryColor,
                          )),
                      error: (error, stack) => Center(
                        child: Text(
                          '오류가 발생했습니다: $error',
                          style: AppTypography.body
                              .copyWith(color: AppColors.errorRed),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 이벤트 리스트 빌드 (타임라인 형식)
  Widget _buildEventsList(List<DailyEventModel> events, List<DateTime> datesToShow, DateTime now) {
    // 필터 적용
    final filteredEvents = _applyFilter(events);
    
    // 날짜별로 이벤트 그룹핑
    final eventsByDate = _groupEventsByDate(filteredEvents);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: () {
            final List<Widget> children = [];
            int? lastMonth;
            int? lastYear;

            for (final date in datesToShow) {
              // 월이 변경되었거나 첫 번째 항목인 경우 구분선 추가
              if (lastMonth != date.month || lastYear != date.year) {
                children.add(_buildMonthSeparator(date));
                lastMonth = date.month;
                lastYear = date.year;
              }

              final isToday = date.year == now.year && 
                             date.month == now.month && 
                             date.day == now.day;
              // 조회 시작일자와 같은지 확인
              final isStartDate = date.year == _startDate.year &&
                                 date.month == _startDate.month &&
                                 date.day == _startDate.day;
              final dateKey = DateTime(date.year, date.month, date.day);
              final dayEvents = eventsByDate[dateKey] ?? [];

              // 이벤트 정렬 (시간순)
              dayEvents.sort((a, b) {
                if (a.eventTime != null && b.eventTime != null) {
                  return a.eventTime!.compareTo(b.eventTime!);
                } else if (a.eventTime != null) {
                  return -1;
                } else if (b.eventTime != null) {
                  return 1;
                }
                return 0;
              });

              children.add(
                Container(
                  margin: const EdgeInsets.only(bottom: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date Header
                      _buildDateHeader(date, isToday),
                      const SizedBox(height: 16),
                      // Content
                      if (dayEvents.isEmpty)
                        const TimelineEmptyCard()
                      else
                        Column(
                          children: dayEvents.map((event) {
                            final alarm = _convertEventToAlarm(event);
                            return AlarmListItem(
                              alarm: alarm,
                              isHighlighted: isStartDate,
                              onToggle: (_) {},
                              onDelete: () {},
                            );
                          }).toList(),
                        )
                    ],
                  ),
                ),
              );
            }
            return children;
          }(),
        ),
      ),
    );
  }

  /// 필터 적용
  List<DailyEventModel> _applyFilter(List<DailyEventModel> events) {
    if (_selectedFilter == AlarmFilterType.all) {
      return events;
    }
    
    return events.where((event) {
      switch (_selectedFilter) {
        case AlarmFilterType.memory:
          return event.eventType.toLowerCase() == 'memory';
        case AlarmFilterType.event:
          return event.eventType.toLowerCase() == 'event';
        case AlarmFilterType.alarm:
          return event.eventType.toLowerCase() == 'alarm';
        case AlarmFilterType.all:
          return true;
      }
    }).toList();
  }

  /// 날짜별로 이벤트 그룹핑
  Map<DateTime, List<DailyEventModel>> _groupEventsByDate(List<DailyEventModel> events) {
    final Map<DateTime, List<DailyEventModel>> groups = {};
    for (var event in events) {
      final dateKey = DateTime(event.eventDate.year, event.eventDate.month, event.eventDate.day);
      if (!groups.containsKey(dateKey)) {
        groups[dateKey] = [];
      }
      groups[dateKey]!.add(event);
    }
    return groups;
  }

  /// DailyEventModel을 AlarmModel로 변환
  AlarmModel _convertEventToAlarm(DailyEventModel event) {
    final eventDate = event.eventDate;

    // eventTime이 null이면 eventDate를 DateTime으로 변환
    final DateTime eventTime = event.eventTime ??
        DateTime(
          eventDate.year,
          eventDate.month,
          eventDate.day,
          12, // 기본 시간: 12시
          0, // 기본 분: 0분
        );

    // ItemType 매핑
    ItemType itemType;
    switch (event.eventType.toLowerCase()) {
      case 'alarm':
        itemType = ItemType.alarm;
        break;
      case 'event':
        itemType = ItemType.event;
        break;
      case 'memory':
      default:
        itemType = ItemType.memory;
        break;
    }

    // 태그를 문자열로 변환 (있는 경우)
    String? contentText = event.eventSummary;
    if (event.tags != null && event.tags!.isNotEmpty) {
      final tagsString = event.tags!.join(' ');
      contentText = '$contentText\n$tagsString';
    }

    return AlarmModel(
      id: event.id,
      year: eventDate.year,
      month: eventDate.month,
      day: eventDate.day,
      week: [], // 주간 반복 없음
      time: eventTime.hour > 12 ? eventTime.hour - 12 : eventTime.hour,
      minute: eventTime.minute,
      amPm: eventTime.hour >= 12 ? 'pm' : 'am',
      isValid: true,
      isEnabled: event.isFutureEvent,
      notificationId: event.id,
      scheduledDatetime: eventTime,
      title: null, // title은 사용하지 않음
      content: contentText, // eventSummary + tags를 content로 표시
      isDeleted: false,
      createdAt: event.createdAt,
      updatedAt: event.updatedAt,
      itemType: itemType,
    );
  }
}
