/// 온보딩 설문 데이터를 임시로 저장하는 전역 홀더
/// 
/// 각 sign_up 화면에서 데이터를 저장하고,
/// 마지막 sign_up5에서 모든 데이터를 수집하여 API로 전송합니다.
class SurveyDataHolder {
  static final SurveyDataHolder _instance = SurveyDataHolder._internal();
  factory SurveyDataHolder() => _instance;
  SurveyDataHolder._internal();

  // Q1: 닉네임
  String? nickname;

  // Q2: 연령대
  String? ageGroup;

  // Q3: 성별
  String? gender;

  // Q4: 결혼 여부
  String? maritalStatus;

  // Q5: 자녀 유무
  String? childrenYn;

  // Q6: 함께 생활하는 사람
  String? livingWith;

  // Q7: 성향
  String? personalityType;

  // Q8: 활동 스타일
  String? activityStyle;

  // Q9: 스트레스 해소법 (다중선택)
  List<String>? stressRelief;

  // Q10: 취미 (다중선택)
  List<String>? hobbies;

  /// 모든 필수 데이터가 입력되었는지 확인
  bool get isComplete {
    return nickname != null &&
        ageGroup != null &&
        gender != null &&
        maritalStatus != null &&
        childrenYn != null &&
        livingWith != null &&
        personalityType != null &&
        activityStyle != null &&
        stressRelief != null &&
        stressRelief!.isNotEmpty &&
        hobbies != null &&
        hobbies!.isNotEmpty;
  }

  /// 데이터 초기화
  void clear() {
    nickname = null;
    ageGroup = null;
    gender = null;
    maritalStatus = null;
    childrenYn = null;
    livingWith = null;
    personalityType = null;
    activityStyle = null;
    stressRelief = null;
    hobbies = null;
  }
}

