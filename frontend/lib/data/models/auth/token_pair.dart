import 'package:freezed_annotation/freezed_annotation.dart';

part 'token_pair.freezed.dart';

@freezed
class TokenPair with _$TokenPair {
  const factory TokenPair({
    required String accessToken,
    required String refreshToken,
  }) = _TokenPair;
}
