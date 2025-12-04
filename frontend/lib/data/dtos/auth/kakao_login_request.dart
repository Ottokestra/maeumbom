import 'package:freezed_annotation/freezed_annotation.dart';

part 'kakao_login_request.freezed.dart';
part 'kakao_login_request.g.dart';

@freezed
class KakaoLoginRequest with _$KakaoLoginRequest {
  const factory KakaoLoginRequest({
    @JsonKey(name: 'auth_code') required String authCode,
    @JsonKey(name: 'redirect_uri') required String redirectUri,
  }) = _KakaoLoginRequest;

  factory KakaoLoginRequest.fromJson(Map<String, dynamic> json) =>
      _$KakaoLoginRequestFromJson(json);
}
