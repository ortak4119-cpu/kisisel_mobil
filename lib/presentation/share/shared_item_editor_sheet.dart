import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/init/locator.dart';
import '../../service/share/share_service.dart';
import '../../models/share/shared_item_models.dart';
import '../../core/utils/custom_snackbar.dart';

const Color _accent = Color(0xFFF6A821);

Future<void> showSharedNoteEditor(BuildContext context,
    {required SharedNoteItem item}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SharedNoteEditor(item: item),
  );
}

Future<void> showSharedTaskEditor(BuildContext context,
    {required SharedTaskItem item}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SharedTaskEditor(item: item),
  );
}

// ---- Ortak renk/kabuk yardımcıları ----
class _Shell extends StatelessWidget {
  final Widget child;
  const _Shell({required this.child});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E1B16) : const Color(0xFFF6F4EF);
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: SafeArea(top: false, child: child),
    );
  }
}

Widget _handle(Color muted) => Center(
      child: Container(
        margin: const EdgeInsets.only(top: 10, bottom: 6),
        width: 38,
        height: 4,
        decoration: BoxDecoration(
            color: muted.withOpacity(0.4),
            borderRadius: BorderRadius.circular(2)),
      ),
    );

/// "X düzenliyor" canlı bilgi şeridi (başkası kilidi tutarken).
Widget _editingBanner(String text) => Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEF5350).withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEF5350).withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: Color(0xFFEF5350)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFD1584F))),
          ),
        ],
      ),
    );

Widget _sharedBadge(bool canEdit, Color muted) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: _accent.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.diversity_3_rounded, size: 14, color: _accent),
        const SizedBox(width: 5),
        Text(canEdit ? 'share.canEdit'.tr() : 'share.viewOnly'.tr(),
            style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFB07B18))),
      ]),
    );

// ======================= NOT ORTAK DÜZENLEYİCİ =======================
class _SharedNoteEditor extends StatefulWidget {
  final SharedNoteItem item;
  const _SharedNoteEditor({required this.item});
  @override
  State<_SharedNoteEditor> createState() => _SharedNoteEditorState();
}

class _SharedNoteEditorState extends State<_SharedNoteEditor> {
  final _share = locator.get<IShareService>();
  late final TextEditingController _title =
      TextEditingController(text: widget.item.note?.title ?? '');
  late final TextEditingController _content =
      TextEditingController(text: widget.item.note?.content ?? '');
  bool _saving = false;

  // Canlı tek-editör kilidi.
  ShareLockState? _lock;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.item.canEdit) {
      _acquire();
      _timer = Timer.periodic(const Duration(seconds: 8), (_) => _acquire());
    }
  }

  Future<void> _acquire() async {
    final r = await _share.lockNote(widget.item.id);
    if (!mounted) return;
    if (r.isSuccess && r.data != null) setState(() => _lock = r.data);
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (_lock?.isMe == true) _share.unlockNote(widget.item.id);
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  // Düzenleyebilmek için: izin VAR + kilidi ben tutuyorum.
  bool get _hasPermission => widget.item.canEdit;
  bool get _canEdit => _hasPermission && (_lock?.acquired ?? false);
  bool get _lockedByOther => _lock?.lockedByOther ?? false;

  Future<void> _save() async {
    if (_saving || !_canEdit) return;
    setState(() => _saving = true);
    final r = await _share.updateSharedNote(widget.item.id,
        title: _title.text.trim(), content: _content.text);
    if (!mounted) return;
    setState(() => _saving = false);
    if (r.isSuccess) {
      CustomSnackBar.showSuccess(context, 'common.saved'.tr());
      Navigator.pop(context);
    } else {
      CustomSnackBar.showError(context, r.errorMessage ?? 'errors.generic'.tr());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : const Color(0xFF3A3326);
    final muted = isDark ? Colors.white60 : const Color(0xFF8A7A5E);
    final card = isDark ? const Color(0xFF2A251E) : Colors.white;

    return _Shell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _handle(muted),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 12, 4),
            child: Row(
              children: [
                _sharedBadge(_canEdit, muted),
                const Spacer(),
                if (_canEdit)
                  TextButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.check_rounded, color: _accent),
                    label: Text('common.save'.tr(),
                        style: const TextStyle(
                            color: _accent, fontWeight: FontWeight.w800)),
                  ),
                IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, color: muted)),
              ],
            ),
          ),
          if (_lockedByOther)
            _editingBanner(
                'share.editing'.tr(namedArgs: {'name': _lock?.editorName ?? ''}))
          else if (!_hasPermission)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
              child: Text('share.viewerCannotEdit'.tr(),
                  style: TextStyle(fontSize: 12, color: muted)),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: card, borderRadius: BorderRadius.circular(18)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _title,
                      enabled: _canEdit,
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: textPrimary),
                      decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'notes.noteTitle'.tr(),
                          hintStyle: TextStyle(color: muted)),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _content,
                      enabled: _canEdit,
                      maxLines: null,
                      minLines: 8,
                      style: TextStyle(
                          fontSize: 15, height: 1.5, color: textPrimary),
                      decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'notes.editor.startWriting'.tr(),
                          hintStyle: TextStyle(color: muted)),
                    ),
                    const SizedBox(height: 16),
                    _participantsRow(widget.item.participants, muted),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ======================= GÖREV ORTAK DÜZENLEYİCİ =======================
class _SharedTaskEditor extends StatefulWidget {
  final SharedTaskItem item;
  const _SharedTaskEditor({required this.item});
  @override
  State<_SharedTaskEditor> createState() => _SharedTaskEditorState();
}

class _SharedTaskEditorState extends State<_SharedTaskEditor> {
  final _share = locator.get<IShareService>();
  late final TextEditingController _title =
      TextEditingController(text: widget.item.task?.title ?? '');
  late final TextEditingController _desc =
      TextEditingController(text: widget.item.task?.description ?? '');
  bool _saving = false;
  bool _toggling = false;

  ShareLockState? _lock;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.item.canEdit) {
      _acquire();
      _timer = Timer.periodic(const Duration(seconds: 8), (_) => _acquire());
    }
  }

  Future<void> _acquire() async {
    final r = await _share.lockTask(widget.item.id);
    if (!mounted) return;
    if (r.isSuccess && r.data != null) setState(() => _lock = r.data);
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (_lock?.isMe == true) _share.unlockTask(widget.item.id);
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  bool get _hasPermission => widget.item.canEdit;
  bool get _canEdit => _hasPermission && (_lock?.acquired ?? false);
  bool get _lockedByOther => _lock?.lockedByOther ?? false;

  Future<void> _save() async {
    if (_saving || !_canEdit) return;
    setState(() => _saving = true);
    final r = await _share.updateSharedTask(widget.item.id,
        title: _title.text.trim(), description: _desc.text);
    if (!mounted) return;
    setState(() => _saving = false);
    if (r.isSuccess) {
      CustomSnackBar.showSuccess(context, 'common.saved'.tr());
    } else {
      CustomSnackBar.showError(context, r.errorMessage ?? 'errors.generic'.tr());
    }
  }

  Future<void> _toggleComplete(bool v) async {
    if (_toggling) return;
    setState(() => _toggling = true);
    final r = await _share.completeSharedTask(widget.item.id, v);
    if (!mounted) return;
    setState(() => _toggling = false);
    if (r.isSuccess) {
      CustomSnackBar.showSuccess(context, 'common.saved'.tr());
      Navigator.pop(context);
    } else {
      CustomSnackBar.showError(context, r.errorMessage ?? 'errors.generic'.tr());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : const Color(0xFF3A3326);
    final muted = isDark ? Colors.white60 : const Color(0xFF8A7A5E);
    final card = isDark ? const Color(0xFF2A251E) : Colors.white;

    return _Shell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _handle(muted),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 12, 4),
            child: Row(
              children: [
                _sharedBadge(_canEdit, muted),
                const Spacer(),
                if (_canEdit)
                  TextButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.check_rounded, color: _accent),
                    label: Text('common.save'.tr(),
                        style: const TextStyle(
                            color: _accent, fontWeight: FontWeight.w800)),
                  ),
                IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, color: muted)),
              ],
            ),
          ),
          if (_lockedByOther)
            _editingBanner(
                'share.editing'.tr(namedArgs: {'name': _lock?.editorName ?? ''})),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: card, borderRadius: BorderRadius.circular(18)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _title,
                      enabled: _canEdit,
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: textPrimary),
                      decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'tasks.title'.tr(),
                          hintStyle: TextStyle(color: muted)),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _desc,
                      enabled: _canEdit,
                      maxLines: null,
                      minLines: 3,
                      style: TextStyle(fontSize: 15, height: 1.5, color: textPrimary),
                      decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'tasks.description'.tr(),
                          hintStyle: TextStyle(color: muted)),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _toggling ? null : () => _toggleComplete(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF34C759),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.check_circle_rounded, size: 18),
                        label: Text('share.completed'.tr(),
                            style: const TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _sectionLabel('share.participants'.tr(), muted),
                    const SizedBox(height: 8),
                    ...widget.item.participants.map((p) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: _accent.withOpacity(0.18),
                                child: Text(
                                    p.name.isNotEmpty
                                        ? p.name[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFFB07B18))),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(p.name,
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: textPrimary)),
                              ),
                              Icon(
                                p.isCompleted
                                    ? Icons.check_circle_rounded
                                    : Icons.radio_button_unchecked_rounded,
                                size: 18,
                                color: p.isCompleted
                                    ? const Color(0xFF34C759)
                                    : muted,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                p.isCompleted
                                    ? 'share.completed'.tr()
                                    : 'share.notCompleted'.tr(),
                                style: TextStyle(fontSize: 12, color: muted),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String t, Color muted) => Text(t,
      style: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w800, color: muted));
}

// Ortak katılımcı satırı (not düzenleyici için).
Widget _participantsRow(List<SharedParticipant> participants, Color muted) {
  final accepted = participants.where((p) => p.status == 'accepted').toList();
  if (accepted.isEmpty) return const SizedBox.shrink();
  return Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final p in accepted)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
              color: _accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.person_rounded, size: 13, color: _accent),
            const SizedBox(width: 5),
            Text(p.name,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFB07B18))),
          ]),
        ),
    ],
  );
}
