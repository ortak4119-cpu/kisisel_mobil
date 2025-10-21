import 'package:flutter/material.dart';
import '../../models/diary/diary_models.dart';
import '../base/base_api_service.dart';
import '../response/service_response.dart';

abstract class IDiaryService {
  Future<ServiceResponse<PaginatedResponse<Diary>>> getAllDiaries({
    int? month,
    int? year,
    int? page,
    int? perPage,
  });
  Future<ServiceResponse<Diary>> getDiaryByDate(String date);
  Future<ServiceResponse<Diary>> createDiary(DiaryRequest request);
  Future<ServiceResponse<Diary>> updateDiary(String date, DiaryRequest request);
  Future<ServiceResponse<void>> deleteDiary(String date);
  Future<ServiceResponse<DiaryStats>> getDiaryStats();
  Future<ServiceResponse<MoodAnalysis>> getMoodAnalysis({int? days});
}

class DiaryService implements IDiaryService {
  @override
  Future<ServiceResponse<PaginatedResponse<Diary>>> getAllDiaries({
    int? month,
    int? year,
    int? page,
    int? perPage,
  }) async {
    final queryParams = <String, dynamic>{};
    if (month != null) queryParams['month'] = month;
    if (year != null) queryParams['year'] = year;
    if (page != null) queryParams['page'] = page;
    if (perPage != null) queryParams['per_page'] = perPage;

    return await BaseApiService.getPaginated<Diary>(
      '/diary',
      queryParameters: queryParams,
      requiresAuth: true,
      fromJson: (json) => Diary.fromJson(json),
    );
  }

  @override
  Future<ServiceResponse<Diary>> getDiaryByDate(String date) async {
    final response = await BaseApiService.get<Diary>(
      '/diary/$date',
      requiresAuth: true,
      fromJson: (json) {
        if (json is Map<String, dynamic>) {
          if (json.containsKey('data')) {
            return Diary.fromJson(json['data'] as Map<String, dynamic>);
          }
          return Diary.fromJson(json);
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
  Future<ServiceResponse<Diary>> createDiary(DiaryRequest request) async {
    final response = await BaseApiService.post<Diary>(
      '/diary',
      body: request.toJson(),
      requiresAuth: true,
      fromJson: (json) {
        debugPrint('🔍 CreateDiary - JSON Type: ${json.runtimeType}');
        debugPrint('🔍 CreateDiary - JSON Content: $json');

        if (json is Map<String, dynamic>) {
          if (json.containsKey('data')) {
            debugPrint('✅ Found "data" key, parsing...');
            return Diary.fromJson(json['data'] as Map<String, dynamic>);
          }
          debugPrint('⚠️ No "data" key, parsing directly...');
          return Diary.fromJson(json);
        }
        throw Exception('Invalid JSON format');
      },
    );

    if (response.isSuccess && response.data != null) {
      return ServiceResponse.success(
        statusCode: response.statusCode,
        data: response.data!,
        message: response.message ?? 'Günlük başarıyla oluşturuldu',
      );
    }

    return ServiceResponse.error(
      statusCode: response.statusCode,
      message: response.errorMessage,
      errors: response.errors,
    );
  }

  @override
  Future<ServiceResponse<Diary>> updateDiary(
      String date,
      DiaryRequest request,
      ) async {
    final response = await BaseApiService.put<Diary>(
      '/diary/$date',
      body: request.toJson(),
      requiresAuth: true,
      fromJson: (json) {
        debugPrint('🔍 UpdateDiary - JSON Type: ${json.runtimeType}');
        debugPrint('🔍 UpdateDiary - JSON Content: $json');

        if (json is Map<String, dynamic>) {
          if (json.containsKey('data')) {
            debugPrint('✅ Found "data" key, parsing...');
            return Diary.fromJson(json['data'] as Map<String, dynamic>);
          }
          debugPrint('⚠️ No "data" key, parsing directly...');
          return Diary.fromJson(json);
        }
        throw Exception('Invalid JSON format');
      },
    );

    if (response.isSuccess && response.data != null) {
      return ServiceResponse.success(
        statusCode: response.statusCode,
        data: response.data!,
        message: response.message ?? 'Günlük güncellendi',
      );
    }

    return ServiceResponse.error(
      statusCode: response.statusCode,
      message: response.errorMessage,
      errors: response.errors,
    );
  }

  @override
  Future<ServiceResponse<void>> deleteDiary(String date) async {
    final response = await BaseApiService.delete<void>(
      '/diary/$date',
      requiresAuth: true,
    );

    if (response.isSuccess) {
      return ServiceResponse.success(
        statusCode: response.statusCode,
        data: null,
        message: response.message ?? 'Günlük silindi',
      );
    }

    return ServiceResponse.error(
      statusCode: response.statusCode,
      message: response.errorMessage,
      errors: response.errors,
    );
  }

  @override
  Future<ServiceResponse<DiaryStats>> getDiaryStats() async {
    final response = await BaseApiService.get<DiaryStats>(
      '/diary/stats',
      requiresAuth: true,
      fromJson: (json) {
        if (json is Map<String, dynamic>) {
          if (json.containsKey('data')) {
            return DiaryStats.fromJson(json['data'] as Map<String, dynamic>);
          }
          return DiaryStats.fromJson(json);
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
  Future<ServiceResponse<MoodAnalysis>> getMoodAnalysis({int? days}) async {
    final queryParams = <String, dynamic>{};
    if (days != null) queryParams['days'] = days;

    final response = await BaseApiService.get<MoodAnalysis>(
      '/diary/mood-analysis',
      queryParameters: queryParams,
      requiresAuth: true,
      fromJson: (json) {
        if (json is Map<String, dynamic>) {
          if (json.containsKey('data')) {
            return MoodAnalysis.fromJson(json['data'] as Map<String, dynamic>);
          }
          return MoodAnalysis.fromJson(json);
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
}