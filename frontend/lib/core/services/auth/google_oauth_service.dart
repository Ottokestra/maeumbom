import 'package:google_sign_in/google_sign_in.dart';
import '../../config/oauth_config.dart';
import '../../utils/logger.dart';

/// Google OAuth Service - Handles Google Sign-In flow
class GoogleOAuthService {
  late final GoogleSignIn _googleSignIn;

  GoogleOAuthService() {
    appLogger.d('GoogleOAuthService 초기화 시작');
    appLogger.d('Android 클라이언트 ID: ${OAuthConfig.googleClientId}');
    appLogger.d('웹 클라이언트 ID (serverClientId): ${OAuthConfig.googleServerClientId}');
    appLogger.d('Scopes: ${OAuthConfig.googleScopes}');
    
    _googleSignIn = GoogleSignIn(
      clientId: OAuthConfig.googleClientId,
      scopes: OAuthConfig.googleScopes,
      // Important: For server-side auth code
      // 백엔드용 클라이언트 ID 사용 (서버 측 인증 코드 교환용)
      serverClientId: OAuthConfig.googleServerClientId,
      // Force serverAuthCode generation even if user is already signed in
      // 이미 로그인된 상태에서도 serverAuthCode를 강제로 생성하도록 함
      forceCodeForRefreshToken: true,
    );
    
    appLogger.d('GoogleOAuthService 초기화 완료');
  }

  /// Sign in with Google and get ID Token
  /// Returns ID Token for backend verification (fallback to serverAuthCode if available)
  Future<String> signIn() async {
    try {
      appLogger.i('구글 로그인 요청');
      appLogger.d('사용 중인 클라이언트 ID: ${OAuthConfig.googleClientId}');
      appLogger.d('사용 중인 서버 클라이언트 ID: ${OAuthConfig.googleServerClientId}');

      // Sign in
      appLogger.d('Google Sign-In SDK 호출 시작');
      final account = await _googleSignIn.signIn();
      appLogger.d('Google Sign-In SDK 응답 수신');

      if (account == null) {
        appLogger.w('Google Sign-In이 취소되었습니다');
        throw Exception('Google Sign-In was cancelled');
      }

      appLogger.d('Google 계정 정보:');
      appLogger.d('  - Email: ${account.email}');
      appLogger.d('  - Display Name: ${account.displayName}');
      appLogger.d('  - ID: ${account.id}');
      appLogger.d('  - Photo URL: ${account.photoUrl}');

      // Get authentication
      appLogger.d('인증 정보 가져오기 시작');
      final auth = await account.authentication;
      appLogger.d('인증 정보 수신 완료');
      appLogger.d('  - Access Token: ${auth.accessToken != null ? "${auth.accessToken!.substring(0, 20)}..." : "null"}');
      appLogger.d('  - ID Token: ${auth.idToken != null ? "${auth.idToken!.substring(0, 20)}..." : "null"}');
      appLogger.d('  - Server Auth Code: ${auth.serverAuthCode != null ? "${auth.serverAuthCode!.substring(0, 20)}..." : "null"}');

      // Prefer ID Token for backend verification (more reliable than serverAuthCode)
      // ID Token contains user information and can be verified directly by backend
      final idToken = auth.idToken;
      final serverAuthCode = auth.serverAuthCode;

      if (idToken != null) {
        appLogger.i('구글 로그인 완료: ${account.email}');
        appLogger.d('ID Token 사용 (길이: ${idToken.length})');
        if (serverAuthCode != null) {
          appLogger.d('Server Auth Code도 사용 가능하지만 ID Token을 우선 사용합니다');
        }
        return idToken;
      } else if (serverAuthCode != null) {
        // Fallback to serverAuthCode if ID Token is not available
        appLogger.i('구글 로그인 완료: ${account.email}');
        appLogger.d('ID Token이 없어 Server Auth Code 사용 (길이: ${serverAuthCode.length})');
        return serverAuthCode;
      } else {
        appLogger.e('ID Token과 Server Auth Code 모두 null입니다');
        appLogger.e('  - Access Token 존재: ${auth.accessToken != null}');
        appLogger.e('  - ID Token 존재: ${auth.idToken != null}');
        appLogger.e('  - Server Auth Code 존재: ${auth.serverAuthCode != null}');
        appLogger.e('  - Server Client ID 설정 확인 필요: ${OAuthConfig.googleServerClientId}');
        appLogger.e('  - Android Client ID: ${OAuthConfig.googleClientId}');
        throw Exception('Failed to get ID Token or authorization code from Google');
      }
    } catch (e) {
      appLogger.e('구글 로그인 실패', error: e);
      appLogger.e('에러 타입: ${e.runtimeType}');
      if (e is Exception) {
        appLogger.e('에러 메시지: ${e.toString()}');
      }
      rethrow;
    }
  }

  /// Sign out from Google
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      appLogger.e('구글 로그아웃 실패', error: e);
      // Don't rethrow - sign out errors are not critical
    }
  }

  /// Disconnect Google account
  Future<void> disconnect() async {
    try {
      await _googleSignIn.disconnect();
    } catch (e) {
      appLogger.e('구글 연결 해제 실패', error: e);
      // Don't rethrow - disconnect errors are not critical
    }
  }

  /// Check if currently signed in
  Future<bool> isSignedIn() async {
    return await _googleSignIn.isSignedIn();
  }
}
