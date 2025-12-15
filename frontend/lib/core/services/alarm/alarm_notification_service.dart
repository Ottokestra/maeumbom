import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../../../data/models/alarm/alarm_model.dart';

/// 알림 푸시 알림 서비스
/// flutter_local_notifications를 사용하여 로컬 푸시 알림 관리
class AlarmNotificationService {
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// 알림 탭 콜백 (외부에서 설정 가능)
  Function(int notificationId)? onNotificationTapped;

  /// 서비스 초기화
  Future<void> initialize() async {
    if (_initialized) return;

    // Android 설정
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS 설정 (포그라운드에서도 알림 표시)
    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification: (id, title, body, payload) async {
        // iOS 10 이하에서 포그라운드 알림 처리
        print(
            '[AlarmNotificationService] Foreground notification received: $id');
      },
    );

    final settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Timezone 초기화
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

    // Android 알림 채널 생성
    await createNotificationChannel();

    _initialized = true;
    print('[AlarmNotificationService] Service initialized successfully');
  }

  /// 알림 탭 핸들러
  void _onNotificationTapped(NotificationResponse response) {
    print('[AlarmNotificationService] Notification tapped: ${response.id}');

    // 외부 콜백 호출 (알림 화면으로 이동 등)
    onNotificationTapped?.call(response.id ?? 0);
  }

  /// 알림 예약
  Future<void> scheduleAlarm(AlarmModel alarm) async {
    if (!alarm.isValid || !alarm.isEnabled) {
      print(
          '[AlarmNotificationService] Alarm is not valid or disabled: ${alarm.id}');
      return;
    }

    try {
      final scheduledDate = tz.TZDateTime.from(
        alarm.scheduledDatetime,
        tz.getLocation('Asia/Seoul'),
      );

      // 과거 시간 체크
      final currentTime = tz.TZDateTime.now(tz.getLocation('Asia/Seoul'));
      if (scheduledDate.isBefore(currentTime)) {
        final timeDifference = currentTime.difference(scheduledDate);
        print('[AlarmNotificationService] ❌ Alarm time is in the PAST:\n'
            '  - ID: ${alarm.id}\n'
            '  - Current time: $currentTime\n'
            '  - Scheduled time: $scheduledDate\n'
            '  - PAST by: ${timeDifference.inMinutes} min ${timeDifference.inSeconds % 60} sec');
        return;
      }

      await _notifications.zonedSchedule(
        alarm.notificationId,
        alarm.title ?? '마음봄 알림',
        alarm.content ?? '알림 시간입니다.',
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'alarm_channel',
            '알림',
            channelDescription: '마음봄 알림 채널',
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
        androidScheduleMode:
            AndroidScheduleMode.exact, // 🔧 exact로 변경 (정확한 시간에 울리도록)
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      final timeDifference = scheduledDate.difference(currentTime);

      print('[AlarmNotificationService] ⏰ Alarm scheduled:\n'
          '  - ID: ${alarm.id}\n'
          '  - Current time: $currentTime\n'
          '  - Scheduled time: $scheduledDate\n'
          '  - Time until alarm: ${timeDifference.inMinutes} min ${timeDifference.inSeconds % 60} sec');
    } catch (e) {
      print('[AlarmNotificationService] Failed to schedule alarm: $e');
      rethrow;
    }
  }

  /// 알림 취소
  Future<void> cancelAlarm(int notificationId) async {
    try {
      await _notifications.cancel(notificationId);
      print('[AlarmNotificationService] Alarm cancelled: $notificationId');
    } catch (e) {
      print('[AlarmNotificationService] Failed to cancel alarm: $e');
      rethrow;
    }
  }

  /// 모든 알림 취소
  Future<void> cancelAllAlarms() async {
    try {
      await _notifications.cancelAll();
      print('[AlarmNotificationService] All alarms cancelled');
    } catch (e) {
      print('[AlarmNotificationService] Failed to cancel all alarms: $e');
      rethrow;
    }
  }

  /// 예약된 알림 목록 조회
  Future<List<PendingNotificationRequest>> getPendingAlarms() async {
    try {
      return await _notifications.pendingNotificationRequests();
    } catch (e) {
      print('[AlarmNotificationService] Failed to get pending alarms: $e');
      return [];
    }
  }

  /// 특정 알림이 예약되어 있는지 확인
  Future<bool> isAlarmScheduled(int notificationId) async {
    final pending = await getPendingAlarms();
    return pending.any((alarm) => alarm.id == notificationId);
  }

  /// 권한 요청 (iOS/Android)
  Future<bool?> requestPermissions() async {
    if (!_initialized) {
      await initialize();
    }

    // iOS 권한 요청
    final iosGranted = await _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    // Android 13+ 권한 요청
    final androidGranted = await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    return iosGranted ?? androidGranted ?? true;
  }

  /// 권한 상태 확인
  Future<bool> checkPermissions() async {
    if (!_initialized) {
      await initialize();
    }

    // iOS 권한 확인
    final iosPermissions = await _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.checkPermissions();

    if (iosPermissions != null) {
      return iosPermissions.isEnabled;
    }

    // Android는 기본적으로 허용 (Android 13 미만)
    // Android 13+는 requestPermissions에서 처리
    return true;
  }

  /// Android 12+ exact alarm 권한 확인
  Future<bool> canScheduleExactAlarms() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) {
      return true; // iOS or unsupported platform
    }

    try {
      return await androidPlugin.canScheduleExactNotifications() ?? false;
    } catch (e) {
      print(
          '[AlarmNotificationService] Failed to check exact alarm permission: $e');
      return false;
    }
  }

  /// Android 12+ exact alarm 권한 요청
  Future<bool> requestExactAlarmPermission() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) {
      return true; // iOS or unsupported platform
    }

    try {
      final canSchedule =
          await androidPlugin.canScheduleExactNotifications() ?? false;

      if (!canSchedule) {
        print(
            '[AlarmNotificationService] Requesting exact alarm permission...');
        return await androidPlugin.requestExactAlarmsPermission() ?? false;
      }

      return true;
    } catch (e) {
      print(
          '[AlarmNotificationService] Failed to request exact alarm permission: $e');
      return false;
    }
  }

  /// 알림 채널 생성 (Android)
  Future<void> createNotificationChannel() async {
    const androidChannel = AndroidNotificationChannel(
      'alarm_channel',
      '알림',
      description: '마음봄 알림 채널',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  /// 즉시 알림 표시 (테스트용)
  Future<void> showImmediateNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await _notifications.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'alarm_channel',
          '알림',
          channelDescription: '마음봄 알림 채널',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }
}
