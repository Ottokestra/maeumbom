import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ui/app_ui.dart';
import '../../data/dtos/onboarding/onboarding_survey_request.dart';
import '../../core/utils/logger.dart';
import '../../providers/onboarding_provider.dart';

/// 설문 수정 화면
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isLoadingData = true;
  String? _errorMessage;

  // Form controllers
  final TextEditingController _nicknameController = TextEditingController();
  String? _selectedAgeGroup;
  String? _selectedGender;
  String? _maritalStatus;
  String? _childrenYn;
  final Set<String> _livingWith = {};
  String? _personalityType;
  String? _activityStyle;
  final Set<String> _stressRelief = {};
  final Set<String> _hobbies = {};
  final Set<String> _atmosphere = {};

  // Options
  final List<String> _ageOptions = ['40대', '50대', '60대', '70대 이상'];
  final List<String> _genderOptions = ['여성', '남성'];
  final List<String> _maritalOptions = ['미혼', '기혼', '이혼/사별', '말하고 싶지 않음'];
  final List<String> _childrenOptions = ['있음', '없음'];
  final List<String> _livingOptions = ['혼자', '배우자와', '자녀와', '부모님과', '가족과 함께', '기타'];
  final List<String> _personalityOptions = ['내향적', '외향적', '상황에따라'];
  final List<String> _activityOptions = ['조용한 활동이 좋아요', '활동적인게 좋아요', '상황에 따라 달라요'];
  final List<String> _stressReliefOptions = [
    '혼자 조용히 해결해요',
    '누군가와 대화를 나눠요',
    '산책을 해요',
    '운동을 해요',
    '취미 활동을 해요',
    '그냥 잊고 넘어가요',
    '바로 감정이 격해져요',
    '기타'
  ];
  final List<String> _hobbyOptions = [
    '등산',
    '산책',
    '음악감상',
    '독서',
    '영화/드라마',
    '요리',
    '정원/식물',
    '반려동물',
    '여행',
    '정리정돈',
    '공예/DIY',
    '기타'
  ];
  final List<String> _atmosphereOptions = [
    '잔잔한 분위기',
    '밝고 명랑한 분위기',
    '감성적인 스타일',
    '차분함',
    '활발함',
    '따뜻하고 부드러운 느낌'
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final onboardingRepository = ref.read(onboardingSurveyRepositoryProvider);
      final profile = await onboardingRepository.getMySurvey();

      setState(() {
        _nicknameController.text = profile.nickname;
        _selectedAgeGroup = profile.ageGroup;
        _selectedGender = profile.gender;
        _maritalStatus = profile.maritalStatus;
        _childrenYn = profile.childrenYn;
        _livingWith.addAll(profile.livingWith);
        _personalityType = profile.personalityType;
        _activityStyle = profile.activityStyle;
        _stressRelief.addAll(profile.stressRelief);
        _hobbies.addAll(profile.hobbies);
        _atmosphere.addAll(profile.atmosphere);
        _isLoadingData = false;
      });
    } catch (e) {
      appLogger.e('Failed to load profile', error: e);
      setState(() {
        _errorMessage = '프로필을 불러오는데 실패했습니다: ${e.toString()}';
        _isLoadingData = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final request = OnboardingSurveyRequest(
        nickname: _nicknameController.text.trim(),
        ageGroup: _selectedAgeGroup!,
        gender: _selectedGender!,
        maritalStatus: _maritalStatus!,
        childrenYn: _childrenYn!,
        livingWith: _livingWith.toList(),
        personalityType: _personalityType!,
        activityStyle: _activityStyle!,
        stressRelief: _stressRelief.toList(),
        hobbies: _hobbies.toList(),
        atmosphere: _atmosphere.toList(),
      );

      final onboardingRepository = ref.read(onboardingSurveyRepositoryProvider);
      await onboardingRepository.submitSurvey(request);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('프로필이 저장되었습니다.')),
        );
        Navigator.pop(context, true); // true를 반환하여 마이페이지에서 새로고침
      }
    } catch (e) {
      appLogger.e('Failed to save profile', error: e);
      setState(() {
        _errorMessage = '저장에 실패했습니다: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Widget _buildOptionButton({
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Text(
          text,
          style: AppTypography.body.copyWith(
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildMultiSelectWrap(List<String> options, Set<String> selectedSet) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final isSelected = selectedSet.contains(opt);
        return _buildOptionButton(
          text: opt,
          isSelected: isSelected,
          onTap: () => setState(() {
            if (isSelected) {
              selectedSet.remove(opt);
            } else {
              selectedSet.add(opt);
            }
          }),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppFrame(
      topBar: TopBar(
        title: '프로필 수정',
        leftIcon: Icons.arrow_back,
        onTapLeft: () => Navigator.pop(context),
      ),
      bottomBar: BottomButtonBar(
        primaryText: '저장',
        onPrimaryTap: _isLoading ? null : _saveProfile,
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _errorMessage!,
                          style: AppTypography.body.copyWith(
                            color: AppColors.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppButton(
                          text: '다시 시도',
                          variant: ButtonVariant.primaryRed,
                          onTap: _loadProfile,
                        ),
                      ],
                    ),
                  ),
                )
              : Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 닉네임
                        Text('닉네임', style: AppTypography.h3),
                        const SizedBox(height: AppSpacing.sm),
                        TextFormField(
                          controller: _nicknameController,
                          decoration: InputDecoration(
                            hintText: '닉네임을 입력하세요',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppColors.borderLight),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppColors.borderLight),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppColors.primaryColor),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return '닉네임을 입력해주세요';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // 연령대
                        Text('연령대', style: AppTypography.h3),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _ageOptions.map((age) {
                            return _buildOptionButton(
                              text: age,
                              isSelected: _selectedAgeGroup == age,
                              onTap: () => setState(() => _selectedAgeGroup = age),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // 성별
                        Text('성별', style: AppTypography.h3),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _genderOptions.map((gender) {
                            return _buildOptionButton(
                              text: gender,
                              isSelected: _selectedGender == gender,
                              onTap: () => setState(() => _selectedGender = gender),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // 결혼 여부
                        Text('결혼 여부', style: AppTypography.h3),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _maritalOptions.map((status) {
                            return _buildOptionButton(
                              text: status,
                              isSelected: _maritalStatus == status,
                              onTap: () => setState(() => _maritalStatus = status),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // 자녀 유무
                        Text('자녀 유무', style: AppTypography.h3),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _childrenOptions.map((option) {
                            return _buildOptionButton(
                              text: option,
                              isSelected: _childrenYn == option,
                              onTap: () => setState(() => _childrenYn = option),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // 동거인 (다중 선택)
                        Text('동거인 (복수 선택 가능)', style: AppTypography.h3),
                        const SizedBox(height: AppSpacing.sm),
                        _buildMultiSelectWrap(_livingOptions, _livingWith),
                        const SizedBox(height: AppSpacing.lg),

                        // 성향
                        Text('성향', style: AppTypography.h3),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _personalityOptions.map((personality) {
                            return _buildOptionButton(
                              text: personality,
                              isSelected: _personalityType == personality,
                              onTap: () => setState(() => _personalityType = personality),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // 활동 스타일
                        Text('활동 스타일', style: AppTypography.h3),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _activityOptions.map((activity) {
                            return _buildOptionButton(
                              text: activity,
                              isSelected: _activityStyle == activity,
                              onTap: () => setState(() => _activityStyle = activity),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // 스트레스 해소법 (다중 선택)
                        Text('스트레스 해소법 (복수 선택 가능)', style: AppTypography.h3),
                        const SizedBox(height: AppSpacing.sm),
                        _buildMultiSelectWrap(_stressReliefOptions, _stressRelief),
                        const SizedBox(height: AppSpacing.lg),

                        // 취미 (다중 선택)
                        Text('취미 (복수 선택 가능)', style: AppTypography.h3),
                        const SizedBox(height: AppSpacing.sm),
                        _buildMultiSelectWrap(_hobbyOptions, _hobbies),
                        const SizedBox(height: AppSpacing.lg),

                        // 선호 분위기 (다중 선택)
                        Text('선호 분위기 (복수 선택 가능)', style: AppTypography.h3),
                        const SizedBox(height: AppSpacing.sm),
                        _buildMultiSelectWrap(_atmosphereOptions, _atmosphere),
                        const SizedBox(height: AppSpacing.lg),

                        if (_errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.md),
                            child: Text(
                              _errorMessage!,
                              style: AppTypography.body.copyWith(color: AppColors.error),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
    );
  }
}

