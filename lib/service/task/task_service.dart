import 'package:flutter/cupertino.dart';

import '../../models/task/task_models.dart';
import '../base/base_api_service.dart';
import '../response/service_response.dart';

abstract class ITaskService {
  Future<ServiceResponse<List<Task>>> getAllTasks({
    String? type,
    int? priority,
    bool? isCompleted,
    String? sortBy,
    String? sortOrder,
  });
  Future<ServiceResponse<Task>> getTask(int id);
  Future<ServiceResponse<Task>> createTask(TaskRequest request);
  Future<ServiceResponse<Task>> updateTask(int id, TaskRequest request);
  Future<ServiceResponse<void>> deleteTask(int id);
  Future<ServiceResponse<void>> markComplete(int id, {int? actualDuration});
  Future<ServiceResponse<void>> markIncomplete(int id);
  Future<ServiceResponse<void>> archiveTask(int id);
  Future<ServiceResponse<List<Task>>> getDailyTasks();
  Future<ServiceResponse<List<Task>>> getWeeklyTasks();
  Future<ServiceResponse<List<Task>>> getOverdueTasks();
  Future<ServiceResponse<PaginatedResponse<Task>>> getCompletedTasks({
    int? page,
    int? perPage,
  });
}

class TaskService implements ITaskService {
  @override
  Future<ServiceResponse<List<Task>>> getAllTasks({
    String? type,
    int? priority,
    bool? isCompleted,
    String? sortBy,
    String? sortOrder,
  }) async {
    final queryParams = <String, dynamic>{};
    if (type != null) queryParams['type'] = type;
    if (priority != null) queryParams['priority'] = priority;
    if (isCompleted != null) queryParams['is_completed'] = isCompleted;
    if (sortBy != null) queryParams['sort_by'] = sortBy;
    if (sortOrder != null) queryParams['sort_order'] = sortOrder;

    final response = await BaseApiService.get<Map<String, dynamic>>(
      '/tasks',
      queryParameters: queryParams,
      requiresAuth: true,
    );

    if (response.isSuccess && response.data != null) {
      final tasks = (response.data!['tasks'] as List)
          .map((json) => Task.fromJson(json as Map<String, dynamic>))
          .toList();

      return ServiceResponse.success(
        statusCode: response.statusCode,
        data: tasks,
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
  Future<ServiceResponse<Task>> getTask(int id) async {
    return await BaseApiService.get<Task>(
      '/tasks/$id',
      requiresAuth: true,
      fromJson: (json) => Task.fromJson(json as Map<String, dynamic>),
    );
  }

  @override
  Future<ServiceResponse<Task>> createTask(TaskRequest request) async {
    debugPrint('📝 Creating task service called');

    final response = await BaseApiService.post<Map<String, dynamic>>(
      '/tasks',
      body: request.toJson(),
      requiresAuth: true,
    );

    debugPrint('📝 Create task response - Success: ${response.isSuccess}');
    debugPrint('📝 Create task response - Data: ${response.data}');

    if (response.isSuccess && response.data != null) {
      try {
        // Backend'den "data" key'i içinde task geliyor veya direkt geliyor
        Map<String, dynamic> taskData;

        if (response.data!.containsKey('data')) {
          taskData = response.data!['data'] as Map<String, dynamic>;
        } else {
          taskData = response.data!;
        }

        debugPrint('📝 Task data extracted: $taskData');

        final task = Task.fromJson(taskData);
        debugPrint('📝 ✅ Task parsed successfully');

        return ServiceResponse.success(
          statusCode: response.statusCode,
          data: task,
          message: response.message ?? 'Görev oluşturuldu',
        );
      } catch (e, stackTrace) {
        debugPrint('📝 ❌ Error parsing task: $e');
        debugPrint('📝 ❌ StackTrace: $stackTrace');
        return ServiceResponse.error(
          statusCode: 500,
          message: 'Görev verisi işlenemedi: $e',
        );
      }
    }

    debugPrint('📝 ❌ Create task failed');
    return ServiceResponse.error(
      statusCode: response.statusCode,
      message: response.message ?? 'Görev oluşturulamadı',
      errors: response.errors,
    );
  }

  @override
  Future<ServiceResponse<Task>> updateTask(int id, TaskRequest request) async {
    return await BaseApiService.put<Task>(
      '/tasks/$id',
      body: request.toJson(),
      requiresAuth: true,
      fromJson: (json) => Task.fromJson(json as Map<String, dynamic>),
    );
  }

  @override
  Future<ServiceResponse<void>> deleteTask(int id) async {
    return await BaseApiService.delete<void>(
      '/tasks/$id',
      requiresAuth: true,
    );
  }

  @override
  Future<ServiceResponse<void>> markComplete(int id, {int? actualDuration}) async {
    return await BaseApiService.post<void>(
      '/tasks/$id/complete',
      body: actualDuration != null
          ? {'actual_duration_minutes': actualDuration}
          : null,
      requiresAuth: true,
    );
  }

  @override
  Future<ServiceResponse<void>> markIncomplete(int id) async {
    return await BaseApiService.post<void>(
      '/tasks/$id/uncomplete',
      requiresAuth: true,
    );
  }

  @override
  Future<ServiceResponse<void>> archiveTask(int id) async {
    return await BaseApiService.post<void>(
      '/tasks/$id/archive',
      requiresAuth: true,
    );
  }

  @override
  Future<ServiceResponse<List<Task>>> getDailyTasks() async {
    final response = await BaseApiService.get<Map<String, dynamic>>(
      '/tasks/daily',
      requiresAuth: true,
    );

    if (response.isSuccess && response.data != null) {
      final tasks = (response.data!['tasks'] as List)
          .map((json) => Task.fromJson(json as Map<String, dynamic>))
          .toList();

      return ServiceResponse.success(
        statusCode: response.statusCode,
        data: tasks,
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
  Future<ServiceResponse<List<Task>>> getWeeklyTasks() async {
    final response = await BaseApiService.get<Map<String, dynamic>>(
      '/tasks/weekly',
      requiresAuth: true,
    );

    if (response.isSuccess && response.data != null) {
      final tasks = (response.data!['tasks'] as List)
          .map((json) => Task.fromJson(json as Map<String, dynamic>))
          .toList();

      return ServiceResponse.success(
        statusCode: response.statusCode,
        data: tasks,
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
  Future<ServiceResponse<List<Task>>> getOverdueTasks() async {
    final response = await BaseApiService.get<Map<String, dynamic>>(
      '/tasks/overdue',
      requiresAuth: true,
    );

    if (response.isSuccess && response.data != null) {
      final tasks = (response.data!['tasks'] as List)
          .map((json) => Task.fromJson(json as Map<String, dynamic>))
          .toList();

      return ServiceResponse.success(
        statusCode: response.statusCode,
        data: tasks,
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
  Future<ServiceResponse<PaginatedResponse<Task>>> getCompletedTasks({
    int? page,
    int? perPage,
  }) async {
    final queryParams = <String, dynamic>{};
    if (page != null) queryParams['page'] = page;
    if (perPage != null) queryParams['per_page'] = perPage;

    return await BaseApiService.getPaginated<Task>(
      '/tasks/completed',
      queryParameters: queryParams,
      requiresAuth: true,
      fromJson: (json) => Task.fromJson(json),
    );
  }
}