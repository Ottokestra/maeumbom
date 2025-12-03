# Maeumbom Frontend 개발 가이드

마음봄 Flutter 앱 개발을 위한 전체 가이드입니다.

---

## 📚 목차

1. [시작하기](#-시작하기)
2. [프로젝트 구조](#-프로젝트-구조)
3. [디자인 시스템](#-디자인-시스템)
4. [개발 워크플로우](#-개발-워크플로우)
5. [코딩 컨벤션](#-코딩-컨벤션)
6. [문제 해결](#-문제-해결)

---

## 🚀 시작하기

### 환경 설정

프로젝트 위치: `/frontend`

### 의존성 설치

```bash
cd frontend
flutter pub get
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
│   ├── characters/                     # 감정 캐릭터 이미지
│   │   ├── high/
│   │   └── normal/
│   ├── fonts/                          # 커스텀 폰트
│   └── images/                         # 앱 이미지, 아이콘
│       └── icons/
│
├── lib/                                # Flutter 소스 코드
│   ├── main.dart                       # 앱 진입점
│   │
│   ├── app/                            # 기능별 화면 (Feature-first)
│   │   ├── home/                       # 홈 화면
│   │   │   └── home_screen.dart
│   │   ├── chat/                       # AI 봄이와 대화
│   │   ├── alarm/                      # 똑똑 알람
│   │   ├── report/                     # 마음리포트
│   │   ├── training/                   # 마음연습실
│   │   ├── onboarding/                 # 온보딩
│   │   ├── settings/                   # 설정
│   │   └── common/                     # 공통 기능
│   │
│   ├── ui/                             # UI 시스템
│   │   ├── app_ui.dart                 # UI 시스템 통합 export
│   │   │
│   │   ├── layout/                     # 레이아웃 컴포넌트
│   │   │   ├── app_frame.dart          # 화면 기본 프레임
│   │   │   ├── top_bars.dart           # Top Bar (5가지 변형)
│   │   │   ├── bottom_menu_bars.dart   # Bottom Menu Bar
│   │   │   ├── bottom_button_bars.dart # Bottom Button Bar
│   │   │   └── bottom_input_bars.dart  # Bottom Input Bar
│   │   │
│   │   ├── components/                 # 재사용 컴포넌트
│   │   │   ├── app_component.dart      # 컴포넌트 통합 export
│   │   │   ├── app_button.dart         # 버튼 (4가지 variant)
│   │   │   ├── app_input.dart          # 입력 필드 (3가지 state)
│   │   │   └── buttons.dart
│   │   │
│   │   ├── tokens/                     # 디자인 토큰
│   │   │   ├── app_tokens.dart         # 토큰 통합 export
│   │   │   ├── colors.dart             # 색상 (51개)
│   │   │   ├── typography.dart         # 타이포그래피 (10가지)
│   │   │   ├── spacing.dart            # 여백 (8단계)
│   │   │   ├── radius.dart             # 둥근 모서리 (4가지)
│   │   │   ├── icon.dart               # 아이콘 사이즈 (6단계)
│   │   │   └── app_theme.dart          # 테마 설정
│   │   │
│   │   └── characters/                 # 감정 캐릭터
│   │       └── app_characters.dart
│   │
│   ├── data/                           # 데이터 계층
│   │   ├── models/                     # 도메인 모델
│   │   ├── dtos/                       # API DTO
│   │   ├── api/                        # HTTP 클라이언트
│   │   └── repository/                 # 데이터 저장소
│   │
│   └── core/                           # 핵심 기능
│       ├── config/                     # 앱 설정
│       ├── utils/                      # 유틸리티
│       └── services/                   # 서비스 (네트워크, 저장소 등)
│
├── DESIGN_GUIDE.md                     
└── FRONTEND_GUIDE.md                   
```

---

## 🎨 디자인 시스템

### 📖 디자인 시스템 문서

**모든 UI 개발 시 [DESIGN_GUIDE.md](./DESIGN_GUIDE.md)를 필수로 참고하세요.**

디자인 가이드에는 다음 내용이 포함되어 있습니다:
- ✅ 디자인 토큰 (Colors, Typography, Spacing, Radius, Icons)
- ✅ Layout 시스템 (AppFrame, Top Bar, Bottom Bar)
- ✅ 컴포넌트 사용법 (AppButton, AppInput)
- ✅ 실제 사용 예시 (홈, 폼, 채팅 화면)
- ✅ Best Practices

### 빠른 시작

#### 1. UI 시스템 Import

```dart
import 'package:frontend/ui/app_ui.dart';
```

이 한 줄로 모든 디자인 시스템 요소 사용 가능:
- Layout (AppFrame, TopBar, BottomBar)
- Tokens (Colors, Typography, Spacing, Radius, Icons)
- Components (AppButton, AppInput)

#### 2. 화면 구성

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

### 주요 디자인 토큰 요약

#### Colors
```dart
AppColors.accentRed         // #D8454D (주 액센트)
AppColors.natureGreen       // #2F6A53 (성공, 자연)
AppColors.pureWhite         // #FFFFFF (기본 배경)
AppColors.textPrimary       // #233446 (기본 텍스트)
AppColors.textSecondary     // #6B6B6B (보조 텍스트)
```

#### Typography
```dart
AppTypography.display       // 56px, 700 (대형 제목)
AppTypography.h1            // 40px, 700 (페이지 제목)
AppTypography.h2            // 32px, 600 (섹션 제목)
AppTypography.body          // 16px, 400 (본문)
AppTypography.caption       // 14px, 400 (캡션)
```

#### Spacing
```dart
AppSpacing.xs    // 8px
AppSpacing.sm    // 16px
AppSpacing.md    // 24px (기본)
AppSpacing.lg    // 32px
AppSpacing.xl    // 40px
```

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

#### 3. 라우팅 추가 (필요시)

```dart
// lib/main.dart
MaterialApp(
  routes: {
    '/': (context) => const HomeScreen(),
    '/feature': (context) => const FeatureScreen(),
  },
)
```

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

**마지막 업데이트**: 2025-12-03

**문의**: 개발팀 채널
