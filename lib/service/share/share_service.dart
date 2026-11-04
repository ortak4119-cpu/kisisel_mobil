import '../../models/share/shared_item_models.dart';
import '../base/base_api_service.dart';
import '../response/service_response.dart';

/// Arkadaşla ortak not/görev paylaşımı API istemcisi.
abstract class IShareService {
  // Paylaşma (davet gönderme)
  Future<ServiceResponse<void>> shareNote(int noteId, List<int> userIds, String permission);
  Future<ServiceResponse<void>> shareTask(int taskId, List<int> userIds, String permission);

  // Listeler
  Future<ServiceResponse<List<SharedNoteItem>>> getSharedNotes();
  Future<ServiceResponse<List<SharedTaskItem>>> getSharedTasks();
  Future<ServiceResponse<List<ShareInvite>>> getNoteInvites();
  Future<ServiceResponse<List<ShareInvite>>> getTaskInvites();

  // Davet yanıtları
  Future<ServiceResponse<void>> acceptNote(int id);
  Future<ServiceResponse<void>> rejectNote(int id);
  Future<ServiceResponse<void>> leaveNote(int id);
  Future<ServiceResponse<void>> acceptTask(int id);
  Future<ServiceResponse<void>> rejectTask(int id);
  Future<ServiceResponse<void>> leaveTask(int id);

  // İçerik güncelleme / tamamlama
  Future<ServiceResponse<void>> updateSharedNote(int id, {String? title, String? content});
  Future<ServiceResponse<void>> updateSharedTask(int id, {String? title, String? description, String? dueDate});
  Future<ServiceResponse<void>> completeSharedTask(int id, bool completed);

  // Kaldırma
  Future<ServiceResponse<void>> deleteSharedNote(int id);
  Future<ServiceResponse<void>> deleteSharedTask(int id);

  // Canlı düzenleme kilidi
  Future<ServiceResponse<ShareLockState>> lockNote(int id);
  Future<ServiceResponse<void>> unlockNote(int id);
  Future<ServiceResponse<void>> pushNoteDraft(int id, String content);
  Future<ServiceResponse<ShareLockState>> lockTask(int id);
  Future<ServiceResponse<void>> unlockTask(int id);

  // Alışkanlık paylaşımı
  Future<ServiceResponse<void>> shareHabit(int habitId, List<int> userIds, String permission);
  Future<ServiceResponse<List<SharedHabitItem>>> getSharedHabits();
  Future<ServiceResponse<List<ShareInvite>>> getHabitInvites();
  Future<ServiceResponse<void>> acceptHabit(int id);
  Future<ServiceResponse<void>> rejectHabit(int id);
  Future<ServiceResponse<void>> leaveHabit(int id);
  Future<ServiceResponse<void>> deleteSharedHabit(int id);
  Future<ServiceResponse<void>> completeSharedHabit(int id, {String? date, bool completed = true});
  Future<ServiceResponse<HabitHeatmap>> getHabitHeatmap(int id, {int days = 90});
  Future<ServiceResponse<ShareLockState>> lockHabit(int id);
  Future<ServiceResponse<void>> unlockHabit(int id);
}

class ShareService implements IShareService {
  @override
  Future<ServiceResponse<void>> shareNote(int noteId, List<int> userIds, String permission) {
    return BaseApiService.post<void>('/notes/$noteId/share',
        requiresAuth: true, body: {'user_ids': userIds, 'permission': permission});
  }

  @override
  Future<ServiceResponse<void>> shareTask(int taskId, List<int> userIds, String permission) {
    return BaseApiService.post<void>('/tasks/$taskId/share',
        requiresAuth: true, body: {'user_ids': userIds, 'permission': permission});
  }

  @override
  Future<ServiceResponse<List<SharedNoteItem>>> getSharedNotes() async {
    final r = await BaseApiService.get<Map<String, dynamic>>('/shared-notes', requiresAuth: true);
    if (r.isSuccess && r.data != null) {
      final list = (r.data!['shared_notes'] as List? ?? [])
          .map((e) => SharedNoteItem.fromJson(e as Map<String, dynamic>))
          .toList();
      return ServiceResponse.success(statusCode: r.statusCode, data: list, message: r.message);
    }
    return ServiceResponse.error(statusCode: r.statusCode, message: r.message, errors: r.errors);
  }

  @override
  Future<ServiceResponse<List<SharedTaskItem>>> getSharedTasks() async {
    final r = await BaseApiService.get<Map<String, dynamic>>('/shared-tasks', requiresAuth: true);
    if (r.isSuccess && r.data != null) {
      final list = (r.data!['shared_tasks'] as List? ?? [])
          .map((e) => SharedTaskItem.fromJson(e as Map<String, dynamic>))
          .toList();
      return ServiceResponse.success(statusCode: r.statusCode, data: list, message: r.message);
    }
    return ServiceResponse.error(statusCode: r.statusCode, message: r.message, errors: r.errors);
  }

  @override
  Future<ServiceResponse<List<ShareInvite>>> getNoteInvites() async {
    final r = await BaseApiService.get<Map<String, dynamic>>('/shared-notes/invites', requiresAuth: true);
    if (r.isSuccess && r.data != null) {
      final list = (r.data!['invites'] as List? ?? [])
          .map((e) => ShareInvite.fromJson(e as Map<String, dynamic>, 'note'))
          .toList();
      return ServiceResponse.success(statusCode: r.statusCode, data: list, message: r.message);
    }
    return ServiceResponse.error(statusCode: r.statusCode, message: r.message, errors: r.errors);
  }

  @override
  Future<ServiceResponse<List<ShareInvite>>> getTaskInvites() async {
    final r = await BaseApiService.get<Map<String, dynamic>>('/shared-tasks/invites', requiresAuth: true);
    if (r.isSuccess && r.data != null) {
      final list = (r.data!['invites'] as List? ?? [])
          .map((e) => ShareInvite.fromJson(e as Map<String, dynamic>, 'task'))
          .toList();
      return ServiceResponse.success(statusCode: r.statusCode, data: list, message: r.message);
    }
    return ServiceResponse.error(statusCode: r.statusCode, message: r.message, errors: r.errors);
  }

  @override
  Future<ServiceResponse<void>> acceptNote(int id) =>
      BaseApiService.post<void>('/shared-notes/$id/accept', requiresAuth: true);
  @override
  Future<ServiceResponse<void>> rejectNote(int id) =>
      BaseApiService.post<void>('/shared-notes/$id/reject', requiresAuth: true);
  @override
  Future<ServiceResponse<void>> leaveNote(int id) =>
      BaseApiService.post<void>('/shared-notes/$id/leave', requiresAuth: true);
  @override
  Future<ServiceResponse<void>> acceptTask(int id) =>
      BaseApiService.post<void>('/shared-tasks/$id/accept', requiresAuth: true);
  @override
  Future<ServiceResponse<void>> rejectTask(int id) =>
      BaseApiService.post<void>('/shared-tasks/$id/reject', requiresAuth: true);
  @override
  Future<ServiceResponse<void>> leaveTask(int id) =>
      BaseApiService.post<void>('/shared-tasks/$id/leave', requiresAuth: true);

  @override
  Future<ServiceResponse<void>> updateSharedNote(int id, {String? title, String? content}) {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (content != null) body['content'] = content;
    return BaseApiService.put<void>('/shared-notes/$id', requiresAuth: true, body: body);
  }

  @override
  Future<ServiceResponse<void>> updateSharedTask(int id, {String? title, String? description, String? dueDate}) {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (description != null) body['description'] = description;
    if (dueDate != null) body['due_date'] = dueDate;
    return BaseApiService.put<void>('/shared-tasks/$id', requiresAuth: true, body: body);
  }

  @override
  Future<ServiceResponse<void>> completeSharedTask(int id, bool completed) =>
      BaseApiService.post<void>('/shared-tasks/$id/complete', requiresAuth: true, body: {'completed': completed});

  @override
  Future<ServiceResponse<void>> deleteSharedNote(int id) =>
      BaseApiService.delete<void>('/shared-notes/$id', requiresAuth: true);
  @override
  Future<ServiceResponse<void>> deleteSharedTask(int id) =>
      BaseApiService.delete<void>('/shared-tasks/$id', requiresAuth: true);

  @override
  Future<ServiceResponse<ShareLockState>> lockNote(int id) =>
      BaseApiService.post<ShareLockState>('/shared-notes/$id/lock',
          requiresAuth: true,
          fromJson: (j) => ShareLockState.fromJson(j as Map<String, dynamic>));
  @override
  Future<ServiceResponse<void>> unlockNote(int id) =>
      BaseApiService.post<void>('/shared-notes/$id/unlock', requiresAuth: true);
  @override
  Future<ServiceResponse<void>> pushNoteDraft(int id, String content) =>
      BaseApiService.post<void>('/shared-notes/$id/draft',
          requiresAuth: true, body: {'content': content});
  @override
  Future<ServiceResponse<ShareLockState>> lockTask(int id) =>
      BaseApiService.post<ShareLockState>('/shared-tasks/$id/lock',
          requiresAuth: true,
          fromJson: (j) => ShareLockState.fromJson(j as Map<String, dynamic>));
  @override
  Future<ServiceResponse<void>> unlockTask(int id) =>
      BaseApiService.post<void>('/shared-tasks/$id/unlock', requiresAuth: true);

  // ---- Alışkanlık paylaşımı ----
  @override
  Future<ServiceResponse<void>> shareHabit(int habitId, List<int> userIds, String permission) {
    return BaseApiService.post<void>('/habits/$habitId/share',
        requiresAuth: true, body: {'user_ids': userIds, 'permission': permission});
  }

  @override
  Future<ServiceResponse<List<SharedHabitItem>>> getSharedHabits() async {
    final r = await BaseApiService.get<Map<String, dynamic>>('/habit-shares', requiresAuth: true);
    if (r.isSuccess && r.data != null) {
      final list = (r.data!['habit_shares'] as List? ?? [])
          .map((e) => SharedHabitItem.fromJson(e as Map<String, dynamic>))
          .toList();
      return ServiceResponse.success(statusCode: r.statusCode, data: list, message: r.message);
    }
    return ServiceResponse.error(statusCode: r.statusCode, message: r.message, errors: r.errors);
  }

  @override
  Future<ServiceResponse<List<ShareInvite>>> getHabitInvites() async {
    final r = await BaseApiService.get<Map<String, dynamic>>('/habit-shares/invites', requiresAuth: true);
    if (r.isSuccess && r.data != null) {
      final list = (r.data!['invites'] as List? ?? [])
          .map((e) => ShareInvite.fromJson(e as Map<String, dynamic>, 'habit'))
          .toList();
      return ServiceResponse.success(statusCode: r.statusCode, data: list, message: r.message);
    }
    return ServiceResponse.error(statusCode: r.statusCode, message: r.message, errors: r.errors);
  }

  @override
  Future<ServiceResponse<void>> acceptHabit(int id) =>
      BaseApiService.post<void>('/habit-shares/$id/accept', requiresAuth: true);
  @override
  Future<ServiceResponse<void>> rejectHabit(int id) =>
      BaseApiService.post<void>('/habit-shares/$id/reject', requiresAuth: true);
  @override
  Future<ServiceResponse<void>> leaveHabit(int id) =>
      BaseApiService.post<void>('/habit-shares/$id/leave', requiresAuth: true);

  @override
  Future<ServiceResponse<void>> deleteSharedHabit(int id) =>
      BaseApiService.delete<void>('/habit-shares/$id', requiresAuth: true);

  @override
  Future<ServiceResponse<void>> completeSharedHabit(int id, {String? date, bool completed = true}) {
    final body = <String, dynamic>{'completed': completed};
    if (date != null) body['date'] = date;
    return BaseApiService.post<void>('/habit-shares/$id/complete', requiresAuth: true, body: body);
  }

  @override
  Future<ServiceResponse<HabitHeatmap>> getHabitHeatmap(int id, {int days = 90}) {
    return BaseApiService.get<HabitHeatmap>('/habit-shares/$id/heatmap',
        queryParameters: {'days': '$days'},
        requiresAuth: true,
        fromJson: (j) => HabitHeatmap.fromJson(j as Map<String, dynamic>));
  }

  @override
  Future<ServiceResponse<ShareLockState>> lockHabit(int id) =>
      BaseApiService.post<ShareLockState>('/habit-shares/$id/lock',
          requiresAuth: true,
          fromJson: (j) => ShareLockState.fromJson(j as Map<String, dynamic>));
  @override
  Future<ServiceResponse<void>> unlockHabit(int id) =>
      BaseApiService.post<void>('/habit-shares/$id/unlock', requiresAuth: true);
}
