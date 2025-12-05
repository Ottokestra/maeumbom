import 'dart:io';

/// OAuth Configuration - Client IDs and redirect URIs
class OAuthConfig {
  // Google OAuth
// Google OAuth
  static const String googleClientId =
      '758124085502-7so94snakhcj5bj5o1242o6ktg48eqqj.apps.googleusercontent.com';

  // Kakao OAuth
  static const String kakaoClientId =
      '40b5bd386c4fe10fbf08723bf52a4487'; // REST API 키
  static const String kakaoNativeAppKey =
      '40b5bd386c4fe10fbf08723bf52a4487'; // 네이티브 앱 키 (동일)

  // Naver OAuth
  static const String naverClientId = 'Y4gXSib6V678m2gYoa9C';

  // HTTP Redirect URIs (백엔드에서 앱 스킴으로 리다이렉트)
  // Google/Kakao: 플랫폼별로 다른 URL 사용 가능
  static String get googleRedirectUri {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000/auth/callback/google';
    }
    return 'http://localhost:8000/auth/callback/google';
  }

  static String get kakaoRedirectUri {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000/auth/callback/kakao';
    }
    return 'http://localhost:8000/auth/callback/kakao';
  }

  static String get naverRedirectUri {
    return 'http://localhost:8000/auth/callback/naver';
  }

  // App Scheme (앱이 받을 deep link)
  static const String appScheme = 'com.maeumbom.app';

  // Scopes
  static const List<String> googleScopes = [
    'email',
    'profile',
  ];
}
