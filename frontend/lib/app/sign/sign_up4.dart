import 'package:flutter/material.dart';

/// 회원가입 화면 4단계
///
/// 성향 및 활동 선호도를 입력받는 화면입니다.
class SignUp4Screen extends StatefulWidget {
  final VoidCallback? onNext;
  
  const SignUp4Screen({super.key, this.onNext});

  @override
  State<SignUp4Screen> createState() => _SignUp4ScreenState();
}

class _SignUp4ScreenState extends State<SignUp4Screen> {
  String? _personality; // Q7: 내향적, 외향적, 상황에따라
  String? _activityPreference; // Q8: 조용한 활동, 활동적인게, 상황에 따라

  final List<String> _personalityOptions = ['내향적', '외향적', '상황에따라'];
  final List<String> _activityOptions = ['조용한 활동이 좋아요', '활동적인게 좋아요', '상황에 따라 달라요'];

  bool get _canProceed {
    return _personality != null && _activityPreference != null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),

              // Q7. 성향
              const Text(
                'Q7. 나는 어떤 성향에 더 가까워요?',
                style: TextStyle(
                  color: Color(0xFF243447),
                  fontSize: 24,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.24,
                ),
              ),

              const SizedBox(height: 16),

              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _personalityOptions.map((option) {
                  final isSelected = _personality == option;
                  return _buildOptionButton(
                    text: option,
                    isSelected: isSelected,
                    onTap: () {
                      setState(() {
                        _personality = option;
                      });
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 40),

              // Q8. 활동 선호도
              const Text(
                'Q8. 선호하는 활동을 골라주세요',
                style: TextStyle(
                  color: Color(0xFF243447),
                  fontSize: 24,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.24,
                ),
              ),

              const SizedBox(height: 16),

              Column(
                children: _activityOptions.map((option) {
                  final isSelected = _activityPreference == option;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildFullWidthOptionButton(
                      text: option,
                      isSelected: isSelected,
                      onTap: () {
                        setState(() {
                          _activityPreference = option;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 60),

              // 다음 버튼
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _canProceed
                      ? () {
                          if (widget.onNext != null) {
                            widget.onNext!();
                          } else {
                            Navigator.pushNamed(context, '/sign_up5');
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _canProceed
                        ? const Color(0xFFC03846)
                        : const Color(0xFFE0E0E0),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    '다음',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
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
          color: isSelected ? const Color(0xFFC03846) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFF0EAE8),
            width: 1,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? const Color(0xFFF0EAE8) : const Color(0xFF233446),
            fontSize: 16,
            fontFamily: 'Pretendard',
          ),
        ),
      ),
    );
  }

  Widget _buildFullWidthOptionButton({
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFC03846) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFF0EAE8),
            width: 1,
          ),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? const Color(0xFFF0EAE8) : const Color(0xFF233446),
            fontSize: 16,
            fontFamily: 'Pretendard',
          ),
        ),
      ),
    );
  }
}
