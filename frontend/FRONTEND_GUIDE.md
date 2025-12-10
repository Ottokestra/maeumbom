# Maeumbom Frontend 개발 가이드

마음봄 Flutter 앱 개발을 위한 전체 가이드입니다.

---

### 서비스 추가 예시

**기본 서비스 생성 요청 예시:**
```
"frontend/FRONTEND_GUIDE.md를 참고하여 
/app/example 에 example_screen.dart 을 추가할거야
- (하위 명시)
```


## 📚 목차

1. [시작하기](#-시작하기)
2. [프로젝트 구조](#-프로젝트-구조)
3. [디자인 시스템](#-디자인-시스템)
4. [API 및 상태 관리](#-api-및-상태-관리)
5. [로컬 데이터베이스 (Drift)](#-로컬-데이터베이스-drift)
6. [개발 워크플로우](#-개발-워크플로우)
7. [코딩 컨벤션](#-코딩-컨벤션)
8. [문제 해결](#-문제-해결)

---

## 🚀 시작하기

### 환경 설정

프로젝트 위치: `/frontend`

### 의존성 설치

```bash
cd frontend
flutter pub get

# build_runner 실행
flutter pub run build_runner build --delete-conflicting-outputs
```

### 실행 방법

#### iOS 시뮬레이터

```bash
flutter run -d "iPhone 16"

# 시뮬레이터가 인식되지 않으면
flutter devices
open -a Simulator  # iOS 시뮬레이터 실행
```

#### Android 에뮬레이터

```bash
flutter run -d android
```

#### 개발 도구

```bash
# 코드 분석
flutter analyze

# 테스트 실행
flutter test

# 빌드 (디버그)
flutter build apk --debug  # Android
flutter build ios --debug  # iOS
```

---

## 📁 프로젝트 구조

```
frontend/
├── android/                            # Android 빌드 설정
├── ios/                                # iOS 빌드 설정
├── assets/                             # 리소스 파일
│   ├── characters/                     # 감정 캐릭터
│   │   ├── animation/                  # Lottie 애니메이션 (✅ 구현됨)
│   │   │   ├── happiness/
│   │   │   ├── sadness/
│   │   │   ├── anger/
│   │   │   └── fear/
│   │   ├── high/                       # 고해상도 정적 이미지
│   │   └── normal/                     # 일반 정적 이미지
│   ├── fonts/                          # 커스텀 폰트
│   └── images/                         # 앱 이미지, 아이콘
│       └── icons/
│
├── lib/                                # Flutter 소스 코드
│   ├── main.dart                       # 앱 진입점
│   │
│   ├── app/                            # 기능별 화면 (Feature-first)
│   │   ├── home/                       # 홈 화면
│   │   │   ├── home_screen.dart
│   │   │   ├── daily_mood_check_screen.dart
│   │   │   └── components/             # 홈 화면 컴포넌트
│   │   │       ├── home_header_section.dart
│   │   │       ├── conversation_temperature_bar.dart
│   │   │       ├── home_bottom_menu.dart
│   │   │       └── home_menu_grid.dart
│   │   ├── chat/                       # AI 봄이와 대화
│   │   │   └── bomi_screen.dart        # 봄이 채팅 (✅ 애니메이션 적용)
│   │   ├── alarm/                      # 똑똑 알람
│   │   ├── report/                     # 마음리포트
│   │   ├── training/                   # 마음연습실
│   │   ├── onboarding/                 # 온보딩
│   │   ├── settings/                   # 설정
│   │   ├── common/                     # 공통 기능 (login)
│   │   └── example/                    # 예시/테스트 화면
│   │       ├── example_screen.dart
│   │       └── bubble_screen.dart      # Bubble 컴포넌트 테스트
│   │
│   ├── ui/                             # UI 시스템
│   │   ├── app_ui.dart                 # UI 시스템 통합 export
│   │   │
│   │   ├── layout/                     # 레이아웃 컴포넌트
│   │   │   ├── app_frame.dart          # 화면 기본 프레임
│   │   │   ├── top_bars.dart           # Top Bar (5가지 변형)
│   │   │   ├── bottom_menu_bars.dart   # Bottom Menu Bar
│   │   │   ├── bottom_button_bars.dart # Bottom Button Bar
│   │   │   ├── bottom_input_bars.dart  # Bottom Input Bar
│   │   │   └── bottom_home_bar.dart    # Bottom Home Bar (홈 화면 전용)
│   │   │
│   │   ├── components/                 # 재사용 컴포넌트
│   │   │   ├── app_component.dart      # 컴포넌트 통합 export
│   │   │   ├── app_button.dart         # 버튼 (4가지 variant)
│   │   │   ├── app_input.dart          # 입력 필드 (3가지 state)
│   │   │   ├── chat_bubble.dart        # 채팅 말풍선 (사용자/봇)
│   │   │   ├── system_bubble.dart      # 시스템 말풍선
│   │   │   ├── emotion_bubble.dart     # 감정 말풍선 (캐릭터 + 메시지)
│   │   │   ├── circular_ripple.dart    # 원형 파동 효과
│   │   │   ├── more_menu_sheet.dart    # 더보기 메뉴 시트
│   │   │   ├── slide_to_action_button.dart  # 슬라이드 액션 버튼
│   │   │   └── buttons.dart
│   │   │
│   │   ├── tokens/                     # 디자인 토큰
│   │   │   ├── app_tokens.dart         # 토큰 통합 export
│   │   │   ├── colors.dart             # 색상 (51개)
│   │   │   ├── typography.dart         # 타이포그래피 (10가지)
│   │   │   ├── spacing.dart            # 여백 (8단계)
│   │   │   ├── radius.dart             # 둥근 모서리 (4가지)
│   │   │   ├── icon_size.dart          # 아이콘 사이즈
│   │   │   ├── bubbles.dart            # 말풍선 토큰 (chat/system/emotion)
│   │   │   └── app_theme.dart          # 테마 설정
│   │   │
│   │   └── characters/                 # 감정 캐릭터
│   │       ├── app_characters.dart     # 정적 이미지 캐릭터
│   │       └── app_animations.dart     # Lottie 애니메이션 캐릭터 (✅ 신규)
│   │
│   ├── providers/                      # Riverpod 상태 관리
│   │   ├── auth_provider.dart          # 인증 provider
│   │   ├── chat_provider.dart          # 채팅 provider
│   │   └── daily_mood_provider.dart    # 일일 감정 체크 provider
│   │
│   ├── data/                           # 데이터 계층 (도메인별 분리)
│   │   ├── local/                      # 로컬 데이터
│   │   │   └── database/               # Drift 데이터베이스
│   │   │       ├── app_database.dart   # DB 정의 및 CRUD
│   │   │       └── app_database.g.dart # 자동 생성 파일
│   │   ├── models/                     # 도메인 모델
│   │   │   ├── auth/
│   │   │   └── alarm/                  # 알람 모델
│   │   ├── dtos/                       # API DTO
│   │   │   └── auth/                   
│   │   ├── api/                        # HTTP 클라이언트
│   │   │   └── auth/                   
│   │   └── repository/                 # 데이터 저장소
│   │       ├── auth/
│   │       └── alarm/                  # 알람 레포지토리                   
│   │
│   └── core/                           # 핵심 기능
│       ├── config/                     # 앱 설정
│       │   ├── api_config.dart         # API 엔드포인트
│       │   ├── app_routes.dart         # 라우트 설정
│       │   └── oauth_config.dart       # OAuth 설정
│       ├── utils/                      # 유틸리티
│       │   ├── logger.dart
│       │   ├── dio_interceptors.dart
│       │   └── emotion_classifier.dart # 감정 분류 유틸
│       └── services/                   # 서비스 (도메인별 분리)
│           ├── auth/                   # 인증 서비스
│           ├── chat/                   # 채팅 서비스
│           ├── alarm/                  # 알람 서비스
│           │   └── alarm_notification_service.dart
│           └── navigation/             # 네비게이션 서비스
│
├── debug/                              # 디버그 유틸리티
│   └── db_path_helper.dart             # DB 경로 확인 헬퍼
│
├── DESIGN_GUIDE.md                     
└── FRONTEND_GUIDE.md                   
```

---

## 🎨 디자인 시스템

### 📖 디자인 시스템 문서

**모든 UI 개발 시 [DESIGN_GUIDE.md](./DESIGN_GUIDE.md)를 필수로 참고하세요.**

디자인 가이드에는 다음 내용이 포함되어 있습니다:
- ✅ 디자인 토큰 (Colors, Typography, Spacing, Radius, Icons, Bubbles)
- ✅ Layout 시스템 (AppFrame, Top Bar, 3가지 Bottom Bar)
- ✅ 컴포넌트 사용법 (AppButton, AppInput, Bubbles, Voice, Ripple)
- ✅ 실제 사용 예시 (홈, 폼, 채팅 화면)
- ✅ Best Practices

** 컴포넌트 **:
- ✅ ChatBubble - 사용자/봇 채팅 말풍선
- ✅ SystemBubble - 시스템 메시지 (info/success/warning)
- ✅ EmotionBubble - 감정 말풍선 (캐릭터 + 메시지)
- ✅ VoiceWaveform - 음성 녹음 파동 애니메이션
- ✅ CircularRipple - 캐릭터 원형 파동 효과
- ✅ MoreMenuSheet - 더보기 메뉴 시트
- [x] SlideToActionButton - 슬라이드 액션 버튼
- [x] TopNotification - 상단 알림 배너 (Red/Green 테마)

** 캐릭터 **:
- ✅ EmotionCharacter - 정적 감정 캐릭터 (PNG, 17개)
- ✅ AnimatedCharacter - 애니메이션 감정 캐릭터 (Lottie, relief 4가지 감정)

### 빠른 시작

#### 1. UI 시스템 Import

```dart
import 'package:frontend/ui/app_ui.dart';
```

이 한 줄로 모든 디자인 시스템 요소 사용 가능:
- Layout (AppFrame, TopBar, BottomBar)
- Tokens (Colors, Typography, Spacing, Radius, Icons)
- Components (AppButton, AppInput 등)

#### 2. 화면 구성

**기본 화면:**
```dart
class NewScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppFrame(
      topBar: TopBar(
        title: '화면 제목',
        leftIcon: Icons.arrow_back,
        onTapLeft: () => Navigator.pop(context),
      ),
      bottomBar: BottomButtonBar(
        primaryText: '확인',
        onPrimaryTap: () => _save(),
      ),
      body: YourContent(),
    );
  }
}
```

**애니메이션 캐릭터 사용:**
```dart
// 봄이 화면에서 감정 캐릭터 애니메이션
AnimatedCharacter(
  characterId: 'relief',
  emotion: 'happiness',  // 'happiness', 'sadness', 'anger', 'fear'
  size: 350,
  repeat: true,
  animate: true,
)
```

#### 3. 디자인 토큰 사용

```dart
// ✅ 권장: 디자인 토큰 사용
Container(
  padding: EdgeInsets.all(AppSpacing.md),
  decoration: BoxDecoration(
    color: AppColors.bgBasic,
    borderRadius: BorderRadius.circular(AppRadius.md),
  ),
  child: Text(
    'Hello',
    style: AppTypography.h2,
  ),
)

// ❌ 비권장: 하드코딩
Container(
  padding: EdgeInsets.all(24),  // 하드코딩 ❌
  decoration: BoxDecoration(
    color: Color(0xFFFFFFFF),    // 하드코딩 ❌
    borderRadius: BorderRadius.circular(12),  // 하드코딩 ❌
  ),
)
```

---

## 🔌 API 및 상태 관리

### 아키텍처 개요

마음봄 앱은 **Clean Architecture** 원칙을 따르며, 다음과 같은 계층으로 구성됩니다:

```
UI Layer (Widgets)
    ↓
State Management (Riverpod Providers)
    ↓
Service Layer (Business Logic)
    ↓
Repository Layer (Data Abstraction)
    ↓
API Client Layer (HTTP Calls)
    ↓
Backend API (FastAPI)
```

### 프로젝트 구조 (도메인별 분리)

```
lib/
├── providers/                    # Riverpod 상태 관리
│   └── auth_provider.dart       # 인증 관련 provider
│
├── core/
│   ├── config/
│   │   ├── api_config.dart      # API 엔드포인트 설정
│   │   └── oauth_config.dart    # OAuth 설정
│   ├── services/
│   │   └── auth/                # 도메인별 서비스
│   │       ├── auth_service.dart
│   │       ├── token_storage_service.dart
│   │       ├── google_oauth_service.dart
│   │       ├── kakao_oauth_service.dart
│   │       └── naver_oauth_service.dart
│   └── utils/
│       ├── logger.dart
│       └── dio_interceptors.dart
│
└── data/
    ├── api/
    │   └── auth/                # 도메인별 API 클라이언트
    │       └── auth_api_client.dart
    ├── repository/
    │   └── auth/                # 도메인별 레포지토리
    │       └── auth_repository.dart
    ├── dtos/
    │   └── auth/                # 도메인별 DTO
    │       ├── google_login_request.dart
    │       ├── kakao_login_request.dart
    │       ├── naver_login_request.dart
    │       ├── token_response.dart
    │       └── user_response.dart
    └── models/
        └── auth/                # 도메인별 도메인 모델
            ├── user.dart
            └── token_pair.dart
```

### 1. 상태 관리 (Riverpod)

#### Provider 작성 예시

```dart
// lib/providers/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/auth/auth_service.dart';
import '../data/models/auth/user.dart';

// Infrastructure Providers
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

// Service Providers
final authServiceProvider = Provider<AuthService>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  final tokenStorage = ref.watch(tokenStorageServiceProvider);
  final googleOAuth = ref.watch(googleOAuthServiceProvider);

  return AuthService(repository, tokenStorage, googleOAuth);
});

// State Providers
class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AsyncValue.loading()) {
    _checkAuthStatus();
  }

  Future<void> loginWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      final user = await _authService.loginWithGoogle();
      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    state = const AsyncValue.data(null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  return AuthNotifier(ref.watch(authServiceProvider));
});

// Convenience Providers
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).value;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});
```

#### UI에서 Provider 사용

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          // 로그인 성공
          return HomeScreen();
        }
        // 로그인 화면
        return _buildLoginUI(ref);
      },
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => Text('Error: $error'),
    );
  }

  Widget _buildLoginUI(WidgetRef ref) {
    return AppButton(
      text: 'Google 로그인',
      onTap: () async {
        await ref.read(authProvider.notifier).loginWithGoogle();
      },
    );
  }
}
```

### 2. Service Layer

서비스는 비즈니스 로직을 담당하며, Repository와 OAuth 서비스를 조율합니다.

```dart
// lib/core/services/auth/auth_service.dart
class AuthService {
  final AuthRepository _repository;
  final TokenStorageService _tokenStorage;
  final GoogleOAuthService _googleOAuth;

  Future<User> loginWithGoogle() async {
    // 1. OAuth로 authCode 획득
    final authCode = await _googleOAuth.signIn();

    // 2. Backend API로 authCode 전송하여 토큰 받기
    final (tokens, user) = await _repository.loginWithGoogle(
      authCode: authCode,
      redirectUri: OAuthConfig.googleRedirectUri,
    );

    // 3. 토큰 안전하게 저장
    await _tokenStorage.saveTokens(tokens);

    return user;
  }

  Future<void> logout() async {
    final accessToken = await _tokenStorage.getAccessToken();
    if (accessToken != null) {
      await _repository.logout(accessToken);
    }
    await _tokenStorage.clearTokens();
    await _googleOAuth.signOut();
  }
}
```

### 3. Repository Layer

Repository는 데이터 소스를 추상화하며, API Client를 래핑합니다.

```dart
// lib/data/repository/auth/auth_repository.dart
class AuthRepository {
  final AuthApiClient _apiClient;

  Future<(TokenPair, User)> loginWithGoogle({
    required String authCode,
    required String redirectUri,
  }) async {
    final request = GoogleLoginRequest(
      authCode: authCode,
      redirectUri: redirectUri,
    );

    final tokenResponse = await _apiClient.googleLogin(request);

    final tokenPair = TokenPair(
      accessToken: tokenResponse.accessToken,
      refreshToken: tokenResponse.refreshToken,
    );

    final userResponse = await _apiClient.getCurrentUser(
      tokenResponse.accessToken,
    );

    final user = User(
      id: userResponse.id,
      email: userResponse.email,
      nickname: userResponse.nickname,
    );

    return (tokenPair, user);
  }
}
```

### 4. API Client Layer

API Client는 실제 HTTP 요청을 처리합니다.

```dart
// lib/data/api/auth/auth_api_client.dart
import 'package:dio/dio.dart';
import '../../../core/config/api_config.dart';
import '../../dtos/auth/google_login_request.dart';
import '../../dtos/auth/token_response.dart';

class AuthApiClient {
  final Dio _dio;

  Future<TokenResponse> googleLogin(GoogleLoginRequest request) async {
    try {
      final response = await _dio.post(
        ApiConfig.googleLogin,
        data: request.toJson(),
      );
      return TokenResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException e) {
    if (e.response != null) {
      final message = e.response!.data?['detail'] ?? 'Unknown error';
      return Exception('API Error: $message');
    }
    return Exception('Network error: ${e.message}');
  }
}
```

### 5. DTO (Data Transfer Objects)

DTO는 API 요청/응답 데이터를 직렬화/역직렬화합니다.

```dart
// lib/data/dtos/auth/google_login_request.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'google_login_request.freezed.dart';
part 'google_login_request.g.dart';

@freezed
class GoogleLoginRequest with _$GoogleLoginRequest {
  const factory GoogleLoginRequest({
    required String authCode,
    required String redirectUri,
  }) = _GoogleLoginRequest;

  factory GoogleLoginRequest.fromJson(Map<String, dynamic> json) =>
      _$GoogleLoginRequestFromJson(json);
}
```

**코드 생성:**
```bash
dart run build_runner build --delete-conflicting-outputs
```

### 6. Domain Models

도메인 모델은 앱 내부에서 사용하는 비즈니스 객체입니다.

```dart
// lib/data/models/auth/user.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';

@freezed
class User with _$User {
  const factory User({
    required int id,
    required String email,
    required String nickname,
    required String provider,
    required DateTime createdAt,
  }) = _User;
}
```

### 새로운 기능 추가 가이드

#### 예시: Survey 기능 추가

**1. 폴더 구조 생성**
```bash
lib/
├── providers/
│   └── survey_provider.dart
├── core/services/
│   └── survey/
│       └── survey_service.dart
└── data/
    ├── api/survey/
    │   └── survey_api_client.dart
    ├── repository/survey/
    │   └── survey_repository.dart
    ├── dtos/survey/
    │   ├── survey_request.dart
    │   └── survey_response.dart
    └── models/survey/
        └── survey.dart
```

**2. API Config 추가**
```dart
// lib/core/config/api_config.dart
class ApiConfig {
  static const String baseUrl = 'http://localhost:8000';

  // Survey Endpoints
  static const String surveyBase = '/survey';
  static const String submitSurvey = '$surveyBase/submit';
  static const String getSurveys = '$surveyBase/list';
}
```

**3. DTO 작성**
```dart
// lib/data/dtos/survey/survey_request.dart
@freezed
class SurveyRequest with _$SurveyRequest {
  const factory SurveyRequest({
    required List<Answer> answers,
  }) = _SurveyRequest;

  factory SurveyRequest.fromJson(Map<String, dynamic> json) =>
      _$SurveyRequestFromJson(json);
}
```

**4. API Client 작성**
```dart
// lib/data/api/survey/survey_api_client.dart
class SurveyApiClient {
  final Dio _dio;

  Future<SurveyResponse> submitSurvey(SurveyRequest request) async {
    final response = await _dio.post(
      ApiConfig.submitSurvey,
      data: request.toJson(),
    );
    return SurveyResponse.fromJson(response.data);
  }
}
```

**5. Repository 작성**
```dart
// lib/data/repository/survey/survey_repository.dart
class SurveyRepository {
  final SurveyApiClient _apiClient;

  Future<Survey> submitSurvey(List<Answer> answers) async {
    final request = SurveyRequest(answers: answers);
    final response = await _apiClient.submitSurvey(request);

    return Survey(
      id: response.id,
      result: response.result,
    );
  }
}
```

**6. Service 작성**
```dart
// lib/core/services/survey/survey_service.dart
class SurveyService {
  final SurveyRepository _repository;

  Future<Survey> submitSurvey(List<Answer> answers) async {
    // 비즈니스 로직
    if (answers.isEmpty) {
      throw Exception('답변이 없습니다');
    }

    return await _repository.submitSurvey(answers);
  }
}
```

**7. Provider 작성**
```dart
// lib/providers/survey_provider.dart
final surveyServiceProvider = Provider<SurveyService>((ref) {
  final repository = ref.watch(surveyRepositoryProvider);
  return SurveyService(repository);
});

class SurveyNotifier extends StateNotifier<AsyncValue<Survey?>> {
  final SurveyService _service;

  SurveyNotifier(this._service) : super(const AsyncValue.data(null));

  Future<void> submitSurvey(List<Answer> answers) async {
    state = const AsyncValue.loading();
    try {
      final survey = await _service.submitSurvey(answers);
      state = AsyncValue.data(survey);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final surveyProvider = StateNotifierProvider<SurveyNotifier, AsyncValue<Survey?>>((ref) {
  return SurveyNotifier(ref.watch(surveyServiceProvider));
});
```

**8. UI에서 사용**
```dart
class SurveyScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surveyState = ref.watch(surveyProvider);

    return surveyState.when(
      data: (survey) => _buildContent(ref, survey),
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => Text('Error: $error'),
    );
  }

  Widget _buildContent(WidgetRef ref, Survey? survey) {
    return AppButton(
      text: '제출',
      onTap: () async {
        final answers = _getAnswers();
        await ref.read(surveyProvider.notifier).submitSurvey(answers);
      },
    );
  }
}
```

### 자동 토큰 관리 (Dio Interceptor)

Dio Interceptor를 통해 자동으로 토큰을 추가하고 갱신합니다:

```dart
// lib/core/utils/dio_interceptors.dart
class AuthInterceptor extends Interceptor {
  final AuthService _authService;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // 자동으로 Authorization 헤더 추가
    final accessToken = await _authService.getAccessToken();
    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // 401 에러 시 자동 토큰 갱신
    if (err.response?.statusCode == 401) {
      try {
        await _authService.refreshToken();

        // 재시도
        final accessToken = await _authService.getAccessToken();
        err.requestOptions.headers['Authorization'] = 'Bearer $accessToken';

        final response = await _dio.fetch(err.requestOptions);
        return handler.resolve(response);
      } catch (e) {
        // 갱신 실패 시 로그아웃
        await _authService.logout();
      }
    }
    handler.next(err);
  }
}
```

### Best Practices

#### ✅ 권장

```dart
// 1. Provider는 providers/ 폴더에
final authProvider = StateNotifierProvider...

// 2. 도메인별로 폴더 분리
lib/core/services/auth/
lib/data/api/auth/
lib/data/repository/auth/

// 3. Freezed 사용 (불변 객체)
@freezed
class User with _$User { ... }

// 4. AsyncValue로 로딩/에러 상태 관리
state.when(
  data: (data) => ...,
  loading: () => ...,
  error: (error, stack) => ...,
)

// 5. 에러 핸들링
try {
  await apiClient.getData();
} on DioException catch (e) {
  throw _handleError(e);
}
```

#### ❌ 비권장

```dart
// 1. UI에서 직접 API 호출 ❌
final response = await http.get('http://localhost:8000/api/data');

// 2. 하드코딩된 URL ❌
await dio.get('http://localhost:8000/api/data');

// 3. 토큰 수동 관리 ❌
final token = await storage.read('token');
headers['Authorization'] = 'Bearer $token';

// 4. 에러 무시 ❌
try {
  await apiCall();
} catch (e) {
  // 아무것도 안 함
}
```

---

## 💾 로컬 데이터베이스 (Drift)

### 개요

마음봄 앱은 로컬 데이터 저장을 위해 **Drift** (구 Moor)를 사용합니다.

Drift는 SQLite 기반의 타입 안전한 ORM으로, Flutter에서 로컬 데이터베이스를 쉽게 관리할 수 있게 해줍니다.

### 주요 특징

- ✅ **타입 안전**: 컴파일 타임에 SQL 오류 감지
- ✅ **자동 코드 생성**: build_runner로 CRUD 코드 자동 생성
- ✅ **Reactive Streams**: 데이터 변경 시 자동 UI 업데이트
- ✅ **마이그레이션**: 스키마 버전 관리 지원
- ✅ **백엔드 규칙 준수**: 테이블명, 컬럼명 등 백엔드 DB 규칙 적용

### 프로젝트 구조

```
lib/
├── data/
│   ├── local/
│   │   └── database/
│   │       ├── app_database.dart      # DB 정의 및 CRUD
│   │       └── app_database.g.dart    # 자동 생성 파일 (build_runner)
│   ├── models/
│   │   └── alarm/
│   │       ├── alarm_model.dart       # 도메인 모델 (Freezed)
│   │       ├── alarm_model.freezed.dart
│   │       └── alarm_model.g.dart
│   └── repository/
│       └── alarm/
│           └── alarm_repository.dart  # Repository 계층
├── providers/
│   └── alarm_provider.dart            # Riverpod Provider
└── debug/
    └── db_path_helper.dart            # DB 경로 확인 헬퍼
```

### 1. 데이터베이스 정의

#### 테이블 정의 (app_database.dart)

```dart
// lib/data/local/database/app_database.dart
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

/// 테이블 정의
/// 백엔드 DB 규칙 준수: TB_ 접두사, 대문자 컬럼명
@DataClassName('AlarmData')
class Alarms extends Table {
  @override
  String get tableName => 'TB_ALARMS';

  // Primary Key
  IntColumn get id => integer().autoIncrement()();

  // 비즈니스 컬럼
  IntColumn get year => integer()();
  IntColumn get month => integer()();
  IntColumn get day => integer()();
  TextColumn get week => text()(); // JSON 배열
  IntColumn get time => integer()();
  IntColumn get minute => integer()();
  TextColumn get amPm => text().withLength(min: 2, max: 2)();
  
  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();
  IntColumn get notificationId => integer()();
  DateTimeColumn get scheduledDatetime => dateTime()();

  // 표준 필드 (백엔드 규칙)
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get createdBy => integer().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get updatedBy => integer().nullable()();

  @override
  List<String> get customConstraints => [
    'UNIQUE(notification_id)',
  ];
}

/// 데이터베이스 클래스
@DriftDatabase(tables: [Alarms])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // CRUD 메서드
  Future<List<AlarmData>> getAllAlarms() {
    return (select(alarms)
      ..where((tbl) => tbl.isDeleted.equals(false))
      ..orderBy([(t) => OrderingTerm.asc(t.scheduledDatetime)]))
      .get();
  }

  Future<int> insertAlarm(AlarmsCompanion alarm) {
    return into(alarms).insert(alarm);
  }

  Future<int> updateAlarm(int id, AlarmsCompanion alarm) {
    return (update(alarms)..where((tbl) => tbl.id.equals(id))).write(alarm);
  }

  Future<int> deleteAlarm(int id, {int? userId}) {
    return (update(alarms)..where((tbl) => tbl.id.equals(id))).write(
      AlarmsCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(DateTime.now()),
        updatedBy: Value(userId),
      ),
    );
  }
}

/// DB 연결 설정
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'maeumbom.db'));
    return NativeDatabase(file);
  });
}
```

#### 코드 생성

```bash
# Drift 코드 생성
flutter pub run build_runner build --delete-conflicting-outputs

# 또는 watch 모드 (자동 재생성)
flutter pub run build_runner watch
```

### 2. 도메인 모델 (Freezed)

```dart
// lib/data/models/alarm/alarm_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:drift/drift.dart' hide JsonKey;
import '../../local/database/app_database.dart';

part 'alarm_model.freezed.dart';
part 'alarm_model.g.dart';

@freezed
class AlarmModel with _$AlarmModel {
  const AlarmModel._();

  const factory AlarmModel({
    required int id,
    required int year,
    required int month,
    required int day,
    required List<String> week,
    required int time,
    required int minute,
    required String amPm,
    required bool isEnabled,
    required DateTime scheduledDatetime,
    // ... 기타 필드
  }) = _AlarmModel;

  // Drift → Model
  factory AlarmModel.fromDrift(AlarmData data) {
    return AlarmModel(
      id: data.id,
      year: data.year,
      // ... 매핑
    );
  }

  // Model → Drift Companion
  AlarmsCompanion toCompanion({int? userId}) {
    return AlarmsCompanion.insert(
      year: year,
      month: month,
      // ... 매핑
      createdBy: Value(userId),
      updatedBy: Value(userId),
    );
  }

  // Helper getters
  String get timeString => '$time:${minute.toString().padLeft(2, '0')} ${amPm.toUpperCase()}';
}
```

### 3. Repository 계층

```dart
// lib/data/repository/alarm/alarm_repository.dart
import '../../local/database/app_database.dart';
import '../../models/alarm/alarm_model.dart';

class AlarmRepository {
  final AppDatabase _database;

  AlarmRepository(this._database);

  // 조회
  Future<List<AlarmModel>> getAllAlarms() async {
    final alarmDataList = await _database.getAllAlarms();
    return alarmDataList.map((data) => AlarmModel.fromDrift(data)).toList();
  }

  // 삽입
  Future<int> insertAlarm(AlarmModel alarm, {int? userId}) async {
    return await _database.insertAlarm(alarm.toCompanion(userId: userId));
  }

  // 수정
  Future<void> updateAlarm(AlarmModel alarm, {int? userId}) async {
    await _database.updateAlarm(
      alarm.id,
      alarm.toCompanion(userId: userId),
    );
  }

  // 삭제 (소프트 삭제)
  Future<void> deleteAlarm(int id, {int? userId}) async {
    await _database.deleteAlarm(id, userId: userId);
  }
}
```

### 4. Provider 연동

```dart
// lib/providers/alarm_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/local/database/app_database.dart';
import '../data/repository/alarm/alarm_repository.dart';
import '../data/models/alarm/alarm_model.dart';

// Database Provider
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

// Repository Provider
final alarmRepositoryProvider = Provider<AlarmRepository>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return AlarmRepository(database);
});

// State Notifier
class AlarmNotifier extends StateNotifier<List<AlarmModel>> {
  final AlarmRepository _repository;

  AlarmNotifier(this._repository) : super([]) {
    loadAlarms();
  }

  Future<void> loadAlarms() async {
    final alarms = await _repository.getAllAlarms();
    state = alarms;
  }

  Future<void> addAlarm(AlarmModel alarm) async {
    await _repository.insertAlarm(alarm);
    await loadAlarms();
  }

  Future<void> deleteAlarm(int id) async {
    await _repository.deleteAlarm(id);
    await loadAlarms();
  }
}

// Provider
final alarmProvider = StateNotifierProvider<AlarmNotifier, List<AlarmModel>>((ref) {
  final repository = ref.watch(alarmRepositoryProvider);
  return AlarmNotifier(repository);
});
```

### 5. UI에서 사용

```dart
// lib/app/alarm/alarm_screen.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/alarm_provider.dart';

class AlarmScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alarms = ref.watch(alarmProvider);

    return AppFrame(
      body: ListView.builder(
        itemCount: alarms.length,
        itemBuilder: (context, index) {
          final alarm = alarms[index];
          return ListTile(
            title: Text(alarm.timeString),
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () async {
                await ref.read(alarmProvider.notifier).deleteAlarm(alarm.id);
                
                TopNotificationManager.show(
                  context,
                  message: '알람이 삭제되었습니다.',
                  type: TopNotificationType.red,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
```

### 6. DB 파일 위치 확인

```dart
// lib/debug/db_path_helper.dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class DbPathHelper {
  static Future<void> printDbPath() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'maeumbom.db'));
    
    print('═══════════════════════════════════════');
    print('📂 DB File Location:');
    print('   ${file.path}');
    print('═══════════════════════════════════════');
    print('📊 DB File Info:');
    print('   Exists: ${file.existsSync()}');
    if (file.existsSync()) {
      print('   Size: ${file.lengthSync()} bytes');
    }
    print('═══════════════════════════════════════');
  }
}
```

```dart
// lib/main.dart
import 'debug/db_path_helper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 🔍 DB 경로 출력 (디버그용)
  await DbPathHelper.printDbPath();
  
  runApp(const ProviderScope(child: MaeumBomApp()));
}
```

### 플랫폼별 DB 위치

#### iOS (시뮬레이터)
```
~/Library/Developer/CoreSimulator/Devices/[DEVICE_ID]/data/Containers/Data/Application/[APP_ID]/Documents/maeumbom.db
```

#### Android
```
/data/data/com.example.maeumbom/app_flutter/maeumbom.db
```

### DB 확인 방법

#### 1. SQLite CLI
```bash
# 터미널에서 출력된 경로 복사 후
sqlite3 "/경로/maeumbom.db"

# 테이블 확인
.tables

# 데이터 조회
SELECT * FROM TB_ALARMS;

# 종료
.quit
```

#### 2. DB Browser for SQLite (추천)
1. [DB Browser for SQLite](https://sqlitebrowser.org/) 다운로드
2. 앱 실행 후 출력된 경로의 `maeumbom.db` 파일 열기
3. GUI로 데이터 확인 및 수정

### 백엔드 DB 규칙 준수

마음봄 프로젝트는 프론트엔드와 백엔드의 일관성을 위해 동일한 DB 규칙을 따릅니다.

#### 명명 규칙

```dart
// ✅ 테이블명: TB_ 접두사 + 대문자
@override
String get tableName => 'TB_ALARMS';

// ✅ 컬럼명: 대문자 스네이크 케이스 (Drift가 자동 변환)
IntColumn get year => integer()();        // → YEAR
TextColumn get amPm => text()();          // → AM_PM
BoolColumn get isDeleted => boolean()();  // → IS_DELETED
```

#### 표준 필드

모든 테이블에 다음 필드를 포함해야 합니다:

```dart
BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
IntColumn get createdBy => integer().nullable()();
DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
IntColumn get updatedBy => integer().nullable()();
```

### 마이그레이션

스키마 변경 시:

```dart
@DriftDatabase(tables: [Alarms, NewTable])
class AppDatabase extends _$AppDatabase {
  @override
  int get schemaVersion => 2; // 버전 증가

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from == 1) {
          // 버전 1 → 2 마이그레이션
          await m.addColumn(alarms, alarms.newColumn);
        }
      },
    );
  }
}
```

### Best Practices

#### ✅ 권장

```dart
// 1. 소프트 삭제 사용
Future<void> deleteAlarm(int id) {
  return (update(alarms)..where((tbl) => tbl.id.equals(id))).write(
    AlarmsCompanion(isDeleted: const Value(true)),
  );
}

// 2. Repository 계층 사용
final repository = ref.watch(alarmRepositoryProvider);
await repository.insertAlarm(alarm);

// 3. 도메인 모델과 Drift 분리
AlarmModel.fromDrift(alarmData)  // Drift → Model
alarm.toCompanion()              // Model → Drift

// 4. Provider로 상태 관리
final alarms = ref.watch(alarmProvider);
```

#### ❌ 비권장

```dart
// 1. UI에서 직접 DB 접근 ❌
final database = AppDatabase();
await database.insertAlarm(...);

// 2. 하드 삭제 ❌
await (delete(alarms)..where((tbl) => tbl.id.equals(id))).go();

// 3. 표준 필드 누락 ❌
class MyTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  // isDeleted, createdAt 등 누락 ❌
}
```

### 참고 문서

- **[Drift 공식 문서](https://drift.simonbinder.eu/)** - 상세 API 가이드
- **[backend/DB_GUIDE.md](../../backend/DB_GUIDE.md)** - 백엔드 DB 규칙
- **구현 파일**: `lib/data/local/database/app_database.dart`

---

## 📢 사용자 피드백 (TopNotification)

### 개요

화면 개발 시 사용자에게 작업 결과나 상태를 알려야 할 때는 **TopNotification**을 사용하세요.

Flutter의 기본 `SnackBar` 대신 디자인 시스템에 정의된 `TopNotification`을 사용하면 일관된 UX를 제공할 수 있습니다.

### 언제 사용하나요?

- ✅ 데이터 저장/수정/삭제 완료 시
- ✅ API 요청 성공/실패 시
- ✅ 폼 제출 결과 알림
- ✅ 중요한 상태 변경 알림
- ✅ 사용자 액션에 대한 즉각적인 피드백

### 기본 사용법

```dart
import '../../ui/app_ui.dart';

// ✅ 성공 메시지 (녹색)
TopNotificationManager.show(
  context,
  message: '알람이 설정되었습니다.',
  type: TopNotificationType.green,
  duration: const Duration(milliseconds: 2000),
);

// ✅ 경고/삭제 메시지 (빨간색)
TopNotificationManager.show(
  context,
  message: '알람이 삭제되었습니다.',
  type: TopNotificationType.red,
  duration: const Duration(milliseconds: 2000),
);

// ✅ 실행취소 액션 포함
TopNotificationManager.show(
  context,
  message: '알람이 삭제되었습니다.',
  actionLabel: '실행취소',
  type: TopNotificationType.red,
  onActionTap: () {
    // 실행취소 로직
    _undoDelete();
  },
);
```

### 타입별 사용 가이드

#### 🟢 Green (성공, 완료)

```dart
// 데이터 저장 성공
TopNotificationManager.show(
  context,
  message: '저장되었습니다.',
  type: TopNotificationType.green,
);

// 설정 변경 완료
TopNotificationManager.show(
  context,
  message: '설정이 변경되었습니다.',
  type: TopNotificationType.green,
);

// 업로드 완료
TopNotificationManager.show(
  context,
  message: '파일이 업로드되었습니다.',
  type: TopNotificationType.green,
);
```

#### 🔴 Red (경고, 삭제, 중요 알림)

```dart
// 삭제 완료
TopNotificationManager.show(
  context,
  message: '항목이 삭제되었습니다.',
  type: TopNotificationType.red,
);

// 오류 발생
TopNotificationManager.show(
  context,
  message: '오류가 발생했습니다. 다시 시도해주세요.',
  type: TopNotificationType.red,
);

// 중요한 경고
TopNotificationManager.show(
  context,
  message: '네트워크 연결을 확인해주세요.',
  type: TopNotificationType.red,
);
```

### 실전 예시

#### 예시 1: 폼 제출

```dart
class ProfileEditScreen extends ConsumerWidget {
  Future<void> _saveProfile(WidgetRef ref) async {
    try {
      await ref.read(profileProvider.notifier).updateProfile(profileData);
      
      // ✅ 성공 피드백
      TopNotificationManager.show(
        context,
        message: '프로필이 저장되었습니다.',
        type: TopNotificationType.green,
      );
      
      Navigator.pop(context);
    } catch (e) {
      // ❌ 실패 피드백
      TopNotificationManager.show(
        context,
        message: '저장에 실패했습니다. 다시 시도해주세요.',
        type: TopNotificationType.red,
      );
    }
  }
}
```

#### 예시 2: 삭제 with 실행취소

```dart
class AlarmScreen extends ConsumerWidget {
  Future<void> _deleteAlarm(WidgetRef ref, int alarmId) async {
    // 임시로 삭제된 알람 저장
    final deletedAlarm = alarms.firstWhere((a) => a.id == alarmId);
    
    // 삭제 실행
    await ref.read(alarmProvider.notifier).deleteAlarm(alarmId);
    
    // ✅ 실행취소 가능한 피드백
    TopNotificationManager.show(
      context,
      message: '알람이 삭제되었습니다.',
      actionLabel: '실행취소',
      type: TopNotificationType.red,
      onActionTap: () async {
        // 실행취소 로직
        await ref.read(alarmProvider.notifier).restoreAlarm(deletedAlarm);
        
        TopNotificationManager.show(
          context,
          message: '알람이 복구되었습니다.',
          type: TopNotificationType.green,
        );
      },
    );
  }
}
```

#### 예시 3: API 요청 결과

```dart
class SurveyScreen extends ConsumerWidget {
  Future<void> _submitSurvey(WidgetRef ref) async {
    final surveyState = await ref.read(surveyProvider.notifier).submitSurvey(answers);
    
    surveyState.when(
      data: (result) {
        // ✅ 성공
        TopNotificationManager.show(
          context,
          message: '설문이 제출되었습니다.',
          type: TopNotificationType.green,
        );
      },
      error: (error, stack) {
        // ❌ 실패
        TopNotificationManager.show(
          context,
          message: '제출에 실패했습니다.',
          type: TopNotificationType.red,
        );
      },
      loading: () {},
    );
  }
}
```

### ❌ 비권장: SnackBar 사용

```dart
// ❌ 비권장: Flutter 기본 SnackBar
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('저장되었습니다.'),
    backgroundColor: Colors.green,
  ),
);

// ✅ 권장: TopNotification 사용
TopNotificationManager.show(
  context,
  message: '저장되었습니다.',
  type: TopNotificationType.green,
);
```

### 주요 특징

#### 1. 일관된 디자인
- 디자인 시스템 색상 자동 적용 (`AppColors.accentRed`, `AppColors.natureGreen`)
- 통일된 위치 (TopBar 바로 아래)
- 일관된 애니메이션

#### 2. 자동 관리
- 2초 후 자동 닫힘 (duration 조정 가능)
- 새 알림 표시 시 이전 알림 자동 제거
- 오버레이 기반으로 어떤 화면에서도 사용 가능

#### 3. 접근성
- 명확한 메시지 전달
- 선택적 액션 버튼 (실행취소 등)
- 시각적으로 눈에 잘 띄는 위치

### 파라미터 상세

```dart
TopNotificationManager.show(
  BuildContext context,           // 필수: BuildContext
  {
    required String message,      // 필수: 표시할 메시지
    String? actionLabel,          // 선택: 액션 버튼 텍스트
    VoidCallback? onActionTap,    // 선택: 액션 버튼 콜백
    TopNotificationType type,     // 선택: red(기본) 또는 green
    Duration duration,            // 선택: 표시 시간 (기본 2000ms)
  }
)
```

### Best Practices

#### ✅ 권장

```dart
// 1. 짧고 명확한 메시지
TopNotificationManager.show(
  context,
  message: '저장되었습니다.',
  type: TopNotificationType.green,
);

// 2. 적절한 타입 선택
// - 성공/완료 → green
// - 삭제/경고/오류 → red

// 3. 중요한 삭제 시 실행취소 제공
TopNotificationManager.show(
  context,
  message: '삭제되었습니다.',
  actionLabel: '실행취소',
  type: TopNotificationType.red,
  onActionTap: () => _undo(),
);

// 4. try-catch와 함께 사용
try {
  await saveData();
  TopNotificationManager.show(context, message: '저장 완료', type: TopNotificationType.green);
} catch (e) {
  TopNotificationManager.show(context, message: '저장 실패', type: TopNotificationType.red);
}
```

#### ❌ 비권장

```dart
// 1. 너무 긴 메시지 ❌
TopNotificationManager.show(
  context,
  message: '사용자의 프로필 정보가 성공적으로 서버에 저장되었으며 이제 다른 사용자들도 볼 수 있습니다.',
  type: TopNotificationType.green,
);

// 2. 중복 호출 ❌
TopNotificationManager.show(context, message: '첫 번째');
TopNotificationManager.show(context, message: '두 번째'); // 첫 번째가 즉시 사라짐

// 3. 불필요한 알림 남발 ❌
// 모든 작은 액션마다 알림을 표시하지 마세요
```

### 참고 문서

- **[DESIGN_GUIDE.md - TopNotification](./DESIGN_GUIDE.md#93-topnotification)** - 디자인 상세 가이드
- **구현 파일**: `lib/ui/components/top_notification.dart`

---

## 🔨 개발 워크플로우

### 새로운 화면 추가

#### 1. 폴더 구조 생성

```bash
lib/app/
└── feature_name/
    └── feature_screen.dart
```

#### 2. 화면 파일 작성

```dart
import 'package:flutter/material.dart';
import '../../ui/app_ui.dart';

class FeatureScreen extends StatelessWidget {
  const FeatureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppFrame(
      topBar: TopBar(
        title: '기능 이름',
        leftIcon: Icons.arrow_back,
        onTapLeft: () => Navigator.pop(context),
      ),
      bottomBar: BottomMenuBar(
        currentIndex: 0,
        onTap: (index) {
          // 탭 전환 로직
        },
      ),
      body: const FeatureContent(),
    );
  }
}

class FeatureContent extends StatelessWidget {
  const FeatureContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Text(
            '화면 내용',
            style: AppTypography.h2,
          ),
          SizedBox(height: AppSpacing.lg),
          AppButton(
            text: '액션',
            variant: ButtonVariant.primaryRed,
          ),
        ],
      ),
    );
  }
}
```

#### 3. 라우팅 추가

앱의 모든 라우트는 `lib/core/config/app_routes.dart`에서 중앙 관리됩니다. 새로운 페이지를 추가할 때는 이 파일만 수정하면 됩니다.

##### AppRoutes에 라우트 추가

`lib/core/config/app_routes.dart` 파일을 열고:

**공개 경로 (인증 불필요)인 경우:**

```dart
static const RouteMetadata newScreen = RouteMetadata(
  routeName: '/new-screen',
  builder: NewScreen.new,
  // requiresAuth는 기본값 false이므로 생략 가능
);
```

**보호된 경로 (인증 필요)인 경우:**

```dart
static const RouteMetadata newScreen = RouteMetadata(
  routeName: '/new-screen',
  builder: NewScreen.new,
  requiresAuth: true, // 인증 필요
);
```

**탭 메뉴에 표시되는 경우:**

```dart
static const RouteMetadata newScreen = RouteMetadata(
  routeName: '/new-screen',
  builder: NewScreen.new,
  requiresAuth: true,
  tabIndex: 5, // 탭 메뉴 인덱스
);
```

**allRoutes에 추가:**

```dart
static const List<RouteMetadata> allRoutes = [
  home,
  alarm,
  chat,
  report,
  mypage,
  login,
  example,
  newScreen, // 여기에 추가
];
```

##### 사용하기

**탭 메뉴에서 접근하는 경우:**

`NavigationService`가 자동으로 인증을 체크하고 라우팅합니다:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/navigation/navigation_service.dart';

class FeatureScreen extends ConsumerWidget {
  const FeatureScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationService = NavigationService(context, ref);

    return AppFrame(
      bottomBar: BottomMenuBar(
        currentIndex: 5,
        onTap: (index) {
          navigationService.navigateToTab(index); // tabIndex로 접근
        },
      ),
      // ...
    );
  }
}
```

**직접 경로로 접근하는 경우:**

```dart
final navigationService = NavigationService(context, ref);
navigationService.navigateToRoute('/new-screen');
```

**RouteMetadata 속성:**

- `routeName`: 경로 이름 (예: `/chat`)
- `builder`: 화면 위젯을 생성하는 함수
- `requiresAuth`: 인증이 필요한지 여부 (기본값: `false`)
- `tabIndex`: 탭 메뉴에 표시되는 경우 인덱스 (선택사항)

**참고:** `main.dart`에서 `AppRoutes.toMaterialRoutes()`를 사용하면 자동으로 모든 라우트가 등록됩니다. 별도로 `routes` 맵을 수정할 필요가 없습니다.



## 📐 코딩 컨벤션

### 파일 명명 규칙

```
화면:    feature_screen.dart
위젯:    feature_content.dart
모델:    feature_model.dart
서비스:  feature_service.dart
```

### 클래스 명명 규칙

```dart
// 화면 위젯
class HomeScreen extends StatelessWidget { }

// 재사용 위젯
class CustomCard extends StatelessWidget { }

// 상태 관리 위젯
class CounterWidget extends StatefulWidget { }
```

### Import 순서

```dart
// 1. Dart SDK
import 'dart:async';

// 2. Flutter SDK
import 'package:flutter/material.dart';

// 3. 외부 패키지
import 'package:provider/provider.dart';

// 4. 내부 패키지
import 'package:frontend/ui/app_ui.dart';
import 'package:frontend/data/models/user.dart';

// 5. 상대 경로
import '../widgets/custom_card.dart';
```

### 주석 작성

```dart
/// 사용자 프로필 화면
///
/// 사용자의 정보를 표시하고 수정할 수 있는 화면입니다.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 복잡한 로직에만 주석 추가
    final user = _getCurrentUser();

    return AppFrame(
      topBar: TopBar(
        title: '프로필',
        leftIcon: Icons.arrow_back,
        onTapLeft: () => Navigator.pop(context),
      ),
      body: _buildContent(user),
    );
  }
}
```

### Best Practices

#### ✅ 권장

```dart
// 1. const 사용
const Text('Hello')
const SizedBox(height: AppSpacing.md)

// 2. 디자인 토큰 사용
padding: EdgeInsets.all(AppSpacing.md)
color: AppColors.textPrimary

// 3. 위젯 분리
body: const ProfileContent()  // 별도 위젯으로 분리

// 4. 명확한 변수명
final userName = user.name;
final isLoggedIn = authState.isAuthenticated;
```

#### ❌ 비권장

```dart
// 1. 하드코딩된 값
padding: EdgeInsets.all(24)  // ❌
color: Color(0xFF233446)     // ❌

// 2. 거대한 build 메서드
Widget build(BuildContext context) {
  return Column(
    children: [
      // 200줄 이상의 코드...  ❌
    ],
  );
}

// 3. 불명확한 변수명
final x = user.name;  // ❌
final flag = true;    // ❌
```

---

## 🔍 문제 해결

### 자주 발생하는 문제

#### 1. "Top Bar가 상태 바를 침범해요"

✅ **해결**: AppFrame이 자동으로 SafeArea를 적용합니다. AppFrame을 사용하세요.

```dart
// ✅ 올바름
AppFrame(
  topBar: TopBar(
    title: '제목',
    leftIcon: Icons.arrow_back,
    onTapLeft: () => Navigator.pop(context),
  ),
  body: content,
)

// ❌ 잘못됨
Scaffold(
  appBar: TopBar(...),  // SafeArea 미적용
  body: content,
)
```

#### 2. "Bottom Bar가 홈 인디케이터를 가려요"

✅ **해결**: 모든 Bottom Bar가 자동으로 홈 인디케이터 여백을 계산합니다.

```dart
// ✅ 올바름 - 자동으로 여백 추가됨
BottomMenuBar(...)
BottomButtonBar(...)
BottomInputBar(...)
```

#### 3. "Top Bar 아이콘을 어떻게 설정하나요?"

✅ **사용 가이드**:

```dart
// 타이틀만
TopBar(title: '설정')

// 뒤로가기 + 타이틀
TopBar(
  title: '상세',
  leftIcon: Icons.arrow_back,
  onTapLeft: () => Navigator.pop(context),
)

// 타이틀 + 더보기
TopBar(
  title: '홈',
  rightIcon: Icons.more_horiz,
  onTapRight: () => _showMenu(),
)

// 뒤로가기 + 타이틀 + 설정
TopBar(
  title: '채팅',
  leftIcon: Icons.arrow_back,
  rightIcon: Icons.settings,
  onTapLeft: () => Navigator.pop(context),
  onTapRight: () => _showOptions(),
)
```

#### 4. "디자인 토큰을 찾을 수 없어요"

✅ **해결**: [DESIGN_GUIDE.md](./DESIGN_GUIDE.md)의 디자인 토큰 섹션 참고

```dart
// Colors
AppColors.accentRed
AppColors.textPrimary

// Typography
AppTypography.h2
AppTypography.body

// Spacing
AppSpacing.md
AppSpacing.lg

// Radius
AppRadius.md
```

### 디버깅 명령어

```bash
# 코드 분석
flutter analyze

# 특정 파일 분석
dart analyze lib/app/home/home_screen.dart

# 클린 빌드
flutter clean
flutter pub get
flutter run
```

---

## 📚 참고 문서

### 필수 문서
- **[DESIGN_GUIDE.md](./DESIGN_GUIDE.md)** - 디자인 시스템 완전 가이드 ⭐

### 외부 문서
- [Flutter 공식 문서](https://flutter.dev/docs)
- [Dart 언어 가이드](https://dart.dev/guides)
- [Material Design](https://material.io/design)

---

## 🎯 개발 체크리스트

새로운 화면 개발 시:

- [ ] DESIGN_GUIDE.md 확인
- [ ] AppFrame 사용
- [ ] 적절한 Top Bar 선택
- [ ] 적절한 Bottom Bar 선택 (필요시)
- [ ] 디자인 토큰 사용 (하드코딩 금지)
- [ ] const 키워드 사용
- [ ] 위젯 분리 (build 메서드 간소화)
- [ ] flutter analyze 통과
- [ ] 실제 기기에서 테스트 (SafeArea 확인)

---

## 💡 팁

### 개발 속도 향상

1. **DESIGN_GUIDE.md를 북마크하세요**
2. **코드 스니펫 활용**
3. **위젯 재사용**
4. **Hot Reload 활용** (`r` 키)
5. **Hot Restart 활용** (`R` 키)

### 일관성 유지

1. **항상 디자인 토큰 사용**
2. **AppFrame으로 화면 구성**
3. **명명 규칙 준수**
4. **파일 구조 일관성**

---

### 테스트 화면

Bubble 컴포넌트 동작을 확인하려면:
```bash
flutter run

# 앱에서: Example 화면 → "Bubble 테스트" 버튼
# 경로: /bubble-test
```

---

**마지막 업데이트**: 2025-12-09

**문의**: 개발팀 채널
