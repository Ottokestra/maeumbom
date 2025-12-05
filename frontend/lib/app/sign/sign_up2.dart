import 'package:flutter/material.dart';
import '../../ui/app_ui.dart';

/// 회원가입 화면 2단계
///
/// 닉네임, 성별, 연령대를 입력받는 화면입니다.
class SignUp2Screen extends StatefulWidget {
  final VoidCallback? onNext;
  
  const SignUp2Screen({super.key, this.onNext});

  @override
  State<SignUp2Screen> createState() => _SignUp2ScreenState();
}

class _SignUp2ScreenState extends State<SignUp2Screen> {
  final TextEditingController _nicknameController = TextEditingController();
  String? _selectedGender;
  String? _selectedAge;

  final List<String> _genderOptions = ['여자', '남자', '기타'];
  final List<String> _ageOptions = ['10대', '20대', '30대', '40대', '50대', '60대', '70대 이상'];

  bool get _canProceed {
    return _nicknameController.text.isNotEmpty &&
        _selectedGender != null &&
        _selectedAge != null;
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pureWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              // 타이틀
              Text(
                '안녕하세요\n저는 봄이예요 :)',
                style: AppTypography.h2.copyWith(
                  color: AppColors.textPrimary,
                  height: 1.3,
                ),
              ),

              const SizedBox(height: 60),

              // Q1. 닉네임
              Text(
                'Q1. 어떻게 불러드릴까요?',
                style: AppTypography.h3.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              TextField(
                controller: _nicknameController,
                onChanged: (_) => setState(() {}),
                style: AppTypography.body.copyWith(
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: '닉네임',
                  hintStyle: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  filled: true,
                  fillColor: AppColors.pureWhite,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppColors.borderLight,
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppColors.borderLight,
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppColors.accentRed,
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Q2. 성별
              Text(
                'Q2. 성별을 선택해주세요.',
                style: AppTypography.h3.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _genderOptions.map((gender) {
                  final isSelected = _selectedGender == gender;
                  return _buildOptionButton(
                    text: gender,
                    isSelected: isSelected,
                    onTap: () {
                      setState(() {
                        _selectedGender = gender;
                      });
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 40),

              // Q3. 연령대
              Text(
                'Q3. 연령대를 선택해주세요.',
                style: AppTypography.h3.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _ageOptions.map((age) {
                  final isSelected = _selectedAge == age;
                  return _buildOptionButton(
                    text: age,
                    isSelected: isSelected,
                    onTap: () {
                      setState(() {
                        _selectedAge = age;
                      });
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 60),

              // 다음 버튼
              AppButton(
                text: '다음',
                variant: ButtonVariant.primaryRed,
                onTap: _canProceed
                    ? () {
                        if (widget.onNext != null) {
                          widget.onNext!();
                        } else {
                          Navigator.pushNamed(context, '/sign_up3');
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

  Widget _buildOptionButton({
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentRed : AppColors.pureWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.borderLight,
            width: 1,
          ),
        ),
        child: Text(
          text,
          style: AppTypography.body.copyWith(
            color: isSelected ? AppColors.pureWhite : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
