import 'package:permission_handler/permission_handler.dart';
import '../../utils/logger.dart';

/// Permission Service - Handles microphone permissions
class PermissionService {
  /// Request microphone permission
  /// Returns: (isGranted, isPermanentlyDenied)
  Future<(bool, bool)> requestMicrophonePermission() async {
    try {
      final status = await Permission.microphone.request();

      if (status.isGranted) {
        appLogger.i('Microphone permission granted');
        return (true, false);
      } else if (status.isDenied) {
        appLogger.w('Microphone permission denied');
        return (false, false);
      } else if (status.isPermanentlyDenied) {
        appLogger.w('Microphone permission permanently denied');
        return (false, true);
      }

      return (false, false);
    } catch (e) {
      appLogger.e('Failed to request microphone permission', error: e);
      return (false, false);
    }
  }

  /// Check if microphone permission is granted
  Future<bool> hasMicrophonePermission() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }

  /// Check if microphone permission is permanently denied
  Future<bool> isPermanentlyDenied() async {
    final status = await Permission.microphone.status;
    return status.isPermanentlyDenied;
  }

  /// Check if microphone permission was never requested (first time)
  /// Returns true if permission is denied but not permanently denied
  Future<bool> isNeverRequested() async {
    final status = await Permission.microphone.status;
    // 권한이 없고 영구적으로 거부되지 않은 경우 (처음 요청 또는 한 번 거부)
    return !status.isGranted && !status.isPermanentlyDenied;
  }

  /// Open app settings
  Future<void> openSettings() async {
    await openAppSettings();
  }
}
