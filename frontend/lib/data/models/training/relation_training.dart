import 'package:freezed_annotation/freezed_annotation.dart';

part 'relation_training.freezed.dart';
part 'relation_training.g.dart';

@freezed
class ScenarioOption with _$ScenarioOption {
  const factory ScenarioOption({
    required int id,
    @JsonKey(name: 'option_code') required String optionCode,
    @JsonKey(name: 'option_text') required String optionText,
  }) = _ScenarioOption;

  factory ScenarioOption.fromJson(Map<String, dynamic> json) => _$ScenarioOptionFromJson(json);
}

@freezed
class ScenarioNode with _$ScenarioNode {
  const factory ScenarioNode({
    required int id,
    @JsonKey(name: 'step_level') required int stepLevel,
    @JsonKey(name: 'situation_text') required String situationText,
    @JsonKey(name: 'image_url') String? imageUrl,
    required List<ScenarioOption> options,
  }) = _ScenarioNode;

  factory ScenarioNode.fromJson(Map<String, dynamic> json) => _$ScenarioNodeFromJson(json);
}

@freezed
class ScenarioResult with _$ScenarioResult {
  const factory ScenarioResult({
    // Backend returns 'result_id', 'result_code', 'display_title', 'analysis_text', 'image_url'
    @JsonKey(name: 'result_id') required int id,
    @JsonKey(name: 'display_title') required String title,
    @JsonKey(name: 'analysis_text') required String resultText,
    @JsonKey(name: 'image_url') String? resultImageUrl,
  }) = _ScenarioResult;

  factory ScenarioResult.fromJson(Map<String, dynamic> json) => _$ScenarioResultFromJson(json);
}

@freezed
class ScenarioStartResponse with _$ScenarioStartResponse {
  const factory ScenarioStartResponse({
    @JsonKey(name: 'scenario_id') required int scenarioId,
    @JsonKey(name: 'start_image_url') String? imageUrl,
    // API returns 'first_node' but we map it to 'currentNode' domain model
    @JsonKey(name: 'first_node') ScenarioNode? currentNode,
  }) = _ScenarioStartResponse;

  factory ScenarioStartResponse.fromJson(Map<String, dynamic> json) => _$ScenarioStartResponseFromJson(json);
}

@freezed
class ScenarioProgressResponse with _$ScenarioProgressResponse {
  const factory ScenarioProgressResponse({
    @JsonKey(name: 'is_finished') required bool isFinished,
    @JsonKey(name: 'next_node') ScenarioNode? nextNode,
    ScenarioResult? result,
  }) = _ScenarioProgressResponse;

  factory ScenarioProgressResponse.fromJson(Map<String, dynamic> json) => _$ScenarioProgressResponseFromJson(json);
}
@freezed
class TrainingScenario with _$TrainingScenario {
 const factory TrainingScenario({
  required int id,
  required String title,
  required String category,
      // --- 새로 추가되는 필드 ---
      @JsonKey(name: 'target_type') String? targetType, // String으로 예상
      @JsonKey(name: 'user_id') int? userId, // Backend에서 null로 보내므로 int?로 처리
      // ----------------------
  String? description,
  @JsonKey(name: 'start_image_url') String? imageUrl,
  }) = _TrainingScenario;

 factory TrainingScenario.fromJson(Map<String, dynamic> json) => _$TrainingScenarioFromJson(json);
}

@freezed
class GenerateScenarioResponse with _$GenerateScenarioResponse {
  const factory GenerateScenarioResponse({
    @JsonKey(name: 'scenario_id') required int scenarioId,
    required String status,
    @JsonKey(name: 'image_count') required int imageCount,
    @JsonKey(name: 'folder_name') required String folderName,
    String? message,
  }) = _GenerateScenarioResponse;

  factory GenerateScenarioResponse.fromJson(Map<String, dynamic> json) => _$GenerateScenarioResponseFromJson(json);
}