import '../../models/subscription/subscription_models.dart';
import '../base/base_api_service.dart';
import '../response/service_response.dart';

abstract class ISubscriptionService {
  Future<ServiceResponse<List<Subscription>>> getAllSubscriptions({
    bool? isActive,
  });
  Future<ServiceResponse<Subscription>> getSubscription(int id);
  Future<ServiceResponse<Subscription>> createSubscription(
      SubscriptionRequest request,
      );
  Future<ServiceResponse<Subscription>> updateSubscription(
      int id,
      SubscriptionRequest request,
      );
  Future<ServiceResponse<void>> deleteSubscription(int id);
  Future<ServiceResponse<void>> toggleActiveStatus(int id);
  Future<ServiceResponse<SubscriptionStats>> getSubscriptionStats();
  Future<ServiceResponse<List<Subscription>>> getDueSoonSubscriptions({
    int? days,
  });
}

class SubscriptionService implements ISubscriptionService {
  @override
  Future<ServiceResponse<List<Subscription>>> getAllSubscriptions({
    bool? isActive,
  }) async {
    final queryParams = <String, dynamic>{};
    if (isActive != null) queryParams['is_active'] = isActive;

    final response = await BaseApiService.get<Map<String, dynamic>>(
      '/subscriptions',
      queryParameters: queryParams,
      requiresAuth: true,
    );

    if (response.isSuccess && response.data != null) {
      final subscriptions = (response.data!['subscriptions'] as List)
          .map((json) => Subscription.fromJson(json as Map<String, dynamic>))
          .toList();

      return ServiceResponse.success(
        statusCode: response.statusCode,
        data: subscriptions,
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
  Future<ServiceResponse<Subscription>> getSubscription(int id) async {
    return await BaseApiService.get<Subscription>(
      '/subscriptions/$id',
      requiresAuth: true,
      fromJson: (json) => Subscription.fromJson(json as Map<String, dynamic>),
    );
  }

  @override
  Future<ServiceResponse<Subscription>> createSubscription(
      SubscriptionRequest request,
      ) async {
    final response = await BaseApiService.post<Map<String, dynamic>>(
      '/subscriptions',
      body: request.toJson(),
      requiresAuth: true,
    );

    if (response.isSuccess && response.data != null) {
      final subscription = Subscription.fromJson(response.data!);
      return ServiceResponse.success(
        statusCode: response.statusCode,
        data: subscription,
        message: response.message ?? 'Abonelik başarıyla eklendi',
      );
    }

    return ServiceResponse.error(
      statusCode: response.statusCode,
      message: response.message ?? 'Abonelik oluşturulamadı',
      errors: response.errors,
    );
  }

  @override
  Future<ServiceResponse<Subscription>> updateSubscription(
      int id,
      SubscriptionRequest request,
      ) async {
    return await BaseApiService.put<Subscription>(
      '/subscriptions/$id',
      body: request.toJson(),
      requiresAuth: true,
      fromJson: (json) => Subscription.fromJson(json as Map<String, dynamic>),
    );
  }

  @override
  Future<ServiceResponse<void>> deleteSubscription(int id) async {
    return await BaseApiService.delete<void>(
      '/subscriptions/$id',
      requiresAuth: true,
    );
  }

  @override
  Future<ServiceResponse<void>> toggleActiveStatus(int id) async {
    return await BaseApiService.post<void>(
      '/subscriptions/$id/toggle-active',
      requiresAuth: true,
    );
  }

  @override
  Future<ServiceResponse<SubscriptionStats>> getSubscriptionStats() async {
    return await BaseApiService.get<SubscriptionStats>(
      '/subscriptions/stats',
      requiresAuth: true,
      fromJson: (json) =>
          SubscriptionStats.fromJson(json as Map<String, dynamic>),
    );
  }

  @override
  Future<ServiceResponse<List<Subscription>>> getDueSoonSubscriptions({
    int? days,
  }) async {
    final queryParams = <String, dynamic>{};
    if (days != null) queryParams['days'] = days;

    final response = await BaseApiService.get<Map<String, dynamic>>(
      '/subscriptions/due-soon',
      queryParameters: queryParams,
      requiresAuth: true,
    );

    if (response.isSuccess && response.data != null) {
      final subscriptions = (response.data!['subscriptions'] as List)
          .map((json) => Subscription.fromJson(json as Map<String, dynamic>))
          .toList();

      return ServiceResponse.success(
        statusCode: response.statusCode,
        data: subscriptions,
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