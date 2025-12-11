import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../ui/tokens/app_tokens.dart';
import '../../../providers/alarm_provider.dart';
import 'alarm_list_item.dart';

/// 알람 리스트 패널
///
/// 화면 하단에 배치되는 확장 가능한 알람 리스트 패널입니다.
/// - 접힌 상태: 알람 개수만 표시
/// - 펼쳐진 상태: 최근 3개 알람 리스트 표시
class AlarmListPanel extends ConsumerStatefulWidget {
  const AlarmListPanel({
    super.key,
    required this.onTapMore,
    this.showOnlyWhenCollapsed = false,
    this.onExpansionChanged,
  });

  /// 더보기 버튼 탭 콜백
  final VoidCallback onTapMore;

  /// 접힌 상태만 표시 (알람 화면에서 사용)
  final bool showOnlyWhenCollapsed;

  /// 확장 상태 변경 콜백
  final ValueChanged<bool>? onExpansionChanged;

  @override
  ConsumerState<AlarmListPanel> createState() => _AlarmListPanelState();
}

class _AlarmListPanelState extends ConsumerState<AlarmListPanel>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    if (widget.showOnlyWhenCollapsed) {
      // 알람 화면에서는 더보기 버튼처럼 동작
      widget.onTapMore();
      return;
    }

    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _rotationController.forward();
      } else {
        _rotationController.reverse();
      }
      // 확장 상태 변경 콜백 호출
      widget.onExpansionChanged?.call(_isExpanded);
    });
  }

  @override
  Widget build(BuildContext context) {
    final alarmState = ref.watch(alarmProvider);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    // 알람 등록 후 자동 확장
    ref.listen(alarmProvider, (previous, next) {
      if (!widget.showOnlyWhenCollapsed) {
        // 이전 상태가 데이터가 있는 상태였을 때만 비교 (초기 로딩 시 자동 확장 방지)
        if (previous?.hasValue == true && next.hasValue) {
          final prevCount = previous!.value!.length;
          final nextCount = next.value!.length;
          
          if (nextCount > prevCount) {
             // 알람이 추가되면 자동으로 확장
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted && !_isExpanded) {
                setState(() {
                  _isExpanded = true;
                  _rotationController.forward();
                  // 확장 상태 변경 콜백 호출
                  widget.onExpansionChanged?.call(true);
                });
              }
            });
          }
        }
      }
    });

    return alarmState.when(
      data: (alarms) {
        if (alarms.isEmpty) {
          // 알람이 없으면 패널 숨김
          // 🆕 확장 상태를 리셋하여 bottomBar가 다시 표시되도록 함
          if (_isExpanded) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _isExpanded = false;
                  _rotationController.reverse();
                });
                widget.onExpansionChanged?.call(false);
              }
            });
          }
          return const SizedBox.shrink();
        }

        final alarmCount = alarms.length;
        final recentAlarms = alarms.take(3).toList();
        final minHeight = 80.0;
        final maxHeight =
            MediaQuery.of(context).size.height * 0.5; // 화면 높이의 50%
        
        final isCollapsed = widget.showOnlyWhenCollapsed || !_isExpanded;
        final targetHeight = isCollapsed
            ? minHeight + bottomPadding
            : maxHeight + bottomPadding;

        return GestureDetector(
          onTap: _toggleExpanded,
          onVerticalDragUpdate: (details) {
            if (widget.showOnlyWhenCollapsed) return;

            if (details.delta.dy > 5 && _isExpanded) {
              // 아래로 드래그 - 축소
              _toggleExpanded();
            } else if (details.delta.dy < -5 && !_isExpanded) {
              // 위로 드래그 - 확장
              _toggleExpanded();
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            constraints: BoxConstraints(
              minHeight: minHeight + bottomPadding,
              maxHeight: targetHeight,
            ),
            decoration: const BoxDecoration(
              color: AppColors.pureWhite,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppRadius.xxl),
                topRight: Radius.circular(AppRadius.xxl),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 20,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppRadius.md),
                topRight: Radius.circular(AppRadius.md),
              ),
              child: OverflowBox(
                minHeight: targetHeight,
                maxHeight: targetHeight,
                alignment: Alignment.topCenter,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 헤더
                    _buildHeader(alarmCount),

                    // 리스트 (펼쳐진 상태에서만 표시)
                    if (!widget.showOnlyWhenCollapsed && _isExpanded) ...[
                      Expanded(
                        child: _buildAlarmList(recentAlarms),
                      ),
                      // 더보기 버튼
                      _buildMoreButton(),
                    ],

                    // 하단 패딩
                    SizedBox(height: bottomPadding),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  /// 헤더 위젯
  Widget _buildHeader(int alarmCount) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          // 알람 아이콘
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.accentRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(
              Icons.alarm,
              color: AppColors.accentRed,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // 알람 개수
          Expanded(
            child: Text(
              '알람 $alarmCount개',
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          // 화살표 아이콘
          RotationTransition(
            turns: Tween<double>(begin: 0.0, end: 0.5)
                .animate(_rotationController),
            child: Icon(
              Icons.keyboard_arrow_up_rounded,
              color: AppColors.textPrimary,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  /// 알람 리스트 위젯
  Widget _buildAlarmList(List alarms) {
    return Column(
      children: [
        // 구분선
        const Divider(
          height: 1,
          thickness: 1,
          color: AppColors.borderLight,
        ),
        const SizedBox(height: AppSpacing.sm),

        // 리스트
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
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

                  // TopNotification은 화면에서 처리하므로 여기서는 생략
                },
              );
            },
          ),
        ),
      ],
    );
  }

  /// 더보기 버튼 위젯
  Widget _buildMoreButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        0,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTapMore,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.accentRed,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Center(
              child: Text(
                '전체 알람 보기',
                style: AppTypography.body.copyWith(
                  color: AppColors.accentRed,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
