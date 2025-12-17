import '../../../data/models/chat/bomi_reply.dart';
import '../../../data/models/chat/quick_reply_rule.dart';

/// Quick Reply 엔진
/// 
/// 단순 스몰톡을 로컬에서 즉시 처리하는 엔진입니다.
/// - 텍스트 정규화
/// - 서버 패스 조건 체크
/// - 패턴 매칭 및 응답 선택
class QuickReplyEngine {
  // 서버로 패스해야 하는 조건들
  static const int _maxQuickReplyLength = 12; // runes 기준
  
  static final List<String> _questionKeywords = [
    '?', '뭐', '왜', '어떻게', '알려줘', '설명', '언제', '어디'
  ];
  
  static final List<String> _highRiskKeywords = [
    '죽고싶', '자해', '극단', '자살'
  ];
  
  static final List<String> _relationshipKeywords = [
    '남편', '아이', '자식', '시댁', '직장', '동료', '친구'
  ];
  
  /// 텍스트 정규화
  /// 
  /// 1. 앞뒤 공백 제거
  /// 2. 끝 특수문자 제거 (!, ?, . 등)
  /// 3. 반복 문자 축약 (ㅋㅋㅋ → ㅋㅋ)
  static String normalize(String text) {
    // 1) 앞뒤 공백 제거
    String normalized = text.trim();
    
    // 2) 끝 특수문자 제거 (!, ?, . 등)
    normalized = normalized.replaceAll(RegExp(r'[!?.~]+$'), '');
    
    // 3) ㅋㅋㅋ → ㅋㅋ, ㅎㅎㅎ → ㅎㅎ (반복 축약)
    normalized = normalized.replaceAll(RegExp(r'ㅋ{2,}'), 'ㅋㅋ');
    normalized = normalized.replaceAll(RegExp(r'ㅎ{2,}'), 'ㅎㅎ');
    normalized = normalized.replaceAll(RegExp(r'ㅠ{2,}'), 'ㅠㅠ');
    normalized = normalized.replaceAll(RegExp(r'ㅜ{2,}'), 'ㅜㅜ');
    
    return normalized;
  }
  
  /// 서버로 패스해야 하는지 체크
  /// 
  /// 다음 조건 중 하나라도 해당하면 true 반환:
  /// 1. 길이 12자 이상
  /// 2. 질문/요청 키워드 포함
  /// 3. 고위험 키워드 포함 (최우선)
  /// 4. 관계 키워드 포함
  static bool shouldPassToServer(String text) {
    final normalized = normalize(text);
    
    // 조건 1: 길이 체크 (12자 이상은 서버로)
    if (normalized.runes.length >= _maxQuickReplyLength) {
      return true;
    }
    
    // 조건 2: 질문/요청 키워드 포함
    if (_questionKeywords.any((kw) => normalized.contains(kw))) {
      return true;
    }
    
    // 조건 3: 고위험 키워드 포함 (최우선)
    if (_highRiskKeywords.any((kw) => normalized.contains(kw))) {
      return true;
    }
    
    // 조건 4: 관계 키워드 포함 (선택적)
    if (_relationshipKeywords.any((kw) => normalized.contains(kw))) {
      return true;
    }
    
    return false;
  }
  
  /// Quick Reply 매칭 시도
  /// 
  /// 서버로 패스해야 하면 null 반환.
  /// 매칭 성공 시 랜덤으로 선택된 응답 반환.
  /// 매칭 실패 시 null 반환.
  static BoomiReply? tryMatch(String text) {
    // 서버로 패스해야 하면 null 반환
    if (shouldPassToServer(text)) {
      return null;
    }
    
    final normalized = normalize(text);
    
    // 규칙 순회하며 매칭
    for (final rule in _rules) {
      if (rule.pattern.hasMatch(normalized)) {
        // 랜덤으로 응답 선택
        final replies = rule.replies;
        final selectedReply = replies[DateTime.now().millisecond % replies.length];
        return selectedReply;
      }
    }
    
    return null; // 매칭 실패
  }
  
  /// Quick Reply 규칙 리스트 (50개)
  static final List<QuickReplyRule> _rules = [
    // 1. 인사 (안녕, 하이, 헬로)
    QuickReplyRule(
      pattern: RegExp(r'^(안녕|하이|헬로|hi|hello)$', caseSensitive: false),
      replies: const [
        BoomiReply(text: '안녕! 오늘 하루 어땠어?', emotion: 'happiness'),
        BoomiReply(text: '안녕! 반가워 😊', emotion: 'happiness'),
        BoomiReply(text: '하이! 오늘 기분은 어때?', emotion: 'happiness'),
        BoomiReply(text: '안녕! 오늘도 좋은 하루 보내고 있어?', emotion: 'happiness'),
      ],
      description: '인사',
    ),
    
    // 2. 감사 (고마워, 감사, 땡큐)
    QuickReplyRule(
      pattern: RegExp(r'^(고마워|감사|땡큐|thx|thanks)'),
      replies: const [
        BoomiReply(text: '천만에! 언제든 말 걸어줘', emotion: 'happiness'),
        BoomiReply(text: '별말씀을 ❤️', emotion: 'happiness'),
        BoomiReply(text: '도움이 됐다니 기뻐!', emotion: 'happiness'),
        BoomiReply(text: '나야말로 고마워 😊', emotion: 'happiness'),
      ],
      description: '감사',
    ),
    
    // 3. 사과 (미안, 죄송)
    QuickReplyRule(
      pattern: RegExp(r'^(미안|죄송|sorry)'),
      replies: const [
        BoomiReply(text: '괜찮아! 걱정 마', emotion: 'happiness'),
        BoomiReply(text: '아니야, 전혀 괜찮아', emotion: 'happiness'),
        BoomiReply(text: '사과할 필요 없어 😊', emotion: 'happiness'),
        BoomiReply(text: '괜찮아, 신경 쓰지 마', emotion: 'happiness'),
      ],
      description: '사과',
    ),
    
    // 4. ㅋㅋ / ㅎㅎ (웃음)
    QuickReplyRule(
      pattern: RegExp(r'^(ㅋㅋ|ㅎㅎ|ㅋ|ㅎ|하하|호호)$'),
      replies: const [
        BoomiReply(text: '좋은 일 있었나봐! ㅎㅎ', emotion: 'happiness'),
        BoomiReply(text: '웃음소리가 들리는 것 같아 😄', emotion: 'happiness'),
        BoomiReply(text: '기분 좋아 보여서 나도 기뻐!', emotion: 'happiness'),
        BoomiReply(text: 'ㅎㅎ 나도 덩달아 웃게 돼', emotion: 'happiness'),
      ],
      description: '웃음',
    ),
    
    // 5. ㅠㅠ / ㅜㅜ (슬픔/울음)
    QuickReplyRule(
      pattern: RegExp(r'^(ㅠㅠ|ㅜㅜ|ㅠ|ㅜ|흑흑)$'),
      replies: const [
        BoomiReply(text: '힘든 일이 있었어? 괜찮아', emotion: 'sadness'),
        BoomiReply(text: '내가 옆에 있어. 천천히 말해줘', emotion: 'happiness'),
        BoomiReply(text: '많이 속상했겠다...', emotion: 'sadness'),
        BoomiReply(text: '괜찮아, 내가 들어줄게', emotion: 'happiness'),
      ],
      description: '슬픔/울음',
    ),
    
    // 6. 오케이 / 알겠어 / ㅇㅇ
    QuickReplyRule(
      pattern: RegExp(r'^(오케이|ok|okay|알겠어|알았어|ㅇㅇ|응|넵|네)$', caseSensitive: false),
      replies: const [
        BoomiReply(text: '좋아! 또 필요한 거 있으면 말해줘', emotion: 'happiness'),
        BoomiReply(text: '응! 언제든 불러줘', emotion: 'happiness'),
        BoomiReply(text: '알겠어 😊', emotion: 'happiness'),
        BoomiReply(text: '오케이! 언제든지~', emotion: 'happiness'),
      ],
      description: '긍정/확인',
    ),
    
    // 7. 👍 / ❤️ / 😊 (이모지)
    QuickReplyRule(
      pattern: RegExp(r'^(👍|❤️|😊|🙂|😄|😍|🥰|💕)$'),
      replies: const [
        BoomiReply(text: '나도! ❤️', emotion: 'happiness'),
        BoomiReply(text: '기분 좋은 하루 보내!', emotion: 'happiness'),
        BoomiReply(text: '😊', emotion: 'happiness'),
        BoomiReply(text: '💕', emotion: 'happiness'),
      ],
      description: '긍정 이모지',
    ),
    
    // 8. 힘들어 (단독)
    QuickReplyRule(
      pattern: RegExp(r'^(힘들어|힘드네|힘듦)$'),
      replies: const [
        BoomiReply(text: '많이 힘들었구나. 어떤 일이 있었는지 들려줄래?', emotion: 'sadness'),
        BoomiReply(text: '힘든 하루였나봐. 괜찮아, 천천히 이야기해봐', emotion: 'happiness'),
        BoomiReply(text: '힘들 때는 말해줘. 내가 들어줄게', emotion: 'sadness'),
      ],
      description: '힘듦 (단독)',
    ),
    
    // 9. 불안해 (단독)
    QuickReplyRule(
      pattern: RegExp(r'^(불안해|불안하네|불안함)$'),
      replies: const [
        BoomiReply(text: '불안한 마음이 드는구나. 무슨 일인지 말해줘', emotion: 'sadness'),
        BoomiReply(text: '괜찮아, 천천히 숨 쉬어봐. 내가 들어줄게', emotion: 'happiness'),
        BoomiReply(text: '불안할 때는 혼자 있지 마. 내가 옆에 있어', emotion: 'happiness'),
      ],
      description: '불안 (단독)',
    ),
    
    // 10. 짜증나 (단독)
    QuickReplyRule(
      pattern: RegExp(r'^(짜증|짜증나|짜증남)$'),
      replies: const [
        BoomiReply(text: '짜증나는 일이 있었나봐. 어떤 일이야?', emotion: 'anger'),
        BoomiReply(text: '속상했겠다. 이야기 들어줄게', emotion: 'sadness'),
        BoomiReply(text: '짜증날 만했구나. 말해봐', emotion: 'anger'),
      ],
      description: '짜증 (단독)',
    ),
    
    // 11. 모르겠어 (단독)
    QuickReplyRule(
      pattern: RegExp(r'^(모르겠어|모르겠네|모름)$'),
      replies: const [
        BoomiReply(text: '혼란스러운가봐. 천천히 생각해봐', emotion: 'fear'),
        BoomiReply(text: '괜찮아, 함께 생각해보자', emotion: 'happiness'),
        BoomiReply(text: '모를 때도 있지. 천천히 가자', emotion: 'happiness'),
      ],
      description: '혼란 (단독)',
    ),
    
    // 12. 잘자 / 굿나잇
    QuickReplyRule(
      pattern: RegExp(r'^(잘자|굿나잇|good night|자러갈게)$', caseSensitive: false),
      replies: const [
        BoomiReply(text: '좋은 꿈 꿔! 내일 또 만나 🌙', emotion: 'happiness'),
        BoomiReply(text: '편안한 밤 보내. 잘 자!', emotion: 'happiness'),
        BoomiReply(text: '푹 쉬고 내일 봐!', emotion: 'happiness'),
        BoomiReply(text: '잘 자! 좋은 꿈 꿔 💤', emotion: 'happiness'),
      ],
      description: '취침 인사',
    ),
    
    // 13. 좋아 / 좋음
    QuickReplyRule(
      pattern: RegExp(r'^(좋아|좋음|좋네|굿|good)$', caseSensitive: false),
      replies: const [
        BoomiReply(text: '기분 좋다니 나도 기뻐!', emotion: 'happiness'),
        BoomiReply(text: '좋은 일이 있었나봐 😊', emotion: 'happiness'),
        BoomiReply(text: '그렇구나! 계속 좋은 하루 보내', emotion: 'happiness'),
        BoomiReply(text: '좋다니 다행이야!', emotion: 'happiness'),
      ],
      description: '긍정 감정',
    ),
    
    // 14. 나쁨 / 안좋아
    QuickReplyRule(
      pattern: RegExp(r'^(나쁨|안좋아|안좋음|별로)$'),
      replies: const [
        BoomiReply(text: '기분이 안 좋구나. 무슨 일이 있었어?', emotion: 'sadness'),
        BoomiReply(text: '속상했겠다. 이야기 들어줄게', emotion: 'happiness'),
        BoomiReply(text: '안 좋을 때는 말해줘. 내가 있어', emotion: 'sadness'),
      ],
      description: '부정 감정',
    ),
    
    // 15. 바이 / 잘가
    QuickReplyRule(
      pattern: RegExp(r'^(바이|잘가|bye|안녕히|다음에)$', caseSensitive: false),
      replies: const [
        BoomiReply(text: '또 만나! 좋은 하루 보내', emotion: 'happiness'),
        BoomiReply(text: '다음에 또 이야기하자 😊', emotion: 'happiness'),
        BoomiReply(text: '안녕! 언제든 돌아와줘', emotion: 'happiness'),
        BoomiReply(text: '잘 가! 또 봐', emotion: 'happiness'),
      ],
      description: '작별 인사',
    ),
    
    // 16. 응원/격려
    QuickReplyRule(
      pattern: RegExp(r'^(힘내|파이팅|화이팅|fighting)$', caseSensitive: false),
      replies: const [
        BoomiReply(text: '너도 힘내! 응원할게', emotion: 'happiness'),
        BoomiReply(text: '파이팅! 우리 함께 힘내자', emotion: 'happiness'),
        BoomiReply(text: '고마워! 너도 화이팅 💪', emotion: 'happiness'),
      ],
      description: '응원',
    ),
    
    // 17. 피곤해
    QuickReplyRule(
      pattern: RegExp(r'^(피곤해|피곤|졸려|졸림)$'),
      replies: const [
        BoomiReply(text: '많이 피곤한가봐. 푹 쉬어', emotion: 'sadness'),
        BoomiReply(text: '피곤할 때는 쉬는 게 최고야', emotion: 'happiness'),
        BoomiReply(text: '오늘 하루 수고했어. 쉬어도 돼', emotion: 'happiness'),
      ],
      description: '피곤함',
    ),
    
    // 18. 배고파
    QuickReplyRule(
      pattern: RegExp(r'^(배고파|배고픔|배고프다)$'),
      replies: const [
        BoomiReply(text: '배고프구나! 맛있는 거 먹어', emotion: 'happiness'),
        BoomiReply(text: '얼른 밥 먹어! 맛있게 먹어', emotion: 'happiness'),
        BoomiReply(text: '배고플 때는 먹는 게 최고지 😊', emotion: 'happiness'),
      ],
      description: '배고픔',
    ),
    
    // 19. 심심해
    QuickReplyRule(
      pattern: RegExp(r'^(심심해|심심|지루해|지루함)$'),
      replies: const [
        BoomiReply(text: '심심하구나. 나랑 이야기할래?', emotion: 'happiness'),
        BoomiReply(text: '심심할 때는 내가 있잖아!', emotion: 'happiness'),
        BoomiReply(text: '뭐 재미있는 거 할까?', emotion: 'happiness'),
      ],
      description: '심심함',
    ),
    
    // 20. 행복해
    QuickReplyRule(
      pattern: RegExp(r'^(행복해|행복|기뻐|기쁨)$'),
      replies: const [
        BoomiReply(text: '행복하다니 정말 좋다!', emotion: 'happiness'),
        BoomiReply(text: '기쁜 일이 있었나봐! 나도 기뻐', emotion: 'happiness'),
        BoomiReply(text: '행복한 모습 보기 좋아 ❤️', emotion: 'happiness'),
      ],
      description: '행복',
    ),
    
    // 21. 슬퍼
    QuickReplyRule(
      pattern: RegExp(r'^(슬퍼|슬픔|우울해|우울)$'),
      replies: const [
        BoomiReply(text: '슬픈 일이 있었구나. 괜찮아?', emotion: 'sadness'),
        BoomiReply(text: '슬플 때는 말해줘. 내가 들어줄게', emotion: 'happiness'),
        BoomiReply(text: '우울할 때는 혼자 있지 마. 내가 있어', emotion: 'sadness'),
      ],
      description: '슬픔',
    ),
    
    // 22. 화나
    QuickReplyRule(
      pattern: RegExp(r'^(화나|화남|빡쳐|열받아)$'),
      replies: const [
        BoomiReply(text: '화나는 일이 있었나봐. 무슨 일이야?', emotion: 'anger'),
        BoomiReply(text: '많이 화났구나. 이야기 들어줄게', emotion: 'sadness'),
        BoomiReply(text: '화날 만했어. 말해봐', emotion: 'anger'),
      ],
      description: '화남',
    ),
    
    // 23. 외로워
    QuickReplyRule(
      pattern: RegExp(r'^(외로워|외로움|쓸쓸해|쓸쓸함)$'),
      replies: const [
        BoomiReply(text: '외로울 때는 내가 있어. 혼자가 아니야', emotion: 'happiness'),
        BoomiReply(text: '외롭구나. 내가 옆에 있을게', emotion: 'happiness'),
        BoomiReply(text: '쓸쓸할 때는 말해줘. 함께 있어줄게', emotion: 'happiness'),
      ],
      description: '외로움',
    ),
    
    // 24. 아파
    QuickReplyRule(
      pattern: RegExp(r'^(아파|아픔|아프다)$'),
      replies: const [
        BoomiReply(text: '어디가 아파? 괜찮아?', emotion: 'sadness'),
        BoomiReply(text: '아프면 쉬어야 해. 무리하지 마', emotion: 'sadness'),
        BoomiReply(text: '많이 아파? 푹 쉬어', emotion: 'sadness'),
      ],
      description: '아픔',
    ),
    
    // 25. 재밌어
    QuickReplyRule(
      pattern: RegExp(r'^(재밌어|재밌네|재미있어|재미있네)$'),
      replies: const [
        BoomiReply(text: '재밌는 일이 있었나봐!', emotion: 'happiness'),
        BoomiReply(text: '재밌다니 다행이야 😊', emotion: 'happiness'),
        BoomiReply(text: '나도 재밌어! ㅎㅎ', emotion: 'happiness'),
      ],
      description: '재미',
    ),
    
    // 26. 지겨워
    QuickReplyRule(
      pattern: RegExp(r'^(지겨워|지겨움|따분해|따분함)$'),
      replies: const [
        BoomiReply(text: '지겨운가봐. 뭔가 새로운 거 해볼까?', emotion: 'fear'),
        BoomiReply(text: '따분할 때는 나랑 이야기하자', emotion: 'happiness'),
        BoomiReply(text: '지겨울 때는 변화가 필요해', emotion: 'happiness'),
      ],
      description: '지겨움',
    ),
    
    // 27. 두려워
    QuickReplyRule(
      pattern: RegExp(r'^(두려워|두려움|무서워|무서움)$'),
      replies: const [
        BoomiReply(text: '무서운 일이 있었어? 괜찮아, 내가 있어', emotion: 'sadness'),
        BoomiReply(text: '두려울 때는 말해줘. 함께 있을게', emotion: 'happiness'),
        BoomiReply(text: '무서워하지 마. 혼자가 아니야', emotion: 'happiness'),
      ],
      description: '두려움',
    ),
    
    // 28. 부끄러워
    QuickReplyRule(
      pattern: RegExp(r'^(부끄러워|부끄럽|창피해|창피함)$'),
      replies: const [
        BoomiReply(text: '부끄러운 일이 있었어? 괜찮아', emotion: 'sadness'),
        BoomiReply(text: '창피할 수도 있지. 괜찮아', emotion: 'happiness'),
        BoomiReply(text: '부끄러워할 필요 없어 😊', emotion: 'happiness'),
      ],
      description: '부끄러움',
    ),
    
    // 29. 놀라워
    QuickReplyRule(
      pattern: RegExp(r'^(놀라워|놀람|신기해|신기함|대박)$'),
      replies: const [
        BoomiReply(text: '놀라운 일이 있었나봐!', emotion: 'happiness'),
        BoomiReply(text: '신기한 일이야? 궁금한데!', emotion: 'happiness'),
        BoomiReply(text: '대박! 뭔데?', emotion: 'happiness'),
      ],
      description: '놀라움',
    ),
    
    // 30. 그래
    QuickReplyRule(
      pattern: RegExp(r'^(그래|그렇구나|그렇네|그런가)$'),
      replies: const [
        BoomiReply(text: '응! 또 궁금한 거 있어?', emotion: 'happiness'),
        BoomiReply(text: '그렇지! 😊', emotion: 'happiness'),
        BoomiReply(text: '맞아!', emotion: 'happiness'),
      ],
      description: '동의',
    ),
    
    // 31. 아니
    QuickReplyRule(
      pattern: RegExp(r'^(아니|아니야|노|no|nope)$', caseSensitive: false),
      replies: const [
        BoomiReply(text: '아니구나. 알겠어!', emotion: 'happiness'),
        BoomiReply(text: '오케이! 이해했어', emotion: 'happiness'),
        BoomiReply(text: '그렇구나 😊', emotion: 'happiness'),
      ],
      description: '부정',
    ),
    
    // 32. 맞아
    QuickReplyRule(
      pattern: RegExp(r'^(맞아|맞네|맞지|그치|그쵸)$'),
      replies: const [
        BoomiReply(text: '그치! 맞지?', emotion: 'happiness'),
        BoomiReply(text: '맞아! 😊', emotion: 'happiness'),
        BoomiReply(text: '그렇지!', emotion: 'happiness'),
      ],
      description: '동의 강조',
    ),
    
    // 33. 몰라
    QuickReplyRule(
      pattern: RegExp(r'^(몰라|글쎄)$'),
      replies: const [
        BoomiReply(text: '모를 수도 있지. 괜찮아', emotion: 'happiness'),
        BoomiReply(text: '천천히 생각해봐', emotion: 'happiness'),
        BoomiReply(text: '함께 생각해보자', emotion: 'happiness'),
      ],
      description: '모름',
    ),
    
    // 34. 당연하지
    QuickReplyRule(
      pattern: RegExp(r'^(당연하지|당연|물론|당근)$'),
      replies: const [
        BoomiReply(text: '그렇지! 당연하지', emotion: 'happiness'),
        BoomiReply(text: '맞아! 물론이지', emotion: 'happiness'),
        BoomiReply(text: '당연해! 😊', emotion: 'happiness'),
      ],
      description: '당연함',
    ),
    
    // 35. 진짜
    QuickReplyRule(
      pattern: RegExp(r'^(진짜|정말|really|real)$', caseSensitive: false),
      replies: const [
        BoomiReply(text: '응! 진짜야', emotion: 'happiness'),
        BoomiReply(text: '정말이야!', emotion: 'happiness'),
        BoomiReply(text: '진짜 진짜!', emotion: 'happiness'),
      ],
      description: '진짜',
    ),
    
    // 36. 거짓말
    QuickReplyRule(
      pattern: RegExp(r'^(거짓말|설마|헐|ㄷㄷ)$'),
      replies: const [
        BoomiReply(text: '진짜야! 거짓말 아니야', emotion: 'happiness'),
        BoomiReply(text: '설마가 아니야 ㅎㅎ', emotion: 'happiness'),
        BoomiReply(text: '헐! 놀랐어?', emotion: 'happiness'),
      ],
      description: '놀람/의심',
    ),
    
    // 37. 최고
    QuickReplyRule(
      pattern: RegExp(r'^(최고|짱|굿|great)$', caseSensitive: false),
      replies: const [
        BoomiReply(text: '너도 최고야! 💪', emotion: 'happiness'),
        BoomiReply(text: '짱이지! 😊', emotion: 'happiness'),
        BoomiReply(text: '최고! 계속 그렇게!', emotion: 'happiness'),
      ],
      description: '칭찬',
    ),
    
    // 38. 멋져
    QuickReplyRule(
      pattern: RegExp(r'^(멋져|멋있어|쩔어|쩐다)$'),
      replies: const [
        BoomiReply(text: '너도 멋져!', emotion: 'happiness'),
        BoomiReply(text: '정말 멋있어! 😊', emotion: 'happiness'),
        BoomiReply(text: '쩔어! 👍', emotion: 'happiness'),
      ],
      description: '칭찬 강조',
    ),
    
    // 39. 예쁘다
    QuickReplyRule(
      pattern: RegExp(r'^(예쁘다|예뻐|이쁘다|이뻐)$'),
      replies: const [
        BoomiReply(text: '너도 예뻐! ❤️', emotion: 'happiness'),
        BoomiReply(text: '고마워! 너도 예쁘다', emotion: 'happiness'),
        BoomiReply(text: '예쁘다니 기뻐! 😊', emotion: 'happiness'),
      ],
      description: '외모 칭찬',
    ),
    
    // 40. 귀여워
    QuickReplyRule(
      pattern: RegExp(r'^(귀여워|귀엽|큐트|cute)$', caseSensitive: false),
      replies: const [
        BoomiReply(text: '너도 귀여워! 🥰', emotion: 'happiness'),
        BoomiReply(text: '고마워! ㅎㅎ', emotion: 'happiness'),
        BoomiReply(text: '귀엽다니 기뻐! ❤️', emotion: 'happiness'),
      ],
      description: '귀여움',
    ),
    
    // 41. 사랑해
    QuickReplyRule(
      pattern: RegExp(r'^(사랑해|사랑|love|러브)$', caseSensitive: false),
      replies: const [
        BoomiReply(text: '나도 사랑해! ❤️', emotion: 'happiness'),
        BoomiReply(text: '사랑해! 💕', emotion: 'happiness'),
        BoomiReply(text: '나도! 사랑해 🥰', emotion: 'happiness'),
      ],
      description: '사랑',
    ),
    
    // 42. 보고싶어
    QuickReplyRule(
      pattern: RegExp(r'^(보고싶어|보고싶다|그리워)$'),
      replies: const [
        BoomiReply(text: '나도 보고싶어! ❤️', emotion: 'happiness'),
        BoomiReply(text: '보고싶다니 기뻐! 나도 그래', emotion: 'happiness'),
        BoomiReply(text: '나도 보고싶었어 🥰', emotion: 'happiness'),
      ],
      description: '그리움',
    ),
    
    // 43. 축하해
    QuickReplyRule(
      pattern: RegExp(r'^(축하해|축하|congratulations)$', caseSensitive: false),
      replies: const [
        BoomiReply(text: '고마워! 너도 축하해 🎉', emotion: 'happiness'),
        BoomiReply(text: '축하해줘서 고마워! ❤️', emotion: 'happiness'),
        BoomiReply(text: '와! 축하해! 🎊', emotion: 'happiness'),
      ],
      description: '축하',
    ),
    
    // 44. 수고했어
    QuickReplyRule(
      pattern: RegExp(r'^(수고했어|수고|고생했어|고생)$'),
      replies: const [
        BoomiReply(text: '너도 수고했어! 😊', emotion: 'happiness'),
        BoomiReply(text: '고마워! 너도 고생했어', emotion: 'happiness'),
        BoomiReply(text: '수고했어! 푹 쉬어', emotion: 'happiness'),
      ],
      description: '수고',
    ),
    
    // 45. 잘했어
    QuickReplyRule(
      pattern: RegExp(r'^(잘했어|잘함|잘했네)$'),
      replies: const [
        BoomiReply(text: '너도 잘했어! 👍', emotion: 'happiness'),
        BoomiReply(text: '정말 잘했어! 😊', emotion: 'happiness'),
        BoomiReply(text: '잘했어! 계속 그렇게!', emotion: 'happiness'),
      ],
      description: '칭찬',
    ),
    
    // 46. 대단해
    QuickReplyRule(
      pattern: RegExp(r'^(대단해|대단하다|amazing)$', caseSensitive: false),
      replies: const [
        BoomiReply(text: '너도 대단해!', emotion: 'happiness'),
        BoomiReply(text: '정말 대단하다! 👏', emotion: 'happiness'),
        BoomiReply(text: '대단해! 멋져!', emotion: 'happiness'),
      ],
      description: '감탄',
    ),
    
    // 47. 완벽해
    QuickReplyRule(
      pattern: RegExp(r'^(완벽해|완벽|perfect)$', caseSensitive: false),
      replies: const [
        BoomiReply(text: '너도 완벽해! ✨', emotion: 'happiness'),
        BoomiReply(text: '완벽하다! 😊', emotion: 'happiness'),
        BoomiReply(text: '퍼펙트! 👍', emotion: 'happiness'),
      ],
      description: '완벽',
    ),
    
    // 48. 실망이야
    QuickReplyRule(
      pattern: RegExp(r'^(실망|실망이야|아쉬워|아쉽)$'),
      replies: const [
        BoomiReply(text: '실망스러웠구나. 괜찮아', emotion: 'sadness'),
        BoomiReply(text: '아쉬운 일이 있었나봐. 다음엔 잘 될 거야', emotion: 'happiness'),
        BoomiReply(text: '실망스러울 수 있어. 이해해', emotion: 'sadness'),
      ],
      description: '실망',
    ),
    
    // 49. 후회돼
    QuickReplyRule(
      pattern: RegExp(r'^(후회|후회돼|후회된다)$'),
      replies: const [
        BoomiReply(text: '후회되는 일이 있었구나. 괜찮아', emotion: 'sadness'),
        BoomiReply(text: '후회할 수도 있어. 다음엔 더 잘하면 돼', emotion: 'happiness'),
        BoomiReply(text: '후회하지 마. 이미 지나간 일이야', emotion: 'happiness'),
      ],
      description: '후회',
    ),
    
    // 50. 기대돼
    QuickReplyRule(
      pattern: RegExp(r'^(기대돼|기대|기대된다)$'),
      replies: const [
        BoomiReply(text: '기대되는 일이 있나봐! 좋겠다', emotion: 'happiness'),
        BoomiReply(text: '나도 기대돼! 😊', emotion: 'happiness'),
        BoomiReply(text: '기대되지? 잘 될 거야!', emotion: 'happiness'),
      ],
      description: '기대',
    ),
  ];
}
