import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/design/app_design.dart';
import '../../../core/init/locator.dart';
import '../../../models/habit/shared_habit_models.dart';

const _accent = Color(0xFFF6A821);

/// Paylaşımlı alışkanlıklar ekranı: oluştur, kodla katıl, lider tablosu.
class SharedHabitsPage extends StatefulWidget {
  final bool isDark;
  const SharedHabitsPage({super.key, required this.isDark});

  @override
  State<SharedHabitsPage> createState() => _SharedHabitsPageState();
}

class _SharedHabitsPageState extends State<SharedHabitsPage> {
  bool _loading = true;
  List<SharedHabit> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await sharedHabitService.getMyShared();
    if (!mounted) return;
    setState(() {
      _items = r.isSuccess && r.data != null ? r.data! : [];
      _loading = false;
    });
  }

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _createFlow() async {
    final ctrl = TextEditingController();
    final c = AppColors(widget.isDark);
    final title = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.card,
        title: Text('habits.shared.createTitle'.tr(),
            style: TextStyle(color: c.textPrimary)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: TextStyle(color: c.textPrimary),
          decoration: InputDecoration(hintText: 'habits.shared.titleHint'.tr()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('common.cancel'.tr())),
          TextButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: Text('common.save'.tr())),
        ],
      ),
    );
    if (title == null || title.isEmpty) return;
    final r = await sharedHabitService.create(SharedHabitRequest(title: title));
    if (r.isSuccess && r.data != null) {
      await _load();
      if (mounted) _showJoinCode(r.data!);
    } else {
      _toast(r.errorMessage);
    }
  }

  Future<void> _joinFlow() async {
    final ctrl = TextEditingController();
    final c = AppColors(widget.isDark);
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.card,
        title: Text('habits.shared.joinTitle'.tr(),
            style: TextStyle(color: c.textPrimary)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          style: TextStyle(color: c.textPrimary),
          decoration: InputDecoration(hintText: 'habits.shared.codeHint'.tr()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('common.cancel'.tr())),
          TextButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: Text('habits.shared.join'.tr())),
        ],
      ),
    );
    if (code == null || code.isEmpty) return;
    final r = await sharedHabitService.joinByCode(code);
    if (r.isSuccess) {
      _toast('habits.shared.joined'.tr());
      await _load();
    } else {
      _toast(r.errorMessage);
    }
  }

  void _showJoinCode(SharedHabit sh) {
    final c = AppColors(widget.isDark);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.card,
        title: Text('habits.shared.created'.tr(),
            style: TextStyle(color: c.textPrimary, fontSize: 16)),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SelectableText(sh.joinCode ?? '-',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                    color: _accent)),
            const SizedBox(width: 10),
            IconButton(
              icon: Icon(Icons.copy_rounded, color: c.textSecondary),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: sh.joinCode ?? ''));
                _toast('habits.shared.codeCopied'.tr());
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Share.share(
                '${sh.title}\n${'habits.shared.joinCode'.tr()}: ${sh.joinCode}'),
            child: Text('habits.shared.shareBtn'.tr()),
          ),
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('habits.shared.ok'.tr())),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors(widget.isDark);
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        elevation: 0,
        foregroundColor: c.textPrimary,
        title: Text('habits.shared.title'.tr(),
            style: TextStyle(
                color: c.textPrimary, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add_rounded, color: _accent),
            tooltip: 'habits.shared.join'.tr(),
            onPressed: _joinFlow,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text('habits.shared.create'.tr()),
        onPressed: _createFlow,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? _empty(c)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _card(c, _items[i]),
                  ),
                ),
    );
  }

  Widget _empty(AppColors c) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.groups_rounded, size: 54, color: _accent.withOpacity(0.6)),
            const SizedBox(height: 14),
            Text('habits.shared.empty'.tr(),
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary)),
            const SizedBox(height: 6),
            Text('habits.shared.emptySub'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, color: c.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _card(AppColors c, SharedHabit sh) {
    return GestureDetector(
      onTap: () => _openDetail(sh),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.border.withOpacity(0.7)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                  color: _accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.groups_rounded, color: _accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sh.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: c.textPrimary)),
                  const SizedBox(height: 3),
                  Text(
                      'habits.shared.participants'.tr(
                          namedArgs: {'n': '${sh.totalParticipants}'}),
                      style:
                          TextStyle(fontSize: 13, color: c.textSecondary)),
                ],
              ),
            ),
            if (sh.joinCode != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                    color: _accent.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(sh.joinCode!,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: _accent)),
              ),
          ],
        ),
      ),
    );
  }

  void _openDetail(SharedHabit sh) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SharedHabitDetailSheet(
          sharedHabit: sh, isDark: widget.isDark, onChanged: _load),
    );
  }
}

class _SharedHabitDetailSheet extends StatefulWidget {
  final SharedHabit sharedHabit;
  final bool isDark;
  final Future<void> Function() onChanged;
  const _SharedHabitDetailSheet(
      {required this.sharedHabit,
      required this.isDark,
      required this.onChanged});

  @override
  State<_SharedHabitDetailSheet> createState() =>
      _SharedHabitDetailSheetState();
}

class _SharedHabitDetailSheetState extends State<_SharedHabitDetailSheet> {
  bool _loading = true;
  List<SharedHabitParticipant> _board = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await sharedHabitService.getLeaderboard(widget.sharedHabit.id);
    if (!mounted) return;
    setState(() {
      _board = r.isSuccess && r.data != null ? r.data! : [];
      _loading = false;
    });
  }

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors(widget.isDark);
    final sh = widget.sharedHabit;
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
        decoration: BoxDecoration(
            color: c.card, borderRadius: BorderRadius.circular(22)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(sh.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: c.textPrimary)),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: c.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Text('habits.shared.leaderboard'.tr(),
                style: TextStyle(fontSize: 13.5, color: c.textSecondary)),
            const SizedBox(height: 12),
            if (_loading)
              const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Center(child: CircularProgressIndicator()))
            else if (_board.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text('habits.shared.noParticipants'.tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: c.textSecondary)),
              )
            else
              ...List.generate(_board.length, (i) => _boardRow(c, i, _board[i])),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final r =
                          await sharedHabitService.complete(sh.id);
                      if (r.isSuccess) {
                        _toast('success.habitCompleted'.tr());
                        await _load();
                        await widget.onChanged();
                      } else {
                        _toast(r.errorMessage);
                      }
                    },
                    icon: const Icon(Icons.check_rounded, size: 20),
                    label: Text('habits.shared.completeToday'.tr()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: () async {
                    final r = await sharedHabitService.leave(sh.id);
                    if (r.isSuccess) {
                      if (mounted) Navigator.pop(context);
                      await widget.onChanged();
                    } else {
                      _toast(r.errorMessage);
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE53E3E),
                    side: const BorderSide(color: Color(0xFFE53E3E)),
                    padding: const EdgeInsets.symmetric(
                        vertical: 13, horizontal: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('habits.shared.leave'.tr()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _boardRow(AppColors c, int rank, SharedHabitParticipant p) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 26,
            child: Text('${rank + 1}',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: rank == 0 ? _accent : c.textSecondary)),
          ),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
                shape: BoxShape.circle, color: _accent.withOpacity(0.15)),
            alignment: Alignment.center,
            child: Text(
                p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: _accent)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(p.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary)),
          ),
          Text(
              'habits.shared.completions'
                  .tr(namedArgs: {'n': '${p.totalCompletions}'}),
              style: TextStyle(fontSize: 13, color: c.textSecondary)),
        ],
      ),
    );
  }
}
