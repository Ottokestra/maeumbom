import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import '../../ui/app_ui.dart';
import '../../ui/layout/app_frame.dart';
import '../../ui/layout/bottom_button_bars.dart';
import 'survey_data_holder.dart';
import '../../core/services/api_client.dart';
import '../../data/api/onboarding/onboarding_survey_api_client.dart';
import '../../data/dtos/onboarding/onboarding_survey_request.dart';
import '../../core/utils/logger.dart';
import '../../providers/auth_provider.dart';
import '../../core/config/api_config.dart';

/// 통합 회원가입 화면
///
/// 모든 설문 단계(약관 ~ Q11)를 하나의 스크롤 가능한 화면에 표시합니다.
class SignUp1Screen extends ConsumerStatefulWidget {
  const SignUp1Screen({super.key});

  @override
  ConsumerState<SignUp1Screen> createState() => _SignUp1ScreenState();
}

class _SignUp1ScreenState extends ConsumerState<SignUp1Screen> {
  final _surveyData = SurveyDataHolder();

  // --- 1. 약관 동의 State ---
  bool _allAgreed = false;
  bool _isAgeVerified = false;
  bool _isServiceAgreed = false;
  bool _isPrivacyAgreed = false;

  // --- 2. 기본 정보 State ---
  final TextEditingController _nicknameController = TextEditingController();
  String? _selectedGender;
  String? _selectedAge;
  final List<String> _genderOptions = ['여성', '남성'];
  final List<String> _ageOptions = ['40대', '50대', '60대', '70대 이상'];

  // --- 3. 가족 정보 State ---
  String? _maritalStatus;
  String? _hasChildren;
  String? _livingWith;
  final List<String> _maritalOptions = ['미혼', '기혼', '이혼/사별', '말하고 싶지 않음'];
  final List<String> _childrenOptions = ['있음', '없음'];
  final List<String> _livingOptions = ['혼자', '배우자와', '자녀와', '부모님과', '가족과 함께', '기타'];

  // --- 4. 성향 State ---
  String? _personality;
  String? _activityPreference;
  final List<String> _personalityOptions = ['내향적', '외향적', '상황에따라'];
  final List<String> _activityOptions = ['조용한 활동이 좋아요', '활동적인게 좋아요', '상황에 따라 달라요'];

  // --- 5. 취미/스트레스 State ---
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

  // --- 6. 분위기(Q11) State ---
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
  void dispose() {
    _nicknameController.dispose();
    _otherHobbyController.dispose();
    super.dispose();
  }

  // --- Logic Helpers ---

  void _updateAllTerms(bool? value) {
    if (value == null) return;
    setState(() {
      _allAgreed = value;
      _isAgeVerified = value;
      _isServiceAgreed = value;
      _isPrivacyAgreed = value;
    });
  }

  void _updateTermItem() {
    setState(() {
      _allAgreed = _isAgeVerified && _isServiceAgreed && _isPrivacyAgreed;
    });
  }

  bool get _isFormValid {
    // 1. 약관
    if (!_allAgreed) return false;
    // 2. 기본 정보
    if (_nicknameController.text.isEmpty || _selectedGender == null || _selectedAge == null) return false;
    // 3. 가족 정보
    if (_maritalStatus == null || _hasChildren == null || _livingWith == null) return false;
    // 4. 성향
    if (_personality == null || _activityPreference == null) return false;
    // 5. 취미
    if (_stressReliefMethods.isEmpty || _hobbies.isEmpty) return false;
    // 6. 분위기
    if (_selectedAtmosphere == null) return false;

    return true;
  }

  Future<void> _submitSurvey() async {
    // 1. 약관
    if (!_allAgreed) {
      _showError('약관에 모두 동의해주세요.');
      return;
    }
    // 2. 기본 정보
    if (_nicknameController.text.isEmpty) {
      _showError('닉네임을 입력해주세요.');
      return;
    }
    if (_selectedGender == null) {
      _showError('성별을 선택해주세요.');
      return;
    }
    if (_selectedAge == null) {
      _showError('연령대를 선택해주세요.');
      return;
    }
    // 3. 가족 정보
    if (_maritalStatus == null) {
      _showError('결혼 여부를 선택해주세요.');
      return;
    }
    if (_hasChildren == null) {
      _showError('자녀 유무를 선택해주세요.');
      return;
    }
    if (_livingWith == null) {
      _showError('동거인 정보를 선택해주세요.');
      return;
    }
    // 4. 성향
    if (_personality == null) {
      _showError('성향을 선택해주세요.');
      return;
    }
    if (_activityPreference == null) {
      _showError('활동 선호도를 선택해주세요.');
      return;
    }
    // 5. 취미
    if (_stressReliefMethods.isEmpty) {
      _showError('스트레스 해소법을 하나 이상 선택해주세요.');
      return;
    }
    if (_hobbies.isEmpty) {
      _showError('취미를 하나 이상 선택해주세요.');
      return;
    }
    // 6. 분위기
    if (_selectedAtmosphere == null) {
      _showError('선호하는 분위기를 선택해주세요.');
      return;
    }

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
      final apiClient = OnboardingSurveyApiClient(ApiClient(dio));

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
        hobbies: _hobbies.map((e) => e.startsWith('기타:') ? e.substring(4).trim() : e).toList(),
        atmosphere: [_selectedAtmosphere!],
      );

      await apiClient.submitSurvey(request, accessToken);

      if (mounted) Navigator.pop(context); // Close loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('회원가입 완료!'), backgroundColor: Colors.green),
        );
        Navigator.pushReplacementNamed(context, '/');
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류 발생: $e'), backgroundColor: Colors.red),
        );
      }
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
    return AppFrame(
      // TopBar 없음
      topBar: null,
      useSafeArea: true,
      // Bottom Menu Bar (여기서는 ButtonBar 사용)
      bottomBar: BottomButtonBar(
        primaryText: '시작하기', // 완료/시작
        style: BottomButtonBarStyle.block, // 꽉 찬 버튼 스타일 권장
        // 유효성 검사 여부와 상관없이 클릭 가능하게 하고, 클릭 시 상세 검증 수행
        onPrimaryTap: _submitSurvey,
        primaryButtonColor: AppColors.accentRed, // 항상 활성화된 색상
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Intro & Terms ---
            Text(
              '마음봄에\n오신 것을 환영합니다!',
              style: AppTypography.h2.copyWith(height: 1.3),
            ),
            const SizedBox(height: 16),
            Text('서비스 이용을 위해 아래 내용에 동의해주세요.', style: AppTypography.body.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 32),
            _buildTermItem(title: '전체 동의합니다.', value: _allAgreed, onChanged: _updateAllTerms, isBold: true),
            const Divider(height: 1, color: AppColors.borderLight),
            _buildTermItem(title: '만 14세 이상입니다. (필수)', value: _isAgeVerified, onChanged: (v) { _isAgeVerified = v!; _updateTermItem(); }),
            _buildTermItem(title: '서비스 이용약관(필수)', value: _isServiceAgreed, onChanged: (v) { _isServiceAgreed = v!; _updateTermItem(); }),
            _buildTermItem(title: '개인정보 수집 및 이용 동의(필수)', value: _isPrivacyAgreed, onChanged: (v) { _isPrivacyAgreed = v!; _updateTermItem(); }),

            const SizedBox(height: 60),

            // --- Q1: Nickname ---
            _buildSectionTitle('Q1. 어떻게 불러드릴까요?'),
            TextField(
              controller: _nicknameController,
              onChanged: (_) => setState(() {}),
              decoration: _inputDecoration('닉네임'),
            ),

            const SizedBox(height: 40),

            // --- Q2: Gender ---
            _buildSectionTitle('Q2. 성별을 선택해주세요.'),
            _buildWrapOptions(_genderOptions, _selectedGender, (val) => setState(() => _selectedGender = val)),

            const SizedBox(height: 40),

            // --- Q3: Age ---
            _buildSectionTitle('Q3. 연령대를 선택해주세요.'),
            _buildWrapOptions(_ageOptions, _selectedAge, (val) => setState(() => _selectedAge = val)),

            const SizedBox(height: 40),

            // --- Q4: Marital ---
            _buildSectionTitle('Q4. 결혼 여부를 알려주세요.'),
            _buildWrapOptions(_maritalOptions, _maritalStatus, (val) => setState(() => _maritalStatus = val)),

            const SizedBox(height: 40),

            // --- Q5: Children ---
            _buildSectionTitle('Q5. 자녀가 있으신가요?'),
            _buildWrapOptions(_childrenOptions, _hasChildren, (val) => setState(() => _hasChildren = val)),

            const SizedBox(height: 40),

            // --- Q6: Living With ---
            _buildSectionTitle('Q6. 현재 누구와 함께 생활하고 계신가요?'),
            _buildWrapOptions(_livingOptions, _livingWith, (val) => setState(() => _livingWith = val)),

            const SizedBox(height: 40),

            // --- Q7: Personality ---
            _buildSectionTitle('Q7. 나는 어떤 성향에 더 가까워요?'),
            _buildWrapOptions(_personalityOptions, _personality, (val) => setState(() => _personality = val)),

            const SizedBox(height: 40),

            // --- Q8: Activity ---
            _buildSectionTitle('Q8. 선호하는 활동을 골라주세요'),
            Column(
              children: _activityOptions.map((opt) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildFullWidthOption(opt, _activityPreference == opt, () => setState(() => _activityPreference = opt)),
              )).toList(),
            ),

            const SizedBox(height: 40),

            // --- Q9: Stress ---
            _buildSectionTitle('Q9. 나만의 스트레스 해소법은?'),
            _buildMultiSelectWrap(_stressReliefOptions, _stressReliefMethods),

            const SizedBox(height: 40),

            // --- Q10: Hobbies ---
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

            const SizedBox(height: 40),

            // --- Q11: Atmosphere (Group3) ---
            // user request: "sign_up6 으로 sign_up5 뒤에 이어서 나오게 해주고" -> merged here as Q11
            _buildGroup3Section(),

            const SizedBox(height: 60), // Space for bottom bar
          ],
        ),
      ),
    );
  }

  // --- Widget Builders ---

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

  Widget _buildMultiSelectWrap(List<String> options, Set<String> selectedSet) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final isSelected = selectedSet.contains(opt);
        return _buildChipButton(
          text: opt,
          isSelected: isSelected,
          onTap: () => setState(() {
            if (isSelected) selectedSet.remove(opt);
            else selectedSet.add(opt);
          }),
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

  Widget _buildChipButton({required String text, required bool isSelected, required VoidCallback onTap}) {
    // Similar to OptionButton but maybe smaller padding or different style if needed
    return _buildOptionButton(text: text, isSelected: isSelected, onTap: onTap);
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

  // --- Group3 (Q11) Implementation ---
  Widget _buildGroup3Section() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title from provided code: "Q11. 평소 선호하는 분위기나 스타일이 있나요?"
        // The provided code uses a Stack for layout. I will wrap selection logic around it.
        Container(
          width: 337,
          height: 209,
          // Use LayoutBuilder to scale if needed, but 337 is roughly mobile width.
          child: Stack(
            children: [
              // Title
              const Positioned(
                left: 0,
                top: 0,
                child: Text(
                  'Q11. 평소 선호하는 분위기나 \n                  스타일이 있나요?',
                  style: TextStyle(
                    color: Color(0xFF243447),
                    fontSize: 24,
                    fontFamily: 'Pretendard',
                    height: 1.2, // adjusted height for newlines
                    letterSpacing: -0.24,
                  ),
                ),
              ),
              // Options
              ..._atmosphereOptions.map((opt) {
                final label = opt['label'] as String;
                final isSelected = _selectedAtmosphere == label;
                return Positioned(
                  left: opt['left'],
                  top: opt['top'],
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedAtmosphere = label;
                      });
                    },
                    child: Container(
                      width: opt['width'],
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: ShapeDecoration(
                        color: isSelected ? AppColors.accentRed : Colors.white,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(width: 1, color: const Color(0xFFF0EAE8)),
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          label,
                          softWrap: false,
                          overflow: TextOverflow.visible, // Allow slight overflow if font differs
                          style: TextStyle(
                            color: isSelected ? Colors.white : const Color(0xFF233446),
                            fontSize: 14, // Slightly reduced to fit fixed widths if needed
                            fontFamily: 'Pretendard',
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ],
    );
  }
}
