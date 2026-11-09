import 'package:easy_localization/easy_localization.dart';
import '../note/note_models.dart';
import '../task/task_models.dart';
import '../habit/habit_models.dart';

/// Paylaşımlı bir öğenin katılımcısı (arkadaş).
class SharedParticipant {
  final int id;
  final int userId;
  final String? username;
  final String? displayName;
  final String? profilePictureUrl;
  final String permission; // 'edit' | 'view'
  final String status; // 'pending' | 'accepted' | 'rejected'
  final bool isCompleted; // sadece paylaşımlı görevlerde anlamlı
  final DateTime? completedAt;

  SharedParticipant({
    required this.id,
    required this.userId,
    this.username,
    this.displayName,
    this.profilePictureUrl,
    this.permission = 'edit',
    this.status = 'pending',
    this.isCompleted = false,
    this.completedAt,
  });

  String get name =>
      (displayName != null && displayName!.trim().isNotEmpty)
          ? displayName!
          : (username ?? 'common.user'.tr());

  factory SharedParticipant.fromJson(Map<String, dynamic> j) {
    final user = j['user'] as Map<String, dynamic>?;
    return SharedParticipant(
      id: j['id'] as int? ?? 0,
      userId: j['user_id'] as int? ?? (user?['id'] as int? ?? 0),
      username: user?['username'] as String?,
      displayName: user?['display_name'] as String?,
      profilePictureUrl: user?['profile_picture_url'] as String?,
      permission: j['permission'] as String? ?? 'edit',
      status: j['status'] as String? ?? 'pending',
      isCompleted: (j['is_completed'] as bool?) ??
          ((j['is_completed'] as int?) == 1),
      completedAt: j['completed_at'] != null
          ? DateTime.tryParse(j['completed_at'].toString())
          : null,
    );
  }
}

/// Basit kullanıcı özeti (paylaşım sahibi vb.).
class ShareUser {
  final int id;
  final String? username;
  final String? displayName;
  final String? profilePictureUrl;
  ShareUser({
    required this.id,
    this.username,
    this.displayName,
    this.profilePictureUrl,
  });
  String get name => (displayName != null && displayName!.trim().isNotEmpty)
      ? displayName!
      : (username ?? 'common.user'.tr());
  factory ShareUser.fromJson(Map<String, dynamic> j) => ShareUser(
        id: j['id'] as int? ?? 0,
        username: j['username'] as String?,
        displayName: j['display_name'] as String?,
        profilePictureUrl: j['profile_picture_url'] as String?,
      );
}

/// Benimle ilgili bir paylaşımlı not.
class SharedNoteItem {
  final int id;
  final Note? note;
  final ShareUser? owner;
  final bool isOwner;
  final String myPermission; // 'edit' | 'view'
  final List<SharedParticipant> participants;

  SharedNoteItem({
    required this.id,
    this.note,
    this.owner,
    this.isOwner = false,
    this.myPermission = 'view',
    this.participants = const [],
  });

  bool get canEdit => myPermission == 'edit';

  factory SharedNoteItem.fromJson(Map<String, dynamic> j) => SharedNoteItem(
        id: j['id'] as int? ?? 0,
        note: j['note'] != null
            ? Note.fromJson(j['note'] as Map<String, dynamic>)
            : null,
        owner: j['owner'] != null
            ? ShareUser.fromJson(j['owner'] as Map<String, dynamic>)
            : null,
        isOwner: j['is_owner'] as bool? ?? false,
        myPermission: j['my_permission'] as String? ?? 'view',
        participants: ((j['participants'] as List?) ?? [])
            .map((e) => SharedParticipant.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Benimle ilgili bir paylaşımlı görev.
class SharedTaskItem {
  final int id;
  final Task? task;
  final ShareUser? owner;
  final bool isOwner;
  final String myPermission;
  final List<SharedParticipant> participants;

  SharedTaskItem({
    required this.id,
    this.task,
    this.owner,
    this.isOwner = false,
    this.myPermission = 'view',
    this.participants = const [],
  });

  bool get canEdit => myPermission == 'edit';

  factory SharedTaskItem.fromJson(Map<String, dynamic> j) => SharedTaskItem(
        id: j['id'] as int? ?? 0,
        task: j['task'] != null
            ? Task.fromJson(j['task'] as Map<String, dynamic>)
            : null,
        owner: j['owner'] != null
            ? ShareUser.fromJson(j['owner'] as Map<String, dynamic>)
            : null,
        isOwner: j['is_owner'] as bool? ?? false,
        myPermission: j['my_permission'] as String? ?? 'view',
        participants: ((j['participants'] as List?) ?? [])
            .map((e) => SharedParticipant.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Benimle ilgili bir paylaşımlı alışkanlık.
class SharedHabitItem {
  final int id;
  final Habit? habit;
  final ShareUser? owner;
  final bool isOwner;
  final String myPermission;
  final List<SharedParticipant> participants;

  SharedHabitItem({
    required this.id,
    this.habit,
    this.owner,
    this.isOwner = false,
    this.myPermission = 'view',
    this.participants = const [],
  });

  bool get canEdit => myPermission == 'edit';

  factory SharedHabitItem.fromJson(Map<String, dynamic> j) => SharedHabitItem(
        id: j['id'] as int? ?? 0,
        habit: j['habit'] != null
            ? Habit.fromJson(j['habit'] as Map<String, dynamic>)
            : null,
        owner: j['owner'] != null
            ? ShareUser.fromJson(j['owner'] as Map<String, dynamic>)
            : null,
        isOwner: j['is_owner'] as bool? ?? false,
        myPermission: j['my_permission'] as String? ?? 'view',
        participants: ((j['participants'] as List?) ?? [])
            .map((e) => SharedParticipant.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Ortak ısı haritası: her kullanıcının tamamladığı tarihler.
class HabitHeatmapUser {
  final int userId;
  final String name;
  final Set<String> dates; // 'yyyy-MM-dd'
  HabitHeatmapUser({required this.userId, required this.name, required this.dates});
  factory HabitHeatmapUser.fromJson(Map<String, dynamic> j) => HabitHeatmapUser(
        userId: j['user_id'] as int? ?? 0,
        name: j['name'] as String? ?? 'common.user'.tr(),
        dates: ((j['dates'] as List?) ?? []).map((e) => e.toString()).toSet(),
      );
}

class HabitHeatmap {
  final int days;
  final List<HabitHeatmapUser> users;
  HabitHeatmap({required this.days, required this.users});
  factory HabitHeatmap.fromJson(Map<String, dynamic> j) => HabitHeatmap(
        days: j['days'] as int? ?? 90,
        users: ((j['users'] as List?) ?? [])
            .map((e) => HabitHeatmapUser.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Canlı düzenleme kilidinin durumu.
class ShareLockState {
  final bool acquired; // kilidi ben aldım mı
  final int? editorId; // şu an düzenleyen kişi (null = serbest)
  final String? editorName;
  final bool isMe;
  final String? draftContent; // düzenleyenin canlı (kaydedilmemiş) taslağı

  ShareLockState({
    this.acquired = false,
    this.editorId,
    this.editorName,
    this.isMe = false,
    this.draftContent,
  });

  bool get lockedByOther => editorId != null && !isMe;

  factory ShareLockState.fromJson(Map<String, dynamic> j) => ShareLockState(
        acquired: j['acquired'] as bool? ?? false,
        editorId: j['editor_id'] as int?,
        editorName: j['editor_name'] as String?,
        isMe: j['is_me'] as bool? ?? false,
        draftContent: j['draft_content'] as String?,
      );
}

/// Bekleyen bir paylaşım daveti (not veya görev).
class ShareInvite {
  final int id; // shared_note_id / shared_task_id
  final String title;
  final String ownerName;
  final String kind; // 'note' | 'task'

  ShareInvite({
    required this.id,
    required this.title,
    required this.ownerName,
    required this.kind,
  });

  /// invites uçlarından gelen participant kaydından üretir.
  factory ShareInvite.fromJson(Map<String, dynamic> j, String kind) {
    final shared = (j['shared_note'] ?? j['shared_task']) as Map<String, dynamic>?;
    final inner = (shared?['note'] ?? shared?['task']) as Map<String, dynamic>?;
    final owner = shared?['owner'] as Map<String, dynamic>?;
    final ownerName = owner != null
        ? ((owner['display_name'] as String?)?.trim().isNotEmpty == true
            ? owner['display_name'] as String
            : (owner['username'] as String? ?? 'common.user'.tr()))
        : 'common.user'.tr();
    return ShareInvite(
      id: (shared?['id'] as int?) ??
          (j['shared_note_id'] as int?) ??
          (j['shared_task_id'] as int?) ??
          0,
      title: (inner?['title'] as String?) ?? '',
      ownerName: ownerName,
      kind: kind,
    );
  }
}
