import '../../../data/repository/auth/auth_repository.dart';
import '../../../data/models/auth/user.dart';
import '../../../data/models/auth/token_pair.dart';
import 'token_storage_service.dart';
import 'google_oauth_service.dart';
import 'kakao_oauth_service.dart';
import 'naver_oauth_service.dart';
import '../../config/oauth_config.dart';
import '../../utils/logger.dart';

/// Auth Service - Business logic for authentication
class AuthService {
  final AuthRepository _repository;
  final TokenStorageService _tokenStorage;
  final GoogleOAuthService _googleOAuth;
  final KakaoOAuthService? _kakaoOAuth;
  final NaverOAuthService? _naverOAuth;

  AuthService(
    this._repository,
    this._tokenStorage,
    this._googleOAuth, {
    KakaoOAuthService? kakaoOAuth,
    NaverOAuthService? naverOAuth,
  })  : _kakaoOAuth = kakaoOAuth,
        _naverOAuth = naverOAuth;

  /// Login with Google OAuth
  Future<User> loginWithGoogle() async {
    try {
      appLogger.i('Starting Google login flow (DUMMY MODE)...');

      // 더미 모드: 실제 Google OAuth 호출 없이 더미 데이터 생성
      // TODO: 개발 완료 후 실제 OAuth 플로우로 교체
      final dummyTokens = TokenPair(
        accessToken:
            'dummy-google-access-token-${DateTime.now().millisecondsSinceEpoch}',
        refreshToken:
            'dummy-google-refresh-token-${DateTime.now().millisecondsSinceEpoch}',
      );

      final dummyUser = User(
        id: 1,
        email: 'google-test@example.com',
        nickname: '구글테스트',
        provider: 'google',
        createdAt: DateTime.now(),
      );

      // Step 3: Store tokens securely
      await _tokenStorage.saveTokens(dummyTokens);

      appLogger.i('Google login completed (DUMMY): ${dummyUser.email}');
      return dummyUser;
    } catch (e) {
      appLogger.e('Google login failed', error: e);
      // Clean up on failure
      await _googleOAuth.signOut();
      rethrow;
    }
  }

  /// Login with Kakao OAuth
  Future<User> loginWithKakao() async {
    if (_kakaoOAuth == null) {
      throw Exception('Kakao OAuth service not initialized');
    }

    try {
      appLogger.i('Starting Kakao login flow...');

      // Step 1: Get access token from Kakao SDK
      final accessToken = await _kakaoOAuth!.signIn();
      appLogger.i('Kakao SDK login successful, exchanging token...');

      // Step 2: Send access token to backend for verification and user creation
      // 백엔드에서 이 토큰으로 카카오 사용자 정보를 가져와서 처리
      final (tokens, user) = await _repository.loginWithKakao(
        authCode: accessToken, // accessToken을 authCode 파라미터로 전달
        redirectUri: OAuthConfig.kakaoRedirectUri,
      );
      appLogger.i('Token exchange successful');

      // Step 3: Store tokens securely
      await _tokenStorage.saveTokens(tokens);

      appLogger.i('Kakao login completed: ${user.email}');
      return user;
    } catch (e) {
      // 상세한 에러 로깅 및 사용자 친화적 메시지 제공
      final errorMessage = e.toString();
      
      if (errorMessage.contains('로그인이 취소되었습니다') || 
          errorMessage.contains('User canceled') ||
          errorMessage.contains('CANCELED')) {
        appLogger.i('Kakao login canceled by user');
        throw Exception('로그인이 취소되었습니다.');
      } else if (errorMessage.contains('network') || errorMessage.contains('네트워크')) {
        appLogger.w('Kakao login network error');
        throw Exception('네트워크 연결을 확인하고 다시 시도해주세요.');
      } else {
        appLogger.e('Kakao login failed', error: e);
        throw Exception('카카오 로그인에 실패했습니다. 잠시 후 다시 시도해주세요.');
      }
    }
  }

  /// Login with Naver OAuth
  Future<User> loginWithNaver() async {
    if (_naverOAuth == null) {
      throw Exception('Naver OAuth service not initialized');
    }

    try {
      appLogger.i('Starting Naver login flow...');

      // Step 1: Get authorization code and state from Naver
      final (authCode, state) = await _naverOAuth!.signIn();
      appLogger.i('OAuth authorization successful, exchanging for tokens...');

      // Step 2: Exchange auth code for tokens via backend
      final (tokens, user) = await _repository.loginWithNaver(
        authCode: authCode,
        redirectUri: OAuthConfig.naverRedirectUri,
        state: state,
      );
      appLogger.i('Token exchange successful');

      // Step 3: Store tokens securely
      await _tokenStorage.saveTokens(tokens);

      appLogger.i('Naver login completed: ${user.email}');
      return user;
    } catch (e) {
      // 상세한 에러 로깅 및 사용자 친화적 메시지 제공
      final errorMessage = e.toString();
      
      if (errorMessage.contains('로그인이 취소되었습니다') || 
          errorMessage.contains('User canceled') ||
          errorMessage.contains('CANCELED')) {
        appLogger.i('Naver login canceled by user');
        throw Exception('로그인이 취소되었습니다.');
      } else if (errorMessage.contains('timeout') || errorMessage.contains('시간이 초과')) {
        appLogger.w('Naver login timeout');
        throw Exception('로그인 시간이 초과되었습니다. 다시 시도해주세요.');
      } else if (errorMessage.contains('network') || errorMessage.contains('네트워크')) {
        appLogger.w('Naver login network error');
        throw Exception('네트워크 연결을 확인하고 다시 시도해주세요.');
      } else if (errorMessage.contains('State mismatch') || errorMessage.contains('CSRF')) {
        appLogger.e('Naver login CSRF attack detected');
        throw Exception('보안 오류가 발생했습니다. 다시 시도해주세요.');
      } else {
        appLogger.e('Naver login failed', error: e);
        throw Exception('네이버 로그인에 실패했습니다. 잠시 후 다시 시도해주세요.');
      }
    }
  }

  /// Refresh access token
  Future<TokenPair> refreshToken() async {
    try {
      final currentRefreshToken = await _tokenStorage.getRefreshToken();

      if (currentRefreshToken == null) {
        throw Exception('No refresh token available');
      }

      // Get new tokens from backend (RTR strategy)
      final newTokens = await _repository.refreshAccessToken(
        currentRefreshToken,
      );

      // Store new tokens
      await _tokenStorage.saveTokens(newTokens);

      appLogger.i('Token refreshed successfully');
      return newTokens;
    } catch (e) {
      appLogger.e('Token refresh failed', error: e);
      rethrow;
    }
  }

  /// Get current user
  Future<User?> getCurrentUser() async {
    try {
      final accessToken = await _tokenStorage.getAccessToken();

      if (accessToken == null) {
        return null;
      }

      return await _repository.getCurrentUser(accessToken);
    } catch (e) {
      appLogger.e('Get current user failed', error: e);
      return null;
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      final accessToken = await _tokenStorage.getAccessToken();

      if (accessToken != null) {
        // Logout from backend (invalidates refresh token)
        await _repository.logout(accessToken);
      }

      // Clear stored tokens
      await _tokenStorage.clearTokens();

      // Sign out from Google
      await _googleOAuth.signOut();

      appLogger.i('Logout successful');
    } catch (e) {
      appLogger.e('Logout failed', error: e);
      // Still clear tokens even if backend call fails
      await _tokenStorage.clearTokens();
      await _googleOAuth.signOut();
    }
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    return await _tokenStorage.hasTokens();
  }

  /// Get stored access token
  Future<String?> getAccessToken() async {
    return await _tokenStorage.getAccessToken();
  }
}
