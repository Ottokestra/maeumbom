import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/config/api_config.dart';
import '../core/services/auth_service.dart';
import '../core/services/token_storage_service.dart';
import '../core/services/google_oauth_service.dart';
import '../core/services/kakao_oauth_service.dart';
import '../core/services/naver_oauth_service.dart';
import '../core/utils/dio_interceptors.dart';
import '../data/api/auth_api_client.dart';
import '../data/repository/auth_repository.dart';
import '../data/models/user.dart';

// ----- Infrastructure Providers -----

/// Base Dio instance provider (without interceptor)
final baseDioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );
});

/// Secure storage provider
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );
});

// ----- Service Providers -----

/// Token storage service provider
final tokenStorageServiceProvider = Provider<TokenStorageService>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return TokenStorageService(storage);
});

/// Google OAuth service provider
final googleOAuthServiceProvider = Provider<GoogleOAuthService>((ref) {
  return GoogleOAuthService();
});

/// Kakao OAuth service provider
final kakaoOAuthServiceProvider = Provider<KakaoOAuthService>((ref) {
  return KakaoOAuthService();
});

/// Naver OAuth service provider
final naverOAuthServiceProvider = Provider<NaverOAuthService>((ref) {
  return NaverOAuthService();
});

/// API client provider
final authApiClientProvider = Provider<AuthApiClient>((ref) {
  final dio = ref.watch(baseDioProvider);
  return AuthApiClient(dio);
});

/// Repository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(authApiClientProvider);
  return AuthRepository(apiClient);
});

/// Auth service provider
final authServiceProvider = Provider<AuthService>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  final tokenStorage = ref.watch(tokenStorageServiceProvider);
  final googleOAuth = ref.watch(googleOAuthServiceProvider);
  final kakaoOAuth = ref.watch(kakaoOAuthServiceProvider);
  final naverOAuth = ref.watch(naverOAuthServiceProvider);

  return AuthService(
    repository,
    tokenStorage,
    googleOAuth,
    kakaoOAuth: kakaoOAuth,
    naverOAuth: naverOAuth,
  );
});

// ----- State Providers -----

/// Auth state notifier
class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AsyncValue.loading()) {
    _checkAuthStatus();
  }

  /// Check if user is already authenticated on app start
  Future<void> _checkAuthStatus() async {
    try {
      final isAuth = await _authService.isAuthenticated();
      if (isAuth) {
        final user = await _authService.getCurrentUser();
        state = AsyncValue.data(user);
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Login with Google
  Future<void> loginWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      final user = await _authService.loginWithGoogle();
      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Login with Kakao
  Future<void> loginWithKakao() async {
    state = const AsyncValue.loading();
    try {
      final user = await _authService.loginWithKakao();
      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Login with Naver
  Future<void> loginWithNaver() async {
    state = const AsyncValue.loading();
    try {
      final user = await _authService.loginWithNaver();
      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      await _authService.logout();
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Refresh user data
  Future<void> refreshUser() async {
    try {
      final user = await _authService.getCurrentUser();
      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

/// Auth state provider
final authProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});

/// Convenience provider for current user
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).value;
});

/// Convenience provider for auth status
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});

// ----- Dio with Interceptor (for general API calls) -----

/// Dio instance with auth interceptor for protected endpoints
final dioWithAuthProvider = Provider<Dio>((ref) {
  final dio = ref.watch(baseDioProvider);
  final authService = ref.watch(authServiceProvider);

  // Add auth interceptor
  dio.interceptors.add(AuthInterceptor(authService, dio));

  return dio;
});
