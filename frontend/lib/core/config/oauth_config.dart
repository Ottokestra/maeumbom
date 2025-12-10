import 'dart:io';
import 'api_config.dart';

/// OAuth Configuration - Client IDs and redirect URIs
class OAuthConfig {
  // Google OAuth
  // Android 앱용 클라이언트 ID
  static const String googleAndroidClientId =
      '758124085502-l3be3r79df8ti4i8pqu223v1laufef4t.apps.googleusercontent.com';
  
  // iOS 앱용 클라이언트 ID
  static const String googleIosClientId =
      '758124085502-umcpgll7m378fgtdkq25s66srdk99sui.apps.googleusercontent.com';
  
  // 플랫폼별 클라이언트 ID (자동 선택)
  static String get googleClientId {
    if (Platform.isIOS) {
      return googleIosClientId;
    }
    return googleAndroidClientId;
  }
  
  // 백엔드용 클라이언트 ID (서버 측 인증 코드 교환용)
  // 백엔드의 GOOGLE_CLIENT_ID와 동일해야 함
  // Google Cloud Console에서 "웹 애플리케이션" 타입으로 생성된 클라이언트 ID 사용
  static const String googleServerClientId =
      '758124085502-7so94snakhcj5bj5o1242o6ktg48eqqj.apps.googleusercontent.com';

  // Kakao OAuth
  static const String kakaoClientId =
      '40b5bd386c4fe10fbf08723bf52a4487'; // REST API 키
  static const String kakaoNativeAppKey =
      '3dc461684b25108e0f01609418154d4e'; // 네이티브 앱 키

  // Naver OAuth
  static const String naverClientId = 'Y4gXSib6V678m2gYoa9C';

  // HTTP Redirect URIs (백엔드에서 앱 스킴으로 리다이렉트)
  // ApiConfig.baseUrl을 사용하여 플랫폼별로 자동으로 적절한 주소 사용
  // - 에뮬레이터: http://10.0.2.2:8000/auth/callback/...
  // - 실제 디바이스: http://localhost:8000/auth/callback/... (또는 환경 변수로 설정한 IP)
  static String get googleRedirectUri {
    return '${ApiConfig.baseUrl}/auth/callback/google';
  }

  static String get kakaoRedirectUri {
    return '${ApiConfig.baseUrl}/auth/callback/kakao';
  }

  static String get naverRedirectUri {
    return '${ApiConfig.baseUrl}/auth/callback/naver';
  }

  // App Scheme (앱이 받을 deep link)
  static const String appScheme = 'com.maeumbom.app';

  // Scopes
  static const List<String> googleScopes = [
    'email',
    'profile',
  ];
}
