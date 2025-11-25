# 소셜 OAuth2 + JWT 인증 시스템

FastAPI와 MySQL을 사용한 소셜 로그인(Google, Kakao, Naver) 및 JWT 인증 시스템입니다.

## 📋 목차

- [기능](#기능)
- [환경 설정](#환경-설정)
- [API 엔드포인트](#api-엔드포인트)
- [사용 방법](#사용-방법)
- [보안 전략](#보안-전략)
- [모바일 앱으로 전환하기](#-모바일-앱으로-전환하기)

## ✨ 기능

- ✅ 소셜 OAuth2 로그인 (Google, Kakao, Naver)
- ✅ JWT 기반 인증 (Access Token + Refresh Token)
- ✅ RTR (Refresh Token Rotation) 전략
- ✅ Whitelist 기반 Refresh Token 관리
- ✅ Stateless 인증 (Session/Cookie 사용 안 함)
- ✅ 웹/앱 모두 대응 (동적 redirect_uri)
- ✅ Provider별 완전 분리 계정 관리

## 🔧 환경 설정

### 1. 소셜 OAuth2 설정

#### 🔐 Google OAuth2 설정

1. [Google Cloud Console](https://console.cloud.google.com/) 접속
2. 프로젝트 생성 또는 선택
3. 좌측 메뉴에서 "API 및 서비스" > "사용자 인증 정보" 클릭
4. "사용자 인증 정보 만들기" > "OAuth 2.0 클라이언트 ID" 선택
5. 애플리케이션 유형: "웹 애플리케이션" 선택
6. 이름 입력 (예: "Bom Project Auth")
7. **승인된 리디렉션 URI** 추가:
   - 개발 환경: `http://localhost:5173/auth/callback`
   - 프로덕션: `https://yourdomain.com/auth/callback`
8. "만들기" 클릭
9. 표시되는 **클라이언트 ID**와 **클라이언트 보안 비밀번호**를 복사
10. `.env` 파일의 `GOOGLE_CLIENT_ID`와 `GOOGLE_CLIENT_SECRET`에 붙여넣기

#### 🔐 Kakao OAuth2 설정

1. [Kakao Developers](https://developers.kakao.com/) 접속
2. "내 애플리케이션" > "애플리케이션 추가하기" 클릭
3. 앱 이름, 사업자명 입력 후 저장
4. 앱 설정 > 앱 키에서 **REST API 키** 복사 → `KAKAO_CLIENT_ID`에 입력
5. 제품 설정 > 카카오 로그인 > 활성화 설정 ON
6. **Redirect URI** 등록:
   - 개발 환경: `http://localhost:5173/auth/callback`
   - 프로덕션: `https://yourdomain.com/auth/callback`
7. 동의항목 설정:
   - 닉네임: 필수 동의
   - 카카오계정(이메일): 필수 동의
8. 보안 > Client Secret 발급 (선택사항, 발급 시 `KAKAO_CLIENT_SECRET`에 입력)

#### 🔐 Naver OAuth2 설정

1. [Naver Developers](https://developers.naver.com/) 접속
2. "Application" > "애플리케이션 등록" 클릭
3. 애플리케이션 이름 입력
4. 사용 API: "네아로(네이버 아이디로 로그인)" 선택
5. **제공 정보**: 회원이름, 이메일 주소, 별명 선택
6. **서비스 URL**: `http://localhost:5173` (개발) 또는 실제 도메인
7. **Callback URL**:
   - 개발 환경: `http://localhost:5173/auth/callback`
   - 프로덕션: `https://yourdomain.com/auth/callback`
8. 등록 완료 후 **Client ID**와 **Client Secret** 복사
9. `.env` 파일의 `NAVER_CLIENT_ID`와 `NAVER_CLIENT_SECRET`에 붙여넣기

### 2. 환경변수 설정

`backend/.env` 파일에 다음 내용 추가:

```env
###########################################################
# Google OAuth2 Configuration
###########################################################
GOOGLE_CLIENT_ID=your_google_client_id_here
GOOGLE_CLIENT_SECRET=your_google_client_secret_here

###########################################################
# Kakao OAuth2 Configuration
###########################################################
KAKAO_CLIENT_ID=your_kakao_rest_api_key_here
KAKAO_CLIENT_SECRET=your_kakao_client_secret_here

###########################################################
# Naver OAuth2 Configuration
###########################################################
NAVER_CLIENT_ID=your_naver_client_id_here
NAVER_CLIENT_SECRET=your_naver_client_secret_here

###########################################################
# JWT Configuration
###########################################################
# Generate: python -c "import secrets; print(secrets.token_urlsafe(32))"
JWT_SECRET_KEY=your_jwt_secret_key_min_32_characters_long
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=15
REFRESH_TOKEN_EXPIRE_DAYS=7

###########################################################
# MySQL Database Configuration
###########################################################
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=1111
DB_NAME=bomdb
```

### 3. JWT Secret Key 생성

터미널에서 다음 명령어를 실행하여 안전한 Secret Key를 생성하세요:

```bash
python -c "import secrets; print(secrets.token_urlsafe(32))"
```

출력된 문자열을 `JWT_SECRET_KEY`에 입력하세요.

### 4. 패키지 설치

```bash
cd backend
pip install -r requirements.txt
```

### 5. 데이터베이스 초기화

서버 시작 시 자동으로 `users` 테이블이 생성됩니다.

**User 테이블 구조:**
- `id`: 사용자 고유 ID (자동 증가)
- `social_id`: 소셜 플랫폼 고유 ID
- `provider`: 소셜 플랫폼 종류 (`google`, `kakao`, `naver`)
- `email`: 이메일 주소
- `nickname`: 사용자 닉네임
- `refresh_token`: Refresh Token (Whitelist)
- `created_at`: 계정 생성 시간
- `updated_at`: 계정 업데이트 시간

### 6. 서버 실행

```bash
cd backend
python main.py
```

서버가 `http://localhost:8000`에서 실행됩니다.

**확인:**
- API 문서: `http://localhost:8000/docs`
- Health Check: `http://localhost:8000/auth/health`

## 🚀 API 엔드포인트

### 1. Google OAuth 로그인

**POST** `/auth/google`

프론트엔드에서 받은 Google authorization code로 로그인합니다.

**Request Body:**
```json
{
  "auth_code": "4/0AY0e-g7xxxxxxxxxxxxxxxxxxx",
  "redirect_uri": "http://localhost:5173/auth/callback"
}
```

**Response:**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer"
}
```

### 2. Kakao OAuth 로그인

**POST** `/auth/kakao`

프론트엔드에서 받은 Kakao authorization code로 로그인합니다.

**Request Body:**
```json
{
  "auth_code": "xxxxxxxxxxxxxxxxxxxxxxxxxxx",
  "redirect_uri": "http://localhost:5173/auth/callback"
}
```

**Response:** (Google과 동일)

### 3. Naver OAuth 로그인

**POST** `/auth/naver`

프론트엔드에서 받은 Naver authorization code로 로그인합니다.

**Request Body:**
```json
{
  "auth_code": "xxxxxxxxxxxxxxxxxxxxxxxxxxx",
  "redirect_uri": "http://localhost:5173/auth/callback",
  "state": "random_state_string"
}
```

**Response:** (Google과 동일)

### 4. Access Token 재발급

**POST** `/auth/refresh`

Refresh Token으로 새로운 Access Token을 발급받습니다 (RTR 적용).

**Request Body:**
```json
{
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Response:**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer"
}
```

### 5. 로그아웃

**POST** `/auth/logout`

Refresh Token을 무효화합니다.

**Headers:**
```
Authorization: Bearer {access_token}
```

**Response:**
```json
{
  "message": "Logged out successfully"
}
```

### 6. 내 정보 조회

**GET** `/auth/me`

현재 로그인한 사용자 정보를 조회합니다.

**Headers:**
```
Authorization: Bearer {access_token}
```

**Response:**
```json
{
  "id": 1,
  "email": "user@example.com",
  "nickname": "홍길동",
  "provider": "google",
  "created_at": "2024-01-01T00:00:00"
}
```

**참고:** `provider` 필드는 `"google"`, `"kakao"`, `"naver"` 중 하나입니다.

### 7. 인증 설정 조회

**GET** `/auth/config`

프론트엔드에서 필요한 OAuth Client ID들을 조회합니다.

**Response:**
```json
{
  "google_client_id": "123456789-abcdefghijklmnop.apps.googleusercontent.com",
  "kakao_client_id": "abcdef1234567890abcdef12",
  "naver_client_id": "AbCdEfGhIjKlMnOp"
}
```

## 💡 사용 방법

### 프론트엔드 통합 예시 (React)

#### 1. OAuth Client ID 가져오기

```javascript
// 백엔드에서 Client ID들을 가져옵니다
const fetchConfig = async () => {
  const response = await fetch('http://localhost:8000/auth/config');
  const config = await response.json();
  // config.google_client_id
  // config.kakao_client_id
  // config.naver_client_id
  return config;
};
```

#### 2. Google OAuth 로그인

```javascript
const handleGoogleLogin = () => {
  const redirectUri = `${window.location.origin}/auth/callback`;
  const authUrl = `https://accounts.google.com/o/oauth2/v2/auth?` +
    `client_id=${encodeURIComponent(googleClientId)}&` +
    `redirect_uri=${encodeURIComponent(redirectUri)}&` +
    `response_type=code&` +
    `scope=${encodeURIComponent('openid email profile')}&` +
    `access_type=offline&` +
    `prompt=consent`;
  
  window.location.href = authUrl;
};
```

#### 3. Kakao OAuth 로그인

```javascript
const handleKakaoLogin = () => {
  sessionStorage.setItem('kakao_login', 'true'); // 콜백 구분용
  const redirectUri = `${window.location.origin}/auth/callback`;
  const authUrl = `https://kauth.kakao.com/oauth/authorize?` +
    `client_id=${encodeURIComponent(kakaoClientId)}&` +
    `redirect_uri=${encodeURIComponent(redirectUri)}&` +
    `response_type=code`;
  
  window.location.href = authUrl;
};
```

#### 4. Naver OAuth 로그인

```javascript
const handleNaverLogin = () => {
  const state = Math.random().toString(36).substring(2, 15);
  sessionStorage.setItem('naver_state', state); // CSRF 방지
  const redirectUri = `${window.location.origin}/auth/callback`;
  const authUrl = `https://nid.naver.com/oauth2.0/authorize?` +
    `client_id=${encodeURIComponent(naverClientId)}&` +
    `redirect_uri=${encodeURIComponent(redirectUri)}&` +
    `response_type=code&` +
    `state=${encodeURIComponent(state)}`;
  
  window.location.href = authUrl;
};
```

#### 5. OAuth Callback 처리

```javascript
// URL에서 code 파라미터 확인
const urlParams = new URLSearchParams(window.location.search);
const code = urlParams.get('code');
const state = urlParams.get('state');

if (code) {
  let endpoint = '/auth/google';
  let requestBody = {
    auth_code: code,
    redirect_uri: `${window.location.origin}/auth/callback`
  };
  
  // Naver인 경우
  if (state) {
    const savedState = sessionStorage.getItem('naver_state');
    if (savedState === state) {
      endpoint = '/auth/naver';
      requestBody.state = state;
      sessionStorage.removeItem('naver_state');
    }
  }
  // Kakao인 경우
  else if (sessionStorage.getItem('kakao_login') === 'true') {
    endpoint = '/auth/kakao';
    sessionStorage.removeItem('kakao_login');
  }
  
  // 백엔드로 authorization code 전송
  const response = await fetch(`http://localhost:8000${endpoint}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(requestBody)
  });
  
  const data = await response.json();
  
  // 토큰 저장
  localStorage.setItem('access_token', data.access_token);
  localStorage.setItem('refresh_token', data.refresh_token);
  
  // URL에서 code 제거
  window.history.replaceState({}, document.title, window.location.pathname);
}
```

#### 6. API 요청 시 토큰 사용

```javascript
async function fetchProtectedData() {
  const accessToken = localStorage.getItem('access_token');
  
  const response = await fetch('http://localhost:8000/auth/me', {
    headers: {
      'Authorization': `Bearer ${accessToken}`
    }
  });
  
  if (response.status === 401) {
    // Access Token 만료 시 재발급
    await refreshToken();
    return fetchProtectedData(); // 재시도
  }
  
  return response.json();
}
```

#### 7. Token Refresh

```javascript
async function refreshToken() {
  const refreshToken = localStorage.getItem('refresh_token');
  
  const response = await fetch('http://localhost:8000/auth/refresh', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ refresh_token: refreshToken })
  });
  
  if (response.ok) {
    const data = await response.json();
    localStorage.setItem('access_token', data.access_token);
    localStorage.setItem('refresh_token', data.refresh_token);
  } else {
    // Refresh Token도 만료됨 -> 재로그인 필요
    localStorage.clear();
    window.location.href = '/login';
  }
}
```

## 🔒 보안 전략

### 1. RTR (Refresh Token Rotation)

- Refresh Token으로 Access Token 재발급 시, Refresh Token도 함께 갱신
- 구 Refresh Token은 즉시 무효화
- Refresh Token 탈취 시 피해 최소화

### 2. Whitelist

- 유효한 Refresh Token을 DB에 저장
- Token 재발급 시 DB의 토큰과 비교하여 검증
- 로그아웃 시 DB에서 토큰 삭제

### 3. Stateless 인증

- Session/Cookie 사용 안 함
- 모든 요청에 Bearer Token 포함
- 서버 확장성 향상

### 4. 동적 redirect_uri

- 요청 파라미터로 redirect_uri 전달
- 웹/앱 모두 대응 가능
- 환경별로 다른 URI 사용 가능

### 5. Provider별 완전 분리

- 각 소셜 플랫폼(Google, Kakao, Naver)별로 별도 계정 생성
- `provider` + `social_id` 조합으로 사용자 식별
- 같은 사용자가 여러 플랫폼으로 가입 가능

## 📱 모바일 앱으로 전환하기

### 1. 앱용 OAuth 설정 개요

모바일 앱에서는 웹과 달리 **Custom URL Scheme** 또는 **Deep Link**를 사용하여 OAuth 콜백을 처리합니다.

**주요 변경사항:**
- `redirect_uri`를 웹 URL에서 앱 스킴으로 변경 (예: `yourapp://auth/callback`)
- 각 플랫폼 개발자 콘솔에 앱 스킴 등록
- 프론트엔드 코드에서 앱 스킴 처리 로직 추가

### 2. Google OAuth 앱 설정

#### Android 앱

1. [Google Cloud Console](https://console.cloud.google.com/) 접속
2. 기존 OAuth 클라이언트 ID 선택 또는 새로 생성
3. 애플리케이션 유형: **"Android"** 선택
4. 패키지 이름 입력 (예: `com.yourapp.bom`)
5. SHA-1 인증서 지문 입력 (디버그/릴리즈 키)
6. **승인된 리디렉션 URI**에 앱 스킴 추가:
   - `yourapp://auth/callback`
   - 또는 `com.yourapp.bom://auth/callback`

#### iOS 앱

1. [Google Cloud Console](https://console.cloud.google.com/) 접속
2. 기존 OAuth 클라이언트 ID 선택 또는 새로 생성
3. 애플리케이션 유형: **"iOS"** 선택
4. 번들 ID 입력 (예: `com.yourapp.bom`)
5. **승인된 리디렉션 URI**에 앱 스킴 추가:
   - `yourapp://auth/callback`
   - 또는 `com.yourapp.bom://auth/callback`

### 3. Kakao OAuth 앱 설정

1. [Kakao Developers](https://developers.kakao.com/) 접속
2. 앱 선택 > 제품 설정 > 카카오 로그인
3. **플랫폼 설정**에서 플랫폼 추가:
   - **Android**: 패키지 이름, 키 해시 입력
   - **iOS**: 번들 ID 입력
4. **Redirect URI**에 앱 스킴 등록:
   - `yourapp://auth/callback`
   - 또는 `kakao{앱키}://oauth` (Kakao 기본 형식)

**참고:** Kakao는 플랫폼별로 다른 Redirect URI 형식을 사용할 수 있습니다.

### 4. Naver OAuth 앱 설정

1. [Naver Developers](https://developers.naver.com/) 접속
2. 애플리케이션 선택 > 설정
3. **플랫폼 설정**에서 플랫폼 추가:
   - **Android**: 패키지 이름 입력
   - **iOS**: 번들 ID 입력
4. **Callback URL**에 앱 스킴 등록:
   - `yourapp://auth/callback`
   - 또는 `com.yourapp.bom://auth/callback`

### 5. 앱에서 OAuth 구현 (React Native 예시)

#### Deep Link 설정

**Android (AndroidManifest.xml):**
```xml
<activity android:name=".MainActivity">
  <intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="yourapp" android:host="auth" />
  </intent-filter>
</activity>
```

**iOS (Info.plist):**
```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>yourapp</string>
    </array>
  </dict>
</array>
```

#### OAuth 로그인 코드

```javascript
import { Linking } from 'react-native';

// Google 로그인
const handleGoogleLogin = async () => {
  const redirectUri = 'yourapp://auth/callback';
  const authUrl = `https://accounts.google.com/o/oauth2/v2/auth?` +
    `client_id=${encodeURIComponent(googleClientId)}&` +
    `redirect_uri=${encodeURIComponent(redirectUri)}&` +
    `response_type=code&` +
    `scope=${encodeURIComponent('openid email profile')}&` +
    `access_type=offline&` +
    `prompt=consent`;
  
  // 외부 브라우저로 열기
  await Linking.openURL(authUrl);
};

// Deep Link 콜백 처리
useEffect(() => {
  const handleDeepLink = async (url) => {
    if (url.startsWith('yourapp://auth/callback')) {
      const urlParams = new URLSearchParams(url.split('?')[1]);
      const code = urlParams.get('code');
      const state = urlParams.get('state');
      
      if (code) {
        // 백엔드로 authorization code 전송
        const response = await fetch('http://your-api.com/auth/google', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            auth_code: code,
            redirect_uri: 'yourapp://auth/callback'
          })
        });
        
        const data = await response.json();
        
        // 토큰 저장 (AsyncStorage 사용)
        await AsyncStorage.setItem('access_token', data.access_token);
        await AsyncStorage.setItem('refresh_token', data.refresh_token);
      }
    }
  };
  
  // 앱이 열릴 때 Deep Link 처리
  Linking.addEventListener('url', ({ url }) => handleDeepLink(url));
  
  // 앱이 이미 실행 중일 때 Deep Link 처리
  Linking.getInitialURL().then(url => {
    if (url) handleDeepLink(url);
  });
}, []);
```

### 6. 백엔드 변경사항

**변경 불필요!** 백엔드는 이미 `redirect_uri`를 동적으로 받아서 처리하므로 앱 스킴도 그대로 동작합니다.

```python
# backend/app/auth/routers.py
# 이미 구현되어 있음 - redirect_uri를 그대로 사용
request: GoogleLoginRequest  # redirect_uri 포함
```

### 7. 주의사항

1. **앱 스킴은 고유해야 함**: 다른 앱과 충돌하지 않도록 고유한 스킴 사용
2. **보안**: 앱 스킴은 공개되므로 추가 검증 로직 권장
3. **테스트**: 개발/프로덕션 환경별로 다른 스킴 사용 권장
4. **플랫폼별 차이**: Android와 iOS의 Deep Link 처리 방식이 다를 수 있음

### 8. 앱 스킴 예시

```
# 개발 환경
devapp://auth/callback

# 프로덕션 환경
yourapp://auth/callback

# 또는 패키지 이름 기반
com.yourapp.bom://auth/callback
```

## 📁 코드 구조

```
backend/app/auth/
├── __init__.py         # 패키지 초기화
├── models.py           # SQLAlchemy User 모델
├── schemas.py          # Pydantic DTO
├── database.py         # DB 연결 설정
├── utils.py            # JWT 생성/검증 함수
├── dependencies.py     # 토큰 검증 의존성
├── services.py         # 비즈니스 로직
├── routers.py          # API 엔드포인트
└── README.md           # 이 문서
```

## 🐛 트러블슈팅

### 1. "OAuth credentials not configured" 오류

- `.env` 파일에 해당 플랫폼의 `CLIENT_ID`와 `CLIENT_SECRET`이 설정되어 있는지 확인
- 환경변수가 제대로 로드되는지 확인 (서버 재시작 필요)

### 2. "Failed to get access token" 오류

- `redirect_uri`가 각 플랫폼 개발자 콘솔에 등록된 URI와 정확히 일치하는지 확인
- Authorization code가 이미 사용되었거나 만료되지 않았는지 확인
- 카카오: REST API 키를 `KAKAO_CLIENT_ID`에 입력했는지 확인
- 네이버: `state` 값이 일치하는지 확인

### 3. "Token has expired" 오류

- Access Token 만료 (15분): `/auth/refresh`로 재발급
- Refresh Token 만료 (7일): 재로그인 필요

### 4. MySQL 연결 오류

- MySQL 서버가 실행 중인지 확인
- `bomdb` 데이터베이스가 생성되어 있는지 확인
- DB 계정 정보가 올바른지 확인

## 📚 참고 자료

- [Google OAuth2 문서](https://developers.google.com/identity/protocols/oauth2)
- [JWT 공식 사이트](https://jwt.io/)
- [FastAPI 문서](https://fastapi.tiangolo.com/)
- [SQLAlchemy 문서](https://docs.sqlalchemy.org/)

