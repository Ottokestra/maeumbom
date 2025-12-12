import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ui/app_ui.dart';
import '../../core/services/navigation/navigation_service.dart';
import '../../data/api/user_phase/user_phase_api_client.dart';
import '../../data/dtos/onboarding/onboarding_survey_response.dart';
import '../../data/dtos/user_phase/user_phase_response.dart';
import '../../data/dtos/user_phase/user_pattern_response.dart';
import '../../data/dtos/user_phase/user_pattern_setting_update.dart';
import '../../data/dtos/user_phase/user_pattern_setting_response.dart';
import '../../data/dtos/user_phase/health_sync_request.dart';
import '../../providers/auth_provider.dart';
import '../../core/utils/logger.dart';
import '../../providers/onboarding_provider.dart';
import 'edit_profile_screen.dart';
import '../chat/chat_list_screen.dart';

class MypageScreen extends ConsumerStatefulWidget {
  const MypageScreen({super.key});

  @override
  ConsumerState<MypageScreen> createState() => _MypageScreenState();
}

class _MypageScreenState extends ConsumerState<MypageScreen> {
  bool _isLoadingProfile = true;
  bool _isLoadingPhase = false;
  bool _isLoadingPattern = false;
  OnboardingSurveyResponse? _profile;
  UserPhaseResponse? _currentPhase;
  UserPatternResponse? _pattern;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final onboardingRepository = ref.read(onboardingSurveyRepositoryProvider);
      final profile = await onboardingRepository.getMySurvey();

      if (!mounted) return;
      setState(() {
        _profile = profile;
        _isLoadingProfile = false;
      });
    } catch (e) {
      appLogger.e('Failed to load profile', error: e);
      if (!mounted) return;
      setState(() {
        _errorMessage = '프로필을 불러오는데 실패했습니다.';
        _isLoadingProfile = false;
      });
    }
  }

  Future<void> _loadCurrentPhase() async {
    if (!mounted) return;
    setState(() {
      _isLoadingPhase = true;
      _errorMessage = null;
    });

    try {
      final dio = ref.read(dioWithAuthProvider);
      final apiClient = UserPhaseApiClient(dio);
      final phase = await apiClient.getCurrentPhase();

      if (!mounted) return;
      setState(() {
        _currentPhase = phase;
        _isLoadingPhase = false;
      });
    } catch (e) {
      appLogger.e('Failed to load current phase', error: e);
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Phase 조회 실패: ${e.toString()}';
        _isLoadingPhase = false;
      });
    }
  }

  Future<void> _loadPattern() async {
    if (!mounted) return;
    setState(() {
      _isLoadingPattern = true;
      _errorMessage = null;
    });

    try {
      final dio = ref.read(dioWithAuthProvider);
      final apiClient = UserPhaseApiClient(dio);
      final pattern = await apiClient.getPattern();

      if (!mounted) return;
      setState(() {
        _pattern = pattern;
        _isLoadingPattern = false;
      });
    } catch (e) {
      appLogger.e('Failed to load pattern', error: e);
      if (!mounted) return;
      setState(() {
        _errorMessage = '패턴 조회 실패: ${e.toString()}';
        _isLoadingPattern = false;
      });
    }
  }

  Future<void> _syncHealthData() async {
    // 수동 데이터 입력 다이얼로그 표시
    final result = await _showHealthDataInputDialog();
    if (result == null) return; // 사용자가 취소한 경우

    if (!mounted) return;
    setState(() {
      _isLoadingPhase = true;
      _errorMessage = null;
    });

    try {
      final dio = ref.read(dioWithAuthProvider);
      final apiClient = UserPhaseApiClient(dio);

      // 사용자가 입력한 취침/기상 시간 추출
      final sleepStartTime = DateTime.parse(result.sleepStartTime!);
      final sleepEndTime = DateTime.parse(result.sleepEndTime!);
      final sleepStartHour = sleepStartTime.hour.toString().padLeft(2, '0');
      final sleepStartMinute = sleepStartTime.minute.toString().padLeft(2, '0');
      final sleepEndHour = sleepEndTime.hour.toString().padLeft(2, '0');
      final sleepEndMinute = sleepEndTime.minute.toString().padLeft(2, '0');
      
      final wakeTimeStr = '$sleepEndHour:$sleepEndMinute';
      final sleepTimeStr = '$sleepStartHour:$sleepStartMinute';
      
      // 오늘이 평일인지 주말인지 확인
      final today = DateTime.now();
      final isWeekend = today.weekday >= 6; // 토요일(6) 또는 일요일(7)
      
      // 먼저 사용자 설정이 있는지 확인
      UserPatternSettingResponse? currentSettings;
      try {
        currentSettings = await apiClient.getSettings();
      } catch (e) {
        // 설정이 없으면 사용자가 입력한 시간으로 설정 생성
        appLogger.i('User settings not found, creating settings from input data');
        try {
          await apiClient.updateSettings(
            UserPatternSettingUpdate(
              weekdayWakeTime: isWeekend ? '07:00' : wakeTimeStr,
              weekdaySleepTime: isWeekend ? '23:00' : sleepTimeStr,
              weekendWakeTime: isWeekend ? wakeTimeStr : '09:00',
              weekendSleepTime: isWeekend ? sleepTimeStr : '01:00',
              isNightWorker: false,
            ),
          );
          appLogger.i('Settings created from input data');
        } catch (createError) {
          appLogger.e('Failed to create settings', error: createError);
          if (!mounted) return;
          setState(() {
            _errorMessage = '사용자 설정 생성 실패: ${createError.toString()}';
            _isLoadingPhase = false;
          });
          return;
        }
      }
      
      // 설정이 있으면 사용자가 입력한 시간으로 업데이트
      if (currentSettings != null) {
        try {
          await apiClient.updateSettings(
            UserPatternSettingUpdate(
              weekdayWakeTime: isWeekend ? currentSettings.weekdayWakeTime : wakeTimeStr,
              weekdaySleepTime: isWeekend ? currentSettings.weekdaySleepTime : sleepTimeStr,
              weekendWakeTime: isWeekend ? wakeTimeStr : currentSettings.weekendWakeTime,
              weekendSleepTime: isWeekend ? sleepTimeStr : currentSettings.weekendSleepTime,
              isNightWorker: false,
            ),
          );
          appLogger.i('Settings updated with input data');
        } catch (updateError) {
          appLogger.e('Failed to update settings', error: updateError);
          // 설정 업데이트 실패해도 건강 데이터 동기화는 계속 진행
        }
      }

      final phase = await apiClient.syncHealthData(result);

      if (!mounted) return;
      setState(() {
        _currentPhase = phase;
        _isLoadingPhase = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('건강 데이터가 동기화되었습니다.')),
        );
      }
    } catch (e) {
      appLogger.e('Failed to sync health data', error: e);
      if (!mounted) return;
      setState(() {
        _errorMessage = '건강 데이터 동기화 실패: ${e.toString()}';
        _isLoadingPhase = false;
      });
    }
  }

  Future<HealthSyncRequest?> _showHealthDataInputDialog() async {
    final now = DateTime.now();
    final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    
    // 기본값: 8시간 전 취침, 지금 기상
    final defaultSleepStart = now.subtract(const Duration(hours: 8));
    final defaultSleepEnd = now;

    final sleepStartController = TextEditingController(
      text: '${defaultSleepStart.hour.toString().padLeft(2, '0')}:${defaultSleepStart.minute.toString().padLeft(2, '0')}',
    );
    final sleepEndController = TextEditingController(
      text: '${defaultSleepEnd.hour.toString().padLeft(2, '0')}:${defaultSleepEnd.minute.toString().padLeft(2, '0')}',
    );
    final stepCountController = TextEditingController(text: '8500');
    final sleepDurationController = TextEditingController(text: '7.5');
    final heartRateAvgController = TextEditingController(text: '72');
    final heartRateRestingController = TextEditingController(text: '65');

    return showDialog<HealthSyncRequest>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('건강 데이터 입력'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('날짜: $today', style: AppTypography.body),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: sleepStartController,
                decoration: const InputDecoration(
                  labelText: '취침 시간 (HH:MM)',
                  hintText: '23:00',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: sleepEndController,
                decoration: const InputDecoration(
                  labelText: '기상 시간 (HH:MM)',
                  hintText: '07:00',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: stepCountController,
                decoration: const InputDecoration(
                  labelText: '걸음 수',
                  hintText: '8500',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: sleepDurationController,
                decoration: const InputDecoration(
                  labelText: '수면 시간 (시간)',
                  hintText: '7.5',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: heartRateAvgController,
                decoration: const InputDecoration(
                  labelText: '평균 심박수',
                  hintText: '72',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: heartRateRestingController,
                decoration: const InputDecoration(
                  labelText: '안정 시 심박수',
                  hintText: '65',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              try {
                // 시간 파싱
                final sleepStartParts = sleepStartController.text.split(':');
                final sleepEndParts = sleepEndController.text.split(':');
                
                final sleepStartHour = int.parse(sleepStartParts[0]);
                final sleepStartMinute = int.parse(sleepStartParts[1]);
                final sleepEndHour = int.parse(sleepEndParts[0]);
                final sleepEndMinute = int.parse(sleepEndParts[1]);

                // 날짜 계산 (취침 시간이 자정을 넘기면 전날)
                DateTime sleepStart = DateTime(now.year, now.month, now.day, sleepStartHour, sleepStartMinute);
                if (sleepStartHour >= 12) {
                  // 오후 시간이면 전날로 간주
                  sleepStart = sleepStart.subtract(const Duration(days: 1));
                }
                
                DateTime sleepEnd = DateTime(now.year, now.month, now.day, sleepEndHour, sleepEndMinute);
                if (sleepEndHour < sleepStartHour) {
                  // 기상 시간이 취침 시간보다 작으면 다음날
                  sleepEnd = sleepEnd.add(const Duration(days: 1));
                }

                final request = HealthSyncRequest(
                  logDate: today,
                  sleepStartTime: sleepStart.toIso8601String() + 'Z',
                  sleepEndTime: sleepEnd.toIso8601String() + 'Z',
                  stepCount: stepCountController.text.isNotEmpty ? int.parse(stepCountController.text) : null,
                  sleepDurationHours: sleepDurationController.text.isNotEmpty ? double.parse(sleepDurationController.text) : null,
                  heartRateAvg: heartRateAvgController.text.isNotEmpty ? int.parse(heartRateAvgController.text) : null,
                  heartRateResting: heartRateRestingController.text.isNotEmpty ? int.parse(heartRateRestingController.text) : null,
                  sourceType: 'manual',
                );

                // 다이얼로그 닫기 (controller는 다이얼로그가 닫힌 후 자동으로 정리됨)
                Navigator.pop(context, request);
                
                // 다이얼로그가 닫힌 후에 controller dispose
                Future.microtask(() {
                  sleepStartController.dispose();
                  sleepEndController.dispose();
                  stepCountController.dispose();
                  sleepDurationController.dispose();
                  heartRateAvgController.dispose();
                  heartRateRestingController.dispose();
                });
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('입력 형식이 올바르지 않습니다: ${e.toString()}')),
                );
              }
            },
            child: const Text('동기화'),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EditProfileScreen()),
    );

    // 수정 화면에서 저장했으면 프로필 다시 로드
    if (result == true) {
      _loadProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    final navigationService = NavigationService(context, ref);

    return AppFrame(
      topBar: TopBar(
        title: '마이페이지',
        leftIcon: Icons.arrow_back,
        onTapLeft: () => navigationService.navigateToTab(0),
        rightIcon: Icons.more_horiz,
        onTapRight: () => MoreMenuSheet.show(context),
      ),
      bottomBar: BottomMenuBar(
        currentIndex: 4,
        onTap: (index) {
          navigationService.navigateToTab(index);
        },
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 섹션 1: 온보딩 설문 정보
            _buildProfileSection(),
            const SizedBox(height: AppSpacing.xl),

            // 섹션 2: 건강 연동 테스트
            _buildHealthSection(),
            const SizedBox(height: AppSpacing.xl),

            // 섹션 3: 대화 히스토리
            _buildChatHistorySection(),
            const SizedBox(height: AppSpacing.xl),

            // 섹션 4: 설정
            _buildSettingsSection(),
            const SizedBox(height: AppSpacing.xl),

            // 에러 메시지
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.bgLightPink,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Text(
                  _errorMessage!,
                  style: AppTypography.body.copyWith(color: AppColors.error),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('온보딩 설문', style: AppTypography.h2),
            if (_profile != null)
              AppButton(
                text: '수정하기',
                variant: ButtonVariant.secondaryRed,
                onTap: _navigateToEditProfile,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (_isLoadingProfile)
          const Center(child: CircularProgressIndicator())
        else if (_profile == null)
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.bgWarm,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Text(
              '설문 정보를 불러올 수 없습니다.',
              style: AppTypography.body,
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.bgWarm,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('닉네임', _profile!.nickname),
                _buildInfoRow('연령대', _profile!.ageGroup),
                _buildInfoRow('성별', _profile!.gender),
                _buildInfoRow('결혼 여부', _profile!.maritalStatus),
                _buildInfoRow('자녀 유무', _profile!.childrenYn),
                _buildInfoRow('동거인', _profile!.livingWith.join(', ')),
                _buildInfoRow('성향', _profile!.personalityType),
                _buildInfoRow('활동 스타일', _profile!.activityStyle),
                _buildInfoRow('스트레스 해소법', _profile!.stressRelief.join(', ')),
                _buildInfoRow('취미', _profile!.hobbies.join(', ')),
                if (_profile!.atmosphere.isNotEmpty)
                  _buildInfoRow('선호 분위기', _profile!.atmosphere.join(', ')),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: AppTypography.bodyBold,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.body,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('건강 연동 테스트', style: AppTypography.h2),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            AppButton(
              text: '건강 데이터 동기화',
              variant: ButtonVariant.primaryRed,
              onTap: _isLoadingPhase ? null : _syncHealthData,
            ),
            AppButton(
              text: '현재 Phase 조회',
              variant: ButtonVariant.secondaryRed,
              onTap: _isLoadingPhase ? null : _loadCurrentPhase,
            ),
            AppButton(
              text: '패턴 분석 결과',
              variant: ButtonVariant.secondaryRed,
              onTap: _isLoadingPattern ? null : _loadPattern,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Phase 결과 표시
        if (_isLoadingPhase)
          const Center(child: CircularProgressIndicator())
        else if (_currentPhase != null)
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.bgSoftMint,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('현재 Phase', style: AppTypography.h3),
                const SizedBox(height: AppSpacing.sm),
                _buildInfoRow('Phase', _currentPhase!.currentPhase),
                _buildInfoRow('기상 후 경과', '${_currentPhase!.hoursSinceWake.toStringAsFixed(1)}시간'),
                if (_currentPhase!.hoursToSleep != null)
                  _buildInfoRow('취침까지 남은 시간', '${_currentPhase!.hoursToSleep!.toStringAsFixed(1)}시간'),
                _buildInfoRow('데이터 출처', _currentPhase!.dataSource),
                _buildInfoRow('메시지', _currentPhase!.message),
                if (_currentPhase!.healthData != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text('건강 데이터', style: AppTypography.h3),
                  const SizedBox(height: AppSpacing.sm),
                  if (_currentPhase!.healthData!.sleepDurationHours != null)
                    _buildInfoRow('수면 시간', '${_currentPhase!.healthData!.sleepDurationHours}시간'),
                  if (_currentPhase!.healthData!.stepCount != null)
                    _buildInfoRow('걸음 수', '${_currentPhase!.healthData!.stepCount}걸음'),
                  if (_currentPhase!.healthData!.heartRateAvg != null)
                    _buildInfoRow('평균 심박수', '${_currentPhase!.healthData!.heartRateAvg}bpm'),
                ],
              ],
            ),
          ),

        // 패턴 분석 결과 표시
        if (_isLoadingPattern)
          const Center(child: CircularProgressIndicator())
        else if (_pattern != null)
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.bgSoftMint,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('패턴 분석 결과', style: AppTypography.h3),
                const SizedBox(height: AppSpacing.sm),
                Text('평일', style: AppTypography.bodyBold),
                _buildInfoRow('평균 기상 시간', _pattern!.weekday.avgWakeTime),
                _buildInfoRow('평균 취침 시간', _pattern!.weekday.avgSleepTime),
                if (_pattern!.weekend != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text('주말', style: AppTypography.bodyBold),
                  _buildInfoRow('평균 기상 시간', _pattern!.weekend!.avgWakeTime),
                  _buildInfoRow('평균 취침 시간', _pattern!.weekend!.avgSleepTime),
                ] else ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '주말 데이터가 부족하여 주말 패턴을 분석할 수 없습니다.',
                    style: AppTypography.body.copyWith(color: AppColors.textSecondary),
                  ),
                ],
                if (_pattern!.insight != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _pattern!.insight!,
                    style: AppTypography.body.copyWith(color: AppColors.primaryColor),
                  ),
                ],
                if (_pattern!.dataCompleteness != null)
                  _buildInfoRow('데이터 완성도', '${(_pattern!.dataCompleteness! * 100).toStringAsFixed(0)}%'),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildChatHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('대화 히스토리', style: AppTypography.h2),
            AppButton(
              text: '목록',
              variant: ButtonVariant.secondaryRed,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ChatListScreen()),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('설정', style: AppTypography.h2),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          text: '로그아웃',
          variant: ButtonVariant.secondaryRed,
          onTap: _handleLogout,
        ),
      ],
    );
  }

  Future<void> _handleLogout() async {
    // 확인 다이얼로그 표시
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('로그아웃', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // 로그아웃 실행
      await ref.read(authProvider.notifier).logout();

      if (!mounted) return;

      // 로그인 화면으로 이동
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false, // 모든 이전 라우트 제거
      );
    } catch (e) {
      appLogger.e('로그아웃 실패', error: e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그아웃 중 오류가 발생했습니다: ${e.toString()}')),
      );
    }
  }
} // End of class
