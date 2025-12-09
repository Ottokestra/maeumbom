import 'package:freezed_annotation/freezed_annotation.dart';

part 'google_login_request.freezed.dart';
part 'google_login_request.g.dart';

@freezed
class GoogleLoginRequest with _$GoogleLoginRequest {
  const factory GoogleLoginRequest({
    @JsonKey(name: 'auth_code') String? authCode,
    @JsonKey(name: 'id_token') String? idToken,
    @JsonKey(name: 'redirect_uri') required String redirectUri,
  }) = _GoogleLoginRequest;

  factory GoogleLoginRequest.fromJson(Map<String, dynamic> json) =>
      _$GoogleLoginRequestFromJson(json);
}
