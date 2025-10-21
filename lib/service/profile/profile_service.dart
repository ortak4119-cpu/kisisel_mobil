import 'dart:io';

import 'package:flutter/cupertino.dart';

import '../../models/auth/auth_models.dart';
import '../../models/settings/settings_models.dart';
import '../base/base_api_service.dart';
import '../response/service_response.dart';


abstract class IProfileService {
  Future<ServiceResponse<User>> getProfile();
  Future<ServiceResponse<User>> updateProfile(ProfileUpdateRequest request);
  Future<ServiceResponse<String>> updateAvatar(File file);
  Future<ServiceResponse<String>> updateCover(File file);
  Future<ServiceResponse<ProfileStats>> getStats();
  Future<ServiceResponse<void>> deleteAccount({String? password});
}

class ProfileService implements IProfileService {
  @override
  Future<ServiceResponse<User>> getProfile() async {
    final response = await BaseApiService.get<Map<String, dynamic>>(
      '/profile',
      requiresAuth: true,
    );

    if (response.isSuccess && response.data != null) {
      final user = User.fromJson(response.data!['user'] as Map<String, dynamic>);
      return ServiceResponse.success(
        statusCode: response.statusCode,
        data: user,
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
  Future<ServiceResponse<User>> updateProfile(ProfileUpdateRequest request) async {
    final response = await BaseApiService.put<Map<String, dynamic>>(
      '/profile',
      body: request.toJson(),
      requiresAuth: true,
    );

    if (response.isSuccess && response.data != null) {
      final user = User.fromJson(response.data!['user'] as Map<String, dynamic>);
      return ServiceResponse.success(
        statusCode: response.statusCode,
        data: user,
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
  Future<ServiceResponse<String>> updateAvatar(File file) async {
    final response = await BaseApiService.uploadFile<Map<String, dynamic>>(
      '/profile/avatar',
      file: file,
      fieldName: 'avatar',
      requiresAuth: true,
    );

    if (response.isSuccess && response.data != null) {
      final imageUrl = response.data!['profile_picture_url'] as String;
      return ServiceResponse.success(
        statusCode: response.statusCode,
        data: imageUrl,
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
  Future<ServiceResponse<String>> updateCover(File file) async {
    final response = await BaseApiService.uploadFile<Map<String, dynamic>>(
      '/profile/cover',
      file: file,
      fieldName: 'cover',
      requiresAuth: true,
    );

    if (response.isSuccess && response.data != null) {
      final imageUrl = response.data!['cover_image_url'] as String;
      return ServiceResponse.success(
        statusCode: response.statusCode,
        data: imageUrl,
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
  Future<ServiceResponse<ProfileStats>> getStats() async {
    try {
      debugPrint('🔄 [ProfileService] Calling /profile/stats endpoint');

      final response = await BaseApiService.get<Map<String, dynamic>>(
        '/profile/stats',
        requiresAuth: true,
      );

      debugPrint('🔄 [ProfileService] Response received');
      debugPrint('   - isSuccess: ${response.isSuccess}');
      debugPrint('   - statusCode: ${response.statusCode}');
      debugPrint('   - message: ${response.message}');
      debugPrint('   - data is null: ${response.data == null}');

      if (response.data != null) {
        debugPrint('   - data keys: ${response.data!.keys.toList()}');
        debugPrint('   - raw data: ${response.data}');
      }

      if (response.isSuccess && response.data != null) {
        debugPrint('✅ [ProfileService] Parsing ProfileStats...');

        final stats = ProfileStats.fromJson(response.data!);

        debugPrint('✅ [ProfileService] Stats parsed successfully');

        return ServiceResponse.success(
          statusCode: response.statusCode,
          data: stats,
          message: response.message,
        );
      }

      debugPrint('❌ [ProfileService] Response not successful or data is null');
      return ServiceResponse.error(
        statusCode: response.statusCode,
        message: response.message,
        errors: response.errors,
      );
    } catch (e, stackTrace) {
      debugPrint('❌ [ProfileService] Exception caught: $e');
      debugPrint('❌ Stack trace: $stackTrace');

      return ServiceResponse.error(
        statusCode: 500,
        message: 'Stats yüklenirken hata: $e',
      );
    }
  }

  @override
  Future<ServiceResponse<void>> deleteAccount({String? password}) async {
    return await BaseApiService.delete<void>(
      '/profile',
      body: password != null ? {'password': password} : null,
      requiresAuth: true,
    );
  }
}