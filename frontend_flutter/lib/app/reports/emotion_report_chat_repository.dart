import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'emotion_report_chat_model.dart';

final emotionReportChatRepositoryProvider =
    Provider<EmotionReportChatRepository>((ref) {
  final dio = Dio();
  return EmotionReportChatRepository(dio);
});

class EmotionReportChatRepository {
  EmotionReportChatRepository(this._dio);

  final Dio _dio;

  Future<EmotionReportChat> fetchWeeklyChat() async {
    final response = await _dio.get('/api/reports/emotion/weekly/chat');
    return EmotionReportChat.fromJson(response.data as Map<String, dynamic>);
  }
}
