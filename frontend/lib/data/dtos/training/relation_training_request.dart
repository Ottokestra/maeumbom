import 'package:freezed_annotation/freezed_annotation.dart';

part 'relation_training_request.freezed.dart';
part 'relation_training_request.g.dart';

@freezed
class ScenarioProgressRequest with _$ScenarioProgressRequest {
  const factory ScenarioProgressRequest({
    @JsonKey(name: 'scenario_id') required int scenarioId,
    @JsonKey(name: 'current_node_id') required int currentNodeId,
    @JsonKey(name: 'selected_option_code') required String selectedOptionCode,
    @JsonKey(name: 'current_path') required String currentPath,
  }) = _ScenarioProgressRequest;

  factory ScenarioProgressRequest.fromJson(Map<String, dynamic> json) => _$ScenarioProgressRequestFromJson(json);
}
