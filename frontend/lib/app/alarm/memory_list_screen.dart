import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/navigation/navigation_service.dart';
import '../../data/models/memory/memory_item.dart';
import '../../providers/memory_provider.dart';
import '../../ui/app_ui.dart';
import '../../ui/components/memory_timeline_item.dart';

/// 기억서랍 화면
/// 과거 기억과 미래 일정을 타임라인 형식으로 표시
///
/// PROMPT_GUIDE.md 준수:
/// - AppFrame 기반 (Scaffold 금지)
/// - 충분한 여백과 공백
/// - 월별 그룹핑
/// - 감정적 UI (이야기 흐름)
class MemoryListScreen extends ConsumerStatefulWidget {
  const MemoryListScreen({super.key});

  @override
  ConsumerState<MemoryListScreen> createState() => _MemoryListScreenState();
}

class _MemoryListScreenState extends ConsumerState<MemoryListScreen> {
  @override
  void initState() {
    super.initState();
    // 화면 진입 시 메모리 로드
    Future.microtask(() => ref.read(memoryProvider.notifier).loadMemories());
  }

  @override
  Widget build(BuildContext context) {
    final memoryState = ref.watch(memoryProvider);
    final navigationService = NavigationService(context, ref);

    return AppFrame(
      topBar: TopBar(
        title: '기억 히스토리',
        leftIcon: Icons.arrow_back_ios,
        rightIcon: Icons.more_horiz,
        onTapLeft: () => navigationService.navigateToTab(1),
        onTapRight: () => MoreMenuSheet.show(context),
        foregroundColor: AppColors.textPrimary,
      ),
      body: memoryState.when(
        data: (memories) => _buildContent(memories),
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: AppColors.primaryColor,
          ),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: AppColors.textSecondary,
              ),
              SizedBox(height: AppSpacing.sm),
              Text(
                '오류가 발생했습니다',
                style: AppTypography.h3.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: AppSpacing.xs),
              Text(
                error.toString(),
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 메모리 목록 컨텐츠
  Widget _buildContent(List<MemoryItem> memories) {
    if (memories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              '아직 등록된 기억이 없습니다',
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    // 월별 그룹핑
    final groupedMemories = _groupByMonth(memories);

    return CustomScrollView(
      slivers: [
        // 섹션 제목: "중요 기억"
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Text(
              '중요 기억',
              style: AppTypography.h3.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),

        // 월별 그룹 + 타임라인
        ...groupedMemories.entries.map((entry) {
          final monthKey = entry.key;
          final items = entry.value;

          return SliverMainAxisGroup(
            slivers: [
              // 날짜 구분선 (예: "2025년 11월")
              SliverToBoxAdapter(
                child: _buildDateSeparator(monthKey),
              ),

              // 타임라인 아이템들
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return MemoryTimelineItem(
                        memory: items[index],
                        showTopLine: index > 0,
                        showBottomLine: index < items.length - 1,
                        onTap: () => _handleMemoryTap(items[index]),
                      );
                    },
                    childCount: items.length,
                  ),
                ),
              ),
            ],
          );
        }),

        // 하단 여백
        SliverToBoxAdapter(
          child: SizedBox(height: AppSpacing.xl),
        ),
      ],
    );
  }

  /// 날짜 구분선 위젯
  /// 예: "2025년 11월"
  Widget _buildDateSeparator(String monthKey) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              color: AppColors.borderLightGray.withOpacity(0.3),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: AppColors.basicColor,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                monthKey,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              color: AppColors.borderLightGray.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  /// 월별 그룹핑
  /// 예: {"2025년 11월": [...], "2025년 10월": [...]}
  Map<String, List<MemoryItem>> _groupByMonth(List<MemoryItem> memories) {
    final groups = <String, List<MemoryItem>>{};

    for (final memory in memories) {
      final key = '${memory.timestamp.year}년 ${memory.timestamp.month}월';
      groups.putIfAbsent(key, () => []).add(memory);
    }

    return groups;
  }

  /// 메모리 아이템 탭 핸들러
  void _handleMemoryTap(MemoryItem memory) {
    // TODO: 상세 화면으로 이동 또는 다이얼로그 표시
    // 현재는 간단히 스낵바로 표시
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(memory.content),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
