import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ui/app_ui.dart';

class MenopauseSurveyIntroScreen extends ConsumerWidget {
  const MenopauseSurveyIntroScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppFrame(
      topBar: TopBar(
        title: '',
        leftIcon: Icons.arrow_back,
        onTapLeft: () => Navigator.pop(context),
        rightIcon: Icons.close,
        onTapRight: () => Navigator.pop(context),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // 제목
              Text(
                '지금 내 몸 상태,\n가볍게 체크해볼까요?',
                style: AppTypography.h2.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 20),

              // 설명
              Text(
                '아래 문항에 예/아니오로만 응답해 주세요.\n'
                '결과는 진단이 아니라, 내 몸과 마음의 변화를 돌아보는 참고 정보로만 사용돼요.',
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),

              const Spacer(),

              // 시작하기 버튼
              AppButton(
                text: '시작하기',
                variant: ButtonVariant.primaryRed,
                onTap: () {
                  Navigator.pushNamed(context, '/menopause-survey');
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
