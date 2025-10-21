import '../../models/habit/habit_models.dart';
import '../base/base_api_service.dart';
import '../response/service_response.dart';


abstract class IHabitService {
  Future<ServiceResponse<List<Habit>>> getAllHabits({
    String? category,
    bool? isActive,
    String? difficultyLevel,
  });
  Future<ServiceResponse<Habit>> getHabit(int id);
  Future<ServiceResponse<Habit>> createHabit(HabitRequest request);
  Future<ServiceResponse<Habit>> updateHabit(int id, HabitRequest request);
  Future<ServiceResponse<void>> deleteHabit(int id);
  Future<ServiceResponse<Map<String, dynamic>>> markComplete(
      int id,
      CompleteHabitRequest request,
      );
  Future<ServiceResponse<void>> skipHabit(int id, SkipHabitRequest request);
  Future<ServiceResponse<PaginatedResponse<HabitLog>>> getHabitLogs(
      int id, {
        int? days,
        int? page,
        int? perPage,
      });
  Future<ServiceResponse<HabitStats>> getHabitStats(int id, {int? days});
  Future<ServiceResponse<Map<String, dynamic>>> getTodayStatus();
}

class HabitService implements IHabitService {
  @override
  Future<ServiceResponse<List<Habit>>> getAllHabits({
    String? category,
    bool? isActive,
    String? difficultyLevel,
  }) async {
    final queryParams = <String, dynamic>{};
    if (category != null) queryParams['category'] = category;
    if (isActive != null) queryParams['is_active'] = isActive;
    if (difficultyLevel != null) queryParams['difficulty_level'] = difficultyLevel;

    final response = await BaseApiService.get<Map<String, dynamic>>(
      '/habits',
      queryParameters: queryParams,
      requiresAuth: true,
    );

    if (response.isSuccess && response.data != null) {
      final habits = (response.data!['habits'] as List)
          .map((json) => Habit.fromJson(json as Map<String, dynamic>))
          .toList();

      return ServiceResponse.success(
        statusCode: response.statusCode,
        data: habits,
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
  Future<ServiceResponse<Habit>> getHabit(int id) async {
    return await BaseApiService.get<Habit>(
      '/habits/$id',
      requiresAuth: true,
      fromJson: (json) => Habit.fromJson(json as Map<String, dynamic>),
    );
  }

  @override
  Future<ServiceResponse<Habit>> createHabit(HabitRequest request) async {
    return await BaseApiService.post<Habit>(
      '/habits',
      body: request.toJson(),
      requiresAuth: true,
      fromJson: (json) => Habit.fromJson(json as Map<String, dynamic>),
    );
  }

  @override
  Future<ServiceResponse<Habit>> updateHabit(
      int id,
      HabitRequest request,
      ) async {
    return await BaseApiService.put<Habit>(
      '/habits/$id',
      body: request.toJson(),
      requiresAuth: true,
      fromJson: (json) => Habit.fromJson(json as Map<String, dynamic>),
    );
  }

  @override
  Future<ServiceResponse<void>> deleteHabit(int id) async {
    return await BaseApiService.delete<void>(
      '/habits/$id',
      requiresAuth: true,
    );
  }

  @override
  Future<ServiceResponse<Map<String, dynamic>>> markComplete(
      int id,
      CompleteHabitRequest request,
      ) async {
    final response = await BaseApiService.post<Map<String, dynamic>>(
      '/habits/$id/complete',
      body: request.toJson(),
      requiresAuth: true,
    );

    return response;
  }

  @override
  Future<ServiceResponse<void>> skipHabit(
      int id,
      SkipHabitRequest request,
      ) async {
    return await BaseApiService.post<void>(
      '/habits/$id/skip',
      body: request.toJson(),
      requiresAuth: true,
    );
  }

  @override
  Future<ServiceResponse<PaginatedResponse<HabitLog>>> getHabitLogs(
      int id, {
        int? days,
        int? page,
        int? perPage,
      }) async {
    final queryParams = <String, dynamic>{};
    if (days != null) queryParams['days'] = days;
    if (page != null) queryParams['page'] = page;
    if (perPage != null) queryParams['per_page'] = perPage;

    return await BaseApiService.getPaginated<HabitLog>(
      '/habits/$id/logs',
      queryParameters: queryParams,
      requiresAuth: true,
      fromJson: (json) => HabitLog.fromJson(json),
    );
  }

  @override
  Future<ServiceResponse<HabitStats>> getHabitStats(int id, {int? days}) async {
    final queryParams = <String, dynamic>{};
    if (days != null) queryParams['days'] = days;

    return await BaseApiService.get<HabitStats>(
      '/habits/$id/stats',
      queryParameters: queryParams,
      requiresAuth: true,
      fromJson: (json) => HabitStats.fromJson(json as Map<String, dynamic>),
    );
  }

  @override
  Future<ServiceResponse<Map<String, dynamic>>> getTodayStatus() async {
    return await BaseApiService.get<Map<String, dynamic>>(
      '/habits/today/status',
      requiresAuth: true,
    );
  }
}