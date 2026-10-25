import '../../models/habit/shared_habit_models.dart';
import '../base/base_api_service.dart';
import '../response/service_response.dart';

/// Paylaşımlı alışkanlık servisi (backend SharedHabitController zaten hazırdı).
abstract class ISharedHabitService {
  Future<ServiceResponse<List<SharedHabit>>> getMyShared();
  Future<ServiceResponse<SharedHabit>> create(SharedHabitRequest request);
  Future<ServiceResponse<SharedHabit>> joinByCode(String code);
  Future<ServiceResponse<SharedHabit>> getDetail(int id);
  Future<ServiceResponse<List<SharedHabitParticipant>>> getLeaderboard(int id);
  Future<ServiceResponse<void>> complete(int id);
  Future<ServiceResponse<void>> leave(int id);
  Future<ServiceResponse<void>> deleteShared(int id);
}

class SharedHabitService implements ISharedHabitService {
  @override
  Future<ServiceResponse<List<SharedHabit>>> getMyShared() async {
    final r = await BaseApiService.get<Map<String, dynamic>>(
      '/shared-habits',
      requiresAuth: true,
    );
    if (r.isSuccess && r.data != null) {
      final list = (r.data!['shared_habits'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(SharedHabit.fromJson)
          .toList();
      return ServiceResponse.success(
          statusCode: r.statusCode, data: list, message: r.message);
    }
    return ServiceResponse.error(
        statusCode: r.statusCode, message: r.message, errors: r.errors);
  }

  @override
  Future<ServiceResponse<SharedHabit>> create(
      SharedHabitRequest request) async {
    return await BaseApiService.post<SharedHabit>(
      '/shared-habits',
      body: request.toJson(),
      requiresAuth: true,
      fromJson: (j) => SharedHabit.fromJson(j as Map<String, dynamic>),
    );
  }

  @override
  Future<ServiceResponse<SharedHabit>> joinByCode(String code) async {
    return await BaseApiService.post<SharedHabit>(
      '/shared-habits/join-by-code',
      body: {'join_code': code.trim()},
      requiresAuth: true,
      fromJson: (j) => SharedHabit.fromJson(j as Map<String, dynamic>),
    );
  }

  @override
  Future<ServiceResponse<SharedHabit>> getDetail(int id) async {
    final r = await BaseApiService.get<Map<String, dynamic>>(
      '/shared-habits/$id',
      requiresAuth: true,
    );
    if (r.isSuccess && r.data != null) {
      final sh = SharedHabit.fromJson(
          r.data!['shared_habit'] as Map<String, dynamic>);
      return ServiceResponse.success(
          statusCode: r.statusCode, data: sh, message: r.message);
    }
    return ServiceResponse.error(
        statusCode: r.statusCode, message: r.message, errors: r.errors);
  }

  @override
  Future<ServiceResponse<List<SharedHabitParticipant>>> getLeaderboard(
      int id) async {
    final r = await BaseApiService.get<Map<String, dynamic>>(
      '/shared-habits/$id/leaderboard',
      requiresAuth: true,
    );
    if (r.isSuccess && r.data != null) {
      final list = (r.data!['leaderboard'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(SharedHabitParticipant.fromJson)
          .toList();
      return ServiceResponse.success(
          statusCode: r.statusCode, data: list, message: r.message);
    }
    return ServiceResponse.error(
        statusCode: r.statusCode, message: r.message, errors: r.errors);
  }

  @override
  Future<ServiceResponse<void>> complete(int id) async {
    return await BaseApiService.post<void>(
      '/shared-habits/$id/complete',
      requiresAuth: true,
    );
  }

  @override
  Future<ServiceResponse<void>> leave(int id) async {
    return await BaseApiService.post<void>(
      '/shared-habits/$id/leave',
      requiresAuth: true,
    );
  }

  @override
  Future<ServiceResponse<void>> deleteShared(int id) async {
    return await BaseApiService.delete<void>(
      '/shared-habits/$id',
      requiresAuth: true,
    );
  }
}
