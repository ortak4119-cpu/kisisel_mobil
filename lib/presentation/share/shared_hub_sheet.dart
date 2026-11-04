import 'package:flutter/material.dart';
import '../../core/utils/color_constant.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/init/locator.dart';
import '../../service/share/share_service.dart';
import '../../models/share/shared_item_models.dart';
import '../../core/utils/custom_snackbar.dart';
import 'shared_item_editor_sheet.dart';
import 'shared_habit_view.dart';

/// Paylaşım Merkezi: bekleyen davetler (kabul/ret) + benimle paylaşılanlar.
/// [kind] = 'note' | 'task'.
Future<void> showSharedHubSheet(BuildContext context,
    {required String kind}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SharedHubSheet(kind: kind),
  );
}

class _SharedHubSheet extends StatefulWidget {
  final String kind;
  const _SharedHubSheet({required this.kind});

  @override
  State<_SharedHubSheet> createState() => _SharedHubSheetState();
}

class _SharedHubSheetState extends State<_SharedHubSheet> {
  final _share = locator.get<IShareService>();
  bool _loading = true;
  List<ShareInvite> _invites = [];
  List<SharedNoteItem> _sharedNotes = [];
  List<SharedTaskItem> _sharedTasks = [];
  List<SharedHabitItem> _sharedHabits = [];

  bool get _isTask => widget.kind == 'task';
  bool get _isHabit => widget.kind == 'habit';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    if (_isHabit) {
      final inv = await _share.getHabitInvites();
      final sh = await _share.getSharedHabits();
      if (!mounted) return;
      setState(() {
        _invites = inv.data ?? [];
        _sharedHabits = sh.data ?? [];
        _loading = false;
      });
    } else if (_isTask) {
      final inv = await _share.getTaskInvites();
      final sh = await _share.getSharedTasks();
      if (!mounted) return;
      setState(() {
        _invites = inv.data ?? [];
        _sharedTasks = sh.data ?? [];
        _loading = false;
      });
    } else {
      final inv = await _share.getNoteInvites();
      final sh = await _share.getSharedNotes();
      if (!mounted) return;
      setState(() {
        _invites = inv.data ?? [];
        _sharedNotes = sh.data ?? [];
        _loading = false;
      });
    }
  }

  Future<void> _accept(int id) async {
    final r = _isHabit
        ? await _share.acceptHabit(id)
        : _isTask
            ? await _share.acceptTask(id)
            : await _share.acceptNote(id);
    if (!mounted) return;
    if (r.isSuccess) {
      CustomSnackBar.showSuccess(context, 'share.accept'.tr());
      _load();
    } else {
      CustomSnackBar.showError(context, r.errorMessage ?? 'share.shareFailed'.tr());
    }
  }

  Future<void> _reject(int id) async {
    final r = _isHabit
        ? await _share.rejectHabit(id)
        : _isTask
            ? await _share.rejectTask(id)
            : await _share.rejectNote(id);
    if (!mounted) return;
    if (r.isSuccess) _load();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? ColorConstant.bgColorDark : ColorConstant.bgColorLight;
    final card = isDark ? ColorConstant.cardColorDark : ColorConstant.cardColorLight;
    final textPrimary = isDark ? ColorConstant.textPrimaryDark : ColorConstant.textPrimaryLight;
    final textMuted = isDark ? ColorConstant.textMutedDark : ColorConstant.textMutedLight;
    final accent = ColorConstant.accentOrange;

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                    color: textMuted.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Row(
                children: [
                  Icon(Icons.diversity_3_rounded, color: accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('share.sharedWithMe'.tr(),
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: textPrimary)),
                  ),
                  IconButton(
                    onPressed: _load,
                    icon: Icon(Icons.refresh_rounded, color: textMuted),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? Center(child: CircularProgressIndicator(color: accent))
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      children: [
                        // --- Davetler ---
                        _sectionTitle('share.invites'.tr(), textMuted),
                        if (_invites.isEmpty)
                          _emptyRow('share.noInvites'.tr(), textMuted)
                        else
                          ..._invites.map((inv) => _inviteCard(
                              inv, card, textPrimary, textMuted, accent)),
                        const SizedBox(height: 14),
                        // --- Paylaşılanlar ---
                        _sectionTitle('share.sharedWithMe'.tr(), textMuted),
                        if (_isHabit)
                          (_sharedHabits.isEmpty
                              ? _emptyRow('share.noShared'.tr(), textMuted)
                              : Column(
                                  children: _sharedHabits
                                      .map((s) => _habitCard(s, card,
                                          textPrimary, textMuted, accent))
                                      .toList()))
                        else if (_isTask)
                          (_sharedTasks.isEmpty
                              ? _emptyRow('share.noShared'.tr(), textMuted)
                              : Column(
                                  children: _sharedTasks
                                      .map((s) => _taskCard(s, card,
                                          textPrimary, textMuted, accent))
                                      .toList()))
                        else
                          (_sharedNotes.isEmpty
                              ? _emptyRow('share.noShared'.tr(), textMuted)
                              : Column(
                                  children: _sharedNotes
                                      .map((s) => _noteCard(s, card,
                                          textPrimary, textMuted, accent))
                                      .toList())),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String t, Color muted) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
        child: Text(t,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w800, color: muted)),
      );

  Widget _emptyRow(String t, Color muted) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Text(t, style: TextStyle(color: muted)),
      );

  Widget _inviteCard(ShareInvite inv, Color card, Color textPrimary,
      Color textMuted, Color accent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: card, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Icon(
              _isHabit
                  ? Icons.local_fire_department_rounded
                  : _isTask
                      ? Icons.check_circle_outline_rounded
                      : Icons.description_rounded,
              color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(inv.title.isEmpty ? '—' : inv.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: textPrimary)),
                const SizedBox(height: 2),
                Text('share.sharedBy'.tr(namedArgs: {'name': inv.ownerName}),
                    style: TextStyle(fontSize: 12, color: textMuted)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _accept(inv.id),
            icon: const Icon(Icons.check_circle_rounded,
                color: Color(0xFF34C759)),
          ),
          IconButton(
            onPressed: () => _reject(inv.id),
            icon: const Icon(Icons.cancel_rounded, color: Color(0xFFEF5350)),
          ),
        ],
      ),
    );
  }

  Widget _noteCard(SharedNoteItem s, Color card, Color textPrimary,
      Color textMuted, Color accent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
          color: card, borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        onTap: () async {
          await showSharedNoteEditor(context, item: s);
          _load();
        },
        leading: Icon(Icons.description_rounded, color: accent),
        title: Text(s.note?.title ?? '—',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontWeight: FontWeight.w700, color: textPrimary)),
        subtitle: Text(
          '${s.isOwner ? 'share.youShared'.tr() : 'share.sharedBy'.tr(namedArgs: {
              'name': s.owner?.name ?? '—'
            })} · ${s.canEdit ? 'share.canEdit'.tr() : 'share.viewOnly'.tr()}',
          style: TextStyle(fontSize: 12, color: textMuted),
        ),
        trailing: _cardTrailing(s.participants, s.isOwner, s.id, accent, textMuted),
      ),
    );
  }

  Widget _taskCard(SharedTaskItem s, Color card, Color textPrimary,
      Color textMuted, Color accent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
          color: card, borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        onTap: () async {
          await showSharedTaskEditor(context, item: s);
          _load();
        },
        leading: Icon(Icons.check_circle_outline_rounded, color: accent),
        title: Text(s.task?.title ?? '—',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontWeight: FontWeight.w700, color: textPrimary)),
        subtitle: Text(
          '${s.isOwner ? 'share.youShared'.tr() : 'share.sharedBy'.tr(namedArgs: {
              'name': s.owner?.name ?? '—'
            })} · ${s.participants.where((p) => p.isCompleted).length}/${s.participants.length} ${'share.completed'.tr()}',
          style: TextStyle(fontSize: 12, color: textMuted),
        ),
        trailing: _cardTrailing(s.participants, s.isOwner, s.id, accent, textMuted),
      ),
    );
  }

  Widget _habitCard(SharedHabitItem s, Color card, Color textPrimary,
      Color textMuted, Color accent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
          color: card, borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        onTap: () async {
          await showSharedHabitView(context, item: s);
          _load();
        },
        leading: Icon(Icons.local_fire_department_rounded, color: accent),
        title: Text(s.habit?.title ?? '—',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontWeight: FontWeight.w700, color: textPrimary)),
        subtitle: Text(
          '${s.isOwner ? 'share.youShared'.tr() : 'share.sharedBy'.tr(namedArgs: {
              'name': s.owner?.name ?? '—'
            })} · ${s.participants.where((p) => p.status == 'accepted').length + 1} ${'share.participants'.tr()}',
          style: TextStyle(fontSize: 12, color: textMuted),
        ),
        trailing: _cardTrailing(s.participants, s.isOwner, s.id, accent, textMuted),
      ),
    );
  }

  // Paylaşan kişi (owner) için: katılımcı avatarları + "Paylaşımı bitir" menüsü.
  Widget _cardTrailing(List<SharedParticipant> participants, bool isOwner,
      int id, Color accent, Color muted) {
    final chips = _participantChips(participants, accent, muted);
    if (!isOwner) return chips;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        chips,
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert_rounded, color: muted),
          onSelected: (v) {
            if (v == 'end') _confirmEndShare(id);
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'end',
              child: Row(
                children: [
                  const Icon(Icons.link_off_rounded,
                      size: 18, color: Color(0xFFEF5350)),
                  const SizedBox(width: 10),
                  Text('share.endShare'.tr(),
                      style: const TextStyle(color: Color(0xFFEF5350))),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _confirmEndShare(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('share.endShare'.tr()),
        content: Text('share.endShareConfirm'.tr()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dctx, false),
              child: Text('common.cancel'.tr())),
          TextButton(
            onPressed: () => Navigator.pop(dctx, true),
            child: Text('share.endShare'.tr(),
                style: const TextStyle(
                    color: Color(0xFFEF5350), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final r = _isHabit
        ? await _share.deleteSharedHabit(id)
        : _isTask
            ? await _share.deleteSharedTask(id)
            : await _share.deleteSharedNote(id);
    if (!mounted) return;
    if (r.isSuccess) {
      CustomSnackBar.showSuccess(context, 'share.endShareDone'.tr());
      _load();
    } else {
      CustomSnackBar.showError(
          context, r.errorMessage ?? 'share.shareFailed'.tr());
    }
  }

  Widget _participantChips(
      List<SharedParticipant> participants, Color accent, Color muted) {
    final accepted =
        participants.where((p) => p.status == 'accepted').take(3).toList();
    if (accepted.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      width: 64,
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          for (int i = 0; i < accepted.length; i++)
            Positioned(
              right: i * 16.0,
              child: CircleAvatar(
                radius: 12,
                backgroundColor: accent.withOpacity(0.2),
                child: Text(
                  accepted[i].name.isNotEmpty
                      ? accepted[i].name[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: ColorConstant.accentInk),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
