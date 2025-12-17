import 'package:flutter/material.dart';

/// 텍스트 포맷팅 유틸리티
///
/// 마크다운 정제 및 텍스트 정규화 기능을 제공합니다.
class TextFormatter {
  /// 기본 마크다운 정제 (볼드, 이탤릭, 줄바꿈)
  ///
  /// 다음 마크다운 문법을 제거하고 일반 텍스트로 변환합니다:
  /// - **볼드** → 볼드
  /// - *이탤릭* → 이탤릭
  /// - 번호 리스트 정리
  /// - 연속된 줄바꿈 정규화
  static String formatBasicMarkdown(String text) {
    String formatted = text;

    // 1. 볼드 제거 (**text** → text) - 줄바꿈 포함 처리
    formatted = formatted.replaceAllMapped(
      RegExp(r'\*\*([^\*]+?)\*\*', dotAll: true),
      (match) => match.group(1) ?? '',
    );

    // 2. 이탤릭 제거 (*text* → text) - 볼드 처리 후 남은 단일 * 처리
    formatted = formatted.replaceAllMapped(
      RegExp(r'\*([^\*]+?)\*', dotAll: true),
      (match) => match.group(1) ?? '',
    );

    // 3. 번호 리스트 앞에 줄바꿈 추가 (가독성 향상)
    // 문장 중간에 있는 "숫자." 패턴 앞에 줄바꿈 추가
    formatted = formatted.replaceAllMapped(
      RegExp(r'([^\n])\s+(\d+\.)\s+'),
      (match) => '${match.group(1)}\n${match.group(2)} ',
    );

    // 4. 연속된 줄바꿈 정규화 (3개 이상을 2개로)
    formatted = formatted.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    // 5. 앞뒤 공백 제거
    formatted = formatted.trim();

    return formatted;
  }

  /// 텍스트 길이 제한 (말줄임표 추가)
  static String truncate(String text, int maxLength, {String suffix = '...'}) {
    if (text.length <= maxLength) {
      return text;
    }
    return text.substring(0, maxLength - suffix.length) + suffix;
  }

  /// 줄바꿈을 공백으로 변환 (한 줄 요약용)
  static String toSingleLine(String text) {
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// 봄이 reply_text를 말풍선/마크다운에 잘 어울리게 줄바꿈 정리
  static String beautifyBomiMarkdown(String raw) {
    if (raw.trim().isEmpty) return raw;

    // 1. 이탤릭만 제거 (볼드는 TextSpan에서 색상 처리)
    String cleaned = raw;
    
    // 이탤릭 제거 (*text* → text) - 볼드가 아닌 단일 * 처리
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'(?<!\*)\*(?!\*)([^\*]+?)(?<!\*)\*(?!\*)'),
      (match) => match.group(1) ?? '',
    );

    // 2. 문장 단위로 자르기 (., ?, !, …, ... 기준)
    final sentences = cleaned
        .replaceAll('...', '…') // ... → … 통합
        .split(RegExp(r'(?<=[\.!\?…])\s+')) // 구두점 + 공백 기준 split
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final buffer = StringBuffer();

    // 3. 2문장씩 묶어서 한 단락으로
    for (int i = 0; i < sentences.length; i += 2) {
      final first = sentences[i];
      final second = (i + 1 < sentences.length) ? sentences[i + 1] : null;

      if (second == null) {
        // 문장 1개만 남은 경우
        buffer.writeln(first);
      } else {
        // 같은 단락 안에서 살짝 끊어서 보여주고 싶으면 강제 줄바꿈 두 개
        buffer.writeln('$first  ');
        buffer.writeln(second);
      }

      // 마지막 단락이 아니면 빈 줄 추가 (새 문단)
      if (i + 2 < sentences.length) {
        buffer.writeln();
      }
    }

    return buffer.toString().trimRight();
  }

  /// 트레이닝 전용 마크다운 포맷팅
  ///
  /// 다음 규칙을 적용합니다:
  /// - "" 로 감싸진 텍스트를 **볼드** 마크다운으로 변환
  /// - 맞춤표(.) 뒤에 줄바꿈 추가
  /// - 기본 마크다운 정제 (볼드, 이탤릭 등)
  static String formatTrainingText(String text) {
    if (text.trim().isEmpty) return text;

    String formatted = text;

    // 1. "" 텍스트를 **볼드** 마크다운으로 변환
    // "텍스트" → **텍스트**
    formatted = formatted.replaceAllMapped(
      RegExp(r'"([^"]+)"'),
      (match) => '**${match.group(1)}**',
    );

    // 2. 맞춤표(.) 뒤에 공백이 있고 다음에 문자가 오는 경우 줄바꿈 추가
    // 단, 이미 줄바꿈이 있거나 URL, 숫자가 아닌 경우에만
    formatted = formatted.replaceAllMapped(
      RegExp(r'(\.)(\s+)(?=[가-힣A-Z"**])'),
      (match) => '${match.group(1)}\n',
    );

    // 3. 기본 마크다운 정제 적용 (볼드 유지, 나머지 정리)
    // 여기서는 볼드를 유지하기 위해 커스텀 처리

    // 이탤릭 제거 (*text* → text) - 볼드가 아닌 단일 * 처리
    formatted = formatted.replaceAllMapped(
      RegExp(r'(?<!\*)\*(?!\*)([^\*]+?)(?<!\*)\*(?!\*)'),
      (match) => match.group(1) ?? '',
    );

    // 연속된 줄바꿈 정규화 (3개 이상을 2개로)
    formatted = formatted.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    // 앞뒤 공백 제거
    formatted = formatted.trim();

    return formatted;
  }

  /// 마크다운 볼드를 TextSpan으로 변환 (색상 강조)
  /// 
  /// **텍스트** 형식의 볼드 마크다운을 파싱하여
  /// 해당 부분에 지정된 색상과 볼드 스타일을 적용한 TextSpan 리스트를 반환합니다.
  /// 
  /// Args:
  ///   text: 파싱할 원본 텍스트
  ///   baseStyle: 기본 텍스트 스타일
  ///   boldColor: 볼드 텍스트에 적용할 색상
  /// 
  /// Returns:
  ///   TextSpan 리스트
  static List<TextSpan> parseMarkdownToSpans(
    String text,
    TextStyle baseStyle,
    Color boldColor,
  ) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'\*\*([^\*]+?)\*\*');
    int lastIndex = 0;
    
    for (final match in regex.allMatches(text)) {
      // 볼드 이전 일반 텍스트
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: baseStyle,
        ));
      }
      
      // 볼드 텍스트 (색상 강조)
      spans.add(TextSpan(
        text: match.group(1),
        style: baseStyle.copyWith(
          color: boldColor,
          fontWeight: FontWeight.bold,
        ),
      ));
      
      lastIndex = match.end;
    }
    
    // 남은 일반 텍스트
    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: baseStyle,
      ));
    }
    
    return spans;
  }
}
