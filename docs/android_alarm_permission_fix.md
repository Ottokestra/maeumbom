# Android 푸시 알람 권한 수정

Android에서 푸시 알람이 작동하지 않던 문제를 해결했습니다.

## 문제점

iOS에서는 알람이 정상 작동하지만 Android에서는 작동하지 않는 문제가 있었습니다.

**근본 원인**: 앱 초기화 시 권한 요청이 누락되어 있었습니다.
- ❌ `AlarmNotificationService.initialize()` 만 호출
- ❌ `AlarmNotificationService.requestPermissions()` 호출 안 됨
- ❌ Android 12+ exact alarm 권한 요청 안 됨

## 해결 방법

### 1. 알림 권한 요청 추가 (Android 13+)

[`main.dart`](file:///c:/dev/Workspace/code/bomproj/frontend/lib/main.dart#L40-L43)
```dart
// 🚨 권한 요청 (Android 13+ 필수!)
debugPrint('🔔 Requesting notification permissions...');
final permissionGranted = await alarmService.requestPermissions();
debugPrint('🔔 Notification permission granted: $permissionGranted');
```

### 2. Exact Alarm 권한 요청 추가 (Android 12+)

[`main.dart`](file:///c:/dev/Workspace/code/bomproj/frontend/lib/main.dart#L45-L52)
```dart
// 🚨 Android 12+ exact alarm 권한 요청
debugPrint('⏰ Requesting exact alarm permission...');
final exactAlarmGranted = await alarmService.requestExactAlarmPermission();
debugPrint('⏰ Exact alarm permission granted: $exactAlarmGranted');

if (!exactAlarmGranted) {
  debugPrint('⚠️ Exact alarm permission denied - alarms may not work precisely!');
}
```

### 3. Exact Alarm 권한 메서드 추가

[`alarm_notification_service.dart`](file:///c:/dev/Workspace/code/bomproj/frontend/lib/core/services/alarm/alarm_notification_service.dart#L206-L247)에 두 개의 새로운 메서드 추가:

- `canScheduleExactAlarms()`: Exact alarm 권한 확인
- `requestExactAlarmPermission()`: Exact alarm 권한 요청

## 수정된 파일

| 파일 | 변경사항 |
|------|----------|
| [`main.dart`](file:///c:/dev/Workspace/code/bomproj/frontend/lib/main.dart) | 권한 요청 2개 추가 (알림 + exact alarm) |
| [`alarm_notification_service.dart`](file:///c:/dev/Workspace/code/bomproj/frontend/lib/core/services/alarm/alarm_notification_service.dart) | Exact alarm 권한 메서드 2개 추가 |

## 테스트 방법

### 1. 앱 재설치 및 실행

```bash
cd c:\dev\Workspace\code\bomproj\frontend
flutter clean
flutter pub get
flutter run
```

### 2. 예상 동작

앱 시작 시 다음과 같은 권한 요청이 나타나야 합니다:

#### Android 13+ 기기
1. **알림 권한 팝업**: "마음봄이 알림을 보내도록 허용하시겠습니까?"
2. **Exact Alarm 권한 설정 화면**: 시스템 설정 페이지로 이동 → "알람 및 리마인더" 토글 활성화

#### Android 12 기기
1. **Exact Alarm 권한 설정 화면**만 표시 (알림 권한은 자동 승인)

#### Android 11 이하
- 권한 요청 없이 자동 승인

### 3. 로그 확인

앱 시작 시 다음 로그가 출력되어야 합니다:

```
🔔 Requesting notification permissions...
🔔 Notification permission granted: true
⏰ Requesting exact alarm permission...
⏰ Exact alarm permission granted: true
✅ AlarmNotificationService initialized
```

권한이 거부된 경우:
```
⚠️ Exact alarm permission denied - alarms may not work precisely!
```

## Android 권한 참고사항

| Android 버전 | 알림 권한 | Exact Alarm 권한 |
|-------------|---------|-----------------|
| 13+ (API 33+) | **런타임 요청 필수** | **설정 화면 필수** |
| 12, 12L (API 31-32) | 자동 승인 | **설정 화면 필수** |
| 11 이하 (API 30-) | 자동 승인 | 불필요 |

## iOS 동작

iOS는 변경사항 없이 기존대로 작동합니다:
- 앱 시작 시 자동으로 알림 권한 요청 팝업 표시
- Exact alarm 개념 없음 (로컬 알림이 항상 정확함)

## 다음 단계

1. ✅ **즉시 테스트**: Android 실기기나 에뮬레이터에서 앱 실행
2. ✅ **권한 확인**: 설정 → 앱 → 마음봄 → 권한에서 "알림", "알람 및 리마인더" 활성화 확인
3. ✅ **알람 생성**: AI에게 알람 요청 → 알람 화면에서 확인 → 예정 시간에 알림 수신 확인
