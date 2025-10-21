

import '../../models/settings/settings_models.dart';
import '../base/base_api_service.dart';
import '../response/service_response.dart';

abstract class ISettingsService {
  Future<ServiceResponse<Settings>> getSettings();
  Future<ServiceResponse<Settings>> updateSettings(SettingsUpdateRequest request);
}

class SettingsService implements ISettingsService {
  @override
  Future<ServiceResponse<Settings>> getSettings() async {
    final response = await BaseApiService.get<Map<String, dynamic>>(
      '/settings',
      requiresAuth: true,
    );

    if (response.isSuccess && response.data != null) {
      final settings = Settings.fromJson(
        response.data!['settings'] as Map<String, dynamic>,
      );
      return ServiceResponse.success(
        statusCode: response.statusCode,
        data: settings,
        message: response.message,
      );
    }

    return ServiceResponse.error(
      statusCode: response.statusCode,
      message: response.message,
      errors: response.errors,
    );
  }

  @override
  Future<ServiceResponse<Settings>> updateSettings(
      SettingsUpdateRequest request,
      ) async {
    final response = await BaseApiService.put<Map<String, dynamic>>(
      '/settings',
      body: request.toJson(),
      requiresAuth: true,
    );

    if (response.isSuccess && response.data != null) {
      final settings = Settings.fromJson(
        response.data!['settings'] as Map<String, dynamic>,
      );
      return ServiceResponse.success(
        statusCode: response.statusCode,
        data: settings,
        message: response.message,
      );
    }

    return ServiceResponse.error(
      statusCode: response.statusCode,
      message: response.message,
      errors: response.errors,
    );
  }
}