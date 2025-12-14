import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ui/app_ui.dart';
import '../../core/services/navigation/navigation_service.dart';
import '../../core/utils/emotion_classifier.dart';
import '../../core/utils/mood_color_helper.dart';
import '../../providers/alarm_provider.dart';
import '../../providers/daily_mood_provider.dart';
import '../../data/models/alarm/alarm_model.dart';
import 'components/alarm_list_item.dart';

class AlarmScreen extends ConsumerStatefulWidget {
  const AlarmScreen({super.key});

  @override
  ConsumerState<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends ConsumerState<AlarmScreen> {
  @override
  void initState() {
    super.initState();
    // 알람 목록 로드
    Future.microtask(() => ref.read(alarmProvider.notifier).loadAlarms());
  }

  @override
  void dispose() {
    // 화면 종료 시 알림도 함께 제거
    TopNotificationManager.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final navigationService = NavigationService(context, ref);
    final alarmState = ref.watch(alarmProvider);
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

              // C. 알람 리스트 영역
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppRadius.xxl),
                    topRight: Radius.circular(AppRadius.xxl),
                  ),
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
                    child: alarmState.when(
                      data: (alarms) => _buildAlarmList(alarms),
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

  /// 알람 리스트 빌드
  Widget _buildAlarmList(List<AlarmModel> alarms) {
    // 미래 일정만 필터링 (오늘 이후)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final futureAlarms = alarms.where((alarm) {
      final alarmDate = DateTime(alarm.year, alarm.month, alarm.day);
      return alarmDate.isAfter(today) || alarmDate.isAtSameMomentAs(today);
    }).toList();

    if (futureAlarms.isEmpty) {
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
      itemCount: futureAlarms.length,
      itemBuilder: (context, index) {
        final alarm = futureAlarms[index];
        return AlarmListItem(
          alarm: alarm,
          onToggle: (value) {
            ref.read(alarmProvider.notifier).toggleAlarm(alarm.id, value);
          },
          onDelete: () {
            ref.read(alarmProvider.notifier).deleteAlarm(alarm.id);
            TopNotificationManager.show(
              context,
              message: '알람이 삭제되었습니다.',
              actionLabel: '실행취소',
              type: TopNotificationType.red,
              onActionTap: () {
                // TODO: 실행취소 구현 (삭제된 알람 복구)
              },
            );
          },
        );
      },
    );
  }
}
