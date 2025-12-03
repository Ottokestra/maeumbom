import 'dart:math';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import '../config/oauth_config.dart';
import '../utils/logger.dart';

/// Naver OAuth Service - Handles Naver Sign-In flow
class NaverOAuthService {
  String? _currentState;

  /// Generate random state for CSRF protection
  String _generateState() {
    final random = Random.secure();
    final values = List<int>.generate(16, (i) => random.nextInt(256));
    return values.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Sign in with Naver and get authorization code + state
  Future<(String code, String state)> signIn() async {
    try {
      // Generate state for CSRF protection
      _currentState = _generateState();

      // Naver OAuth URL (백엔드 callback URL 사용)
      final authUrl = 'https://nid.naver.com/oauth2.0/authorize?'
          'client_id=${Uri.encodeComponent(OAuthConfig.naverClientId)}&'
          'redirect_uri=${Uri.encodeComponent(OAuthConfig.naverRedirectUri)}&'
          'response_type=code&'
          'state=${Uri.encodeComponent(_currentState!)}';

      // Open WebView for OAuth
      // 백엔드에서 com.maeumbom.app://auth/callback 으로 리다이렉트됨
      final result = await FlutterWebAuth2.authenticate(
        url: authUrl,
        callbackUrlScheme: OAuthConfig.appScheme,
      );

      // Extract authorization code and state from callback URL
      final uri = Uri.parse(result);
      final code = uri.queryParameters['code'];
      final state = uri.queryParameters['state'];

      if (code == null || state == null) {
        throw Exception('Failed to get authorization code from Naver');
      }

      // Verify state (CSRF protection)
      if (state != _currentState) {
        throw Exception('State mismatch - potential CSRF attack');
      }

      appLogger.i('Naver Sign-In successful');
      return (code, state);
    } catch (e) {
      // 사용자 취소는 정상 동작 - 에러 로그만 남기고 조용히 실패
      if (e.toString().contains('CANCELED') || e.toString().contains('User canceled')) {
        appLogger.i('Naver Sign-In canceled by user');
      } else {
        appLogger.e('Naver Sign-In failed', error: e);
      }
      rethrow;
    }
  }
}
