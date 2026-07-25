import 'package:flutter/foundation.dart';
import '../../models/gamification/gamification_models.dart';
import '../base/base_api_service.dart';
import '../response/service_response.dart';

abstract class IGamificationService {
  Future<ServiceResponse<LevelInfo>> getLevelInfo();
  Future<ServiceResponse<PaginatedResponse<XPTransaction>>> getXPTransactions({
    int? page,
    int? perPage,
    String? filter,
  });
  Future<ServiceResponse<List<Achievement>>> getAchievements({
    String? category,
    String? rarity,
    bool? completed,
  });
  Future<ServiceResponse<Map<String, dynamic>>> getAchievementProgress();
  Future<ServiceResponse<List<LeaderboardEntry>>> getLeaderboard({
    int? limit,
    String? country,
  });
  Future<ServiceResponse<List<LeaderboardEntry>>> getFriendsLeaderboard();
}

class GamificationService implements IGamificationService {
  @override
  Future<ServiceResponse<LevelInfo>> getLevelInfo() async {
    final response = await BaseApiService.get<Map<String, dynamic>>(
      '/gamification/level',
      requiresAuth: true,
    );

    if (response.isSuccess && response.data != null) {
      final levelInfo = LevelInfo.fromJson(
        response.data!['level'] as Map<String, dynamic>,
      );
      return ServiceResponse.success(
        statusCode: response.statusCode,
        data: levelInfo,
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
  Future<ServiceResponse<PaginatedResponse<XPTransaction>>> getXPTransactions({
    int? page,
    int? perPage,
    String? filter,
  }) async {
    final queryParams = <String, dynamic>{};
    if (page != null) queryParams['page'] = page;
    if (perPage != null) queryParams['per_page'] = perPage;
    if (filter != null) queryParams['filter'] = filter;

    return await BaseApiService.getPaginated<XPTransaction>(
      '/gamification/xp-transactions',
      queryParameters: queryParams,
      requiresAuth: true,
      fromJson: (json) => XPTransaction.fromJson(json),
    );
  }

  @override
  Future<ServiceResponse<List<Achievement>>> getAchievements({
    String? category,
    String? rarity,
    bool? completed,
  }) async {
    final queryParams = <String, dynamic>{};
    if (category != null) queryParams['category'] = category;
    if (rarity != null) queryParams['rarity'] = rarity;
    if (completed != null) queryParams['completed'] = completed;

    try {
      debugPrint('🏆 [GamificationService] Fetching achievements...');

      final response = await BaseApiService.get<Map<String, dynamic>>(
        '/gamification/achievements',
        queryParameters: queryParams,
        requiresAuth: true,
      );

      debugPrint('🏆 [GamificationService] Response received');
      debugPrint('   - isSuccess: ${response.isSuccess}');
      debugPrint('   - statusCode: ${response.statusCode}');

      if (response.isSuccess && response.data != null) {
        debugPrint(
            '🏆 [GamificationService] Response data keys: ${response.data!.keys}');

        final achievementsData = response.data!['achievements'];
        debugPrint(
            '🏆 [GamificationService] Achievements data type: ${achievementsData.runtimeType}');
        debugPrint(
            '🏆 [GamificationService] Achievements count: ${(achievementsData as List).length}');

        final achievements = (achievementsData)
            .map((json) {
              try {
                return Achievement.fromJson(json as Map<String, dynamic>);
              } catch (e) {
                debugPrint(
                    '❌ [GamificationService] Error parsing achievement: $e');
                debugPrint('   JSON: $json');
                return null;
              }
            })
            .whereType<Achievement>() // Filter out null values
            .toList();

        debugPrint(
            '✅ [GamificationService] Successfully parsed ${achievements.length} achievements');

        return ServiceResponse.success(
          statusCode: response.statusCode,
          data: achievements,
          message: response.message,
        );
      }

      debugPrint(
          '❌ [GamificationService] Response failed: ${response.message}');
      return ServiceResponse.error(
        statusCode: response.statusCode,
        message: response.message,
        errors: response.errors,
      );
    } catch (e, stackTrace) {
      debugPrint('❌ [GamificationService] Exception in getAchievements: $e');
      debugPrint('Stack trace: $stackTrace');

      return ServiceResponse.error(
        statusCode: 500,
        message: 'Error loading achievements: $e',
      );
    }
  }

  @override
  Future<ServiceResponse<Map<String, dynamic>>> getAchievementProgress() async {
    return await BaseApiService.get<Map<String, dynamic>>(
      '/gamification/achievements/progress',
      requiresAuth: true,
    );
  }

  @override
  Future<ServiceResponse<List<LeaderboardEntry>>> getLeaderboard({
    int? limit,
    String? country,
  }) async {
    final queryParams = <String, dynamic>{};
    if (limit != null) queryParams['limit'] = limit;
    if (country != null) queryParams['country'] = country;

    final response = await BaseApiService.get<Map<String, dynamic>>(
      '/gamification/leaderboard',
      queryParameters: queryParams,
      requiresAuth: true,
    );

    if (response.isSuccess && response.data != null) {
      final leaderboard = (response.data!['leaderboard'] as List)
          .map(
              (json) => LeaderboardEntry.fromJson(json as Map<String, dynamic>))
          .toList();

      return ServiceResponse.success(
        statusCode: response.statusCode,
        data: leaderboard,
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
  Future<ServiceResponse<List<LeaderboardEntry>>>
      getFriendsLeaderboard() async {
    final response = await BaseApiService.get<Map<String, dynamic>>(
      '/gamification/leaderboard/friends',
      requiresAuth: true,
    );

    if (response.isSuccess && response.data != null) {
      final leaderboard = (response.data!['leaderboard'] as List)
          .map(
              (json) => LeaderboardEntry.fromJson(json as Map<String, dynamic>))
          .toList();

      return ServiceResponse.success(
        statusCode: response.statusCode,
        data: leaderboard,
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
