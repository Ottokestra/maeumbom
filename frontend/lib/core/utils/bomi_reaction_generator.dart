import 'dart:math';
import '../../data/models/routine/routine_recommendation.dart';

/// 봄이 입력 반응 메시지 생성기
/// 
/// 사용자가 텍스트를 입력할 때 봄이가 보여줄 다양한 반응 메시지를 생성합니다.
/// 시간대, 요일, 루틴 데이터를 기반으로 확률적으로 메시지를 선택합니다.
class BomiReactionGenerator {
  static final _random = Random();

  /// 반응 메시지 생성
  /// 
  /// [routineData]: 사용자의 루틴 추천 데이터 (없을 수 있음)
  /// 
  /// 반환: 봄이의 반응 메시지
  static String generate({RoutineRecommendation? routineData}) {
    final now = DateTime.now();
    final hour = now.hour;
    final weekday = now.weekday;
    final hasRoutine = routineData != null && routineData.routines.isNotEmpty;

    // 5% 확률로 레어 반응
    if (_random.nextDouble() < 0.05) {
      return _getRareReaction();
    }

    if (hasRoutine) {
      // 루틴 데이터가 있을 때: 루틴 30% / 시간대 25% / 요일 15% / 기본 30%
      final value = _random.nextDouble();
      if (value < 0.30) {
        return _getRoutineReaction(routineData);
      } else if (value < 0.55) {
        return _getTimeBasedReaction(hour);
      } else if (value < 0.70) {
        return _getWeekdayReaction(weekday);
      } else {
        return _getBasicReaction();
      }
    } else {
      // 루틴 데이터가 없을 때: 기본 50% / 시간대 30% / 요일 20%
      final value = _random.nextDouble();
      if (value < 0.50) {
        return _getBasicReaction();
      } else if (value < 0.80) {
        return _getTimeBasedReaction(hour);
      } else {
        return _getWeekdayReaction(weekday);
      }
    }
  }

  /// 기본 반응 메시지
  static String _getBasicReaction() {
    final reactions = [
      // 기본 반응
      "두근두근 무슨 말을 할지 정말 기대돼!!",
      "어떤 이야기를 들려줄 거야?",
      "오늘은 무슨 일이 있었어?",
      "궁금해! 말해줘!",
      "나한테 얘기해줄래?",
      "어떤 이야기일까? 너무 기대된다.",
      "듣고 있어! 말해봐!",
      "말해봐! 듣고 있어!",
      // 친근하고 귀여운 느낌
      "헤헤 뭐라고 할 거야?",
      "나한테만 말해줘!",
      "어서어서! 궁금해!",
      "오늘은 어떤 이야기를 들려줄까?",
      "나 지금 엄청 집중하고 있어!",
      "히히 뭔가 재밌는 일 있었어?",
      // 위로하는 느낌
      "무슨 일이든 들어줄게",
      "편하게 말해도 돼",
      "천천히 말해줘, 괜찮아",
      "내가 옆에 있어줄게",
      "힘든 일 있었어? 말해봐",
      // 응원하는 느낌
      "오늘도 화이팅!",
      "너라면 잘할 수 있어!",
      "뭐든지 말해봐! 응원할게!",
      "오늘 하루도 수고했어!",
      "너의 이야기가 듣고 싶어!",
    ];
    return reactions[_random.nextInt(reactions.length)];
  }

  /// 시간대별 반응 메시지
  static String _getTimeBasedReaction(int hour) {
    List<String> reactions;

    if (hour >= 6 && hour < 11) {
      // 아침 (6-11시)
      reactions = [
        "오늘 아침은 어땠어?",
        "잘 잤어?",
        "좋은 아침이야!",
        "아침부터 무슨 일이 있었어?",
        "오늘 기분은 어때?",
        // 친근하고 귀여운
        "아침부터 만나서 반가워!",
        "오늘도 좋은 하루 보내자!",
        "일어나자마자 나한테 와줘서 고마워!",
        // 위로하는
        "아침부터 힘들지 않아?",
        "천천히 시작해도 괜찮아",
        // 응원하는
        "오늘도 힘내!",
        "좋은 하루 만들어보자!",
      ];
    } else if (hour >= 11 && hour < 14) {
      // 점심 (11-14시)
      reactions = [
        "점심은 맛있게 먹었어?",
        "오전은 어땠어?",
        "배고프지 않아?",
        "점심 시간이네! 뭐 먹었어?",
        "오전에 무슨 일 있었어?",
        // 친근하고 귀여운
        "점심 뭐 먹었어? 나도 궁금해!",
        "배불러? 나는 배고파!",
        "점심 시간이 제일 좋아!",
        // 위로하는
        "오전에 힘든 일 있었어?",
        "잠깐 쉬어가도 괜찮아",
        // 응원하는
        "오후도 화이팅!",
        "반은 왔어! 조금만 더!",
      ];
    } else if (hour >= 14 && hour < 20) {
      // 저녁 (14-20시)
      reactions = [
        "하루는 어땠어?",
        "피곤하진 않아?",
        "오늘 하루 어땠어?",
        "오후는 잘 보냈어?",
        "힘든 일은 없었어?",
        // 친근하고 귀여운
        "오늘 하루 재밌었어?",
        "나한테 오늘 있었던 일 얘기해줘!",
        "저녁 먹었어? 뭐 먹었어?",
        // 위로하는
        "오늘 하루 고생 많았어",
        "힘들었지? 잘 버텼어",
        "괜찮아, 내가 들어줄게",
        // 응원하는
        "오늘도 정말 잘했어!",
        "조금만 더 힘내!",
        "거의 다 왔어!",
      ];
    } else {
      // 밤 (20-6시)
      reactions = [
        "오늘 하루 수고했어!",
        "푹 쉬어야 해!",
        "잠은 잘 오고 있어?",
        "오늘 하루 어땠어?",
        "이제 쉴 시간이야!",
        // 친근하고 귀여운
        "자기 전에 나한테 와줘서 고마워!",
        "오늘 하루 어땠는지 들려줘!",
        "밤에 만나니까 더 좋아!",
        // 위로하는
        "오늘 하루 정말 고생했어",
        "이제 푹 쉬어도 돼",
        "힘들었던 일은 다 잊고 쉬자",
        "내일은 더 좋은 날이 될 거야",
        // 응원하는
        "오늘도 최고였어!",
        "내일도 잘할 수 있을 거야!",
        "오늘 하루도 정말 잘 버텼어!",
      ];
    }

    return reactions[_random.nextInt(reactions.length)];
  }

  /// 요일별 반응 메시지
  static String _getWeekdayReaction(int weekday) {
    List<String> reactions;

    if (weekday == DateTime.monday) {
      reactions = [
        "새로운 한 주가 시작됐네!",
        "월요일은 어때?",
        "이번 주는 어떨 것 같아?",
        "월요일이야! 힘내!",
        // 친근하고 귀여운
        "월요일이지만 괜찮아!",
        "새로운 한 주! 설레지 않아?",
        // 위로하는
        "월요일이라 힘들지? 괜찮아",
        "천천히 시작하자",
        // 응원하는
        "이번 주도 화이팅!",
        "월요일도 잘 이겨낼 수 있어!",
      ];
    } else if (weekday == DateTime.friday) {
      reactions = [
        "주말이 코앞이네!",
        "금요일이다! 신나지?",
        "이번 주도 거의 끝났어!",
        // 친근하고 귀여운
        "금요일이라 기분 좋아!",
        "주말 계획 있어?",
        "드디어 금요일이야!",
        // 위로하는
        "이번 주도 고생 많았어",
        "주말엔 푹 쉬어",
        // 응원하는
        "이번 주도 정말 잘했어!",
        "마지막까지 화이팅!",
      ];
    } else if (weekday == DateTime.saturday || weekday == DateTime.sunday) {
      reactions = [
        "주말 잘 보내고 있어?",
        "오늘은 쉬는 날이지?",
        "주말에 뭐 하고 있어?",
        "주말 즐겁게 보내!",
        // 친근하고 귀여운
        "주말이라 기분 좋지?",
        "오늘 뭐 하고 놀았어?",
        "주말에 만나니까 더 좋아!",
        // 위로하는
        "주말엔 푹 쉬어야 해",
        "오늘은 마음 편히 쉬자",
        // 응원하는
        "주말 알차게 보내!",
        "재충전하는 시간 가져!",
      ];
    } else {
      reactions = [
        "오늘 하루는 어때?",
        "무슨 일이 있었어?",
        "오늘은 어떤 날이야?",
        "이번 주는 잘 지내고 있어?",
      ];
    }

    return reactions[_random.nextInt(reactions.length)];
  }

  /// 루틴 기반 반응 메시지
  static String _getRoutineReaction(RoutineRecommendation routineData) {
    if (routineData.routines.isEmpty) {
      return _getBasicReaction();
    }

    // 랜덤하게 루틴 하나 선택
    final routine = routineData.routines[_random.nextInt(routineData.routines.length)];
    final routineTitle = routine.title;

    final templates = [
      "오늘 $routineTitle은 어땠어?",
      "$routineTitle 잘 하고 있어?",
      "$routineTitle 시간 가졌어?",
      "어제 $routineTitle 했다며? 오늘은?",
      "$routineTitle는 어때?",
      "$routineTitle 해봤어?",
    ];

    return templates[_random.nextInt(templates.length)];
  }

  /// 레어 반응 메시지 (5% 확률)
  /// 
  /// 특수문자 이모티콘이 포함된 특별한 반응
  static String _getRareReaction() {
    final reactions = [
      "헉! (ʘ‿ʘ) 뭐라고?!",
      "두근두근... ♡(ˊ͈ ॢꇴ ˋ͈ॢ)♡",
      "사실... 너무 궁금해서 잠이 안 와 (´°̥̥̥̥̥̥̥̥ω°̥̥̥̥̥̥̥̥｀)",
      "오늘따라 왠지... ✧*｡٩(ˊᗜˋ*)و✧*｡",
      "와! 특별한 이야기 냄새가 나! (๑•̀ㅂ•́)و✧",
      "귀 쫑긋! (๑•ᴗ•๑)♡",
      // 추가 레어 반응
      "오호! 뭔가 특별한 이야기인가? (๑˃̵ᴗ˂̵)و",
      "나만 들을 수 있는 비밀 이야기야? ✧٩(ˊωˋ*)و✧",
      "히히 재밌을 것 같아! (ノ◕ヮ◕)ノ*:･ﾟ✧",
    ];
    return reactions[_random.nextInt(reactions.length)];
  }

  /// 대기 메시지 생성 (AI 응답 생성 중)
  /// 
  /// 사용자가 채팅을 입력하고 AI 응답을 기다리는 동안 표시할 메시지를 생성합니다.
  /// 시간대에 따라 다양한 메시지를 확률적으로 선택합니다.
  /// 
  /// 반환: 봄이의 대기 메시지
  static String generateWaitingMessage() {
    final now = DateTime.now();
    final hour = now.hour;

    // 5% 확률로 레어 대기 메시지
    if (_random.nextDouble() < 0.05) {
      return _getRareWaitingMessage();
    }

    // 30% 확률로 시간대별 메시지, 70% 확률로 기본 메시지
    final value = _random.nextDouble();
    if (value < 0.30) {
      return _getTimeBasedWaitingMessage(hour);
    } else {
      return _getBasicWaitingMessage();
    }
  }

  /// 기본 대기 메시지
  static String _getBasicWaitingMessage() {
    final messages = [
      // 생각하는 느낌
      "음... 뭐라고 해야 하지?",
      "잠깐만 생각해볼게!",
      "어떻게 말하면 좋을까?",
      "음... 생각 중이야!",
      "잠시만, 고민 중!",
      "뭐라고 답해줄까 생각 중이야!",
      
      // 기다림 요청
      "조금만 기다려줘!",
      "금방 답해줄게!",
      "잠깐만 기다려!",
      "곧 답해줄게!",
      "조금만 시간을 줘!",
      "잠시만 기다려줄래?",
      
      // 친근한 느낌
      "히히 잠시만~",
      "두근두근 답변 준비 중!",
      "나 지금 열심히 생각하고 있어!",
      "잠깐만! 좋은 답변 준비할게!",
      "어떻게 말해줄까 고민 중이야!",
      "기다려줘서 고마워!",
      
      // 위로하는 느낌 (대기 중에도 따뜻함 유지)
      "너를 위해 최선의 답변 찾는 중!",
      "좋은 답변 하려고 열심히 생각 중!",
      "너에게 딱 맞는 답변 준비할게!",
      "진심을 담아서 답해줄게!",
      "너를 위한 답변, 곧 준비될 거야!",
      
      // 응원하는 느낌
      "최선을 다해 답해줄게!",
      "좋은 이야기 들려줄게!",
      "멋진 답변 준비할게!",
    ];
    return messages[_random.nextInt(messages.length)];
  }

  /// 시간대별 대기 메시지
  static String _getTimeBasedWaitingMessage(int hour) {
    List<String> messages;

    if (hour >= 6 && hour < 11) {
      // 아침 (6-11시)
      messages = [
        "아침부터 생각이 많네! 잠깐만~",
        "좋은 아침! 답변 준비 중이야!",
        "아침에 만나서 반가워! 잠깐만!",
        "오늘 아침엔 뭐라고 해줄까?",
        "아침이라 머리가 잘 돌아가! 잠깐만!",
      ];
    } else if (hour >= 11 && hour < 14) {
      // 점심 (11-14시)
      messages = [
        "점심시간이네! 잠깐만 생각해볼게!",
        "배고프지만 답변은 해줄게! 잠깐만!",
        "점심 먹고 왔어? 답변 준비 중!",
        "점심시간에도 열심히 생각 중!",
      ];
    } else if (hour >= 14 && hour < 20) {
      // 저녁 (14-20시)
      messages = [
        "오후라 좀 졸리지만 열심히 생각할게!",
        "하루 어땠어? 잠깐만 생각해볼게!",
        "오후에도 힘내서 답해줄게!",
        "저녁 시간이네! 답변 준비 중!",
      ];
    } else {
      // 밤 (20-6시)
      messages = [
        "밤이지만 열심히 생각할게!",
        "자기 전에 좋은 답변 해줄게!",
        "밤에도 나는 깨어있어! 잠깐만!",
        "늦은 시간인데 고마워! 답변 준비 중!",
        "밤이라 더 집중돼! 잠깐만!",
      ];
    }

    return messages[_random.nextInt(messages.length)];
  }

  /// 레어 대기 메시지 (5% 확률)
  /// 
  /// 특수문자 이모티콘이 포함된 특별한 대기 메시지
  static String _getRareWaitingMessage() {
    final messages = [
      "음... (๑•́ ₃ •̀๑) 뭐라고 하지?",
      "잠깐만! ✧*｡٩(ˊᗜˋ*)و✧*｡",
      "생각 중... (´・ω・｀)",
      "두근두근... ♡(ˊ͈ ॢꇴ ˋ͈ॢ)♡ 답변 준비 중!",
      "히히 잠시만! (ノ◕ヮ◕)ノ*:･ﾟ✧",
      "음... 좋은 답변 생각 중! (๑˃̵ᴗ˂̵)و",
      "잠깐! 멋진 답변 준비할게! ✧٩(ˊωˋ*)و✧",
    ];
    return messages[_random.nextInt(messages.length)];
  }

  /// 대화 종료 확인 메시지 생성
  /// 
  /// 사용자가 뒤로가기 버튼을 눌렀을 때 표시할 확인 메시지를 생성합니다.
  /// 봄이의 친근하고 아쉬워하는 감정을 담은 다양한 메시지를 랜덤으로 제공합니다.
  /// 
  /// 반환: {'title': '제목', 'content': '내용'} 형태의 Map
  static Map<String, String> generateExitConfirmation() {
    final confirmations = [
      {
        'title': '벌써 가는 거야?',
        'content': '오늘 이야기 정말 좋았어!\n다음에 또 만날 수 있지?',
      },
      {
        'title': '잠깐! 벌써 가는 거야?',
        'content': '지금까지 나눈 이야기는 잘 간직할게.\n정말 가는 거야?',
      },
      {
        'title': '헉! 벌써?',
        'content': '조금 아쉬운데...\n다음에 또 올 거지?',
      },
      {
        'title': '오늘은 여기까지?',
        'content': '오늘 이야기 고마웠어.\n다음에 또 만나자!',
      },
      {
        'title': '벌써 가려고?',
        'content': '아쉽지만... 다음에 또 놀자!\n꼭 다시 와줘!',
      },
    ];
    
    return confirmations[_random.nextInt(confirmations.length)];
  }
}

