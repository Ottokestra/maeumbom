import 'package:freezed_annotation/freezed_annotation.dart';

part 'naver_login_request.freezed.dart';
part 'naver_login_request.g.dart';

@freezed
class NaverLoginRequest with _$NaverLoginRequest {
  const factory NaverLoginRequest({
    @JsonKey(name: 'auth_code') required String authCode,
    @JsonKey(name: 'redirect_uri') required String redirectUri,
    required String state,
  }) = _NaverLoginRequest;

  factory NaverLoginRequest.fromJson(Map<String, dynamic> json) =>
      _$NaverLoginRequestFromJson(json);
}
