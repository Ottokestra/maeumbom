/// Response model for onboarding survey submission.
///
/// The backend may omit numeric fields like `profile_id` while the
/// implementation is in flux, so parsing is defensive to avoid
/// Null -> num cast crashes.
class OnboardingSurveySubmitResponse {
  const OnboardingSurveySubmitResponse({
    this.status,
    this.message,
    this.profileId,
    this.submittedAt,
    this.payload,
  });

  final String? status;
  final String? message;
  final int? profileId;
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

    return OnboardingSurveySubmitResponse(
      status: json['status'] as String?,
      message: json['message'] as String?,
      profileId: (json['profile_id'] as num?)?.toInt() ??
          (json['profileId'] as num?)?.toInt(),
      submittedAt: parsedSubmittedAt,
      payload: rawPayload is Map<String, dynamic>
          ? rawPayload
          : (rawPayload is Map ?
              rawPayload.cast<String, dynamic>()
              : null),
    );
  }

  /// Convenience helper when the backend responds with an empty body.
  static const empty = OnboardingSurveySubmitResponse();
}
