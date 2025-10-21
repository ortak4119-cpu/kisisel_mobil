

// ==================== UTILITY SERVICE ====================

import '../../models/notification/notification_models.dart';
import '../base/base_api_service.dart';
import '../response/service_response.dart';

abstract class IUtilityService {
  Future<ServiceResponse<Quote>> getQuoteOfDay({String? language});
  Future<ServiceResponse<DashboardData>> getDashboardData();
  Future<ServiceResponse<AppInfo>> getAppInfo();
}

class UtilityService implements IUtilityService {
  @override
  Future<ServiceResponse<Quote>> getQuoteOfDay({String? language}) async {
    final queryParams = <String, dynamic>{};
    if (language != null) queryParams['language'] = language;

    final response = await BaseApiService.get<Map<String, dynamic>>(
      '/utility/quote-of-day',
      queryParameters: queryParams,
      requiresAuth: true,
    );

    if (response.isSuccess && response.data != null) {
      final quote = Quote.fromJson(
        response.data!['quote'] as Map<String, dynamic>,
      );
      return ServiceResponse.success(
        statusCode: response.statusCode,
        data: quote,
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
  Future<ServiceResponse<DashboardData>> getDashboardData() async {
    return await BaseApiService.get<DashboardData>(
      '/utility/dashboard',
      requiresAuth: true,
      fromJson: (json) => DashboardData.fromJson(json as Map<String, dynamic>),
    );
  }

  @override
  Future<ServiceResponse<AppInfo>> getAppInfo() async {
    return await BaseApiService.get<AppInfo>(
      '/utility/app-info',
      requiresAuth: false,
      fromJson: (json) => AppInfo.fromJson(json as Map<String, dynamic>),
    );
  }
}

// ==================== FEEDBACK SERVICE ====================

abstract class IFeedbackService {
  Future<ServiceResponse<Map<String, dynamic>>> submitFeedback(
      FeedbackRequest request,
      );
}

class FeedbackService implements IFeedbackService {
  @override
  Future<ServiceResponse<Map<String, dynamic>>> submitFeedback(
      FeedbackRequest request,
      ) async {
    return await BaseApiService.post<Map<String, dynamic>>(
      '/feedback',
      body: request.toJson(),
      requiresAuth: true,
    );
  }
}