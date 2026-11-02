import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/init/locator.dart';
import '../../service/social/social_service.dart';
import '../../service/share/share_service.dart';
import '../../models/social/social_model.dart';
import '../../core/utils/custom_snackbar.dart';

/// Not/görev paylaşım alt sayfasını açar. Arkadaş listesi + izin seçimi.
/// [kind] = 'note' | 'task', [itemId] = paylaşılacak öğenin id'si.
Future<bool?> showShareWithFriendsSheet(
  BuildContext context, {
  required String kind,
  required int itemId,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ShareWithFriendsSheet(kind: kind, itemId: itemId),
  );
}

class _ShareWithFriendsSheet extends StatefulWidget {
  final String kind;
  final int itemId;
  const _ShareWithFriendsSheet({required this.kind, required this.itemId});

  @override
  State<_ShareWithFriendsSheet> createState() => _ShareWithFriendsSheetState();
}

class _ShareWithFriendsSheetState extends State<_ShareWithFriendsSheet> {
  final _social = locator.get<ISocialService>();
  final _share = locator.get<IShareService>();

  bool _loading = true;
  bool _sharing = false;
  List<Friend> _friends = [];
  final Set<int> _selected = {};
  String _permission = 'edit';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await _social.getFriends();
    if (!mounted) return;
    setState(() {
      _friends = r.isSuccess && r.data != null ? r.data! : [];
      _loading = false;
    });
  }

  Future<void> _doShare() async {
    if (_selected.isEmpty || _sharing) return;
    setState(() => _sharing = true);
    final ids = _selected.toList();
    final r = widget.kind == 'task'
        ? await _share.shareTask(widget.itemId, ids, _permission)
        : widget.kind == 'habit'
            ? await _share.shareHabit(widget.itemId, ids, _permission)
            : await _share.shareNote(widget.itemId, ids, _permission);
    if (!mounted) return;
    setState(() => _sharing = false);
    if (r.isSuccess) {
      CustomSnackBar.showSuccess(context, 'share.shared'.tr());
      Navigator.pop(context, true);
    } else {
      CustomSnackBar.showError(context, 'share.shareFailed'.tr());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E1B16) : const Color(0xFFF6F4EF);
    final card = isDark ? const Color(0xFF2A251E) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF3A3326);
    final textMuted = isDark ? Colors.white60 : const Color(0xFF8A7A5E);
    const accent = Color(0xFFF6A821);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
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
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
              child: Row(
                children: [
                  const Icon(Icons.group_add_rounded, color: accent),
                  const SizedBox(width: 10),
                  Text('share.shareWithFriend'.tr(),
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: textPrimary)),
                ],
              ),
            ),
            // İzin seçimi
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
              child: Row(
                children: [
                  _permPill('edit', 'share.canEdit'.tr(), Icons.edit_rounded,
                      accent, card, textPrimary, textMuted),
                  const SizedBox(width: 8),
                  _permPill('view', 'share.viewOnly'.tr(),
                      Icons.visibility_rounded, accent, card, textPrimary,
                      textMuted),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('share.selectFriends'.tr(),
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textMuted)),
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: accent))
                  : _friends.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(28),
                            child: Text('share.noFriends'.tr(),
                                textAlign: TextAlign.center,
                                style: TextStyle(color: textMuted, height: 1.4)),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          itemCount: _friends.length,
                          itemBuilder: (_, i) {
                            final f = _friends[i];
                            final sel = _selected.contains(f.id);
                            final name = f.displayName.trim().isNotEmpty
                                ? f.displayName
                                : f.username;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Material(
                                color: card,
                                borderRadius: BorderRadius.circular(14),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: () => setState(() {
                                    if (sel) {
                                      _selected.remove(f.id);
                                    } else {
                                      _selected.add(f.id);
                                    }
                                  }),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 20,
                                          backgroundColor:
                                              accent.withOpacity(0.18),
                                          backgroundImage: (f.profilePictureUrl !=
                                                      null &&
                                                  f.profilePictureUrl!.isNotEmpty)
                                              ? NetworkImage(f.profilePictureUrl!)
                                              : null,
                                          child: (f.profilePictureUrl == null ||
                                                  f.profilePictureUrl!.isEmpty)
                                              ? Text(
                                                  name.isNotEmpty
                                                      ? name[0].toUpperCase()
                                                      : '?',
                                                  style: const TextStyle(
                                                      color: accent,
                                                      fontWeight:
                                                          FontWeight.w800))
                                              : null,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700,
                                                  color: textPrimary)),
                                        ),
                                        Icon(
                                          sel
                                              ? Icons.check_circle_rounded
                                              : Icons.circle_outlined,
                                          color: sel ? accent : textMuted,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 8, 20, MediaQuery.of(context).viewInsets.bottom + 14),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: (_selected.isEmpty || _sharing) ? null : _doShare,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: _sharing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send_rounded, size: 18),
                  label: Text(
                    _selected.isEmpty
                        ? 'share.shareBtn'.tr()
                        : '${'share.shareBtn'.tr()} (${_selected.length})',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _permPill(String value, String label, IconData icon, Color accent,
      Color card, Color textPrimary, Color textMuted) {
    final sel = _permission == value;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _permission = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: sel ? accent.withOpacity(0.15) : card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: sel ? accent : textMuted.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: sel ? accent : textMuted),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: sel ? accent : textPrimary)),
            ],
          ),
        ),
      ),
    );
  }
}
