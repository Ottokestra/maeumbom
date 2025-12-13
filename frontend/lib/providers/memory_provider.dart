import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/api/memory/memory_api_client.dart';
import '../data/repository/memory/memory_repository.dart';
import '../data/models/memory/memory_item.dart';
import 'auth_provider.dart';

// ----- Infrastructure Providers -----

/// Memory API Client Provider
final memoryApiClientProvider = Provider<MemoryApiClient>((ref) {
  final dio = ref.watch(dioWithAuthProvider);
  return MemoryApiClient(dio);
});

/// Memory Repository Provider
final memoryRepositoryProvider = Provider<MemoryRepository>((ref) {
  final apiClient = ref.watch(memoryApiClientProvider);
  return MemoryRepository(apiClient);
});

// ----- State Provider -----

/// Memory State Notifier
class MemoryNotifier extends StateNotifier<AsyncValue<List<MemoryItem>>> {
  final MemoryRepository _repository;

  MemoryNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadMemories();
  }

  /// 기억 목록 로드
  Future<void> loadMemories() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final memories = await _repository.getMemories();

      // 최신순 정렬 (timestamp 내림차순)
      memories.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return memories;
    });
  }

  /// 기억 목록 새로고침
  Future<void> refreshMemories() async {
    await loadMemories();
  }
}

/// Memory Provider
final memoryProvider =
    StateNotifierProvider<MemoryNotifier, AsyncValue<List<MemoryItem>>>((ref) {
  final repository = ref.watch(memoryRepositoryProvider);
  return MemoryNotifier(repository);
});
