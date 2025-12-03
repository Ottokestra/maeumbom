import 'package:google_sign_in/google_sign_in.dart';
import '../config/oauth_config.dart';
import '../utils/logger.dart';

/// Google OAuth Service - Handles Google Sign-In flow
class GoogleOAuthService {
  late final GoogleSignIn _googleSignIn;

  GoogleOAuthService() {
    _googleSignIn = GoogleSignIn(
      clientId: OAuthConfig.googleClientId,
      scopes: OAuthConfig.googleScopes,
      // Important: For server-side auth code
      serverClientId: OAuthConfig.googleClientId,
    );
  }

  /// Sign in with Google and get authorization code
  Future<String> signIn() async {
    try {
      // Sign in
      final account = await _googleSignIn.signIn();

      if (account == null) {
        throw Exception('Google Sign-In was cancelled');
      }

      // Get authentication
      final auth = await account.authentication;

      // For server-side flow, we need the serverAuthCode
      final serverAuthCode = auth.serverAuthCode;

      if (serverAuthCode == null) {
        throw Exception('Failed to get authorization code from Google');
      }

      appLogger.i('Google Sign-In successful: ${account.email}');
      return serverAuthCode;
    } catch (e) {
      appLogger.e('Google Sign-In failed', error: e);
      rethrow;
    }
  }

  /// Sign out from Google
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      appLogger.i('Google Sign-Out successful');
    } catch (e) {
      appLogger.e('Google Sign-Out failed', error: e);
      // Don't rethrow - sign out errors are not critical
    }
  }

  /// Disconnect Google account
  Future<void> disconnect() async {
    try {
      await _googleSignIn.disconnect();
      appLogger.i('Google disconnect successful');
    } catch (e) {
      appLogger.e('Google disconnect failed', error: e);
      // Don't rethrow - disconnect errors are not critical
    }
  }

  /// Check if currently signed in
  Future<bool> isSignedIn() async {
    return await _googleSignIn.isSignedIn();
  }
}
