import 'dart:math';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import '../../config/oauth_config.dart';
import '../../utils/logger.dart';

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

      appLogger.i('Starting Naver OAuth with URL: $authUrl');

      // Open WebView for OAuth with enhanced configuration
      // 백엔드에서 com.maeumbom.app://auth/callback 으로 리다이렉트됨
      final result = await FlutterWebAuth2.authenticate(
        url: authUrl,
        callbackUrlScheme: OAuthConfig.appScheme,
        options: const FlutterWebAuth2Options(
          timeout: 120, // 2분 타임아웃
          preferEphemeral: true, // 세션 격리
        ),
      );

      appLogger.i('OAuth callback received: $result');

      // Extract authorization code and state from callback URL
      final uri = Uri.parse(result);
      final code = uri.queryParameters['code'];
      final state = uri.queryParameters['state'];
      final error = uri.queryParameters['error'];

      // 에러 체크
      if (error != null) {
        appLogger.e('OAuth error received: $error');
        throw Exception('OAuth error: $error');
      }

      if (code == null || state == null) {
        appLogger.e('Missing code or state in callback. Code: $code, State: $state');
        throw Exception('Failed to get authorization code from Naver - missing parameters');
      }

      // Verify state (CSRF protection)
      if (state != _currentState) {
        appLogger.e('State mismatch. Expected: $_currentState, Received: $state');
        throw Exception('State mismatch - potential CSRF attack');
      }

      appLogger.i('Naver Sign-In successful - code and state verified');
      return (code, state);
    } catch (e) {
      // 상세한 에러 분류 및 처리
      final errorMessage = e.toString().toLowerCase();
      
      if (errorMessage.contains('canceled') || errorMessage.contains('user canceled')) {
        appLogger.i('Naver Sign-In canceled by user');
        throw Exception('로그인이 취소되었습니다.');
      } else if (errorMessage.contains('timeout')) {
        appLogger.w('Naver Sign-In timeout');
        throw Exception('로그인 시간이 초과되었습니다. 다시 시도해주세요.');
      } else if (errorMessage.contains('network') || errorMessage.contains('connection')) {
        appLogger.w('Naver Sign-In network error');
        throw Exception('네트워크 연결을 확인하고 다시 시도해주세요.');
      } else {
        appLogger.e('Naver Sign-In failed', error: e);
        throw Exception('네이버 로그인에 실패했습니다: ${e.toString()}');
      }
    }
  }
}
