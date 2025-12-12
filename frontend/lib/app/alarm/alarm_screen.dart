import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ui/app_ui.dart';
import '../../core/services/navigation/navigation_service.dart';
import '../../core/utils/emotion_classifier.dart';
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

    // 배경색 결정
    final backgroundColor = _getMoodColor(moodCategory);

    // 상태바 스타일 설정 (밝은 배경에는 어두운 아이콘)
    final statusBarStyle = SystemUiOverlayStyle.dark;

    return AppFrame(
      statusBarStyle: SystemUiOverlayStyle.light,
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
                title: '똑똑 알람',
                leftIcon: Icons.arrow_back_ios,
                rightIcon: Icons.more_horiz,
                onTapLeft: () => navigationService.navigateToTab(0),
                onTapRight: () => MoreMenuSheet.show(context),
                backgroundColor: Colors.transparent,
                foregroundColor: AppColors.basicColor,
              ),

              // B. 상단 영역 (텍스트 + 캐릭터)
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 0,
                ),
                child: Row(
                  children: [
                    // 왼쪽: 텍스트 영역
                    Expanded(
                      child: GestureDetector(
                        onTap: () => navigationService.navigateToTab(1),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '제가 알람을\n등록해드릴까요?',
                              style: AppTypography.h3.copyWith(
                                color: AppColors.basicColor,
                                height: 1.4,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_forward,
                                color: AppColors.basicColor,
                                size: 28,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    // 오른쪽: 캐릭터
                    EmotionCharacter(
                      id: currentEmotion,
                      size: 160,
                    ),
                  ],
                ),
              ),
            ),

            // C. 알람 리스트 영역
            Expanded(
              flex: 6,
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

  /// 기분 카테고리에 따른 배경색 반환
  Color _getMoodColor(MoodCategory category) {
    switch (category) {
      case MoodCategory.good:
        return AppColors.homeGoodYellow;
      case MoodCategory.neutral:
        return AppColors.homeNormalGreen;
      case MoodCategory.bad:
        return AppColors.homeBadBlue;
    }
  }

  /// 알람 리스트 빌드
  Widget _buildAlarmList(List<AlarmModel> alarms) {
    if (alarms.isEmpty) {
      return Center(
        child: Text(
          '등록된 알람이 없습니다.\n마이크 버튼을 눌러 알람을 등록해보세요!',
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
      itemCount: alarms.length,
      itemBuilder: (context, index) {
        final alarm = alarms[index];
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
