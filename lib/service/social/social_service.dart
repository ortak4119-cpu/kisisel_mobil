import 'package:flutter/cupertino.dart';

import '../../models/social/social_model.dart';
import '../base/base_api_service.dart';
import '../response/service_response.dart';

abstract class ISocialService {
  Future<ServiceResponse<List<Friend>>> getFriends();
  Future<ServiceResponse<List<FriendRequest>>> getFriendRequests();
  Future<ServiceResponse<FriendRequest>> sendFriendRequest(int userId);
  Future<ServiceResponse<void>> acceptFriendRequest(int requestId);
  Future<ServiceResponse<void>> rejectFriendRequest(int requestId);
  Future<ServiceResponse<void>> unfriend(int userId);
  Future<ServiceResponse<void>> follow(int userId);
  Future<ServiceResponse<void>> unfollow(int userId);
  Future<ServiceResponse<List<Follower>>> getFollowers();
  Future<ServiceResponse<List<Following>>> getFollowing();
  Future<ServiceResponse<List<UserSearchResult>>> searchUsers(String query);
  Future<ServiceResponse<UserProfile>> getUserProfile(int userId);
}

class SocialService implements ISocialService {
  @override
  Future<ServiceResponse<List<Friend>>> getFriends() async {
    final response = await BaseApiService.get<Map<String, dynamic>>(
      '/social/friends',
      requiresAuth: true,
    );

    if (response.isSuccess && response.data != null) {
      final friends = (response.data!['friends'] as List)
          .map((json) => Friend.fromJson(json as Map<String, dynamic>))
          .toList();

      return ServiceResponse.success(
        statusCode: response.statusCode,
        data: friends,
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
  Future<ServiceResponse<List<FriendRequest>>> getFriendRequests() async {
    final response = await BaseApiService.get<Map<String, dynamic>>(
      '/social/friend-requests',
      requiresAuth: true,
    );

    if (response.isSuccess && response.data != null) {
      final requests = (response.data!['requests'] as List)
          .map((json) => FriendRequest.fromJson(json as Map<String, dynamic>))
          .toList();

      return ServiceResponse.success(
        statusCode: response.statusCode,
        data: requests,
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
  Future<ServiceResponse<FriendRequest>> sendFriendRequest(int userId) async {
    return await BaseApiService.post<FriendRequest>(
      '/social/friend-request/$userId',
      requiresAuth: true,
      fromJson: (json) => FriendRequest.fromJson(json as Map<String, dynamic>),
    );
  }

  @override
  Future<ServiceResponse<void>> acceptFriendRequest(int requestId) async {
    return await BaseApiService.post<void>(
      '/social/friend-request/$requestId/accept',
      requiresAuth: true,
    );
  }

  @override
  Future<ServiceResponse<void>> rejectFriendRequest(int requestId) async {
    return await BaseApiService.post<void>(
      '/social/friend-request/$requestId/reject',
      requiresAuth: true,
    );
  }

  @override
  Future<ServiceResponse<void>> unfriend(int userId) async {
    return await BaseApiService.delete<void>(
      '/social/friend/$userId',
      requiresAuth: true,
    );
  }

  @override
  Future<ServiceResponse<void>> follow(int userId) async {
    return await BaseApiService.post<void>(
      '/social/follow/$userId',
      requiresAuth: true,
    );
  }

  @override
  Future<ServiceResponse<void>> unfollow(int userId) async {
    return await BaseApiService.delete<void>(
      '/social/unfollow/$userId',
      requiresAuth: true,
    );
  }

  @override
  Future<ServiceResponse<List<Follower>>> getFollowers() async {
    final response = await BaseApiService.get<Map<String, dynamic>>(
      '/social/followers',
      requiresAuth: true,
    );

    if (response.isSuccess && response.data != null) {
      final followers = (response.data!['followers'] as List)
          .map((json) => Follower.fromJson(json as Map<String, dynamic>))
          .toList();

      return ServiceResponse.success(
        statusCode: response.statusCode,
        data: followers,
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
  Future<ServiceResponse<List<Following>>> getFollowing() async {
    final response = await BaseApiService.get<Map<String, dynamic>>(
      '/social/following',
      requiresAuth: true,
    );

    if (response.isSuccess && response.data != null) {
      final following = (response.data!['following'] as List)
          .map((json) => Following.fromJson(json as Map<String, dynamic>))
          .toList();

      return ServiceResponse.success(
        statusCode: response.statusCode,
        data: following,
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
  Future<ServiceResponse<List<UserSearchResult>>> searchUsers(String query) async {
    try {
      debugPrint('🔍 [SocialService] Searching users with query: "$query"');

      final response = await BaseApiService.get<Map<String, dynamic>>(
        '/social/users/search',
        queryParameters: {'query': query},
        requiresAuth: true,
      );

      debugPrint('🔍 [SocialService] Response received');
      debugPrint('   - isSuccess: ${response.isSuccess}');
      debugPrint('   - statusCode: ${response.statusCode}');
      debugPrint('   - data is null: ${response.data == null}');

      if (response.data != null) {
        debugPrint('   - data keys: ${response.data!.keys.toList()}');
        debugPrint('   - raw data: ${response.data}');
      }

      if (response.isSuccess && response.data != null) {
        debugPrint('🔍 [SocialService] Parsing users...');

        final users = (response.data!['users'] as List)
            .map((json) => UserSearchResult.fromJson(json as Map<String, dynamic>))
            .toList();

        debugPrint('✅ [SocialService] Parsed ${users.length} users');

        return ServiceResponse.success(
          statusCode: response.statusCode,
          data: users,
          message: response.message,
        );
      }

      debugPrint('❌ [SocialService] Search failed');
      return ServiceResponse.error(
        statusCode: response.statusCode,
        message: response.message,
        errors: response.errors,
      );
    } catch (e, stackTrace) {
      debugPrint('❌ [SocialService] Exception: $e');
      debugPrint('Stack trace: $stackTrace');

      return ServiceResponse.error(
        statusCode: 500,
        message: 'Arama sırasında hata: $e',
      );
    }
  }

  @override
  Future<ServiceResponse<UserProfile>> getUserProfile(int userId) async {
    return await BaseApiService.get<UserProfile>(
      '/social/users/$userId/profile',
      requiresAuth: true,
      fromJson: (json) => UserProfile.fromJson(json as Map<String, dynamic>),
    );
  }
}