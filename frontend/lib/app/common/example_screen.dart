import 'package:flutter/material.dart';
import '../../ui/app_ui.dart';

/// Example Screen - 기능 테스트용 화면
class ExampleScreen extends StatelessWidget {
  const ExampleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppFrame(
      topBar: TopBar(
        title: '테스트',
        leftIcon: Icons.arrow_back,
        rightIcon: Icons.more_horiz,
        onTapLeft: () => Navigator.pop(context),
        onTapRight: () {
          // TODO: 더보기 메뉴 표시
        },
      ),
      body: const ExampleContent(),
    );
  }
}

/// Example Content - 테스트 화면 본문
class ExampleContent extends StatelessWidget {
  const ExampleContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            text: '홈',
            variant: ButtonVariant.primaryRed,
            onTap: () {
              Navigator.pushNamed(context, '/');
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            text: '채팅',
            variant: ButtonVariant.secondaryRed,
            onTap: () {
              Navigator.pushNamed(context, '/chat');
            },
          ),
        ],
      ),
    );
  }
}
