# 신조어 퀴즈 프론트엔드 구현 가이드

## 📋 목차

- [개요](#개요)
- [폴더 구조](#폴더-구조)
- [화면 구성](#화면-구성)
- [API 통합](#api-통합)
- [상태 관리](#상태-관리)
- [라우팅](#라우팅)
- [사용자 플로우](#사용자-플로우)
- [주요 기능](#주요-기능)

## 개요

신조어 퀴즈 프론트엔드는 Flutter와 Riverpod을 사용하여 구현되었습니다. 사용자의 현재 감정 캐릭터를 활용하여 친근한 퀴즈 경험을 제공합니다.

### 기술 스택

- **Framework**: Flutter
- **State Management**: Riverpod
- **HTTP Client**: Dio
- **Code Generation**: Freezed
- **UI Components**: AppFrame, TopBar, EmotionCharacter 등

## 폴더 구조

```
frontend/lib/
├── app/
│   ├── slang_quiz/
│   │   ├── slang_quiz_start_screen.dart      # 시작 화면
│   │   ├── slang_quiz_game_screen.dart       # 게임 화면
│   │   ├── slang_quiz_result_screen.dart     # 결과 화면
│   │   └── slang_quiz_admin_screen.dart      # 관리자 화면 (개발용)
│   └── training/
│       └── training_screen.dart               # 마음연습실 메뉴 (수정됨)
├── data/
│   ├── api/slang_quiz/
│   │   └── slang_quiz_api_client.dart        # API 클라이언트
│   └── dtos/slang_quiz/                      # DTO 모델들
│       ├── start_game_request.dart
│       ├── start_game_response.dart
│       ├── submit_answer_request.dart
│       ├── submit_answer_response.dart
│       └── end_game_response.dart
└── core/
    └── config/
        ├── api_config.dart                    # API 엔드포인트 설정 (수정됨)
        └── app_routes.dart                    # 라우팅 설정 (수정됨)
```

## 화면 구성

### 1. 시작 화면 (`SlangQuizStartScreen`)

**경로**: `frontend/lib/app/slang_quiz/slang_quiz_start_screen.dart`

**기능**:
- 사용자의 현재 감정 캐릭터 표시 (`dailyMoodProvider.selectedEmotion`)
- 난이도 선택 (초급/중급/고급)
- 퀴즈 타입 선택 (단어→뜻 / 뜻→단어)
- 게임 시작 버튼
- 관리자 화면 접근 (우측 상단 설정 아이콘 또는 캐릭터 5번 탭)

**UI 구성**:
- TopBar: "글자 빨리 누르기" + 뒤로가기
- 중앙: 감정 캐릭터 (240x240, normal_2d)
- 하단: 안내 텍스트 + 설정 선택 + 게임 시작 버튼

### 2. 게임 화면 (`SlangQuizGameScreen`)

**경로**: `frontend/lib/app/slang_quiz/slang_quiz_game_screen.dart`

**기능**:
- 게임 시작 API 호출
- 문제 표시 및 4개 선택지
- 40초 타이머 카운트다운
- 답안 선택 및 제출
- 정답/오답 결과 다이얼로그
- 자동으로 다음 문제 로드
- 게임 종료 처리

**UI 구성**:
- TopBar: "문제 X/5 ⏱️ X초"
- 중앙 상단: 감정 캐릭터 (120x120, 크기 축소)
- 중앙: 문제 박스 (연한 분홍색 배경)
- 하단: 선택지 4개 (한 화면에 모두 표시)
- 최하단: 답안 제출 버튼

**상태 관리**:
```dart
- gameId: 게임 ID
- currentQuestion: 현재 문제 번호 (1-5)
- questionData: 현재 문제 데이터
- selectedIndex: 선택한 답안 인덱스
- timeRemaining: 남은 시간 (40초부터 감소)
- totalScore: 총 점수
- isLoading: 로딩 상태
- isSubmitting: 제출 중 상태
```

**타이머 구현**:
- `Timer.periodic`로 1초마다 카운트다운
- 시간 초과 시 자동으로 오답 처리

### 3. 결과 화면 (`SlangQuizResultScreen`)

**경로**: `frontend/lib/app/slang_quiz/slang_quiz_result_screen.dart`

**기능**:
- 최종 점수 및 정답 개수 표시
- 정답률 계산 및 표시
- 문제별 요약 (정답 여부, 획득 점수)
- 결과에 따른 감정 캐릭터 변경
- "다시 하기", "나가기" 버튼

**UI 구성**:
- TopBar: "퀴즈 결과" + 닫기 버튼
- 중앙: 결과 감정 캐릭터 (정답률에 따라 변경)
- 총점: 큰 글씨로 표시
- 정답 개수: "5문제 중 4문제 정답!"
- 문제별 요약: 각 문제의 정답 여부 + 점수
- 하단: 버튼 2개 (나가기, 다시 하기)

**결과 기반 캐릭터**:
```dart
- 4개 이상 정답: joy (기쁨)
- 3개 정답: relief (안도)
- 2개 정답: interest (관심)
- 2개 미만: sadness (슬픔)
```

### 4. 관리자 화면 (`SlangQuizAdminScreen`) - 개발용

**경로**: `frontend/lib/app/slang_quiz/slang_quiz_admin_screen.dart`

**기능**:
- 문제 생성 API 호출
- 난이도/타입/개수 선택
- 생성 진행 상태 표시
- 결과 메시지 표시

**접근 방법**:
1. 시작 화면 우측 상단 설정 아이콘(⚙️) 클릭
2. 또는 시작 화면에서 캐릭터를 5번 연속 탭

**주의사항**:
- 개발용 기능이므로 프로덕션 배포 시 제거하거나 숨겨야 함
- OpenAI API 호출 비용 발생
- 타임아웃: 180초 (3분)로 설정됨

## API 통합

### API Client

**파일**: `frontend/lib/data/api/slang_quiz/slang_quiz_api_client.dart`

**주요 메서드**:
```dart
- startGame(StartGameRequest): 게임 시작
- getQuestion(int gameId, int questionNumber): 문제 조회
- submitAnswer(int gameId, SubmitAnswerRequest): 답안 제출
- endGame(int gameId): 게임 종료
- generateQuestionsAdmin(...): 문제 생성 (관리자용)
```

**인증**:
- `dioWithAuthProvider` 사용
- 자동으로 Authorization 헤더에 Bearer 토큰 추가

**타임아웃 설정**:
- 일반 API: 기본 설정 (30초)
- 문제 생성 API: 180초 (관리자 화면에서 별도 Dio 인스턴스 사용)

### DTO 모델

**위치**: `frontend/lib/data/dtos/slang_quiz/`

**모델 목록**:
- `StartGameRequest` / `StartGameResponse`
- `SubmitAnswerRequest` / `SubmitAnswerResponse`
- `EndGameResponse`

**특징**:
- Freezed 사용하여 불변 객체로 구현
- JSON 직렬화/역직렬화 자동 생성
- `@JsonKey` 어노테이션으로 snake_case 변환

### API Config

**파일**: `frontend/lib/core/config/api_config.dart`

**추가된 엔드포인트**:
```dart
static const String slangQuizBase = '/api/service/slang-quiz';
static const String slangQuizStartGame = '$slangQuizBase/start-game';
static String slangQuizGetQuestion(int gameId, int questionNumber) =>
    '$slangQuizBase/games/$gameId/questions/$questionNumber';
static String slangQuizSubmitAnswer(int gameId) =>
    '$slangQuizBase/games/$gameId/submit-answer';
static String slangQuizEndGame(int gameId) =>
    '$slangQuizBase/games/$gameId/end';
static const String slangQuizHistory = '$slangQuizBase/history';
static const String slangQuizStatistics = '$slangQuizBase/statistics';
static const String slangQuizAdminGenerate = '$slangQuizBase/admin/questions/generate';
```

## 상태 관리

### Riverpod 사용

현재는 각 화면에서 `ConsumerStatefulWidget`을 사용하여 로컬 상태를 관리합니다.

**주요 Provider 사용**:
- `dailyMoodProvider`: 사용자의 현재 감정 캐릭터
- `dioWithAuthProvider`: 인증된 Dio 인스턴스

**향후 개선 가능**:
- `SlangQuizViewModel` 또는 `SlangQuizProvider` 생성하여 상태 관리 중앙화
- 게임 진행 상태를 Provider로 관리하여 화면 간 공유

## 라우팅

### 라우트 정의

**파일**: `frontend/lib/core/config/app_routes.dart`

```dart
static const RouteMetadata slangQuizStart = RouteMetadata(
  routeName: '/training/slang-quiz/start',
  builder: SlangQuizStartScreen.new,
  requiresAuth: true,
);
```

### 커스텀 라우트 처리

**파일**: `frontend/lib/main.dart`

`onGenerateRoute`에서 arguments를 받는 라우트 처리:

```dart
// 게임 화면 (level, quizType arguments)
if (routeName == '/training/slang-quiz/game') {
  final args = settings.arguments as Map<String, dynamic>?;
  if (args != null) {
    return MaterialPageRoute(
      builder: (context) => SlangQuizGameScreen(
        level: args['level'] as String,
        quizType: args['quizType'] as String,
      ),
    );
  }
}

// 결과 화면 (EndGameResponse argument)
if (routeName == '/training/slang-quiz/result') {
  final result = settings.arguments as EndGameResponse?;
  if (result != null) {
    return MaterialPageRoute(
      builder: (context) => SlangQuizResultScreen(result: result),
    );
  }
}

// 관리자 화면
if (routeName == '/training/slang-quiz/admin') {
  return MaterialPageRoute(
    builder: (context) => const SlangQuizAdminScreen(),
  );
}
```

## 사용자 플로우

```
1. 홈 화면
   ↓
2. 하단 메뉴 → "마음연습실" 탭
   ↓
3. TrainingScreen (메뉴 선택)
   - "관계 연습하기" 카드
   - "신조어 퀴즈" 카드 ← 클릭
   ↓
4. SlangQuizStartScreen (시작 화면)
   - 난이도/타입 선택
   - "게임 시작" 버튼 클릭
   ↓
5. SlangQuizGameScreen (게임 화면)
   - 문제 1 표시 → 답안 선택 → 제출
   - 결과 다이얼로그 표시
   - 문제 2 표시 → ... (5문제 반복)
   ↓
6. SlangQuizResultScreen (결과 화면)
   - 최종 점수 및 정답 개수 확인
   - "다시 하기" 또는 "나가기"
```

## 주요 기능

### 1. 게임 시작

**플로우**:
1. 사용자가 난이도/타입 선택
2. `POST /start-game` API 호출
3. 첫 번째 문제 즉시 표시
4. 나머지 4개 문제는 백그라운드에서 준비

**처리**:
- API 응답으로 `gameId`와 첫 번째 문제 받음
- 게임 세션 생성 및 답안 레코드 초기화

### 2. 문제 풀이

**플로우**:
1. 문제 표시 (40초 타이머 시작)
2. 사용자가 선택지 중 하나 선택
3. "답안 제출" 버튼 클릭
4. `POST /submit-answer` API 호출
5. 결과 다이얼로그 표시 (정답 여부, 점수, 설명, 보상 카드)
6. 다음 문제로 자동 이동

**타이머**:
- 40초 카운트다운
- 시간 초과 시 자동으로 오답 처리 (`user_answer_index: -1`)

### 3. 게임 종료

**플로우**:
1. 5문제 모두 완료
2. `POST /end` API 호출
3. 최종 결과 받음
4. 결과 화면으로 이동

**결과 데이터**:
- 총점
- 정답 개수
- 정답률
- 문제별 요약

### 4. 문제 생성 (관리자)

**플로우**:
1. 관리자 화면 접근
2. 난이도/타입/개수 선택
3. "문제 생성" 버튼 클릭
4. `POST /admin/questions/generate` API 호출
5. 로딩 표시 (약 10-180초)
6. 완료 메시지 표시

**타임아웃**:
- 별도의 Dio 인스턴스 사용
- `receiveTimeout: 180초` 설정
- OpenAI API 호출 대기 시간 고려

## 디자인 가이드 준수

### 사용된 컴포넌트

- **AppFrame**: 모든 화면의 기본 프레임
- **TopBar**: 상단 네비게이션 바
- **EmotionCharacter**: 감정 캐릭터 표시 (`use2d: true`, `normal_2d` 폴더)
- **AppButton**: 버튼 컴포넌트
- **AppTypography**: 텍스트 스타일
- **AppColors**: 색상 토큰
- **AppSpacing**: 간격 토큰
- **AppRadius**: 둥근 모서리 토큰

### 캐릭터 표시

**사용자의 현재 감정 캐릭터**:
```dart
final dailyState = ref.watch(dailyMoodProvider);
final currentEmotion = dailyState.selectedEmotion ?? EmotionId.joy;

EmotionCharacter(
  id: currentEmotion,
  use2d: true,  // normal_2d 폴더 사용
  size: 240,   // 시작 화면
  size: 120,   // 게임 화면 (공간 절약)
  size: 200,   // 결과 화면
)
```

**결과 기반 캐릭터**:
- 정답률에 따라 다른 감정 캐릭터 표시
- 높은 점수 → 기쁨, 낮은 점수 → 슬픔

## 주요 수정 사항

### Training Screen 수정

**파일**: `frontend/lib/app/training/training_screen.dart`

**변경 내용**:
- 기존: "관계 연습하기" 버튼 하나
- 변경: "관계 연습하기"와 "신조어 퀴즈" 두 개의 카드 버튼

**라우팅 변경**:
- `/training` 경로가 `TrainingScreen`을 가리키도록 수정
- 기존: `RelationTrainingListScreen` 직접 연결
- 변경: `TrainingScreen` (메뉴 선택 화면)

### API Config 추가

**파일**: `frontend/lib/core/config/api_config.dart`

신조어 퀴즈 관련 엔드포인트 8개 추가

### Main.dart 라우팅 추가

**파일**: `frontend/lib/main.dart`

`onGenerateRoute`에 커스텀 라우트 3개 추가:
- 게임 화면 (arguments: level, quizType)
- 결과 화면 (arguments: EndGameResponse)
- 관리자 화면

## 문제 해결

### 1. Dio 타임아웃 문제

**문제**: 문제 생성 API가 30초 타임아웃으로 실패

**해결**:
- 관리자 화면에서 별도의 Dio 인스턴스 생성
- `receiveTimeout: 180초` 설정
- 인터셉터(인증 토큰) 복사

### 2. 선택지 스크롤 문제

**문제**: 선택지 4개가 한 화면에 보이지 않아 스크롤 필요

**해결**:
- 캐릭터 크기 축소 (180px → 120px)
- `Expanded` + `ListView` → `SingleChildScrollView` + `Column` 변경
- 선택지 간격 및 패딩 최적화

### 3. User 모델 속성명 문제

**문제**: 백엔드에서 `current_user.id` 사용 시 에러

**해결**:
- 백엔드 `routes.py`에서 모든 `current_user.id` → `current_user.ID` 변경
- User 모델의 ID 속성은 대문자 `ID` 사용

## 테스트

### 테스트 시나리오

1. **게임 플레이**:
   - 마음연습실 → 신조어 퀴즈
   - 난이도/타입 선택 → 게임 시작
   - 5문제 풀이 → 결과 확인

2. **문제 생성**:
   - 시작 화면 → 설정 아이콘 클릭
   - 관리자 화면에서 문제 생성
   - 각 레벨/타입별로 5개씩 생성

3. **에러 처리**:
   - 네트워크 오류 시 에러 메시지 표시
   - 타임아웃 시 적절한 안내

## 향후 개선 사항

1. **상태 관리 개선**:
   - `SlangQuizProvider` 생성하여 게임 상태 중앙화
   - 화면 간 상태 공유

2. **UX 개선**:
   - 문제 전환 애니메이션
   - 타이머 시각적 피드백
   - 로딩 상태 개선

3. **기능 추가**:
   - 히스토리 화면 구현
   - 통계 화면 구현
   - 문제 난이도별 필터링

4. **성능 최적화**:
   - 문제 미리 로드
   - 이미지 캐싱

## 참고 자료

- 백엔드 API 문서: `backend/app/slang_quiz/README.md`
- 프론트엔드 가이드: `frontend/FRONTEND_GUIDE.md`
- 디자인 가이드: `frontend/DESIGN_GUIDE.md`

