import 'package:flutter/material.dart';
import '../../ui/app_ui.dart';

/// Home Screen - 메인 홈 화면
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppFrame(
      // 상단 바와 하단 바를 포함한 기본 레이아웃
      topBar: TopBar(
        title: '',
        leftIcon: Icons.arrow_back,
        onTapLeft: () => Navigator.pop(context),
      ),
      bottomBar: BottomMenuBar(
        currentIndex: 0,
        onTap: (index) {
          // TODO: 탭 전환 로직
        },
      ),
      // body: 홈 화면의 본문 내용
      body: const HomeContent(),
    );
  }
}

/// Home Content
class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          Text(
            '오늘 하루 어떠셨나요?',
            style: AppTypography.h2,
          ),
          SizedBox(height: AppSpacing.lg),
          AppButton(
            text: 'Primary Red',
            variant: ButtonVariant.primaryRed,
          ),
          SizedBox(height: AppSpacing.sm),
          AppButton(
            text: 'Secondary Red',
            variant: ButtonVariant.secondaryRed,
          ),
          SizedBox(height: AppSpacing.lg),
          AppInput(
            caption: 'Input (Normal)',
            value: '텍스트를 입력해 주세요',
            state: InputState.normal,
          ),
          SizedBox(height: AppSpacing.sm),
          AppInput(
            caption: 'Input (Error)',
            value: '에러 상태 예시',
            state: InputState.error,
          ),
        ],
      ),
    );
  }
}
