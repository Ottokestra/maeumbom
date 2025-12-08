import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../config/dev_flags.dart';
import 'onboarding_survey_submit_request.dart';
import 'onboarding_survey_submit_response.dart';

/// Handles submission of onboarding survey answers to the backend.
class OnboardingSurveyRepository {
  OnboardingSurveyRepository({
    required String baseUrl,
    HttpClient? client,
  })  : _baseUrl = baseUrl,
        _client = client ?? HttpClient();

  final String _baseUrl;
  final HttpClient _client;

  /// Submits the onboarding survey answers to the backend.
  ///
  /// When [kOnboardingStubMode] is enabled, any failures are swallowed and a
  /// stub response is returned so the onboarding flow can proceed.
  Future<OnboardingSurveySubmitResponse> submit(
    OnboardingSurveySubmitRequest request,
  ) async {
    final uri = Uri.parse('$_baseUrl/api/onboarding-survey/submit');

    try {
      final httpRequest = await _client.postUrl(uri);
      httpRequest.headers.contentType = ContentType.json;
      httpRequest.add(utf8.encode(jsonEncode(request.toJson())));

      final httpResponse = await httpRequest.close();
      final body = await utf8.decoder.bind(httpResponse).join();

      if (httpResponse.statusCode >= 200 && httpResponse.statusCode < 300) {
        return body.isEmpty
            ? OnboardingSurveySubmitResponse.empty
            : OnboardingSurveySubmitResponse.fromJson(
                jsonDecode(body) as Map<String, dynamic>,
              );
      }

      if (kOnboardingStubMode) {
        debugPrint(
          'Onboarding submit failed (stub mode, ignoring): '
          '${httpResponse.statusCode} $body',
        );
        return OnboardingSurveySubmitResponse.fromJson(
          _dummyResponse(request),
        );
      }

      throw HttpException(
        '온보딩 설문 제출 실패: ${httpResponse.statusCode}',
        uri: uri,
      );
    } catch (e, st) {
      if (kOnboardingStubMode) {
        debugPrint('Onboarding submit error (stub mode, ignoring): $e');
        debugPrint('$st');
        return OnboardingSurveySubmitResponse.fromJson(
          _dummyResponse(request),
        );
      }

      rethrow;
    }
  }

  Map<String, dynamic> _dummyResponse(OnboardingSurveySubmitRequest request) {
    return {
      'status': 'stubbed-success',
      'message': 'Onboarding survey submission stubbed.',
      'profile_id': null,
      'submittedAt': DateTime.now().toUtc().toIso8601String(),
      'payload': request.toJson(),
    };
  }
}
