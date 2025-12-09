import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ui/app_ui.dart';
import '../../ui/layout/app_frame.dart';
import '../../data/dtos/onboarding/onboarding_survey_request.dart';
import '../onboarding/onboarding_survey_controller.dart';
import '../../providers/onboarding_provider.dart';

/// 회원가입 슬라이드 화면
///
/// 기존의 1~6단계 화면을 하나의 파일에 통합(Merged)하여 PageView(슬라이드) 형태로 제공합니다.
class SignUpSlideScreen extends ConsumerStatefulWidget {
  const SignUpSlideScreen({super.key});

  @override
  ConsumerState<SignUpSlideScreen> createState() => _SignUpSlideScreenState();
}

class _SignUpSlideScreenState extends ConsumerState<SignUpSlideScreen> {
  late final OnboardingSurveyController _surveyController;
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalSteps = 6; // 약관, 정보, 가족, 성향, 취미, 분위기
  String? _errorMessage;

  // --- 통합된 State ---
  // 1. 약관
  bool _allAgreed = false;
  bool _isAgeVerified = false;
  bool _isServiceAgreed = false;
  bool _isPrivacyAgreed = false;

  // 2. 기본 정보
  final TextEditingController _nicknameController = TextEditingController();
  String? _selectedGender;
  String? _selectedAge;
  final List<String> _genderOptions = ['여성', '남성'];
  final List<String> _ageOptions = ['40대', '50대', '60대', '70대 이상'];

  // 3. 가족 정보
  String? _maritalStatus;
  String? _hasChildren;
  String? _livingWith;
  final List<String> _maritalOptions = ['미혼', '기혼', '이혼/사별', '말하고 싶지 않음'];
  final List<String> _childrenOptions = ['있음', '없음'];
  final List<String> _livingOptions = ['혼자', '배우자와', '자녀와', '부모님과', '가족과 함께', '기타'];

  // 4. 성향
  String? _personality;
  String? _activityPreference;
  final List<String> _personalityOptions = ['내향적', '외향적', '상황에따라'];
  final List<String> _activityOptions = ['조용한 활동이 좋아요', '활동적인게 좋아요', '상황에 따라 달라요'];

  // 5. 취미/스트레스
  final Set<String> _stressReliefMethods = {};
  final Set<String> _hobbies = {};
  final TextEditingController _otherHobbyController = TextEditingController();
  final List<String> _stressReliefOptions = [
    '혼자 조용히 해결해요', '취미 활동을 해요', '그냥 잊고 넘어가요', '바로 감정이 격해져요',
    '산책을 해요', '누군가와 대화를 나눠요', '운동을 해요', '기타'
  ];
  final List<String> _hobbyOptions = [
    '등산', '산책', '독서', '요리', '음악감상', '여행',
    '정리정돈', '공예/DIY', '반려동물', '영화/드라마', '정원/식물'
  ];

  // 6. 분위기 (Q11)
  String? _selectedAtmosphere;
  final List<Map<String, dynamic>> _atmosphereOptions = [
    {'label': '활발함', 'left': 0.0, 'top': 165.0, 'width': 78.0},
    {'label': '따뜻하고 부드러운 느낌', 'left': 141.0, 'top': 165.0, 'width': 196.0},
    {'label': '감성적인 스타일', 'left': 175.0, 'top': 68.0, 'width': 141.0},
    {'label': '잔잔한 분위기', 'left': 0.0, 'top': 70.0, 'width': 172.0},
    {'label': '차분함', 'left': 164.0, 'top': 115.0, 'width': 97.0},
    {'label': '밝고 명랑한 분위기', 'left': 0.0, 'top': 115.0, 'width': 161.0},
  ];

  @override
  void initState() {
    super.initState();
    _surveyController = ref.read(onboardingSurveyControllerProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExistingSurvey();
    });
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _otherHobbyController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingSurvey() async {
    await _surveyController.loadExistingSurvey();
    if (!mounted) return;

    final survey = _surveyController.initialSurvey;
    if (survey != null) {
      setState(() {
        _nicknameController.text = survey.nickname;
        _selectedGender = survey.gender;
        _selectedAge = survey.ageGroup;
        _maritalStatus = survey.maritalStatus;
        _hasChildren = survey.childrenYn;
        _livingWith = survey.livingWith.isNotEmpty ? survey.livingWith.first : null;
        _personality = survey.personalityType;
        _activityPreference = survey.activityStyle;
        _stressReliefMethods
          ..clear()
          ..addAll(survey.stressRelief);
        _hobbies
          ..clear()
          ..addAll(survey.hobbies.map((hobby) => hobby.trim()).where((hobby) => hobby.isNotEmpty));
        _selectedAtmosphere =
            survey.atmosphere.isNotEmpty ? survey.atmosphere.first : _selectedAtmosphere;
        _errorMessage = _surveyController.errorMessage;
      });
    } else {
      setState(() {
        _errorMessage = _surveyController.errorMessage;
      });
    }
  }

  // --- Logic Helpers ---
  void _showMessage(String msg) {
    setState(() {
      _errorMessage = msg;
    });
  }

  void _clearError() {
    if (_errorMessage != null) {
      setState(() {
        _errorMessage = null;
      });
    }
    _surveyController.clearError();
  }

  void _nextPage() {
    if (_currentPage < _totalSteps - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.ease);
    }
  }

  // --- Step Validation & Actions ---

  /// Step 1 Validation
  void _onNextStep1() {
    _clearError();
    if (!_allAgreed) {
      _showMessage('약관에 모두 동의해주세요.');
      return;
    }
    _nextPage();
  }

  /// Step 2 Validation
  void _onNextStep2() {
    _clearError();
    if (_nicknameController.text.isEmpty) {
      _showMessage('닉네임을 입력해주세요.');
      return;
    }
    if (_selectedGender == null) {
      _showMessage('성별을 선택해주세요.');
      return;
    }
    if (_selectedAge == null) {
      _showMessage('연령대를 선택해주세요.');
      return;
    }
    _nextPage();
  }

  /// Step 3 Validation
  void _onNextStep3() {
    _clearError();
    if (_maritalStatus == null || _hasChildren == null || _livingWith == null) {
      _showMessage('모든 항목을 선택해주세요.');
      return;
    }
    _nextPage();
  }

  /// Step 4 Validation
  void _onNextStep4() {
    _clearError();
    if (_personality == null || _activityPreference == null) {
      _showMessage('모든 항목을 선택해주세요.');
      return;
    }
    _nextPage();
  }

  /// Step 5 Validation
  void _onNextStep5() {
    _clearError();
    if (_stressReliefMethods.isEmpty || _hobbies.isEmpty) {
      _showMessage('항목을 하나 이상 선택해주세요.');
      return;
    }
    _nextPage();
  }

  /// Step 6 Submit
  Future<void> _onSubmit() async {
    _clearError();
    if (_selectedAtmosphere == null) {
      _showMessage('분위기를 선택해주세요.');
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final request = OnboardingSurveyRequest(
        nickname: _nicknameController.text,
        ageGroup: _selectedAge!,
        gender: _selectedGender!,
        maritalStatus: _maritalStatus!,
        childrenYn: _hasChildren!,
        livingWith: [_livingWith!],
        personalityType: _personality!,
        activityStyle: _activityPreference!,
        stressRelief: _stressReliefMethods.toList(),
        hobbies: _hobbies
            .map((e) => e.startsWith('기타:') ? e.substring(4).trim() : e)
            .toList(),
        atmosphere: [_selectedAtmosphere!],
      );

      final status = await _surveyController.submitSurvey(request);

      if (mounted) Navigator.pop(context);
      if (!mounted) return;

      if (status != null) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        _showMessage(
          _surveyController.errorMessage ?? '제출 중 문제가 발생했습니다. 잠시 후 다시 시도해주세요.',
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        _showMessage('오류: $e');
      }
    }
  }

  // --- Views ---

  // Page 1: Terms
  Widget _buildStep1() {
    return _buildPageLayout(
      title: '마음봄에\n오신 것을 환영합니다!',
      children: [
        Text('서비스 이용을 위해 아래 내용에 동의해주세요.', style: AppTypography.body.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 32),
        _buildTermItem(title: '전체 동의합니다.', value: _allAgreed, onChanged: (v) {
           setState(() {
             _allAgreed = v!;
             _isAgeVerified = v;
             _isServiceAgreed = v;
             _isPrivacyAgreed = v;
           });
        }, isBold: true),
        const Divider(),
        _buildTermItem(title: '만 14세 이상입니다. (필수)', value: _isAgeVerified, onChanged: (v) { setState(() => _isAgeVerified = v!); _checkAll(); }),
        _buildTermItem(title: '서비스 이용약관(필수)', value: _isServiceAgreed, onChanged: (v) { setState(() => _isServiceAgreed = v!); _checkAll(); }),
        _buildTermItem(title: '개인정보 수집 및 이용 동의(필수)', value: _isPrivacyAgreed, onChanged: (v) { setState(() => _isPrivacyAgreed = v!); _checkAll(); }),
      ],
      buttonText: '다음',
      onButtonTap: _onNextStep1,
    );
  }

  void _checkAll() {
    setState(() => _allAgreed = _isAgeVerified && _isServiceAgreed && _isPrivacyAgreed);
  }

  // Page 2: Info
  Widget _buildStep2() {
    return _buildPageLayout(
      title: '안녕하세요\n저는 봄이예요 :)',
      children: [
        _buildSectionTitle('Q1. 어떻게 불러드릴까요?'),
        TextField(
          controller: _nicknameController,
          decoration: _inputDecoration('닉네임'),
          onChanged: (_) => setState((){}),
        ),
        const SizedBox(height: 40),
        _buildSectionTitle('Q2. 성별을 선택해주세요.'),
        _buildWrapOptions(_genderOptions, _selectedGender, (v) => setState(() => _selectedGender = v)),
        const SizedBox(height: 40),
        _buildSectionTitle('Q3. 연령대를 선택해주세요.'),
        _buildWrapOptions(_ageOptions, _selectedAge, (v) => setState(() => _selectedAge = v)),
      ],
      buttonText: '다음',
      onButtonTap: _onNextStep2,
    );
  }

  // Page 3: Family
  Widget _buildStep3() {
    return _buildPageLayout(
      title: '가족 정보를\n알려주세요',
      children: [
        _buildSectionTitle('Q4. 결혼 여부를 알려주세요.'),
        _buildWrapOptions(_maritalOptions, _maritalStatus, (v) => setState(() => _maritalStatus = v)),
        const SizedBox(height: 40),
        _buildSectionTitle('Q5. 자녀가 있으신가요?'),
        _buildWrapOptions(_childrenOptions, _hasChildren, (v) => setState(() => _hasChildren = v)),
        const SizedBox(height: 40),
        _buildSectionTitle('Q6. 현재 누구와 함께 생활하고 계신가요?'),
        _buildWrapOptions(_livingOptions, _livingWith, (v) => setState(() => _livingWith = v)),
      ],
      buttonText: '다음',
      onButtonTap: _onNextStep3,
    );
  }

  // Page 4: Personality
  Widget _buildStep4() {
    return _buildPageLayout(
      title: '성향을\n알아보고 싶어요',
      children: [
        _buildSectionTitle('Q7. 나는 어떤 성향에 더 가까워요?'),
        _buildWrapOptions(_personalityOptions, _personality, (v) => setState(() => _personality = v)),
        const SizedBox(height: 40),
        _buildSectionTitle('Q8. 선호하는 활동을 골라주세요'),
        Column(children: _activityOptions.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildFullWidthOption(e, _activityPreference == e, () => setState(() => _activityPreference = e)),
        )).toList()),
      ],
      buttonText: '다음',
      onButtonTap: _onNextStep4,
    );
  }

  // Page 5: Hobbies
  Widget _buildStep5() {
    return _buildPageLayout(
      title: '취미와 스트레스\n해소법을 알려주세요',
      children: [
        _buildSectionTitle('Q9. 나만의 스트레스 해소법은?'),
        _buildMultiSelectWrap(_stressReliefOptions, _stressReliefMethods),
        const SizedBox(height: 40),
        _buildSectionTitle('Q10. 좋아하는 취미를 선택해주세요'),
        _buildMultiSelectWrap(_hobbyOptions, _hobbies),
        const SizedBox(height: 12),
        TextField(
          controller: _otherHobbyController,
          decoration: _inputDecoration('기타(직접입력)'),
          onChanged: (val) {
             setState(() {
               if (val.isNotEmpty) _hobbies.add('기타: $val');
               else _hobbies.removeWhere((h) => h.startsWith('기타:'));
             });
          },
        ),
      ],
      buttonText: '다음',
      onButtonTap: _onNextStep5,
    );
  }

  // Page 6: Atmosphere (Group3)
  Widget _buildStep6() {
    return _buildPageLayout(
      title: '', // Title is inside Group3 widget logic
      children: [
        // Group3 Content
        Container(
          width: 337,
          height: 209,
          // Use hardcoded values from design
          child: Stack(
            children: [
              const Positioned(
                left: 0, top: 0,
                child: Text('Q11. 평소 선호하는 분위기나 \n                  스타일이 있나요?', style: TextStyle(
                  color: Color(0xFF243447), fontSize: 24, fontWeight: FontWeight.w600, height: 1.2, fontFamily: 'Pretendard', letterSpacing: -0.24,
                )),
              ),
              ..._atmosphereOptions.map((opt) {
                final label = opt['label'] as String;
                final isSelected = _selectedAtmosphere == label;
                return Positioned(
                  left: opt['left'], top: opt['top'],
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedAtmosphere = label),
                    child: Container(
                      width: opt['width'], height: 44,
                      decoration: ShapeDecoration(
                        color: isSelected ? AppColors.accentRed : Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFFF0EAE8))),
                      ),
                      alignment: Alignment.center,
                      child: Text(label, style: TextStyle(color: isSelected ? Colors.white : const Color(0xFF233446), fontSize: 13)),
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ],
      buttonText: '시작하기',
      onButtonTap: _onSubmit,
    );
  }


  // --- Helper Widgets ---

  Widget _buildPageLayout({
    required String title,
    required List<Widget> children,
    required String buttonText,
    required VoidCallback onButtonTap,
  }) {
    final controller = ref.watch(onboardingSurveyControllerProvider);
    final resolvedError = _errorMessage ?? controller.errorMessage;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty) ...[
            Text(
              title,
              style: AppTypography.h2.copyWith(height: 1.3),
            ),
            const SizedBox(height: 40),
          ],

          // 위쪽 스크롤 영역
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ),

          const SizedBox(height: 24),

          if (resolvedError != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.accentCoral.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                resolvedError,
                style: AppTypography.body.copyWith(color: AppColors.accentRed),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // 하단 버튼 영역 (고정)
          AppButton(
            text: buttonText,
            variant: ButtonVariant.primaryRed,
            onTap: controller.isLoading ? null : onButtonTap,
          ),
          const SizedBox(height: 20),
        ],
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

  Widget _buildSectionTitle(String title) {
    return Padding(padding: const EdgeInsets.only(bottom: 16), child: Text(title, style: AppTypography.h3));
  }

  // ... (Reusing Option Widgets from before)
  Widget _buildWrapOptions(List<String> options, String? selected, ValueChanged<String> onSelect) {
    return Wrap(
      spacing: 12, runSpacing: 12,
      children: options.map((opt) => _buildOptionButton(text: opt, isSelected: selected == opt, onTap: () => onSelect(opt))).toList(),
    );
  }

  Widget _buildMultiSelectWrap(List<String> options, Set<String> selectedSet) {
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: options.map((opt) {
        final isSelected = selectedSet.contains(opt);
        return _buildOptionButton(text: opt, isSelected: isSelected, onTap: () => setState(() {
          if (isSelected) selectedSet.remove(opt); else selectedSet.add(opt);
        }));
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
        child: Text(text, style: AppTypography.body.copyWith(color: isSelected ? Colors.white : AppColors.textPrimary)),
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
        child: Text(text, textAlign: TextAlign.center, style: AppTypography.body.copyWith(color: isSelected ? Colors.white : AppColors.textPrimary)),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint, filled: true, fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.borderLight)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.borderLight)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.accentRed)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppFrame(
      topBar: null,
      useSafeArea: true,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // 버튼으로만 이동
        onPageChanged: (index) => setState(() => _currentPage = index),
        children: [
          _buildStep1(),
          _buildStep2(),
          _buildStep3(),
          _buildStep4(),
          _buildStep5(),
          _buildStep6(),
        ],
      ),
    );
  }
}
