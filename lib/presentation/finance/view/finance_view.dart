import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/design/app_design.dart';
import '../../../core/utils/color_constant.dart';
import '../../../core/utils/subscription_icons.dart';
import '../../../core/utils/premium_helper.dart';
import '../../../core/route/app_router.gr.dart';
import '../viewmodel/finance_viewmodel.dart';

// ==================== FİNANS KATEGORİLERİ & YARDIMCILAR ====================

class _FinCat {
  final String id;
  final String labelKey;
  final IconData icon;
  final Color color;
  const _FinCat(this.id, this.labelKey, this.icon, this.color);
}

const List<_FinCat> kFinCats = [
  _FinCat('market', 'finance.cat.market', Icons.shopping_cart_rounded,
      Color(0xFFF6A821)),
  _FinCat('bills', 'finance.cat.bills', Icons.description_rounded,
      Color(0xFF4C9AFF)),
  _FinCat('transport', 'finance.cat.transport', Icons.directions_bus_rounded,
      Color(0xFF48BB78)),
  _FinCat('health', 'finance.cat.health', Icons.favorite_rounded,
      Color(0xFFF6524B)),
  _FinCat('other', 'finance.cat.other', Icons.more_horiz_rounded,
      Color(0xFF9AA0A6)),
];

const List<_FinCat> kIncomeCats = [
  _FinCat('salary', 'finance.inc.salary', Icons.work_rounded,
      Color(0xFF48BB78)),
  _FinCat('freelance', 'finance.inc.freelance', Icons.laptop_mac_rounded,
      Color(0xFF4C9AFF)),
  _FinCat('investment', 'finance.inc.investment', Icons.trending_up_rounded,
      Color(0xFF9F7AEA)),
  _FinCat('gift', 'finance.inc.gift', Icons.card_giftcard_rounded,
      Color(0xFFED64A6)),
  _FinCat('other', 'finance.inc.other', Icons.more_horiz_rounded,
      Color(0xFF9AA0A6)),
];

_FinCat finCatById(String? id) {
  for (final c in kFinCats) {
    if (c.id == id) return c;
  }
  for (final c in kIncomeCats) {
    if (c.id == id) return c;
  }
  return kFinCats.last;
}

const _fOrange = Color(0xFFF6A821);

String tl(double v) {
  final neg = v < 0;
  v = v.abs();
  final s = v.toStringAsFixed(2);
  final parts = s.split('.');
  final intp = parts[0];
  final buf = StringBuffer();
  for (int i = 0; i < intp.length; i++) {
    if (i > 0 && (intp.length - i) % 3 == 0) buf.write('.');
    buf.write(intp[i]);
  }
  return '${neg ? '-' : ''}₺$buf,${parts[1]}';
}

String tl0(double v) {
  final s = v.abs().toStringAsFixed(0);
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return '₺$buf';
}

/// Gider/gelir ekleme formunu açar.
void showFinanceFormSheet(BuildContext context, FinanceViewModel vm, bool isDark,
    {bool income = false}) {
  vm.resetFinanceForm(income: income);
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) =>
        _FinanceFormSheet(viewModel: vm, isDarkMode: isDark),
  );
}

class _DonutPainter extends CustomPainter {
  final List<MapEntry<Color, double>> segments;
  final double total;
  _DonutPainter(this.segments, this.total);
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final stroke = radius * 0.42;
    final rect = Rect.fromCircle(
        center: center, radius: radius - stroke / 2);
    var start = -1.5708; // -90°
    if (total <= 0) return;
    for (final s in segments) {
      final sweep = (s.value / total) * 6.28319;
      final paint = Paint()
        ..color = s.key
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, start, sweep - 0.03, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.segments != segments || old.total != total;
}

class FinanceView extends StatefulWidget {
  const FinanceView({super.key});

  @override
  State<FinanceView> createState() => _FinanceViewState();
}

class _FinanceViewState extends State<FinanceView> {
  double _subsMonthly(FinanceViewModel vm) {
    double t = 0;
    for (final s in vm.activeSubscriptions) {
      t += s.amount;
    }
    return t;
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FinanceViewModel()..refreshAll(),
      child: Consumer<FinanceViewModel>(
        builder: (context, vm, _) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final c = AppColors(isDark);
          return Scaffold(
            backgroundColor: isDark
                ? ColorConstant.bgColorDark
                : ColorConstant.bgColorLight,
            body: SafeArea(
              bottom: false,
              child: vm.isInitialLoading
                  ? Center(child: CircularProgressIndicator(color: _fOrange))
                  : RefreshIndicator(
                      onRefresh: () => vm.refreshAll(),
                      color: _fOrange,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 130),
                        children: [
                          _header(context, vm, c),
                          const SizedBox(height: 16),
                          _balanceCard(vm, c),
                          const SizedBox(height: 14),
                          _actionButtons(context, vm, c),
                          const SizedBox(height: 16),
                          _budgetCard(context, vm, c),
                          const SizedBox(height: 14),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _monthExpensesCard(vm, c)),
                              const SizedBox(width: 12),
                              Expanded(child: _dailyAvgCard(vm, c)),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _distributionCard(context, vm, c),
                          const SizedBox(height: 14),
                          _subscriptionsCard(context, vm, c),
                          const SizedBox(height: 14),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                  flex: 3,
                                  child: _upcomingCard(context, vm, c)),
                              const SizedBox(width: 12),
                              Expanded(
                                  flex: 2,
                                  child: _savingsCard(context, vm, c)),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _transactionsCard(context, vm, c),
                        ],
                      ),
                    ),
            ),
            floatingActionButton: FloatingActionButton(
              heroTag: 'finance_fab',
              onPressed: () => showFinanceFormSheet(context, vm, isDark),
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFF6C23E), _fOrange],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: _fOrange.withOpacity(0.45),
                        blurRadius: 14,
                        offset: const Offset(0, 6)),
                  ],
                ),
                child: const Icon(Icons.add_rounded,
                    color: Colors.white, size: 30),
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------- Başlık ----------
  Widget _header(BuildContext context, FinanceViewModel vm, AppColors c) {
    final now = DateTime.now();
    final month = 'calendar.monthNames'.tr().split(',');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('finance.title'.tr(),
                  style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: c.textPrimary)),
              const SizedBox(height: 2),
              Text(
                  '${now.month <= month.length ? month[now.month - 1] : ''} ${now.year}',
                  style: TextStyle(fontSize: 14, color: c.textSecondary)),
            ],
          ),
        ),
        _iconBtn(c, Icons.notifications_none_rounded,
            () => _showUpcomingSheet(context, vm, c)),
        const SizedBox(width: 10),
        _iconBtn(c, Icons.settings_outlined,
            () => _showBudgetSettingsDialog(context, vm, c.isDark)),
      ],
    );
  }

  Widget _iconBtn(AppColors c, IconData icon, VoidCallback onTap) => Material(
        color: c.card,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: c.border.withOpacity(0.6))),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
              padding: const EdgeInsets.all(10),
              child: Icon(icon, size: 22, color: c.textSecondary)),
        ),
      );

  // ---------- Bakiye kartı ----------
  Widget _balanceCard(FinanceViewModel vm, AppColors c) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFFF6C23E), _fOrange],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
              color: _fOrange.withOpacity(0.35),
              blurRadius: 18,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('finance.availableBalance'.tr(),
                  style: const TextStyle(
                      fontSize: 14.5, color: Colors.white)),
              const SizedBox(width: 6),
              const Icon(Icons.remove_red_eye_outlined,
                  size: 16, color: Colors.white70),
            ],
          ),
          const SizedBox(height: 4),
          Text(tl(vm.availableBalance),
              style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: Colors.white)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                _balMini('finance.income'.tr(), tl0(vm.monthIncomeTotal),
                    const Color(0xFF48BB78)),
                _balDivider(),
                _balMini('finance.expense'.tr(),
                    tl0(vm.monthExpensesTotal), const Color(0xFFF6524B)),
                _balDivider(),
                _balMini('finance.savings'.tr(),
                    '%${vm.monthSavingsRate.round()}',
                    const Color(0xFFCFF6D8)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _balMini(String label, String value, Color dot) => Expanded(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                    width: 7,
                    height: 7,
                    decoration:
                        BoxDecoration(color: dot, shape: BoxShape.circle)),
                const SizedBox(width: 5),
                Text(label,
                    style: const TextStyle(
                        fontSize: 12.5, color: Colors.white)),
              ],
            ),
            const SizedBox(height: 3),
            Text(value,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
          ],
        ),
      );

  Widget _balDivider() => Container(
      width: 1, height: 34, color: Colors.white.withOpacity(0.25));

  // ---------- 3 aksiyon ----------
  Widget _actionButtons(
      BuildContext context, FinanceViewModel vm, AppColors c) {
    return Row(
      children: [
        Expanded(
          child: _actBtn(c, Icons.add_circle, 'finance.addExpense'.tr(),
              const Color(0xFFF6524B),
              () => showFinanceFormSheet(context, vm, c.isDark)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _actBtn(c, Icons.add_circle, 'finance.addIncome'.tr(),
              const Color(0xFF48BB78),
              () => showFinanceFormSheet(context, vm, c.isDark, income: true)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _actBtn(c, Icons.add_circle, 'finance.addSub'.tr(),
              const Color(0xFF9F7AEA),
              () => _showAddSubscriptionDialog(context, vm, c.isDark)),
        ),
      ],
    );
  }

  Widget _actBtn(AppColors c, IconData icon, String label, Color color,
      VoidCallback onTap) {
    return Material(
      color: c.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.border.withOpacity(0.7))),
          child: Column(
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 6),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: color)),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Aylık bütçe ----------
  Widget _budgetCard(BuildContext context, FinanceViewModel vm, AppColors c) {
    final b = vm.budgetStats;
    final budget = b?.monthlyBudget ?? 0;
    final spent = b?.totalSpent ?? vm.monthExpensesTotal;
    final pct = budget <= 0 ? 0.0 : (spent / budget).clamp(0.0, 1.0);
    final over = spent > budget && budget > 0;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border.withOpacity(0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('finance.monthlyBudget'.tr(),
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: c.textPrimary)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(children: [
                        TextSpan(
                            text: tl0(spent),
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: c.textPrimary)),
                        TextSpan(
                            text: ' / ${tl0(budget)}',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: c.textMuted)),
                      ]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                        'finance.remainingAmount'.tr(namedArgs: {
                          'amount': tl0((budget - spent).clamp(0, budget))
                        }),
                        style: TextStyle(fontSize: 13, color: c.textMuted)),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: pct.toDouble(),
                        minHeight: 8,
                        backgroundColor: _fOrange.withOpacity(0.15),
                        valueColor: AlwaysStoppedAnimation<Color>(
                            over ? const Color(0xFFF6524B) : _fOrange),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 76,
                height: 76,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 76,
                      height: 76,
                      child: CircularProgressIndicator(
                        value: pct.toDouble(),
                        strokeWidth: 8,
                        backgroundColor: c.border.withOpacity(0.4),
                        valueColor: AlwaysStoppedAnimation<Color>(
                            over ? const Color(0xFFF6524B) : _fOrange),
                      ),
                    ),
                    Text('%${(pct * 100).round()}',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: c.textPrimary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              if (pct >= 0.8)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                      color: _fOrange.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.warning_amber_rounded,
                        size: 14, color: _fOrange),
                    const SizedBox(width: 4),
                    Text(
                        'finance.limitWarn'.tr(namedArgs: {
                          'pct': '${(pct * 100).round()}'
                        }),
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _fOrange)),
                  ]),
                ),
              const Spacer(),
              GestureDetector(
                onTap: () =>
                    _showBudgetSettingsDialog(context, vm, c.isDark),
                child: Row(children: [
                  Text('finance.editBudget'.tr(),
                      style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: _fOrange)),
                  const Icon(Icons.chevron_right_rounded,
                      size: 18, color: _fOrange),
                ]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------- Bu ayki giderler (çubuk) ----------
  Widget _monthExpensesCard(FinanceViewModel vm, AppColors c) {
    final series = vm.dailyExpenseSeries;
    final maxV = series.fold<double>(
        1, (p, e) => e.value > p ? e.value : p);
    return Container(
      padding: const EdgeInsets.all(16),
      height: 176,
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.border.withOpacity(0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('finance.monthExpenses'.tr(),
              style: TextStyle(fontSize: 13, color: c.textSecondary)),
          const SizedBox(height: 4),
          Text(tl0(vm.monthExpensesTotal),
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: c.textPrimary)),
          const SizedBox(height: 10),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final e in series)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: (e.value / maxV * 46).clamp(3, 46),
                          margin:
                              const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                              color: const Color(0xFFF6524B)
                                  .withOpacity(0.85),
                              borderRadius: BorderRadius.circular(4)),
                        ),
                        const SizedBox(height: 3),
                        Text('${e.key.day}',
                            maxLines: 1,
                            style: TextStyle(
                                fontSize: 9.5, color: c.textMuted)),
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

  Widget _dailyAvgCard(FinanceViewModel vm, AppColors c) {
    const target = 500.0;
    final avg = vm.dailyAverage;
    final pct = (avg / target).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(16),
      height: 176,
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.border.withOpacity(0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('finance.dailyAvg'.tr(),
              style: TextStyle(fontSize: 13, color: c.textSecondary)),
          const SizedBox(height: 4),
          Text(tl0(avg),
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: c.textPrimary)),
          const SizedBox(height: 4),
          Text('finance.target'.tr(namedArgs: {'amount': tl0(target)}),
              style: TextStyle(fontSize: 12.5, color: c.textMuted)),
          const Spacer(),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct.toDouble(),
              minHeight: 8,
              backgroundColor: c.border.withOpacity(0.4),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF4C9AFF)),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Gider dağılımı (halka) ----------
  Widget _distributionCard(
      BuildContext context, FinanceViewModel vm, AppColors c) {
    final totals = vm.categoryTotals;
    final total = totals.values.fold<double>(0, (p, v) => p + v);
    final segs = <MapEntry<Color, double>>[];
    for (final cat in kFinCats) {
      final v = totals[cat.id] ?? 0;
      if (v > 0) segs.add(MapEntry(cat.color, v));
    }
    // Bilinmeyen kategoriler "diğer"e
    totals.forEach((k, v) {
      if (!kFinCats.any((cat) => cat.id == k) && v > 0) {
        segs.add(MapEntry(const Color(0xFF9AA0A6), v));
      }
    });
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border.withOpacity(0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('finance.distribution'.tr(),
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: c.textPrimary)),
              ),
              GestureDetector(
                onTap: () =>
                    _showMonthlyStatisticsDialog(context, vm, c.isDark),
                child: Text('finance.details'.tr(),
                    style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: _fOrange)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (total <= 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                  child: Text('finance.noExpenses'.tr(),
                      style: TextStyle(color: c.textMuted))),
            )
          else
            Row(
              children: [
                SizedBox(
                  width: 110,
                  height: 110,
                  child: CustomPaint(
                    painter: _DonutPainter(segs, total),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(tl0(total),
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: c.textPrimary)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      for (final cat in kFinCats)
                        if ((totals[cat.id] ?? 0) > 0)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(children: [
                              Container(
                                  width: 9,
                                  height: 9,
                                  decoration: BoxDecoration(
                                      color: cat.color,
                                      shape: BoxShape.circle)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(cat.labelKey.tr(),
                                    style: TextStyle(
                                        fontSize: 13.5,
                                        color: c.textSecondary)),
                              ),
                              Text(tl0(totals[cat.id]!),
                                  style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: c.textPrimary)),
                            ]),
                          ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ---------- Abonelikler ----------
  Widget _subscriptionsCard(
      BuildContext context, FinanceViewModel vm, AppColors c) {
    final subs = vm.activeSubscriptions;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border.withOpacity(0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('finance.subscriptions'.tr(),
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: c.textPrimary)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                    color: const Color(0xFF9F7AEA).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(
                    '${tl0(_subsMonthly(vm))} ${'finance.perMonth'.tr()}',
                    style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF9F7AEA))),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (subs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text('finance.noSubs'.tr(),
                  style: TextStyle(color: c.textMuted)),
            )
          else
            Row(
              children: [
                for (final s in subs.take(2)) ...[
                  Expanded(child: _subMini(s, c)),
                  const SizedBox(width: 12),
                ],
                if (subs.length < 2) const Expanded(child: SizedBox()),
              ],
            ),
          const SizedBox(height: 6),
          Divider(color: c.border.withOpacity(0.5)),
          Row(
            children: [
              Text(
                  'finance.activeSubs'.tr(namedArgs: {'n': '${subs.length}'}),
                  style: TextStyle(fontSize: 13, color: c.textMuted)),
              const Spacer(),
              GestureDetector(
                onTap: () =>
                    _showMonthlyStatisticsDialog(context, vm, c.isDark),
                child: Row(children: [
                  Text('finance.seeAll'.tr(),
                      style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF9F7AEA))),
                  const Icon(Icons.chevron_right_rounded,
                      size: 18, color: Color(0xFF9F7AEA)),
                ]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _subMini(dynamic s, AppColors c) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: c.bg, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                  color: const Color(0xFF9F7AEA).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(9)),
              child: const Icon(Icons.subscriptions_rounded,
                  size: 18, color: Color(0xFF9F7AEA)),
            ),
          ]),
          const SizedBox(height: 8),
          Text(s.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary)),
          Text('${tl(s.amount)} ${'finance.perMonth'.tr()}',
              style: TextStyle(fontSize: 12, color: c.textMuted)),
        ],
      ),
    );
  }

  // ---------- Yaklaşan ödemeler ----------
  Widget _upcomingCard(
      BuildContext context, FinanceViewModel vm, AppColors c) {
    final now = DateTime.now();
    final subs = vm.activeSubscriptions.toList()
      ..sort((a, b) => a.nextBillingDate.compareTo(b.nextBillingDate));
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border.withOpacity(0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('finance.upcoming'.tr(),
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: c.textPrimary)),
          const SizedBox(height: 12),
          if (subs.isEmpty)
            Text('finance.noUpcoming'.tr(),
                style: TextStyle(color: c.textMuted, fontSize: 13))
          else
            for (final s in subs.take(2)) ...[
              _upRow(s, now, c),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }

  Widget _upRow(dynamic s, DateTime now, AppColors c) {
    final days =
        s.nextBillingDate.difference(DateTime(now.year, now.month, now.day)).inDays;
    return Row(children: [
      Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
            color: _fOrange.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10)),
        child: const Icon(Icons.receipt_long_rounded,
            size: 18, color: _fOrange),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary)),
            Text(
                days <= 0
                    ? 'finance.dueToday'.tr()
                    : 'finance.daysLeft'.tr(namedArgs: {'n': '$days'}),
                style: TextStyle(fontSize: 11.5, color: c.textMuted)),
          ],
        ),
      ),
      Text(tl0(s.amount),
          style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: c.textPrimary)),
    ]);
  }

  // ---------- Tasarruf hedefi ----------
  Widget _savingsCard(
      BuildContext context, FinanceViewModel vm, AppColors c) {
    final pct = vm.savingsPercent.clamp(0, 100).toDouble();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border.withOpacity(0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('finance.savingsGoal'.tr(),
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: c.textPrimary)),
          Text(
              vm.savingsTitle.isEmpty
                  ? 'finance.savingsFund'.tr()
                  : vm.savingsTitle,
              style: TextStyle(fontSize: 12.5, color: c.textMuted)),
          const SizedBox(height: 10),
          Text(tl0(vm.savingsCurrent),
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: c.textPrimary)),
          Text('/ ${tl0(vm.savingsTarget)}',
              style: TextStyle(fontSize: 12.5, color: c.textMuted)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct / 100,
              minHeight: 8,
              backgroundColor: c.border.withOpacity(0.4),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF48BB78)),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _addSavingsDialog(context, vm, c),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                  color: const Color(0xFF48BB78).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12)),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.add_rounded, size: 18, color: Color(0xFF48BB78)),
                const SizedBox(width: 4),
                Text('finance.addMoney'.tr(),
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF48BB78))),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Son işlemler ----------
  Widget _transactionsCard(
      BuildContext context, FinanceViewModel vm, AppColors c) {
    final items = <_Txn>[];
    for (final e in vm.expenses) {
      items.add(_Txn(e.id, e.description ?? finCatById(e.category).labelKey.tr(),
          e.expenseDate, -e.amount, e.category, false));
    }
    for (final i in vm.income) {
      DateTime d;
      try {
        d = DateTime.parse(i.date);
      } catch (_) {
        d = DateTime.now();
      }
      items.add(_Txn(i.id, i.description ?? finCatById(i.category).labelKey.tr(),
          d, i.amount, i.category, true));
    }
    items.sort((a, b) => b.date.compareTo(a.date));
    final top = items.take(6).toList();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border.withOpacity(0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text('finance.recent'.tr(),
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: c.textPrimary)),
            ),
            GestureDetector(
              onTap: () => _showExpenseFilterDialog(context, vm, c.isDark),
              child: Icon(Icons.tune_rounded, size: 20, color: c.textMuted),
            ),
          ]),
          const SizedBox(height: 8),
          if (top.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                  child: Text('finance.noTxn'.tr(),
                      style: TextStyle(color: c.textMuted))),
            )
          else
            for (final t in top) _txnRow(context, vm, t, c),
        ],
      ),
    );
  }

  Widget _txnRow(
      BuildContext context, FinanceViewModel vm, _Txn t, AppColors c) {
    final cat = finCatById(t.category);
    final month = 'calendar.monthNames'.tr().split(',');
    return GestureDetector(
      onLongPress: () => showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: c.card,
          title: Text('finance.deleteExpense'.tr(),
              style: TextStyle(color: c.textPrimary)),
          content: Text(t.title, style: TextStyle(color: c.textSecondary)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('common.cancel'.tr())),
            TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  if (t.income) {
                    vm.deleteIncome(t.id);
                  } else {
                    vm.deleteExpense(t.id, context);
                  }
                },
                child: Text('common.delete'.tr(),
                    style: const TextStyle(color: Color(0xFFE53E3E)))),
          ],
        ),
      ),
      child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
              color: cat.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(11)),
          child: Icon(cat.icon, size: 20, color: cat.color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary)),
              Text(
                  '${t.date.day} ${t.date.month <= month.length ? month[t.date.month - 1] : ''} ${t.date.year}',
                  style: TextStyle(fontSize: 12, color: c.textMuted)),
            ],
          ),
        ),
        Text('${t.income ? '+' : '-'}${tl(t.amount.abs())}',
            style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: t.income
                    ? const Color(0xFF48BB78)
                    : const Color(0xFFF6524B))),
      ]),
    ),
    );
  }

  // ---------- Diyaloglar ----------
  void _addSavingsDialog(
      BuildContext context, FinanceViewModel vm, AppColors c) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.card,
        title: Text('finance.addMoney'.tr(),
            style: TextStyle(color: c.textPrimary)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: TextStyle(color: c.textPrimary),
          decoration: const InputDecoration(hintText: '0'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('common.cancel'.tr())),
          TextButton(
              onPressed: () {
                final v = double.tryParse(ctrl.text.replaceAll(',', '.'));
                if (v != null && v > 0) vm.addToSavings(v);
                Navigator.pop(ctx);
              },
              child: Text('common.save'.tr(),
                  style: const TextStyle(color: Color(0xFF48BB78)))),
        ],
      ),
    );
  }

  void _showUpcomingSheet(
      BuildContext context, FinanceViewModel vm, AppColors c) {
    final now = DateTime.now();
    final subs = vm.activeSubscriptions.toList()
      ..sort((a, b) => a.nextBillingDate.compareTo(b.nextBillingDate));
    showModalBottomSheet(
      context: context,
      backgroundColor: c.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('finance.upcoming'.tr(),
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: c.textPrimary)),
              const SizedBox(height: 12),
              if (subs.isEmpty)
                Text('finance.noUpcoming'.tr(),
                    style: TextStyle(color: c.textSecondary))
              else
                ...subs.take(8).map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: _upRow(s, now, c),
                    )),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Diğer sheet açıcılar (mevcut sheet'leri kullanır) ----------
  void _showAddSubscriptionDialog(
      BuildContext context, FinanceViewModel viewModel, bool isDarkMode) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddSubscriptionBottomSheet(
          viewModel: viewModel, isDarkMode: isDarkMode),
    );
  }

  void _showBudgetSettingsDialog(
      BuildContext context, FinanceViewModel viewModel, bool isDarkMode) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BudgetSettingsBottomSheet(
          viewModel: viewModel, isDarkMode: isDarkMode),
    );
  }

  void _showExpenseFilterDialog(
      BuildContext context, FinanceViewModel viewModel, bool isDarkMode) {
    showDialog(
      context: context,
      builder: (context) =>
          _ExpenseFilterDialog(viewModel: viewModel, isDarkMode: isDarkMode),
    );
  }

  void _showMonthlyStatisticsDialog(
      BuildContext context, FinanceViewModel viewModel, bool isDarkMode) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MonthlyStatisticsBottomSheet(
          viewModel: viewModel, isDarkMode: isDarkMode),
    );
  }
}

class _Txn {
  final int id;
  final String title;
  final DateTime date;
  final double amount;
  final String category;
  final bool income;
  _Txn(this.id, this.title, this.date, this.amount, this.category, this.income);
}

// ==================== BOTTOM SHEETS & DIALOGS ====================
// Bu kod parçasını finance_view.dart dosyasının sonuna ekleyin

class _AddSubscriptionBottomSheet extends StatelessWidget {
  final FinanceViewModel viewModel;
  final bool isDarkMode;

  const _AddSubscriptionBottomSheet({
    required this.viewModel,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: viewModel,
      child: Consumer<FinanceViewModel>(
        builder: (context, vm, _) {
          return Container(
            decoration: BoxDecoration(
              color: isDarkMode
                  ? ColorConstant.cardColorDark
                  : ColorConstant.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? ColorConstant.borderColorDark
                                  : ColorConstant.borderColorLight,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'finance.newSubscription'.tr(),
                          style: TextStyle(
                            color: isDarkMode
                                ? ColorConstant.textPrimaryDark
                                : ColorConstant.textPrimaryLight,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Logo Preview
                        ValueListenableBuilder<TextEditingValue>(
                          valueListenable: vm.subscriptionNameController,
                          builder: (context, value, child) {
                            final iconData =
                                SubscriptionIcons.getIcon(value.text) ??
                                    SubscriptionIcons.getDefaultIcon();

                            return Center(
                              child: Container(
                                width: 80,
                                height: 80,
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: isDarkMode
                                      ? ColorConstant.bgColorDark
                                      : ColorConstant.bgColorLight,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color:
                                        iconData.color.withValues(alpha: 0.3),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          iconData.color.withValues(alpha: 0.2),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: iconData.logoUrl != null
                                    ? SvgPicture.network(
                                        iconData.logoUrl!,
                                        colorFilter: ColorFilter.mode(
                                          iconData.color,
                                          BlendMode.srcIn,
                                        ),
                                        placeholderBuilder: (context) => Icon(
                                          iconData.icon,
                                          color: iconData.color,
                                          size: 40,
                                        ),
                                      )
                                    : Icon(
                                        iconData.icon,
                                        color: iconData.color,
                                        size: 40,
                                      ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: vm.subscriptionNameController,
                          style: TextStyle(
                            color: isDarkMode
                                ? ColorConstant.textPrimaryDark
                                : ColorConstant.textPrimaryLight,
                          ),
                          decoration: InputDecoration(
                            hintText: 'finance.hints.subscriptionName'.tr(),
                            hintStyle: TextStyle(
                              color: isDarkMode
                                  ? ColorConstant.textMutedDark
                                  : ColorConstant.textMutedLight,
                            ),
                            filled: true,
                            fillColor: isDarkMode
                                ? ColorConstant.bgColorDark
                                : ColorConstant.bgColorLight,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: vm.subscriptionAmountController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                            color: isDarkMode
                                ? ColorConstant.textPrimaryDark
                                : ColorConstant.textPrimaryLight,
                          ),
                          decoration: InputDecoration(
                            hintText: 'finance.hints.monthlyAmount'.tr(),
                            hintStyle: TextStyle(
                              color: isDarkMode
                                  ? ColorConstant.textMutedDark
                                  : ColorConstant.textMutedLight,
                            ),
                            filled: true,
                            fillColor: isDarkMode
                                ? ColorConstant.bgColorDark
                                : ColorConstant.bgColorLight,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: vm.subscriptionBillingDateController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                            color: isDarkMode
                                ? ColorConstant.textPrimaryDark
                                : ColorConstant.textPrimaryLight,
                          ),
                          decoration: InputDecoration(
                            hintText: 'finance.hints.paymentDay'.tr(),
                            hintStyle: TextStyle(
                              color: isDarkMode
                                  ? ColorConstant.textMutedDark
                                  : ColorConstant.textMutedLight,
                            ),
                            filled: true,
                            fillColor: isDarkMode
                                ? ColorConstant.bgColorDark
                                : ColorConstant.bgColorLight,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  vm.resetSubscriptionForm();
                                  Navigator.pop(context);
                                },
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  side: BorderSide(
                                    color: isDarkMode
                                        ? ColorConstant.borderColorDark
                                        : ColorConstant.borderColorLight,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  'common.cancel'.tr(),
                                  style: TextStyle(
                                    color: isDarkMode
                                        ? ColorConstant.textSecondaryDark
                                        : ColorConstant.textSecondaryLight,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => vm.createSubscription(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: ColorConstant.accentBlue,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  'finance.add'.tr(),
                                  style: TextStyle(
                                    color: ColorConstant.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCycleChip(
    BuildContext context,
    FinanceViewModel vm,
    String value,
    String label,
    bool isDarkMode,
  ) {
    final isSelected = vm.subscriptionBillingCycle == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => vm.setSubscriptionBillingCycle(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? ColorConstant.accentBlue.withValues(alpha: 0.15)
                : Colors.transparent,
            border: Border.all(
              color: isSelected
                  ? ColorConstant.accentBlue
                  : (isDarkMode
                      ? ColorConstant.borderColorDark
                      : ColorConstant.borderColorLight),
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected
                  ? ColorConstant.accentBlue
                  : (isDarkMode
                      ? ColorConstant.textSecondaryDark
                      : ColorConstant.textSecondaryLight),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _FinanceFormSheet extends StatelessWidget {
  final FinanceViewModel viewModel;
  final bool isDarkMode;
  const _FinanceFormSheet({
    required this.viewModel,
    required this.isDarkMode,
  });

  static const _accent = Color(0xFFF6A821);
  static const _red = Color(0xFFF6524B);
  static const _green = Color(0xFF48BB78);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: viewModel,
      child: Consumer<FinanceViewModel>(
        builder: (context, vm, _) {
          final c = AppColors(isDarkMode);
          final income = vm.isIncomeForm;
          final cats = income ? kIncomeCats : kFinCats;
          return Container(
            height: MediaQuery.of(context).size.height * 0.95,
            decoration: BoxDecoration(
              color: isDarkMode
                  ? ColorConstant.bgColorDark
                  : const Color(0xFFF6F4EF),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  _topBar(context, vm, c, income),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      children: [
                        _amount(vm, c, income),
                        const SizedBox(height: 14),
                        _typeToggle(vm, c),
                        const SizedBox(height: 16),
                        _descCategory(context, vm, c, cats, income),
                        const SizedBox(height: 16),
                        _detailsCard(context, vm, c, income),
                        if (!income) ...[
                          const SizedBox(height: 16),
                          _recurringCard(context, vm, c),
                          const SizedBox(height: 16),
                          _budgetImpact(vm, c),
                        ],
                        const SizedBox(height: 16),
                        _optionalCard(context, vm, c),
                      ],
                    ),
                  ),
                  _bottomBar(context, vm, c, income),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _topBar(
      BuildContext context, FinanceViewModel vm, AppColors c, bool income) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      child: Row(
        children: [
          Material(
            color: c.card,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: c.border.withOpacity(0.6))),
            child: InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                  padding: const EdgeInsets.all(9),
                  child: Icon(Icons.close_rounded,
                      size: 18, color: c.textSecondary)),
            ),
          ),
          Expanded(
            child: Text(
                income ? 'finance.newIncome'.tr() : 'finance.newExpense'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: c.textPrimary)),
          ),
          GestureDetector(
            onTap: () => vm.saveFinanceForm(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: Text('common.save'.tr(),
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: _accent)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _amount(FinanceViewModel vm, AppColors c, bool income) {
    return Column(
      children: [
        Text('finance.amount'.tr(),
            style: TextStyle(fontSize: 13, color: c.textMuted)),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('₺',
                style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: income ? _green : c.textPrimary)),
            const SizedBox(width: 4),
            IntrinsicWidth(
              child: TextField(
                controller: vm.expenseAmountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    color: income ? _green : c.textPrimary),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  hintText: '0,00',
                  hintStyle: TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                      color: c.textMuted.withOpacity(0.4)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: c.border.withOpacity(0.7))),
          child: Text('TRY ₺',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: c.textSecondary)),
        ),
      ],
    );
  }

  Widget _typeToggle(FinanceViewModel vm, AppColors c) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.border.withOpacity(0.7))),
      child: Row(children: [
        Expanded(
          child: GestureDetector(
            onTap: () => vm.setIsIncomeForm(false),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 11),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: !vm.isIncomeForm
                      ? _red.withOpacity(0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10)),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.trending_up_rounded,
                    size: 18,
                    color: !vm.isIncomeForm ? _red : c.textMuted),
                const SizedBox(width: 6),
                Text('finance.expense'.tr(),
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: !vm.isIncomeForm ? _red : c.textMuted)),
              ]),
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => vm.setIsIncomeForm(true),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 11),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: vm.isIncomeForm
                      ? _green.withOpacity(0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10)),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.trending_down_rounded,
                    size: 18,
                    color: vm.isIncomeForm ? _green : c.textMuted),
                const SizedBox(width: 6),
                Text('finance.income'.tr(),
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: vm.isIncomeForm ? _green : c.textMuted)),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _descCategory(BuildContext context, FinanceViewModel vm, AppColors c,
      List<_FinCat> cats, bool income) {
    return Container(
      decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.border.withOpacity(0.7))),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Row(children: [
              Icon(Icons.receipt_long_rounded, size: 22, color: c.textMuted),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: vm.expenseDescriptionController,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    labelText: 'finance.description'.tr(),
                    labelStyle: TextStyle(color: c.textMuted, fontSize: 13),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ]),
          ),
          Divider(height: 1, color: c.border.withOpacity(0.5)),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: Row(children: [
              Icon(Icons.sell_outlined, size: 22, color: c.textMuted),
              const SizedBox(width: 12),
              Text('finance.category'.tr(),
                  style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: finCatById(vm.formExpCategory)
                        .color
                        .withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(finCatById(vm.formExpCategory).labelKey.tr(),
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: finCatById(vm.formExpCategory).color)),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 4, 10, 12),
            child: Row(
              children: [
                for (final cat in cats)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => vm.setFormExpCategory(cat.id),
                      child: Container(
                        margin:
                            const EdgeInsets.symmetric(horizontal: 3),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: vm.formExpCategory == cat.id
                              ? cat.color.withOpacity(0.12)
                              : c.bg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: vm.formExpCategory == cat.id
                                  ? cat.color
                                  : Colors.transparent,
                              width: 1.5),
                        ),
                        child: Column(children: [
                          Icon(cat.icon,
                              size: 22,
                              color: vm.formExpCategory == cat.id
                                  ? cat.color
                                  : c.textSecondary),
                          const SizedBox(height: 5),
                          Text(cat.labelKey.tr(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: vm.formExpCategory == cat.id
                                      ? cat.color
                                      : c.textSecondary)),
                        ]),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailsCard(
      BuildContext context, FinanceViewModel vm, AppColors c, bool income) {
    final month = 'calendar.monthNames'.tr().split(',');
    final d = vm.formExpDate;
    return Container(
      decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.border.withOpacity(0.7))),
      child: Column(
        children: [
          _row(c, Icons.calendar_month_rounded, 'finance.date'.tr(),
              '${d.day} ${d.month <= month.length ? month[d.month - 1] : ''} ${d.year}',
              onTap: () async {
            final now = DateTime.now();
            final r = await showDatePicker(
                context: context,
                initialDate: d,
                firstDate: DateTime(now.year - 2),
                lastDate: DateTime(now.year + 2));
            if (r != null) vm.setFormExpDate(r);
          }),
          _div(c),
          _row(c, Icons.access_time_rounded, 'finance.time'.tr(),
              '${vm.formExpTime.hour.toString().padLeft(2, '0')}:${vm.formExpTime.minute.toString().padLeft(2, '0')}',
              onTap: () async {
            final t = await showTimePicker(
                context: context, initialTime: vm.formExpTime);
            if (t != null) vm.setFormExpTime(t);
          }),
          if (!income) ...[
            _div(c),
            _row(c, Icons.credit_card_rounded, 'finance.payMethod'.tr(),
                'finance.pay.${vm.formPayMethod}'.tr(),
                onTap: () => _pickOption(
                    context,
                    c,
                    'finance.payMethod'.tr(),
                    const ['card', 'cash', 'transfer'],
                    'finance.pay',
                    vm.formPayMethod,
                    vm.setFormPayMethod)),
            _div(c),
            _row(c, Icons.account_balance_wallet_rounded,
                'finance.account'.tr(), 'finance.acc.${vm.formAccount}'.tr(),
                onTap: () => _pickOption(
                    context,
                    c,
                    'finance.account'.tr(),
                    const ['daily', 'savings', 'credit'],
                    'finance.acc',
                    vm.formAccount,
                    vm.setFormAccount)),
          ],
        ],
      ),
    );
  }

  Widget _recurringCard(
      BuildContext context, FinanceViewModel vm, AppColors c) {
    final d = vm.formExpDate;
    final next = DateTime(d.year, d.month + 1, d.day);
    final month = 'calendar.monthNames'.tr().split(',');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text('finance.recurrence'.tr(),
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: c.textSecondary)),
        ),
        Container(
          decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: c.border.withOpacity(0.7))),
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                child: Row(children: [
                  const Icon(Icons.autorenew_rounded,
                      size: 22, color: _accent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('finance.regularExpense'.tr(),
                        style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w600,
                            color: c.textPrimary)),
                  ),
                  Switch(
                    value: vm.formRecurring,
                    activeColor: _accent,
                    onChanged: vm.setFormRecurring,
                  ),
                ]),
              ),
              if (vm.formRecurring) ...[
                _div(c),
                _row(c, Icons.repeat_rounded, 'finance.frequency'.tr(),
                    'finance.freq.${vm.formRecurPattern}'.tr(),
                    onTap: () => _pickOption(
                        context,
                        c,
                        'finance.frequency'.tr(),
                        const ['weekly', 'monthly', 'yearly'],
                        'finance.freq',
                        vm.formRecurPattern,
                        vm.setFormRecurPattern)),
                _div(c),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 14),
                  child: Row(children: [
                    const Icon(Icons.event_rounded, size: 22, color: _accent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('finance.nextPayment'.tr(),
                          style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w600,
                              color: c.textPrimary)),
                    ),
                    Text(
                        '${next.day} ${next.month <= month.length ? month[next.month - 1] : ''} ${next.year}',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: c.textSecondary)),
                  ]),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _budgetImpact(FinanceViewModel vm, AppColors c) {
    final b = vm.budgetStats;
    final budget = b?.monthlyBudget ?? 0;
    final spent = b?.totalSpent ?? vm.monthExpensesTotal;
    final amount =
        double.tryParse(vm.expenseAmountController.text.replaceAll(',', '.')) ??
            0;
    final after = spent + amount;
    final pct = budget <= 0 ? 0.0 : (after / budget).clamp(0.0, 1.0);
    final over = after > budget && budget > 0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: _accent.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _accent.withOpacity(0.3))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text('finance.budgetImpact'.tr(),
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: _accent)),
            ),
            Text('%${(pct * 100).round()}',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: _accent)),
          ]),
          const SizedBox(height: 6),
          Text(
              'finance.budgetLine'.tr(namedArgs: {
                'spent': tl0(after),
                'budget': tl0(budget)
              }),
              style: TextStyle(fontSize: 12.5, color: c.textSecondary)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct.toDouble(),
              minHeight: 8,
              backgroundColor: _accent.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(
                  over ? _red : _accent),
            ),
          ),
          if (over) ...[
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.warning_amber_rounded,
                  size: 15, color: _red),
              const SizedBox(width: 4),
              Text(
                  'finance.overLimit'.tr(namedArgs: {
                    'amount': tl0(after - budget)
                  }),
                  style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: _red)),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _optionalCard(BuildContext context, FinanceViewModel vm, AppColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text('finance.optional'.tr(),
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: c.textSecondary)),
        ),
        Container(
          decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: c.border.withOpacity(0.7))),
          child: Column(
            children: [
              // Etiketler
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(children: [
                  Icon(Icons.local_offer_outlined,
                      size: 22, color: c.textMuted),
                  const SizedBox(width: 12),
                  Text('finance.tags'.tr(),
                      style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                          color: c.textPrimary)),
                  const Spacer(),
                  for (int i = 0; i < vm.formTags.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: GestureDetector(
                        onTap: () => vm.removeFormTag(i),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                              color: _accent.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20)),
                          child: Text('#${vm.formTags[i]}',
                              style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: _accent)),
                        ),
                      ),
                    ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => _textInput(context, vm, 'finance.tags'.tr(),
                        '', (v) => vm.addFormTag(v)),
                    child: const Icon(Icons.add_rounded,
                        size: 20, color: _accent),
                  ),
                ]),
              ),
              _div(c),
              _row(c, Icons.notes_rounded, 'finance.note'.tr(),
                  vm.formNote ?? 'finance.addNote'.tr(),
                  onTap: () => _textInput(context, vm, 'finance.note'.tr(),
                      vm.formNote ?? '', vm.setFormNote)),
              _div(c),
              _row(c, Icons.place_outlined, 'finance.location'.tr(),
                  vm.formLocation ?? 'finance.addLocation'.tr(),
                  onTap: () => _textInput(context, vm,
                      'finance.location'.tr(), vm.formLocation ?? '',
                      vm.setFormLocation)),
              _div(c),
              // Fiş ekle
              Padding(
                padding: const EdgeInsets.all(12),
                child: vm.formReceipt == null
                    ? GestureDetector(
                        onTap: () => _receiptOptions(context, vm, c),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: c.border, width: 1.4),
                          ),
                          child: Column(children: [
                            const Icon(Icons.camera_alt_rounded,
                                size: 26, color: _accent),
                            const SizedBox(height: 6),
                            Text('finance.addReceipt'.tr(),
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: c.textPrimary)),
                          ]),
                        ),
                      )
                    : Stack(children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(vm.formReceipt!,
                              width: double.infinity,
                              height: 120,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                  height: 120,
                                  color: c.bg,
                                  child: Icon(Icons.insert_drive_file_rounded,
                                      color: c.textMuted))),
                        ),
                        Positioned(
                          top: 6,
                          right: 6,
                          child: GestureDetector(
                            onTap: vm.removeReceipt,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.close_rounded,
                                  size: 15, color: Colors.white),
                            ),
                          ),
                        ),
                      ]),
              ),
              _div(c),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                child: Row(children: [
                  Icon(Icons.notifications_none_rounded,
                      size: 22, color: c.textMuted),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('finance.paymentReminder'.tr(),
                        style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w600,
                            color: c.textPrimary)),
                  ),
                  Switch(
                    value: vm.formReminder,
                    activeColor: _accent,
                    onChanged: vm.setFormReminder,
                  ),
                ]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _bottomBar(
      BuildContext context, FinanceViewModel vm, AppColors c, bool income) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, 12 + MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: c.card,
        border: Border(top: BorderSide(color: c.border.withOpacity(0.5))),
      ),
      child: Row(children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: _accent.withOpacity(0.6)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: Text('tasks.discard'.tr(),
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _accent)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed:
                vm.isLoading ? null : () => vm.saveFinanceForm(context),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: _accent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.check_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                  income
                      ? 'finance.saveIncome'.tr()
                      : 'finance.saveExpense'.tr(),
                  style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
            ]),
          ),
        ),
      ]),
    );
  }

  // ---------- ortak ----------
  Widget _div(AppColors c) =>
      Divider(height: 1, thickness: 1, color: c.border.withOpacity(0.5), indent: 52);

  Widget _row(AppColors c, IconData icon, String label, String value,
      {required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(children: [
            Icon(icon, size: 22, color: _accent),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary)),
            ),
            Flexible(
              child: Text(value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: c.textSecondary)),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, size: 20, color: c.textMuted),
          ]),
        ),
      ),
    );
  }

  void _pickOption(BuildContext context, AppColors c, String title,
      List<String> opts, String prefix, String current,
      void Function(String) onPick) {
    showModalBottomSheet(
      context: context,
      backgroundColor: c.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 14),
          Text(title,
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: c.textPrimary)),
          const SizedBox(height: 6),
          for (final o in opts)
            ListTile(
              title: Text('$prefix.$o'.tr(),
                  style: TextStyle(color: c.textPrimary)),
              trailing: current == o
                  ? const Icon(Icons.check_rounded, color: _accent)
                  : null,
              onTap: () {
                onPick(o);
                Navigator.pop(ctx);
              },
            ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  void _receiptOptions(BuildContext context, FinanceViewModel vm, AppColors c) {
    showModalBottomSheet(
      context: context,
      backgroundColor: c.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.camera_alt_rounded, color: _accent),
            title: Text('finance.takePhoto'.tr(),
                style: TextStyle(color: c.textPrimary)),
            onTap: () {
              Navigator.pop(ctx);
              vm.pickReceiptImage(ImageSource.camera);
            },
          ),
          ListTile(
            leading:
                const Icon(Icons.photo_library_rounded, color: Color(0xFF4C9AFF)),
            title: Text('finance.chooseGallery'.tr(),
                style: TextStyle(color: c.textPrimary)),
            onTap: () {
              Navigator.pop(ctx);
              vm.pickReceiptImage(ImageSource.gallery);
            },
          ),
          ListTile(
            leading: const Icon(Icons.folder_rounded, color: Color(0xFFF6A821)),
            title: Text('finance.chooseFile'.tr(),
                style: TextStyle(color: c.textPrimary)),
            onTap: () {
              Navigator.pop(ctx);
              vm.pickReceiptFile();
            },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  void _textInput(BuildContext context, FinanceViewModel vm, String title,
      String initial, void Function(String) onDone) {
    final ctrl = TextEditingController(text: initial);
    final c = AppColors(isDarkMode);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.card,
        title: Text(title, style: TextStyle(color: c.textPrimary)),
        content: TextField(
            controller: ctrl,
            autofocus: true,
            style: TextStyle(color: c.textPrimary),
            decoration: InputDecoration(hintText: title)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('common.cancel'.tr())),
          TextButton(
              onPressed: () {
                onDone(ctrl.text);
                Navigator.pop(ctx);
              },
              child: Text('common.save'.tr(),
                  style: const TextStyle(color: _accent))),
        ],
      ),
    );
  }
}

class _BudgetSettingsBottomSheet extends StatelessWidget {
  final FinanceViewModel viewModel;
  final bool isDarkMode;

  const _BudgetSettingsBottomSheet({
    required this.viewModel,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: viewModel,
      child: Consumer<FinanceViewModel>(
        builder: (context, vm, _) {
          return Container(
            decoration: BoxDecoration(
              color: isDarkMode
                  ? ColorConstant.cardColorDark
                  : ColorConstant.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? ColorConstant.borderColorDark
                                  : ColorConstant.borderColorLight,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'finance.budgetSettings'.tr(),
                          style: TextStyle(
                            color: isDarkMode
                                ? ColorConstant.textPrimaryDark
                                : ColorConstant.textPrimaryLight,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: vm.budgetAmountController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                            color: isDarkMode
                                ? ColorConstant.textPrimaryDark
                                : ColorConstant.textPrimaryLight,
                          ),
                          decoration: InputDecoration(
                            labelText: 'finance.monthlyBudget'.tr(),
                            hintText: 'finance.hints.budgetExample'.tr(),
                            prefixText: '₺ ',
                            hintStyle: TextStyle(
                              color: isDarkMode
                                  ? ColorConstant.textMutedDark
                                  : ColorConstant.textMutedLight,
                            ),
                            filled: true,
                            fillColor: isDarkMode
                                ? ColorConstant.bgColorDark
                                : ColorConstant.bgColorLight,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  vm.resetBudgetForm();
                                  Navigator.pop(context);
                                },
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  side: BorderSide(
                                    color: isDarkMode
                                        ? ColorConstant.borderColorDark
                                        : ColorConstant.borderColorLight,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  'common.cancel'.tr(),
                                  style: TextStyle(
                                    color: isDarkMode
                                        ? ColorConstant.textSecondaryDark
                                        : ColorConstant.textSecondaryLight,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => vm.updateBudget(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: ColorConstant.accentGreen,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  'Kaydet',
                                  style: TextStyle(
                                    color: ColorConstant.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MonthlyStatisticsBottomSheet extends StatefulWidget {
  final FinanceViewModel viewModel;
  final bool isDarkMode;

  const _MonthlyStatisticsBottomSheet({
    required this.viewModel,
    required this.isDarkMode,
  });

  @override
  State<_MonthlyStatisticsBottomSheet> createState() =>
      _MonthlyStatisticsBottomSheetState();
}

class _MonthlyStatisticsBottomSheetState
    extends State<_MonthlyStatisticsBottomSheet> {
  final PageController _pageController = PageController(
    initialPage: DateTime.now().month - 1,
  );
  int _currentPage = DateTime.now().month - 1;

  @override
  void initState() {
    super.initState();
    // Load statistics after the first frame to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.viewModel.loadMonthlyStatistics();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.viewModel,
      child: Consumer<FinanceViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoadingStatistics) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: BoxDecoration(
                color: widget.isDarkMode
                    ? ColorConstant.cardColorDark
                    : ColorConstant.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: Center(
                child: CircularProgressIndicator(
                  color: ColorConstant.accentBlue,
                ),
              ),
            );
          }

          if (vm.monthlyStatistics == null) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: BoxDecoration(
                color: widget.isDarkMode
                    ? ColorConstant.cardColorDark
                    : ColorConstant.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: Center(
                child: Text(
                  'finance.noData'.tr(),
                  style: TextStyle(
                    color: widget.isDarkMode
                        ? ColorConstant.textSecondaryDark
                        : ColorConstant.textSecondaryLight,
                  ),
                ),
              ),
            );
          }

          final monthlyStats =
              vm.monthlyStatistics!['monthly_statistics'] as List<dynamic>;
          final totalYearSpending =
              vm.monthlyStatistics!['total_year_spending'] as num;

          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: BoxDecoration(
              color: widget.isDarkMode
                  ? ColorConstant.cardColorDark
                  : ColorConstant.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: widget.isDarkMode
                        ? ColorConstant.borderColorDark
                        : ColorConstant.borderColorLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'finance.monthlyStats'.tr(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: widget.isDarkMode
                              ? ColorConstant.textPrimaryDark
                              : ColorConstant.textPrimaryLight,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color:
                              ColorConstant.accentBlue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '₺${totalYearSpending.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: ColorConstant.accentBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemCount: monthlyStats.length,
                    itemBuilder: (context, index) {
                      final monthData = monthlyStats[index];
                      return _buildMonthPage(monthData);
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    monthlyStats.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? ColorConstant.accentBlue
                            : (widget.isDarkMode
                                ? ColorConstant.borderColorDark
                                : ColorConstant.borderColorLight),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMonthPage(Map<String, dynamic> monthData) {
    final monthName = monthData['month_name'] as String;
    final total = monthData['total'] as num;
    final categories = monthData['categories'] as List<dynamic>;
    final expenseCount = monthData['expense_count'] as int;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  ColorConstant.accentBlue,
                  const Color(0xFF667EEA),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: ColorConstant.accentBlue.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  monthName,
                  style: TextStyle(
                    color: ColorConstant.white.withValues(alpha: 0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '₺${total.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: ColorConstant.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ColorConstant.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'finance.totalExpense'.tr(),
                        style: TextStyle(
                          color: ColorConstant.white.withValues(alpha: 0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '$expenseCount ${'finance.transactions'.tr()}',
                        style: TextStyle(
                          color: ColorConstant.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (categories.isNotEmpty) ...[
            Text(
              'finance.categoryDistribution'.tr(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: widget.isDarkMode
                    ? ColorConstant.textPrimaryDark
                    : ColorConstant.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 12),
            ...categories.map((category) {
              final categoryName = category['category'] as String;
              final categoryTotal = category['total'] as num;
              final percentage = category['percentage'] as num;
              final count = category['count'] as int;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: widget.isDarkMode
                      ? ColorConstant.bgColorDark
                      : ColorConstant.bgColorLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: widget.isDarkMode
                        ? ColorConstant.borderColorDark
                        : ColorConstant.borderColorLight,
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: widget.viewModel
                                .getCategoryColor(categoryName)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              widget.viewModel.getCategoryEmoji(categoryName),
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.viewModel.getCategoryLabel(categoryName),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: widget.isDarkMode
                                      ? ColorConstant.textPrimaryDark
                                      : ColorConstant.textPrimaryLight,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$count ${'finance.transactions'.tr()}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: widget.isDarkMode
                                      ? ColorConstant.textSecondaryDark
                                      : ColorConstant.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₺${categoryTotal.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: widget.isDarkMode
                                    ? ColorConstant.textPrimaryDark
                                    : ColorConstant.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '%${percentage.toStringAsFixed(1)}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: ColorConstant.accentBlue,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: widget.isDarkMode
                            ? ColorConstant.borderColorDark
                            : ColorConstant.borderColorLight,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          widget.viewModel.getCategoryColor(categoryName),
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ] else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Text(
                  'finance.noExpenses'.tr(),
                  style: TextStyle(
                    color: widget.isDarkMode
                        ? ColorConstant.textSecondaryDark
                        : ColorConstant.textSecondaryLight,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ExpenseFilterDialog extends StatelessWidget {
  final FinanceViewModel viewModel;
  final bool isDarkMode;

  const _ExpenseFilterDialog({
    required this.viewModel,
    required this.isDarkMode,
  });

  List<Map<String, dynamic>> get _categories => [
        {
          'value': 'food',
          'label': 'finance.categories.food'.tr(),
          'emoji': '🍔'
        },
        {
          'value': 'transportation',
          'label': 'finance.categories.transportation'.tr(),
          'emoji': '🚗'
        },
        {
          'value': 'entertainment',
          'label': 'finance.categories.entertainment'.tr(),
          'emoji': '🎬'
        },
        {
          'value': 'shopping',
          'label': 'finance.categories.shopping'.tr(),
          'emoji': '🛍️'
        },
        {
          'value': 'bills',
          'label': 'finance.categories.bills'.tr(),
          'emoji': '📄'
        },
        {
          'value': 'health',
          'label': 'finance.categories.health'.tr(),
          'emoji': '💊'
        },
        {
          'value': 'education',
          'label': 'finance.categories.education'.tr(),
          'emoji': '📚'
        },
        {
          'value': 'other',
          'label': 'finance.categories.other'.tr(),
          'emoji': '💰'
        },
      ];

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: viewModel,
      child: Consumer<FinanceViewModel>(
        builder: (context, vm, _) {
          return AlertDialog(
            backgroundColor:
                isDarkMode ? ColorConstant.cardColorDark : ColorConstant.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'finance.filterExpenses'.tr(),
              style: TextStyle(
                color: isDarkMode
                    ? ColorConstant.textPrimaryDark
                    : ColorConstant.textPrimaryLight,
                fontWeight: FontWeight.w800,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'finance.category'.tr(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode
                          ? ColorConstant.textSecondaryDark
                          : ColorConstant.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categories.map((category) {
                      final isSelected = vm.isFilterActive(category['value']!);
                      return GestureDetector(
                        onTap: () =>
                            vm.toggleFilterCategory(category['value']!),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? ColorConstant.accentBlue
                                    .withValues(alpha: 0.15)
                                : (isDarkMode
                                    ? ColorConstant.bgColorDark
                                    : ColorConstant.bgColorLight),
                            border: Border.all(
                              color: isSelected
                                  ? ColorConstant.accentBlue
                                  : (isDarkMode
                                      ? ColorConstant.borderColorDark
                                      : ColorConstant.borderColorLight),
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                category['emoji']!,
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                category['label']!,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? ColorConstant.accentBlue
                                      : (isDarkMode
                                          ? ColorConstant.textSecondaryDark
                                          : ColorConstant.textSecondaryLight),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  vm.resetFilter();
                  Navigator.pop(context);
                },
                child: Text(
                  'finance.clear'.tr(),
                  style: TextStyle(
                    color: isDarkMode
                        ? ColorConstant.textSecondaryDark
                        : ColorConstant.textSecondaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  vm.applyFilter(context);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorConstant.accentBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'finance.apply'.tr(),
                  style: TextStyle(
                    color: ColorConstant.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ==================== EDIT SUBSCRIPTION BOTTOM SHEET ====================
class _EditSubscriptionBottomSheet extends StatelessWidget {
  final FinanceViewModel viewModel;
  final dynamic subscription;
  final bool isDarkMode;

  const _EditSubscriptionBottomSheet({
    required this.viewModel,
    required this.subscription,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: viewModel,
      child: Consumer<FinanceViewModel>(
        builder: (context, vm, _) {
          return Container(
            decoration: BoxDecoration(
              color: isDarkMode
                  ? ColorConstant.cardColorDark
                  : ColorConstant.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? ColorConstant.borderColorDark
                                  : ColorConstant.borderColorLight,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'finance.editSubscription'.tr(),
                              style: TextStyle(
                                color: isDarkMode
                                    ? ColorConstant.textPrimaryDark
                                    : ColorConstant.textPrimaryLight,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                color: ColorConstant.errorRed,
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                                vm.deleteSubscription(subscription.id, context);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildTextField(
                          context,
                          label: 'finance.subscriptionName'.tr(),
                          controller: vm.subscriptionNameController,
                          hint: 'Netflix, Spotify...',
                          icon: Icons.label_outline,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          context,
                          label: 'finance.amount'.tr(),
                          controller: vm.subscriptionAmountController,
                          hint: '0.00',
                          icon: Icons.attach_money,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),
                        _buildBillingCycleSelector(context, vm),
                        const SizedBox(height: 16),
                        _buildTextField(
                          context,
                          label: 'finance.paymentDay'.tr(),
                          controller: vm.subscriptionBillingDateController,
                          hint: '1-31',
                          icon: Icons.calendar_today,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () =>
                                vm.updateSubscription(subscription.id, context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ColorConstant.accentBlue,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'finance.update'.tr(),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: ColorConstant.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDarkMode
                ? ColorConstant.textSecondaryDark
                : ColorConstant.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(
            color: isDarkMode
                ? ColorConstant.textPrimaryDark
                : ColorConstant.textPrimaryLight,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(
              icon,
              color: isDarkMode
                  ? ColorConstant.textMutedDark
                  : ColorConstant.textMutedLight,
            ),
            filled: true,
            fillColor: isDarkMode
                ? ColorConstant.bgColorDark
                : ColorConstant.bgColorLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBillingCycleSelector(BuildContext context, FinanceViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'finance.billingCycle'.tr(),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDarkMode
                ? ColorConstant.textSecondaryDark
                : ColorConstant.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildCycleOption(
                context,
                vm,
                'monthly',
                'finance.monthly'.tr(),
                Icons.calendar_month,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCycleOption(
                context,
                vm,
                'yearly',
                'finance.yearly'.tr(),
                Icons.calendar_today,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCycleOption(
    BuildContext context,
    FinanceViewModel vm,
    String value,
    String label,
    IconData icon,
  ) {
    final isSelected = vm.subscriptionBillingCycle == value;
    return GestureDetector(
      onTap: () => vm.setSubscriptionBillingCycle(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? ColorConstant.accentBlue.withValues(alpha: 0.1)
              : (isDarkMode
                  ? ColorConstant.bgColorDark
                  : ColorConstant.bgColorLight),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? ColorConstant.accentBlue
                : (isDarkMode
                    ? ColorConstant.borderColorDark
                    : ColorConstant.borderColorLight),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? ColorConstant.accentBlue
                  : (isDarkMode
                      ? ColorConstant.textMutedDark
                      : ColorConstant.textMutedLight),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected
                    ? ColorConstant.accentBlue
                    : (isDarkMode
                        ? ColorConstant.textSecondaryDark
                        : ColorConstant.textSecondaryLight),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== EDIT EXPENSE BOTTOM SHEET ====================
class _EditExpenseBottomSheet extends StatelessWidget {
  final FinanceViewModel viewModel;
  final dynamic expense;
  final bool isDarkMode;

  const _EditExpenseBottomSheet({
    required this.viewModel,
    required this.expense,
    required this.isDarkMode,
  });

  List<Map<String, dynamic>> get _categories => [
        {
          'value': 'food',
          'label': 'finance.categories.food'.tr(),
          'emoji': '🍔'
        },
        {
          'value': 'transportation',
          'label': 'finance.categories.transportation'.tr(),
          'emoji': '🚗'
        },
        {
          'value': 'entertainment',
          'label': 'finance.categories.entertainment'.tr(),
          'emoji': '🎬'
        },
        {
          'value': 'shopping',
          'label': 'finance.categories.shopping'.tr(),
          'emoji': '🛍️'
        },
        {
          'value': 'bills',
          'label': 'finance.categories.bills'.tr(),
          'emoji': '📄'
        },
        {
          'value': 'health',
          'label': 'finance.categories.health'.tr(),
          'emoji': '💊'
        },
        {
          'value': 'education',
          'label': 'finance.categories.education'.tr(),
          'emoji': '📚'
        },
        {
          'value': 'other',
          'label': 'finance.categories.other'.tr(),
          'emoji': '💰'
        },
      ];

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: viewModel,
      child: Consumer<FinanceViewModel>(
        builder: (context, vm, _) {
          return Container(
            decoration: BoxDecoration(
              color: isDarkMode
                  ? ColorConstant.cardColorDark
                  : ColorConstant.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? ColorConstant.borderColorDark
                                  : ColorConstant.borderColorLight,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'finance.editExpense'.tr(),
                              style: TextStyle(
                                color: isDarkMode
                                    ? ColorConstant.textPrimaryDark
                                    : ColorConstant.textPrimaryLight,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                color: ColorConstant.errorRed,
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                                vm.deleteExpense(expense.id, context);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'finance.selectCategory'.tr(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode
                                ? ColorConstant.textSecondaryDark
                                : ColorConstant.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _categories.map((category) {
                            final isSelected =
                                vm.expenseCategory == category['value'];
                            return GestureDetector(
                              onTap: () =>
                                  vm.setExpenseCategory(category['value']),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? ColorConstant.accentBlue
                                          .withValues(alpha: 0.1)
                                      : (isDarkMode
                                          ? ColorConstant.bgColorDark
                                          : ColorConstant.bgColorLight),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? ColorConstant.accentBlue
                                        : (isDarkMode
                                            ? ColorConstant.borderColorDark
                                            : ColorConstant.borderColorLight),
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      category['emoji'],
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      category['label'],
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w600,
                                        color: isSelected
                                            ? ColorConstant.accentBlue
                                            : (isDarkMode
                                                ? ColorConstant
                                                    .textSecondaryDark
                                                : ColorConstant
                                                    .textSecondaryLight),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          context,
                          label: 'finance.amount'.tr(),
                          controller: vm.expenseAmountController,
                          hint: '0.00',
                          icon: Icons.attach_money,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          context,
                          label: 'finance.description'.tr(),
                          controller: vm.expenseDescriptionController,
                          hint: 'finance.descriptionHint'.tr(),
                          icon: Icons.notes,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () =>
                                vm.updateExpense(expense.id, context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ColorConstant.accentBlue,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'finance.update'.tr(),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: ColorConstant.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDarkMode
                ? ColorConstant.textSecondaryDark
                : ColorConstant.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(
            color: isDarkMode
                ? ColorConstant.textPrimaryDark
                : ColorConstant.textPrimaryLight,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(
              icon,
              color: isDarkMode
                  ? ColorConstant.textMutedDark
                  : ColorConstant.textMutedLight,
            ),
            filled: true,
            fillColor: isDarkMode
                ? ColorConstant.bgColorDark
                : ColorConstant.bgColorLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
