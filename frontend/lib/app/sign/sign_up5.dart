import 'package:flutter/material.dart';

/// 회원가입 화면 5단계
///
/// 스트레스 해소법과 취미를 입력받는 화면입니다.
class SignUp5Screen extends StatefulWidget {
  final VoidCallback? onNext;
  
  const SignUp5Screen({super.key, this.onNext});

  @override
  State<SignUp5Screen> createState() => _SignUp5ScreenState();
}

class _SignUp5ScreenState extends State<SignUp5Screen> {
  // Q9: 스트레스 해소법 (다중 선택 가능)
  final Set<String> _stressReliefMethods = {};
  
  // Q10: 취미 (다중 선택 가능)
  final Set<String> _hobbies = {};
  
  final TextEditingController _otherHobbyController = TextEditingController();

  final List<String> _stressReliefOptions = [
    '혼자 조용히 해결해요',
    '취미 활동을 해요',
    '그냥 잊고 넘어가요',
    '바로 감정이 격해져요',
    '산책을 해요',
    '누군가와 대화를 나눠요',
    '운동을 해요',
    '기타',
  ];

  final List<String> _hobbyOptions = [
    '등산',
    '산책',
    '독서',
    '요리',
    '음악감상',
    '여행',
    '정리정돈',
    '공예/DIY',
    '반려동물',
    '영화/드라마',
    '정원/식물',
  ];

  bool get _canProceed {
    return _stressReliefMethods.isNotEmpty && _hobbies.isNotEmpty;
  }

  @override
  void dispose() {
    _otherHobbyController.dispose();
    super.dispose();
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
              const SizedBox(height: 20),

              // Q9. 스트레스 해소법
              const Text(
                'Q9. 나만의 스트레스 해소법은?',
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
                spacing: 8,
                runSpacing: 8,
                children: _stressReliefOptions.map((option) {
                  final isSelected = _stressReliefMethods.contains(option);
                  return _buildChipButton(
                    text: option,
                    isSelected: isSelected,
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _stressReliefMethods.remove(option);
                        } else {
                          _stressReliefMethods.add(option);
                        }
                      });
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 40),

              // Q10. 취미
              const Text(
                'Q10. 좋아하는 취미를 선택해주세요',
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
                spacing: 8,
                runSpacing: 8,
                children: _hobbyOptions.map((option) {
                  final isSelected = _hobbies.contains(option);
                  return _buildChipButton(
                    text: option,
                    isSelected: isSelected,
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _hobbies.remove(option);
                        } else {
                          _hobbies.add(option);
                        }
                      });
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 12),

              // 기타(직접입력)
              GestureDetector(
                onTap: () {
                  // 기타 입력 필드로 포커스 이동
                  FocusScope.of(context).requestFocus(FocusNode());
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFF0EAE8),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: _otherHobbyController,
                    onChanged: (value) {
                      setState(() {
                        if (value.isNotEmpty) {
                          _hobbies.add('기타: $value');
                        } else {
                          _hobbies.removeWhere((h) => h.startsWith('기타:'));
                        }
                      });
                    },
                    style: const TextStyle(
                      color: Color(0xFF233446),
                      fontSize: 16,
                      fontFamily: 'Pretendard',
                    ),
                    decoration: const InputDecoration(
                      hintText: '기타(직접입력)',
                      hintStyle: TextStyle(
                        color: Color(0xFF233446),
                        fontSize: 16,
                        fontFamily: 'Pretendard',
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 60),

              // 완료 버튼
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _canProceed
                      ? () {
                          if (widget.onNext != null) {
                            widget.onNext!();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('회원가입이 완료되었습니다!'),
                              ),
                            );
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
                    '완료',
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

  Widget _buildChipButton({
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
}
