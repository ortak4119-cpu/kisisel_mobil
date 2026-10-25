import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../models/calender/calendar_models.dart';
import '../base/base_api_service.dart';
import '../response/service_response.dart';

abstract class ICalendarService {
  Future<ServiceResponse<List<CalendarEvent>>> getAllEvents({
    String? eventType,
    String? startDate,
    String? endDate,
  });

  Future<ServiceResponse<CalendarEvent>> createEvent(
      CalendarEventRequest request,
      );

  Future<ServiceResponse<CalendarEvent>> updateEvent(
      int id,
      CalendarEventUpdateRequest request,
      );

  Future<ServiceResponse<void>> deleteEvent(int id);
}

class CalendarService implements ICalendarService {
  @override
  Future<ServiceResponse<List<CalendarEvent>>> getAllEvents({
    String? eventType,
    String? startDate,
    String? endDate,
  }) async {
    final queryParams = <String, dynamic>{};
    if (eventType != null) queryParams['event_type'] = eventType;
    if (startDate != null) queryParams['start_date'] = startDate;
    if (endDate != null) queryParams['end_date'] = endDate;

    final response = await BaseApiService.get<List<CalendarEvent>>(
      '/calendar/events',
      queryParameters: queryParams,
      requiresAuth: true,
      fromJson: (json) {
        debugPrint('🔍 GetAllEvents - JSON Type: ${json.runtimeType}');
        debugPrint('🔍 GetAllEvents - JSON Content: $json');

        if (json is Map<String, dynamic>) {
          if (json.containsKey('events')) {
            final eventsList = json['events'] as List;
            return eventsList
                .map((e) => CalendarEvent.fromJson(e as Map<String, dynamic>))
                .toList();
          }
        }
        throw Exception('Invalid JSON format');
      },
    );

    if (response.isSuccess && response.data != null) {
      return ServiceResponse.success(
        statusCode: response.statusCode,
        data: response.data!,
        message: response.message,
      );
    }

    return ServiceResponse.error(
      statusCode: response.statusCode,
      message: response.errorMessage,
      errors: response.errors,
    );
  }

  @override
  Future<ServiceResponse<CalendarEvent>> createEvent(
      CalendarEventRequest request,
      ) async {
    final response = await BaseApiService.post<Map<String, dynamic>>(
      '/calendar/events',
      body: request.toJson(),
      requiresAuth: true,
    );

    if (response.isSuccess && response.data != null) {
      final event = CalendarEvent.fromJson(response.data!);
      return ServiceResponse.success(
        statusCode: response.statusCode,
        data: event,
        message: response.message ?? 'messages.eventCreated'.tr(),
      );
    }

    return ServiceResponse.error(
      statusCode: response.statusCode,
      message: response.message ?? 'messages.eventCreateFailed'.tr(),
      errors: response.errors,
    );
  }

  @override
  Future<ServiceResponse<CalendarEvent>> updateEvent(
      int id,
      CalendarEventUpdateRequest request,
      ) async {
    final response = await BaseApiService.put<CalendarEvent>(
      '/calendar/events/$id',
      body: request.toJson(),
      requiresAuth: true,
      fromJson: (json) {
        debugPrint('🔍 UpdateEvent - JSON Type: ${json.runtimeType}');
        debugPrint('🔍 UpdateEvent - JSON Content: $json');

        if (json is Map<String, dynamic>) {
          if (json.containsKey('data')) {
            return CalendarEvent.fromJson(
              json['data'] as Map<String, dynamic>,
            );
          }
          return CalendarEvent.fromJson(json);
        }
        throw Exception('Invalid JSON format');
      },
    );

    if (response.isSuccess && response.data != null) {
      return ServiceResponse.success(
        statusCode: response.statusCode,
        data: response.data!,
        message: response.message ?? 'messages.eventUpdated'.tr(),
      );
    }

    return ServiceResponse.error(
      statusCode: response.statusCode,
      message: response.errorMessage,
      errors: response.errors,
    );
  }

  @override
  Future<ServiceResponse<void>> deleteEvent(int id) async {
    final response = await BaseApiService.delete<void>(
      '/calendar/events/$id',
      requiresAuth: true,
    );

    if (response.isSuccess) {
      return ServiceResponse.success(
        statusCode: response.statusCode,
        data: null,
        message: response.message ?? 'messages.eventDeleted'.tr(),
      );
    }

    return ServiceResponse.error(
      statusCode: response.statusCode,
      message: response.errorMessage,
      errors: response.errors,
    );
  }
}
