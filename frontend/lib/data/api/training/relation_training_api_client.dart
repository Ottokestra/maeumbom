import 'package:dio/dio.dart';
import '../../../core/config/api_config.dart';
import '../../dtos/training/relation_training_request.dart';
import '../../models/training/relation_training.dart';

class RelationTrainingApiClient {
  final Dio _dio;

  RelationTrainingApiClient(this._dio);

  Future<ScenarioStartResponse> startScenario(int scenarioId) async {
    try {
      final response = await _dio.get(
        ApiConfig.relationTrainingStart(scenarioId),
      );
      print('[RelationTraining API] Start Response: ${response.data}'); // Debug Log
      return ScenarioStartResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<TrainingScenario>> getScenarios() async {
    try {
      final response = await _dio.get(
        ApiConfig.relationTrainingScenarios,
      );
      // Backend returns { "scenarios": [...], "total": 4 }
      final list = response.data['scenarios'] as List;
      print('[RelationTraining API] Scenarios List: $list'); // Debug Log
      final scenarios = <TrainingScenario>[];
      for (final e in list) {
        try {
          if (e == null) continue;
          print('[Scenario Item] $e');
          
          if (e is! Map) {
            print('[Error] Scenario item is not a Map: $e');
            continue;
          }
          
          if (e['id'] == null) {
            print('[Error] Scenario ID is null (skipping): $e');
            continue;
          }
          
          scenarios.add(TrainingScenario.fromJson(Map<String, dynamic>.from(e)));
        } catch (error) {
          print('[Error] Failed to parse scenario item: $e. Error: $error');
        }
      }
      return scenarios;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<ScenarioProgressResponse> progressScenario(ScenarioProgressRequest request) async {
    try {
      final response = await _dio.post(
        ApiConfig.relationTrainingProgress,
        data: request.toJson(),
      );
      return ScenarioProgressResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<GenerateScenarioResponse> generateScenario({
    required String target,
    required String topic,
    String category = 'TRAINING',
    String? genre,
  }) async {
    try {
      final requestData = {
        'target': target,
        'topic': topic,
        'category': category,
      };
      
      // 드라마 선택 시에만 genre 추가
      if (category == 'DRAMA' && genre != null) {
        requestData['genre'] = genre;
      }
      
      final response = await _dio.post(
        ApiConfig.relationTrainingGenerate,
        data: requestData,
      );
      return GenerateScenarioResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteScenario(int scenarioId) async {
    try {
      await _dio.delete(
        ApiConfig.relationTrainingDelete(scenarioId),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException e) {
    if (e.response != null) {
      final message = e.response!.data?['detail'] ?? 'Unknown error';
      return Exception('API Error: $message');
    }
    return Exception('Network error: ${e.message}');
  }
}
