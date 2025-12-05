# 카카오 로그인 트러블슈팅 가이드

## 문제 개요
Flutter 앱에서 카카오 로그인 구현 시 발생한 여러 에러와 해결 과정을 정리한 문서입니다.

---

## 발생한 에러들

### 1. REDIRECT_URI_MISMATCH 에러
**에러 메시지:**
```
PlatformException(REDIRECT_URI_MISMATCH, Expected: kakao{YOUR_NATIVE_APP_KEY}://oauth, Actual: null)
```

**원인:**
- 카카오 SDK의 웹 로그인 후 앱으로 돌아오는 과정을 처리하는 `AuthCodeCustomTabsActivity`가 AndroidManifest.xml에 등록되지 않음

**해결 방법:**
`frontend/android/app/src/main/AndroidManifest.xml`에 다음 Activity 추가:

```xml
<!-- Kakao Login CustomTabs Activity -->
<activity 
    android:name="com.kakao.sdk.flutter.AuthCodeCustomTabsActivity"
    android:exported="true">
    <intent-filter android:label="flutter_web_auth">
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="kakao${KAKAO_APP_KEY}" android:host="oauth"/>
    </intent-filter>
</activity>
```

**참고:**
- `${KAKAO_APP_KEY}`는 `build.gradle.kts`의 `manifestPlaceholders`에서 정의된 값
- 카카오 개발자 콘솔에서 확인한 네이티브 앱 키를 사용

---

### 2. Android keyHash validation failed
**에러 메시지:**
```
{error: invalid_request, error_description: Android keyHash validation failed.}
```

**원인:**
- Windows Git Bash에서 `openssl` 명령어로 추출한 키 해시가 실제 앱의 키 해시와 다름
- 바이너리 데이터를 텍스트로 변환하는 과정에서 데이터 손실 발생

**해결 방법:**

#### Step 1: MainActivity.kt에 키 해시 로그 출력 코드 추가

`frontend/android/app/src/main/kotlin/com/maeumbom/frontend/MainActivity.kt`:

```kotlin
package com.maeumbom.frontend

import io.flutter.embedding.android.FlutterActivity
import android.os.Bundle
import android.util.Log
import android.content.pm.PackageManager
import android.util.Base64
import java.security.MessageDigest

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // 💡 앱 실행 시 키 해시를 로그로 출력하는 코드
        try {
            val info = packageManager.getPackageInfo(packageName, PackageManager.GET_SIGNATURES)
            info.signatures?.let { signatures ->
                for (signature in signatures) {
                    val md = MessageDigest.getInstance("SHA")
                    md.update(signature.toByteArray())
                    val hashKey = Base64.encodeToString(md.digest(), Base64.NO_WRAP)
                    Log.d("HASH_KEY_CHECK", "🔥🔥🔥 실제 적용된 키 해시: $hashKey")
                }
            }
        } catch (e: Exception) {
            Log.e("HASH_KEY_CHECK", "키 해시 로드 실패", e)
        }
    }
}
```

#### Step 2: 앱 실행 후 로그 확인
- `flutter run` 실행
- 터미널에서 `🔥🔥🔥` 검색
- 출력된 키 해시 복사 (예: `YOUR_KEY_HASH_HERE=`)

#### Step 3: 카카오 개발자 콘솔에 등록
1. https://developers.kakao.com 접속
2. 내 애플리케이션 → 플랫폼 → Android 플랫폼
3. 키 해시 섹션에 로그에서 확인한 키 해시 등록
4. 저장 후 1-2분 대기 (카카오 서버 반영 시간)

**주의사항:**
- 터미널 명령어로 추출한 키 해시는 신뢰하지 말 것
- 앱에서 직접 출력한 키 해시만 사용할 것
- Debug 키스토어와 Release 키스토어의 키 해시가 다를 수 있음

---

### 3. authorization code not found (KOE320)
**에러 메시지:**
```
{"error":"invalid_grant","error_description":"authorization code not found for code=...","error_code":"KOE320"}
```

**원인:**
- 카카오 Flutter SDK는 이미 `accessToken`을 직접 반환함
- 프론트엔드에서 `accessToken`을 백엔드로 전달
- 백엔드가 받은 값을 `authCode`로 착각하여 카카오에 토큰 교환 요청
- 카카오가 "그런 authCode 없어!" 응답

**해결 방법:**

`backend/app/auth/services.py`의 `kakao_login` 함수 수정:

```python
# 기존 코드 (문제 발생)
if len(auth_code) > 100:  # Access token은 보통 100자 이상
    kakao_access_token = auth_code
else:
    kakao_access_token = await get_kakao_access_token(auth_code, redirect_uri)

# 수정된 코드
if len(auth_code) > 50:  # Access token은 보통 50자 이상, authCode는 30-40자
    kakao_access_token = auth_code
else:
    kakao_access_token = await get_kakao_access_token(auth_code, redirect_uri)
```

**설명:**
- 카카오 SDK의 `accessToken`은 보통 50자 이상
- 카카오의 `authCode`는 보통 30-40자
- 길이로 구분하여 `accessToken`인 경우 토큰 교환 과정을 건너뜀

---

## 최종 확인 사항

### 카카오 개발자 콘솔 설정
- ✅ **네이티브 앱 키**: 카카오 개발자 콘솔에서 확인한 값 등록
- ✅ **REST API 키**: 카카오 개발자 콘솔에서 확인한 값 등록
- ✅ **패키지명**: 앱의 실제 패키지명 등록
- ✅ **키 해시**: 앱에서 로그로 확인한 실제 키 해시 등록
- ✅ **Android 플랫폼**: 활성화 상태

### 코드 설정 확인
- ✅ `AndroidManifest.xml`: `AuthCodeCustomTabsActivity` 추가
- ✅ `build.gradle.kts`: `manifestPlaceholders`에 카카오 네이티브 앱 키 설정
- ✅ `strings.xml`: 카카오 네이티브 앱 키 리소스 정의
- ✅ `MainActivity.kt`: 키 해시 로그 출력 코드 (디버깅용, 나중에 제거 가능)
- ✅ `services.py`: 길이 체크 50자로 수정

---

## 성공 로그 예시

```
[Auth] New Kakao user created: {USER_ID} ({USER_EMAIL})
INFO: POST /auth/kakao HTTP/1.1" 200 OK
INFO: GET /auth/me HTTP/1.1" 200 OK
```

---

## 참고 자료
- [카카오 Flutter SDK 공식 문서](https://developers.kakao.com/docs/latest/ko/flutter/getting-started)
- [카카오 로그인 Flutter 가이드](https://developers.kakao.com/docs/latest/ko/kakaologin/flutter)
- [박사개구리의 블로그 - Flutter로 카카오톡 로그인 구현하기](https://phd-frog.tistory.com/46)

---

## 추가 팁

### 키 해시 확인 방법 (앱에서 직접)
앱 실행 시 자동으로 키 해시가 로그에 출력되도록 설정했으므로, 언제든지 확인 가능합니다.

### 디버깅용 코드 제거
프로덕션 배포 전에 `MainActivity.kt`의 키 해시 로그 출력 코드는 제거하는 것을 권장합니다.

### Release 빌드 시 주의사항
- Release 키스토어의 키 해시도 별도로 등록해야 함
- 카카오 개발자 콘솔에서 여러 개의 키 해시 등록 가능

---

**작성일**: 2025-01-XX  
**해결 완료**: ✅

