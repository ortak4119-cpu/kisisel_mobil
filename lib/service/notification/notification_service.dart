

import '../../models/notification/notification_models.dart';
import '../base/base_api_service.dart';
import '../response/service_response.dart';

abstract class INotificationService {
  Future<ServiceResponse<PaginatedResponse<AppNotification>>> getNotifications({
    int? page,
    int? perPage,
  });
  Future<ServiceResponse<int>> getUnreadCount();
  Future<ServiceResponse<void>> markAsRead(int id);
  Future<ServiceResponse<void>> markAllAsRead();
  Future<ServiceResponse<void>> deleteNotification(int id);
  Future<ServiceResponse<void>> deleteAllNotifications();
  Future<ServiceResponse<void>> storePushToken(PushTokenRequest request);
  Future<ServiceResponse<void>> deletePushToken(String deviceId);
}

class NotificationService implements INotificationService {
  @override
  Future<ServiceResponse<PaginatedResponse<AppNotification>>> getNotifications({
    int? page,
    int? perPage,
  }) async {
    final queryParams = <String, dynamic>{};
    if (page != null) queryParams['page'] = page;
    if (perPage != null) queryParams['per_page'] = perPage;

    return await BaseApiService.getPaginated<AppNotification>(
      '/notifications',
      queryParameters: queryParams,
      requiresAuth: true,
      fromJson: (json) => AppNotification.fromJson(json),
    );
  }

  @override
  Future<ServiceResponse<int>> getUnreadCount() async {
    final response = await BaseApiService.get<Map<String, dynamic>>(
      '/notifications/unread-count',
      requiresAuth: true,
    );

    if (response.isSuccess && response.data != null) {
      final count = response.data!['unread_count'] as int;
      return ServiceResponse.success(
        statusCode: response.statusCode,
        data: count,
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
  Future<ServiceResponse<void>> markAsRead(int id) async {
    return await BaseApiService.post<void>(
      '/notifications/$id/mark-read',
      requiresAuth: true,
    );
  }

  @override
  Future<ServiceResponse<void>> markAllAsRead() async {
    return await BaseApiService.post<void>(
      '/notifications/mark-all-read',
      requiresAuth: true,
    );
  }

  @override
  Future<ServiceResponse<void>> deleteNotification(int id) async {
    return await BaseApiService.delete<void>(
      '/notifications/$id',
      requiresAuth: true,
    );
  }

  @override
  Future<ServiceResponse<void>> deleteAllNotifications() async {
    return await BaseApiService.delete<void>(
      '/notifications',
      requiresAuth: true,
    );
  }

  @override
  Future<ServiceResponse<void>> storePushToken(PushTokenRequest request) async {
    return await BaseApiService.post<void>(
      '/push-tokens',
      body: request.toJson(),
      requiresAuth: true,
    );
  }

  @override
  Future<ServiceResponse<void>> deletePushToken(String deviceId) async {
    return await BaseApiService.delete<void>(
      '/push-tokens',
      body: {'device_id': deviceId},
      requiresAuth: true,
    );
  }
}