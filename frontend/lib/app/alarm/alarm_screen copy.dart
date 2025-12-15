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

class AlarmScreen extends ConsumerStatefulWidget {
  const AlarmScreen({super.key});

  @override
  ConsumerState<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends ConsumerState<AlarmScreen> {
  // 기준 날짜 (이 날짜부터 +7일 조회)
  late DateTime _baseDate;

  @override
  void initState() {
    super.initState();

    // 오늘을 기준 날짜로 설정
    final now = DateTime.now();
    _baseDate = DateTime(now.year, now.month, now.day);

    appLogger.d('🟡 AlarmScreen initState - Base Date: $_baseDate');

    // 화면 진입 시 항상 이벤트 로드
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
    final endDate = _baseDate.add(const Duration(days: 7));
    appLogger.d('🟡 AlarmScreen - Loading events from $_baseDate to $endDate');

    ref.read(targetEventsProvider.notifier).loadDailyEvents(
          startDate: _baseDate,
          endDate: endDate,
        );
  }

  /// 이전 날짜로 이동
  void _goToPreviousDay() {
    setState(() {
      _baseDate = _baseDate.subtract(const Duration(days: 1));
    });
    _loadEvents();
  }

  /// 다음 날짜로 이동
  void _goToNextDay() {
    setState(() {
      _baseDate = _baseDate.add(const Duration(days: 1));
    });
    _loadEvents();
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
                title: '',
                leftIcon: Icons.arrow_back_ios,
                rightIcon: Icons.history,
                onTapLeft: () => navigationService.navigateToTab(0),
                onTapRight: () =>
                    navigationService.navigateToRoute('/alarm/memory'),
                backgroundColor: Colors.transparent,
                foregroundColor: AppColors.basicColor,
              ),

              // B. 상단 영역 (텍스트 + 캐릭터)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xxl,
                  0,
                  AppSpacing.xxxl,
                  AppSpacing.sm,
                ),
                child: SizedBox(
                  height: 70,
                  child: Row(
                    children: [
                      // 왼쪽: 텍스트 영역
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              navigationService.navigateToRoute('/bomi'),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '봄이가 중요한 기억을 알려줄게',
                                style: AppTypography.body.copyWith(
                                  color: AppColors.basicColor,
                                  height: 1.2,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // 오른쪽: 캐릭터
                      EmotionCharacter(
                        id: currentEmotion,
                        size: 90,
                      ),
                    ],
                  ),
                ),
              ),

              // C. 날짜 선택기 (화살표 네비게이션)
              DateRangeSelector(
                selectedDate: _baseDate,
                onPreviousDay: _goToPreviousDay,
                onNextDay: _goToNextDay,
              ),

              // D. 이벤트 리스트 영역
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
                      data: (events) => _buildEventsList(events),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
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

  /// 이벤트 리스트 빌드
  Widget _buildEventsList(List<DailyEventModel> events) {
    if (events.isEmpty) {
      return Center(
        child: Text(
          '등록된 정보가 없습니다.',
          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      );
    }

    // 날짜/시간 기준 오름차순 정렬
    final sortedEvents = List<DailyEventModel>.from(events)
      ..sort((a, b) {
        // 1. 날짜 비교
        final dateComparison = a.eventDate.compareTo(b.eventDate);
        if (dateComparison != 0) return dateComparison;

        // 2. 시간 비교 (eventTime이 있는 경우)
        if (a.eventTime != null && b.eventTime != null) {
          return a.eventTime!.compareTo(b.eventTime!);
        } else if (a.eventTime != null) {
          return -1; // a가 시간이 있으면 먼저
        } else if (b.eventTime != null) {
          return 1; // b가 시간이 있으면 먼저
        }

        return 0; // 둘 다 시간이 없으면 동일
      });

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md + MediaQuery.of(context).padding.bottom,
      ),
      itemCount: sortedEvents.length,
      itemBuilder: (context, index) {
        final event = sortedEvents[index];

        // 기준 날짜와 이벤트 날짜가 같으면 강조 표시
        final isHighlighted = event.eventDate.year == _baseDate.year &&
            event.eventDate.month == _baseDate.month &&
            event.eventDate.day == _baseDate.day;

        // DailyEventModel을 AlarmModel 형식으로 변환하여 표시
        // (기존 AlarmListItem 재사용)
        final alarm = _convertEventToAlarm(event);

        return AlarmListItem(
          alarm: alarm,
          isHighlighted: isHighlighted,
          onToggle: (value) {
            // 이벤트는 토글 기능 없음 (알람 타입만 토글 가능)
          },
          onDelete: () {
            // TODO: 이벤트 삭제 API 연동
            TopNotificationManager.show(
              context,
              message: '이벤트가 삭제되었습니다.',
              actionLabel: '실행취소',
              type: TopNotificationType.red,
              onActionTap: () {
                // TODO: 실행취소 구현
              },
            );
          },
        );
      },
    );
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
