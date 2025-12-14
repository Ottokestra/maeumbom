import 'package:flutter/material.dart';
import '../characters/app_characters.dart';
import '../characters/app_character_colors.dart';
import '../tokens/app_tokens.dart';

/// 선택지 레이아웃 타입
enum ChoiceLayout {
  horizontal, // 가로 배치 (2개)
  vertical, // 세로 배치
}

/// 선택지 버튼 모드
enum ChoiceButtonMode {
  basic, // 기본: 흰 배경 + 테두리/체크 강조
  color, // 컬러: 감정 색상 배경 (연함 -> 진함)
  custom, // 커스텀: 배경색, 선택색, 번호색 직접 지정
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
///   mode: ChoiceButtonMode.basic, // or color
///   customColor: Color(0xFF4A9DFF), // 또는 커스텀 색상
///   showBorder: true,
///   showNumber: true,
///   imageUrl: "https://example.com/image.png", // 선택적 이미지
///   onTap: () {},
/// )
/// ```
class ChoiceButton extends StatefulWidget {
  /// 버튼에 표시될 텍스트
  final String text;

  /// 버튼의 순서 (0부터 시작)
  final int index;

  /// 선택 상태
  final bool isSelected;

  /// 감정 기반 색상 (null이면 기본 색상)
  final EmotionId? emotionId;

  /// 커스텀 색상 (emotionId보다 우선순위 높음)
  final Color? customColor;

  /// 버튼 모드 (basic/color)
  final ChoiceButtonMode mode;

  /// 클릭 콜백
  final VoidCallback? onTap;

  /// 테두리 표시 여부
  final bool showBorder;

  /// 번호 표시 여부
  final bool showNumber;

  /// 선택지 이미지 URL (선택적, 세로형에서만 표시)
  final String? imageUrl;

  /// [Custom 모드 전용] 배경색 (미선택 시)
  final Color? customBackgroundColor;

  /// [Custom 모드 전용] 선택 시 강조 색상 (테두리, 번호 배경, 체크)
  final Color? customChoiceColor;

  /// [Custom 모드 전용] 번호 텍스트 색상
  final Color? customNumberColor;

  const ChoiceButton({
    super.key,
    required this.text,
    required this.index,
    this.isSelected = false,
    this.emotionId,
    this.customColor,
    this.mode = ChoiceButtonMode.basic,
    this.onTap,
    this.showBorder = true,
    this.showNumber = true,
    this.imageUrl,
    this.customBackgroundColor,
    this.customChoiceColor,
    this.customNumberColor,
  });

  @override
  State<ChoiceButton> createState() => _ChoiceButtonState();
}

class _ChoiceButtonState extends State<ChoiceButton> {
  bool _isHovering = false;
  bool _isPressed = false;

  // 마크다운 텍스트를 RichText로 변환 (볼드 처리)
  Widget _buildText(String rawText) {
    final baseStyle = AppTypography.body.copyWith(
      color: AppColors.textPrimary,
    );

    final spans = <TextSpan>[];

    // **볼드** 패턴을 찾아서 TextSpan으로 분리
    final regex = RegExp(r'\*\*([^\*]+?)\*\*');
    int lastIndex = 0;

    // 볼드 마크다운이 없으면 일반 Text 반환
    if (!regex.hasMatch(rawText)) {
      return Text(rawText, style: baseStyle);
    }

    for (final match in regex.allMatches(rawText)) {
      // 볼드 이전의 일반 텍스트
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: rawText.substring(lastIndex, match.start),
          style: baseStyle,
        ));
      }

      // 볼드 텍스트
      spans.add(TextSpan(
        text: match.group(1),
        style: AppTypography.bodyBold.copyWith(
          color: AppColors.textPrimary,
        ),
      ));

      lastIndex = match.end;
    }

    // 남은 텍스트
    if (lastIndex < rawText.length) {
      spans.add(TextSpan(
        text: rawText.substring(lastIndex),
        style: baseStyle,
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 색상 결정 로직
    final EmotionColorPair colors;
    if (widget.customColor != null) {
      colors = EmotionColorPair(
        primary: widget.customColor!,
        secondary: widget.customColor!,
      );
    } else if (widget.emotionId != null) {
      colors = getEmotionColors(widget.emotionId!);
    } else {
      colors = EmotionColorPair(
        primary: AppColors.primaryColor,
        secondary: AppColors.primaryColor,
      );
    }

    // 모드별 배경색 설정
    Color backgroundColor;
    Color numberBackgroundColor; // 번호 배경색
    Color numberTextColor; // 번호 텍스트 색상
    Color accentColor; // 선택 시 강조 색상

    // 선택 상태이거나 호버/프레스 상태일 때 강조
    final isActive = widget.isSelected || _isHovering || _isPressed;

    if (widget.mode == ChoiceButtonMode.custom) {
      // Custom: 사용자 지정 색상 사용
      backgroundColor = widget.customBackgroundColor ?? AppColors.basicGray;
      accentColor = widget.customChoiceColor ?? AppColors.primaryColor;
      numberBackgroundColor = accentColor;
      numberTextColor = widget.customNumberColor ?? AppColors.pureWhite;

      // 선택 시 배경색 변경 (선택 색상의 연한 틴트)
      if (isActive) {
        backgroundColor = accentColor.withOpacity(0.1);
      }
    } else if (widget.mode == ChoiceButtonMode.basic) {
      // Basic: 기본 basicGray, 활성 시 아주 연한 틴트
      accentColor = colors.primary;
      numberBackgroundColor = colors.primary;
      numberTextColor = AppColors.pureWhite;
      backgroundColor =
          isActive ? colors.primary.withOpacity(0.08) : AppColors.basicGray;
    } else {
      // Color: 기본 연한색, 활성 시 진한색
      accentColor = colors.primary;
      numberBackgroundColor = colors.primary;
      numberTextColor = AppColors.pureWhite;
      backgroundColor = isActive
          ? colors.secondary.withOpacity(0.5) // 활성 시 진하게
          : colors.secondary.withOpacity(0.2); // 평소 연하게
    }

    // 테두리 색상 설정
    Color borderColor = Colors.transparent;
    if (widget.showBorder) {
      if (widget.mode == ChoiceButtonMode.custom) {
        borderColor = isActive ? accentColor : AppColors.borderLightGray;
      } else {
        borderColor = isActive
            ? colors.primary
            : (widget.mode == ChoiceButtonMode.basic
                ? AppColors.borderLightGray // Basic 미활성 시 회색 테두리
                : colors.primary.withOpacity(0.0)); // Color 미활성 시 테두리 없음
      }
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: backgroundColor,
            border: widget.showBorder
                ? Border.all(
                    width: 2,
                    color: borderColor,
                  )
                : null,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 이미지가 있으면 먼저 표시
              if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: Image.network(
                      widget.imageUrl!,
                      height: 120,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 120,
                          color: AppColors.basicGray,
                          alignment: Alignment.center,
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                              color: colors.primary,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (ctx, err, stack) {
                        return Container(
                          height: 120,
                          decoration: BoxDecoration(
                            color: AppColors.basicGray,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            size: 32,
                            color: AppColors.textSecondary,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              // 텍스트 영역
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center, // 세로 중앙 정렬
                children: [
                  // 선택적 번호 표시 & 체크 애니메이션
                  if (widget.showNumber) ...[
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: numberBackgroundColor, // 커스텀 색상 지원
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder:
                              (Widget child, Animation<double> animation) {
                            return ScaleTransition(
                                scale: animation, child: child);
                          },
                          child: isActive
                              ? Icon(
                                  Icons.check_rounded,
                                  key: ValueKey('check'),
                                  size: 20,
                                  color: numberTextColor, // 커스텀 색상 지원
                                )
                              : Text(
                                  '${widget.index + 1}',
                                  key: ValueKey('number'),
                                  style: AppTypography.bodyBold.copyWith(
                                    color: numberTextColor, // 커스텀 색상 지원
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  // 텍스트
                  Expanded(
                    child: _buildText(widget.text),
                  ),
                  // 번호가 없는 경우 우측에 체크 표시 (활성 시에만)
                  if (!widget.showNumber && isActive) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Icon(
                      Icons.check_circle_rounded,
                      color: widget.mode == ChoiceButtonMode.custom
                          ? accentColor
                          : colors.primary,
                      size: 24,
                    ),
                  ],
                ],
              ),
            ],
          ),
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
///   mode: ChoiceButtonMode.basic, // or color
///   emotionIds: [EmotionId.relief, EmotionId.joy],
///   customColors: [Color(0xFF4A9DFF), Color(0xFFFF6B9D)], // 또는 커스텀 색상
///   imageUrls: ['https://example.com/1.png', 'https://example.com/2.png'], // 선택적
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

  /// 버튼 모드 (basic/color)
  final ChoiceButtonMode mode;

  /// 각 선택지별 감정 ID (null이면 기본 패턴 사용)
  final List<EmotionId>? emotionIds;

  /// 각 선택지별 커스텀 색상 (emotionIds보다 우선순위 높음)
  final List<Color?>? customColors;

  /// 모든 선택지에 적용할 단일 커스텀 색상 (customColors보다 우선순위 높음)
  final Color? customColor;

  /// 각 선택지별 이미지 URL (선택적, 세로형에서만 표시)
  final List<String?>? imageUrls;

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
    this.mode = ChoiceButtonMode.basic,
    this.emotionIds,
    this.customColors,
    this.customColor,
    this.imageUrls,
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

      // 이미지 URL 가져오기
      final imageUrl = imageUrls != null && index < imageUrls!.length
          ? imageUrls![index]
          : null;

      // 커스텀 색상 가져오기 (우선순위: customColor > customColors[index])
      final effectiveCustomColor = customColor ??
          (customColors != null && index < customColors!.length
              ? customColors![index]
              : null);

      return ChoiceButton(
        text: choice,
        index: index,
        isSelected: isSelected,
        emotionId: emotionId,
        customColor: effectiveCustomColor,
        mode: mode,
        imageUrl: imageUrl,
        showBorder: showBorder,
        showNumber: showNumber,
        onTap: () => onChoiceSelected?.call(index, choice),
      );
    });

    if (layout == ChoiceLayout.horizontal) {
      // 가로 배치 (2개)
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start, // 텍스트 길이에 따라 높이 달라질 수 있음
        children: [
          for (int i = 0; i < buttons.length; i++) ...[
            Expanded(child: buttons[i]),
            if (i < buttons.length - 1) const SizedBox(width: AppSpacing.sm),
          ],
        ],
      );
    } else {
      // 세로 배치
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < buttons.length; i++) ...[
            buttons[i],
            if (i < buttons.length - 1) const SizedBox(height: AppSpacing.sm),
          ],
        ],
      );
    }
  }
}
