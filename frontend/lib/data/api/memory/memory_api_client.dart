import 'package:dio/dio.dart';
import '../../../core/config/api_config.dart';
import '../../../core/utils/logger.dart';

/// 기억서랍 API Client
/// 메모리/히스토리 데이터를 가져오는 API 클라이언트
class MemoryApiClient {
  final Dio _dio;

  MemoryApiClient(this._dio);

  /// 기억 목록 조회
  /// GET /api/memory/list
  Future<List<Map<String, dynamic>>> fetchMemories() async {
    try {
      final response = await _dio.get('/api/memory/list');
      return (response.data as List).cast<Map<String, dynamic>>();
    } catch (e) {
      // API가 아직 준비되지 않은 경우 Mock 데이터 반환
      return _getMockData();
    }
  }

  /// Mock 데이터 (개발용)
  /// 실제 API 연동 전까지 사용
  List<Map<String, dynamic>> _getMockData() {
    return [
      {
        'id': 1,
        'content': '매우 중요한 발표가 있어서 긴장된다고 이야기 했음.',
        'timestamp': DateTime(2025, 11, 16, 14, 30).toIso8601String(),
        'category': 'spouse',
        'isPast': false,
        'title': '예정된 일정',
      },
      {
        'id': 2,
        'content': '사무자가 힘든 하루를 보내고 있으며, 밀린 일이 많아 힘들다고 이야기함.',
        'timestamp': DateTime(2025, 11, 11, 18, 32).toIso8601String(),
        'category': 'friend',
        'isPast': true,
        'title': null,
      },
      {
        'id': 3,
        'content': '오늘 동장 모임에 가기 위해 화장을 해야겠다는 이야기와 친구들과 즐거운 시간을 보내고 오겠다는 약속이 있었습니다.',
        'timestamp': DateTime(2025, 11, 9, 9, 0).toIso8601String(),
        'category': 'friend',
        'isPast': true,
        'title': null,
      },
      {
        'id': 4,
        'content': '직장에서 중요한 프로젝트 발표 예정',
        'timestamp': DateTime(2025, 11, 20, 10, 0).toIso8601String(),
        'category': 'workplace',
        'isPast': false,
        'title': '프로젝트 발표',
      },
      {
        'id': 5,
        'content': '아이들과 함께 놀이공원 가기로 약속했어요.',
        'timestamp': DateTime(2025, 11, 23, 14, 0).toIso8601String(),
        'category': 'children',
        'isPast': false,
        'title': '가족 나들이',
      },
      {
        'id': 6,
        'content': '남편과 저녁 식사 약속이 있었는데 정말 좋은 시간이었어요.',
        'timestamp': DateTime(2025, 11, 5, 19, 30).toIso8601String(),
        'category': 'spouse',
        'isPast': true,
        'title': null,
      },
      {
        'id': 7,
        'content': '팀 미팅에서 새로운 아이디어를 제안했고 좋은 반응을 얻었어요.',
        'timestamp': DateTime(2025, 11, 3, 15, 0).toIso8601String(),
        'category': 'workplace',
        'isPast': true,
        'title': null,
      },
      {
        'id': 8,
        'content': '친구들과 카페에서 수다 떨기로 했어요.',
        'timestamp': DateTime(2025, 11, 25, 15, 30).toIso8601String(),
        'category': 'friend',
        'isPast': false,
        'title': '친구 모임',
      },
    ];
  }
}
