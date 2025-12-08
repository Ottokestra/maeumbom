/// Response model for onboarding survey submission.
///
/// The backend may omit or null out numeric fields, so parsing is defensive to
/// avoid `Null -> num` cast crashes.
class OnboardingSurveySubmitResponse {
  const OnboardingSurveySubmitResponse({
    this.status,
    this.message,
    this.profile,
    this.submittedAt,
    this.payload,
  });

  final String? status;
  final String? message;
  final OnboardingProfileSnapshot? profile;
  final DateTime? submittedAt;
  final Map<String, dynamic>? payload;

  factory OnboardingSurveySubmitResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    final submittedAtRaw =
        json['submittedAt'] as String? ?? json['submitted_at'] as String?;
    final parsedSubmittedAt =
        submittedAtRaw != null ? DateTime.tryParse(submittedAtRaw) : null;

    final rawPayload = json['payload'];
    final rawProfile = json['profile'];

    return OnboardingSurveySubmitResponse(
      status: json['status'] as String?,
      message: json['message'] as String?,
      profile: rawProfile is Map<String, dynamic>
          ? OnboardingProfileSnapshot.fromJson(rawProfile)
          : rawProfile is Map
              ? OnboardingProfileSnapshot.fromJson(
                  rawProfile.cast<String, dynamic>(),
                )
              : null,
      submittedAt: parsedSubmittedAt,
      payload: rawPayload is Map<String, dynamic>
          ? rawPayload
          : (rawPayload is Map
              ? rawPayload.cast<String, dynamic>()
              : null),
    );
  }

  /// Convenience helper when the backend responds with an empty body.
  static const empty = OnboardingSurveySubmitResponse();
}

class OnboardingProfileSnapshot {
  const OnboardingProfileSnapshot({
    required this.profileId,
    required this.score,
    required this.level,
    required this.progress,
    this.stage,
  });

  final int profileId;
  final double score;
  final int level;
  final double progress;
  final String? stage;

  factory OnboardingProfileSnapshot.fromJson(Map<String, dynamic> json) {
    final profileId = _toInt(json['profile_id'] ?? json['profileId']);
    return OnboardingProfileSnapshot(
      profileId: profileId,
      score: _toDouble(json['score']),
      level: _toInt(json['level']),
      progress: _toDouble(json['progress']),
      stage: json['stage'] as String?,
    );
  }
}

double _toDouble(dynamic value, {double defaultValue = 0.0}) {
  if (value == null) return defaultValue;
  if (value is num) return value.toDouble();
  if (value is String) {
    final parsed = double.tryParse(value);
    return parsed ?? defaultValue;
  }
  return defaultValue;
}

int _toInt(dynamic value, {int defaultValue = 0}) {
  if (value == null) return defaultValue;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    final parsed = int.tryParse(value);
    return parsed ?? defaultValue;
  }
  return defaultValue;
}
