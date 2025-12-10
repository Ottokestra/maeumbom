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
      appLogger.i('구글 로그인 요청');

      // 먼저 저장된 토큰이 유효한지 확인
      final existingUser = await getCurrentUser();
      if (existingUser != null) {
        appLogger.i('이미 로그인된 상태입니다. 저장된 토큰 사용: ${existingUser.email}');
        return existingUser;
      }

      // Step 1: Get ID Token (or auth code) from Google SDK
      // ID Token is preferred as it's more reliable than serverAuthCode
      final tokenOrCode = await _googleOAuth.signIn();
      
      // Determine if it's an ID Token (starts with "eyJ") or auth code
      final isIdToken = tokenOrCode.startsWith('eyJ');
      
      // Step 2: Send ID Token or auth code to backend for verification and user creation
      // 백엔드에서 ID Token을 검증하거나 auth code로 Google 사용자 정보를 가져와서 처리
      final (tokens, user) = await _repository.loginWithGoogle(
        authCode: isIdToken ? null : tokenOrCode,
        idToken: isIdToken ? tokenOrCode : null,
        redirectUri: OAuthConfig.googleRedirectUri,
      );

      // Step 3: Store tokens securely
      await _tokenStorage.saveTokens(tokens);

      appLogger.i('구글 로그인 완료: ${user.email}');
      return user;
    } catch (e) {
      appLogger.e('구글 로그인 실패', error: e);
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
      appLogger.i('카카오 로그인 요청');

      // 먼저 저장된 토큰이 유효한지 확인
      final existingUser = await getCurrentUser();
      if (existingUser != null) {
        appLogger.i('이미 로그인된 상태입니다. 저장된 토큰 사용: ${existingUser.email}');
        return existingUser;
      }

      // Step 1: Get access token from Kakao SDK
      final accessToken = await _kakaoOAuth!.signIn();

      // Step 2: Send access token to backend for verification and user creation
      // 백엔드에서 이 토큰으로 카카오 사용자 정보를 가져와서 처리
      final (tokens, user) = await _repository.loginWithKakao(
        authCode: accessToken, // accessToken을 authCode 파라미터로 전달
        redirectUri: OAuthConfig.kakaoRedirectUri,
      );

      // Step 3: Store tokens securely
      await _tokenStorage.saveTokens(tokens);

      appLogger.i('카카오 로그인 완료: ${user.email}');
      return user;
    } catch (e) {
      // 상세한 에러 로깅 및 사용자 친화적 메시지 제공
      final errorMessage = e.toString();

      if (errorMessage.contains('로그인이 취소되었습니다') ||
          errorMessage.contains('User canceled') ||
          errorMessage.contains('CANCELED')) {
        throw Exception('로그인이 취소되었습니다.');
      } else if (errorMessage.contains('network') ||
          errorMessage.contains('네트워크')) {
        throw Exception('네트워크 연결을 확인하고 다시 시도해주세요.');
      } else {
        appLogger.e('카카오 로그인 실패', error: e);
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
      appLogger.i('네이버 로그인 요청');

      // 먼저 저장된 토큰이 유효한지 확인
      final existingUser = await getCurrentUser();
      if (existingUser != null) {
        appLogger.i('이미 로그인된 상태입니다. 저장된 토큰 사용: ${existingUser.email}');
        return existingUser;
      }

      // Step 1: Get authorization code and state from Naver
      final (authCode, state) = await _naverOAuth!.signIn();

      // Step 2: Exchange auth code for tokens via backend
      final (tokens, user) = await _repository.loginWithNaver(
        authCode: authCode,
        redirectUri: OAuthConfig.naverRedirectUri,
        state: state,
      );

      // Step 3: Store tokens securely
      await _tokenStorage.saveTokens(tokens);

      appLogger.i('네이버 로그인 완료: ${user.email}');
      return user;
    } catch (e) {
      // 상세한 에러 로깅 및 사용자 친화적 메시지 제공
      final errorMessage = e.toString();

      if (errorMessage.contains('로그인이 취소되었습니다') ||
          errorMessage.contains('User canceled') ||
          errorMessage.contains('CANCELED')) {
        throw Exception('로그인이 취소되었습니다.');
      } else if (errorMessage.contains('timeout') ||
          errorMessage.contains('시간이 초과')) {
        throw Exception('로그인 시간이 초과되었습니다. 다시 시도해주세요.');
      } else if (errorMessage.contains('network') ||
          errorMessage.contains('네트워크')) {
        throw Exception('네트워크 연결을 확인하고 다시 시도해주세요.');
      } else if (errorMessage.contains('State mismatch') ||
          errorMessage.contains('CSRF')) {
        appLogger.e('네이버 로그인 보안 오류 (CSRF)');
        throw Exception('보안 오류가 발생했습니다. 다시 시도해주세요.');
      } else {
        appLogger.e('네이버 로그인 실패', error: e);
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

      return newTokens;
    } catch (e) {
      appLogger.e('토큰 갱신 실패', error: e);
      rethrow;
    }
  }

  /// Get current user
  /// Automatically refreshes access token if expired (401 error)
  Future<User?> getCurrentUser() async {
    try {
      final accessToken = await _tokenStorage.getAccessToken();

      if (accessToken == null) {
        appLogger.d('액세스 토큰이 없습니다.');
        return null;
      }

      try {
        return await _repository.getCurrentUser(accessToken);
      } catch (e) {
        // Check if error is 401 Unauthorized (token expired)
        final errorMessage = e.toString().toLowerCase();
        if (errorMessage.contains('unauthorized') || 
            errorMessage.contains('401') ||
            errorMessage.contains('인증이 필요')) {
          appLogger.w('액세스 토큰이 만료되었습니다. 리프레시 토큰으로 갱신 시도...');
          
          try {
            // Try to refresh token
            await refreshToken();
            
            // Retry with new access token
            final newAccessToken = await _tokenStorage.getAccessToken();
            if (newAccessToken != null) {
              appLogger.i('토큰 갱신 성공. 사용자 정보 재조회...');
              return await _repository.getCurrentUser(newAccessToken);
            } else {
              appLogger.w('토큰 갱신 후에도 액세스 토큰을 가져올 수 없습니다.');
              return null;
            }
          } catch (refreshError) {
            // Refresh token also expired or failed
            appLogger.e('토큰 갱신 실패. 리프레시 토큰이 만료되었거나 유효하지 않습니다.', error: refreshError);
            
            // Clear tokens since refresh failed
            await _tokenStorage.clearTokens();
            return null;
          }
        } else {
          // Other errors (network, server error, etc.)
          appLogger.e('사용자 정보 조회 실패', error: e);
          return null;
        }
      }
    } catch (e) {
      appLogger.e('사용자 정보 조회 중 예상치 못한 오류 발생', error: e);
      return null;
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      appLogger.i('로그아웃 요청');

      final accessToken = await _tokenStorage.getAccessToken();

      if (accessToken != null) {
        // Logout from backend (invalidates refresh token)
        await _repository.logout(accessToken);
      }

      // Clear stored tokens
      await _tokenStorage.clearTokens();

      // Sign out from Google
      await _googleOAuth.signOut();

      appLogger.i('로그아웃 완료');
    } catch (e) {
      appLogger.e('로그아웃 실패', error: e);
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
