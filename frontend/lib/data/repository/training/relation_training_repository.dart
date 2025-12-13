// 기존 (오류): import '../../data/api/training/relation_training_api_client.dart';
// 수정:
import '../../api/training/relation_training_api_client.dart';

// 기존 (오류): import '../../data/dtos/training/relation_training_request.dart';
// 수정:
import '../../dtos/training/relation_training_request.dart';

// 기존 (오류): import '../../data/models/training/relation_training.dart';
// 수정:
import '../../models/training/relation_training.dart';

// 여기 수정해야 하는 부분
import '../../../core/config/api_config.dart'; // Import ApiConfig

class RelationTrainingRepository {
  final RelationTrainingApiClient _apiClient;

  RelationTrainingRepository(this._apiClient);

  Future<ScenarioStartResponse> startScenario(int scenarioId) async {
    final response = await _apiClient.startScenario(scenarioId);

    // Fix image URLs in the response
    if (response.currentNode != null) {
      return response.copyWith(
        currentNode: response.currentNode!.copyWith(
          imageUrl: _fixImageUrl(response.currentNode!.imageUrl),
          // Fix options
          options: response.currentNode!.options.toList(), // options have no images
        )
      );
    }
    return response;
  }

  Future<List<TrainingScenario>> getScenarios({String? category}) async {
    final scenarios = await _apiClient.getScenarios(category: category);
    return scenarios.map((s) => s.copyWith(
      imageUrl: _fixImageUrl(s.imageUrl)
    )).toList();
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
    final response = await _apiClient.progressScenario(request);

    // Fix image URLs
    return response.copyWith(
      nextNode: response.nextNode?.copyWith(
        imageUrl: _fixImageUrl(response.nextNode!.imageUrl)
      ),
      result: response.result?.copyWith(
        resultImageUrl: _fixImageUrl(response.result!.resultImageUrl)
      )
    );
  }

  Future<GenerateScenarioResponse> generateScenario({
    required String target,
    required String topic,
    String category = 'TRAINING',
    String? genre,
  }) async {
    return _apiClient.generateScenario(
      target: target,
      topic: topic,
      category: category,
      genre: genre,
    );
  }

  Future<void> deleteScenario(int scenarioId) async {
    return _apiClient.deleteScenario(scenarioId);
  }

  String? _fixImageUrl(String? url) {
    if (url == null || url.isEmpty) return null;

    // Handle relative paths
    if (url.startsWith('/')) {
      return '${ApiConfig.baseUrl}$url';
    }

    // Handle localhost on Android
    if (url.contains('localhost') && ApiConfig.baseUrl.contains('10.0.2.2')) {
      return url.replaceFirst('localhost', '10.0.2.2');
    }
    
    // Also handle 127.0.0.1 just in case
    if (url.contains('127.0.0.1') && ApiConfig.baseUrl.contains('10.0.2.2')) {
       return url.replaceFirst('127.0.0.1', '10.0.2.2');
    }

    return url;
  }
}
