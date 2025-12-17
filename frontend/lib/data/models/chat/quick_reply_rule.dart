import 'bomi_reply.dart';

/// Quick Reply 매칭 규칙
/// 
/// 정규식 패턴과 응답 후보 리스트를 포함하는 규칙입니다.
/// 사용자 입력이 패턴과 매칭되면 응답 후보 중 하나를 랜덤으로 선택합니다.
class QuickReplyRule {
  /// 정규식 패턴
  final RegExp pattern;
  
  /// 응답 후보 리스트
  final List<BoomiReply> replies;
  
  /// 규칙 설명 (디버깅용)
  final String description;
  
  const QuickReplyRule({
    required this.pattern,
    required this.replies,
    required this.description,
  });
}
