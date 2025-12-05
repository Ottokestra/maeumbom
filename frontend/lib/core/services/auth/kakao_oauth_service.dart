import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import '../../config/oauth_config.dart';
import '../../utils/logger.dart';

/// Kakao OAuth Service - Handles Kakao Sign-In flow using Native SDK
class KakaoOAuthService {
  /// Sign in with Kakao and get authorization code
  Future<String> signIn() async {
    try {
      appLogger.i('Starting Kakao login flow...');
      
      // 카카오톡 설치 여부 확인
      final isTalkInstalled = await isKakaoTalkInstalled();
      
      OAuthToken token;
      
      if (isTalkInstalled) {
        // 카카오톡으로 로그인
        appLogger.i('Kakao Talk app detected, using Kakao Talk login');
        try {
          token = await UserApi.instance.loginWithKakaoTalk();
          appLogger.i('Kakao Talk login successful');
        } catch (e) {
          appLogger.w('Kakao Talk login failed, falling back to web login: $e');
          
          // 사용자가 카카오톡 로그인을 취소한 경우
          if (e.toString().contains('CANCELED')) {
            appLogger.i('Kakao login canceled by user');
            throw Exception('로그인이 취소되었습니다.');
          }
          
          // 카카오톡 로그인 실패 시 웹 로그인으로 대체
          token = await UserApi.instance.loginWithKakaoAccount();
          appLogger.i('Kakao web login successful');
        }
      } else {
        // 카카오 계정으로 로그인 (웹뷰)
        appLogger.i('Kakao Talk not installed, using web login');
        token = await UserApi.instance.loginWithKakaoAccount();
        appLogger.i('Kakao web login successful');
      }
      
      // Access Token을 Authorization Code로 교환하기 위해
      // 백엔드 API를 호출할 때 사용할 수 있도록 반환
      // 참고: 카카오 SDK는 직접 토큰을 제공하므로, 
      // 백엔드에서 이 토큰을 검증하고 사용자 정보를 가져와야 함
      
      appLogger.i('Kakao login completed, access token obtained');
      return token.accessToken;
      
    } catch (e) {
      // 상세한 에러 분류 및 처리
      final errorMessage = e.toString().toLowerCase();
      
      if (errorMessage.contains('canceled') || errorMessage.contains('취소')) {
        appLogger.i('Kakao login canceled by user');
        throw Exception('로그인이 취소되었습니다.');
      } else if (errorMessage.contains('network') || errorMessage.contains('connection')) {
        appLogger.w('Kakao login network error');
        throw Exception('네트워크 연결을 확인하고 다시 시도해주세요.');
      } else {
        appLogger.e('Kakao login failed', error: e);
        throw Exception('카카오 로그인에 실패했습니다: ${e.toString()}');
      }
    }
  }
}
