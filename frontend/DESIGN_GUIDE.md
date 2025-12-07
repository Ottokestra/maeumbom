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

| ID | 이름 | 캐릭터 | 컬러 힌트 | 사용 예시 |
|----|------|---------|----------|----------|
| `joy` | 기쁨 | 해바라기 | Yellow `#FFD54F` | 행복한 순간 |
| `excitement` | 흥분 | 별 | Orange `#FF9800` | 기대감, 설렘 |
| `confidence` | 자신감 | 사자 | Gold `#FFC107` | 성취, 당당함 |
| `love` | 사랑 | 펭귄 | Pink `#F06292` | 애정, 사랑 |
| `relief` | 안심 | 사슴 | Mint `#80CBC4` | 평온, 안정 |
| `enlightenment` | 깨달음 | 전구 | LightBlue `#4FC3F7` | 통찰, 이해 |
| `interest` | 흥미 | 부엉이 | Purple `#AB47BC` | 호기심, 관심 |

#### 부정 감정 (10개)

| ID | 이름 | 캐릭터 | 컬러 힌트 | 사용 예시 |
|----|------|---------|----------|----------|
| `discontent` | 불만 | 당근 | Brown `#8D6E63` | 거슬림, 짜증 |
| `shame` | 수치 | 복숭아 | PeachPink `#FFAB91` | 창피함, 부끄러움 |
| `sadness` | 슬픔 | 고래 | DeepBlue `#5C6BC0` | 상실, 우울 |
| `guilt` | 죄책감 | 곰 | DarkBrown `#6D4C41` | 미안함, 후회 |
| `depression` | 우울 | 돌 | Gray `#78909C` | 무기력, 침체 |
| `boredom` | 무료 | 나무늘보 | LightGray `#B0BEC5` | 심심함, 무료함 |
| `contempt` | 경멸 | 가지 | Purple `#7E57C2` | 무시, 경멸 |
| `anger` | 화 | 불 | Red `#E53935` | 분노, 화남 |
| `fear` | 공포 | 쥐 | DarkGray `#546E7A` | 두려움, 불안 |
| `confusion` | 혼란 | 로봇 | Silver `#90A4AE` | 갈피 상실 |

---

### 1.2 캐릭터 사용 패턴

#### 홈 화면 - 주간 대표 캐릭터

```dart
// 백엔드 API에서 대표 감정 받아오기
EmotionCharacter(
  id: EmotionId.joy,  // API 응답으로 받은 감정 ID
  highRes: true,      // 홈 화면은 고해상도 사용
  size: 180,          // 큰 사이즈로 표시
)
```

**홈 화면 구조 예시:**
```
     🌟 금주의 감정 캐릭터 🌟
             [기쁨 😊]

          (해바라기 캐릭터)
           (180x180)

       "오늘 하루 어떠셨나요?"
         (AppTypography.h2)

    (~ 음성 파동 애니메이션 ~)
        (VoiceWaveform)

    🎤    [ 음성 입력 ]    ✏️
     (마이크)  (버튼)   (텍스트)
```

#### 말풍선 내부 - 감정 아이콘

```dart
// 말풍선 내부 작은 아이콘으로 사용
EmotionCharacter(
  id: EmotionId.sadness,
  highRes: false,     // 일반 해상도
  size: 32,           // 작은 사이즈
)
```

#### 감정 리포트 - 감정 히스토리

```dart
// 감정 리포트에서 중간 사이즈로 표시
EmotionCharacter(
  id: EmotionId.confidence,
  highRes: true,
  size: 80,
)
```

---

### 1.3 캐릭터 에셋 구조

#### 현재 구조 (정적 PNG)

```
assets/characters/
  ├─ normal/  (일반 해상도, 200x200)
  │   ├─ char_joy.png
  │   ├─ char_anger.png
  │   └─ ... (17개)
  └─ high/    (고해상도, 400x400)
      ├─ char_joy.png
      ├─ char_anger.png
      └─ ... (17개)
```

#### 향후 확장 (애니메이션 대비)

```
assets/characters/
  ├─ images/  (정적 이미지)
  └─ animations/  (향후 추가)
      ├─ lottie/
      │   └─ char_joy.json
      └─ live2d/
          └─ char_joy.moc3
```

---

### 1.4 구현 위치

**파일:** [lib/ui/characters/app_characters.dart](lib/ui/characters/app_characters.dart)

이미 완벽하게 구현되어 있으며, 추가 작업 불필요합니다.

**주요 클래스:**
- `EmotionId`: 17개 감정 enum
- `EmotionMeta`: 감정별 메타데이터 (이름, 캐릭터, 에셋 경로)
- `EmotionCharacter`: 위젯 (이미지 렌더링)

---

### 1.5 API 연동 예시

#### 주간 대표 감정 조회

```dart
// API 엔드포인트 (예시)
GET /api/emotion/weekly-representative

// 응답
{
  "emotionId": "joy",
  "intensity": "high",  // "normal" | "high"
  "message": "이번 주는 기쁨이 가득했어요!"
}

// 사용 예시
final response = await emotionService.getWeeklyEmotion();
final emotionId = EmotionId.values.firstWhere(
  (e) => e.name == response.emotionId,
  orElse: () => EmotionId.confusion,  // Fallback
);

EmotionCharacter(
  id: emotionId,
  highRes: true,
  size: 180,
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

### 2.2 BottomInputBar 사용 패턴

#### 기본 사용

```dart
BottomInputBar(
  controller: _textController,
  hintText: '메시지를 입력하세요',
  onSend: () => _handleTextSend(),
  onMicrophoneTap: () => _handleMicToggle(),
)
```

**특징:**
- 텍스트 입력 시: 전송 아이콘 자동 표시
- 빈 입력 시: 마이크 아이콘 표시
- 동적 아이콘 전환으로 사용자 의도 명확화

---

### 2.3 음성 입력 상태별 UI

#### 대기 상태 (기본)

```
┌─────────────────────────────────┐
│ [메시지를 입력하세요...]   🎤   │
└─────────────────────────────────┘
```

#### 녹음 중

```
┌─────────────────────────────────┐
│ 🎤 녹음 중...  ~~~~~~  [중지]  │
│          (음성 파동)            │
└─────────────────────────────────┘
```

#### 텍스트 입력 중

```
┌─────────────────────────────────┐
│ [안녕하세요!]            [전송] │
└─────────────────────────────────┘
```

---

### 2.4 VoiceWaveform 컴포넌트 (향후 구현)

#### 컴포넌트 위치

**파일:** `lib/ui/components/voice_waveform.dart` (신규 생성 필요)

#### 인터페이스

```dart
class VoiceWaveform extends StatefulWidget {
  final bool isActive;        // 녹음 중 여부
  final Color color;          // 파동 색상
  final double height;        // 높이

  const VoiceWaveform({
    this.isActive = true,
    this.color = AppColors.accentRed,
    this.height = 40,
  });
}
```

#### 사용 예시

```dart
// 홈 화면에서 음성 파동 표시
VoiceWaveform(
  isActive: isRecording,
  color: AppColors.accentRed,
  height: 40,
)

// 채팅 화면에서 작게 표시
VoiceWaveform(
  isActive: isRecording,
  color: AppColors.accentCoral,
  height: 24,
)
```

#### 구현 방식

```dart
class _VoiceWaveformState extends State<VoiceWaveform>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(double.infinity, widget.height),
      painter: WaveformPainter(
        animation: _controller,
        color: widget.color,
        isActive: widget.isActive,
      ),
    );
  }
}

class WaveformPainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;
  final bool isActive;

  // Sine wave 그리기 로직
  // 실시간 오디오 레벨에 따라 진폭 변화 (향후 확장)
}
```

**디자인 스펙:**
- 높이: 40px (기본)
- 색상: `AppColors.accentRed` (기본)
- 파동: 3-5개 바 (Sine wave 형태)
- 주기: 1.5초
- 이징: `Curves.easeInOut`

---

### 2.5 권한 처리

#### 이미 구현됨

**파일:**
- [lib/core/services/chat/permission_service.dart](lib/core/services/chat/permission_service.dart)
- [lib/core/services/chat/audio_service.dart](lib/core/services/chat/audio_service.dart)

#### 권한 요청 흐름

1. 마이크 버튼 탭
2. 권한 확인 (`PermissionService`)
3. 권한 없으면 다이얼로그 표시
4. 권한 있으면 녹음 시작 (`AudioService`)

**권한 거부 시 메시지 예시:**
```dart
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('마이크 권한 필요'),
    content: Text('음성 입력을 위해 마이크 권한이 필요합니다.'),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text('취소'),
      ),
      TextButton(
        onPressed: () => openAppSettings(),
        child: Text('설정으로 이동'),
      ),
    ],
  ),
);
```

---

### 2.6 음성 입력 Best Practices

#### ✅ 권장사항

```dart
// Good: 명확한 상태 표시
if (isRecording) {
  return VoiceWaveform(isActive: true);
} else {
  return Icon(Icons.mic, color: AppColors.accentRed);
}

// Good: 사용자에게 피드백 제공
AppButton(
  text: isRecording ? '녹음 중지' : '음성 입력',
  variant: isRecording
    ? ButtonVariant.secondaryRed
    : ButtonVariant.primaryRed,
)
```

#### ❌ 피해야 할 사항

```dart
// Bad: 상태 표시 없음
IconButton(
  icon: Icon(Icons.mic),
  onPressed: toggleRecording,  // 녹음 중인지 알 수 없음
)

// Bad: 텍스트 입력만 제공
TextField(
  decoration: InputDecoration(
    hintText: '메시지 입력',
    // 마이크 버튼 없음
  ),
)
```

---

## 🗯 3. Bubble Component System

### 3.1 말풍선 디자인 철학

마음봄은 카드 대신 **말풍선(Bubble)**으로 주로 정보를 전달합니다.

#### 왜 말풍선인가?

- **대화 느낌**: 카드는 정보 전달, 말풍선은 대화
- **친근함**: 딱딱한 사각형보다 부드러운 곡선
- **감정 표현**: 말풍선 꼬리로 화자 구분

---

### 3.2 Bubble 타입

#### 3.2.1 ChatBubble (User/Bot)

**현재 구현:** [lib/app/chat/chat_screen.dart](lib/app/chat/chat_screen.dart) (404-478줄)

**특징:**
- User: 우측 정렬, `accentRed` 배경, 흰색 텍스트
- Bot: 좌측 정렬, 흰색 배경, `borderLight` 테두리
- 하단 모서리 한쪽만 각짐 (꼬리 효과)

**사용 예시:**

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
    text: '좋은 하루를 보내셨군요! 어떤 일이 있었나요?',
    isUser: false,
    timestamp: DateTime.now(),
  ),
)
```

**독립화 필요:**

현재 `chat_screen.dart` 내부에 정의되어 있어 재사용 불가.

**제안:** `lib/ui/components/chat_bubble.dart`로 이동

```dart
// 신규 파일: lib/ui/components/chat_bubble.dart
class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    // 기존 구현 이동
  }
}
```

---

#### 3.2.2 SystemBubble (신규 필요)

**목적:** 시스템 메시지 표시 (안내, 피드백, 시간)

**파일:** `lib/ui/components/system_bubble.dart` (신규 생성)

**인터페이스:**

```dart
enum SystemBubbleType { info, success, warning }

class SystemBubble extends StatelessWidget {
  final String text;
  final SystemBubbleType type;

  const SystemBubble({
    required this.text,
    this.type = SystemBubbleType.info,
  });
}
```

**사용 예시:**

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

**스타일 스펙:**

```dart
// 중앙 정렬
Alignment.center

// 배경색
info:    AppColors.bgLightPink.withOpacity(0.5)
success: AppColors.bgSoftMint.withOpacity(0.5)
warning: AppColors.lightPink

// 텍스트
style: AppTypography.caption
color: AppColors.textSecondary

// 크기
padding: EdgeInsets.symmetric(
  horizontal: AppSpacing.sm,
  vertical: AppSpacing.xs,
)
borderRadius: BorderRadius.circular(AppRadius.pill)
```

---

#### 3.2.3 EmotionBubble (신규 필요)

**목적:** 감정 캐릭터 + 간단한 메시지

**파일:** `lib/ui/components/emotion_bubble.dart` (신규 생성)

**인터페이스:**

```dart
class EmotionBubble extends StatelessWidget {
  final EmotionId emotion;
  final String message;
  final VoidCallback? onTap;

  const EmotionBubble({
    required this.emotion,
    required this.message,
    this.onTap,
  });
}
```

**사용 예시:**

```dart
// 감정 추천
EmotionBubble(
  emotion: EmotionId.joy,
  message: '기분 좋은 하루네요!',
  onTap: () => _showEmotionDetail(EmotionId.joy),
)

// 감정 히스토리
EmotionBubble(
  emotion: EmotionId.sadness,
  message: '어제는 조금 슬펐어요',
)
```

**레이아웃:**

```
┌─────────────────────────────────┐
│  [캐릭터]  "메시지 텍스트"           │
│   (32px)   (body 스타일)          │
└─────────────────────────────────┘
```

**구현 예시:**

```dart
class EmotionBubble extends StatelessWidget {
  final EmotionId emotion;
  final String message;
  final VoidCallback? onTap;

  const EmotionBubble({
    required this.emotion,
    required this.message,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: BubbleTokens.chatPadding,
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          border: Border.all(color: AppColors.borderLight),
          borderRadius: BorderRadius.circular(BubbleTokens.chatRadius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            EmotionCharacter(
              id: emotion,
              size: 32,
              highRes: false,
            ),
            SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                message,
                style: AppTypography.body,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

### 3.3 BubbleTokens (신규 필요)

**파일:** `lib/ui/tokens/bubble_tokens.dart` (신규 생성)

**목적:** 말풍선 스타일 일관성 유지

```dart
class BubbleTokens {
  // Padding
  static const chatPadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.sm,
    vertical: 12,
  );

  static const systemPadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.sm,
    vertical: AppSpacing.xs,
  );

  // Radius
  static const chatRadius = AppRadius.md;
  static const systemRadius = AppRadius.pill;

  // Max Width
  static const maxWidthRatio = 0.85;  // 화면의 85%

  // Colors - User Bubble
  static const userBg = AppColors.accentRed;
  static const userText = AppColors.textWhite;

  // Colors - Bot Bubble
  static const botBg = AppColors.pureWhite;
  static const botBorder = AppColors.borderLight;
  static const botText = AppColors.textPrimary;

  // Colors - System Bubble
  static const systemBgInfo = AppColors.bgLightPink;
  static const systemBgSuccess = AppColors.bgSoftMint;
  static const systemBgWarning = AppColors.lightPink;
  static const systemText = AppColors.textSecondary;
}
```

---

### 3.4 구현 위치 정리

| 컴포넌트 | 상태 | 파일 경로 |
|---------|------|----------|
| ChatBubble | ✅ 구현됨 | `lib/app/chat/chat_screen.dart` (404-478줄) |
| ChatBubble (독립) | ⚠️ 이동 필요 | `lib/ui/components/chat_bubble.dart` |
| SystemBubble | ❌ 신규 | `lib/ui/components/system_bubble.dart` |
| EmotionBubble | ❌ 신규 | `lib/ui/components/emotion_bubble.dart` |
| BubbleTokens | ❌ 신규 | `lib/ui/tokens/bubble_tokens.dart` |

---

### 3.5 Bubble 사용 원칙

#### ✅ 권장사항

```dart
// Good: 적절한 타입 선택
ChatBubble(message: userMessage)        // 대화
SystemBubble(text: '시스템 안내')        // 안내
EmotionBubble(emotion: joy, message: '기쁨')  // 감정

// Good: 일관된 스타일
Container(
  padding: BubbleTokens.chatPadding,
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(BubbleTokens.chatRadius),
  ),
)
```

#### ❌ 피해야 할 사항

```dart
// Bad: 카드 사용
Card(
  child: ListTile(title: Text('메시지')),
)

// Bad: 하드코딩된 스타일
Container(
  padding: EdgeInsets.all(16),  // BubbleTokens 사용
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(12),  // BubbleTokens 사용
  ),
)
```

---

## 🎞 4. Animation Guide

### 4.1 현재 상태

**정적 이미지 (PNG) 사용 중**

- 에셋: `assets/characters/normal/*.png`, `assets/characters/high/*.png`
- 17개 감정 캐릭터 모두 정적 이미지
- 향후 애니메이션 시스템으로 확장 예정

---

### 4.2 향후 애니메이션 시스템

#### 4.2.1 애니메이션 타입

| 타입 | 설명 | 타이밍 | 우선순위 |
|------|------|--------|---------|
| **Idle Loop** | 대기 중 자연스러운 움직임 | 항시 재생 | P2 |
| **Voice Reaction** | 음성 입력 시 반응 | 음성 감지 시 | P0 |
| **Emotion Burst** | 감정 변화 시 폭발 효과 | 감정 전환 시 | P1 |
| **Transition** | 캐릭터 교체 전환 | 주간 업데이트 시 | P2 |

**우선순위 설명:**
- P0: 즉시 필요 (음성 피드백)
- P1: 중요 (감정 표현)
- P2: 선택 (품질 향상)

---

#### 4.2.2 구현 방식 후보

**Option 1: Lottie (추천)**

- **장점**: 가볍고 빠름, After Effects 연동, 성숙한 생태계
- **단점**: 인터랙티브 제한적
- **패키지**: `lottie` (pub.dev)
- **사용 예시**:
  ```dart
  Lottie.asset(
    'assets/animations/char_joy.json',
    width: 180,
    height: 180,
  )
  ```

**Option 2: Live2D**

- **장점**: 고품질 2D 애니메이션, 인터랙티브, 부드러운 움직임
- **단점**: 무겁고 복잡, 라이센스 비용, Flutter 통합 어려움
- **패키지**: Custom Native Plugin 필요

**Option 3: Rive**

- **장점**: 실시간 인터랙티브 애니메이션, State Machine 지원
- **단점**: 디자인 툴 학습 곡선
- **패키지**: `rive` (pub.dev)

**권장 순서:**
1. **Lottie (P0)**: VoiceWaveform, 간단한 캐릭터 애니메이션
2. **Rive (P1)**: 복잡한 인터랙티브 애니메이션 (필요 시)
3. **Live2D (P2)**: 최고 품질 필요 시 (선택적)

---

#### 4.2.3 EmotionCharacter 확장 구조

현재 `EmotionCharacter` 위젯은 확장 가능하게 설계되어 있습니다.

**현재 (정적 이미지):**

```dart
class EmotionCharacter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,  // PNG 파일
      width: size,
      height: size,
    );
  }
}
```

**향후 (애니메이션):**

```dart
class EmotionCharacter extends StatefulWidget {
  final bool enableAnimation;  // 애니메이션 활성화 여부

  @override
  Widget build(BuildContext context) {
    if (enableAnimation && hasAnimationFile) {
      return Lottie.asset(
        animationPath,  // JSON 파일
        width: size,
        height: size,
      );
    } else {
      return Image.asset(
        imagePath,  // Fallback PNG
        width: size,
        height: size,
      );
    }
  }
}
```

**추가 필요 파일:**
- `lib/ui/characters/emotion_animation_controller.dart`
- `assets/animations/*.json` (Lottie 파일)

---

#### 4.2.4 VoiceWaveform 애니메이션 (우선순위 P0)

**위치:** `lib/ui/components/voice_waveform.dart` (신규)

**구현 방식:**

```dart
class VoiceWaveform extends StatefulWidget {
  final bool isActive;
  final Color color;
  final double height;

  const VoiceWaveform({
    this.isActive = true,
    this.color = AppColors.accentRed,
    this.height = 40,
  });

  @override
  _VoiceWaveformState createState() => _VoiceWaveformState();
}

class _VoiceWaveformState extends State<VoiceWaveform>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );

    if (widget.isActive) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(VoiceWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isActive && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(double.infinity, widget.height),
          painter: WaveformPainter(
            progress: _controller.value,
            color: widget.color,
            isActive: widget.isActive,
          ),
        );
      },
    );
  }
}

class WaveformPainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool isActive;

  WaveformPainter({
    required this.progress,
    required this.color,
    required this.isActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isActive) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final waveHeight = size.height * 0.5;
    final waveCount = 5;

    for (var i = 0; i < size.width; i++) {
      final x = i.toDouble();
      final phase = progress * 2 * pi;
      final y = size.height / 2 +
          sin((x / size.width) * waveCount * 2 * pi + phase) * waveHeight;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isActive != isActive;
  }
}
```

**디자인 스펙:**
- 높이: 40px (기본)
- 색상: `AppColors.accentRed`
- 파동: Sine wave (5개 주기)
- 애니메이션: 1.5초 주기로 반복
- 이징: `Curves.easeInOut`

---

### 4.3 애니메이션 원칙

#### 1. Subtle & Natural
과하지 않게, 자연스럽게 움직입니다.

```dart
// Good: 부드러운 애니메이션
AnimationController(
  duration: Duration(milliseconds: 800),
  curve: Curves.easeInOut,
)

// Bad: 급격한 애니메이션
AnimationController(
  duration: Duration(milliseconds: 100),
  curve: Curves.linear,
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

```dart
// Good: 사용자 액션에 대한 피드백
void onButtonTap() {
  _animationController.forward();  // 버튼 탭 피드백
  _handleAction();
}

// Bad: 의미 없는 애니메이션
Timer.periodic(Duration(seconds: 1), (_) {
  _randomAnimation();  // 무의미한 반복
});
```

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

### 4.4 패키지 설치 (향후 필요 시)

#### Lottie

```yaml
# pubspec.yaml
dependencies:
  lottie: ^3.0.0
```

#### Rive

```yaml
# pubspec.yaml
dependencies:
  rive: ^0.13.0
```

---

## 🧭 5. Navigation Structure

### 5.1 현재 네비게이션 (5탭)

#### BottomMenuBar (기존)

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

**문제점:**
- 너무 많은 탭 (5개)
- 캐릭터 중심 철학과 불일치
- 복잡한 구조

---

### 5.2 새로운 네비게이션 제안

#### Option A: 2-Icon Minimal (추천)

```
        [🎙️ 말하기]
    (중앙 플로팅 버튼, 56x56)

[홈]                    [더보기]
  (icon-home)         (icon-menu)
```

**장점:**
- 극도로 심플
- 캐릭터/음성 중심 인터랙션 강조
- 화이트 스페이스 극대화

**구현:**

```dart
BottomMenuBar(
  items: [
    BottomMenuItem(
      icon: SvgPicture.asset('assets/icons/icon-home.svg'),
      label: '홈',
    ),
    BottomMenuItem(
      icon: Icon(Icons.mic, size: 32),
      label: '',
      isCenter: true,  // 중앙 플로팅
    ),
    BottomMenuItem(
      icon: Icon(Icons.apps),
      label: '더보기',
    ),
  ],
  currentIndex: _currentIndex,
  onTap: (index) {
    if (index == 1) {
      _startVoiceInput();  // 음성 입력
    } else {
      setState(() => _currentIndex = index);
    }
  },
)
```

---

#### Option B: 3-Icon Balanced

```
┌─────┬─────┬─────┐
│ 홈  │ 🎙️  │기록 │
└─────┴─────┴─────┘
```

**장점:**
- 기록에 바로 접근 가능
- 균형잡힌 레이아웃
- 주요 기능 직접 노출

**구현:**

```dart
BottomMenuBar(
  items: [
    BottomMenuItem(icon: icon-home, label: '홈'),
    BottomMenuItem(icon: icon-mic, label: '말하기', isCenter: true),
    BottomMenuItem(icon: icon-chart, label: '기록'),
  ],
)
```

---

### 5.3 네비게이션 흐름

#### 홈 화면 → 대화

```
[홈 화면]
  - 감정 캐릭터 표시
  - "오늘 하루 어떠셨나요?"
   ↓ (음성 입력 버튼 탭)
[대화 화면]
  - 음성 입력 시작
  - 실시간 파동 표시
   ↓ (자동 감정 분석)
[감정 피드백]
  - 분석 결과 표시
  - 캐릭터 반응
  - 관련 추천
```

---

#### 더보기 메뉴 (Option A 선택 시)

```
더보기 버튼 탭
   ↓
[BottomSheet]
┌─────────────────────┐
│  📋 마음봄 메뉴      │
├─────────────────────┤
│  ⏰ 알람 설정       │
│  📊 리포트 보기     │
│  👤 마이페이지      │
│  ⚙️  설정           │
│  ❓ 도움말          │
└─────────────────────┘
```

**구현:**

```dart
// lib/ui/components/more_menu_sheet.dart (신규)
class MoreMenuSheet extends StatelessWidget {
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg),
        ),
      ),
      builder: (context) => MoreMenuSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('마음봄 메뉴', style: AppTypography.h3),
          SizedBox(height: AppSpacing.md),
          _buildMenuItem(
            icon: Icons.alarm,
            title: '알람 설정',
            onTap: () => _navigateToAlarm(context),
          ),
          _buildMenuItem(
            icon: Icons.bar_chart,
            title: '리포트 보기',
            onTap: () => _navigateToReport(context),
          ),
          _buildMenuItem(
            icon: Icons.person,
            title: '마이페이지',
            onTap: () => _navigateToMyPage(context),
          ),
          _buildMenuItem(
            icon: Icons.settings,
            title: '설정',
            onTap: () => _navigateToSettings(context),
          ),
          _buildMenuItem(
            icon: Icons.help,
            title: '도움말',
            onTap: () => _navigateToHelp(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.accentRed),
      title: Text(title, style: AppTypography.body),
      trailing: Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
```

---

### 5.4 구현 위치

**현재 파일:**
- [lib/ui/layout/bottom_menu_bars.dart](lib/ui/layout/bottom_menu_bars.dart)

**수정 필요:**
1. MenuItem 수를 5개 → 2-3개로 변경 가능하도록 유연화
2. 중앙 버튼 강조 (크기, 색상)
3. 라벨 표시 선택 가능

**신규 필요:**
- `lib/ui/components/more_menu_sheet.dart` (더보기 BottomSheet)

---

### 5.5 마이그레이션 전략

#### Phase 1: 병행 운영

```dart
// Feature Flag로 전환 제어
final useSimpleNav = ref.watch(featureFlagProvider).simpleNavigation;

if (useSimpleNav) {
  // 신규 2-3 아이콘 네비게이션
  return BottomMenuBar(items: _simpleItems);
} else {
  // 기존 5탭 네비게이션
  return BottomMenuBar(items: _fullItems);
}
```

**장점:**
- 안전한 전환
- A/B 테스트 가능
- 롤백 용이

#### Phase 2: 완전 전환

- 사용자 피드백 수집 후
- 신규 네비게이션만 사용
- 기존 코드 제거

#### Phase 3: 캐릭터 인터랙션 네비게이션

- 홈 화면에서 캐릭터 탭 → 해당 감정 관련 기능
- 네비게이션 바 최소화 또는 제거
- 제스처 기반 네비게이션 (스와이프 등)

---

### 5.6 네비게이션 Best Practices

#### ✅ 권장사항

```dart
// Good: 명확한 액션
if (index == centerButtonIndex) {
  _startVoiceInput();  // 음성 입력 즉시 시작
  return;  // 탭 전환 안 함
}

// Good: 피드백 제공
void onNavigate(int index) {
  HapticFeedback.lightImpact();  // 햅틱 피드백
  setState(() => _currentIndex = index);
}
```

#### ❌ 피해야 할 사항

```dart
// Bad: 너무 많은 탭
BottomMenuBar(
  items: [/* 6개 이상의 탭 */],
)

// Bad: 불명확한 아이콘
Icon(Icons.square)  // 의미 불명
```

---

## 🎨 6. Design Tokens

### 6.1 Colors

**파일:** [lib/ui/tokens/colors.dart](lib/ui/tokens/colors.dart)

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
AppColors.bgBasic      // 기본 배경 (pureWhite)
AppColors.bgWarm       // 따뜻한 배경 (warmWhite)
AppColors.bgLightPink  // 핑크 배경
AppColors.bgSoftMint   // 민트 배경
AppColors.bgRed        // 레드 배경 (accentRed)
AppColors.bgGreen      // 그린 배경 (natureGreen)

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

### 6.2 Typography

**파일:** [lib/ui/tokens/typography.dart](lib/ui/tokens/typography.dart)

**폰트:** Pretendard

| 스타일 | 크기 | 굵기 | Letter Spacing | 용도 |
|--------|------|------|----------------|------|
| `display` | 56px | 700 | -1.68 | 대형 제목, 감정 리포트 타이틀 |
| `h1` | 40px | 700 | -0.8 | 페이지 제목 |
| `h2` | 32px | 600 | -0.32 | 섹션 제목 |
| `h3` | 24px | 600 | -0.24 | 서브섹션 제목 |
| `bodyLarge` | 18px | 400 | 0 | 봄이 대사, 말풍선 |
| `body` | 16px | 400 | 0 | 기본 본문 |
| `bodyBold` | 16px | 600 | 0 | 강조 본문, 선택지 |
| `bodySmall` | 14px | 600 | 0 | 작은 본문 |
| `caption` | 14px | 400 | 0 | 캡션, 설명 |
| `label` | 8px | 500 | 0 | 라벨, 작은 안내 |

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

### 6.3 Spacing

**파일:** [lib/ui/tokens/spacing.dart](lib/ui/tokens/spacing.dart)

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

### 6.4 Radius

**파일:** [lib/ui/tokens/radius.dart](lib/ui/tokens/radius.dart)

| 이름 | 값 | 용도 |
|------|-----|------|
| `sm` | 8px | 작은 둥근 모서리 |
| `md` | 12px | 중간 둥근 모서리 (기본) |
| `lg` | 16px | 큰 둥근 모서리 |
| `pill` | 999px | 완전한 pill 형태 |

---

### 6.5 Icon Sizes

**파일:** [lib/ui/tokens/icon.dart](lib/ui/tokens/icon.dart)

| 이름 | 크기 | 용도 |
|------|------|------|
| `xs` | 16×16 | 최소 아이콘 |
| `sm` | 24×24 | 작은 아이콘 |
| `md` | 28×28 | 중간 아이콘 (기본) |
| `lg` | 32×32 | 큰 아이콘 |
| `xl` | 36×36 | 아주 큰 아이콘 |
| `xxl` | 42×42 | 초대형 아이콘 |

---

## 🏗️ 7. Layout System

### 7.1 AppFrame

**파일:** [lib/ui/layout/app_frame.dart](lib/ui/layout/app_frame.dart)

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

#### 파라미터

| 파라미터 | 타입 | 필수 | 설명 |
|----------|------|------|------|
| `topBar` | `PreferredSizeWidget?` | ❌ | 상단 바 (TopBar 위젯) |
| `bottomBar` | `Widget?` | ❌ | 하단 바 (BottomBar 위젯) |
| `body` | `Widget` | ✅ | 메인 컨텐츠 영역 |

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

#### SafeArea 자동 적용

- **Top Bar**: 상태 바(status bar) 영역 자동 회피
- **Body**: SafeArea로 감싸져 있음
- **Bottom Bar**: 홈 인디케이터 영역 자동 계산

---

### 7.2 Top Bar

**파일:** [lib/ui/layout/top_bars.dart](lib/ui/layout/top_bars.dart)

#### TopBar

단일 클래스로 모든 형태 지원. 아이콘과 콜백 제공 시 표시됩니다.

**파라미터:**

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

### 7.3 Bottom Bar

#### 7.3.1 BottomMenuBar

**파일:** [lib/ui/layout/bottom_menu_bars.dart](lib/ui/layout/bottom_menu_bars.dart)

5개 탭 메인 네비게이션 바.

**구조:**
```
┌─────┬─────┬─────┬─────┬─────┐
│ 홈  │알람 │ 🎙️  │리포트│마이 │
└─────┴─────┴─────┴─────┴─────┘
```

**파라미터:**

| 파라미터 | 타입 | 기본값 | 설명 |
|----------|------|--------|------|
| `currentIndex` | `int` | `0` | 현재 선택된 탭 (0~4) |
| `onTap` | `ValueChanged<int>?` | `null` | 탭 선택 콜백 |
| `backgroundColor` | `Color` | `AppColors.pureWhite` | 배경색 |
| `foregroundColor` | `Color` | `AppColors.textPrimary` | 비선택 색상 |
| `accentColor` | `Color` | `AppColors.accentRed` | 선택 색상 |

**탭 인덱스:**
- `0`: 홈
- `1`: 알람
- `2`: 녹음 (중앙 버튼)
- `3`: 리포트
- `4`: 마이페이지

---

#### 7.3.2 BottomButtonBar

**파일:** [lib/ui/layout/bottom_button_bars.dart](lib/ui/layout/bottom_button_bars.dart)

1~2개 액션 버튼 제공.

**스타일:**
- `pill`: 둥근 버튼 (기본)
- `block`: 전체 폭 블록 버튼

**사용 예시:**

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

#### 7.3.3 BottomInputBar

**파일:** [lib/ui/layout/bottom_input_bars.dart](lib/ui/layout/bottom_input_bars.dart)

텍스트 입력 + 음성 입력.

**사용 예시:**

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
      bottomBar: BottomInputBar(
        controller: _controller,
        hintText: '메시지를 입력하세요',
        onSend: () {
          if (_controller.text.isNotEmpty) {
            _sendMessage(_controller.text);
            _controller.clear();
          }
        },
      ),
      body: ChatMessageList(),
    );
  }
}
```

---

## 🧩 8. Component Library

### 8.1 AppButton

**파일:** [lib/ui/components/app_button.dart](lib/ui/components/app_button.dart)

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

### 8.2 AppInput

**파일:** [lib/ui/components/app_input.dart](lib/ui/components/app_input.dart)

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

// Error 상태 (명확한 표시)
AppInput(
  caption: '비밀번호',
  value: '',
  state: InputState.error,
  errorMessage: '비밀번호를 입력해주세요',
)
```

**Error 상태 강화:**
- 테두리: `errorRed`, 2px 이상
- 레이블/텍스트: `errorRed`
- 하단에 에러 메시지 표시 (`caption` 스타일)

---

### 8.3 ChatBubble

**파일:** [lib/app/chat/chat_screen.dart](lib/app/chat/chat_screen.dart) (404-478줄)

> ⚠️ **독립화 권장:** `lib/ui/components/chat_bubble.dart`로 이동

```dart
ChatBubble(
  message: ChatMessage(
    text: '오늘 기분이 좋아요!',
    isUser: true,
  ),
)
```

---

### 8.4 EmotionCharacter

**파일:** [lib/ui/characters/app_characters.dart](lib/ui/characters/app_characters.dart)

```dart
// 큰 사이즈 (홈 화면)
EmotionCharacter(
  id: EmotionId.joy,
  highRes: true,
  size: 180,
)

// 작은 사이즈 (말풍선)
EmotionCharacter(
  id: EmotionId.sadness,
  size: 32,
)
```

---

### 8.5 신규 컴포넌트 (향후 구현)

#### SystemBubble
**파일:** `lib/ui/components/system_bubble.dart`

시스템 메시지 표시.

```dart
SystemBubble(
  text: '금주의 감정: 기쁨 😊',
  type: SystemBubbleType.info,
)
```

---

#### EmotionBubble
**파일:** `lib/ui/components/emotion_bubble.dart`

감정 캐릭터 + 메시지.

```dart
EmotionBubble(
  emotion: EmotionId.joy,
  message: '기분 좋은 하루네요!',
)
```

---

#### VoiceWaveform
**파일:** `lib/ui/components/voice_waveform.dart`

음성 파동 시각화.

```dart
VoiceWaveform(
  isActive: isRecording,
  color: AppColors.accentRed,
  height: 40,
)
```

---

#### MoreMenuSheet
**파일:** `lib/ui/components/more_menu_sheet.dart`

더보기 BottomSheet.

```dart
MoreMenuSheet.show(context);
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
- 향후 애니메이션 시스템 추가 대비
- 감정 캐릭터 확장 가능

---

## 🔧 개발 가이드

### Import

```dart
import 'package:frontend/ui/app_ui.dart';
```

위 한 줄로 모든 디자인 시스템 요소 접근:
- Layout (AppFrame, TopBar, BottomBar)
- Tokens (Colors, Typography, Spacing, Radius, Icons)
- Components (AppButton, AppInput)
- Characters (EmotionCharacter)

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

**마지막 업데이트**: 2025-12-05
