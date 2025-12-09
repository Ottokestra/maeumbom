import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import '../../ui/app_ui.dart';
import '../../ui/layout/app_frame.dart';
import '../../ui/layout/bottom_button_bars.dart';
import '../../data/api/onboarding/onboarding_survey_api_client.dart';
import '../../data/dtos/onboarding/onboarding_survey_request.dart';
import '../../core/utils/logger.dart';
import '../../providers/auth_provider.dart';
import '../../core/config/api_config.dart';
import 'package:frontend/providers/sign_up_provider.dart';
/// 통합 회원가입 화면 (비동기 상태 관리 + 슬라이드형 PageView)
class SignUp1Screen extends ConsumerStatefulWidget {
  const SignUp1Screen({super.key});

  @override
  ConsumerState<SignUp1Screen> createState() => _SignUp1ScreenState();
}

class _SignUp1ScreenState extends ConsumerState<SignUp1Screen> {
  final PageController _pageController = PageController();
  int _currentPage = 0; // 0 ~ 5 (Total 6 Steps)

  late TextEditingController _nicknameController;
  late TextEditingController _otherHobbyController;

  final List<String> _genderOptions = ['여성', '남성'];
  final List<String> _ageOptions = ['30대 이전','40대', '50대', '60대', '70대 이상'];
  final List<String> _maritalOptions = ['미혼', '기혼', '이혼/사별', '말하고 싶지 않음'];
  final List<String> _childrenOptions = ['있음', '없음'];
  final List<String> _livingOptions = ['혼자', '배우자와', '자녀와', '부모님과', '가족과 함께', '기타'];
  final List<String> _personalityOptions = ['내향적', '외향적', '상황에따라'];
  final List<String> _activityOptions = ['조용한 활동이 좋아요', '활동적인게 좋아요', '상황에 따라 달라요'];
  final List<String> _stressReliefOptions = [
    '혼자 조용히 해결해요', '취미 활동을 해요', '그냥 잊고 넘어가요', '바로 감정이 격해져요',
    '산책을 해요', '누군가와 대화를 나눠요', '운동을 해요', '기타'
  ];
  final List<String> _hobbyOptions = [
    '등산', '산책', '독서', '요리', '음악감상', '여행',
    '정리정돈', '공예/DIY', '반려동물', '영화/드라마', '정원/식물'
  ];
  final List<String> _atmosphereOptions = [
    '활발함', '따뜻하고 부드러운 느낌', '감성적인 스타일',
    '잔잔한 분위기', '차분함', '밝고 명랑한 분위기'
  ];

  // ... (inside build or helper)
  
  // Step 6: Atmosphere
  Widget _buildStep6() {
    final state = ref.watch(signUpProvider);
    final notifier = ref.read(signUpProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           _buildSectionTitle('Q11. 평소 선호하는 분위기나\n스타일이 있나요?'),
           // Use the same multi-select wrap as Q10
           _buildMultiSelectWrap(_atmosphereOptions, state.atmospheres, notifier.toggleAtmosphere),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    final state = ref.read(signUpProvider);
    _nicknameController = TextEditingController(text: state.nickname);
    _otherHobbyController = TextEditingController(text: state.otherHobbyInput);
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _otherHobbyController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // --- Navigation & Validation Logic ---

  void _onNext() {
    if (_currentPage < 5) {
      if (_validateStep(_currentPage)) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300), 
          curve: Curves.easeInOut
        );
      }
    } else {
      _submitSurvey();
    }
  }

  void _onPrev() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300), 
        curve: Curves.easeInOut
      );
    }
  }

  bool _validateStep(int step) {
    final state = ref.read(signUpProvider);
    switch (step) {
      case 0: // Terms
        if (!state.allAgreed) {
          _showError('약관에 모두 동의해주세요.');
          return false;
        }
        return true;
      case 1: // Info
        if (_nicknameController.text.isEmpty) {
          _showError('닉네임을 입력해주세요.');
          return false;
        }
        if (state.gender == null) {
          _showError('성별을 선택해주세요.');
          return false;
        }
        if (state.ageGroup == null) {
          _showError('연령대를 선택해주세요.');
          return false;
        }
        return true;
      case 2: // Family
        if (state.maritalStatus == null || state.hasChildren == null || state.livingWith == null) {
          _showError('모든 항목을 선택해주세요.');
          return false;
        }
        return true;
      case 3: // Personality
        if (state.personality == null || state.activityPreference == null) {
          _showError('모든 항목을 선택해주세요.');
          return false;
        }
        return true;
      case 4: // Hobbies
        if (state.stressReliefMethods.isEmpty || state.hobbies.isEmpty) {
          _showError('항목을 하나 이상 선택해주세요.');
          return false;
        }
        return true;
      case 5: // Atmosphere
        if (state.atmospheres.isEmpty) {
          _showError('선호하는 분위기를 선택해주세요.');
          return false;
        }
        return true;
    }
    return true;
  }

  Future<void> _submitSurvey() async {
    final state = ref.read(signUpProvider);
    final notifier = ref.read(signUpProvider.notifier);

    // Final Sync
    notifier.setNickname(_nicknameController.text);
    notifier.addOtherHobbyToSet(_otherHobbyController.text);

    if (!_validateStep(5)) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final authService = ref.read(authServiceProvider);
      final accessToken = await authService.getAccessToken();

      if (accessToken == null) throw Exception('로그인이 필요합니다.');

      final dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));
      final apiClient = OnboardingSurveyApiClient(dio);

      final request = OnboardingSurveyRequest(
        nickname: state.nickname,
        ageGroup: state.ageGroup!,
        gender: state.gender!,
        maritalStatus: state.maritalStatus!,
        childrenYn: state.hasChildren!,
        livingWith: [state.livingWith!],
        personalityType: state.personality!,
        activityStyle: state.activityPreference!,
        stressRelief: state.stressReliefMethods.toList(),
        hobbies: state.hobbies.map((e) => e.startsWith('기타:') ? e.substring(4).trim() : e).toList(),
        atmosphere: state.atmospheres.toList(),
      );

      await apiClient.submitSurvey(request, accessToken);

      if (mounted) Navigator.pop(context); // Close loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('회원가입 완료!'), backgroundColor: Colors.green),
        );
        Navigator.pushReplacementNamed(context, '/home'); 
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showError('오류 발생: $e');
      appLogger.e('Survey Submit Error', error: e);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 100, left: 20, right: 20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine button text based on page
    final isLastPage = _currentPage == 5;
    final buttonText = isLastPage ? '시작하기' : '다음';

    return WillPopScope(
      onWillPop: () async {
        if (_currentPage > 0) {
          _onPrev();
          return false;
        }
        return true; 
      },
      child: AppFrame(
        topBar: null,
        useSafeArea: true,
        bottomBar: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: const Color(0xFFF0EAE8))),
          ),
          child: Row(
            children: [
              // Previous Button
              Expanded(
                child: GestureDetector(
                  onTap: _onPrev,
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: _currentPage > 0 ? const Color(0xFFD7454D) : const Color(0xFFE0E0E0)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '이전',
                      style: TextStyle(
                        color: _currentPage > 0 ? const Color(0xFFD7454D) : const Color(0xFFB0B8C1),
                        fontSize: 16,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Next/Submit Button
              Expanded(
                child: GestureDetector(
                  onTap: _onNext,
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD7454D),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _currentPage == 5 ? '시작하기' : '다음',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(), // Only defined nav
          onPageChanged: (index) {
            setState(() {
              _currentPage = index;
            });
          },
          children: [
            _buildStep1(),
            _buildStep2(),
            _buildStep3(),
            _buildStep4(),
            _buildStep5(),
            _buildStep6(),
          ],
        ),
      ),
    );
  }

  // --- Step Builders ---

  // Step 1: Terms
  Widget _buildStep1() {
    final state = ref.watch(signUpProvider);
    final notifier = ref.read(signUpProvider.notifier);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '마음봄에\n오신 것을 환영합니다!',
            style: AppTypography.h2.copyWith(height: 1.3),
          ),
          const SizedBox(height: 16),
          Text('서비스 이용을 위해 아래 내용에 동의해주세요.', style: AppTypography.body.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 32),
          _buildTermItem(title: '전체 동의합니다.', value: state.allAgreed, onChanged: (v) => notifier.setAllTerms(v!), isBold: true),
          const Divider(height: 1, color: AppColors.borderLight),
          _buildTermItem(title: '만 14세 이상입니다. (필수)', value: state.isAgeVerified, onChanged: (v) => notifier.updateTerm(age: v)),
          _buildTermItem(title: '서비스 이용약관(필수)', value: state.isServiceAgreed, onChanged: (v) => notifier.updateTerm(service: v)),
          _buildTermItem(title: '개인정보 수집 및 이용 동의(필수)', value: state.isPrivacyAgreed, onChanged: (v) => notifier.updateTerm(privacy: v)),
        ],
      ),
    );
  }

  // Step 2: Info
  Widget _buildStep2() {
    final state = ref.watch(signUpProvider);
    final notifier = ref.read(signUpProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Q1. 어떻게 불러드릴까요?'),
          TextField(
            controller: _nicknameController,
            onChanged: notifier.setNickname,
            decoration: _inputDecoration('닉네임'),
          ),
          const SizedBox(height: 40),
          _buildSectionTitle('Q2. 성별을 선택해주세요.'),
          _buildWrapOptions(_genderOptions, state.gender, notifier.setGender),
          const SizedBox(height: 40),
          _buildSectionTitle('Q3. 연령대를 선택해주세요.'),
          _buildWrapOptions(_ageOptions, state.ageGroup, notifier.setAgeGroup),
        ],
      ),
    );
  }

  // Step 3: Family
  Widget _buildStep3() {
    final state = ref.watch(signUpProvider);
    final notifier = ref.read(signUpProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Q4. 결혼 여부를 알려주세요.'),
          _buildWrapOptions(_maritalOptions, state.maritalStatus, notifier.setMaritalStatus),
          const SizedBox(height: 40),
          _buildSectionTitle('Q5. 자녀가 있으신가요?'),
          _buildWrapOptions(_childrenOptions, state.hasChildren, notifier.setChildren),
          const SizedBox(height: 40),
          _buildSectionTitle('Q6. 현재 누구와 함께 생활하고 계신가요?'),
          _buildWrapOptions(_livingOptions, state.livingWith, notifier.setLivingWith),
        ],
      ),
    );
  }

  // Step 4: Personality
  Widget _buildStep4() {
    final state = ref.watch(signUpProvider);
    final notifier = ref.read(signUpProvider.notifier);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Q7. 나는 어떤 성향에 더 가까워요?'),
          _buildWrapOptions(_personalityOptions, state.personality, notifier.setPersonality),
          const SizedBox(height: 40),
          _buildSectionTitle('Q8. 선호하는 활동을 골라주세요'),
          Column(
            children: _activityOptions.map((opt) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildFullWidthOption(opt, state.activityPreference == opt, () => notifier.setActivity(opt)),
            )).toList(),
          ),
        ],
      ),
    );
  }

  // Step 5: Hobbies
  Widget _buildStep5() {
    final state = ref.watch(signUpProvider);
    final notifier = ref.read(signUpProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Q9. 나만의 스트레스 해소법은?'),
          _buildMultiSelectWrap(_stressReliefOptions, state.stressReliefMethods, notifier.toggleStressRelief),
          const SizedBox(height: 40),
          _buildSectionTitle('Q10. 좋아하는 취미를 선택해주세요'),
          _buildMultiSelectWrap(_hobbyOptions, state.hobbies, notifier.toggleHobby),
          const SizedBox(height: 12),
          TextField(
            controller: _otherHobbyController,
            decoration: _inputDecoration('기타(직접입력)'),
            onChanged: (val) {
                notifier.setOtherHobby(val);
                notifier.addOtherHobbyToSet(val);
            },
          ),
        ],
      ),
    );
  }




  // --- Helper Widgets ---

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
      ),
    );
  }

  Widget _buildTermItem({required String title, required bool value, required ValueChanged<bool?> onChanged, bool isBold = false}) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Checkbox(value: value, onChanged: onChanged, activeColor: AppColors.natureGreen),
            Text(title, style: AppTypography.body.copyWith(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  Widget _buildWrapOptions(List<String> options, String? selected, ValueChanged<String> onSelect) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: options.map((opt) => _buildOptionButton(
        text: opt,
        isSelected: selected == opt,
        onTap: () => onSelect(opt),
      )).toList(),
    );
  }

  Widget _buildMultiSelectWrap(List<String> options, Set<String> selectedSet, ValueChanged<String> onToggle) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final isSelected = selectedSet.contains(opt);
        return _buildOptionButton(
          text: opt,
          isSelected: isSelected,
          onTap: () => onToggle(opt),
        );
      }).toList(),
    );
  }

  Widget _buildOptionButton({required String text, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentRed : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Text(
          text,
          style: AppTypography.body.copyWith(color: isSelected ? Colors.white : AppColors.textPrimary),
        ),
      ),
    );
  }

  Widget _buildFullWidthOption(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentRed : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: AppTypography.body.copyWith(color: isSelected ? Colors.white : AppColors.textPrimary),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.borderLight)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.borderLight)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.accentRed)),
    );
  }


}


