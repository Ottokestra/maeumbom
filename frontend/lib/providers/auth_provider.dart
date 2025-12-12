import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/config/api_config.dart';
import '../core/services/auth/auth_service.dart';
import '../core/services/auth/token_storage_service.dart';
import '../core/services/auth/google_oauth_service.dart';
import '../core/services/auth/kakao_oauth_service.dart';
import '../core/services/auth/naver_oauth_service.dart';
import '../core/utils/dio_interceptors.dart';
import '../core/utils/error_logger.dart';
import '../data/api/auth/auth_api_client.dart';
import '../data/api/user_phase/user_phase_api_client.dart';
import '../data/repository/auth/auth_repository.dart';
import '../data/models/auth/user.dart';

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
  /// Automatically refreshes token if expired
  Future<void> _checkAuthStatus() async {
    try {
      final isAuth = await _authService.isAuthenticated();
      if (isAuth) {
        // getCurrentUser() will automatically refresh token if expired
        final user = await _authService.getCurrentUser();
        
        if (user != null) {
          state = AsyncValue.data(user);
        } else {
          // Token refresh failed or user not found
          // Clear state and require login
          state = const AsyncValue.data(null);
        }
      } else {
        // No tokens stored
        state = const AsyncValue.data(null);
      }
    } catch (e) {
      // Log error but don't show error state to user
      // Just set to null (not logged in)
      state = const AsyncValue.data(null);
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
  dio.interceptors.add(
    AuthInterceptor(
      authService,
      dio,
      errorLogger: const AppErrorLogger(),
    ),
  );

  return dio;
});

// ----- User Phase API Client Provider -----

/// User Phase API Client provider
final userPhaseApiClientProvider = Provider<UserPhaseApiClient>((ref) {
  final dio = ref.watch(dioWithAuthProvider);
  return UserPhaseApiClient(dio);
});