import 'package:flutter/material.dart';
import '../characters/app_characters.dart';
import '../characters/app_character_colors.dart';

/// 선택지 레이아웃 타입
enum ChoiceLayout {
  horizontal, // 가로 배치 (2개)
  vertical, // 세로 배치 (2-5개)
}

/// 개별 선택지 버튼
///
/// 사용 예시:
/// ```dart
/// ChoiceButton(
///   text: "선택지 텍스트",
///   index: 0,
///   isSelected: false,
///   emotionId: EmotionId.relief,
///   showBorder: true,
///   showNumber: true,
///   onTap: () {},
/// )
/// ```
class ChoiceButton extends StatelessWidget {
  /// 버튼에 표시될 텍스트
  final String text;

  /// 버튼의 순서 (0부터 시작)
  final int index;

  /// 선택 상태
  final bool isSelected;

  /// 감정 기반 색상 (null이면 기본 색상)
  final EmotionId? emotionId;

  /// 클릭 콜백
  final VoidCallback? onTap;

  /// 테두리 표시 여부
  final bool showBorder;

  /// 번호 표시 여부
  final bool showNumber;

  const ChoiceButton({
    super.key,
    required this.text,
    required this.index,
    this.isSelected = false,
    this.emotionId,
    this.onTap,
    this.showBorder = true,
    this.showNumber = true,
  });

  @override
  Widget build(BuildContext context) {
    // 감정 색상 가져오기
    final colors = emotionId != null
        ? getEmotionColors(emotionId!)
        : const EmotionColorPair(
            primary: Color(0xFF4A9DFF),
            secondary: Color(0xFFD6EBFF),
          );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          // 단일 연한 배경색
          color: colors.secondary.withOpacity(0.2),
          // 선택적 테두리
          border: showBorder
              ? Border.all(
                  width: 2,
                  color: isSelected ? colors.primary : colors.primary.withOpacity(0.5),
                )
              : null,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 선택적 번호 표시
            if (showNumber)
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16777200),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Color(0xFF243447),
                      fontSize: 16,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w700,
                      height: 1.50,
                    ),
                  ),
                ),
              ),
            if (showNumber) const SizedBox(width: 12),
            // 텍스트
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: Color(0xFF243447),
                  fontSize: 16,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w500,
                  height: 1.63,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 선택지 버튼 그룹
///
/// 사용 예시:
/// ```dart
/// ChoiceButtonGroup(
///   choices: ['선택지 1', '선택지 2'],
///   selectedIndex: 0,
///   layout: ChoiceLayout.horizontal,
///   emotionIds: [EmotionId.relief, EmotionId.joy],
///   showBorder: true,
///   showNumber: true,
///   onChoiceSelected: (index, choice) {
///     print('Selected: $choice');
///   },
/// )
/// ```
class ChoiceButtonGroup extends StatelessWidget {
  /// 선택지 텍스트 리스트
  final List<String> choices;

  /// 현재 선택된 인덱스 (-1이면 선택 안 됨)
  final int? selectedIndex;

  /// 선택 콜백
  final Function(int index, String choice)? onChoiceSelected;

  /// 레이아웃 타입 (가로/세로)
  final ChoiceLayout layout;

  /// 각 선택지별 감정 ID (null이면 기본 패턴 사용)
  final List<EmotionId>? emotionIds;

  /// 테두리 표시 여부
  final bool showBorder;

  /// 번호 표시 여부
  final bool showNumber;

  const ChoiceButtonGroup({
    super.key,
    required this.choices,
    this.selectedIndex,
    this.onChoiceSelected,
    this.layout = ChoiceLayout.vertical,
    this.emotionIds,
    this.showBorder = true,
    this.showNumber = true,
  });

  @override
  Widget build(BuildContext context) {
    // 기본 감정 패턴
    final defaultEmotionIds = [
      EmotionId.relief, // 파랑
      EmotionId.joy, // 노랑
      EmotionId.love, // 핑크
      EmotionId.interest, // 보라
      EmotionId.confidence, // 골드
    ];

    final effectiveEmotionIds = emotionIds ?? defaultEmotionIds;

    final buttons = List.generate(choices.length, (index) {
      final choice = choices[index];
      final emotionId = effectiveEmotionIds[index % effectiveEmotionIds.length];
      final isSelected = selectedIndex == index;

      return ChoiceButton(
        text: choice,
        index: index,
        isSelected: isSelected,
        emotionId: emotionId,
        showBorder: showBorder,
        showNumber: showNumber,
        onTap: () => onChoiceSelected?.call(index, choice),
      );
    });

    if (layout == ChoiceLayout.horizontal) {
      // 가로 배치 (2개)
      return Row(
        children: [
          for (int i = 0; i < buttons.length; i++) ...[
            Expanded(child: buttons[i]),
            if (i < buttons.length - 1) const SizedBox(width: 12),
          ],
        ],
      );
    } else {
      // 세로 배치 (2-5개)
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < buttons.length; i++) ...[
            buttons[i],
            if (i < buttons.length - 1) const SizedBox(height: 12),
          ],
        ],
      );
    }
  }
}

