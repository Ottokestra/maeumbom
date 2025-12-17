import 'dart:async';
import 'package:flutter/material.dart';
import '../../../ui/app_ui.dart';

/// 홈 화면 공지사항 배너 컴포넌트
class HomeNoticeBanner extends StatefulWidget {
  const HomeNoticeBanner({super.key});

  @override
  State<HomeNoticeBanner> createState() => _HomeNoticeBannerState();
}

class _HomeNoticeBannerState extends State<HomeNoticeBanner> {
  int _currentIndex = 0;
  Timer? _timer;

  // 공지사항 목록
  final List<String> _notices = const [
    '📢 마음봄과 함께 건강한 하루를 시작하세요!',
    '📢 [마음연습실] 새로운 시나리오가 등록됐습니다.',
    '📢 봄이와 대화하며 마음을 나눠보세요',
  ];

  @override
  void initState() {
    super.initState();

    // 4초마다 자동 슬라이드
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % _notices.length;
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
      height: 36,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.borderLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRect(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (Widget child, Animation<double> animation) {
            // 위에서 아래로 슬라이드 + 페이드 애니메이션
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
          child: _buildNoticeContent(
            _notices[_currentIndex],
            key: ValueKey<int>(_currentIndex),
          ),
        ),
      ),
    );
  }

  Widget _buildNoticeContent(String notice, {Key? key}) {
    return Row(
      key: key,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            notice,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
