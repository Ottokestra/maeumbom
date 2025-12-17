import 'package:freezed_annotation/freezed_annotation.dart';

part 'emotion_history_model.freezed.dart';
part 'emotion_history_model.g.dart';

/// 감정 이력 모델
@freezed
class EmotionHistoryModel with _$EmotionHistoryModel {
  const factory EmotionHistoryModel({
    @JsonKey(name: 'CREATED_AT') required DateTime createdAt,
    @JsonKey(name: 'SENTIMENT_OVERALL') String? sentimentOverall,
    @JsonKey(name: 'PRIMARY_EMOTION') PrimaryEmotionData? primaryEmotion,
    @JsonKey(name: 'CHECK_ROOT') String? checkRoot,
  }) = _EmotionHistoryModel;

  factory EmotionHistoryModel.fromJson(Map<String, dynamic> json) =>
      _$EmotionHistoryModelFromJson(json);
}

/// 주요 감정 데이터
@freezed
class PrimaryEmotionData with _$PrimaryEmotionData {
  const factory PrimaryEmotionData({
    String? code, // "joy", "sadness" 등
    @JsonKey(name: 'name_ko') String? nameKo, // "기쁨", "슬픔" 등
    String? group, // "positive", "negative"
    required int intensity,
    required double confidence,
  }) = _PrimaryEmotionData;

  factory PrimaryEmotionData.fromJson(Map<String, dynamic> json) =>
      _$PrimaryEmotionDataFromJson(json);
}

