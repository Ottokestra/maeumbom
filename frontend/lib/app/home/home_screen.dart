import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ui/app_ui.dart';
import '../../core/services/navigation/navigation_service.dart';

/// Home Screen - 메인 홈 화면
///
/// 감정 교감 인터페이스의 중심 화면입니다.
/// - 주간 대표 감정 캐릭터 표시
/// - 음성 우선 인터랙션
/// - 화이트 스페이스 활용
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppFrame(
      topBar: TopBar(
        title: '',
        rightIcon: Icons.more_horiz,
        onTapRight: () => MoreMenuSheet.show(context),
      ),
      body: const HomeContent(),
    );
  }
}

/// Home Content - 홈 화면 본문
class HomeContent extends ConsumerStatefulWidget {
  const HomeContent({super.key});

  @override
  ConsumerState<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends ConsumerState<HomeContent> {
  // TODO: 실제로는 API에서 받아올 데이터
  final EmotionId _weeklyEmotion = EmotionId.test; // 임시 데이터
  bool _isRecording = false;

  void _handleVoiceInput() {
    setState(() {
      _isRecording = !_isRecording;
    });

    // TODO: 실제 음성 입력 처리
    if (_isRecording) {
      // 음성 녹음 시작
      debugPrint('음성 녹음 시작');
    } else {
      // 음성 녹음 중지
      debugPrint('음성 녹음 중지');
    }
  }

  void _handleTextInput() {
    // TODO: 텍스트 입력 화면으로 이동
    Navigator.pushNamed(context, '/chat');
  }

  @override
  Widget build(BuildContext context) {
    final emotionMeta = emotionMetaMap[_weeklyEmotion]!;

    return Container(
      color: AppColors.bgBasic,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 감정 캐릭터 타이틀
              Text(
                '나의 감정 캐릭터',
                style: AppTypography.h3.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),

              // 감정 캐릭터 (중앙, 큰 사이즈) + 원형 파동 효과
              CircularRipple(
                isActive: _isRecording,
                color: AppColors.accentRed,
                size: 350,
                child: EmotionCharacter(
                  id: _weeklyEmotion,
                  highRes: true,
                  size: 350,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // 인사 메시지
              Text(
                '오늘 하루 어떠셨나요?',
                style: AppTypography.h2.copyWith(
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),

              // 음성/텍스트 입력 버튼
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 마이크 버튼 (음성 입력)
                  GestureDetector(
                    onTap: _handleVoiceInput,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: _isRecording
                            ? AppColors.accentCoral
                            : AppColors.accentRed,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accentRedShadow,
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        _isRecording ? Icons.stop : Icons.mic,
                        color: AppColors.textWhite,
                        size: 32,
                      ),
                    ),
                  ),

                  const SizedBox(width: AppSpacing.md),

                  // 상태 텍스트
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      // border: Border.all(
                      //   color: AppColors.accentRed,
                      //   width: 2,
                      // ),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      _isRecording ? '녹음 중지' : '음성 입력하기',
                      style: AppTypography.bodyBold.copyWith(
                        color: AppColors.accentRed,
                      ),
                    ),
                  ),

                  const SizedBox(width: AppSpacing.md),

                  // 텍스트 입력 아이콘
                  GestureDetector(
                    onTap: _handleTextInput,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.bgLightPink,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit,
                        color: AppColors.accentRed,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),

              const Spacer(flex: 2),

              // 하단 힌트 텍스트
              Text(
                '마이크 버튼을 눌러 음성으로 대화해보세요',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
