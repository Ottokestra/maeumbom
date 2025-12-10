import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/api/training/relation_training_api_client.dart';
import '../../data/repository/training/relation_training_repository.dart';
import '../../core/services/training/relation_training_service.dart';
import '../../data/models/training/relation_training.dart';
import '../../providers/auth_provider.dart'; // Import auth_provider

// --- Providers ---

final relationTrainingApiClientProvider =
    Provider<RelationTrainingApiClient>((ref) {
  // Use the authenticated Dio instance from auth_provider
  // This automatically adds the Bearer token and handles refresh logic
  final dio = ref.watch(dioWithAuthProvider);
  return RelationTrainingApiClient(dio);
});

final relationTrainingRepositoryProvider =
    Provider<RelationTrainingRepository>((ref) {
  return RelationTrainingRepository(ref.watch(relationTrainingApiClientProvider));
});

final relationTrainingServiceProvider =
    Provider<RelationTrainingService>((ref) {
  return RelationTrainingService(ref.watch(relationTrainingRepositoryProvider));
});

final relationTrainingViewModelProvider = StateNotifierProvider.autoDispose
    .family<RelationTrainingViewModel, AsyncValue<RelationTrainingState>, int>(
  (ref, scenarioId) {
    return RelationTrainingViewModel(
      ref.watch(relationTrainingServiceProvider),
      scenarioId,
    );
  },
);

// --- State ---

class RelationTrainingState {
  final ScenarioNode? currentNode;
  final String currentPath;
  final bool isFinished;
  final ScenarioResult? result;
  final String? scenarioImage;
  final List<ScenarioNode> history;

  RelationTrainingState({
    this.currentNode,
    this.currentPath = '',
    this.isFinished = false,
    this.result,
    this.scenarioImage,
    this.history = const [],
  });

  RelationTrainingState copyWith({
    ScenarioNode? currentNode,
    String? currentPath,
    bool? isFinished,
    ScenarioResult? result,
    String? scenarioImage,
    List<ScenarioNode>? history,
  }) {
    return RelationTrainingState(
      currentNode: currentNode ?? this.currentNode,
      currentPath: currentPath ?? this.currentPath,
      isFinished: isFinished ?? this.isFinished,
      result: result ?? this.result,
      scenarioImage: scenarioImage ?? this.scenarioImage,
      history: history ?? this.history,
    );
  }
}

// --- ViewModel ---

class RelationTrainingViewModel
    extends StateNotifier<AsyncValue<RelationTrainingState>> {
  final RelationTrainingService _service;
  final int _scenarioId;

  RelationTrainingViewModel(this._service, this._scenarioId)
      : super(const AsyncValue.loading()) {
    _startScenario();
  }

  Future<void> _startScenario() async {
    try {
      final response = await _service.startScenario(_scenarioId);
      state = AsyncValue.data(
        RelationTrainingState(
          currentNode: response.currentNode,
          currentPath: '',
          scenarioImage: response.imageUrl,
        ),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> selectOption(ScenarioOption option) async {
    final currentState = state.value;
    if (currentState == null || currentState.currentNode == null) return;

    try {
      // Store current node in history before moving
      final newHistory = List<ScenarioNode>.from(currentState.history)
        ..add(currentState.currentNode!);

      final response = await _service.progressScenario(
        scenarioId: _scenarioId,
        currentNodeId: currentState.currentNode!.id,
        selectedOptionCode: option.optionCode,
        currentPath: currentState.currentPath,
      );

      // Append option code to path
      // Note: Backend might rely on the full path sent in next request to assume history,
      // but here we just track it for completeness.
      final newPath = currentState.currentPath.isEmpty
          ? option.optionCode
          : '${currentState.currentPath}-${option.optionCode}';

      if (response.isFinished) {
        state = AsyncValue.data(
          currentState.copyWith(
            isFinished: true,
            result: response.result,
            currentPath: newPath,
            history: newHistory,
          ),
        );
      } else {
        state = AsyncValue.data(
          currentState.copyWith(
            currentNode: response.nextNode,
            currentPath: newPath,
            history: newHistory,
          ),
        );
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Go back to the previous node
  /// Returns true if went back, false if no history (should pop screen)
  bool navigateBack() {
    final currentState = state.value;
    if (currentState == null || currentState.history.isEmpty) {
      return false;
    }

    final newHistory = List<ScenarioNode>.from(currentState.history);
    final previousNode = newHistory.removeLast();

    // Adjust path - remove last segment
    // Assuming format "A-B-C" or "A"
    String newPath = currentState.currentPath;
    if (newPath.contains('-')) {
      newPath = newPath.substring(0, newPath.lastIndexOf('-'));
    } else {
      newPath = '';
    }

    state = AsyncValue.data(
      currentState.copyWith(
        currentNode: previousNode,
        currentPath: newPath,
        isFinished: false, // Always reset finished state when going back
        result: null,
        history: newHistory,
      ),
    );

    return true;
  }
}
