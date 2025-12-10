# Maeumbom UI Design System

마음봄 앱의 **"감정 교감 인터페이스"** 디자인 시스템 가이드입니다.

---

## 📚 목차

0. [Design Philosophy](#-0-design-philosophy)
1. [Emotion Character System](#-1-emotion-character-system)
2. [Voice Interaction Pattern](#-2-voice-interaction-pattern)
3. [Bubble Component System](#-3-bubble-component-system)
4. [Animation Guide](#-4-animation-guide)
5. [Navigation Structure](#-5-navigation-structure)
6. [Design Tokens](#-6-design-tokens)
7. [Layout System](#-7-layout-system)
8. [Component Library](#-8-component-library)

---

## ⭐ 0. Design Philosophy

### "앱"이 아닌 "감정 교감 인터페이스"

마음봄은 단순한 앱이 아니라, 사용자와 감정을 교감하는 인터페이스입니다.

---

### 핵심 원칙

#### 1. **캐릭터 중심 (Character-First)**

모든 인터랙션은 17개 감정 캐릭터를 통해 이루어집니다.

- 사용자는 "앱을 조작"하는 게 아니라 **"캐릭터와 상호작용"**합니다
- 감정 분석 결과에 따라 메인 캐릭터가 교체됩니다
- UI 요소보다 캐릭터가 화면의 중심이 됩니다

#### 2. **감정 중심 (Emotion-First)**

UI는 감정 상태를 시각적으로 표현합니다.

- 색상, 캐릭터, 애니메이션이 감정을 전달합니다
- 데이터나 기능보다 **"지금 이 순간의 감정"**이 우선입니다
- 모든 디자인 결정은 감정 교감을 목표로 합니다

#### 3. **음성 중심 (Voice-First)**

주 인터랙션 방식은 음성입니다.

- 마이크 버튼이 화면 중앙에 배치됩니다
- 음성 입력 중 시각적 피드백(파동)을 제공합니다
- 텍스트 입력은 보조 수단입니다

#### 4. **화이트 스페이스 (Breathing Room)**

여백을 충분히 활용해 시각적 안정감을 줍니다.

- 한 화면에 하나의 주요 메시지만 전달합니다
- 긴 텍스트는 **1~2줄로 제한**합니다
- 과도한 정보 표시를 지양합니다

#### 5. **직관적 인터랙션 (Intuitive)**

복잡한 메뉴 대신 자연스러운 대화 흐름을 따릅니다.

- 최소한의 버튼, 최대한의 공감
- 캐릭터의 반응으로 피드백 제공
- 사용자가 생각하지 않아도 되는 인터페이스

---

### 디자인 언어

#### 말풍선(Bubble)
카드 대신 말풍선으로 모든 정보를 전달합니다. 대화하는 느낌을 강조합니다.

#### 캐릭터 표정
17개 감정 캐릭터가 현재 감정 상태를 반영합니다.

#### 음성 파동
말하는 동안 시각적 피드백을 제공해 생동감을 더합니다.

#### 부드러운 전환
급격한 화면 전환보다 자연스러운 애니메이션을 사용합니다.

---

## 🎭 1. Emotion Character System

### 1.1 17개 감정 캐릭터

마음봄은 17개의 감정을 캐릭터로 표현합니다.

#### 긍정 감정 (7개)

| ID | 이름 | 캐릭터 | Primary 컬러 | Secondary 컬러 |
|----|------|---------|----------|----------|
| `joy` | 기쁨 | 해바라기 | #FFB84C | #FFD749 |
| `excitement` | 흥분 | 별 | #FF9800 | #FFB74D |
| `confidence` | 자신감 | 사자 | #FFC107 | #FFD54F |
| `love` | 사랑 | 펭귄 | #FF6FAE | #FF8EC3 |
| `relief` | 안심 | 사슴 | #76D6FF | #A1E8FF |
| `enlightenment` | 깨달음 | 전구 | #4FC3F7 | #81D4FA |
| `interest` | 흥미 | 부엉이 | #AB47BC | #BA68C8 |

#### 부정 감정 (10개)

| ID | 이름 | 캐릭터 | Primary 컬러 | Secondary 컬러 |
|----|------|---------|----------|----------|
| `discontent` | 불만 | 당근 | #8D6E63 | #A1887F |
| `shame` | 수치 | 복숭아 | #FFAB91 | #FFCCBC |
| `sadness` | 슬픔 | 고래 | #5C6BC0 | #7986CB |
| `guilt` | 죄책감 | 곰 | #6D4C41 | #8D6E63 |
| `depression` | 우울 | 돌 | #6C8CD5 | #8AA7E2 |
| `boredom` | 무료 | 나무늘보 | #B0BEC5 | #CFD8DC |
| `contempt` | 경멸 | 가지 | #7E57C2 | #9575CD |
| `anger` | 화 | 불 | #FF5E4A | #FF7A5C |
| `fear` | 공포 | 쥐 | #546E7A | #78909C |
| `confusion` | 혼란 | 로봇 | #B28CFF | #C7A4FF |

---

### 1.2 캐릭터 컬러 시스템

**파일:** `lib/ui/characters/app_character_colors.dart`

각 감정별로 Primary/Secondary 컬러가 정의되어 있습니다.

```dart
// 컬러 가져오기
final colors = emotionColorMap[EmotionId.joy]!;
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [colors.primary, colors.secondary],
    ),
  ),
)

// 헬퍼 함수 사용
final primaryColor = getEmotionPrimaryColor(EmotionId.love);
final secondaryColor = getEmotionSecondaryColor(EmotionId.love);
```

---

### 1.3 캐릭터 에셋 구조

```
assets/characters/
  ├─ normal/     (일반 해상도, 200x200)
  │   ├─ char_joy.png
  │   ├─ char_anger.png
  │   └─ ... (18개 - 17개 감정 + test)
  ├─ normal_2d/  (2D 버전, 200x200)
  │   ├─ char_joy.png
  │   ├─ char_anger.png
  │   └─ ... (18개)
  └─ animation/  (Lottie 애니메이션)
      ├─ happiness/
      │   └─ char_relief.json
      ├─ sadness/
      │   └─ char_relief.json
      ├─ anger/
      │   └─ char_relief.json
      ├─ fear/
      │   └─ char_relief.json
      ├─ basic/
      ├─ error/
      ├─ listening/
      ├─ realization/
      └─ thinking/
```

---

### 1.4 구현 위치

#### 정적 캐릭터 (PNG)
**파일:** `lib/ui/characters/app_characters.dart`

**주요 클래스:**
- `EmotionId`: 18개 감정 enum (17개 + test)
- `EmotionMeta`: 감정별 메타데이터 (이름, 캐릭터, PNG 에셋 경로)
- `EmotionCharacter`: 위젯 (Image.asset으로 PNG 렌더링)

**사용 예시:**
```dart
// 기본 사용 (normal 버전)
EmotionCharacter(
  id: EmotionId.joy,
  size: 120,
)

// 2D 버전 사용
EmotionCharacter(
  id: EmotionId.joy,
  use2d: true,
  size: 120,
)

// 컬러 배경과 함께
EmotionCharacterWithColor(
  id: EmotionId.joy,
  size: 120,
  showColorBackground: true,
  backgroundOpacity: 0.1,
)
```

#### 애니메이션 캐릭터 (Lottie)
**파일:** `lib/ui/characters/app_animations.dart`

**주요 클래스:**
- `EmotionCategory`: 감정군 enum (happiness, sadness, anger, fear 등)
- `AnimationMeta`: 애니메이션 메타데이터
- `AnimatedCharacter`: Lottie 애니메이션 위젯

**사용 예시:**
```dart
// 기본 사용
AnimatedCharacter(
  characterId: 'relief',
  emotion: 'happiness',
  size: 350,
)

// 카테고리로 지정
AnimatedCharacter.withCategory(
  characterId: 'relief',
  category: EmotionCategory.happiness,
  size: 350,
)
```

---

## 🎤 2. Voice Interaction Pattern

### 2.1 음성 우선 원칙

마음봄의 주 인터랙션은 음성입니다.

#### UI 우선순위

1. **마이크 버튼** (최우선, 가장 크고 눈에 띄게)
2. 음성 파동 시각화 (녹음 중 피드백)
3. 텍스트 입력 (보조 수단, 작게 배치)

---

### 2.2 SlideToActionButton

**파일:** `lib/ui/components/slide_to_action_button.dart`

양방향 슬라이딩 액션 버튼으로 음성/텍스트 입력을 통합 관리합니다.

```dart
SlideToActionButton(
  onVoiceActivated: () => _handleVoiceInput(),
  onTextActivated: () => _handleTextInputToggle(),
  onVoiceReset: () => _handleVoiceInput(),
  onTextReset: () => _handleTextInputToggle(),
  isRecording: _isRecording,
)
```

**특징:**
- 양방향 슬라이딩 지원 (왼쪽 마이크, 오른쪽 텍스트)
- 도착 상태 관리
- 녹음 중 시각적 피드백
- 클릭하여 리셋 가능

---

### 2.3 VoiceWaveform 애니메이션

**파일:** `lib/ui/components/voice_waveform.dart`

음성 입력 중 파동을 시각화하는 위젯입니다.

```dart
VoiceWaveform(
  isActive: isRecording,
  color: AppColors.accentRed,
  height: 40,
)
```

**디자인 스펙:**
- 높이: 40px (기본)
- 색상: `AppColors.accentRed` (기본)
- 파동: Sine wave (5개 주기)
- 애니메이션: 1.5초 주기로 반복
- 진폭: 높이의 30%

---

## 🗯 3. Bubble Component System

### 3.1 말풍선 디자인 철학

마음봄은 카드 대신 **말풍선(Bubble)**으로 정보를 전달합니다.

#### 왜 말풍선인가?

- **대화 느낌**: 카드는 정보 전달, 말풍선은 대화
- **친근함**: 딱딱한 사각형보다 부드러운 곡선
- **감정 표현**: 말풍선 꼬리로 화자 구분

---

### 3.2 Bubble 타입

#### 3.2.1 ChatBubble

**파일:** `lib/ui/components/chat_bubble.dart`

사용자와 봄이(봇)의 메시지를 말풍선 형태로 표시합니다.

```dart
// 사용자 메시지
ChatBubble(
  message: ChatMessage(
    text: '오늘 기분이 좋아요!',
    isUser: true,
    timestamp: DateTime.now(),
  ),
)

// 봄이 메시지
ChatBubble(
  message: ChatMessage(
    text: '좋은 하루를 보내셨군요!',
    isUser: false,
    timestamp: DateTime.now(),
  ),
)
```

**특징:**
- User: 우측 정렬, `accentRed` 배경, 흰색 텍스트
- Bot: 좌측 정렬, 흰색 배경, `borderLight` 테두리
- 하단 모서리 한쪽만 각짐 (꼬리 효과)

---

#### 3.2.2 SystemBubble

**파일:** `lib/ui/components/system_bubble.dart`

시스템 메시지를 표시하는 말풍선입니다.

```dart
// 정보 메시지
SystemBubble(
  text: '금주의 감정: 기쁨 😊',
  type: SystemBubbleType.info,
)

// 성공 메시지
SystemBubble(
  text: '감정 기록이 저장되었습니다',
  type: SystemBubbleType.success,
)

// 경고 메시지
SystemBubble(
  text: '네트워크 연결을 확인해주세요',
  type: SystemBubbleType.warning,
)
```

**타입:**
- `info`: 정보성 메시지 (warmWhite 배경)
- `success`: 성공 메시지 (softMint 배경)
- `warning`: 경고 메시지 (lightPink 배경)

---

#### 3.2.3 EmotionBubble

**파일:** `lib/ui/components/emotion_bubble.dart`

봄이의 대화 말풍선으로 타이핑 애니메이션과 스크롤을 지원합니다.

```dart
// 타이핑 애니메이션 있음
EmotionBubble(
  message: '오늘 하루 어떠셨나요?',
  enableTypingAnimation: true,
  typingSpeed: 50,
)

// 즉시 표시
EmotionBubble(
  message: '좋은 하루 보내세요!',
)
```

**특징:**
- 연분홍 배경 (`bgLightPink`)
- 3줄 고정 높이 (120px)
- 스크롤 가능 (내용이 길 경우)
- 하단 삼각형 표시 (더 많은 컨텐츠 있을 때)
- 타이핑 애니메이션 지원

---

### 3.3 BubbleTokens

**파일:** `lib/ui/tokens/bubbles.dart`

말풍선 스타일 일관성을 유지하는 토큰입니다.

```dart
class BubbleTokens {
  // Chat Bubble
  static const chatPadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.sm,
    vertical: 12,
  );
  static const double chatRadius = AppRadius.lg;
  static const double bubbleSpacing = AppSpacing.sm;
  static const double maxWidthRatio = 0.85;
  
  // User Bubble
  static const Color userBg = AppColors.accentRed;
  static const Color userText = AppColors.textWhite;
  
  // Bot Bubble
  static const Color botBg = AppColors.pureWhite;
  static const Color botText = AppColors.textPrimary;
  static const Color botBorder = AppColors.borderLight;
  static const double borderWidth = 1.0;
  
  // System Bubble
  static const systemPadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.sm,
    vertical: AppSpacing.xs,
  );
  static const double systemRadius = AppRadius.pill;
  static const Color systemText = AppColors.textSecondary;
  static const Color systemBgInfo = AppColors.warmWhite;
  static const Color systemBgSuccess = AppColors.bgSoftMint;
  static const Color systemBgWarning = AppColors.bgLightPink;
  
  // Emotion Bubble
  static const emotionPadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.sm,
    vertical: AppSpacing.xs,
  );
  static const double emotionRadius = AppRadius.md;
  static const Color emotionBg = AppColors.bgLightPink;
  static const Color emotionBorder = AppColors.borderLight;
  static const Color emotionText = AppColors.textPrimary;
}
```

---

## 🎞 4. Animation Guide

### 4.1 현재 구현 상태

#### 정적 이미지 (PNG)

- 에셋: `assets/characters/normal/*.png`, `assets/characters/normal_2d/*.png`
- 18개 감정 캐릭터 (17개 + test) 모두 정적 PNG 이미지 제공
- 위젯: `EmotionCharacter` (app_characters.dart)
- 렌더링: `Image.asset`

#### Lottie 애니메이션

- 에셋: `assets/characters/animation/{emotion}/char_{character}.json`
- 현재 `relief` 캐릭터의 여러 감정 애니메이션 구현
- 위젯: `AnimatedCharacter` (app_animations.dart)
- 패키지: `lottie: ^3.0.0`

---

### 4.2 애니메이션 원칙

#### 1. Subtle & Natural
과하지 않게, 자연스럽게 움직입니다.

```dart
// Good: 부드러운 애니메이션
AnimationController(
  duration: Duration(milliseconds: 800),
  curve: Curves.easeInOut,
)
```

#### 2. Performance First
60fps를 유지합니다.

```dart
// Good: 가벼운 애니메이션
Lottie.asset('animation.json')

// Good: 필요 시만 재생
if (shouldAnimate) {
  controller.forward();
}
```

#### 3. Purposeful
모든 애니메이션은 목적이 있어야 합니다.

#### 4. Consistent
타이밍과 이징을 일관되게 유지합니다.

**권장 타이밍:**
- Quick: 200-300ms (버튼, 작은 요소)
- Normal: 400-600ms (화면 전환, 중간 요소)
- Slow: 800-1200ms (큰 전환, 강조)

**권장 이징:**
- Enter: `Curves.easeOut`
- Exit: `Curves.easeIn`
- Continuous: `Curves.easeInOut`

---

## 🏠 5. Home Screen Design

### 5.1 홈 화면 개요

홈 화면은 사용자의 현재 감정 상태를 시각적으로 표현하는 핵심 화면입니다.

#### 디자인 철학
- **기분 기반 배경**: 감정 카테고리에 따라 배경색이 동적으로 변경됩니다
- **캐릭터 중심**: 240×240 크기의 감정 캐릭터가 화면 중앙에 배치됩니다
- **미니멀 UI**: 필수 정보만 표시하여 감정에 집중할 수 있도록 합니다

---

### 5.2 화면 구조

```
┌─────────────────────────────┐
│                             │ ← 상태바 (흰색 아이콘)
│  닉네임님,                   │
│  오늘 하루도 응원해요!        │
│  [나는 어떤 상태일까?]       │ ← 헤더 섹션
│                             │
│         [캐릭터]             │ ← 감정 캐릭터 (240×240)
│                             │
│     [대화 온도 막대]          │ ← 3단계 인디케이터
│                             │
├─────────────────────────────┤
│  [봄이] [알람] [리포트] [연습실] │ ← 하단 메뉴 (4개)
└─────────────────────────────┘
```

---

### 5.3 배경색 시스템

감정 분류(`MoodCategory`)에 따라 배경색이 변경됩니다.

| 기분 카테고리 | 배경색 | Hex 코드 | 적용 감정 |
|--------------|--------|----------|----------|
| **좋음** (good) | homeGoodYellow | #FFB84C | joy, excitement, confidence, love |
| **보통** (neutral) | homeNormalGreen | #63C96B | relief, enlightenment, interest |
| **나쁨** (bad) | homeBadBlue | #6C8CD5 | sadness, depression, fear, anger |

**구현:**
```dart
final moodCategory = EmotionClassifier.classify(currentEmotion);
final backgroundColor = _getBackgroundColor(moodCategory);

Color _getBackgroundColor(MoodCategory category) {
  switch (category) {
    case MoodCategory.good:
      return AppColors.homeGoodYellow;
    case MoodCategory.neutral:
      return AppColors.homeNormalGreen;
    case MoodCategory.bad:
      return AppColors.homeBadBlue;
  }
}
```

---

### 5.4 컴포넌트 상세

#### 5.4.1 HomeHeaderSection

**파일:** `lib/app/home/components/home_header_section.dart`

상단 헤더 영역으로 사용자 정보와 설문 버튼을 표시합니다.

**구성 요소:**
- 닉네임 인사 (h1, 흰색 100%, 700 bold)
- 인사말 메시지 (h3, 흰색 70%)
- 설문 버튼 (pill 형태, 흰색 20% 배경)

```dart
HomeHeaderSection()
```

---

#### 5.4.2 ConversationTemperatureBar

**파일:** `lib/app/home/components/conversation_temperature_bar.dart`

봄이와의 대화 온도를 3단계로 시각화합니다.

**구성 요소:**
- 제목: "봄이와의 대화 온도" (bodyBold, 흰색, 중앙 정렬)
- 3개 가로 막대 (8px 높이, pill 형태)
  - 활성: 흰색 90% 투명도
  - 비활성: 흰색 30% 투명도
- 라벨: "나쁨", "보통", "좋음" (caption, 흰색 70%)

```dart
ConversationTemperatureBar(
  currentMood: moodCategory,
)
```

---

#### 5.4.3 HomeBottomMenu

**파일:** `lib/app/home/components/home_bottom_menu.dart`

하단 4개 메뉴 버튼 (인라인 버전).

**구성 요소:**
- 4개 원형 아이콘 버튼 (56×56)
- 아이콘 배경: 흰색 20% 투명도
- 아이콘 크기: 28×28
- 라벨: caption, 흰색 100%

```dart
HomeBottomMenu()
```

---

### 5.5 일일 기분 체크 다이얼로그

홈 화면 진입 시 아직 오늘의 감정을 선택하지 않은 경우 자동으로 표시됩니다.

**동작:**
- `dailyMoodProvider.hasChecked`가 `false`일 때 500ms 후 표시
- 현재 화면이 최상위(`ModalRoute.isCurrent`)일 때만 표시
- "나중에" / "기록하기" 버튼 제공

---

### 5.6 완전한 구현 예시

```dart
class HomeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppFrame(
      topBar: null,
      useSafeArea: false,
      statusBarStyle: SystemUiOverlayStyle.light,
      body: const HomeContent(),
    );
  }
}

class HomeContent extends ConsumerStatefulWidget {
  @override
  Widget build(BuildContext context) {
    final dailyState = ref.watch(dailyMoodProvider);
    final currentEmotion = dailyState.selectedEmotion ?? EmotionId.joy;
    final moodCategory = EmotionClassifier.classify(currentEmotion);
    final backgroundColor = _getBackgroundColor(moodCategory);

    return Container(
      color: backgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.lg,
                ),
                child: Column(
                  children: [
                    const HomeHeaderSection(),
                    const SizedBox(height: AppSpacing.md),
                    Center(
                      child: EmotionCharacter(
                        id: currentEmotion,
                        size: 240,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    ConversationTemperatureBar(
                      currentMood: moodCategory,
                    ),
                  ],
                ),
              ),
            ),
            const HomeBottomMenu(),
          ],
        ),
      ),
    );
  }
}
```

---

## 🧭 6. Navigation Structure

### 6.1 현재 네비게이션

#### BottomMenuBar (5탭)

**파일:** `lib/ui/layout/bottom_menu_bars.dart`

```
┌─────┬─────┬─────┬─────┬─────┐
│ 홈  │알람 │ 🎙️  │리포트│마이 │
└─────┴─────┴─────┴─────┴─────┘
```

**구성:**
- 탭 0: 홈
- 탭 1: 알람
- 탭 2: 녹음 (중앙 원형 버튼)
- 탭 3: 리포트
- 탭 4: 마이페이지

**사용 예시:**
```dart
BottomMenuBar(
  currentIndex: 0,
  onTap: (index) {
    // 탭 전환 로직
  },
)
```

---

### 6.2 MoreMenuSheet

**파일:** `lib/ui/components/more_menu_sheet.dart`

더보기 버튼 탭 시 표시되는 BottomSheet입니다.

```dart
// 사용 예시
MoreMenuSheet.show(context);
```

**특징:**
- 2열 그리드 레이아웃
- 6개 메뉴 항목
- 각 항목: 아이콘 + 텍스트
- 반응형 높이 (화면의 최대 80%)

---

## 🎨 7. Design Tokens

### 7.1 Colors

**파일:** `lib/ui/tokens/colors.dart`

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

#### Emotion Colors

각 감정별 Primary/Secondary 컬러가 정의되어 있습니다.

```dart
// 기쁨 (Happiness)
AppColors.emotionHappinessPrimary    // #FFB84C
AppColors.emotionHappinessSecondary  // #FFD749

// 사랑 (Love)
AppColors.emotionLovePrimary         // #FF6FAE
AppColors.emotionLoveSecondary       // #FF8EC3

// 안정 (Stability)
AppColors.emotionStabilityPrimary    // #76D6FF
AppColors.emotionStabilitySecondary  // #A1E8FF

// 의욕 (Motivation)
AppColors.emotionMotivationPrimary   // #63C96B
AppColors.emotionMotivationSecondary // #8EE89C

// 분노 (Anger)
AppColors.emotionAngerPrimary        // #FF5E4A
AppColors.emotionAngerSecondary      // #FF7A5C

// 걱정/우울 (Worry/Depression)
AppColors.emotionWorryPrimary        // #6C8CD5
AppColors.emotionWorrySecondary      // #8AA7E2

// 혼란 (Confusion)
AppColors.emotionConfusionPrimary    // #B28CFF
AppColors.emotionConfusionSecondary  // #C7A4FF
```

#### Semantic Colors

```dart
// Background
AppColors.bgBasic      // 기본 배경 (pureWhite)
AppColors.bgWarm       // 따뜻한 배경 (warmWhite)
AppColors.bgLightPink  // 핑크 배경
AppColors.bgSoftMint   // 민트 배경
AppColors.bgRed        // 레드 배경 (accentRed)
AppColors.bgGreen      // 그린 배경 (natureGreen)

// Home Screen Mood-based Backgrounds
AppColors.homeGoodYellow   // #FFB84C (좋은 기분)
AppColors.homeNormalGreen  // #63C96B (보통 기분)
AppColors.homeBadBlue      // #6C8CD5 (나쁜 기분)

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

---

### 7.2 Typography

**파일:** `lib/ui/tokens/typography.dart`

**폰트:** Pretendard

| 스타일 | 크기 | 굵기 | Letter Spacing | 용도 |
|--------|------|------|----------------|------|
| `display` | 56px | 700 | -1.68 | 대형 제목 |
| `h1` | 40px | 700 | -0.8 | 페이지 제목 |
| `h2` | 32px | 600 | -0.32 | 섹션 제목 |
| `h3` | 24px | 600 | -0.24 | 서브섹션 제목 |
| `bodyLarge` | 18px | 400 | 0 | 봄이 대사, 말풍선 |
| `body` | 16px | 400 | 0 | 기본 본문 |
| `bodyBold` | 16px | 600 | 0 | 강조 본문 |
| `bodySmall` | 14px | 600 | 0 | 작은 본문 |
| `caption` | 14px | 400 | 0 | 캡션, 설명 |
| `label` | 8px | 500 | 0 | 라벨 |

**사용 예시:**

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

### 7.3 Spacing

**파일:** `lib/ui/tokens/spacing.dart`

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

---

### 7.4 Radius

**파일:** `lib/ui/tokens/radius.dart`

| 이름 | 값 | 용도 |
|------|-----|------|
| `sm` | 8px | 작은 둥근 모서리 |
| `md` | 12px | 중간 둥근 모서리 (기본) |
| `lg` | 16px | 큰 둥근 모서리 |
| `xl` | 24px | 아주 큰 둥근 모서리 |
| `xxl` | 32px | 매우 큰 둥근 모서리 |
| `pill` | 999px | 완전한 pill 형태 |

---

### 7.5 Icon Sizes

**파일:** `lib/ui/tokens/icon_size.dart`

| 이름 | 크기 | 용도 |
|------|------|------|
| `xs` | 16×16 | 최소 아이콘 |
| `sm` | 24×24 | 작은 아이콘 |
| `md` | 28×28 | 중간 아이콘 (기본) |
| `lg` | 32×32 | 큰 아이콘 |
| `xl` | 36×36 | 아주 큰 아이콘 |
| `xxl` | 42×42 | 초대형 아이콘 |

---

## 🏗️ 8. Layout System

### 8.1 AppFrame

**파일:** `lib/ui/layout/app_frame.dart`

화면의 기본 레이아웃 구조를 제공하는 최상위 프레임입니다.

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

#### 사용 예시

```dart
AppFrame(
  topBar: TopBar(
    title: '홈',
    leftIcon: Icons.arrow_back,
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

---

### 8.2 Top Bar

**파일:** `lib/ui/layout/top_bars.dart`

#### TopBar

단일 클래스로 모든 형태 지원. 아이콘과 콜백 제공 시 표시됩니다.

**사용 예시:**

```dart
// 타이틀만
TopBar(title: '설정')

// 좌측 버튼 + 타이틀
TopBar(
  title: '일기 작성',
  leftIcon: Icons.arrow_back,
  onTapLeft: () => Navigator.pop(context),
)

// 타이틀 + 우측 버튼
TopBar(
  title: '홈',
  rightIcon: Icons.more_horiz,
  onTapRight: () => _showMenu(),
)

// 양쪽 버튼
TopBar(
  title: '채팅',
  leftIcon: Icons.arrow_back,
  rightIcon: Icons.settings,
  onTapLeft: () => Navigator.pop(context),
  onTapRight: () => _openSettings(),
)
```

---

### 8.3 Bottom Bar

#### 8.3.1 BottomMenuBar

**파일:** `lib/ui/layout/bottom_menu_bars.dart`

5개 탭 메인 네비게이션 바.

```dart
BottomMenuBar(
  currentIndex: 0,
  onTap: (index) {
    // 탭 전환 로직
  },
)
```

**탭 인덱스:**
- `0`: 홈
- `2`: 녹음 (중앙 버튼)
- `4`: 마이페이지

---

#### 8.3.2 BottomButtonBar

**파일:** `lib/ui/layout/bottom_button_bars.dart`

1~2개 액션 버튼 제공.

```dart
// Pill 스타일
BottomButtonBar(
  primaryText: '저장',
  secondaryText: '취소',
  onPrimaryTap: () => _save(),
  onSecondaryTap: () => Navigator.pop(context),
)

// Block 스타일
BottomButtonBar(
  primaryText: '확인',
  style: BottomButtonBarStyle.block,
  onPrimaryTap: () => _confirm(),
)
```

---

#### 8.3.3 BottomInputBar

**파일:** `lib/ui/layout/bottom_input_bars.dart`

텍스트 입력 + 음성 입력.

```dart
BottomInputBar(
  controller: _controller,
  hintText: '메시지를 입력하세요',
  onSend: () {
    if (_controller.text.isNotEmpty) {
      _sendMessage(_controller.text);
      _controller.clear();
    }
  },
)
```

---

#### 8.3.4 BottomHomeBar

**파일:** `lib/ui/layout/bottom_home_bar.dart`

홈 화면 전용 Bottom Bar. 4개의 원형 아이콘 메뉴 제공.

```dart
BottomHomeBar()
```

**특징:**
- 투명 배경 (`Colors.transparent`)
- 4개 메뉴: 봄이 채팅, 똑똑 알람, 마음리포트, 마음연습실
- 원형 아이콘 컨테이너 (56×56, 흰색 20% 투명도)
- 아이콘 크기: 28×28
- 자동 SafeArea bottom padding 적용
- NavigationService를 통한 라우팅

**사용 예시:**
```dart
AppFrame(
  topBar: null,
  bottomBar: const BottomHomeBar(),
  body: HomeContent(),
)
```

---

## 🧩 9. Component Library

### 9.1 AppButton

**파일:** `lib/ui/components/app_button.dart`

**Variants:**
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

---

### 9.2 AppInput

**파일:** `lib/ui/components/app_input.dart`

**States:**
- `normal`: 기본 상태
- `focus`: 포커스 (accentRed 테두리)
- `success`: 성공 (natureGreen 테두리)
- `error`: 에러 (errorRed 테두리, 두꺼운 선)
- `disabled`: 비활성화

```dart
AppInput(
  caption: '이메일',
  value: 'user@example.com',
  state: InputState.normal,
  controller: _emailController,
)

// Error 상태
AppInput(
  caption: '비밀번호',
  value: '',
  state: InputState.error,
  errorMessage: '비밀번호를 입력해주세요',
)
```

---

### 9.3 TopNotification

**파일:** `lib/ui/components/top_notification.dart`

상단 알림 배너 (Alert/Success).

**타입:**
- `red`: 경고, 삭제, 중요한 알림 (`accentRed`)
- `green`: 성공, 완료 (`natureGreen`)

```dart
// 표시
TopNotificationManager.show(
  context,
  message: '알람이 삭제되었습니다.',
  actionLabel: '실행취소',
  type: TopNotificationType.red,
  onActionTap: () => _undo(),
);
```

---

### 9.4 CircularRipple

**파일:** `lib/ui/components/circular_ripple.dart`

원형 파동 애니메이션 위젯입니다.

```dart
CircularRipple(
  isActive: isRecording,
  color: AppColors.accentRed,
)
```

---

### 9.5 ProcessIndicator

**파일:** `lib/ui/components/process_indicator.dart`

프로세스 진행 상태를 표시하는 인디케이터입니다.

```dart
ProcessIndicator(
  currentStep: 2,
  totalSteps: 5,
)
```

---

## 📐 디자인 원칙

### 일관성 (Consistency)

- 모든 화면에서 동일한 디자인 토큰 사용
- AppFrame을 통한 일관된 레이아웃
- 컴포넌트 재사용 극대화

### 접근성 (Accessibility)

- 충분한 색상 대비 (WCAG AA 준수)
- 터치 영역 최소 44×44px
- SafeArea 자동 적용

### 확장성 (Scalability)

- 토큰 기반 시스템으로 테마 변경 용이
- 감정 캐릭터 확장 가능
- 컴포넌트 조합으로 새로운 UI 구성

---

## 🔧 개발 가이드

### Import

```dart
import 'package:frontend/ui/app_ui.dart';
```

위 한 줄로 모든 디자인 시스템 요소 접근:
- Layout (AppFrame, TopBar, BottomBar)
- Tokens (Colors, Typography, Spacing, Radius, Icons)
- Components (AppButton, AppInput, Bubbles)
- Characters (EmotionCharacter, AnimatedCharacter, EmotionColors)

---

### 새로운 화면 추가

1. `lib/app/` 하위에 기능별 폴더 생성
2. `_screen.dart` 파일 생성
3. `AppFrame` 사용하여 레이아웃 구성

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
  topBar: TopBar(title: '제목'),
  bottomBar: BottomButtonBar(primaryText: '확인'),
  body: content,
)

// Good: 말풍선 사용
ChatBubble(message: message)

// Good: 감정별 컬러 사용
final primaryColor = getEmotionPrimaryColor(EmotionId.joy);
Container(color: primaryColor)
```

### ❌ 피해야 할 사항

```dart
// Bad: 하드코딩된 값
Container(
  padding: EdgeInsets.all(24),  // AppSpacing.md 사용
  decoration: BoxDecoration(
    color: Color(0xFFFFFFFF),    // AppColors.pureWhite 사용
  ),
)

// Bad: Scaffold 직접 사용
Scaffold(
  appBar: AppBar(...),  // TopBar 사용
)

// Bad: 카드 사용 (말풍선 대신)
Card(
  child: ListTile(title: Text('메시지')),
)
```

---

## 📞 문의 및 기여

디자인 시스템 관련 문의사항이나 개선 제안은 팀 채널로 연락해주세요.

**마지막 업데이트**: 2025-12-09
