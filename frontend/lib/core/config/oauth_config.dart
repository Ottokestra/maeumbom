/// OAuth Configuration - Client IDs and redirect URIs
class OAuthConfig {
  // Google OAuth
  static const String googleClientId =
      '758124085502-7so94snakhcj5bj5o1242o6ktg48eqqj.apps.googleusercontent.com';

  // Kakao OAuth
  static const String kakaoClientId = '40b5bd386c4fe10fbf08723bf52a4487';

  // Naver OAuth
  static const String naverClientId = 'Y4gXSib6V678m2gYoa9C';

  // HTTP Redirect URIs (백엔드에서 앱 스킴으로 리다이렉트)
  static const String googleRedirectUri = 'http://localhost:8000/auth/callback/google';
  static const String kakaoRedirectUri = 'http://localhost:8000/auth/callback/kakao';
  static const String naverRedirectUri = 'http://localhost:8000/auth/callback/naver';

  // App Scheme (앱이 받을 deep link)
  static const String appScheme = 'com.maeumbom.app';

  // Scopes
  static const List<String> googleScopes = [
    'email',
    'profile',
  ];
}
