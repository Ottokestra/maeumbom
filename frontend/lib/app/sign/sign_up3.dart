import 'package:flutter/material.dart';
import '../../ui/app_ui.dart';
import 'survey_data_holder.dart';

/// 회원가입 화면 3단계
///
/// 결혼 여부, 자녀 유무, 동거인 정보를 입력받는 화면입니다.
class SignUp3Screen extends StatefulWidget {
  final VoidCallback? onNext;
  
  const SignUp3Screen({super.key, this.onNext});

  @override
  State<SignUp3Screen> createState() => _SignUp3ScreenState();
}

class _SignUp3ScreenState extends State<SignUp3Screen> {
  String? _maritalStatus;
  String? _hasChildren;
  String? _livingWith;
  final _surveyData = SurveyDataHolder();

  final List<String> _maritalOptions = ['미혼', '기혼', '이혼/사별', '말하고 싶지 않음'];
  final List<String> _childrenOptions = ['있음', '없음'];
  final List<String> _livingOptions = ['혼자', '배우자와', '자녀와', '부모님과', '가족과 함께', '기타'];

  bool get _canProceed {
    return _maritalStatus != null &&
        _hasChildren != null &&
        _livingWith != null;
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

              // Q4. 결혼 여부
              Text(
                'Q4. 결혼 여부를 알려주세요.',
                style: AppTypography.h3.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _maritalOptions.map((status) {
                  final isSelected = _maritalStatus == status;
                  return _buildOptionButton(
                    text: status,
                    isSelected: isSelected,
                    onTap: () {
                      setState(() {
                        _maritalStatus = status;
                      });
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 40),

              // Q5. 자녀 유무
              Text(
                'Q5. 자녀가 있으신가요?',
                style: AppTypography.h3.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _childrenOptions.map((option) {
                  final isSelected = _hasChildren == option;
                  return _buildOptionButton(
                    text: option,
                    isSelected: isSelected,
                    onTap: () {
                      setState(() {
                        _hasChildren = option;
                      });
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 40),

              // Q6. 동거인
              Text(
                'Q6. 현재 누구와 함께 생활하고\n계신가요?',
                style: AppTypography.h3.copyWith(
                  color: AppColors.textPrimary,
                  height: 1.3,
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _livingOptions.map((option) {
                  final isSelected = _livingWith == option;
                  return _buildOptionButton(
                    text: option,
                    isSelected: isSelected,
                    onTap: () {
                      setState(() {
                        _livingWith = option;
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
                        // 데이터 저장
                        _surveyData.maritalStatus = _maritalStatus;
                        _surveyData.childrenYn = _hasChildren;
                        _surveyData.livingWith = _livingWith;
                        
                        if (widget.onNext != null) {
                          widget.onNext!();
                        } else {
                          Navigator.pushNamed(context, '/sign_up4');
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
