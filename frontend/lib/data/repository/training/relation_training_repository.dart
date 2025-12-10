// 기존 (오류): import '../../data/api/training/relation_training_api_client.dart';
// 수정:
import '../../api/training/relation_training_api_client.dart'; 

// 기존 (오류): import '../../data/dtos/training/relation_training_request.dart';
// 수정:
import '../../dtos/training/relation_training_request.dart';

// 기존 (오류): import '../../data/models/training/relation_training.dart';
// 수정:
import '../../models/training/relation_training.dart';

class RelationTrainingRepository {
  final RelationTrainingApiClient _apiClient;

  RelationTrainingRepository(this._apiClient);

  Future<ScenarioStartResponse> startScenario(int scenarioId) async {
    return _apiClient.startScenario(scenarioId);
  }

  Future<List<TrainingScenario>> getScenarios() async {
    return _apiClient.getScenarios();
  }

  Future<ScenarioProgressResponse> progressScenario({
    required int scenarioId,
    required int currentNodeId,
    required String selectedOptionCode,
    required String currentPath,
  }) async {
    final request = ScenarioProgressRequest(
      scenarioId: scenarioId,
      currentNodeId: currentNodeId,
      selectedOptionCode: selectedOptionCode,
      currentPath: currentPath,
    );
    return _apiClient.progressScenario(request);
  }
}
