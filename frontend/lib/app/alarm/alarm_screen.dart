import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ui/app_ui.dart';
import '../../ui/components/date_range_selector.dart';
import '../../core/services/navigation/navigation_service.dart';
import '../../core/utils/emotion_classifier.dart';
import '../../core/utils/mood_color_helper.dart';
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
  // 날짜 범위 상태
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    
    // 오늘부터 오늘+7일까지
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day);
    _endDate = _startDate.add(const Duration(days: 7));
    
    // 이벤트 로드
    Future.microtask(() {
      ref.read(targetEventsProvider.notifier).loadDailyEvents(
            startDate: _startDate,
            endDate: _endDate,
          );
    });
  }

  @override
  void dispose() {
    // 화면 종료 시 알림도 함께 제거
    TopNotificationManager.remove();
    super.dispose();
  }

  /// 날짜 범위 선택 다이얼로그
  Future<void> _showDateRangePicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('ko', 'KR'),
      helpText: '시작 날짜 선택',
    );

    if (picked != null && mounted) {
      setState(() {
        _startDate = picked;
        _endDate = picked.add(const Duration(days: 7));
      });

      // 새로운 날짜 범위로 이벤트 다시 로드
      ref.read(targetEventsProvider.notifier).loadDailyEvents(
            startDate: _startDate,
            endDate: _endDate,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final navigationService = NavigationService(context, ref);
    final eventsState = ref.watch(targetEventsProvider);
    final dailyState = ref.watch(dailyMoodProvider);

    // 현재 감정 가져오기 (기본값: 기쁨)
    final currentEmotion = dailyState.selectedEmotion ?? EmotionId.joy;

    // 배경색을 위한 기분 카테고리 가져오기
    final moodCategory = EmotionClassifier.classify(currentEmotion);

    // MoodColorHelper를 사용하여 일관된 색상 적용
    final backgroundColor = MoodColorHelper.getBackgroundColor(moodCategory);

    return AppFrame(
      statusBarStyle: SystemUiOverlayStyle(
        statusBarColor: backgroundColor,
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
                  height: 90,
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
                                '봄이가 기억해줄게.\n나랑 대화하러 와줘!',
                                style: AppTypography.body.copyWith(
                                  color: AppColors.basicColor,
                                  height: 1.2,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.arrow_forward,
                                  color: AppColors.basicColor,
                                  size: 18,
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

              // C. 날짜 범위 선택기
              DateRangeSelector(
                startDate: _startDate,
                endDate: _endDate,
                onTap: _showDateRangePicker,
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
          '봄이가 체크해줄게.',
          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md + MediaQuery.of(context).padding.bottom,
      ),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        
        // DailyEventModel을 AlarmModel 형식으로 변환하여 표시
        // (기존 AlarmListItem 재사용)
        final alarm = _convertEventToAlarm(event);
        
        return AlarmListItem(
          alarm: alarm,
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
    final DateTime eventTime = event.eventTime ?? DateTime(
      eventDate.year,
      eventDate.month,
      eventDate.day,
      12, // 기본 시간: 12시
      0,  // 기본 분: 0분
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
      title: event.eventSummary,
      content: null, // 태그 대신 summary를 title에 표시
      isDeleted: false,
      createdAt: event.createdAt,
      updatedAt: event.updatedAt,
      itemType: itemType,
    );
  }
}
