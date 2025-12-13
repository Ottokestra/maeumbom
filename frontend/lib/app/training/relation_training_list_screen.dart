import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ui/app_ui.dart';
import '../../ui/characters/app_characters.dart';
import '../../data/models/training/relation_training.dart';
import 'viewmodel/relation_training_list_viewmodel.dart';
import 'relation_training_screen.dart';
import 'scenario_generation_screen.dart';
import 'components/training_info_widget.dart';

class RelationTrainingListScreen extends ConsumerWidget {
  const RelationTrainingListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listState = ref.watch(relationTrainingListViewModelProvider);
    final viewMode = listState.viewMode;
    final categoryFilter = listState.categoryFilter;

    return AppFrame(
      topBar: TopBar(
        title: '',
        leftIcon: Icons.arrow_back,
        onTapLeft: () => Navigator.pop(context),
        rightIcon: Icons.add,
        onTapRight: () => _navigateToGenerationScreen(context, ref),
      ),
      body: listState.scenarios.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('오류가 발생했습니다: $error')),
        data: (scenarios) {
          if (scenarios.isEmpty) {
            return const Center(child: Text('사용 가능한 시나리오가 없습니다.'));
          }
          return _buildScenarioContent(
              context, ref, scenarios, viewMode, categoryFilter);
        },
      ),
    );
  }

  // 시나리오 생성 화면으로 이동
  Future<void> _navigateToGenerationScreen(
      BuildContext context, WidgetRef ref) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const ScenarioGenerationScreen(),
      ),
    );

    // 시나리오 생성이 완료되면 목록 새로고침
    if (result == true && context.mounted) {
      ref.read(relationTrainingListViewModelProvider.notifier).getScenarios();
    }
  }

  // 컨텐츠 영역: 상단 정보 + 카테고리 필터 + 토글 버튼 + 그리드/리스트
  Widget _buildScenarioContent(
      BuildContext context,
      WidgetRef ref,
      List<TrainingScenario> scenarios,
      ViewMode viewMode,
      CategoryFilter categoryFilter) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 12, left: 24, right: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Practice Records Card
          TrainingInfoWidget(
            completedCount: 2, // TODO: 실제 완료 개수로 교체
            totalCount: scenarios.length,
          ),
          const SizedBox(height: AppSpacing.md),

          // 카테고리 필터 탭 + 뷰 모드 토글
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 카테고리 필터 탭
              Expanded(
                child: _buildCategoryFilterTabs(ref, categoryFilter),
              ),
              const SizedBox(height: AppSpacing.sm),
              // 뷰 모드 토글 버튼
              _buildViewModeToggle(ref, viewMode),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // 그리드 또는 리스트 뷰
          Expanded(
            child: viewMode == ViewMode.grid
                ? _buildGridView(context, ref, scenarios, categoryFilter)
                : _buildListView(context, ref, scenarios, categoryFilter),
          ),
        ],
      ),
    );
  }

  // 카테고리 필터 탭
  Widget _buildCategoryFilterTabs(WidgetRef ref, CategoryFilter currentFilter) {
    return Row(
      children: CategoryFilter.values.map((filter) {
        final isSelected = filter == currentFilter;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () {
              ref
                  .read(relationTrainingListViewModelProvider.notifier)
                  .setCategoryFilter(filter);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color:
                    isSelected ? AppColors.primaryColor : AppColors.basicGray,
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
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // 뷰 모드 토글 버튼
  Widget _buildViewModeToggle(WidgetRef ref, ViewMode viewMode) {
    return Row(
      children: [
        // 그리드 버튼
        IconButton(
          icon: Icon(
            Icons.grid_view,
            color: viewMode == ViewMode.grid
                ? AppColors.primaryColor
                : AppColors.textSecondary,
          ),
          onPressed: () {
            if (viewMode != ViewMode.grid) {
              ref
                  .read(relationTrainingListViewModelProvider.notifier)
                  .toggleViewMode();
            }
          },
        ),
        // 리스트 버튼
        IconButton(
          icon: Icon(
            Icons.view_list,
            color: viewMode == ViewMode.list
                ? AppColors.primaryColor
                : AppColors.textSecondary,
          ),
          onPressed: () {
            if (viewMode != ViewMode.list) {
              ref
                  .read(relationTrainingListViewModelProvider.notifier)
                  .toggleViewMode();
            }
          },
        ),
      ],
    );
  }

  // 그리드 뷰 (기존)
  Widget _buildGridView(BuildContext context, WidgetRef ref,
      List<TrainingScenario> scenarios, CategoryFilter categoryFilter) {
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.65, // 0.75에서 0.65로 감소 (카드가 더 길어짐)
      ),
      itemCount: scenarios.length,
      itemBuilder: (context, index) {
        return _buildScenarioCard(
            context, ref, scenarios[index], categoryFilter);
      },
    );
  }

  // 리스트 뷰 (신규)
  Widget _buildListView(BuildContext context, WidgetRef ref,
      List<TrainingScenario> scenarios, CategoryFilter categoryFilter) {
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemCount: scenarios.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return _buildScenarioListItem(
            context, ref, scenarios[index], categoryFilter);
      },
    );
  }

  // 리스트 아이템 (가로형)
  Widget _buildScenarioListItem(BuildContext context, WidgetRef ref,
      TrainingScenario scenario, CategoryFilter categoryFilter) {
    final isUserScenario = scenario.userId != null;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                RelationTrainingScreen(scenarioId: scenario.id),
          ),
        );
      },
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // 왼쪽: 이미지
            SizedBox(
              width: 120,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(16)),
                    child: (isUserScenario ||
                            scenario.imageUrl == null ||
                            scenario.imageUrl!.isEmpty)
                        ? Image.asset(
                            'assets/training_images/randomQ.png',
                            fit: BoxFit.cover,
                            width: 120,
                            height: 120,
                          )
                        : (scenario.imageUrl != null &&
                                scenario.imageUrl!.isNotEmpty)
                            ? Image.network(
                                scenario.imageUrl!,
                                fit: BoxFit.cover,
                                width: 120,
                                height: 120,
                                errorBuilder: (ctx, err, stack) => Image.asset(
                                  'assets/training_images/randomQ.png',
                                  fit: BoxFit.cover,
                                  width: 120,
                                  height: 120,
                                ),
                              )
                            : Container(
                                width: 120,
                                height: 120,
                                color:
                                    AppColors.moodGoodYellow.withOpacity(0.5),
                                child: const Icon(Icons.people,
                                    size: 40, color: AppColors.secondaryColor),
                              ),
                  ),
                ],
              ),
            ),

            // 오른쪽: 정보
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      scenario.title,
                      style: AppTypography.bodyBold,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // 태그 배지: 카테고리 + 타겟 타입 (필터링 적용)
                    TagBadgeRow(
                      tags: _getVisibleTags(scenario, categoryFilter),
                      backgroundColorMap:
                          _getBackgroundColorMapForScenario(scenario),
                      textColorMap: _getTextColorMapForScenario(scenario),
                      colorMap: _getColorMapForScenario(scenario),
                      emotionMap: _getEmotionMapForScenario(scenario),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 카드형 아이템
  Widget _buildScenarioCard(BuildContext context, WidgetRef ref,
      TrainingScenario scenario, CategoryFilter categoryFilter) {
    final isUserScenario = scenario.userId != null;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                RelationTrainingScreen(scenarioId: scenario.id),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: AppColors.textSecondary.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 이미지 영역 (60%)
                Expanded(
                  flex: 6,
                  child: ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    child: (isUserScenario ||
                            scenario.imageUrl == null ||
                            scenario.imageUrl!.isEmpty)
                        ? Image.asset(
                            'assets/training_images/randomQ.png',
                            fit: BoxFit.cover,
                          )
                        : (scenario.imageUrl != null &&
                                scenario.imageUrl!.isNotEmpty)
                            ? Image.network(
                                scenario.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) => Image.asset(
                                  'assets/training_images/randomQ.png',
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Container(
                                color:
                                    AppColors.moodGoodYellow.withOpacity(0.5),
                                child: const Icon(Icons.people,
                                    size: 40, color: AppColors.secondaryColor),
                              ),
                  ),
                ),
                // 텍스트 영역 (40%)
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 제목
                        Flexible(
                          child: Text(
                            scenario.title,
                            style: AppTypography.bodyBold,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 6),
                        // 태그 배지: 카테고리 + 타겟 타입 (필터링 적용)
                        TagBadgeRow(
                          tags: _getVisibleTags(scenario, categoryFilter),
                          backgroundColorMap:
                              _getBackgroundColorMapForScenario(scenario),
                          textColorMap: _getTextColorMapForScenario(scenario),
                          colorMap: _getColorMapForScenario(scenario),
                          emotionMap: _getEmotionMapForScenario(scenario),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 카테고리 코드를 라벨로 변환
  String _getCategoryLabel(String category) {
    switch (category.toUpperCase()) {
      case 'TRAINING':
        return '훈련';
      case 'DRAMA':
        return '드라마';
      default:
        return category;
    }
  }

  // 필터에 따라 표시할 태그 목록 반환
  List<String> _getVisibleTags(
      TrainingScenario scenario, CategoryFilter filter) {
    final tags = <String>[];

    // 전체 필터일 때만 카테고리 태그 표시
    if (filter == CategoryFilter.all) {
      tags.add(_getCategoryLabel(scenario.category));
    }

    // 관계 타입은 항상 표시
    if (scenario.targetType != null) {
      tags.add(_getTargetTypeLabel(scenario.targetType!));
    }

    return tags;
  }

  // 시나리오에 따른 커스텀 색상 매핑 생성 (사용 안 함 - 배경/텍스트 분리 사용)
  Map<String, Color> _getColorMapForScenario(TrainingScenario scenario) {
    return {};
  }

  // 시나리오에 따른 배경/텍스트 색상 매핑 생성 (카테고리용 특별 스타일)
  Map<String, Color> _getBackgroundColorMapForScenario(
      TrainingScenario scenario) {
    final categoryLabel = _getCategoryLabel(scenario.category);
    final backgroundColorMap = <String, Color>{};

    // 훈련: 연한 핑크 배경
    if (categoryLabel == '훈련') {
      backgroundColorMap['훈련'] = const Color(0xFFF4E6E4);
    }
    // 드라마: 연한 민트 배경
    else if (categoryLabel == '드라마') {
      backgroundColorMap['드라마'] = const Color(0xFFCDE7DE);
    }

    return backgroundColorMap;
  }

  Map<String, Color> _getTextColorMapForScenario(TrainingScenario scenario) {
    final categoryLabel = _getCategoryLabel(scenario.category);
    final textColorMap = <String, Color>{};

    // 훈련: 빨간색 텍스트
    if (categoryLabel == '훈련') {
      textColorMap['훈련'] = const Color(0xFFD7454D);
    }
    // 드라마: 짙은 초록색 텍스트
    else if (categoryLabel == '드라마') {
      textColorMap['드라마'] = const Color(0xFF2F6A53);
    }

    return textColorMap;
  }

  // 시나리오에 따른 감정 매핑 생성 (관계 타입용)
  Map<String, EmotionId> _getEmotionMapForScenario(TrainingScenario scenario) {
    final targetLabel = scenario.targetType != null
        ? _getTargetTypeLabel(scenario.targetType!)
        : null;

    final emotionMap = <String, EmotionId>{};

    // 타겟 타입별 고정 색상 (감정 기반)
    if (targetLabel != null) {
      switch (targetLabel) {
        case '배우자':
          emotionMap['배우자'] = EmotionId.love; // 사랑 - 핑크 계열
          break;
        case '자식':
          emotionMap['자식'] = EmotionId.joy; // 기쁨 - 노랑 계열
          break;
        case '부모':
          emotionMap['부모'] = EmotionId.anger; // 화 - 불/빨강 계열
          break;
        case '친구':
          emotionMap['친구'] = EmotionId.interest; // 흥미 - 부엉이/파랑 계열
          break;
        case '직장':
          emotionMap['직장'] = EmotionId.enlightenment; // 깨달음 - 전구/밝은 계열
          break;
        case '시댁/처가':
          emotionMap['시댁/처가'] = EmotionId.confusion; // 혼란 - 로봇/회색 계열
          break;
      }
    }

    return emotionMap;
  }

  // 타겟 타입 코드를 라벨로 변환
  String _getTargetTypeLabel(String targetType) {
    switch (targetType.toUpperCase()) {
      // 가족 관계
      case 'HUSBAND':
      case 'WIFE':
      case 'SPOUSE':
      case 'CEO': // CEO도 배우자 역할로 사용됨 (드라마)
        return '배우자';

      case 'CHILD':
      case 'SON':
      case 'DAUGHTER':
        return '자식';

      case 'PARENT':
      case 'MOTHER':
      case 'FATHER':
        return '부모';

      case 'MOTHER_IN_LAW':
      case 'FATHER_IN_LAW':
        return '시댁/처가';

      // 사회 관계
      case 'FRIEND':
        return '친구';

      case 'COLLEAGUE':
      case 'COWORKER':
      case 'BOSS':
      case 'EMPLOYEE':
        return '직장';

      // 기타
      case 'ETC':
      case 'OTHER':
        return '기타';

      default:
        return targetType;
    }
  }
}
