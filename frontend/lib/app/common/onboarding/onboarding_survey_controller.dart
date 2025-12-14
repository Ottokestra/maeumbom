import 'package:flutter/foundation.dart';

import '../../../core/services/api_client.dart';
import '../../../data/dtos/onboarding/onboarding_survey_request.dart';
import '../../../data/dtos/onboarding/onboarding_survey_response.dart';
import '../../../data/dtos/onboarding/onboarding_survey_status_response.dart';
import '../../../data/repository/onboarding/onboarding_survey_repository.dart';

class OnboardingSurveyController with ChangeNotifier {
  OnboardingSurveyController(this._repository);

  final OnboardingSurveyRepository _repository;

  OnboardingSurveyResponse? _initialSurvey;
  String? _errorMessage;
  bool _isLoading = false;

  OnboardingSurveyResponse? get initialSurvey => _initialSurvey;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  Future<void> loadExistingSurvey() async {
    _setLoading(true);
    try {
      _initialSurvey = await _repository.getMySurvey();
      _errorMessage = null;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } finally {
      _setLoading(false);
    }
  }

  Future<OnboardingSurveyStatusResponse?> submitSurvey(
    OnboardingSurveyRequest request,
  ) async {
    _setLoading(true);
    try {
      await _repository.submitSurvey(request);
      final status = await _repository.getSurveyStatus();
      _errorMessage = null;
      return status;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return null;
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
