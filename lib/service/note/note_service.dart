import 'package:flutter/material.dart';
import '../../models/note/note_models.dart';
import '../base/base_api_service.dart';
import '../response/service_response.dart';

abstract class INoteService {
  Future<ServiceResponse<List<Note>>> getAllNotes({
    int? categoryId,
    bool? isArchived,
    bool? isPinned,
    String? search,
  });
  Future<ServiceResponse<Note>> getNote(int id);
  Future<ServiceResponse<Note>> createNote(NoteRequest request);
  Future<ServiceResponse<Note>> updateNote(int id, NoteRequest request);
  Future<ServiceResponse<void>> deleteNote(int id);
  Future<ServiceResponse<void>> lockNote(int id, String pin);
  Future<ServiceResponse<Note>> unlockNote(int id, String pin);
  Future<ServiceResponse<void>> archiveNote(int id);
  Future<ServiceResponse<void>> unarchiveNote(int id);
  Future<ServiceResponse<void>> pinNote(int id);
  Future<ServiceResponse<void>> unpinNote(int id);
  Future<ServiceResponse<List<NoteCategory>>> getCategories();
  Future<ServiceResponse<NoteCategory>> createCategory(NoteCategoryRequest request);
  Future<ServiceResponse<NoteCategory>> updateCategory(
      int id,
      NoteCategoryRequest request,
      );
  Future<ServiceResponse<void>> deleteCategory(int id);
}

class NoteService implements INoteService {
  @override
  Future<ServiceResponse<List<Note>>> getAllNotes({
    int? categoryId,
    bool? isArchived,
    bool? isPinned,
    String? search,
  }) async {
    final queryParams = <String, dynamic>{};
    if (categoryId != null) queryParams['category_id'] = categoryId;
    if (isArchived != null) queryParams['is_archived'] = isArchived;
    if (isPinned != null) queryParams['is_pinned'] = isPinned;
    if (search != null) queryParams['search'] = search;

    final response = await BaseApiService.get<Map<String, dynamic>>(
      '/notes',
      queryParameters: queryParams,
      requiresAuth: true,
    );

    if (response.isSuccess && response.data != null) {
      final notes = (response.data!['notes'] as List)
          .map((json) => Note.fromJson(json as Map<String, dynamic>))
          .toList();

      return ServiceResponse.success(
        statusCode: response.statusCode,
        data: notes,
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
  Future<ServiceResponse<Note>> getNote(int id) async {
    return await BaseApiService.get<Note>(
      '/notes/$id',
      requiresAuth: true,
      fromJson: (json) => Note.fromJson(json as Map<String, dynamic>),
    );
  }

  @override
  Future<ServiceResponse<Note>> createNote(NoteRequest request) async {
    final response = await BaseApiService.post<Map<String, dynamic>>(
      '/notes',
      body: request.toJson(),
      requiresAuth: true,
    );

    if (response.isSuccess && response.data != null) {
      final note = Note.fromJson(response.data!);
      return ServiceResponse.success(
        statusCode: response.statusCode,
        data: note,
        message: response.message ?? 'Not başarıyla eklendi',
      );
    }

    return ServiceResponse.error(
      statusCode: response.statusCode,
      message: response.message ?? 'Not oluşturulamadı',
      errors: response.errors,
    );
  }

  @override
  Future<ServiceResponse<Note>> updateNote(int id, NoteRequest request) async {
    final response = await BaseApiService.put<Map<String, dynamic>>(
      '/notes/$id',
      body: request.toJson(),
      requiresAuth: true,
    );

    if (response.isSuccess && response.data != null) {
      final note = Note.fromJson(response.data!);
      return ServiceResponse.success(
        statusCode: response.statusCode,
        data: note,
        message: response.message ?? 'Not güncellendi',
      );
    }

    return ServiceResponse.error(
      statusCode: response.statusCode,
      message: response.message ?? 'Not güncellenemedi',
      errors: response.errors,
    );
  }

  @override
  Future<ServiceResponse<void>> deleteNote(int id) async {
    return await BaseApiService.delete<void>(
      '/notes/$id',
      requiresAuth: true,
    );
  }

  @override
  Future<ServiceResponse<void>> lockNote(int id, String pin) async {
    return await BaseApiService.post<void>(
      '/notes/$id/lock',
      body: {'pin': pin},
      requiresAuth: true,
    );
  }

  @override
  Future<ServiceResponse<Note>> unlockNote(int id, String pin) async {
    debugPrint('🔓 Unlock note called - ID: $id, PIN: $pin');

    final response = await BaseApiService.post<Map<String, dynamic>>(
      '/notes/$id/unlock',
      body: {'pin': pin},
      requiresAuth: true,
    );

    debugPrint('🔍 Unlock response - Success: ${response.isSuccess}');
    debugPrint('🔍 Unlock response - Data: ${response.data}');
    debugPrint('🔍 Unlock response - Message: ${response.message}');

    if (response.isSuccess && response.data != null) {
      try {
        // Backend'den "note" key'i içinde data geliyor
        final noteData = response.data!['note'] as Map<String, dynamic>;
        debugPrint('📦 Note data extracted: $noteData');

        final note = Note.fromJson(noteData);
        debugPrint('✅ Note parsed successfully - Locked: ${note.isLocked}');

        return ServiceResponse.success(
          statusCode: response.statusCode,
          data: note,
          message: response.message ?? 'Not kilidi açıldı',
        );
      } catch (e, stackTrace) {
        debugPrint('❌ Error parsing note: $e');
        debugPrint('❌ StackTrace: $stackTrace');
        return ServiceResponse.error(
          statusCode: 500,
          message: 'Not verisi işlenemedi: $e',
        );
      }
    }

    debugPrint('❌ Unlock failed - StatusCode: ${response.statusCode}');
    return ServiceResponse.error(
      statusCode: response.statusCode,
      message: response.message ?? 'Not kilidi açılamadı',
      errors: response.errors,
    );
  }

  @override
  Future<ServiceResponse<void>> archiveNote(int id) async {
    return await BaseApiService.post<void>(
      '/notes/$id/archive',
      requiresAuth: true,
    );
  }

  @override
  Future<ServiceResponse<void>> unarchiveNote(int id) async {
    return await BaseApiService.post<void>(
      '/notes/$id/unarchive',
      requiresAuth: true,
    );
  }

  @override
  Future<ServiceResponse<void>> pinNote(int id) async {
    return await BaseApiService.post<void>(
      '/notes/$id/pin',
      requiresAuth: true,
    );
  }

  @override
  Future<ServiceResponse<void>> unpinNote(int id) async {
    return await BaseApiService.post<void>(
      '/notes/$id/unpin',
      requiresAuth: true,
    );
  }

  @override
  Future<ServiceResponse<List<NoteCategory>>> getCategories() async {
    final response = await BaseApiService.get<Map<String, dynamic>>(
      '/notes/categories',
      requiresAuth: true,
    );

    if (response.isSuccess && response.data != null) {
      final categories = (response.data!['categories'] as List)
          .map((json) => NoteCategory.fromJson(json as Map<String, dynamic>))
          .toList();

      return ServiceResponse.success(
        statusCode: response.statusCode,
        data: categories,
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
  Future<ServiceResponse<NoteCategory>> createCategory(
      NoteCategoryRequest request,
      ) async {
    debugPrint('🔧 Creating category service called');

    final response = await BaseApiService.post<Map<String, dynamic>>(
      '/notes/categories',
      body: request.toJson(),
      requiresAuth: true,
    );

    debugPrint('🔧 Create category response - Success: ${response.isSuccess}');
    debugPrint('🔧 Create category response - Data: ${response.data}');

    if (response.isSuccess && response.data != null) {
      try {
        // Backend'den gelen data'ya eksik alanları ekle
        final categoryData = {
          ...response.data!,
          'notes_count': response.data!['notes_count'] ?? 0,
          'order_index': response.data!['order_index'] ?? 0,
        };

        final category = NoteCategory.fromJson(categoryData);
        debugPrint('🔧 ✅ Category parsed successfully');

        return ServiceResponse.success(
          statusCode: response.statusCode,
          data: category,
          message: response.message ?? 'Kategori oluşturuldu',
        );
      } catch (e, stackTrace) {
        debugPrint('🔧 ❌ Error parsing category: $e');
        debugPrint('🔧 ❌ StackTrace: $stackTrace');
        return ServiceResponse.error(
          statusCode: 500,
          message: 'Kategori verisi işlenemedi: $e',
        );
      }
    }

    debugPrint('🔧 ❌ Create category failed');
    return ServiceResponse.error(
      statusCode: response.statusCode,
      message: response.message ?? 'Kategori oluşturulamadı',
      errors: response.errors,
    );
  }

  @override
  Future<ServiceResponse<NoteCategory>> updateCategory(
      int id,
      NoteCategoryRequest request,
      ) async {
    return await BaseApiService.put<NoteCategory>(
      '/notes/categories/$id',
      body: request.toJson(),
      requiresAuth: true,
      fromJson: (json) => NoteCategory.fromJson(json as Map<String, dynamic>),
    );
  }

  @override
  Future<ServiceResponse<void>> deleteCategory(int id) async {
    return await BaseApiService.delete<void>(
      '/notes/categories/$id',
      requiresAuth: true,
    );
  }
}