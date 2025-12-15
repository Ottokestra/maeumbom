# Maeumbom UI Design System

마음봄 앱의 **"감정 교감 인터페이스"** 디자인 시스템 가이드입니다.

---

## 🆕 최근 업데이트 (2025-12-15)

### 새로운 컴포넌트

- **HomeMainButtons**: 2x3 그리드 레이아웃 (캐릭터 + 5개 기능 버튼)
  - 첫 번째 셀: 사용자 감정 캐릭터 (투명 배경)
  - 나머지 5개: 봄이와 대화, 기억서랍, 마음리포트, 마음연습실, 신조어퀴즈
  - 기분 기반 색상 시스템
  - 아이콘 우측 정렬
- **AlarmListItem**: 알람/기억/이벤트 리스트 아이템
  - 2줄 레이아웃 (날짜/타입/시간 + 아이콘/내용)
  - 키워드 기반 동적 태그 색상 시스템
  - Dismissible 삭제 지원
  - 타입별 배지 및 아이콘
- **DateRangeSelector**: 날짜 범위 선택 컴포넌트
  - 이전/다음 날짜 네비게이션
  - 현재 날짜 표시
  - 알람 화면 통합
- **MemoryTimelineItem**: 기억 타임라인 아이템
- **ChoiceButton**: 사용자 선택지를 표시하는 버튼 컴포넌트
  - `ChoiceButton`: 개별 선택지 버튼
  - `ChoiceButtonGroup`: 가로/세로 레이아웃 지원 (2-5개 선택지)
  - 감정 기반 색상 시스템
  - 테두리/번호 표시 제어 가능
- **BottomVoiceBar**: 음성 입력 전용 3버튼 레이아웃 (TTS 토글, 마이크, 텍스트 모드)
- **BottomMenuBar**: 5탭 네비게이션 바 (중앙 마이크 버튼 포함)
- **HomeGaugeSection**: Fear & Greed Index 스타일 반원형 감정 게이지
- **HomeBannerSlider**: 마음연습실 소개 슬라이드 배너
- **BottomAddModalBar**: 재사용 가능한 모달 Bottom Sheet
- **SplashScreen**: Lottie 애니메이션 기반 스플래시 화면
- **QuestionProgressView**: 설문 및 연습용 질문/진행률 통합 컴포넌트


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
  color: AppColors.primaryColor,
  height: 40,
)
```

**디자인 스펙:**
- 높이: 40px (기본)
- 색상: `AppColors.primaryColor` (기본)
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
// 기본 사용 (타이핑 애니메이션)
EmotionBubble(
  message: '오늘 하루 어떠셨나요?',
  enableTypingAnimation: true,
  typingSpeed: 50,
)

// 민트색 배경 (Green 모드)
EmotionBubble(
  message: '좋은 하루 보내세요!',
  bgGreen: true,
)
```

**특징:**
- 연분홍 배경 (`bgLightPink`) 또는 민트색 배경 (`bgSoftMint`)
- **동적 높이**: 최소 60px ~ 최대 144px (4줄)
  - 짧은 텍스트: 내용에 맞게 작은 크기
  - 긴 텍스트: 최대 4줄까지 표시, 그 이상은 스크롤
- 스크롤 가능 (내용이 4줄 초과 시)
- 하단 삼각형 표시 (더 많은 컨텐츠 있을 때)
- 타이핑 애니메이션 지원
- **TTS 토글은 버블 외부에 배치** (BomiContent에서 관리)

---

#### 3.2.4 ListBubble

**파일:** `lib/ui/components/list_bubble.dart`

선택형 답변을 위한 리스트 버블입니다. `response_type: "list"`일 때 사용됩니다.

```dart
// 기본 사용
ListBubble(
  items: ['요가', '산책', '수영'],
  selectedIndex: -1,
  onItemSelected: (index, item) {
    print('Selected: $item');
    // 선택한 항목을 서버로 전송
  },
)

// 선택 후 비활성화
ListBubble(
  items: ['요가', '산책', '수영'],
  selectedIndex: 0,
  disabled: true, // 선택 후 다른 항목 비활성화
  onItemSelected: (index, item) {
    // 이미 선택됨
  },
)
```

**특징:**
- 아웃라인 스타일 (테두리만 있는 버블)
- 번호 표시 (원형 배지)
- 선택 시 강조 표시 (빨간색 테두리 + 배경 + 체크 아이콘)
- 선택 후 다른 항목 비활성화 (연한 회색 처리)
- 자동 텍스트 파싱 (`parseListItems()` 유틸리티)
- 각 항목은 독립적으로 클릭 가능

**텍스트 파싱:**
```dart
final items = parseListItems('''
갱년기에 좋은 운동 추천해줄게!

1. 요가 - 스트레칭과 명상을 통해 몸과 마음을 편안하게 해줘
2. 산책 - 가벼운 유산산소 운동으로 기분 전환에 좋아
3. 수영 - 관절에 무리 없이 전신 운동을 할 수 있어
''');
// 결과: ['요가 - 스트레칭과...', '산책 - 가벼운...', '수영 - 관절에...']
```

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
  static const Color userBg = AppColors.primaryColor;
  static const Color userText = AppColors.textWhite;
  
  // Bot Bubble
  static const Color botBg = AppColors.basicColor;
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

### 3.4 ToggleTokens

**파일:** `lib/ui/tokens/toggles.dart`

앱 전체에서 사용되는 토글(Switch) 스타일을 정의합니다.

```dart
class ToggleTokens {
  // Primary Toggle (Red) - 주요 토글
  static const Color primaryActiveThumb = AppColors.basicColor;      // 활성화 토글 원 (흰색)
  static const Color primaryActiveTrack = AppColors.primaryColor;      // 활성화 배경 (빨간색)
  static const Color primaryInactiveThumb = AppColors.basicColor;    // 비활성 토글 원 (흰색)
  static const Color primaryInactiveTrack = AppColors.borderLightGray; // 비활성 배경 (회색)

  // Secondary Toggle (Green) - 보조 토글
  static const Color secondaryActiveThumb = AppColors.basicColor;    // 활성화 토글 원 (흰색)
  static const Color secondaryActiveTrack = AppColors.secondaryColor;  // 활성화 배경 (초록색)
  static const Color secondaryInactiveThumb = AppColors.basicColor;  // 비활성 토글 원 (흰색)
  static const Color secondaryInactiveTrack = AppColors.borderLightGray; // 비활성 배경 (회색)

  // Toggle Scale
  static const double defaultScale = 0.75;  // 기본 크기
  static const double largeScale = 0.85;    // 큰 크기
  static const double smallScale = 0.65;    // 작은 크기
}
```

**사용 예시:**

```dart
// Primary 토글 (빨간색)
_buildToggle(
  value: ttsEnabled,
  onChanged: (value) => toggleTts(),
  style: ToggleStyle.primary(),
)

// Secondary 토글 (초록색)
_buildToggle(
  value: isEnabled,
  onChanged: (value) => toggle(),
  style: ToggleStyle.secondary(),
)

// 크기 조정
_buildToggle(
  value: isEnabled,
  onChanged: (value) => toggle(),
  style: ToggleStyle.primary(size: ToggleSize.large),
)
```

**토글 타입:**
- `ToggleType.primary` - 빨간색 (기본, TTS 토글 등)
- `ToggleType.secondary` - 초록색 (보조 기능)

**토글 크기:**
- `ToggleSize.small` - 0.65 배율
- `ToggleSize.normal` - 0.75 배율 (기본)
- `ToggleSize.large` - 0.85 배율

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
│  닉네임님,                    │
│  오늘 하루도 응원해요!           │
│  [나는 어떤 상태일까?]          │ ← 헤더 섹션
│                             │
│         [캐릭터]              │ ← 감정 캐릭터 (240×240)
│                             │
│     [대화 온도 막대]           │ ← 3단계 인디케이터
│                             │
├─────────────────────────────┤
│  [봄이] [알람] [리포트] [연습실]  │ ← 하단 메뉴 (4개)
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

#### 5.4.4 HomeGaugeSection

**파일:** `lib/app/home/components/home_gauge_section.dart`

"Fear & Greed Index" 스타일의 반원형 게이지로 사용자의 감정 상태를 시각화합니다.

**구성 요소:**
- 반원형 게이지 (320×150px)
- 진행률 표시 (0~100%)
- 감정 라벨 배지 (pill 형태)
- 좌/중/우 감정 라벨 (좌절, 슬픔, 기쁨)

**디자인 스펙:**
- **컨테이너**:
  - 배경: `basicColor` (흰색)
  - 모서리: 32px 둥근 모서리
  - 패딩: 가로 16px, 세로 8px
- **게이지**:
  - 크기: 320×150px
  - 배경: 회색 반원 (비활성)
  - 진행: 감정 색상 반원 (활성)
  - 선 두께: 24px
- **퍼센트 텍스트**:
  - 크기: 60px
  - 굵기: 800 (extra bold)
  - 색상: `textBlack`
- **감정 배지**:
  - 배경: 감정 색상 20% 투명도
  - 텍스트: 감정 색상, 700 weight
  - 모서리: pill 형태

```dart
HomeGaugeSection(
  temperaturePercentage: 0.65, // 0.0 ~ 1.0
  emotionColor: getEmotionPrimaryColor(EmotionId.fear),
)
```

**사용 예시:**
```dart
// 동적 감정 기반 게이지
final currentEmotion = EmotionId.joy;
final emotionColor = getEmotionPrimaryColor(currentEmotion);
final percentage = _calculateEmotionPercentage(currentEmotion);

HomeGaugeSection(
  temperaturePercentage: percentage,
  emotionColor: emotionColor,
)
```

---

#### 5.4.5 HomeBannerSlider

**파일:** `lib/app/home/components/home_banner_slider.dart`

마음연습실 기능을 소개하는 슬라이드 배너입니다. PageView를 사용하여 2개의 배너를 좌우로 스와이프할 수 있습니다.

**구성 요소:**
- 2개 배너 슬라이더 (관계 연습하기, 신조어 퀴즈)
- 페이지 인디케이터 (하단 점)
- 각 배너: 제목, 부제목, 화살표 아이콘

**디자인 스펙:**
- **배너 높이**: 100px
- **배너 1 (관계 연습하기)**:
  - 배경: `#FFE0B2` (연한 오렌지)
  - 텍스트: `#E65100` (진한 오렌지)
- **배너 2 (신조어 퀴즈)**:
  - 배경: `#C8E6C9` (연한 초록)
  - 텍스트: `#2E7D32` (진한 초록)
- **모서리**: 16px 둥근 모서리
- **패딩**: 가로 32px
- **인디케이터**:
  - 크기: 8×8px
  - 활성: `textPrimary`
  - 비활성: `borderLightGray`

```dart
HomeBannerSlider(
  onTraining1Tap: () {
    Navigator.pushNamed(context, '/training/relationship');
  },
  onTraining2Tap: () {
    Navigator.pushNamed(context, '/training/quiz');
  },
)
```

**특징:**
- 자동 스와이프 지원
- 탭하여 해당 연습실로 이동
- 현재 페이지 인디케이터 표시

---

#### 5.4.6 HomeMainButtons

**파일:** `lib/app/home/components/home_main_buttons.dart`

2x3 그리드 레이아웃으로 사용자 감정 캐릭터와 5개의 기능 버튼을 표시합니다.

**구성 요소:**
- **첫 번째 셀**: 사용자 감정 캐릭터 (투명 배경)
- **나머지 5개 셀**: 기능 버튼
  1. 봄이와 대화 (마이크 아이콘, 기분 기반 배경색)
  2. 기억 서랍 (알람 아이콘)
  3. 마음리포트 (차트 아이콘)
  4. 마음연습실 (앱 아이콘)
  5. 신조어퀴즈 (퀴즈 아이콘)

**디자인 스펙:**
- **그리드**: 2행 × 3열
- **셀 간격**: 8px
- **셀 높이**: 160px
- **캐릭터 셀**:
  - 배경: 투명 (기분 색상 배경 위에 배치)
  - 캐릭터 크기: 120px
  - 중앙 정렬
- **기능 버튼 셀**:
  - 배경: `basicColor` (흰색)
  - 모서리: 16px 둥근 모서리
  - 패딩: 16px
  - 아이콘: 우측 상단 정렬, 24×24px
  - 텍스트: 좌측 하단, `bodyBold`
  - **봄이와 대화 버튼만**: 기분 기반 배경색, 흰색 텍스트

**기분 기반 색상:**
```dart
// MoodColorHelper를 사용하여 일관된 색상 적용
final moodCategory = EmotionClassifier.classify(currentEmotion);
final moodMainColor = MoodColorHelper.getEmotionColor(currentEmotion);
final moodBgColor = MoodColorHelper.getBackgroundColor(moodCategory);
```

**사용 예시:**
```dart
// HomeNewScreen에서 사용
HomeMainButtons()
```

**특징:**
- 기분에 따라 "봄이와 대화" 버튼 색상 자동 변경
- 각 버튼 탭 시 해당 화면으로 네비게이션
- 캐릭터는 현재 선택된 감정 표시

---

#### 5.4.7 DailyMoodCheckWidget

**파일:** `lib/app/home/components/daily_mood_check_widget.dart`

일일 기분 체크를 위한 감정 선택 위젯입니다.

**구성 요소:**
- 3개 카테고리 (좋음, 보통, 나쁨)
- 각 카테고리별 랜덤 감정 캐릭터 3개
- 선택 시 확대 효과

```dart
DailyMoodCheckWidget(
  onEmotionSelected: (EmotionId emotion) {
    // 감정 선택 처리
    ref.read(dailyMoodProvider.notifier).selectEmotion(emotion);
  },
)
```

---

### 5.5 홈 화면 전체 구성 예시

```dart
class HomeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyState = ref.watch(dailyMoodProvider);
    final currentEmotion = dailyState.selectedEmotion ?? EmotionId.joy;
    final moodCategory = EmotionClassifier.classify(currentEmotion);
    final backgroundColor = _getBackgroundColor(moodCategory);

    return AppFrame(
      topBar: null,
      useSafeArea: false,
      statusBarStyle: SystemUiOverlayStyle.light,
      bottomBar: const BottomMenuBar(currentIndex: 0),
      body: Container(
        color: backgroundColor,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                // 헤더
                const HomeHeaderSection(),
                const SizedBox(height: AppSpacing.md),
                
                // 감정 캐릭터
                Center(
                  child: EmotionCharacter(
                    id: currentEmotion,
                    size: 240,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                
                // 감정 게이지
                HomeGaugeSection(
                  temperaturePercentage: 0.65,
                  emotionColor: getEmotionPrimaryColor(currentEmotion),
                ),
                const SizedBox(height: AppSpacing.lg),
                
                // 배너 슬라이더
                HomeBannerSlider(
                  onTraining1Tap: () => Navigator.pushNamed(context, '/training/relationship'),
                  onTraining2Tap: () => Navigator.pushNamed(context, '/training/quiz'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

---

### 5.6 일일 기분 체크 다이얼로그

홈 화면 진입 시 아직 오늘의 감정을 선택하지 않은 경우 자동으로 표시됩니다.

**동작:**
- `dailyMoodProvider.hasChecked`가 `false`일 때 500ms 후 표시
- 현재 화면이 최상위(`ModalRoute.isCurrent`)일 때만 표시
- "나중에" / "기록하기" 버튼 제공

---

### 5.9 똑똑 알람 (Alarm Screen) Design

알람 화면은 홈 화면의 디자인 언어를 계승하면서 기능적인 요소를 추가했습니다.

#### 디자인 철학
- **몰입형 헤더**: 배경색이 상태바 영역까지 확장되어 개방감을 줍니다 (투명 TopBar)
- **화이트 아이콘/텍스트**: 컬러풀한 배경 위 화이트 텍스트로 가독성을 확보합니다
- **일일 이벤트 분석**: `/analyze-daily` API를 통해 날짜별 이벤트 요약 표시
- **키워드 기반 태그**: 동적 색상 시스템으로 태그 시각화

---

#### 5.9.1 DateRangeSelector

**파일:** `lib/ui/components/date_range_selector.dart`

날짜 범위를 선택하고 네비게이션할 수 있는 컴포넌트입니다.

**구성 요소:**
- 이전 날짜 버튼 (왼쪽 화살표)
- 현재 날짜 표시 (YYYY년 MM월 DD일 형식)
- 다음 날짜 버튼 (오른쪽 화살표)

**디자인 스펙:**
- **높이**: 48px
- **배경**: 투명
- **텍스트**: `bodyBold`, 흰색
- **버튼**: 아이콘 버튼, 흰색 아이콘
- **간격**: 버튼 간 16px

**사용 예시:**
```dart
DateRangeSelector(
  currentDate: selectedDate,
  onPreviousDay: () {
    setState(() {
      selectedDate = selectedDate.subtract(Duration(days: 1));
    });
    _loadEvents();
  },
  onNextDay: () {
    setState(() {
      selectedDate = selectedDate.add(Duration(days: 1));
    });
    _loadEvents();
  },
)
```

**특징:**
- 알람 화면 상단에 배치
- 날짜 변경 시 이벤트 자동 로드
- 투명 배경으로 배경색과 조화

---

#### 5.9.2 AlarmListItem

**파일:** `lib/app/alarm/components/alarm_list_item.dart`

알람/기억/이벤트를 표시하는 리스트 아이템으로 2줄 레이아웃을 사용합니다.

**구성 요소:**

**1줄 (상단)**:
- 날짜 (MM/DD) + 요일
- 타입 배지 (기억/알림/이벤트)
- 시간 (HH:MM)
- 토글 스위치 (알림 타입만)

**2줄 (하단)**:
- 타입별 아이콘 (원형, 36×36px)
- 내용 텍스트 (최대 2줄)
- 태그 (키워드 기반 색상)

**디자인 스펙:**
- **컨테이너**:
  - 배경: `basicColor` (흰색)
  - 모서리: 12px 둥근 모서리
  - 테두리: 1px `borderLight`
  - 패딩: 16px
  - 하단 마진: 12px
- **날짜/요일**:
  - 날짜: `bodyBold`, 15px, `textPrimary`
  - 요일: `caption`, 12px, `textSecondary`
  - 너비: 50px
- **타입 배지**:
  - 패딩: 가로 8px, 세로 4px
  - 모서리: 8px 둥근 모서리
  - 타입별 배경/텍스트 색상
- **아이콘**:
  - 크기: 36×36px
  - 원형 배경 (타입별 색상)
  - 테두리: 1.5px
- **태그**:
  - 패딩: 가로 8px, 세로 3px
  - 모서리: 12px 둥근 모서리
  - 배경: 색상 15% 투명도
  - 테두리: 색상 30% 투명도

**키워드 기반 태그 색상:**
```dart
// 키워드별 색상 매핑
'알람/알림' → #FFB84C (노랑/오렌지)
'중요/긴급' → #D7454D (붉은색)
'약속/미팅/회의' → #7BC67E (초록색)
'기억/추억' → #FF8A80 (핑크/산호색)
'이벤트/행사' → #6C8CD5 (파랑색)
기타 → 해시 기반 6가지 색상 중 하나
```

**사용 예시:**
```dart
AlarmListItem(
  alarm: AlarmModel(
    id: 1,
    year: 2025,
    month: 12,
    day: 15,
    hour: 14,
    minute: 30,
    content: '병원 예약\n#중요 #알림',
    itemType: ItemType.alarm,
    isEnabled: true,
  ),
  onToggle: (value) {
    // 알림 활성화/비활성화
  },
  onDelete: () {
    // 알림 삭제
  },
)
```

**특징:**
- Dismissible로 스와이프 삭제 지원
- 태그는 `#`으로 시작하는 단어 자동 파싱
- 키워드 기반 동적 색상으로 시각적 구분
- 타입별 아이콘 및 배지로 직관적 구분
- 알림 타입만 토글 스위치 표시

---

#### 화면 구조


```
┌─────────────────────────────┐
│                             │ ← 상태바 (투명 배경, 흰색 아이콘)
│  <  똑똑 알람         ...   │ ← 투명 TopBar (흰색 아이콘/텍스트)
│                             │
│     제가 알람을              │
│     등록해드릴까요?           │
│                             │
│      (→)        [캐릭터]     │ ← 원형 화살표 아이콘, 캐릭터
│                             │
│ ┌─────────────────────────┐ │
│ │                         │ │
│ │   오전 07:00       (O)  │ │ ← 알람 리스트 패널
│ │   출근 준비              │ │    (흰색 배경, 둥근 모서리)
│ │                         │ │
│ └─────────────────────────┘ │
└─────────────────────────────┘
```

#### 주요 컴포넌트

**1. 원형 화살표 아이콘**
- 배경: 흰색 20% 투명도 (`Colors.white.withValues(alpha: 0.2)`)
- 모양: 원형 (`BoxShape.circle`)
- 아이콘: 흰색 `arrow_forward`

```dart
Container(
  width: 56,
  height: 56,
  decoration: BoxDecoration(
    color: Colors.white.withValues(alpha: 0.2),
    shape: BoxShape.circle,
  ),
  child: Icon(Icons.arrow_forward, color: AppColors.basicColor),
)
```

**2. 알람 리스트 패널**
- **확장형 UI**: 기본적으로 일부만 보이다가 드래그/클릭 시 확장됩니다
- **배경**: 흰색으로 깔끔하게 정리하여 컬러풀한 상단과 대비를 줍니다
- **상호작용**:
    - 접힘 상태: "UP" 화살표 (`keyboard_arrow_up_rounded`)
    - 펼침 상태: "DOWN" 화살표
    - "전체 보기" 버튼: `/alarm` 경로로 이동

---

### 5.7 스플래시 화면 (Splash Screen) Design

**파일:** `lib/app/onboarding/splash_screen.dart`

앱 시작 시 표시되는 스플래시 화면입니다. 마음봄 로고 애니메이션을 재생하며 인증 상태를 확인합니다.

#### 디자인 철학
- **미니멀**: 로고 애니메이션만 중앙에 표시
- **부드러운 전환**: Lottie 애니메이션으로 브랜드 경험 제공
- **빠른 로딩**: 최소 2초 표시 후 다음 화면으로 전환

#### 화면 구조

```
┌─────────────────────────────┐
│                             │ ← 상태바 (다크 아이콘)
│                             │
│                             │
│                             │
│       [로고 애니메이션]        │ ← Lottie 애니메이션 (256×256)
│                             │
│                             │
│                             │
│                             │
└─────────────────────────────┘
```

#### 디자인 스펙

- **배경색**: `basicGray` (#F5F5F5)
- **상태바**: 다크 아이콘 (`SystemUiOverlayStyle.dark`)
- **로고 애니메이션**:
  - 파일: `assets/images/logo/splash.json`
  - 크기: 256×256px
  - 재생: 1회만 (`repeat: false`)
  - 위치: 화면 중앙

#### 동작 흐름

1. **스플래시 표시**: 앱 시작 시 자동 표시
2. **애니메이션 재생**: Lottie 애니메이션 1회 재생
3. **인증 확인**: 백그라운드에서 인증 상태 확인
4. **화면 전환**: 최소 2초 후 다음 화면으로 이동
   - 로그인 상태: `/home`으로 이동
   - 비로그인 상태: `/login`으로 이동

**구현 예시:**

```dart
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    // 최소 2초 대기
    final minDisplayTime = Future.delayed(const Duration(seconds: 2));

    // 인증 상태 확인
    while (mounted) {
      final authState = ref.read(authProvider);
      
      if (!authState.isLoading) {
        await minDisplayTime;
        
        if (!mounted) return;

        // 화면 전환
        final isLoggedIn = authState.value != null;
        if (isLoggedIn) {
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          Navigator.pushReplacementNamed(context, '/login');
        }
        return;
      }
      
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.basicGray,
        body: Center(
          child: Lottie.asset(
            'assets/images/logo/splash.json',
            width: 256,
            height: 256,
            repeat: false,
          ),
        ),
      ),
    );
  }
}
```

---

### 5.8 일일 기분 체크 다이얼로그

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

마음봄의 메인 네비게이션 바로 5개의 탭을 제공합니다. 중앙에는 마이크 버튼이 돌출되어 음성 입력을 강조합니다.

```
┌──────────────────────────────────────┐
│                                      │
│  홈   마음서랍   🎙️   마음연습실  마이  │
│                ↑                     │
│            (중앙 돌출)                 │
└──────────────────────────────────────┘
```

**구성:**
- 탭 0: **홈** (`icon-home.svg`)
- 탭 1: **마음서랍** (`icon-report.svg`)
- 탭 2: **봄이 (마이크)** - 중앙 원형 버튼 (`icon-mic.svg`)
- 탭 3: **마음연습실** (`icon-apps.svg`)
- 탭 4: **마이페이지** (`icon-mypage.svg`)

**디자인 스펙:**
- **높이**: 90px (전체)
- **배경색**: `pureWhite` (기본값, 커스터마이징 가능)
- **상단 테두리**: 1px, `borderLight`
- **중앙 마이크 버튼**:
  - 크기: 56×56px
  - 배경: `primaryColor` (기본값, 커스터마이징 가능)
  - 아이콘: 흰색 마이크 (42×42px)
  - 위치: 상단으로 20px 돌출
- **메뉴 아이템**:
  - 아이콘 크기: 28×28px
  - 라벨: `label` 스타일 (8px, 500 weight)
  - 선택 시: `primaryColor`
  - 미선택 시: `textPrimary`

**사용 예시:**
```dart
// 기본 사용
BottomMenuBar(
  currentIndex: 0,
  onTap: (index) {
    // 탭 전환 로직
    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/home');
        break;
      case 1:
        Navigator.pushNamed(context, '/alarm');
        break;
      case 2:
        Navigator.pushNamed(context, '/bomi');
        break;
      case 3:
        Navigator.pushNamed(context, '/training');
        break;
      case 4:
        Navigator.pushNamed(context, '/mypage');
        break;
    }
  },
)

// 색상 커스터마이징
BottomMenuBar(
  currentIndex: 2,
  backgroundColor: AppColors.warmWhite,
  foregroundColor: AppColors.textSecondary,
  primaryColor: AppColors.secondaryColor,
  onTap: (index) => _handleNavigation(index),
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
| `secondaryColor` | `#2F6A53` | 성공 상태, 자연 테마 |
| `errorRed` | `#C62828` | 에러, 경고 |

#### Neutral Colors

| 이름 | 값 | 용도 |
|------|------|------|
| `basicColor` | `#FFFFFF` | 기본 배경 |
| `pureWhite` | `#FFFFFF` | 순수 흰색 (네비게이션 바) |
| `basicGray` | `#F5F5F5` | 연한 회색 배경 (스플래시 화면) |
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
AppColors.bgBasic      // 기본 배경 (basicColor)
AppColors.bgWarm       // 따뜻한 배경 (warmWhite)
AppColors.bgLightPink  // 핑크 배경
AppColors.bgSoftMint   // 민트 배경
AppColors.bgRed        // 레드 배경 (accentRed)
AppColors.bgGreen      // 그린 배경 (secondaryColor)

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
AppColors.success  // secondaryColor
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

**파일:** `lib/ui/layout/`

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

#### 8.3.4 BottomAddModalBar

**파일:** `lib/ui/layout/bottom_add_modal_bar.dart`

재사용 가능한 모달 Bottom Sheet 컴포넌트입니다. 타이틀과 커스텀 컨텐츠를 주입받아 표시합니다.

**디자인 스펙:**
- **배경**: `basicColor` (흰색)
- **모서리**: 상단 좌우 32px 둥근 모서리
- **패딩**: 24px (기본) + 키보드 높이 (자동)
- **헤더**:
  - 타이틀: `h3` 스타일, 700 weight, 중앙 정렬
  - 닫기 버튼: 우측 상단, `close_rounded` 아이콘 (24px)
- **컨텐츠**: 주입받은 child 위젯 표시
- **SafeArea**: 하단 안전 영역 자동 적용

**사용 예시:**

```dart
// 기본 사용 - show 헬퍼 메서드
BottomAddModalBar.show(
  context,
  title: '알람 추가',
  child: Column(
    children: [
      AppInput(caption: '알람 제목', controller: _titleController),
      const SizedBox(height: AppSpacing.md),
      // 시간 선택 위젯
      TimePicker(onTimeSelected: (time) => _selectedTime = time),
      const SizedBox(height: AppSpacing.lg),
      AppButton(
        text: '저장',
        variant: ButtonVariant.primaryRed,
        onTap: () {
          _saveAlarm();
          Navigator.pop(context);
        },
      ),
    ],
  ),
);

// 직접 사용
showModalBottomSheet(
  context: context,
  backgroundColor: Colors.transparent,
  isScrollControlled: true,
  builder: (context) => BottomAddModalBar(
    title: '메모 작성',
    onClose: () => Navigator.pop(context),
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: TextField(
        maxLines: 5,
        decoration: InputDecoration(
          hintText: '메모를 입력하세요',
        ),
      ),
    ),
  ),
);
```

**특징:**
- 키보드 자동 대응 (`viewInsets.bottom`)
- 투명 배경으로 둥근 모서리 표현
- 닫기 버튼 옵션 (`onClose` 콜백)
- 스크롤 제어 가능 (`isScrollControlled`)
- 재사용 가능한 헬퍼 메서드 제공

---

#### 8.3.5 BottomHomeBar

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
- `success`: 성공 (secondaryColor 테두리)
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
- `green`: 성공, 완료 (`secondaryColor`)

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

### 9.4 Toggle

**파일:** `lib/ui/tokens/toggles.dart`

일관된 토글(Switch) 스타일을 제공합니다.

**사용 예시:**

```dart
// Primary 토글 (빨간색) - TTS 등
_buildToggle(
  value: ttsEnabled,
  onChanged: (value) => toggleTts(),
  style: ToggleStyle.primary(),
)

// Secondary 토글 (초록색) - 보조 기능
_buildToggle(
  value: isEnabled,
  onChanged: (value) => toggle(),
  style: ToggleStyle.secondary(),
)

// 크기 조정
_buildToggle(
  value: isEnabled,
  onChanged: (value) => toggle(),
  style: ToggleStyle.primary(size: ToggleSize.large),
)

// 헬퍼 메서드 구현
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

**토글 타입:**
- `ToggleStyle.primary()` - 빨간색 (기본, TTS 토글 등)
- `ToggleStyle.secondary()` - 초록색 (보조 기능)

**토글 크기:**
- `ToggleSize.small` - 0.65 배율
- `ToggleSize.normal` - 0.75 배율 (기본)
- `ToggleSize.large` - 0.85 배율

---

### 9.5 ChoiceButton

**파일:** `lib/ui/components/choice_button.dart`

사용자 선택지를 표시하는 버튼 컴포넌트입니다. 단일 버튼(`ChoiceButton`)과 버튼 그룹(`ChoiceButtonGroup`)으로 구성됩니다.

#### 9.5.1 ChoiceButton (개별 버튼)

개별 선택지 버튼을 표시합니다.

```dart
QuestionProgressView(
  currentStep: 0,
  totalSteps: 10,
  questionNumber: 'Q1.',
  questionText: '오늘 기분이 어떠신가요?',
  media: Image.asset('assets/images/scenario.png'), // 선택적 미디어 (질문 아래 표시)
  content: ChoiceButtonGroup(...), // 선택지 영역
)
```

**파라미터:**
- `currentStep` (필수): 현재 단계 (0-based)
- `totalSteps` (필수): 전체 단계 수
- `questionNumber`: 질문 번호 텍스트 (예: "Q1.")
- `questionText`: 질문 텍스트
- `titleWidget`: 질문 텍스트 대신 사용할 커스텀 위젯 (RichText 등)
- `media`: 질문 텍스트 아래에 표시할 미디어/이미지 위젯
- `content` (필수): 하단 콘텐츠 영역 (주로 `ChoiceButtonGroup`)

**특징:**
- 상단 진행률 바 자동 계산 및 표시
- 일관된 질문 텍스트 스타일
- 유연한 미디어 및 콘텐츠 영역 (질문 -> 미디어 -> 콘텐츠 순서)
#### 9.5.2 ChoiceButtonGroup (버튼 그룹)

여러 선택지를 그룹으로 표시합니다.

```dart
ChoiceButtonGroup(
  choices: ['선택지 1', '선택지 2'],
  selectedIndex: 0,
  layout: ChoiceLayout.horizontal,  // 가로/세로 레이아웃 선택
  emotionIds: [EmotionId.relief, EmotionId.joy],
  showBorder: true,
  showNumber: true,
  onChoiceSelected: (index, choice) {
    print('Selected: $choice');
  },
)
```

**파라미터:**
- `choices` (필수): 선택지 텍스트 리스트
- `selectedIndex`: 현재 선택된 인덱스 (-1이면 선택 안 됨)
- `onChoiceSelected`: 선택 콜백 `(int index, String choice)`
- `layout`: 레이아웃 타입 (기본값: `ChoiceLayout.vertical`)
  - `ChoiceLayout.horizontal`: **가로 배치** - 선택지를 가로로 나란히 배치 (주로 2개)
  - `ChoiceLayout.vertical`: **세로 배치** - 선택지를 세로로 쌓아서 배치 (2-5개)
- `emotionIds`: 각 선택지별 감정 ID (null이면 기본 패턴 사용)
- `showBorder`: 테두리 표시 여부 (기본값: true)
- `showNumber`: 번호 표시 여부 (기본값: true)

**레이아웃 선택 가이드:**

| 선택지 개수 | 권장 레이아웃 | 이유 |
|-----------|-------------|------|
| 2개 | `horizontal` | 화면을 효율적으로 사용하고 선택이 명확함 |
| 3-5개 | `vertical` | 긴 텍스트도 편하게 읽을 수 있음 |

**Note**: 레이아웃은 선택지 개수에 따라 자동 결정되지 않으며, 개발자가 `layout` 파라미터로 직접 지정해야 합니다.

**디자인 스펙:**

- **배경색**: 감정별 `secondary` 색상 20% 투명도
- **테두리**: 
  - 선택 시: 감정별 `primary` 색상
  - 미선택 시: 감정별 `primary` 색상 50% 투명도
- **모서리**: 16px 둥근 모서리
- **패딩**: 18px
- **번호 표시**:
  - 크기: 32×32px
  - 배경: 흰색
  - 텍스트: `textPrimary`, 16px, 700 weight
- **간격**:
  - 버튼 간: 12px

**기본 감정 패턴:**

1. `EmotionId.relief` (파랑)
2. `EmotionId.joy` (노랑)
3. `EmotionId.love` (핑크)
4. `EmotionId.interest` (보라)
5. `EmotionId.confidence` (골드)

**사용 예시:**

```dart
// 가로 배치 (2개 선택지) - 짧은 답변에 적합
ChoiceButtonGroup(
  choices: ['예', '아니오'],
  layout: ChoiceLayout.horizontal,
  onChoiceSelected: (index, choice) {
    print('Selected: $choice');
  },
)

// 가로 배치 (3개 선택지도 가능)
ChoiceButtonGroup(
  choices: ['좋음', '보통', '나쁨'],
  layout: ChoiceLayout.horizontal,
  emotionIds: [EmotionId.joy, EmotionId.relief, EmotionId.sadness],
  onChoiceSelected: (index, choice) {
    _handleChoice(choice);
  },
)

// 세로 배치 (2개 선택지) - 긴 텍스트에 적합
ChoiceButtonGroup(
  choices: [
    '네, 지금 바로 시작하고 싶어요',
    '아니요, 나중에 할게요'
  ],
  layout: ChoiceLayout.vertical,
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
    _handleChoice(choice);
  },
)

// 선택지 개수에 따라 자동으로 레이아웃 결정
ChoiceButtonGroup(
  choices: choices,
  layout: choices.length == 2 
    ? ChoiceLayout.horizontal 
    : ChoiceLayout.vertical,
  onChoiceSelected: (index, choice) {
    _handleChoice(choice);
  },
)

// 테두리 없이, 번호 표시 없이
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

---

### 9.6 CircularRipple

**파일:** `lib/ui/components/circular_ripple.dart`

원형 파동 애니메이션 위젯입니다.

```dart
CircularRipple(
  isActive: isRecording,
  color: AppColors.primaryColor,
)
```

---

### 9.7 ProcessIndicator

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
    color: Color(0xFFFFFFFF),    // AppColors.basicColor 사용
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

## 🎤 9. Bottom Bar Components

### 9.1 BottomInputBar (텍스트 입력 바)

**파일:** `lib/ui/layout/bottom_input_bars.dart`

텍스트 메시지 입력을 위한 Bottom Bar입니다.

#### 특징

- 텍스트 입력 필드 항상 표시
- 마이크 ↔ 전송 버튼 자동 토글
- 텍스트 입력 시 전송 버튼으로 변경
- 간소화된 API

#### 사용 예시

```dart
BottomInputBar(
  controller: _textController,
  hintText: '메시지를 입력하세요',
  onSend: () {
    // 전송 버튼 탭 시
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      sendMessage(text);
      _textController.clear();
    }
  },
  onMicTap: () {
    // 마이크 버튼 탭 시 (Voice Bar로 전환)
    setState(() => _showVoiceBar = true);
  },
)
```

#### API

| 파라미터 | 타입 | 필수 | 기본값 | 설명 |
|---------|------|------|--------|------|
| `controller` | `TextEditingController` | ✅ | - | 텍스트 입력 컨트롤러 |
| `hintText` | `String` | ❌ | '메시지를 입력하세요' | 플레이스홀더 텍스트 |
| `onSend` | `VoidCallback?` | ❌ | null | 전송 버튼 탭 콜백 |
| `onMicTap` | `VoidCallback?` | ❌ | null | 마이크 버튼 탭 콜백 |
| `backgroundColor` | `Color` | ❌ | `AppColors.basicColor` | 배경색 |

#### 디자인 스펙

- **높이**: 100px + safeArea bottom
- **배경색**: `basicColor` (흰색)
- **입력 필드**: 
  - 배경: `warmWhite`
  - 테두리: `borderLight`
  - 둥근 모서리: `pill`
- **버튼**:
  - 크기: 44×44
  - 배경: `primaryColor` (빨간색)
  - 아이콘: 흰색
  - 둥근 모서리: `pill`

---

### 9.2 BottomVoiceBar (음성 입력 바)

**파일:** `lib/ui/layout/bottom_voice_bar.dart`

음성 입력을 위한 3버튼 레이아웃 Bottom Bar입니다.

#### 특징

- 3버튼 레이아웃 (TTS 토글, 마이크, 텍스트 모드)
- 가운데 마이크 버튼 크게 표시 (80×80)
- 음성 상태별 애니메이션
- 원형 파동 효과

#### 사용 예시

```dart
BottomVoiceBar(
  voiceState: chatState.voiceState,
  onMicTap: () {
    // 마이크 버튼 탭 시 (녹음 시작/중지)
    if (isRecording) {
      stopRecording();
    } else {
      startRecording();
    }
  },
  onTextModeTap: () {
    // 텍스트 버튼 탭 시 (Input Bar로 전환)
    setState(() => _showVoiceBar = false);
  },
  // TTS 기능은 선택적
  isTtsEnabled: true,
  onTtsToggle: () {
    toggleTts();
  },
)
```

#### API

| 파라미터 | 타입 | 필수 | 기본값 | 설명 |
|---------|------|------|--------|------|
| `voiceState` | `VoiceInterfaceState` | ✅ | - | 현재 음성 상태 |
| `onMicTap` | `VoidCallback` | ✅ | - | 마이크 버튼 탭 콜백 |
| `onTextModeTap` | `VoidCallback` | ✅ | - | 텍스트 모드 전환 콜백 |
| `isTtsEnabled` | `bool?` | ❌ | null | TTS 활성화 여부 |
| `onTtsToggle` | `VoidCallback?` | ❌ | null | TTS 토글 콜백 |
| `backgroundColor` | `Color` | ❌ | `AppColors.basicColor` | 배경색 |

#### 음성 상태별 표시

| 상태 | 버튼 색상 | 아이콘/애니메이션 | 파동 효과 |
|------|----------|-----------------|----------|
| `idle` | `primaryColor` | 마이크 아이콘 | ❌ |
| `loading` | `primaryColor` | 타이핑 애니메이션 (점 3개) | ✅ |
| `listening` | `primaryColor` | 파형 애니메이션 | ✅ |
| `processing` | `orangeAccent` | 타이핑 애니메이션 | ✅ (breathing) |
| `replying` | `green` | 체크 아이콘 | ✅ |

#### 버튼 레이아웃

```
┌─────────────────────────────────┐
│  [TTS]    [마이크]    [텍스트]    │
│   50px      80px      50px     │
└─────────────────────────────────┘
```

#### 디자인 스펙

- **높이**: 100px + safeArea bottom
- **배경색**: `basicColor` (흰색)
- **왼쪽 버튼 (TTS)**:
  - 크기: 50×50
  - ON: `primaryColor` 테두리 + 연한 배경
  - OFF: `borderLight` 테두리 + `warmWhite` 배경
- **가운데 버튼 (마이크)**:
  - 크기: 80×80 (크게)
  - 배경: 상태별 색상
  - 그림자: 활성화 시 강조
- **오른쪽 버튼 (텍스트)**:
  - 크기: 50×50
  - 배경: `warmWhite`
  - 아이콘: `edit` (`primaryColor`)

#### 애니메이션

**파형 애니메이션** (listening):
- 4개 막대, 1000ms 주기
- 높이: 14~32px

**타이핑 애니메이션** (loading, processing):
- 3개 점, 1200ms 주기
- 투명도 변화

**파동 효과**:
- listening/replying: 3개 원형 파동
- processing: breathing 효과

---

## 📞 문의 및 기여

디자인 시스템 관련 문의사항이나 개선 제안은 팀 채널로 연락해주세요.

**마지막 업데이트**: 2025-12-13
