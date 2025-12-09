import 'package:flutter_riverpod/flutter_riverpod.dart';

class SignUpState {
  // Terms
  final bool allAgreed;
  final bool isAgeVerified;
  final bool isServiceAgreed;
  final bool isPrivacyAgreed;

  // Basic Info
  final String nickname;
  final String? gender;
  final String? ageGroup;

  // Family
  final String? maritalStatus;
  final String? hasChildren;
  final String? livingWith;

  // Personality
  final String? personality;
  final String? activityPreference;

  // Hobbies
  final Set<String> stressReliefMethods;
  final Set<String> hobbies;
  final String otherHobbyInput;

  // Atmosphere
  final Set<String> atmospheres;

  SignUpState({
    this.allAgreed = false,
    this.isAgeVerified = false,
    this.isServiceAgreed = false,
    this.isPrivacyAgreed = false,
    this.nickname = '',
    this.gender,
    this.ageGroup,
    this.maritalStatus,
    this.hasChildren,
    this.livingWith,
    this.personality,
    this.activityPreference,
    this.stressReliefMethods = const {},
    this.hobbies = const {},
    this.otherHobbyInput = '',
    this.atmospheres = const {},
  });

  SignUpState copyWith({
    bool? allAgreed,
    bool? isAgeVerified,
    bool? isServiceAgreed,
    bool? isPrivacyAgreed,
    String? nickname,
    String? gender,
    String? ageGroup,
    String? maritalStatus,
    String? hasChildren,
    String? livingWith,
    String? personality,
    String? activityPreference,
    Set<String>? stressReliefMethods,
    Set<String>? hobbies,
    String? otherHobbyInput,
    Set<String>? atmospheres,
  }) {
    return SignUpState(
      allAgreed: allAgreed ?? this.allAgreed,
      isAgeVerified: isAgeVerified ?? this.isAgeVerified,
      isServiceAgreed: isServiceAgreed ?? this.isServiceAgreed,
      isPrivacyAgreed: isPrivacyAgreed ?? this.isPrivacyAgreed,
      nickname: nickname ?? this.nickname,
      gender: gender ?? this.gender,
      ageGroup: ageGroup ?? this.ageGroup,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      hasChildren: hasChildren ?? this.hasChildren,
      livingWith: livingWith ?? this.livingWith,
      personality: personality ?? this.personality,
      activityPreference: activityPreference ?? this.activityPreference,
      stressReliefMethods: stressReliefMethods ?? this.stressReliefMethods,
      hobbies: hobbies ?? this.hobbies,
      otherHobbyInput: otherHobbyInput ?? this.otherHobbyInput,
      atmospheres: atmospheres ?? this.atmospheres,
    );
  }
}

class SignUpNotifier extends StateNotifier<SignUpState> {
  SignUpNotifier() : super(SignUpState());

  void setAllTerms(bool value) {
    state = state.copyWith(
      allAgreed: value,
      isAgeVerified: value,
      isServiceAgreed: value,
      isPrivacyAgreed: value,
    );
  }

  void updateTerm({bool? age, bool? service, bool? privacy}) {
    final newAge = age ?? state.isAgeVerified;
    final newService = service ?? state.isServiceAgreed;
    final newPrivacy = privacy ?? state.isPrivacyAgreed;
    final all = newAge && newService && newPrivacy;
    
    state = state.copyWith(
      isAgeVerified: newAge,
      isServiceAgreed: newService,
      isPrivacyAgreed: newPrivacy,
      allAgreed: all,
    );
  }

  void setNickname(String value) => state = state.copyWith(nickname: value);
  void setGender(String value) => state = state.copyWith(gender: value);
  void setAgeGroup(String value) => state = state.copyWith(ageGroup: value);
  void setMaritalStatus(String value) => state = state.copyWith(maritalStatus: value);
  void setChildren(String value) => state = state.copyWith(hasChildren: value);
  void setLivingWith(String value) => state = state.copyWith(livingWith: value);
  void setPersonality(String value) => state = state.copyWith(personality: value);
  void setActivity(String value) => state = state.copyWith(activityPreference: value);
  
  void toggleStressRelief(String value) {
    final newSet = Set<String>.from(state.stressReliefMethods);
    if (newSet.contains(value)) newSet.remove(value);
    else newSet.add(value);
    state = state.copyWith(stressReliefMethods: newSet);
  }

  void toggleHobby(String value) {
    final newSet = Set<String>.from(state.hobbies);
    if (newSet.contains(value)) newSet.remove(value);
    else newSet.add(value);
    state = state.copyWith(hobbies: newSet);
  }

  void setOtherHobby(String value) {
    state = state.copyWith(otherHobbyInput: value);
  }
  
  void addOtherHobbyToSet(String value) {
      final newSet = Set<String>.from(state.hobbies);
      // Remove old other if exists
      newSet.removeWhere((e) => e.startsWith('기타:'));
      if (value.isNotEmpty) {
          newSet.add('기타: $value');
      }
      state = state.copyWith(hobbies: newSet);
  }

  void toggleAtmosphere(String value) {
    final newSet = Set<String>.from(state.atmospheres);
    if (newSet.contains(value)) newSet.remove(value);
    else newSet.add(value);
    state = state.copyWith(atmospheres: newSet);
  }
}

final signUpProvider = StateNotifierProvider.autoDispose<SignUpNotifier, SignUpState>((ref) {
  return SignUpNotifier();
});
