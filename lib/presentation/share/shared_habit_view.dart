import 'package:flutter/material.dart';
import '../../core/utils/color_constant.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/init/locator.dart';
import '../../service/share/share_service.dart';
import '../../models/share/shared_item_models.dart';
import '../../core/utils/custom_snackbar.dart';

Color get _accent => ColorConstant.accentOrange;

/// Paylaşımlı alışkanlık detayı: ortak ısı haritası (her katılımcı görünür) +
/// bugünü tamamla. Tam sayfa açılır.
Future<void> showSharedHabitView(BuildContext context,
    {required SharedHabitItem item}) {
  return Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => _SharedHabitView(item: item),
  ));
}

class _SharedHabitView extends StatefulWidget {
  final SharedHabitItem item;
  const _SharedHabitView({required this.item});
  @override
  State<_SharedHabitView> createState() => _SharedHabitViewState();
}

class _SharedHabitViewState extends State<_SharedHabitView> {
  final _share = locator.get<IShareService>();
  HabitHeatmap? _heatmap;
  bool _loading = true;
  bool _completing = false;

  static const int _spanDays = 84; // ~12 hafta

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await _share.getHabitHeatmap(widget.item.id, days: _spanDays);
    if (!mounted) return;
    setState(() {
      _heatmap = r.data;
      _loading = false;
    });
  }

  Future<void> _completeToday() async {
    if (_completing) return;
    setState(() => _completing = true);
    final r = await _share.completeSharedHabit(widget.item.id);
    if (!mounted) return;
    setState(() => _completing = false);
    if (r.isSuccess) {
      CustomSnackBar.showSuccess(context, 'share.completed'.tr());
      _load();
    } else {
      CustomSnackBar.showError(context, r.errorMessage ?? 'errors.generic'.tr());
    }
  }

  List<String> _lastDates() {
    final now = DateTime.now();
    final out = <String>[];
    for (int i = _spanDays - 1; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      out.add(
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}');
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? ColorConstant.bgColorDark : ColorConstant.bgColorLight;
    final card = isDark ? ColorConstant.cardColorDark : ColorConstant.cardColorLight;
    final textPrimary = isDark ? ColorConstant.textPrimaryDark : ColorConstant.textPrimaryLight;
    final textMuted = isDark ? ColorConstant.textMutedDark : ColorConstant.textMutedLight;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        foregroundColor: textPrimary,
        title: Text(widget.item.habit?.title ?? '—',
            style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary)),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: _accent))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                // Bugünü tamamla
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _completing ? null : _completeToday,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF34C759),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: _completing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_circle_rounded, size: 18),
                    label: Text('share.completed'.tr(),
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(height: 18),
                Text('share.participants'.tr(),
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: textMuted)),
                const SizedBox(height: 10),
                ...(_heatmap?.users ?? []).map((u) => _userHeatmap(
                    u, card, textPrimary, textMuted)),
              ],
            ),
    );
  }

  Widget _userHeatmap(HabitHeatmapUser u, Color card, Color textPrimary,
      Color textMuted) {
    final dates = _lastDates();
    final total = u.dates.length;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration:
          BoxDecoration(color: card, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: _accent.withOpacity(0.18),
                child: Text(
                    u.name.isNotEmpty ? u.name[0].toUpperCase() : '?',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: ColorConstant.accentInk)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(u.name,
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: textPrimary)),
              ),
              Text('$total ✓',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: textMuted)),
            ],
          ),
          const SizedBox(height: 10),
          // Haftalara bölünmüş ızgara (sütun = hafta, satır = gün).
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (int w = 0; w < (dates.length / 7).ceil(); w++)
                  Padding(
                    padding: const EdgeInsets.only(right: 3),
                    child: Column(
                      children: [
                        for (int d = 0; d < 7; d++)
                          Builder(builder: (_) {
                            final idx = w * 7 + d;
                            if (idx >= dates.length) {
                              return const SizedBox(width: 12, height: 12);
                            }
                            final filled = u.dates.contains(dates[idx]);
                            return Container(
                              width: 12,
                              height: 12,
                              margin: const EdgeInsets.only(bottom: 3),
                              decoration: BoxDecoration(
                                color: filled
                                    ? const Color(0xFF34C759)
                                    : textMuted.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
