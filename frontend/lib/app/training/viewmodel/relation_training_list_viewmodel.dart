import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/training/relation_training.dart';
import '../../../core/services/training/relation_training_service.dart';
import 'relation_training_viewmodel.dart'; // To access service provider

// 뷰 모드 정의: 그리드 또는 리스트
enum ViewMode { grid, list }

// 카테고리 필터 정의
enum CategoryFilter {
  all('전체', null),
  training('훈련', 'TRAINING'),
  drama('드라마', 'DRAMA');

  const CategoryFilter(this.label, this.value);
  final String label;
  final String? value; // null이면 전체 조회
}

// 리스트 화면의 전체 상태
class RelationTrainingListState {
  final AsyncValue<List<TrainingScenario>> scenarios;
  final ViewMode viewMode;
  final CategoryFilter categoryFilter;

  const RelationTrainingListState({
    required this.scenarios,
    this.viewMode = ViewMode.list, // 기본값: 리스트
    this.categoryFilter = CategoryFilter.all, // 기본값: 전체
  });

  RelationTrainingListState copyWith({
    AsyncValue<List<TrainingScenario>>? scenarios,
    ViewMode? viewMode,
    CategoryFilter? categoryFilter,
  }) {
    return RelationTrainingListState(
      scenarios: scenarios ?? this.scenarios,
      viewMode: viewMode ?? this.viewMode,
      categoryFilter: categoryFilter ?? this.categoryFilter,
    );
  }
}

class RelationTrainingListViewModel extends StateNotifier<RelationTrainingListState> {
  final RelationTrainingService _service;

  RelationTrainingListViewModel(this._service) 
      : super(const RelationTrainingListState(
          scenarios: AsyncValue.loading(),
        )) {
    getScenarios();
  }

  // 뷰 모드 토글 (그리드 ↔ 리스트)
  void toggleViewMode() {
    state = state.copyWith(
      viewMode: state.viewMode == ViewMode.grid ? ViewMode.list : ViewMode.grid,
    );
  }

  // 카테고리 필터 변경
  Future<void> setCategoryFilter(CategoryFilter filter) async {
    state = state.copyWith(
      categoryFilter: filter,
      scenarios: const AsyncValue.loading(),
    );
    await getScenarios();
  }

  Future<void> getScenarios() async {
    try {
      final scenarios = await _service.getScenarios(
        category: state.categoryFilter.value,
      );
      state = state.copyWith(scenarios: AsyncValue.data(scenarios));
    } catch (e, stack) {
      state = state.copyWith(scenarios: AsyncValue.error(e, stack));
    }
  }

  Future<void> generateScenario({
    required String target,
    required String topic,
    String category = 'TRAINING',
    String? genre,
  }) async {
    try {
      await _service.generateScenario(
        target: target,
        topic: topic,
        category: category,
        genre: genre,
      );
      // Refresh the scenario list after generation
      await getScenarios();
    } catch (e, stack) {
      state = state.copyWith(scenarios: AsyncValue.error(e, stack));
      rethrow;
    }
  }

  Future<void> deleteScenario(int scenarioId) async {
    try {
      await _service.deleteScenario(scenarioId);
      // Refresh the scenario list after deletion
      await getScenarios();
    } catch (e, stack) {
      state = state.copyWith(scenarios: AsyncValue.error(e, stack));
      rethrow;
    }
  }
}

final relationTrainingListViewModelProvider = StateNotifierProvider.autoDispose<RelationTrainingListViewModel, RelationTrainingListState>((ref) {
  final service = ref.watch(relationTrainingServiceProvider);
  return RelationTrainingListViewModel(service);
});
