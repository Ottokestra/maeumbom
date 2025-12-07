import 'package:flutter/material.dart';
import '../../ui/app_ui.dart';

/// 회원가입 화면 1단계
///
/// 약관 동의를 받는 화면입니다.
class SignUp1Screen extends StatefulWidget {
  final VoidCallback? onNext;
  
  const SignUp1Screen({super.key, this.onNext});

  @override
  State<SignUp1Screen> createState() => _SignUp1ScreenState();
}

class _SignUp1ScreenState extends State<SignUp1Screen> {
  // 약관 동의 상태
  bool _allAgreed = false;
  bool _isAgeVerified = false;
  bool _isServiceAgreed = false;
  bool _isPrivacyAgreed = false;

  /// 전체 동의 변경 시 호출
  void _updateAll(bool? value) {
    if (value == null) return;
    setState(() {
      _allAgreed = value;
      _isAgeVerified = value;
      _isServiceAgreed = value;
      _isPrivacyAgreed = value;
    });
  }

  /// 개별 항목 변경 시 호출 (전체 동의 상태 업데이트)
  void _updateItem() {
    setState(() {
      _allAgreed = _isAgeVerified && _isServiceAgreed && _isPrivacyAgreed;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pureWhite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              // 타이틀
              Text(
                '마음봄에\n오신 것을 환영합니다!',
                style: AppTypography.h2.copyWith(
                  color: AppColors.textPrimary,
                  height: 1.3,
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // 설명 텍스트
              Text(
                '서비스 이용을 위해 아래 내용에 동의해주세요.',
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 40),

              // 전체 동의
              _buildTermItem(
                title: '전체 동의합니다.',
                value: _allAgreed,
                onChanged: _updateAll,
                isBold: true,
              ),

              const SizedBox(height: AppSpacing.sm),
              const Divider(
                height: 1,
                color: AppColors.borderLight,
              ),
              const SizedBox(height: AppSpacing.sm),

              // 개별 약관
              _buildTermItem(
                title: '만 14세 이상입니다. (필수)',
                value: _isAgeVerified,
                onChanged: (v) {
                  _isAgeVerified = v ?? false;
                  _updateItem();
                },
              ),
              _buildTermItem(
                title: '서비스 이용약관(필수)',
                value: _isServiceAgreed,
                onChanged: (v) {
                  _isServiceAgreed = v ?? false;
                  _updateItem();
                },
              ),
              _buildTermItem(
                title: '개인정보 수집 및 이용 동의(필수)',
                value: _isPrivacyAgreed,
                onChanged: (v) {
                  _isPrivacyAgreed = v ?? false;
                  _updateItem();
                },
              ),

              const Spacer(),

              // 다음 버튼
              AppButton(
                text: '다음',
                variant: ButtonVariant.primaryRed,
                onTap: _allAgreed
                    ? () {
                        if (widget.onNext != null) {
                          widget.onNext!();
                        } else {
                          Navigator.pushNamed(context, '/sign_up2');
                        }
                      }
                    : null,
              ),

              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTermItem({
    required String title,
    required bool value,
    required ValueChanged<bool?> onChanged,
    bool isBold = false,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: value,
                onChanged: onChanged,
                activeColor: AppColors.natureGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                side: const BorderSide(
                  color: AppColors.borderLightGray,
                  width: 1.5,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                title,
                style: isBold
                    ? AppTypography.body.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      )
                    : AppTypography.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
