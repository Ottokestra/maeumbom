import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../data/models/auth/token_pair.dart';
import '../../utils/logger.dart';

/// Secure Token Storage Service - Encrypted storage for tokens
class TokenStorageService {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  final FlutterSecureStorage _storage;

  TokenStorageService(this._storage);

  /// Save token pair
  Future<void> saveTokens(TokenPair tokens) async {
    try {
      await Future.wait([
        _storage.write(key: _accessTokenKey, value: tokens.accessToken),
        _storage.write(key: _refreshTokenKey, value: tokens.refreshToken),
      ]);
    } catch (e) {
      appLogger.e('토큰 저장 실패', error: e);
      rethrow;
    }
  }

  /// Get access token
  Future<String?> getAccessToken() async {
    try {
      return await _storage.read(key: _accessTokenKey);
    } catch (e) {
      appLogger.e('액세스 토큰 조회 실패', error: e);
      return null;
    }
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: _refreshTokenKey);
    } catch (e) {
      appLogger.e('리프레시 토큰 조회 실패', error: e);
      return null;
    }
  }

  /// Get both tokens
  Future<TokenPair?> getTokens() async {
    try {
      final accessToken = await getAccessToken();
      final refreshToken = await getRefreshToken();

      if (accessToken != null && refreshToken != null) {
        return TokenPair(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
      }
      return null;
    } catch (e) {
      appLogger.e('토큰 조회 실패', error: e);
      return null;
    }
  }

  /// Clear all tokens (logout)
  Future<void> clearTokens() async {
    try {
      await Future.wait([
        _storage.delete(key: _accessTokenKey),
        _storage.delete(key: _refreshTokenKey),
      ]);
    } catch (e) {
      appLogger.e('토큰 삭제 실패', error: e);
      rethrow;
    }
  }

  /// Check if user is logged in (has tokens)
  Future<bool> hasTokens() async {
    final tokens = await getTokens();
    return tokens != null;
  }
}
