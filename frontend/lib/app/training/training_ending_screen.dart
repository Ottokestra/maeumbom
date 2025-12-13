import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/training/relation_training.dart';
import '../../ui/app_ui.dart';
import '../../core/services/navigation/navigation_service.dart';
import '../../core/utils/text_formatter.dart';

class RelationTrainingEndingScreen extends ConsumerWidget {
  final ScenarioResult result;
  final VoidCallback? onConfirm;

  const RelationTrainingEndingScreen({
    super.key,
    required this.result,
    this.onConfirm,
  });

  Widget _buildTrainingText(String text, TextStyle baseStyle,
      {TextAlign textAlign = TextAlign.center}) {
    final formattedText = TextFormatter.formatTrainingText(text);
    final spans = <TextSpan>[];

    final regex = RegExp(r'\*\*([^\*]+?)\*\*');
    int lastIndex = 0;

    for (final match in regex.allMatches(formattedText)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: formattedText.substring(lastIndex, match.start),
          style: baseStyle,
        ));
      }

      spans.add(TextSpan(
        text: match.group(1),
        style: baseStyle.copyWith(fontWeight: FontWeight.w700),
      ));

      lastIndex = match.end;
    }

    if (lastIndex < formattedText.length) {
      spans.add(TextSpan(
        text: formattedText.substring(lastIndex),
        style: baseStyle,
      ));
    }

    return RichText(
      textAlign: textAlign,
      text: TextSpan(children: spans),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const highlightColor = AppColors.primaryColor;

    return AppFrame(
      backgroundColor: Colors.white,
      topBar: TopBar(
        title: '',
        backgroundColor: Colors.white,
      ),
      bottomBar: BottomButtonBar(
        primaryText: '돌아가기',
        onPrimaryTap: () => NavigationService(context, ref).navigateToRoute("/training/relation-training"),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm), 
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Visual Center (Result Image)
            if (result.resultImageUrl != null)
              Center(
                child: SizedBox(
                   height: 80, 
                   child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.lg), 
                    child: Image.network(
                      result.resultImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.image_not_supported_rounded,
                        size: 54,
                        color: AppColors.borderLightGray,
                      ),
                    ),
                  ),
                ),
              )
            else
              // Fallback visual if no image
              const Center(
                child: Icon(
                  Icons.check_circle_outline_rounded,
                  size: 80,
                  color: highlightColor,
                ),
              ),
              
            const SizedBox(height: AppSpacing.xs), 

            // 2. Result Card
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: highlightColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(AppRadius.xl), 
                    border: Border.all(
                      color: highlightColor.withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: highlightColor,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          result.title,
                          style: AppTypography.bodyBold.copyWith(
                            color: AppColors.textWhite,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md), 

                      // Result Text
                      _buildTrainingText(
                        result.resultText,
                        AppTypography.body.copyWith(
                          color: AppColors.textPrimary,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
