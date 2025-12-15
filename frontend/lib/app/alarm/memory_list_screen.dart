import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/navigation/navigation_service.dart';
import '../../data/models/alarm/alarm_model.dart';
import '../../data/models/target_events/daily_event_model.dart';
import '../../providers/target_events_provider.dart';
import '../../ui/app_ui.dart';
import '../../ui/components/date_range_selector.dart';
import 'components/alarm_list_item.dart';
import 'components/timeline_empty_card.dart';

/// 기억서랍 화면
/// 과거 기억과 미래 일정을 타임라인 형식으로 표시
class MemoryListScreen extends ConsumerStatefulWidget {
  const MemoryListScreen({super.key});

  @override
  ConsumerState<MemoryListScreen> createState() => _MemoryListScreenState();
}

class _MemoryListScreenState extends ConsumerState<MemoryListScreen> {
  // 조회 기준 날짜 (기본값: 오늘)
  late DateTime _startDate;
  late DateTime _endDate;
  
  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // 초기 범위: 오늘을 포함한 과거 7일 ~ 미래 7일
    _startDate = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 7));
    _endDate = DateTime(now.year, now.month, now.day).add(const Duration(days: 7));

    // 화면 진입 시 이벤트 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEvents();
    });
  }

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
              primary: AppColors.primaryColor, // 선택된 날짜 원형 배경 (시작/종료일)
              onPrimary: AppColors.pureWhite, // 선택된 날짜 텍스트
              onSurface: AppColors.textPrimary, // 달력 기본 텍스트
              surface: AppColors.pureWhite, // 달력 배경
            ),
            datePickerTheme: DatePickerThemeData(
              rangeSelectionBackgroundColor: AppColors.accentCoral.withOpacity(0.3), // 날짜 사이 연결 막대 색상 (연하게)
              // 만약 진한 코랄색을 원하면 opacity 제거: AppColors.accentCoral
              // 보통 연결 막대는 텍스트 가독성을 위해 연하게 처리함. 사용자 요청이 "코랄색"이므로 일단 opacity 없이 하거나,
              // Material3 가이드라인상 연한색이 맞음. 
              // 사용자 요청: "연결막대는 코랄색상으로" -> opacity 없이 시도하거나 0.5 정도?
              // 일단 가독성 고려해 0.4 정도 적용
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textPrimary, // 상단 취소/저장 버튼
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

  @override
  Widget build(BuildContext context) {
    final navigationService = NavigationService(context, ref);
    final eventsState = ref.watch(targetEventsProvider);

    // 표시할 날짜 리스트 생성
    final dayCount = _endDate.difference(_startDate).inDays + 1;
    final datesToShow = List.generate(
      dayCount,
      (index) => _startDate.add(Duration(days: index)),
    );
    final now = DateTime.now();

    return AppFrame(
      topBar: TopBar(
        title: '',
        leftIcon: null,
        rightIcon: Icons.close,
        onTapLeft: null,
        onTapRight: () => navigationService.navigateToTab(1),
        foregroundColor: AppColors.textPrimary,
      ),
      body: Column(
        children: [
          // 날짜 선택기 (기간 표시 및 선택)
          DateRangeSelector(
            selectedDate: _startDate,
            endDate: _endDate,
            onPreviousDay: _goToPreviousRange, // 화살표는 기간 단위 이동
            onNextDay: _goToNextRange,
            onDateTap: _showDateRangePicker, // 텍스트 탭 시 달력 표시
          ),
          
          Expanded(
            child: eventsState.when(
              data: (events) {
                // 날짜별로 이벤트 그룹핑
                final eventsByDate = _groupEventsByDate(events);

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

                          final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
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
                                          isHighlighted: false,
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
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primaryColor),
              ),
              error: (error, stack) => Center(
                child: Text('오류가 발생했습니다: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }

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
          padding: const EdgeInsets.only(top: 8.0),
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

  AlarmModel _convertEventToAlarm(DailyEventModel event) {
    final eventDate = event.eventDate;
    final DateTime eventTime = event.eventTime ??
        DateTime(eventDate.year, eventDate.month, eventDate.day, 12, 0);

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
      week: [],
      time: eventTime.hour > 12 ? eventTime.hour - 12 : eventTime.hour,
      minute: eventTime.minute,
      amPm: eventTime.hour >= 12 ? 'pm' : 'am',
      isValid: true,
      isEnabled: event.isFutureEvent,
      notificationId: event.id,
      scheduledDatetime: eventTime,
      title: null,
      content: contentText,
      isDeleted: false,
      createdAt: event.createdAt,
      updatedAt: event.updatedAt,
      itemType: itemType,
    );
  }
}
