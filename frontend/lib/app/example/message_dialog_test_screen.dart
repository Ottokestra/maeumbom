import 'package:flutter/material.dart';
import '../../ui/app_ui.dart';

/// MessageDialog 테스트 화면
///
/// 다양한 MessageDialog 사용 예시를 보여줍니다.
class MessageDialogTestScreen extends StatelessWidget {
  const MessageDialogTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppFrame(
      topBar: TopBar(
        title: 'MessageDialog 테스트',
        leftIcon: Icons.arrow_back,
        onTapLeft: () => Navigator.pop(context),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Confirm 다이얼로그 섹션
            Text(
              'Confirm 다이얼로그 (2개 버튼)',
              style: AppTypography.h3,
            ),
            const SizedBox(height: AppSpacing.sm),

            // Red Confirm - 아이콘 있음
            ElevatedButton(
              onPressed: () => _showRedConfirmWithIcon(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentRed,
                foregroundColor: AppColors.textWhite,
              ),
              child: const Text('Red Confirm (아이콘 있음)'),
            ),
            const SizedBox(height: AppSpacing.xs),

            // Red Confirm - 아이콘 없음
            ElevatedButton(
              onPressed: () => _showRedConfirmWithoutIcon(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentRed,
                foregroundColor: AppColors.textWhite,
              ),
              child: const Text('Red Confirm (아이콘 없음)'),
            ),
            const SizedBox(height: AppSpacing.xs),

            // Green Confirm - 아이콘 있음
            ElevatedButton(
              onPressed: () => _showGreenConfirmWithIcon(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.natureGreen,
                foregroundColor: AppColors.textWhite,
              ),
              child: const Text('Green Confirm (아이콘 있음)'),
            ),
            const SizedBox(height: AppSpacing.xs),

            // Green Confirm - 아이콘 없음
            ElevatedButton(
              onPressed: () => _showGreenConfirmWithoutIcon(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.natureGreen,
                foregroundColor: AppColors.textWhite,
              ),
              child: const Text('Green Confirm (아이콘 없음)'),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Alert 다이얼로그 섹션
            Text(
              'Alert 다이얼로그 (1개 버튼)',
              style: AppTypography.h3,
            ),
            const SizedBox(height: AppSpacing.sm),

            // Red Alert - 아이콘 있음
            ElevatedButton(
              onPressed: () => _showRedAlertWithIcon(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentRed,
                foregroundColor: AppColors.textWhite,
              ),
              child: const Text('Red Alert (아이콘 있음)'),
            ),
            const SizedBox(height: AppSpacing.xs),

            // Red Alert - 아이콘 없음
            ElevatedButton(
              onPressed: () => _showRedAlertWithoutIcon(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentRed,
                foregroundColor: AppColors.textWhite,
              ),
              child: const Text('Red Alert (아이콘 없음)'),
            ),
            const SizedBox(height: AppSpacing.xs),

            // Green Alert - 아이콘 있음
            ElevatedButton(
              onPressed: () => _showGreenAlertWithIcon(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.natureGreen,
                foregroundColor: AppColors.textWhite,
              ),
              child: const Text('Green Alert (아이콘 있음)'),
            ),
            const SizedBox(height: AppSpacing.xs),

            // Green Alert - 아이콘 없음
            ElevatedButton(
              onPressed: () => _showGreenAlertWithoutIcon(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.natureGreen,
                foregroundColor: AppColors.textWhite,
              ),
              child: const Text('Green Alert (아이콘 없음)'),
            ),

            const SizedBox(height: AppSpacing.lg),

            // 설명
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.bgLightPink,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '사용 가이드',
                    style: AppTypography.bodyBold,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '【Confirm】 사용자 확인 필요\n'
                    '• 삭제 확인, 권한 요청, 저장 확인 등\n'
                    '• 2개 버튼 (메인 + 보조)\n\n'
                    '【Alert】 단순 알림\n'
                    '• 에러 메시지, 성공 알림, 완료 메시지 등\n'
                    '• 1개 버튼 (확인)\n\n'
                    '【색상】\n'
                    '• Red: 경고, 삭제, 중요 알림\n'
                    '• Green: 성공, 완료 알림',
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========================================
  // Confirm 다이얼로그 (2개 버튼)
  // ========================================

  void _showRedConfirmWithIcon(BuildContext context) {
    MessageDialogHelper.showRedConfirm(
      context,
      icon: Icons.sentiment_satisfied_rounded,
      title: '알 수도 있는 사람 찾기👀',
      message:
          '내가 아는 사람의 루틴이\n궁금하지 않나요? 연락처를\n동기화하면 마이루틴을 하고\n있는 지인을 찾을 수 있어요.',
      primaryButtonText: '좋아, 찾아줘!',
      secondaryButtonText: '나중에 할게',
      onPrimaryPressed: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('메인 버튼 클릭!')),
        );
      },
      onSecondaryPressed: () {
        Navigator.pop(context);
      },
    );
  }

  void _showRedConfirmWithoutIcon(BuildContext context) {
    MessageDialogHelper.showRedConfirm(
      context,
      title: '정말 삭제하시겠습니까?',
      message: '삭제된 데이터는 복구할 수 없습니다.',
      primaryButtonText: '삭제',
      secondaryButtonText: '취소',
      onPrimaryPressed: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('삭제되었습니다')),
        );
      },
      onSecondaryPressed: () {
        Navigator.pop(context);
      },
    );
  }

  void _showGreenConfirmWithIcon(BuildContext context) {
    MessageDialogHelper.showGreenConfirm(
      context,
      icon: Icons.check_circle_outline_rounded,
      title: '저장 완료!',
      message: '데이터가 성공적으로 저장되었습니다.\n이제 다른 기기에서도 확인할 수 있어요.',
      primaryButtonText: '확인',
      secondaryButtonText: '공유하기',
      onPrimaryPressed: () {
        Navigator.pop(context);
      },
      onSecondaryPressed: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('공유 기능 실행')),
        );
      },
    );
  }

  void _showGreenConfirmWithoutIcon(BuildContext context) {
    MessageDialogHelper.showGreenConfirm(
      context,
      title: '업로드 완료',
      message: '파일이 성공적으로 업로드되었습니다.',
      primaryButtonText: '확인',
      secondaryButtonText: '파일 보기',
      onPrimaryPressed: () {
        Navigator.pop(context);
      },
      onSecondaryPressed: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('파일 보기')),
        );
      },
    );
  }

  // ========================================
  // Alert 다이얼로그 (1개 버튼)
  // ========================================

  void _showRedAlertWithIcon(BuildContext context) {
    MessageDialogHelper.showRedAlert(
      context,
      icon: Icons.error_outline_rounded,
      title: '네트워크 오류',
      message: '인터넷 연결을 확인해주세요.',
      onPressed: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('확인 버튼 클릭!')),
        );
      },
    );
  }

  void _showRedAlertWithoutIcon(BuildContext context) {
    MessageDialogHelper.showRedAlert(
      context,
      title: '권한이 필요합니다',
      message: '이 기능을 사용하려면 카메라 권한이 필요합니다.',
    );
  }

  void _showGreenAlertWithIcon(BuildContext context) {
    MessageDialogHelper.showGreenAlert(
      context,
      icon: Icons.check_circle_outline_rounded,
      title: '저장 완료!',
      message: '변경사항이 성공적으로 저장되었습니다.',
      onPressed: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('확인 버튼 클릭!')),
        );
      },
    );
  }

  void _showGreenAlertWithoutIcon(BuildContext context) {
    MessageDialogHelper.showGreenAlert(
      context,
      title: '업로드 완료',
      message: '파일이 성공적으로 업로드되었습니다.',
    );
  }
}
