import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import '../../utils/logger.dart';

/// Kakao OAuth Service - Handles Kakao Sign-In flow using Native SDK
class KakaoOAuthService {
  /// Sign in with Kakao and get authorization code
  /// 주의: 실제 토큰 확인은 AuthService에서 수행되므로, 여기서는 로그인 다이얼로그만 표시합니다.
  /// AuthService의 loginWithKakao()에서 먼저 저장된 토큰을 확인하므로,
  /// 이 메서드가 호출되는 경우는 토큰이 없거나 만료된 경우입니다.
  Future<String> signIn() async {
    try {
      appLogger.i('카카오 로그인 요청');

      // 저장된 토큰이 없거나 유효하지 않은 경우 로그인 다이얼로그 표시
      // 카카오톡 설치 여부 확인
      final isTalkInstalled = await isKakaoTalkInstalled();

      OAuthToken token;

      if (isTalkInstalled) {
        // 카카오톡으로 로그인
        try {
          token = await UserApi.instance.loginWithKakaoTalk();
        } catch (e) {
          // 사용자가 카카오톡 로그인을 취소한 경우
          if (e.toString().contains('CANCELED')) {
            throw Exception('로그인이 취소되었습니다.');
          }

          // 카카오톡 로그인 실패 시 웹 로그인으로 대체
          token = await UserApi.instance.loginWithKakaoAccount();
        }
      } else {
        // 카카오 계정으로 로그인 (웹뷰)
        token = await UserApi.instance.loginWithKakaoAccount();
      }

      // Access Token을 Authorization Code로 교환하기 위해
      // 백엔드 API를 호출할 때 사용할 수 있도록 반환
      // 참고: 카카오 SDK는 직접 토큰을 제공하므로,
      // 백엔드에서 이 토큰을 검증하고 사용자 정보를 가져와야 함

      appLogger.i('카카오 로그인 완료');
      return token.accessToken;
    } catch (e) {
      // 상세한 에러 분류 및 처리
      final errorMessage = e.toString().toLowerCase();

      if (errorMessage.contains('canceled') || errorMessage.contains('취소')) {
        throw Exception('로그인이 취소되었습니다.');
      } else if (errorMessage.contains('network') ||
          errorMessage.contains('connection')) {
        throw Exception('네트워크 연결을 확인하고 다시 시도해주세요.');
      } else {
        appLogger.e('카카오 로그인 실패', error: e);
        throw Exception('카카오 로그인에 실패했습니다: ${e.toString()}');
      }
    }
  }
}
