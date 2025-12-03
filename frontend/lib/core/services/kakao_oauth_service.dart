import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import '../config/oauth_config.dart';
import '../utils/logger.dart';

/// Kakao OAuth Service - Handles Kakao Sign-In flow
class KakaoOAuthService {
  /// Sign in with Kakao and get authorization code
  Future<String> signIn() async {
    try {
      // Kakao OAuth URL (백엔드 callback URL 사용)
      final authUrl = 'https://kauth.kakao.com/oauth/authorize?'
          'client_id=${Uri.encodeComponent(OAuthConfig.kakaoClientId)}&'
          'redirect_uri=${Uri.encodeComponent(OAuthConfig.kakaoRedirectUri)}&'
          'response_type=code';

      // Open WebView for OAuth
      // 백엔드에서 com.maeumbom.app://auth/callback 으로 리다이렉트됨
      final result = await FlutterWebAuth2.authenticate(
        url: authUrl,
        callbackUrlScheme: OAuthConfig.appScheme,
      );

      // Extract authorization code from callback URL
      final uri = Uri.parse(result);
      final code = uri.queryParameters['code'];

      if (code == null) {
        throw Exception('Failed to get authorization code from Kakao');
      }

      appLogger.i('Kakao Sign-In successful');
      return code;
    } catch (e) {
      // 사용자 취소는 정상 동작 - 에러 로그만 남기고 조용히 실패
      if (e.toString().contains('CANCELED') || e.toString().contains('User canceled')) {
        appLogger.i('Kakao Sign-In canceled by user');
      } else {
        appLogger.e('Kakao Sign-In failed', error: e);
      }
      rethrow;
    }
  }
}
