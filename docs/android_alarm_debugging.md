# Android 푸시 알람이 안 뜨는 문제 디버깅 가이드

권한은 승인되었지만 알람이 울리지 않는 경우의 점검 사항입니다.

## 🔍 점검할 사항

### 1. 알람 시간이 과거인지 확인

**문제**: 백엔드에서 보낸 알람 시간이 현재 시간보다 과거면 알람이 예약되지 않습니다.

**확인 방법**:
- Android Studio Logcat 또는 `flutter logs` 확인
- 다음 로그 확인:
  ```
  [AlarmNotificationService] Alarm time is in the past: ...
  ```

**해결**:
- AI에게 **미래 시간**으로 알람을 요청하세요
- 예: "1분 뒤에 알람 맞춰줘", "오후 6시에 알람 설정해줘"

### 2. 알람이 DB에 저장되었는지 확인

**확인할 로그**:
```
[AlarmProvider] Alarm saved with ID: 1
[AlarmProvider] Notification scheduled for alarm ID: 1
```

### 3. Notification 예약 확인

**확인할 로그**:
```
[AlarmNotificationService] Alarm scheduled: 1 at 2025-12-12 18:40:00.000
```

### 4. 테스트용 즉시 알람

앱에서 바로 알람이 울리는지 테스트하려면, 알람 화면에 테스트 버튼을 추가할 수 있습니다:

```dart
// 테스트 버튼 추가 (임시)
ElevatedButton(
  onPressed: () async {
    final service = ref.read(alarmNotificationServiceProvider);
    await service.showImmediateNotification(
      id: 999,
      title: '테스트 알람',
      body: '알람이 정상 작동합니다!',
    );
  },
  child: Text('즉시 알람 테스트'),
)
```

## 🐛 일반적인 문제

### 문제 1: 배터리 최적화

**증상**: 알람이 예약되었지만 시간이 되어도 안 울림

**원인**: Android 배터리 최적화가 앱을 절전 모드로 전환

**해결**:
1. 설정 → 앱 → 마음봄 → 배터리
2. "배터리 사용량 최적화" → 최적화하지 않음 선택

### 문제 2: 알림 채널 문제

**증상**: 권한은 있지만 알람이 울리지 않음

**원인**: 알림 채널이 제대로 생성되지 않음

**해결**:
1. 앱 재설치
2. 설정 → 앱 → 마음봄 → 알림 → "알람" 채널 활성화 확인

### 문제 3: Exact Alarm 권한 설정

**증상**: 알람이 정확한 시간에 울리지 않거나 안 울림

**확인**:
1. 설정 → 앱 → 마음봄 → 알람 및 리마인더
2. 토글이 **ON** 상태인지 확인

**로그 확인**:
```
⏰ Exact alarm permission granted: true
```

false면 설정에서 수동으로 활성화 필요!

### 문제 4: 과거 시간 알람

**증상**: 알람 생성 시 시간이 이미 지나감

**예시**:
- 현재 시간: 12월 12일 오후 6:30
- 요청: "오후 5시 알람" → 과거이므로 예약 안 됨

**해결**:
- "내일 오후 5시 알람" 또는 구체적인 날짜 지정

## 🔧 디버깅 명령어

### Flutter 로그 확인
```bash
flutter logs | grep -i alarm
```

### 현재 예약된 알람 확인 (코드 추가 필요)
```dart
// alarm_screen.dart에 추가
final pending = await ref.read(alarmNotificationServiceProvider)
    .getPendingAlarms();
print('Pending notifications: ${pending.length}');
for (final p in pending) {
  print('  - ID: ${p.id}, Title: ${p.title}');
}
```

## 📊 체크리스트

앱 실행 후 다음을 모두 확인하세요:

- [ ] 앱 시작 시 권한 요청 팝업 2개 나타남 (알림 + exact alarm)
- [ ] 로그에 `🔔 Notification permission granted: true` 출력
- [ ] 로그에 `⏰ Exact alarm permission granted: true` 출력
- [ ] AI에게 미래 시간으로 알람 요청
- [ ] 로그에 `[AlarmProvider] Alarm saved with ID: ...` 출력
- [ ] 로그에 `[AlarmNotificationService] Alarm scheduled: ...` 출력
- [ ] 설정 → 앱 → 마음봄 → 알림 → "알람" 채널 활성화
- [ ] 설정 → 앱 → 마음봄 → 알람 및 리마인더 ON
- [ ] 설정 → 앱 → 마음봄 → 배터리 → 최적화하지 않음

## 🎯 빠른 테스트 방법

1. **1분 후 알람 테스트**:
   ```
   AI: "1분 뒤에 알람 맞춰줘"
   ```

2. **로그 확인**:
   ```
   [AlarmProvider] Alarm saved with ID: 1
   [AlarmNotificationService] Alarm scheduled: 1 at 2025-12-12 18:38:00.000
   ```

3. **1분 대기** → 알람이 울리면 성공! 🎉

## 🆘 그래도 안 되면

다음 정보를 확인해주세요:

1. Android 버전: 설정 → 휴대전화 정보 → Android 버전
2. Flutter logs 전체 출력 (알람 생성부터 시간 경과까지)
3. 앱이 백그라운드/포그라운드 중 어느 상태인지
4. 배터리 절약 모드 ON/OFF 여부
