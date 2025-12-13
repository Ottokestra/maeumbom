import 'dart:io'; // Platform detection
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import '../../../data/models/alarm/alarm_model.dart';
import '../../../data/local/database/app_database.dart';

/// Android AlarmManager를 사용한 신뢰할 수 있는 알람 서비스
///
/// Hybrid 접근법:
/// - android_alarm_manager_plus: 정확한 시간에 callback 실행
/// - flutter_local_notifications: 알림 UI 표시
class AlarmManagerService {
  static final AlarmManagerService _instance = AlarmManagerService._internal();
  factory AlarmManagerService() => _instance;
  AlarmManagerService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// 서비스 초기화
  Future<void> initialize() async {
    if (_initialized) return;

    // AndroidAlarmManager 초기화 (Android 전용)
    if (Platform.isAndroid) {
      await AndroidAlarmManager.initialize();
    }

    // Timezone 초기화 (iOS zonedSchedule용)
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

    // Notifications 초기화
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _notifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    // Android 알림 채널 생성
    const channel = AndroidNotificationChannel(
      'alarm_channel',
      '알람',
      description: '마음봄 알람 채널',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    _initialized = true;
    print(
        '[AlarmManagerService] Initialized successfully (Platform: ${Platform.operatingSystem})');
  }

  /// 알림 권한 확인
  Future<bool> checkPermissions() async {
    if (Platform.isAndroid) {
      final androidImpl = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return await androidImpl?.areNotificationsEnabled() ?? false;
    } else if (Platform.isIOS) {
      final iosImpl = _notifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final settings = await iosImpl?.requestPermissions(
        alert: false, // 요청하지 않고 현재 상태만 확인
        badge: false,
        sound: false,
      );
      return settings ?? false;
    }
    return false;
  }

  /// 알림 권한 요청
  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final androidImpl = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return await androidImpl?.requestNotificationsPermission() ?? false;
    } else if (Platform.isIOS) {
      final iosImpl = _notifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      return await iosImpl?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    return false;
  }

  /// 알람 예약
  Future<void> scheduleAlarm(AlarmModel alarm) async {
    if (!alarm.isValid || !alarm.isEnabled) {
      print(
          '[AlarmManagerService] Alarm is not valid or disabled: ${alarm.id}');
      return;
    }

    final now = DateTime.now();
    final scheduledTime = alarm.scheduledDatetime;

    // 과거 시간 체크
    if (scheduledTime.isBefore(now)) {
      final diff = now.difference(scheduledTime);
      print('[AlarmManagerService] ❌ Alarm is in the PAST:\n'
          '  - Current: $now\n'
          '  - Scheduled: $scheduledTime\n'
          '  - PAST by: ${diff.inMinutes}m ${diff.inSeconds % 60}s');
      return;
    }

    try {
      if (Platform.isAndroid) {
        // ⭐ Android: AlarmManager로 정확한 시간에 callback 실행
        await AndroidAlarmManager.oneShotAt(
          scheduledTime,
          alarm.notificationId,
          _alarmCallback,
          exact: true,
          wakeup: true,
          rescheduleOnReboot: true,
          params: {
            'id': alarm.notificationId,
            'title': alarm.title ?? '마음봄 알람',
            'body': alarm.content ?? '알람 시간입니다.',
          },
        );
      } else {
        // ⭐ iOS: flutter_local_notifications의 zonedSchedule 사용
        final scheduledDate = tz.TZDateTime.from(
          scheduledTime,
          tz.getLocation('Asia/Seoul'),
        );

        await _notifications.zonedSchedule(
          alarm.notificationId,
          alarm.title ?? '마음봄 알람',
          alarm.content ?? '알람 시간입니다.',
          scheduledDate,
          const NotificationDetails(
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }

      final diff = scheduledTime.difference(now);
      print(
          '[AlarmManagerService] ⏰ Alarm scheduled (${Platform.operatingSystem}):\n'
          '  - ID: ${alarm.notificationId}\n'
          '  - Current: $now\n'
          '  - Scheduled: $scheduledTime\n'
          '  - Time until: ${diff.inMinutes}m ${diff.inSeconds % 60}s');
    } catch (e) {
      print('[AlarmManagerService] Failed to schedule alarm: $e');
      rethrow;
    }
  }

  /// 알람 취소
  Future<void> cancelAlarm(int notificationId) async {
    try {
      await AndroidAlarmManager.cancel(notificationId);
      print('[AlarmManagerService] Alarm cancelled: $notificationId');
    } catch (e) {
      print('[AlarmManagerService] Failed to cancel alarm: $e');
      rethrow;
    }
  }

  /// 모든 알람 복구 (재부팅 후)
  static Future<void> rescheduleAllAlarms() async {
    try {
      print('[AlarmManagerService] Rescheduling all alarms after reboot...');

      final db = AppDatabase();
      final alarmDataList = await db.getEnabledAlarms();

      final service = AlarmManagerService();
      await service.initialize();

      for (final alarmData in alarmDataList) {
        // AlarmData → AlarmModel 변환
        final alarm = AlarmModel.fromDrift(alarmData);
        await service.scheduleAlarm(alarm);
      }

      print('[AlarmManagerService] ${alarmDataList.length} alarms rescheduled');
    } catch (e) {
      print('[AlarmManagerService] Failed to reschedule alarms: $e');
    }
  }
}

/// ⭐ AlarmCallback: 정확한 시간에 실행되는 함수
///
/// CRITICAL: 이 함수는 top-level 함수여야 하며, isolate에서 실행됩니다.
/// UI에 직접 접근할 수 없으니 flutter_local_notifications로 알림을 표시합니다.
@pragma('vm:entry-point')
Future<void> _alarmCallback(int id, Map<String, dynamic> params) async {
  print('[AlarmCallback] ⏰ Alarm triggered! ID: $id');

  try {
    // Notifications 플러그인 초기화
    final notifications = FlutterLocalNotificationsPlugin();

    // 알림 표시
    await notifications.show(
      id,
      params['title'] as String? ?? '마음봄 알람',
      params['body'] as String? ?? '알람 시간입니다.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'alarm_channel',
          '알람',
          channelDescription: '마음봄 알람 채널',
          importance: Importance.max,
          priority: Priority.high,
          enableVibration: true,
          playSound: true,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );

    print('[AlarmCallback] ✅ Notification shown');
  } catch (e) {
    print('[AlarmCallback] ❌ Failed to show notification: $e');
  }
}
