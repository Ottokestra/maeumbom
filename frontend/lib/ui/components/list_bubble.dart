import 'package:flutter/material.dart';
import '../tokens/app_tokens.dart';

/// 선택형 답변을 위한 리스트 버블 위젯
///
/// response_type이 'list'일 때 사용되며,
/// 각 항목을 클릭 가능한 아웃라인 스타일 버블로 표시합니다.
///
/// 사용 예시:
/// ```dart
/// ListBubble(
///   items: ['요가', '산책', '수영'],
///   selectedIndex: 0,
///   onItemSelected: (index, item) {
///     print('Selected: $item');
///   },
/// )
/// ```
class ListBubble extends StatelessWidget {
  /// 표시할 항목 리스트
  final List<String> items;

  /// 선택된 항목의 인덱스 (-1이면 선택 안 됨)
  final int selectedIndex;

  /// 항목 선택 콜백
  final void Function(int index, String item)? onItemSelected;

  /// 비활성화 여부 (선택 후 다른 항목 비활성화)
  final bool disabled;

  const ListBubble({
    super.key,
    required this.items,
    this.selectedIndex = -1,
    this.onItemSelected,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bubbleWidth = screenWidth - (AppSpacing.md * 2); // 좌우 여백 제외

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isSelected = index == selectedIndex;
          final isDisabled = disabled && !isSelected;

          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: GestureDetector(
              onTap:
                  isDisabled ? null : () => onItemSelected?.call(index, item),
              child: Container(
                width: bubbleWidth,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryColor.withOpacity(0.1)
                      : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primaryColor
                        : isDisabled
                            ? AppColors.borderLightGray
                            : AppColors.textSecondary,
                    width: isSelected ? 2.0 : 1.0,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    // 번호 표시
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryColor
                            : isDisabled
                                ? AppColors.borderLightGray
                                : AppColors.textSecondary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.basicColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    // 항목 텍스트
                    Expanded(
                      child: Text(
                        item,
                        style: AppTypography.body.copyWith(
                          color: isDisabled
                              ? AppColors.textSecondary.withOpacity(0.5)
                              : isSelected
                                  ? AppColors.primaryColor
                                  : AppColors.textPrimary,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    // 선택 아이콘
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: AppColors.primaryColor,
                        size: 20,
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// reply_text를 파싱하여 리스트 항목 추출
///
/// 예시 입력:
/// ```
/// 갱년기에 좋은 운동 추천해줄게!
///
/// 1. 요가 - 스트레칭과 명상을 통해 몸과 마음을 편안하게 해줘
/// 2. 산책 - 가벼운 유산산소 운동으로 기분 전환에 좋아
/// 3. 수영 - 관절에 무리 없이 전신 운동을 할 수 있어
/// ```
///
/// 반환:
/// ```
/// ['요가 - 스트레칭과 명상을 통해 몸과 마음을 편안하게 해줘', '산책 - ...', '수영 - ...']
/// ```
List<String> parseListItems(String replyText) {
  final lines = replyText.split('\n');
  final items = <String>[];

  for (final line in lines) {
    final trimmed = line.trim();
    // "1. ", "2. ", "3. " 등으로 시작하는 라인 찾기
    final match = RegExp(r'^\d+\.\s+(.+)$').firstMatch(trimmed);
    if (match != null) {
      items.add(match.group(1)!);
    }
  }

  return items;
}
