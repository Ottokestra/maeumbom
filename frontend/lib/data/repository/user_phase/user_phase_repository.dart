import '../../api/user_phase/user_phase_api_client.dart';
import '../../dtos/user_phase/user_pattern_setting_response.dart';
import '../../dtos/user_phase/user_pattern_setting_update.dart';
import '../../dtos/user_phase/user_phase_response.dart';

class UserPhaseRepository {
  UserPhaseRepository(this._apiClient);

  final UserPhaseApiClient _apiClient;

  Future<UserPhaseResponse> fetchCurrentPhase() {
    return _apiClient.getCurrentPhase();
  }

  Future<UserPatternSettingResponse> fetchSettings() {
    return _apiClient.getSettings();
  }

  Future<UserPatternSettingResponse> updateSettings(
    UserPatternSettingUpdate update,
  ) {
    return _apiClient.updateSettings(update);
  }
}
