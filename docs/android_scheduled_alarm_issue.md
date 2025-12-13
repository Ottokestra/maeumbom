# Android 예약 알림이 울리지 않는 문제 분석

## 현황
- ✅ 즉시 알림 (`.show()`) → 정상 작동
- ❌ 예약 알림 (`.zonedSchedule()`) → 예약 성공but 울리지 않음

## 로그 분석```
Scheduled time: 15:22:00
Current time (예약 시점): 15:21:20
Time until alarm: 39 sec ✅알람 예약 성공!
```

**1분 후 (15:22:59)**: 알람이 울리지 않음 ❌

## 문제 원인 추정

### 1. AndroidScheduleMode 문제 🔴 (가장 유력)
**현재 설정**: `AndroidScheduleMode.exactAllowWhileIdle`

**문제**: 이 모드는 Doze mode에서도 작동하지만, Android 12+에서는:
- `SCHEDULE_EXACT_ALARM` 권한 필요 ✅ (있음)
- `USE_EXACT_ALARM` 권한 필요 ✅ (있음)  
- 하지만 실제로 **작동 안 할 수 있음** (기기 제조사별 상이)

**해결 시도**: `AndroidScheduleMode.exact`로 변경
- 더 단순함
- Doze mode에서는 지연될 수 있지만 **기본적으로 더 안정적**

### 2. Notification Channel 문제
**확인 필요**:
- 채널이 실제로 생성되었는지
- 채널 설정이 올바른지

### 3. 앱 Background Restriction
**Android 시스템 제약**:
- 배터리 최적화
- Background app restrictions  
- Doze mode
- App standby

## 시도한 수정사항

1. `AndroidScheduleMode.exactAllowWhileIdle` → `AndroidScheduleMode.exact` 변경

## 다음 테스트

1. 앱 재시작
2. "1분 뒤 알람" 설정
3. **앱을 켜둔 상태로** 1분 대기
4. 만약 안 되면:
   - 설정 → 앱 → 마음봄 → 배터리 → 제한 없음
   - 앱 재시작 후 다시 테스트

## flutter_local_notifications 제약사항

`zonedSchedule`은 Android에서:
- AlarmManager 사용
- 시스템 배터리 최적화 영향 받음
- 기기 제조사별로 동작이 다를 수 있음

---

**대안**: `android_alarm_manager_plus` 패키지 사용 고려
- 더 강력한 알람 기능  
- Background에서도 확실하게 작동
- 하지만 추가 설정 필요
