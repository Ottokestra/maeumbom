class RecommendationResponse {
  final String title;
  final String content;
  final String type;

  RecommendationResponse({
    required this.title,
    required this.content,
    required this.type,
  });

  factory RecommendationResponse.fromJson(Map<String, dynamic> json, String type) {
    return RecommendationResponse(
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      type: type,
    );
  }
}
