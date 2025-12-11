import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/training/relation_training.dart';
import '../../core/services/training/relation_training_service.dart';
import 'relation_training_viewmodel.dart'; // To access service provider

class RelationTrainingListViewModel extends StateNotifier<AsyncValue<List<TrainingScenario>>> {
  final RelationTrainingService _service;

  RelationTrainingListViewModel(this._service) : super(const AsyncValue.loading()) {
    getScenarios();
  }

  Future<void> getScenarios() async {
    try {
      final scenarios = await _service.getScenarios();
      state = AsyncValue.data(scenarios);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> generateScenario({
    required String target,
    required String topic,
  }) async {
    try {
      await _service.generateScenario(target: target, topic: topic);
      // Refresh the scenario list after generation
      await getScenarios();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> deleteScenario(int scenarioId) async {
    try {
      await _service.deleteScenario(scenarioId);
      // Refresh the scenario list after deletion
      await getScenarios();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}

final relationTrainingListViewModelProvider = StateNotifierProvider.autoDispose<RelationTrainingListViewModel, AsyncValue<List<TrainingScenario>>>((ref) {
  final service = ref.watch(relationTrainingServiceProvider);
  return RelationTrainingListViewModel(service);
});
