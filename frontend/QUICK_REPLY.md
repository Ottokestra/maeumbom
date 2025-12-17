# Quick Reply 시스템

마음봄 앱의 Quick Reply 시스템은 단순 스몰톡을 서버 호출 없이 즉시 처리하여 응답 속도를 개선하고 자연스러운 대화 경험을 제공합니다.

---

## 📋 개요

### 목적
- **즉각적인 응답**: "안녕", "고마워", "ㅋㅋ" 같은 단순 스몰톡을 0.1초 이내에 처리
- **서버 부하 감소**: 단순 스몰톡 약 20~30%를 로컬에서 처리
- **안전성 우선**: 의미 있는 대화와 고위험 키워드는 반드시 서버로 전송
- **일관된 UX**: Quick Reply도 서버 응답과 동일한 JSON 구조 및 UI 렌더링

### 응답 속도 개선
- **기존**: 2~3초 (서버 API 호출)
- **Quick Reply**: 즉시 (0.1초 이내)

---

## 🏗️ 아키텍처

### 데이터 플로우

```
사용자 입력
    ↓
QuickReplyEngine.tryMatch()
    ↓
├─ 매칭 성공 → 즉시 응답 (response_type: "quick")
│   ↓
│   UI에 봄이 메시지 추가
│   ↓
│   return (서버 호출 없음)
│
└─ 매칭 실패 → 서버 API 호출 (기존 플로우)
    ↓
    v2/text API
    ↓
    서버 응답 처리
```

### 파일 구조

```
lib/
├── data/models/chat/
│   ├── bomi_reply.dart              # 봄이 응답 모델
│   └── quick_reply_rule.dart        # Quick Reply 규칙 모델
│
├── core/services/chat/
│   └── quick_reply_engine.dart      # Quick Reply 엔진 (핵심 로직)
│
└── providers/
    └── chat_provider.dart           # sendTextMessage에 Quick Reply 통합
```

---

## 🔧 핵심 컴포넌트

### 1. BoomiReply 모델

봄이의 Quick Reply 응답을 표현하는 데이터 모델입니다.

```dart
class BoomiReply {
  final String text;        // 응답 텍스트 (반말)
  final String emotion;     // 감정 ID
  
  Map<String, dynamic> toServerFormat() {
    return {
      'reply_text': text,
      'emotion': emotion,
      'response_type': 'quick',
      'alarm_info': null,
      'tts_audio_url': null,
      'tts_status': 'skip',
    };
  }
}
```

**감정 종류** (app_animations.dart 정의):
- `happiness`: 행복/기쁨
- `sadness`: 슬픔
- `anger`: 분노
- `fear`: 공포/두려움

### 2. QuickReplyRule 모델

정규식 패턴과 응답 후보 리스트를 포함하는 규칙입니다.

```dart
class QuickReplyRule {
  final RegExp pattern;           // 정규식 패턴
  final List<BoomiReply> replies; // 응답 후보 리스트
  final String description;       // 규칙 설명 (디버깅용)
}
```

### 3. QuickReplyEngine

Quick Reply의 핵심 로직을 담당하는 엔진입니다.

#### 주요 기능

**1) 텍스트 정규화**
```dart
QuickReplyEngine.normalize(String text)
```
- 앞뒤 공백 제거
- 끝 특수문자 제거 (!, ?, . 등)
- 반복 문자 축약 (ㅋㅋㅋ → ㅋㅋ)

**2) 서버 패스 조건 체크**
```dart
QuickReplyEngine.shouldPassToServer(String text)
```

다음 조건 중 하나라도 해당하면 서버로 전송:
- ✅ 길이 12자 이상 (runes 기준)
- ✅ 질문/요청 키워드 포함: `?`, `뭐`, `왜`, `어떻게`, `알려줘`, `설명`, `언제`, `어디`
- ✅ 고위험 키워드 포함: `죽고싶`, `자해`, `극단`, `자살`
- ✅ 관계 키워드 포함: `남편`, `아이`, `자식`, `시댁`, `직장`, `동료`, `친구`

**3) Quick Reply 매칭**
```dart
QuickReplyEngine.tryMatch(String text)
```
- 서버로 패스해야 하면 `null` 반환
- 매칭 성공 시 랜덤으로 선택된 응답 반환
- 매칭 실패 시 `null` 반환

---

## 📝 Quick Reply 규칙 (50개)

### 인사 및 작별
1. **인사**: 안녕, 하이, 헬로, hi, hello
2. **작별**: 바이, 잘가, bye, 안녕히, 다음에
3. **취침**: 잘자, 굿나잇, good night, 자러갈게

### 감사 및 사과
4. **감사**: 고마워, 감사, 땡큐, thx, thanks
5. **사과**: 미안, 죄송, sorry

### 웃음 및 감정 표현
6. **웃음**: ㅋㅋ, ㅎㅎ, ㅋ, ㅎ, 하하, 호호
7. **슬픔/울음**: ㅠㅠ, ㅜㅜ, ㅠ, ㅜ, 흑흑
8. **긍정 이모지**: 👍, ❤️, 😊, 🙂, 😄, 😍, 🥰, 💕

### 긍정/부정 응답
9. **긍정/확인**: 오케이, ok, okay, 알겠어, 알았어, ㅇㅇ, 응, 넵, 네
10. **부정**: 아니, 아니야, 노, no, nope
11. **동의**: 그래, 그렇구나, 그렇네, 그런가
12. **동의 강조**: 맞아, 맞네, 맞지, 그치, 그쵸
13. **모름**: 몰라, 모르겠어, 글쎄

### 감정 상태 (단독)
14. **힘듦**: 힘들어, 힘드네, 힘듦
15. **불안**: 불안해, 불안하네, 불안함
16. **짜증**: 짜증, 짜증나, 짜증남
17. **혼란**: 모르겠어, 모르겠네, 모름
18. **피곤**: 피곤해, 피곤, 졸려, 졸림
19. **배고픔**: 배고파, 배고픔, 배고프다
20. **심심함**: 심심해, 심심, 지루해, 지루함
21. **행복**: 행복해, 행복, 기뻐, 기쁨
22. **슬픔**: 슬퍼, 슬픔, 우울해, 우울
23. **화남**: 화나, 화남, 빡쳐, 열받아
24. **외로움**: 외로워, 외로움, 쓸쓸해, 쓸쓸함
25. **아픔**: 아파, 아픔, 아프다
26. **재미**: 재밌어, 재밌네, 재미있어, 재미있네
27. **지겨움**: 지겨워, 지겨움, 따분해, 따분함
28. **두려움**: 두려워, 두려움, 무서워, 무서움
29. **부끄러움**: 부끄러워, 부끄럽, 창피해, 창피함
30. **놀라움**: 놀라워, 놀람, 신기해, 신기함, 대박

### 긍정/부정 평가
31. **좋음**: 좋아, 좋음, 좋네, 굿, good
32. **나쁨**: 나쁨, 안좋아, 안좋음, 별로

### 확신 및 의심
33. **당연함**: 당연하지, 당연, 물론, 당근
34. **진짜**: 진짜, 정말, really, real
35. **놀람/의심**: 거짓말, 설마, 헐, ㄷㄷ

### 칭찬 및 격려
36. **응원**: 힘내, 파이팅, 화이팅, fighting
37. **칭찬**: 최고, 짱, 굿, great
38. **칭찬 강조**: 멋져, 멋있어, 쩔어, 쩐다
39. **외모 칭찬**: 예쁘다, 예뻐, 이쁘다, 이뻐
40. **귀여움**: 귀여워, 귀엽, 큐트, cute
41. **잘했어**: 잘했어, 잘함, 잘했네
42. **대단함**: 대단해, 대단하다, amazing
43. **완벽**: 완벽해, 완벽, perfect

### 애정 표현
44. **사랑**: 사랑해, 사랑, love, 러브
45. **그리움**: 보고싶어, 보고싶다, 그리워

### 기타
46. **축하**: 축하해, 축하, congratulations
47. **수고**: 수고했어, 수고, 고생했어, 고생
48. **실망**: 실망, 실망이야, 아쉬워, 아쉽
49. **후회**: 후회, 후회돼, 후회된다
50. **기대**: 기대돼, 기대, 기대된다

---

## 💻 사용 예시

### ChatProvider에서의 사용

```dart
Future<void> sendTextMessage(String text) async {
  if (text.trim().isEmpty) return;

  // Quick Reply 시도
  final quickReply = QuickReplyEngine.tryMatch(text);
  
  if (quickReply != null) {
    // ✅ Quick Reply 매칭 성공
    print('[ChatProvider] 🚀 Quick Reply matched!');
    
    // 사용자 메시지 추가
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );
    
    // 봄이 Quick Reply 추가
    final aiMessage = ChatMessage(
      id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
      text: quickReply.text,
      isUser: false,
      timestamp: DateTime.now(),
      meta: {
        'emotion': quickReply.emotion,
        'response_type': 'quick',
      },
    );
    
    state = state.copyWith(
      messages: [...state.messages, userMessage, aiMessage],
    );
    
    await _updateSessionTime();
    return; // 서버 호출 없이 종료
  }

  // ❌ Quick Reply 매칭 실패 → 기존 서버 플로우
  print('[ChatProvider] 📡 Passing to server...');
  // ... 기존 서버 호출 로직
}
```

---

## 🧪 테스트 케이스

| 입력 | 예상 결과 | 이유 |
|------|----------|------|
| "안녕" | Quick Reply: "안녕! 오늘 하루 어땠어?" | 단순 인사 |
| "고마워!" | Quick Reply: "천만에! 언제든 말 걸어줘" | 감사 표현 |
| "ㅋㅋㅋㅋ" | Quick Reply: "좋은 일 있었나봐! ㅎㅎ" | 웃음 (정규화: ㅋㅋ) |
| "ㅠㅠ" | Quick Reply: "힘든 일이 있었어? 괜찮아" | 슬픔 표현 |
| "👍" | Quick Reply: "나도! ❤️" | 긍정 이모지 |
| "오늘 기분이 어때?" | Server | 질문 키워드 (?) |
| "남편이랑 싸웠어" | Server | 관계 키워드 (남편) |
| "죽고싶어" | Server | 고위험 키워드 (최우선) |
| "오늘 회사에서 정말 힘든 일이 있었어요" | Server | 길이 12자 초과 |
| "알려줘" | Server | 요청 키워드 |

---

## ⚠️ 주의사항

### 1. 안전성 최우선
- 고위험 키워드(`죽고싶`, `자해`, `극단`, `자살`)는 **무조건 서버로 전송**
- 의미 있는 대화(질문, 관계, 감정 상세)는 서버 플로우 유지
- Quick Reply는 "안전한 스몰톡"만 처리

### 2. 일관된 UX
- Quick Reply도 서버 응답과 동일한 JSON 구조 사용
- `response_type: "quick"`으로 구분 가능
- UI 렌더링 로직 재사용 (EmotionBubble, 캐릭터 표시 등)

### 3. 반말 톤 유지
- 모든 응답은 친근한 반말체 사용
- "~해요" ❌ → "~해" ⭕
- "~주세요" ❌ → "~줘" ⭕

### 4. 디버깅
- Quick Reply 매칭 시: `[ChatProvider] 🚀 Quick Reply matched!`
- 서버 패스 시: `[ChatProvider] 📡 Passing to server...`

---

## 🔄 확장 가이드

### 새로운 규칙 추가

`QuickReplyEngine._rules`에 새로운 `QuickReplyRule` 추가:

```dart
QuickReplyRule(
  pattern: RegExp(r'^(새로운패턴)$'),
  replies: const [
    BoomiReply(text: '응답 1', emotion: 'happiness'),
    BoomiReply(text: '응답 2', emotion: 'love'),
  ],
  description: '규칙 설명',
),
```

### 서버 패스 조건 수정

`QuickReplyEngine.shouldPassToServer()` 함수 수정:

```dart
static final List<String> _newKeywords = ['새키워드1', '새키워드2'];

if (_newKeywords.any((kw) => normalized.contains(kw))) {
  return true;
}
```

---

## 📊 성능 지표

- **응답 속도**: 2~3초 → 0.1초 이내 (약 20~30배 개선)
- **서버 부하**: 단순 스몰톡 20~30% 로컬 처리
- **사용자 경험**: 즉각적인 응답으로 자연스러운 대화 흐름 유지

---

## 📚 관련 문서

- [FRONTEND_GUIDE.md](./FRONTEND_GUIDE.md): 전체 프론트엔드 개발 가이드
- [DESIGN_GUIDE.md](./DESIGN_GUIDE.md): 디자인 시스템 가이드
- [PROMPT_GUIDE.md](./PROMPT_GUIDE.md): AI 프롬프트 가이드

---

**최종 업데이트**: 2025-12-18
