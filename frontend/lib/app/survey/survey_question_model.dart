class SurveyQuestion {
  final int id;
  final String text;
  final String description;

  const SurveyQuestion({
    required this.id,
    required this.text,
    required this.description,
  });
}

const List<SurveyQuestion> menopauseQuestions = [
  SurveyQuestion(
    id: 1,
    text: '일의 집중력이나 기억력이\n예전 같지 않다고 느낀다',
    description: '최근 업무나 일상생활에서 깜빡하는 일이 잦아졌나요?',
  ),
  SurveyQuestion(
    id: 2,
    text: '얼굴이나 목이 붉어지거나\n화끈거리는 열감이 있다',
    description: '갑자기 더워지거나 식은땀이 나는 증상이 있나요?',
  ),
  SurveyQuestion(
    id: 3,
    text: '잠들기가 어렵거나\n도중에 자주 깬다',
    description: '수면의 질이 떨어졌다고 느끼시나요?',
  ),
  SurveyQuestion(
    id: 4,
    text: '사소한 일에도 짜증이 나거나\n기분이 오르락내리락 한다',
    description: '감정 조절이 어렵고 우울감이 느껴지나요?',
  ),
];
