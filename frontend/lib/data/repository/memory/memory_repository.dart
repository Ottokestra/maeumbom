import '../../api/memory/memory_api_client.dart';
import '../../models/memory/memory_item.dart';

/// 기억서랍 Repository
/// API Client와 도메인 모델 간의 데이터 변환 담당
class MemoryRepository {
  final MemoryApiClient _apiClient;

  MemoryRepository(this._apiClient);

  /// 기억 목록 조회
  Future<List<MemoryItem>> getMemories() async {
    final response = await _apiClient.fetchMemories();
    return response.map((json) => MemoryItem.fromJson(json)).toList();
  }
}
