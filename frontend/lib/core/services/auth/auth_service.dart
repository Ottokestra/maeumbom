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
      appLogger.i('Starting Google login flow...');

      // Step 1: Get authorization code from Google
      final authCode = await _googleOAuth.signIn();

      // Step 2: Exchange auth code for tokens via backend
      final (tokens, user) = await _repository.loginWithGoogle(
        authCode: authCode,
        redirectUri: OAuthConfig.googleRedirectUri,
      );

      // Step 3: Store tokens securely
      await _tokenStorage.saveTokens(tokens);

      appLogger.i('Google login completed: ${user.email}');
      return user;
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

      // Step 1: Get authorization code from Kakao
      final authCode = await _kakaoOAuth!.signIn();

      // Step 2: Exchange auth code for tokens via backend
      final (tokens, user) = await _repository.loginWithKakao(
        authCode: authCode,
        redirectUri: OAuthConfig.kakaoRedirectUri,
      );

      // Step 3: Store tokens securely
      await _tokenStorage.saveTokens(tokens);

      appLogger.i('Kakao login completed: ${user.email}');
      return user;
    } catch (e) {
      appLogger.e('Kakao login failed', error: e);
      rethrow;
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

      // Step 2: Exchange auth code for tokens via backend
      final (tokens, user) = await _repository.loginWithNaver(
        authCode: authCode,
        redirectUri: OAuthConfig.naverRedirectUri,
        state: state,
      );

      // Step 3: Store tokens securely
      await _tokenStorage.saveTokens(tokens);

      appLogger.i('Naver login completed: ${user.email}');
      return user;
    } catch (e) {
      appLogger.e('Naver login failed', error: e);
      rethrow;
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
