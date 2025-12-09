import 'package:flutter/material.dart';
import 'package:frontend/ui/app_ui.dart';
import 'package:frontend/data/models/chat/chat_message.dart';

/// Bubble Test Screen - 말풍선 컴포넌트 테스트 화면
class BubbleScreen extends StatelessWidget {
  const BubbleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppFrame(
      topBar: TopBar(
        title: 'Bubble 테스트',
        leftIcon: Icons.arrow_back,
        onTapLeft: () => Navigator.pop(context),
      ),
      body: const BubbleContent(),
    );
  }
}

/// Bubble Content - 말풍선 테스트 본문
class BubbleContent extends StatelessWidget {
  const BubbleContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgBasic,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ============================================================
            // Chat Bubble Section
            // ============================================================
            _buildSectionTitle('1. Chat Bubble (채팅 말풍선)'),
            const SizedBox(height: AppSpacing.sm),

            // 봄이 메시지
            ChatBubble(
              message: ChatMessage(
                id: '1',
                text: '안녕하세요! 오늘 기분은 어떠세요?',
                isUser: false,
                timestamp: DateTime.now(),
              ),
            ),

            // 사용자 메시지
            ChatBubble(
              message: ChatMessage(
                id: '2',
                text: '오늘은 정말 기분이 좋아요!',
                isUser: true,
                timestamp: DateTime.now(),
              ),
            ),

            // 긴 메시지 테스트
            ChatBubble(
              message: ChatMessage(
                id: '3',
                text: '오늘 회사에서 프로젝트 발표를 성공적으로 마쳤어요. 팀원들이 모두 칭찬해줘서 너무 뿌듯했습니다!',
                isUser: true,
                timestamp: DateTime.now(),
              ),
            ),

            ChatBubble(
              message: ChatMessage(
                id: '4',
                text:
                    '정말 축하드려요! 열심히 준비하신 노력이 빛을 발했네요. 앞으로도 좋은 일만 가득하시길 바랄게요 😊',
                isUser: false,
                timestamp: DateTime.now(),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // ============================================================
            // System Bubble Section
            // ============================================================
            _buildSectionTitle('2. System Bubble (시스템 말풍선)'),
            const SizedBox(height: AppSpacing.sm),

            // Info 타입
            const SystemBubble(
              text: '2025년 1월 15일',
              type: SystemBubbleType.info,
            ),
            const SizedBox(height: AppSpacing.sm),

            const SystemBubble(
              text: '금주의 감정: 기쁨 😊',
              type: SystemBubbleType.info,
            ),
            const SizedBox(height: AppSpacing.sm),

            // Success 타입
            const SystemBubble(
              text: '감정 기록이 저장되었습니다',
              type: SystemBubbleType.success,
            ),
            const SizedBox(height: AppSpacing.sm),

            // Warning 타입
            const SystemBubble(
              text: '네트워크 연결을 확인해주세요',
              type: SystemBubbleType.warning,
            ),

            const SizedBox(height: AppSpacing.xl),

            // ============================================================
            // Emotion Bubble Section
            // ============================================================
            _buildSectionTitle('3. Emotion Bubble (봄이 말풍선)'),
            const SizedBox(height: AppSpacing.sm),

            // 봄이 말풍선 예시들 (타이핑 애니메이션 + 스크롤 기능 테스트)
            EmotionBubble(
              message: '오늘 하루 어떠셨나요?',
              enableTypingAnimation: true,
              onTap: () => _showToast(context, '봄이 말풍선 1 (짧은 메시지 + 타이핑)'),
            ),
            const SizedBox(height: AppSpacing.sm),

            EmotionBubble(
              message: '그런 일이 있으셨군요. 조금 더 자세히 이야기해주실 수 있을까요?',
              enableTypingAnimation: true,
              typingSpeed: 30,
              onTap: () => _showToast(context, '봄이 말풍선 2 (2줄 메시지 + 빠른 타이핑)'),
            ),
            const SizedBox(height: AppSpacing.sm),

            EmotionBubble(
              message:
                  '힘든 하루를 보내셨네요. 하지만 이렇게 이야기해주셔서 감사해요. 천천히 함께 이야기 나눠봐요. 당신의 감정을 충분히 이해하고 있어요. 언제든 편하게 이야기해주세요.',
              enableTypingAnimation: true,
              onTap: () => _showToast(context, '봄이 말풍선 3 (긴 메시지 + 스크롤 + 타이핑)'),
            ),
            const SizedBox(height: AppSpacing.sm),

            const EmotionBubble(
              message: '당신의 이야기에 귀 기울이고 있어요.',
              enableTypingAnimation: true,
            ),
            const SizedBox(height: AppSpacing.sm),

            const EmotionBubble(
              message: '좋은 하루 보내세요!',
            ),

            const SizedBox(height: AppSpacing.xl),

            // ============================================================
            // Mixed Example Section
            // ============================================================
            _buildSectionTitle('4. 조합 예시 (실제 사용 시나리오)'),
            const SizedBox(height: AppSpacing.sm),

            const SystemBubble(
              text: '2025년 1월 15일 수요일',
              type: SystemBubbleType.info,
            ),

            ChatBubble(
              message: ChatMessage(
                id: '5',
                text: '안녕하세요! 오늘 하루는 어떠셨나요?',
                isUser: false,
                timestamp: DateTime.now(),
              ),
            ),

            ChatBubble(
              message: ChatMessage(
                id: '6',
                text: '오늘 너무 좋은 일이 있었어요!',
                isUser: true,
                timestamp: DateTime.now(),
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            ChatBubble(
              message: ChatMessage(
                id: '7',
                text: '좋은 일이 있으셨군요! 자세히 들려주시겠어요?',
                isUser: false,
                timestamp: DateTime.now(),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  /// 섹션 제목 위젯
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTypography.h3.copyWith(
        color: AppColors.textPrimary,
      ),
    );
  }

  /// 토스트 메시지 표시
  void _showToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
