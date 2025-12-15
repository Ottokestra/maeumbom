import 'dart:async';
import 'package:flutter/material.dart';
import '../../../ui/app_ui.dart';

/// 홈 화면 알림 미리보기 컴포넌트 (위에서 아래로 슬라이드)
class HomeAlarmPreview extends StatefulWidget {
  const HomeAlarmPreview({super.key});

  @override
  State<HomeAlarmPreview> createState() => _HomeAlarmPreviewState();
}

class _HomeAlarmPreviewState extends State<HomeAlarmPreview> {
  int _currentIndex = 0;
  Timer? _timer;

  // TODO: 실제 데이터는 provider에서 가져와야 함
  final List<AlarmPreviewItem> _alarms = const [
    AlarmPreviewItem(
      title: '중요한 회의 준비하기',
      timeRemaining: '오전 11:00',
    ),
    AlarmPreviewItem(
      title: '오후 약속 시간 확인',
      timeRemaining: '오후 12:00',
    ),
    AlarmPreviewItem(
      title: '알림: 저녁 이벤트 행사',
      timeRemaining: '오후 7시',
    ),
  ];

  @override
  void initState() {
    super.initState();

    // 3초마다 자동 슬라이드
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % _alarms.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRect(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (Widget child, Animation<double> animation) {
            // 위에서 아래로 슬라이드 + 페이드 애니메이션
            final slideAnimation = Tween<Offset>(
              begin: const Offset(0.0, -0.3), // 살짝만 위에서 시작
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
                Icons.refresh,
                color: AppColors.basicColor,
                size: 16,
              ),
              const SizedBox(width: AppSpacing.xs),
              Center(
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
