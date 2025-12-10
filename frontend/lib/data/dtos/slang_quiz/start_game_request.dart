import 'package:freezed_annotation/freezed_annotation.dart';

part 'start_game_request.freezed.dart';
part 'start_game_request.g.dart';

@freezed
class StartGameRequest with _$StartGameRequest {
  const factory StartGameRequest({
    required String level,
    @JsonKey(name: 'quiz_type') required String quizType,
  }) = _StartGameRequest;

  factory StartGameRequest.fromJson(Map<String, dynamic> json) =>
      _$StartGameRequestFromJson(json);
}

