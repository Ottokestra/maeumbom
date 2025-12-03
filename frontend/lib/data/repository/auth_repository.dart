import '../api/auth_api_client.dart';
import '../dtos/google_login_request.dart';
import '../dtos/kakao_login_request.dart';
import '../dtos/naver_login_request.dart';
import '../models/user.dart';
import '../models/token_pair.dart';

/// Auth Repository - Abstracts data sources
class AuthRepository {
  final AuthApiClient _apiClient;

  AuthRepository(this._apiClient);

  /// Login with Google and return tokens + user
  Future<(TokenPair, User)> loginWithGoogle({
    required String authCode,
    required String redirectUri,
  }) async {
    final request = GoogleLoginRequest(
      authCode: authCode,
      redirectUri: redirectUri,
    );

    final tokenResponse = await _apiClient.googleLogin(request);

    final tokenPair = TokenPair(
      accessToken: tokenResponse.accessToken,
      refreshToken: tokenResponse.refreshToken,
    );

    // Fetch user profile with the new access token
    final userResponse = await _apiClient.getCurrentUser(
      tokenResponse.accessToken,
    );

    final user = User(
      id: userResponse.id,
      email: userResponse.email,
      nickname: userResponse.nickname,
      provider: userResponse.provider,
      createdAt: userResponse.createdAt,
    );

    return (tokenPair, user);
  }

  /// Login with Kakao and return tokens + user
  Future<(TokenPair, User)> loginWithKakao({
    required String authCode,
    required String redirectUri,
  }) async {
    final request = KakaoLoginRequest(
      authCode: authCode,
      redirectUri: redirectUri,
    );

    final tokenResponse = await _apiClient.kakaoLogin(request);

    final tokenPair = TokenPair(
      accessToken: tokenResponse.accessToken,
      refreshToken: tokenResponse.refreshToken,
    );

    // Fetch user profile with the new access token
    final userResponse = await _apiClient.getCurrentUser(
      tokenResponse.accessToken,
    );

    final user = User(
      id: userResponse.id,
      email: userResponse.email,
      nickname: userResponse.nickname,
      provider: userResponse.provider,
      createdAt: userResponse.createdAt,
    );

    return (tokenPair, user);
  }

  /// Login with Naver and return tokens + user
  Future<(TokenPair, User)> loginWithNaver({
    required String authCode,
    required String redirectUri,
    required String state,
  }) async {
    final request = NaverLoginRequest(
      authCode: authCode,
      redirectUri: redirectUri,
      state: state,
    );

    final tokenResponse = await _apiClient.naverLogin(request);

    final tokenPair = TokenPair(
      accessToken: tokenResponse.accessToken,
      refreshToken: tokenResponse.refreshToken,
    );

    // Fetch user profile with the new access token
    final userResponse = await _apiClient.getCurrentUser(
      tokenResponse.accessToken,
    );

    final user = User(
      id: userResponse.id,
      email: userResponse.email,
      nickname: userResponse.nickname,
      provider: userResponse.provider,
      createdAt: userResponse.createdAt,
    );

    return (tokenPair, user);
  }

  /// Refresh access token
  Future<TokenPair> refreshAccessToken(String refreshToken) async {
    final tokenResponse = await _apiClient.refreshToken(refreshToken);

    return TokenPair(
      accessToken: tokenResponse.accessToken,
      refreshToken: tokenResponse.refreshToken,
    );
  }

  /// Get current user profile
  Future<User> getCurrentUser(String accessToken) async {
    final userResponse = await _apiClient.getCurrentUser(accessToken);

    return User(
      id: userResponse.id,
      email: userResponse.email,
      nickname: userResponse.nickname,
      provider: userResponse.provider,
      createdAt: userResponse.createdAt,
    );
  }

  /// Logout
  Future<void> logout(String accessToken) async {
    await _apiClient.logout(accessToken);
  }
}
