# Maeumbom UI Design System

마음봄 앱의 디자인 시스템 가이드입니다. 일관된 UI/UX를 위한 디자인 토큰, 컴포넌트 사용법을 제공합니다.

---

## 📚 목차

1. [사용 예시](#-사용-예시)
2. [디자인 토큰](#-디자인-토큰)
   - [Colors](#1-colors)
   - [Typography](#2-typography)
   - [Spacing](#3-spacing)
   - [Radius](#4-radius)
   - [Icon Sizes](#5-icon-sizes)
3. [Layout 시스템](#-layout-시스템)
   - [AppFrame](#1-appframe)
   - [Top Bar](#2-top-bar)
   - [Bottom Bar](#3-bottom-bar)
4. [컴포넌트](#-컴포넌트)


---

## 💡 사용 예시

### 기본 화면 구성 

```dart
import 'package:flutter/material.dart';
import 'package:frontend/ui/app_ui.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppFrame(
      topBar: TopBarWithBoth(
        title: '마음봄',
      ),
      bottomBar: BottomMenuBar(
        currentIndex: 0,
        onTap: (index) {
          // 탭 전환 로직
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Text(
              '오늘 하루 어떠셨나요?',
              style: AppTypography.h2,
            ),
            SizedBox(height: AppSpacing.lg),
            AppButton(
              text: '일기 작성하기',
              variant: ButtonVariant.primaryRed,
            ),
          ],
        ),
      ),
    );
  }
}
```

### 폼 화면

```dart
class ProfileEditScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppFrame(
      topBar: TopBarWithLeft(
        title: '프로필 수정',
        onTapLeft: () => Navigator.pop(context),
        backgroundColor: AppColors.pureWhite,
        foregroundColor: AppColors.textPrimary,
      ),
      bottomBar: BottomButtonBar(
        primaryText: '저장',
        secondaryText: '취소',
        onPrimaryTap: () => _save(),
        onSecondaryTap: () => Navigator.pop(context),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            AppInput(
              caption: '이름',
              value: '',
              state: InputState.normal,
            ),
            SizedBox(height: AppSpacing.sm),
            AppInput(
              caption: '이메일',
              value: '',
              state: InputState.normal,
            ),
          ],
        ),
      ),
    );
  }
}
```

### 채팅 화면

```dart
class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AppFrame(
      topBar: TopBarWithLeft(
        title: '상담사와 대화',
        onTapLeft: () => Navigator.pop(context),
      ),
      bottomBar: BottomInputBar(
        controller: _controller,
        hintText: '메시지를 입력하세요',
        onSend: () {
          // 메시지 전송
          _controller.clear();
        },
      ),
      body: MessageList(),
    );
  }
}
```

---

## 🎨 디자인 토큰

디자인 토큰은 `lib/ui/tokens/` 디렉토리에 정의되어 있습니다.

### 1. Colors

**파일**: `lib/ui/tokens/colors.dart`

#### Primary Colors

| 이름 | 값 | 용도 |
|------|------|------|
| `accentRed` | `#D8454D` | 주요 액센트 컬러 (CTA 버튼, 강조) |
| `accentCoral` | `#E6757A` | 보조 액센트 컬러 |
| `natureGreen` | `#2F6A53` | 성공 상태, 자연 테마 |
| `errorRed` | `#C62828` | 에러, 경고 |

#### Neutral Colors

| 이름 | 값 | 용도 |
|------|------|------|
| `pureWhite` | `#FFFFFF` | 기본 배경 |
| `warmWhite` | `#FFFBFA` | 따뜻한 배경 |
| `lightPink` | `#F4E6E4` | 연한 핑크 배경 |
| `softMint` | `#CDE7DE` | 연한 민트 배경 |
| `softGray` | `#8F8F8F` | 보조 그레이 |
| `darkBlack` | `#000000` | 다크 모드, 강조 텍스트 |

#### Semantic Colors

```dart
// Background
AppColors.bgBasic      // 기본 배경 (white)
AppColors.bgWarm       // 따뜻한 배경
AppColors.bgLightPink  // 핑크 배경
AppColors.bgSoftMint   // 민트 배경
AppColors.bgRed        // 레드 배경
AppColors.bgGreen      // 그린 배경

// Text
AppColors.textWhite     // 흰색 텍스트
AppColors.textBlack     // 검은색 텍스트
AppColors.textPrimary   // #233446 (기본 텍스트)
AppColors.textSecondary // #6B6B6B (보조 텍스트)

// Border
AppColors.borderLight      // #F0EAE8
AppColors.borderLightGray  // #B0B0B0

// Status
AppColors.success  // natureGreen
AppColors.error    // errorRed

// Disabled
AppColors.disabledBg      // #F8F8F8
AppColors.disabledBorder  // #B0B0B0
AppColors.disabledText    // #B0B0B0
```

**사용 예시**:
```dart
Container(
  color: AppColors.bgBasic,
  child: Text(
    'Hello',
    style: TextStyle(color: AppColors.textPrimary),
  ),
)
```

---

### 2. Typography

**파일**: `lib/ui/tokens/typography.dart`

폰트: **Pretendard**

| 스타일 | 크기 | 굵기 | Letter Spacing | 용도 |
|--------|------|------|----------------|------|
| `display` | 56px | 700 | -1.68 | 대형 제목 |
| `h1` | 40px | 700 | -0.8 | 페이지 제목 |
| `h2` | 32px | 600 | -0.32 | 섹션 제목 |
| `h3` | 24px | 600 | -0.24 | 서브섹션 제목 |
| `bodyLarge` | 18px | 400 | 0 | 큰 본문 |
| `body` | 16px | 400 | 0 | 기본 본문 |
| `bodyBold` | 16px | 600 | 0 | 강조 본문 |
| `bodySmall` | 14px | 600 | 0 | 작은 본문 |
| `caption` | 14px | 400 | 0 | 캡션 |
| `label` | 8px | 500 | 0 | 라벨 (탭 바 등) |

**사용 예시**:
```dart
Text(
  '오늘 하루 어떠셨나요?',
  style: AppTypography.h2,
)

// 색상 커스터마이징
Text(
  '에러 메시지',
  style: AppTypography.body.copyWith(
    color: AppColors.error,
  ),
)
```

---

### 3. Spacing

**파일**: `lib/ui/tokens/spacing.dart`

| 이름 | 값 | 용도 |
|------|-----|------|
| `xxs` | 4px | 최소 여백 |
| `xs` | 8px | 아주 작은 여백 |
| `sm` | 16px | 작은 여백 |
| `md` | 24px | 중간 여백 (기본) |
| `lg` | 32px | 큰 여백 |
| `xl` | 40px | 아주 큰 여백 |
| `xxl` | 48px | 매우 큰 여백 |
| `xxxl` | 64px | 초대형 여백 |

**사용 예시**:
```dart
Padding(
  padding: const EdgeInsets.all(AppSpacing.md),
  child: Column(
    children: [
      Text('Title'),
      SizedBox(height: AppSpacing.sm),
      Text('Content'),
    ],
  ),
)
```

---

### 4. Radius

**파일**: `lib/ui/tokens/radius.dart`

| 이름 | 값 | 용도 |
|------|-----|------|
| `sm` | 8px | 작은 둥근 모서리 |
| `md` | 12px | 중간 둥근 모서리 |
| `lg` | 16px | 큰 둥근 모서리 |
| `pill` | 999px | 완전한 pill 형태 |

**사용 예시**:
```dart
Container(
  decoration: BoxDecoration(
    color: AppColors.accentRed,
    borderRadius: BorderRadius.circular(AppRadius.md),
  ),
)
```

---

### 5. Icon Sizes

**파일**: `lib/ui/tokens/icon.dart`

| 이름 | 크기 | 용도 |
|------|------|------|
| `xs` | 16×16 | 최소 아이콘 |
| `sm` | 24×24 | 작은 아이콘 |
| `md` | 28×28 | 중간 아이콘 (기본) |
| `lg` | 32×32 | 큰 아이콘 |
| `xl` | 36×36 | 아주 큰 아이콘 |
| `xxl` | 42×42 | 초대형 아이콘 |

**사용 예시**:
```dart
// Size 객체 사용
SizedBox.fromSize(
  size: AppIconSizes.mdSize,
  child: Icon(Icons.home),
)

// 직접 값 사용
Icon(Icons.home, size: AppIconSizes.md)
```

---

## 🏗️ Layout 시스템

### 1. AppFrame

**파일**: `lib/ui/layout/app_frame.dart`

화면의 기본 레이아웃 구조를 제공하는 최상위 프레임입니다. Flutter의 `Scaffold` 패턴을 따릅니다.

#### 구조

```
┌─────────────────────┐
│     Top Bar         │ ← topBar (optional)
├─────────────────────┤
│                     │
│       Body          │ ← body (required)
│                     │
├─────────────────────┤
│    Bottom Bar       │ ← bottomBar (optional)
└─────────────────────┘
```

#### 파라미터

| 파라미터 | 타입 | 필수 | 설명 |
|----------|------|------|------|
| `topBar` | `PreferredSizeWidget?` | ❌ | 상단 바 (TopBar 위젯) |
| `bottomBar` | `Widget?` | ❌ | 하단 바 (BottomBar 위젯) |
| `body` | `Widget` | ✅ | 메인 컨텐츠 영역 |

#### 기본 사용법

```dart
AppFrame(
  topBar: TopBarWithLeft(
    title: '홈',
    onTapLeft: () => Navigator.pop(context),
  ),
  bottomBar: BottomMenuBar(
    currentIndex: 0,
    onTap: (index) {
      // 탭 전환 로직
    },
  ),
  body: YourContentWidget(),
)
```

#### SafeArea 자동 적용

- **Top Bar**: 자동으로 상태 바(status bar) 영역 회피
- **Body**: SafeArea로 감싸져 있음
- **Bottom Bar**: 홈 인디케이터 영역 자동 계산 (iPhone 등)

---

### 2. Top Bar

**파일**: `lib/ui/layout/top_bars.dart`

상단 네비게이션 바 컴포넌트입니다.

#### 2.1 TopBar

단일 Top Bar 클래스로 모든 형태를 지원합니다. 아이콘과 콜백을 제공하면 표시되고, 제공하지 않으면 표시되지 않습니다.

**파라미터**:

| 파라미터 | 타입 | 기본값 | 설명 |
|----------|------|--------|------|
| `title` | `String` | - | 중앙 타이틀 (필수) |
| `leftIcon` | `IconData?` | `null` | 좌측 아이콘 |
| `rightIcon` | `IconData?` | `null` | 우측 아이콘 |
| `onTapLeft` | `VoidCallback?` | `null` | 좌측 버튼 탭 콜백 |
| `onTapRight` | `VoidCallback?` | `null` | 우측 버튼 탭 콜백 |
| `height` | `double` | `80` | 바 높이 |
| `backgroundColor` | `Color` | `AppColors.pureWhite` | 배경색 |
| `foregroundColor` | `Color` | `AppColors.textPrimary` | 텍스트/아이콘 색상 |

**사용 예시**:

**타이틀만**:
```dart
TopBar(
  title: '설정',
)
```

**좌측 버튼 + 타이틀**:
```dart
TopBar(
  title: '일기 작성',
  leftIcon: Icons.arrow_back,
  onTapLeft: () => Navigator.pop(context),
)
```

**타이틀 + 우측 버튼**:
```dart
TopBar(
  title: '홈',
  rightIcon: Icons.more_horiz,
  onTapRight: () => _showMenu(),
)
```

**좌측 + 타이틀 + 우측 버튼**:
```dart
TopBar(
  title: '채팅',
  leftIcon: Icons.arrow_back,
  rightIcon: Icons.settings,
  onTapLeft: () => Navigator.pop(context),
  onTapRight: () => _openSettings(),
)
```

#### 2.2 색상 커스터마이징

모든 Top Bar는 색상을 커스터마이징할 수 있습니다.

**기본 색상 (White)**:
```dart
TopBar(
  title: '홈',
  leftIcon: Icons.arrow_back,
  onTapLeft: () => Navigator.pop(context),
  // backgroundColor, foregroundColor 생략 시 기본값 사용
  // 기본값: pureWhite 배경, textPrimary 텍스트
)
```

**Red 액센트**:
```dart
TopBar(
  title: '프로필',
  leftIcon: Icons.arrow_back,
  onTapLeft: () => Navigator.pop(context),
  backgroundColor: AppColors.accentRed,
  foregroundColor: AppColors.textWhite,
)
```

**Green 액센트**:
```dart
TopBar(
  title: '테마',
  leftIcon: Icons.arrow_back,
  onTapLeft: () => Navigator.pop(context),
  backgroundColor: AppColors.natureGreen,
  foregroundColor: AppColors.textWhite,
)
```

---

### 3. Bottom Bar

하단 네비게이션/액션 바 컴포넌트입니다. 3가지 종류를 제공합니다.

#### 3.1 BottomMenuBar

**파일**: `lib/ui/layout/bottom_menu_bars.dart`

5개 탭을 가진 메인 네비게이션 바입니다.

**구조**:
```
┌─────┬─────┬─────┬─────┬─────┐
│ 홈  │알람 │ 🎙️  │리포트│마이 │
└─────┴─────┴─────┴─────┴─────┘
```

- **높이**: 100px (홈 인디케이터 여백 자동 추가)
- **중앙 버튼**: 음성 녹음 버튼 (원형, 56×56)

**파라미터**:

| 파라미터 | 타입 | 기본값 | 설명 |
|----------|------|--------|------|
| `currentIndex` | `int` | `0` | 현재 선택된 탭 인덱스 (0~4) |
| `onTap` | `ValueChanged<int>?` | `null` | 탭 선택 콜백 |
| `backgroundColor` | `Color` | `AppColors.pureWhite` | 바 배경색 |
| `foregroundColor` | `Color` | `AppColors.textPrimary` | 비선택 아이콘/텍스트 색상 |
| `accentColor` | `Color` | `AppColors.accentRed` | 선택 아이콘/중앙 버튼 색상 |

**탭 인덱스**:
- `0`: 홈
- `1`: 알람
- `2`: 녹음 (중앙 버튼)
- `3`: 리포트
- `4`: 마이페이지

**기본 사용 (White 배경)**:
```dart
BottomMenuBar(
  currentIndex: 0,
  onTap: (index) {
    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/home');
        break;
      case 1:
        Navigator.pushNamed(context, '/alarm');
        break;
      case 2:
        _startRecording();
        break;
      case 3:
        Navigator.pushNamed(context, '/report');
        break;
      case 4:
        Navigator.pushNamed(context, '/mypage');
        break;
    }
  },
)
```

**Green 액센트 버전**:
```dart
BottomMenuBar(
  currentIndex: 0,
  onTap: (index) { /* ... */ },
  accentColor: AppColors.natureGreen,  // 선택 시 초록색
)
```

#### 3.2 BottomButtonBar

**파일**: `lib/ui/layout/bottom_button_bars.dart`

1~2개의 액션 버튼을 제공하는 하단 바입니다.

**스타일**:
- `pill`: 둥근 버튼 (기본)
- `block`: 전체 폭 블록 버튼

##### 파라미터

| 파라미터 | 타입 | 기본값 | 설명 |
|----------|------|--------|------|
| `primaryText` | `String` | `'확인'` | 주 버튼 텍스트 |
| `secondaryText` | `String?` | `null` | 보조 버튼 텍스트 (옵션) |
| `onPrimaryTap` | `VoidCallback?` | `null` | 주 버튼 탭 콜백 |
| `onSecondaryTap` | `VoidCallback?` | `null` | 보조 버튼 탭 콜백 |
| `style` | `BottomButtonBarStyle` | `pill` | 버튼 스타일 |
| `backgroundColor` | `Color` | `AppColors.pureWhite` | 바 배경색 |
| `primaryButtonColor` | `Color` | `AppColors.accentRed` | 주 버튼 색상 |

##### Pill 스타일 (기본)

```dart
BottomButtonBar(
  primaryText: '저장',
  secondaryText: '취소',
  onPrimaryTap: () => _save(),
  onSecondaryTap: () => Navigator.pop(context),
  style: BottomButtonBarStyle.pill,  // 생략 가능
)
```

**특징**:
- 높이: 150px
- 비율: 보조(1) : 주(2)
- 둥근 모서리

**1개 버튼만 사용**:
```dart
BottomButtonBar(
  primaryText: '확인',
  onPrimaryTap: () => _confirm(),
  // secondaryText 생략
)
```

##### Block 스타일

```dart
BottomButtonBar(
  primaryText: '확인',
  secondaryText: '취소',
  onPrimaryTap: () => _confirm(),
  onSecondaryTap: () => _cancel(),
  style: BottomButtonBarStyle.block,
)
```

**특징**:
- 높이: 100px
- 비율: 보조(1) : 주(2)
- 모서리 없음 (전체 폭)
- Figma 디자인 기반 (129/246 split)

**Green 버튼 사용**:
```dart
BottomButtonBar(
  primaryText: '완료',
  onPrimaryTap: () => _complete(),
  primaryButtonColor: AppColors.natureGreen,  // 초록색 버튼
)
```

#### 3.3 BottomInputBar

**파일**: `lib/ui/layout/bottom_input_bars.dart`

텍스트 입력과 음성 입력 버튼을 제공하는 하단 바입니다.

**파라미터**:

| 파라미터 | 타입 | 기본값 | 설명 |
|----------|------|--------|------|
| `controller` | `TextEditingController` | - | 텍스트 필드 컨트롤러 (필수) |
| `hintText` | `String` | `'메시지를 입력하세요'` | 힌트 텍스트 |
| `onSend` | `VoidCallback?` | `null` | 전송 버튼 탭 콜백 |
| `backgroundColor` | `Color` | `AppColors.pureWhite` | 바 배경색 |
| `iconColor` | `Color` | `AppColors.textPrimary` | 마이크 아이콘 색상 |

**사용 예시**:
```dart
class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppFrame(
      topBar: TopBarWithLeft(title: '채팅'),
      bottomBar: BottomInputBar(
        controller: _controller,
        hintText: '메시지를 입력하세요',
        onSend: () {
          final message = _controller.text;
          if (message.isNotEmpty) {
            _sendMessage(message);
            _controller.clear();
          }
        },
      ),
      body: ChatMessageList(),
    );
  }
}
```

**특징**:
- 높이: 100px (홈 인디케이터 여백 자동 추가)
- 왼쪽: 텍스트 입력 필드
- 오른쪽: 음성 입력 버튼 (마이크 아이콘)

---

## 🧩 컴포넌트

### AppButton

**파일**: `lib/ui/components/app_button.dart`

다양한 스타일의 버튼 컴포넌트입니다.

**Variants**:
- `primaryRed`: 빨간색 주 버튼
- `secondaryRed`: 빨간색 보조 버튼 (외곽선)
- `primaryGreen`: 초록색 주 버튼
- `secondaryGreen`: 초록색 보조 버튼

```dart
AppButton(
  text: '시작하기',
  variant: ButtonVariant.primaryRed,
  onTap: () => _start(),
)
```

### AppInput

**파일**: `lib/ui/components/app_input.dart`

텍스트 입력 필드 컴포넌트입니다.

**States**:
- `normal`: 기본 상태
- `error`: 에러 상태
- `disabled`: 비활성화 상태

```dart
AppInput(
  caption: '이메일',
  value: 'user@example.com',
  state: InputState.normal,
  controller: _emailController,
)
```

---

## 📐 디자인 원칙

### 일관성 (Consistency)

- 모든 화면에서 동일한 디자인 토큰 사용
- Top Bar와 Bottom Bar는 AppFrame을 통해 일관되게 구성

### 접근성 (Accessibility)

- 충분한 색상 대비 (WCAG AA 준수)
- 터치 영역 최소 44×44px
- SafeArea 자동 적용으로 기기별 최적화

### 확장성 (Scalability)

- 토큰 기반 시스템으로 테마 변경 용이
- 컴포넌트 재사용성 극대화
- 새로운 화면 추가 시 일관된 구조 유지

---

## 🔧 개발 가이드

### Import

```dart
import 'package:frontend/ui/app_ui.dart';
```

위 한 줄로 모든 디자인 시스템 요소에 접근할 수 있습니다:
- Layout (AppFrame, TopBar, BottomBar)
- Tokens (Colors, Typography, Spacing, Radius, Icons)
- Components (AppButton, AppInput)

### 새로운 화면 추가

1. `lib/app/` 하위에 기능별 폴더 생성
2. `_screen.dart` 파일 생성
3. `AppFrame`을 사용하여 레이아웃 구성

```
lib/app/
├── home/
│   └── home_screen.dart
├── alarm/
│   └── alarm_screen.dart
└── mypage/
    └── mypage_screen.dart
```

---

## 📱 반응형 지원

### 안전 영역 자동 처리

- **iOS Notch**: Top Bar가 상태 바 영역 자동 회피
- **홈 인디케이터**: Bottom Bar가 자동으로 여백 추가
- **다양한 화면 크기**: MediaQuery를 통한 동적 계산

---

## 🎯 Best Practices

### ✅ 권장사항

```dart
// Good: 디자인 토큰 사용
Container(
  padding: EdgeInsets.all(AppSpacing.md),
  decoration: BoxDecoration(
    color: AppColors.bgBasic,
    borderRadius: BorderRadius.circular(AppRadius.md),
  ),
)

// Good: AppFrame 사용
AppFrame(
  topBar: TopBarWithLeft(title: '제목'),
  bottomBar: BottomButtonBar(primaryText: '확인'),
  body: content,
)
```

### ❌ 피해야 할 사항

```dart
// Bad: 하드코딩된 값
Container(
  padding: EdgeInsets.all(24),  // AppSpacing.md 사용
  decoration: BoxDecoration(
    color: Color(0xFFFFFFFF),    // AppColors.pureWhite 사용
    borderRadius: BorderRadius.circular(12),  // AppRadius.md 사용
  ),
)

// Bad: Scaffold 직접 사용
Scaffold(
  appBar: AppBar(...),  // TopBar 사용
  body: body,
)
```

---

## 📞 문의 및 기여

디자인 시스템 관련 문의사항이나 개선 제안은 팀 채널로 연락해주세요.

**마지막 업데이트**: 2025-12-03
