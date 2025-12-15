# Maeumbom Frontend 개발 가이드

***바이브 코딩시에는 PROMPT_GUIDE.md를 프롬프트에 전달 후 진행하세요***

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

#### Android 실제 디바이스
# localhost 부분 ip 변경 가능 (backend ip로 변경)
```bash
flutter run --dart-define=API_BASE_URL=http://localhost:8000
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
│   │   │   ├── home_screen.dart        # 기존 홈 화면
│   │   │   ├── home_new_screen.dart    # 새 홈 화면 (2x3 그리드)
│   │   │   ├── daily_mood_check_screen.dart
│   │   │   └── components/             # 홈 화면 컴포넌트
│   │   │       ├── home_header_section.dart
│   │   │       ├── home_main_buttons.dart      # 2x3 그리드 (캐릭터 + 5개 버튼)
│   │   │       ├── home_gauge_section.dart     # Fear & Greed 스타일 게이지
│   │   │       ├── home_banner_slider.dart     # 배너 슬라이더
│   │   │       ├── conversation_temperature_bar.dart
│   │   │       ├── semicircle_progress_painter.dart
│   │   │       └── daily_mood_check_widget.dart
│   │   ├── chat/                       # AI 봄이와 대화
│   │   │   └── bomi_screen.dart        # 봄이 채팅 (✅ 애니메이션 적용)
│   │   ├── alarm/                      # 똑똑 알람 (기억 서랍)
│   │   │   ├── alarm_screen.dart       # 알람 화면 (일일 이벤트 분석)
│   │   │   ├── memory_list_screen.dart # 기억 목록 화면
│   │   │   └── components/
│   │   │       ├── alarm_list_item.dart    # 알람 아이템 (2줄 레이아웃, 태그)
│   │   │       └── alarm_list_panel.dart   # 알람 목록 패널
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
│   │   ├── layout/                     # 레이아웃 컴포넌트 (9개)
│   │   │   ├── app_frame.dart          # 화면 기본 프레임
│   │   │   ├── top_bars.dart           # Top Bar (5가지 변형)
│   │   │   ├── bottom_menu_bars.dart   # Bottom Menu Bar (5탭 네비게이션)
│   │   │   ├── bottom_button_bars.dart # Bottom Button Bar
│   │   │   ├── bottom_input_bars.dart  # Bottom Input Bar (텍스트 입력)
│   │   │   ├── bottom_voice_bar.dart   # Bottom Voice Bar (음성 입력)
│   │   │   ├── bottom_home_bar.dart    # Bottom Home Bar (홈 화면 전용)
│   │   │   └── bottom_add_modal_bar.dart  # Bottom Add Modal Bar (재사용 모달)
│   │   │
│   │   ├── components/                 # 재사용 컴포넌트 (24개)
│   │   │   ├── app_component.dart      # 컴포넌트 통합 export
│   │   │   ├── app_button.dart         # 버튼 (4가지 variant)
│   │   │   ├── app_input.dart          # 입력 필드 (3가지 state)
│   │   │   ├── buttons.dart            # 기타 버튼
│   │   │   ├── inputs.dart             # 기타 입력
│   │   │   ├── chat_bubble.dart        # 채팅 말풍선 (사용자/봇)
│   │   │   ├── system_bubble.dart      # 시스템 말풍선
│   │   │   ├── emotion_bubble.dart     # 감정 말풍선 (캐릭터 + 메시지)
│   │   │   ├── speech_bubble.dart      # 말풍선 기본 컴포넌트
│   │   │   ├── list_bubble.dart        # 선택형 답변 말풍선 [deprecated]
│   │   │   ├── choice_button.dart      # 선택지 버튼 (가로/세로 레이아웃)
│   │   │   ├── circular_ripple.dart    # 원형 파동 효과
│   │   │   ├── orbital_dots.dart       # 궤도 점 애니메이션
│   │   │   ├── voice_waveform.dart     # 음성 파동 애니메이션
│   │   │   ├── slide_to_action_button.dart  # 슬라이드 액션 버튼
│   │   │   ├── more_menu_sheet.dart    # 더보기 메뉴 시트
│   │   │   ├── message_dialog.dart     # 메시지 다이얼로그
│   │   │   ├── top_notification.dart   # 상단 알림 배너
│   │   │   ├── date_range_selector.dart    # 날짜 범위 선택기
│   │   │   ├── memory_timeline_item.dart    # 기억 타임라인 아이템
│   │   │   ├── tag_badge.dart          # 태그 배지
│   │   │   ├── process_indicator.dart  # 프로세스 인디케이터
│   │   │   ├── progress_card.dart      # 진행률 카드
│   │   │   └── question_progress_view.dart  # 질문/진행률 통합 컴포넌트
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
- ✅ 디자인 토큰 (Colors, Typography, Spacing, Radius, Icons, Bubbles, Toggles)
- ✅ Layout 시스템 (AppFrame, Top Bar, 9가지 Bottom Bar)
- ✅ 컴포넌트 사용법 (AppButton, AppInput, Bubbles, Voice, Ripple, Toggle)
- ✅ 실제 사용 예시 (홈, 폼, 채팅 화면)
- ✅ Best Practices

**컴포넌트 (24개)**:

**기본 UI**:
- ✅ AppButton - 기본 버튼 (4가지 variant)
- ✅ AppInput - 입력 필드 (3가지 state)
- ✅ MessageDialog - 확인/알림 다이얼로그
- ✅ TopNotification - 상단 알림 배너 (Red/Green 테마)

**말풍선 (Bubbles)**:
- ✅ ChatBubble - 사용자/봇 채팅 말풍선
- ✅ SystemBubble - 시스템 메시지 (info/success/warning)
- ✅ EmotionBubble - 감정 말풍선 (TTS 토글 지원)
- ✅ SpeechBubble - 말풍선 기본 컴포넌트
- ✅ ListBubble - 선택형 답변 말풍선 [deprecated]

**선택 및 입력**:
- ✅ ChoiceButton - 사용자 선택지 버튼 (가로/세로 레이아웃, 감정 색상)
- ✅ SlideToActionButton - 슬라이드 액션 버튼 (음성/텍스트)
- ✅ DateRangeSelector - 날짜 범위 선택기

**애니메이션 및 시각 효과**:
- ✅ CircularRipple - 캐릭터 원형 파동 효과
- ✅ OrbitalDots - 궤도 점 애니메이션
- ✅ VoiceWaveform - 음성 녹음 파동 애니메이션
- ✅ ProcessIndicator - 프로세스 인디케이터

**리스트 및 카드**:
- ✅ MemoryTimelineItem - 기억 타임라인 아이템
- ✅ ProgressCard - 진행률 카드
- ✅ TagBadge - 태그 배지

**복합 컴포넌트**:
- ✅ MoreMenuSheet - 더보기 메뉴 시트
- ✅ QuestionProgressView - 질문/진행률 통합 컴포넌트

**캐릭터**:
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

**투명 상태바/TopBar 패턴 (Home/Alarm):**
```dart
class TranslucentScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppFrame(
      topBar: null, // 프레임의 TopBar는 사용 안함
      useSafeArea: false, // 배경색 확장
      statusBarStyle: SystemUiOverlayStyle.light, // 흰색 아이콘
      body: Container(
        color: dynamicBackgroundColor, // 배경색
        child: SafeArea(
          bottom: false, // 하단 배경 확장
          child: Column(
            children: [
              // 본문 내에 TopBar 배치
              TopBar(
                title: 'Title',
                backgroundColor: Colors.transparent, 
                foregroundColor: AppColors.basicColor,
                // ...
              ),
              Expanded(child: Content()),
            ],
          ),
        ),
      ),
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

#### 4. 토글 사용

```dart
// ✅ 권장: Toggle 토큰 사용
_buildToggle(
  value: ttsEnabled,
  onChanged: (value) => toggleTts(),
  style: ToggleStyle.primary(), // 빨간색 토글
)

_buildToggle(
  value: isEnabled,
  onChanged: (value) => toggle(),
  style: ToggleStyle.secondary(), // 초록색 토글
)

// ❌ 비권장: 하드코딩
Switch(
  value: isEnabled,
  onChanged: (value) => toggle(),
  activeColor: Colors.white,  // 하드코딩 ❌
  activeTrackColor: Colors.red,  // 하드코딩 ❌
)
```

#### 5. 선택지 버튼 사용 (ChoiceButton)

```dart
// 가로 배치 (2개 선택지) - 짧은 답변
ChoiceButtonGroup(
  choices: ['예', '아니오'],
  layout: ChoiceLayout.horizontal,  // 가로 배치 명시
  onChoiceSelected: (index, choice) {
    print('Selected: $choice');
  },
)

// 가로 배치 (3개 선택지도 가능)
ChoiceButtonGroup(
  choices: ['좋음', '보통', '나쁨'],
  layout: ChoiceLayout.horizontal,
  onChoiceSelected: (index, choice) {
    _handleMoodSelection(choice);
  },
)

// 세로 배치 (긴 텍스트)
ChoiceButtonGroup(
  choices: [
    '네, 지금 바로 시작하고 싶어요',
    '아니요, 나중에 할게요'
  ],
  layout: ChoiceLayout.vertical,  // 세로 배치 명시
  onChoiceSelected: (index, choice) {
    _handleChoice(choice);
  },
)

// 세로 배치 (3개 이상 선택지)
ChoiceButtonGroup(
  choices: ['요가', '산책', '수영', '헬스', '필라테스'],
  layout: ChoiceLayout.vertical,
  emotionIds: [
    EmotionId.relief, 
    EmotionId.joy, 
    EmotionId.love,
    EmotionId.interest,
    EmotionId.confidence
  ],
  onChoiceSelected: (index, choice) {
    _handleExerciseSelection(choice);
  },
)

// 선택지 개수에 따라 자동 레이아웃 결정
ChoiceButtonGroup(
  choices: choices,
  layout: choices.length == 2 
    ? ChoiceLayout.horizontal   // 2개면 가로
    : ChoiceLayout.vertical,    // 3개 이상이면 세로
  onChoiceSelected: (index, choice) {
    _handleChoice(choice);
  },
)

// 커스터마이징 (테두리 없이, 번호 표시 없이)
ChoiceButtonGroup(
  choices: ['선택 1', '선택 2', '선택 3'],
  layout: ChoiceLayout.vertical,
  showBorder: false,
  showNumber: false,
  onChoiceSelected: (index, choice) {
    _handleChoice(choice);
  },
)
```

**레이아웃 선택 가이드:**
- `ChoiceLayout.horizontal`: 가로 배치 (짧은 텍스트, 2-3개 선택지)
- `ChoiceLayout.vertical`: 세로 배치 (긴 텍스트, 3개 이상 선택지)

#### 6. 선택형 답변 사용 (ListBubble) [Deprecated]

**Note**: `ListBubble`은 deprecated되었으며, `ChoiceButtonGroup`을 사용하세요.

```dart
// ❌ Deprecated: ListBubble
if (responseType == 'list') {
  ListBubble(
    items: parseListItems(replyText),
    selectedIndex: selectedIndex,
    onItemSelected: (index, item) {
      sendMessage(item);
    },
  )
}

// ✅ 권장: ChoiceButtonGroup
ChoiceButtonGroup(
  choices: parseListItems(replyText),
  selectedIndex: selectedIndex,
  layout: choices.length == 2 
    ? ChoiceLayout.horizontal 
    : ChoiceLayout.vertical,
  onChoiceSelected: (index, choice) {
    sendMessage(choice);
  },
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
- 디자인 시스템 색상 자동 적용 (`AppColors.primaryColor`, `AppColors.secondaryColor`)
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

## 💬 팝업 메시지 (MessageDialog)

### 개요

사용자에게 중요한 메시지를 전달하거나 확인이 필요한 액션을 수행할 때 **MessageDialog**를 사용하세요.

### 언제 사용하나요?

- ✅ 삭제 확인 등 중요한 액션 전 확인
- ✅ 권한 요청 안내
- ✅ 작업 완료 알림 (성공/실패)
- ✅ 네트워크 오류 등 에러 메시지
- ✅ 사용자 선택이 필요한 상황

### 기본 사용법

#### Confirm 다이얼로그 (2개 버튼 - 확인 필요)

사용자의 확인이 필요한 경우 사용합니다.

```dart
import '../../ui/app_ui.dart';

// Red Confirm - 삭제, 권한 요청 등
MessageDialogHelper.showRedConfirm(
  context,
  icon: Icons.sentiment_satisfied_rounded,
  title: '알 수도 있는 사람 찾기👀',
  message: '내가 아는 사람의 루틴이\n궁금하지 않나요?',
  primaryButtonText: '좋아, 찾아줘!',
  secondaryButtonText: '나중에 할게',
  onPrimaryPressed: () {
    Navigator.pop(context);
    // 메인 액션 실행
  },
  onSecondaryPressed: () {
    Navigator.pop(context);
  },
);

// Green Confirm - 저장 확인, 공유 선택 등
MessageDialogHelper.showGreenConfirm(
  context,
  icon: Icons.check_circle_outline_rounded,
  title: '저장 완료!',
  message: '데이터가 성공적으로 저장되었습니다.',
  primaryButtonText: '확인',
  secondaryButtonText: '공유하기',
  onPrimaryPressed: () {
    Navigator.pop(context);
  },
  onSecondaryPressed: () {
    Navigator.pop(context);
    _shareData();
  },
);
```

#### Alert 다이얼로그 (1개 버튼 - 단순 알림)

단순 알림이나 에러 메시지를 표시할 때 사용합니다.

```dart
// Red Alert - 에러, 경고 등
MessageDialogHelper.showRedAlert(
  context,
  icon: Icons.error_outline_rounded,
  title: '네트워크 오류',
  message: '인터넷 연결을 확인해주세요.',
  onPressed: () {
    Navigator.pop(context);
    // 추가 액션 (선택사항)
  },
);

// Green Alert - 성공, 완료 등
MessageDialogHelper.showGreenAlert(
  context,
  icon: Icons.check_circle_outline_rounded,
  title: '저장 완료!',
  message: '변경사항이 저장되었습니다.',
  // onPressed 생략 시 자동으로 닫기
);
```

### 타입별 사용 가이드

#### 🔴 Red Confirm (경고, 삭제 확인)

```dart
// 삭제 확인
MessageDialogHelper.showRedConfirm(
  context,
  icon: Icons.delete_outline_rounded,
  title: '정말 삭제하시겠습니까?',
  message: '삭제된 데이터는 복구할 수 없습니다.',
  primaryButtonText: '삭제',
  secondaryButtonText: '취소',
  onPrimaryPressed: () {
    Navigator.pop(context);
    _deleteItem();
  },
  onSecondaryPressed: () {
    Navigator.pop(context);
  },
);

// 권한 요청
MessageDialogHelper.showRedConfirm(
  context,
  icon: Icons.location_on_outlined,
  title: '위치 권한 필요',
  message: '이 기능을 사용하려면\n위치 권한이 필요합니다.',
  primaryButtonText: '권한 설정',
  secondaryButtonText: '나중에',
  onPrimaryPressed: () {
    Navigator.pop(context);
    _openAppSettings();
  },
  onSecondaryPressed: () {
    Navigator.pop(context);
  },
);
```

#### 🔴 Red Alert (에러, 경고 알림)

```dart
// 네트워크 오류
MessageDialogHelper.showRedAlert(
  context,
  icon: Icons.wifi_off_rounded,
  title: '네트워크 오류',
  message: '인터넷 연결을 확인해주세요.',
);

// 권한 없음
MessageDialogHelper.showRedAlert(
  context,
  icon: Icons.lock_outline_rounded,
  title: '권한이 필요합니다',
  message: '이 기능을 사용하려면 카메라 권한이 필요합니다.',
  onPressed: () {
    Navigator.pop(context);
    _openSettings();
  },
);
```

#### 🟢 Green Confirm (저장 확인, 공유 선택)

```dart
// 저장 후 공유 선택
MessageDialogHelper.showGreenConfirm(
  context,
  icon: Icons.check_circle_outline_rounded,
  title: '저장 완료!',
  message: '변경사항이 저장되었습니다.',
  primaryButtonText: '확인',
  secondaryButtonText: '공유하기',
  onPrimaryPressed: () {
    Navigator.pop(context);
  },
  onSecondaryPressed: () {
    Navigator.pop(context);
    _shareData();
  },
);

// 업로드 후 파일 보기
MessageDialogHelper.showGreenConfirm(
  context,
  icon: Icons.cloud_done_outlined,
  title: '업로드 완료',
  message: '파일이 성공적으로 업로드되었습니다.',
  primaryButtonText: '확인',
  secondaryButtonText: '파일 보기',
  onPrimaryPressed: () {
    Navigator.pop(context);
  },
  onSecondaryPressed: () {
    Navigator.pop(context);
    _viewFile();
  },
);
```

#### 🟢 Green Alert (성공, 완료 알림)

```dart
// 저장 완료
MessageDialogHelper.showGreenAlert(
  context,
  icon: Icons.check_circle_outline_rounded,
  title: '저장 완료!',
  message: '변경사항이 저장되었습니다.',
);

// 업로드 완료
MessageDialogHelper.showGreenAlert(
  context,
  icon: Icons.cloud_done_outlined,
  title: '업로드 완료',
  message: '파일이 성공적으로 업로드되었습니다.',
  onPressed: () {
    Navigator.pop(context);
    _refreshList();
  },
);
```

### 실전 예시

#### 예시 1: 폼 제출 전 확인

```dart
class ProfileEditScreen extends ConsumerWidget {
  Future<void> _saveProfile(WidgetRef ref) async {
    // 확인 다이얼로그 표시
    MessageDialogHelper.showRedConfirm(
      context,
      icon: Icons.save_outlined,
      title: '프로필 저장',
      message: '변경사항을 저장하시겠습니까?',
      primaryButtonText: '저장',
      secondaryButtonText: '취소',
      onPrimaryPressed: () async {
        Navigator.pop(context);
        
        try {
          await ref.read(profileProvider.notifier).updateProfile(profileData);
          
          // 성공 알림
          MessageDialogHelper.showGreenAlert(
            context,
            icon: Icons.check_circle_outline_rounded,
            title: '저장 완료!',
            message: '프로필이 저장되었습니다.',
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // 편집 화면 닫기
            },
          );
        } catch (e) {
          // 실패 알림
          MessageDialogHelper.showRedAlert(
            context,
            icon: Icons.error_outline_rounded,
            title: '저장 실패',
            message: '저장에 실패했습니다. 다시 시도해주세요.',
          );
        }
      },
      onSecondaryPressed: () {
        Navigator.pop(context);
      },
    );
  }
}
```

#### 예시 2: 삭제 with 실행취소

```dart
class AlarmScreen extends ConsumerWidget {
  Future<void> _deleteAlarm(WidgetRef ref, int alarmId) async {
    MessageDialogHelper.showRedConfirm(
      context,
      icon: Icons.delete_outline_rounded,
      title: '알람 삭제',
      message: '정말 삭제하시겠습니까?',
      primaryButtonText: '삭제',
      secondaryButtonText: '취소',
      onPrimaryPressed: () async {
        Navigator.pop(context);
        
        // 삭제 실행
        await ref.read(alarmProvider.notifier).deleteAlarm(alarmId);
        
        // TopNotification으로 실행취소 제공
        TopNotificationManager.show(
          context,
          message: '알람이 삭제되었습니다.',
          actionLabel: '실행취소',
          type: TopNotificationType.red,
          onActionTap: () async {
            await ref.read(alarmProvider.notifier).restoreAlarm(alarmId);
          },
        );
      },
      onSecondaryPressed: () {
        Navigator.pop(context);
      },
    );
  }
}
```

#### 예시 3: 네트워크 오류

```dart
void _handleNetworkError(BuildContext context) {
  MessageDialogHelper.showRedConfirm(
    context,
    icon: Icons.wifi_off_rounded,
    title: '네트워크 오류',
    message: '인터넷 연결을 확인해주세요.',
    primaryButtonText: '다시 시도',
    secondaryButtonText: '취소',
    onPrimaryPressed: () {
      Navigator.pop(context);
      _retry();
    },
    onSecondaryPressed: () {
      Navigator.pop(context);
    },
  );
}
```

#### 예시 4: 단순 에러 알림

```dart
void _showError(BuildContext context, String errorMessage) {
  MessageDialogHelper.showRedAlert(
    context,
    icon: Icons.error_outline_rounded,
    title: '오류 발생',
    message: errorMessage,
  );
}
```

#### 예시 5: 성공 알림

```dart
void _showSuccess(BuildContext context) {
  MessageDialogHelper.showGreenAlert(
    context,
    icon: Icons.check_circle_outline_rounded,
    title: '완료!',
    message: '작업이 성공적으로 완료되었습니다.',
    onPressed: () {
      Navigator.pop(context);
      _refreshData();
    },
  );
}
```

### 메서드 종류

#### Confirm 다이얼로그 (2개 버튼)
- `showRedConfirm()` - Red 타입, 확인 필요
- `showGreenConfirm()` - Green 타입, 확인 필요

#### Alert 다이얼로그 (1개 버튼)
- `showRedAlert()` - Red 타입, 단순 알림
- `showGreenAlert()` - Green 타입, 단순 알림

### 파라미터 상세

#### Confirm 다이얼로그

```dart
MessageDialogHelper.showRedConfirm(
  BuildContext context,                 // 필수: BuildContext
  {
    IconData? icon,                     // 선택: 상단 아이콘
    required String title,              // 필수: 제목
    required String message,            // 필수: 본문 메시지
    required String primaryButtonText,  // 필수: 메인 버튼 텍스트
    required String secondaryButtonText,// 필수: 보조 버튼 텍스트
    VoidCallback? onPrimaryPressed,     // 선택: 메인 버튼 콜백
    VoidCallback? onSecondaryPressed,   // 선택: 보조 버튼 콜백
  }
)
```

#### Alert 다이얼로그

```dart
MessageDialogHelper.showRedAlert(
  BuildContext context,                 // 필수: BuildContext
  {
    IconData? icon,                     // 선택: 상단 아이콘
    required String title,              // 필수: 제목
    required String message,            // 필수: 본문 메시지
    String primaryButtonText = '확인',   // 선택: 버튼 텍스트 (기본값: '확인')
    VoidCallback? onPressed,            // 선택: 버튼 콜백 (기본: 다이얼로그 닫기)
  }
)
```

### Best Practices

#### ✅ 권장

```dart
// 1. 확인이 필요한 경우 Confirm 사용
MessageDialogHelper.showRedConfirm(
  context,
  title: '삭제 확인',
  message: '정말 삭제하시겠습니까?',
  primaryButtonText: '삭제',
  secondaryButtonText: '취소',
  onPrimaryPressed: () {
    Navigator.pop(context);
    _deleteItem();
  },
  onSecondaryPressed: () {
    Navigator.pop(context);
  },
);

// 2. 단순 알림은 Alert 사용
MessageDialogHelper.showGreenAlert(
  context,
  icon: Icons.check_circle_outline_rounded,
  title: '완료',
  message: '작업이 완료되었습니다.',
);

// 3. 적절한 아이콘 사용
// 에러: Icons.error_outline_rounded
// 성공: Icons.check_circle_outline_rounded
// 삭제: Icons.delete_outline_rounded
// 네트워크: Icons.wifi_off_rounded

// 4. 타입에 맞는 용도
// Red: 경고, 삭제, 에러
// Green: 성공, 완료
```

#### ❌ 비권장

```dart
// 1. 너무 긴 메시지 ❌
MessageDialogHelper.showRedAlert(
  context,
  title: '알림',
  message: '매우 긴 메시지가 여기에 들어가면 가독성이 떨어집니다...',
);

// 2. 부적절한 타입 사용 ❌
// 삭제 알림에 Green 타입 사용
MessageDialogHelper.showGreenAlert(
  context,
  title: '삭제',
  message: '삭제되었습니다.',
);

// 3. Confirm이 필요한데 Alert 사용 ❌
MessageDialogHelper.showRedAlert(
  context,
  title: '삭제 확인',
  message: '정말 삭제하시겠습니까?',
  primaryButtonText: '삭제',
);
// → showRedConfirm 사용해야 함

// 4. Alert인데 불필요한 콜백 제공 ❌
MessageDialogHelper.showGreenAlert(
  context,
  title: '완료',
  message: '저장되었습니다.',
  onPressed: () {
    Navigator.pop(context); // 자동으로 닫히므로 불필요
  },
);
```

### 선택 가이드

#### TopNotification 사용
- 간단한 피드백 (저장 완료, 삭제 완료)
- 사용자 액션이 필요 없는 알림
- 자동으로 사라지는 메시지

#### MessageDialog Confirm 사용
- 중요한 확인이 필요한 경우 (삭제, 권한 요청)
- 사용자 선택이 필요한 상황 (저장/취소, 공유/닫기)
- 되돌릴 수 없는 액션

#### MessageDialog Alert 사용
- 에러 메시지, 경고 알림
- 성공/완료 메시지 (상세 설명 필요)
- 사용자가 반드시 확인해야 하는 정보

### 참고 문서

- **구현 파일**: `lib/ui/components/message_dialog.dart`
- **테스트 화면**: `lib/app/example/message_dialog_test_screen.dart`

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
AppColors.primaryColor
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

---

## 🎨 에러 및 알림 처리 (TopNotification)

### 개요

화면 개발 시 오류나 처리에 대한 안내 메시지가 필요할 때는 **TopNotification**을 사용하세요.

디자인 가이드에 정의된 TopNotification을 사용하면 일관된 UX를 제공할 수 있습니다.

### 언제 사용하나요?

- ✅ API 요청 실패 시 에러 메시지
- ✅ 권한 거부 등 일반 에러 안내
- ✅ 네트워크 오류 등 즉각적인 피드백
- ✅ 사용자 액션 실패 알림
- ✅ 작업 성공/완료 알림

### 기본 사용법

#### 에러 알림 헬퍼 메서드

```dart
/// 에러 알림 표시 (TopNotification)
void _showErrorNotification(String message) {
  if (!mounted) return;

  TopNotificationManager.show(
    context,
    message: message,
    type: TopNotificationType.red,
    duration: const Duration(milliseconds: 3000),
  );
}
```

#### 성공 알림

```dart
/// 성공 알림 표시
void _showSuccessNotification(String message) {
  if (!mounted) return;

  TopNotificationManager.show(
    context,
    message: message,
    type: TopNotificationType.green,
    duration: const Duration(milliseconds: 2000),
  );
}
```

### 실전 예시

#### 예시 1: API 요청 실패 (bomi_screen.dart)

```dart
// lib/app/chat/bomi_screen.dart
class _BomiScreenState extends ConsumerState<BomiScreen> {
  /// 에러 알림 표시 (TopNotification)
  void _showErrorNotification(String message) {
    if (!mounted) return;

    TopNotificationManager.show(
      context,
      message: message,
      type: TopNotificationType.red,
      duration: const Duration(milliseconds: 3000),
    );
  }

  Future<void> _handleVoiceInput() async {
    final chatNotifier = ref.read(chatProvider.notifier);
    final chatState = ref.read(chatProvider);

    if (chatState.voiceState == VoiceInterfaceState.listening ||
        chatState.voiceState == VoiceInterfaceState.processing ||
        chatState.voiceState == VoiceInterfaceState.replying) {
      // 진행 중인 작업 중지
      try {
        await chatNotifier.stopAudioRecording();
      } catch (e) {
        if (mounted) {
          _showErrorNotification('중지 실패: ${e.toString()}');
        }
      }
    } else {
      // 녹음 시작
      try {
        await chatNotifier.startAudioRecording();
      } catch (e) {
        if (!mounted) return;

        if (e.toString().contains('PERMANENTLY_DENIED')) {
          _showPermissionDialog();
        } else {
          _showErrorNotification(e.toString());
        }
      }
    }
  }

  Future<void> _handleSendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final chatNotifier = ref.read(chatProvider.notifier);
    _textController.clear();

    try {
      await chatNotifier.sendTextMessage(text);
    } catch (e) {
      if (mounted) {
        _showErrorNotification('메시지 전송 실패: ${e.toString()}');
      }
    }
  }
}
```

#### 예시 2: 데이터 저장 성공

```dart
Future<void> _saveData() async {
  try {
    await repository.saveData(data);
    
    // 성공 알림
    TopNotificationManager.show(
      context,
      message: '저장되었습니다.',
      type: TopNotificationType.green,
    );
  } catch (e) {
    // 실패 알림
    TopNotificationManager.show(
      context,
      message: '저장 실패: ${e.toString()}',
      type: TopNotificationType.red,
    );
  }
}
```

#### 예시 3: 실행취소 액션 포함

```dart
Future<void> _deleteItem(int id) async {
  await repository.deleteItem(id);
  
  TopNotificationManager.show(
    context,
    message: '삭제되었습니다.',
    actionLabel: '실행취소',
    type: TopNotificationType.red,
    onActionTap: () async {
      await repository.restoreItem(id);
      TopNotificationManager.show(
        context,
        message: '복구되었습니다.',
        type: TopNotificationType.green,
      );
    },
  );
}
```

### 타입별 사용 가이드

#### 🔴 Red (에러, 경고, 삭제)

```dart
// 에러 메시지
TopNotificationManager.show(
  context,
  message: '네트워크 연결을 확인해주세요.',
  type: TopNotificationType.red,
);

// 삭제 완료
TopNotificationManager.show(
  context,
  message: '알람이 삭제되었습니다.',
  actionLabel: '실행취소',
  type: TopNotificationType.red,
  onActionTap: () => _undoDelete(),
);
```

#### 🟢 Green (성공, 완료)

```dart
// 저장 완료
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
```

### 디자인 스펙

#### 위치 및 스타일
- **위치**: TopBar 바로 아래 (상단 패딩 + 60px)
- **너비**: 전체 너비
- **배경색**: 
  - Red: `AppColors.primaryColor`
  - Green: `AppColors.secondaryColor`
- **텍스트 색상**: `AppColors.basicColor`
- **타이포그래피**: `AppTypography.body`
- **패딩**: 가로 `AppSpacing.md`, 세로 12px

#### 동작
- **duration**: 기본 2000ms (2초)
- **자동 닫힘**: duration 후 자동으로 사라짐
- **오버레이**: 화면 최상단에 오버레이로 표시
- **중복 방지**: 새 알림 표시 시 이전 알림 자동 제거

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
// 1. 헬퍼 메서드로 중복 코드 제거
void _showErrorNotification(String message) {
  if (!mounted) return;
  TopNotificationManager.show(
    context,
    message: message,
    type: TopNotificationType.red,
  );
}

// 2. mounted 체크
if (mounted) {
  _showErrorNotification('에러 메시지');
}

// 3. 짧고 명확한 메시지
TopNotificationManager.show(
  context,
  message: '저장되었습니다.',
  type: TopNotificationType.green,
);

// 4. 적절한 타입 선택
// - 에러/경고/삭제 → red
// - 성공/완료 → green

// 5. try-catch와 함께 사용
try {
  await apiCall();
  TopNotificationManager.show(context, message: '성공', type: TopNotificationType.green);
} catch (e) {
  TopNotificationManager.show(context, message: '실패', type: TopNotificationType.red);
}
```

#### ❌ 비권장

```dart
// 1. SnackBar 사용 ❌
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('메시지')),
);
// → TopNotificationManager.show() 사용

// 2. mounted 체크 없이 사용 ❌
TopNotificationManager.show(context, message: '에러');

// 3. 너무 긴 메시지 ❌
TopNotificationManager.show(
  context,
  message: '매우 긴 에러 메시지가 여기에 들어가면 가독성이 떨어집니다...',
);

// 4. 부적절한 타입 사용 ❌
// 삭제 알림에 Green 타입
TopNotificationManager.show(
  context,
  message: '삭제되었습니다.',
  type: TopNotificationType.green,  // red 사용해야 함
);
```

### 참고 문서

- **[DESIGN_GUIDE.md - TopNotification](./DESIGN_GUIDE.md#93-topnotification)** - 디자인 상세 가이드
- **구현 파일**: `lib/ui/components/top_notification.dart`
- **사용 예시**: `lib/app/chat/bomi_screen.dart`

---

## 🔊 TTS 및 선택형 답변 기능

### 개요

봄이 채팅 화면에서 TTS(Text-to-Speech) 토글과 선택형 답변 UI를 제공합니다.

### TTS 토글 기능

#### 구현 위치
- **EmotionBubble 외부**, 우측 정렬로 배치
- "목소리 듣기" 레이블 + Switch 토글
- `BomiContent`에서 관리 (일반 답변과 선택형 답변 모두)

#### 상태 관리
```dart
// ChatState에 ttsEnabled 필드
class ChatState {
  final bool ttsEnabled; // TTS 활성화 여부
  // ...
}

// SharedPreferences에 저장하여 앱 재시작 시에도 유지
final prefs = await SharedPreferences.getInstance();
await prefs.setBool('chat_tts_enabled', ttsEnabled);
```

#### 사용 예시
```dart
// BomiContent에서 TTS 토글 배치
Row(
  mainAxisAlignment: MainAxisAlignment.end,
  children: [
    Text(
      '목소리 듣기',
      style: AppTypography.caption.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w500,
      ),
    ),
    const SizedBox(width: 8),
    _buildToggle(
      value: chatState.ttsEnabled,
      onChanged: (value) {
        ref.read(chatProvider.notifier).toggleTtsEnabled();
      },
      style: ToggleStyle.primary(),
    ),
  ],
),
// 그 아래 EmotionBubble 배치
EmotionBubble(
  message: '오늘 하루 어떠셨나요?',
  enableTypingAnimation: true,
)
```

#### API 연동
```dart
// 메시지 전송 시 tts_enabled 파라미터 포함
final response = await _chatRepository.sendTextMessageRaw(
  text: text,
  userId: _userId,
  sessionId: state.sessionId,
  ttsEnabled: state.ttsEnabled, // ✅ TTS 활성화 여부 전달
);

// 응답에서 TTS 오디오 URL 수신
{
  "reply_text": "string",
  "tts_audio_url": "string",  // TTS 오디오 URL
  "tts_status": "ready",      // TTS 상태
  "meta": { ... }
}
```

### 선택형 답변 (ListBubble)

#### 개요
`response_type: "list"`일 때 사용자가 선택할 수 있는 항목 리스트를 표시합니다.

#### 데이터 구조
```json
{
  "reply_text": "갱년기에 좋은 운동 추천해줄게!\n\n1. 요가 - 스트레칭과 명상을 통해 몸과 마음을 편안하게 해줘\n2. 산책 - 가벼운 유산산소 운동으로 기분 전환에 좋아\n3. 수영 - 관절에 무리 없이 전신 운동을 할 수 있어",
  "emotion": "happiness",
  "response_type": "list",
  "meta": {
    "model": "gpt-4o-mini",
    "session_id": "user_2_1765330968438",
    "response_type": "list"
  }
}
```

#### 구현 예시
```dart
// response_type 확인
final responseType = latestBotMessage?.responseType;
final isListType = responseType == 'list';

// list 타입일 때 요약 텍스트만 추출
String getSummaryText(String fullText) {
  if (!isListType) return fullText;
  
  final lines = fullText.split('\n');
  final summaryLines = <String>[];
  
  for (final line in lines) {
    final trimmed = line.trim();
    // 번호 리스트가 시작되면 중단
    if (RegExp(r'^\d+\.\s+').hasMatch(trimmed)) {
      break;
    }
    if (trimmed.isNotEmpty) {
      summaryLines.add(trimmed);
    }
  }
  
  return summaryLines.isEmpty ? fullText : summaryLines.join('\n');
}

// 조건부 렌더링
if (isListType) {
  // TTS 토글
  Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      Text('목소리 듣기', ...),
      _buildToggle(...),
    ],
  ),
  
  // 안내 메시지 (요약만 표시)
  EmotionBubble(
    message: getSummaryText(botMessageText),
    enableTypingAnimation: true,
  ),
  
  // 선택 가능한 리스트
  ListBubble(
    items: parseListItems(botMessageText),
    selectedIndex: _selectedListIndex,
    disabled: _selectedListIndex != -1,
    onItemSelected: (index, item) {
      setState(() {
        _selectedListIndex = index;
      });
      // 선택한 항목을 서버로 전송
      _handleListItemSelected(item);
    },
  ),
}
```

#### 텍스트 파싱
```dart
// parseListItems 유틸리티 함수
final items = parseListItems(replyText);
// 입력: "1. 요가\n2. 산책\n3. 수영"
// 출력: ['요가', '산책', '수영']
```

#### ListBubble 특징
- 아웃라인 스타일 (테두리만 있는 버블)
- 번호 표시 (원형 배지)
- 선택 시 강조 표시 (빨간색 테두리 + 배경 + 체크 아이콘)
- 선택 후 다른 항목 비활성화 (연한 회색 처리)
- 각 항목은 독립적으로 클릭 가능
- 자동으로 서버에 선택 항목 전송

#### UI 개선 사항
- **스크롤바**: list 타입일 때만 표시 (`thumbVisibility: isListType`)
- **키보드 대응**: 텍스트 입력 시 자동으로 스크롤 하단 이동
- **EmotionBubble 동적 높이**: 
  - 최소 60px ~ 최대 144px (4줄)
  - 짧은 텍스트는 작게, 긴 텍스트는 최대 4줄까지
  - 4줄 초과 시 스크롤 가능

### Toggle 토큰 시스템

#### 토큰 정의
```dart
// Primary Toggle (빨간색) - TTS 등
ToggleStyle.primary()

// Secondary Toggle (초록색) - 보조 기능
ToggleStyle.secondary()

// 크기 조정
ToggleStyle.primary(size: ToggleSize.large)
```

#### 사용 예시
```dart
Widget _buildToggle({
  required bool value,
  required ValueChanged<bool>? onChanged,
  required ToggleStyle style,
}) {
  return Transform.scale(
    scale: style.scale,
    child: Switch(
      value: value,
      onChanged: onChanged,
      activeColor: style.activeThumb,
      activeTrackColor: style.activeTrack,
      inactiveThumbColor: style.inactiveThumb,
      inactiveTrackColor: style.inactiveTrack,
    ),
  );
}
```

### 주요 파일
- `lib/providers/chat_provider.dart` - TTS 상태 관리
- `lib/ui/components/emotion_bubble.dart` - TTS 토글 UI
- `lib/ui/components/list_bubble.dart` - 선택형 버블
- `lib/ui/tokens/toggles.dart` - 토글 토큰
- `lib/app/chat/components/bomi_content.dart` - 조건부 렌더링
- `lib/data/models/chat/chat_message.dart` - responseType getter
- `lib/data/dtos/chat/text_chat_request.dart` - tts_enabled 필드
- `lib/data/repository/chat/chat_repository.dart` - API 파라미터 전달

---

## 🎭 캐릭터 애니메이션 크기 조정

### 개요

봄이 화면에서 캐릭터 애니메이션 전환 시 크기 차이를 조정하여 자연스러운 UX를 제공합니다.

### 구현 상세

#### 캐릭터 크기 조정 (BomiContent)

```dart
// lib/app/chat/components/bomi_content.dart

Widget _buildCharacterLayer({
  required ProcessMode mode,
  required ProcessStep currentStep,
  required String animationState,
}) {
  return SizedBox(
    height: 360,
    child: Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: 50,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeInOut,
            switchOutCurve: Curves.easeInOut,
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.95, end: 1.0).animate(animation),
                  child: child,
                ),
              );
            },
            child: AnimatedCharacter(
              key: ValueKey(animationState),
              characterId: 'relief',
              emotion: animationState,
              size: animationState == 'basic' ? 270 : 300,  // 크기 조정
              repeat: true,
              animate: true,
            ),
          ),
        ),
        // Process Indicator...
      ],
    ),
  );
}
```

### 크기 스펙

| 애니메이션 상태 | 크기 | 비고 |
|--------------|------|------|
| `basic` | 270 | 기본 상태 (크기 축소) |
| 기타 (`happiness`, `sadness`, `anger`, `fear`) | 300 | 감정 애니메이션 (기본 크기) |

### 애니메이션 전환

- **duration**: 300ms
- **curve**: `Curves.easeInOut`
- **transition**: FadeTransition + ScaleTransition
- **scale**: 0.95 → 1.0 (부드러운 확대 효과)

### 참고 구현

- **구현 파일**: `lib/app/chat/components/bomi_content.dart`
- **애니메이션 헬퍼**: `lib/app/chat/helpers/animation_state_helper.dart`

---

**마지막 업데이트**: 2025-12-13

**문의**: 개발팀 채널
