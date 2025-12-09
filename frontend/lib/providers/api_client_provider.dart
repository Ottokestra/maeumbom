import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/api_client.dart';
import 'auth_provider.dart';

/// 공통 ApiClient Provider - 인증 인터셉터가 적용된 Dio 사용
final apiClientProvider = Provider<ApiClient>((ref) {
  final dio = ref.watch(dioWithAuthProvider);
  return ApiClient(dio);
});
