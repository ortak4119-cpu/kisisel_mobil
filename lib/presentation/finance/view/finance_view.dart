import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/design/app_design.dart';
import '../../../core/utils/color_constant.dart';
import '../../../core/utils/subscription_icons.dart';
import '../../../core/utils/currency.dart';
import '../../../models/subscription/subscription_models.dart';
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
// Mockup'taki koyu teal başlık + hesap kartı tonları.
const _fTeal = Color(0xFF0F524E);
const _fTealDark = Color(0xFF0B3C39);
const _fTealCard = Color(0xFF0A3F3C);

// Tutar biçimlendirme artık seçili para birimine (AppCurrency) göre yapılır.
String tl(double v) {
  final neg = v < 0;
  return '${neg ? '-' : ''}${AppCurrency.format(v.abs(), decimals: 2)}';
}

String tl0(double v) => AppCurrency.format(v.abs(), decimals: 0);

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


class FinanceView extends StatefulWidget {
  const FinanceView({super.key});

  @override
  State<FinanceView> createState() => _FinanceViewState();
}

class _FinanceViewState extends State<FinanceView> {
  final PageController _acctCtrl = PageController(viewportFraction: 0.7);
  int _acctIdx = 0;
  int _dashTab = 0; // 0 Genel, 1 Harcama, 2 Plan

  @override
  void dispose() {
    _acctCtrl.dispose();
    super.dispose();
  }

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
            body: vm.isInitialLoading
                ? Center(child: CircularProgressIndicator(color: _fOrange))
                : vm.financeLocked
                    ? SafeArea(child: _FinanceLockGate(vm: vm, c: c))
                    : RefreshIndicator(
                        onRefresh: () => vm.refreshAll(),
                        color: _fOrange,
                        child: ListView(
                          padding: const EdgeInsets.only(bottom: 130),
                          children: [
                            _tealHeader(context, vm, c),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                              child: Column(
                                children: [
                                  _tabPills(c),
                                  const SizedBox(height: 16),
                                  ..._tabContent(context, vm, c),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
            // Ekleme, teal başlıktaki Gelir/Gider/Abonelik aksiyonlarından
            // yapılır; ayrı bir "+" FAB'ı (Gider ile aynı işi gören) kaldırıldı.
          );
        },
      ),
    );
  }

  // ---------- Genel/Harcama/Plan sekme pilleri ----------
  Widget _tabPills(AppColors c) {
    final labels = [
      'finance.tabGeneral'.tr(),
      'finance.tabSpending'.tr(),
      'finance.tabPlan'.tr(),
    ];
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: c.isDark ? ColorConstant.cardColorDark : const Color(0xFFE8DFCD),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: List.generate(3, (i) {
          final sel = i == _dashTab;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _dashTab = i),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: sel
                      ? (c.isDark ? _fTeal : ColorConstant.cardColorLight)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: sel
                      ? [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 6,
                              offset: const Offset(0, 2))
                        ]
                      : null,
                ),
                child: Text(labels[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: sel
                            ? (c.isDark ? Colors.white : c.textPrimary)
                            : c.textMuted)),
              ),
            ),
          );
        }),
      ),
    );
  }

  List<Widget> _tabContent(
      BuildContext context, FinanceViewModel vm, AppColors c) {
    switch (_dashTab) {
      case 1: // Harcama
        return [
          _harcamaSummary(vm, c),
          const SizedBox(height: 14),
          _categoryBreakdown(vm, c),
          const SizedBox(height: 14),
          _transactionsCard(context, vm, c),
        ];
      case 2: // Plan
        return [
          _planBudgetCard(context, vm, c),
          const SizedBox(height: 14),
          _planSavingsCard(context, vm, c),
          const SizedBox(height: 14),
          _planUpcomingCard(context, vm, c),
          const SizedBox(height: 14),
          _planDebtCard(vm, c),
        ];
      default: // Genel
        return [
          _buAyCard(context, vm, c),
          const SizedBox(height: 14),
          _coloredStatCards(context, vm, c),
          const SizedBox(height: 14),
          _transactionsCard(context, vm, c),
          const SizedBox(height: 22),
          // Bütçe ayarları bölümü — en altta, tüm ayarlar doğrudan erişilebilir.
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'finance.budgetSettings'.tr(),
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: c.textPrimary,
              ),
            ),
          ),
          _settingsList(context, vm, c),
        ];
    }
  }

  // ---------- Koyu teal başlık + hesap carousel + dairesel aksiyonlar ----------
  Widget _tealHeader(BuildContext context, FinanceViewModel vm, AppColors c) {
    final months = 'calendar.monthNames'.tr().split(',');
    final m = vm.viewMonth;
    final monthLabel =
        '${m.month <= months.length ? months[m.month - 1] : ''} ${m.year}';
    final topPad = MediaQuery.of(context).padding.top;
    final user = vm.currentUser;
    return Container(
      padding: EdgeInsets.fromLTRB(20, topPad + 10, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_fTeal, _fTealDark],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Üst satır: avatar + ay/başlık + arama/zil ---
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white.withOpacity(0.18),
                backgroundImage: (user?.profilePictureUrl != null)
                    ? NetworkImage(user!.profilePictureUrl!)
                    : null,
                child: user?.profilePictureUrl == null
                    ? const Icon(Icons.person_rounded,
                        color: Colors.white, size: 22)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: vm.isCurrentMonth ? null : vm.goToCurrentMonth,
                      child: Row(
                        children: [
                          InkWell(
                            onTap: () => vm.changeMonth(-1),
                            child: const Icon(Icons.chevron_left_rounded,
                                size: 18, color: Colors.white70),
                          ),
                          Text(monthLabel,
                              style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white70)),
                          InkWell(
                            onTap: () => vm.changeMonth(1),
                            child: const Icon(Icons.chevron_right_rounded,
                                size: 18, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    Text('finance.title'.tr(),
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.1)),
                  ],
                ),
              ),
              _tealIconBtn(Icons.search_rounded,
                  () => _showBudgetSettingsDialog(context, vm, c.isDark)),
              const SizedBox(width: 10),
              _tealIconBtn(Icons.notifications_none_rounded,
                  () => _showUpcomingSheet(context, vm, c)),
            ],
          ),
          const SizedBox(height: 18),
          // --- Hesap carousel ---
          SizedBox(
            height: 150,
            child: PageView(
              controller: _acctCtrl,
              onPageChanged: (i) => setState(() => _acctIdx = i),
              children: [
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: _mainAccountCard(vm)),
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: _subsAccountCard(vm)),
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: _installmentsAccountCard(vm)),
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: _savingsAccountCard(vm)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // --- Sayfa noktaları ---
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) {
              final sel = i == _acctIdx;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: sel ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(sel ? 0.95 : 0.4),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
          const SizedBox(height: 18),
          // --- 4 dairesel aksiyon ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _circleAction(Icons.add_rounded, 'finance.income'.tr(),
                  const Color(0xFF48BB78),
                  () => showFinanceFormSheet(context, vm, c.isDark,
                      income: true)),
              _circleAction(Icons.remove_rounded, 'finance.expense'.tr(),
                  const Color(0xFFF6524B),
                  () => showFinanceFormSheet(context, vm, c.isDark)),
              _circleAction(Icons.sync_rounded, 'finance.subShort'.tr(),
                  const Color(0xFF9F7AEA),
                  () => _showAddSubscriptionDialog(context, vm, c.isDark)),
              _circleAction(Icons.lock_outline_rounded, 'finance.lockShort'.tr(),
                  const Color(0xFF3AB7A8), () {
                if (vm.financeHasPin) {
                  vm.lockNow();
                } else {
                  _showBudgetSettingsDialog(context, vm, c.isDark);
                }
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tealIconBtn(IconData icon, VoidCallback onTap) => Material(
        color: Colors.white.withOpacity(0.15),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Padding(
              padding: const EdgeInsets.all(9),
              child: Icon(icon, size: 20, color: Colors.white)),
        ),
      );

  Widget _mainAccountCard(FinanceViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _fTealCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('finance.mainAccount'.tr(),
                  style: TextStyle(
                      fontSize: 13.5, color: Colors.white.withOpacity(0.7))),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(10)),
                child: Text(AppCurrency.code,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(tl(vm.availableBalance),
              style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.white)),
          const Spacer(),
          Text(
            '${'finance.spendableToday'.tr()} · ${tl0(vm.safeToSpendPerDay)}',
            style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF5FE3B3)),
          ),
        ],
      ),
    );
  }

  Widget _savingsAccountCard(FinanceViewModel vm) {
    final pct = vm.savingsTarget > 0
        ? (vm.savingsCurrent / vm.savingsTarget).clamp(0.0, 1.0)
        : 0.0;
    final title =
        vm.savingsTitle.trim().isEmpty ? 'finance.savingsFund'.tr() : vm.savingsTitle;
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFFF6894B), _fOrange],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 13.5, color: Colors.white.withOpacity(0.9))),
          const SizedBox(height: 8),
          Text(tl(vm.savingsCurrent),
              style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.white)),
          const Spacer(),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'finance.target'.tr(namedArgs: {'amount': tl0(vm.savingsTarget)}),
            style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _gradAccountCard({
    required String label,
    required String value,
    required String sub,
    required List<Color> grad,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: grad,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 13.5, color: Colors.white.withOpacity(0.92))),
              const Spacer(),
              Icon(icon, color: Colors.white70, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.white)),
          const Spacer(),
          Text(sub,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
        ],
      ),
    );
  }

  Widget _subsAccountCard(FinanceViewModel vm) {
    final n = vm.activeSubscriptions.length;
    return _gradAccountCard(
      label: 'finance.subscriptions'.tr(),
      value: tl(_subsMonthly(vm)),
      sub: '$n ${'finance.subShort'.tr()} · ${'finance.monthly'.tr()}',
      grad: const [Color(0xFF9F7AEA), Color(0xFF6D4FB8)],
      icon: Icons.sync_rounded,
    );
  }

  Widget _installmentsAccountCard(FinanceViewModel vm) {
    final n = vm.installments.length;
    return _gradAccountCard(
      label: 'finance.installment.title'.tr(),
      value: tl(vm.monthlyInstallmentTotal),
      sub: '$n · ${'finance.monthly'.tr()}',
      grad: const [Color(0xFF3B82C4), Color(0xFF2C6AA0)],
      icon: Icons.credit_card_rounded,
    );
  }

  Widget _circleAction(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: Icon(icon, color: color == const Color(0xFF3AB7A8)
                ? Colors.white
                : color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
        ],
      ),
    );
  }

  // ---------- "Bu ay" kartı (Genel sekmesi) ----------
  Widget _buAyCard(BuildContext context, FinanceViewModel vm, AppColors c) {
    final exp = vm.monthExpensesTotal;
    final inc = vm.monthIncomeTotal;
    final rate = vm.monthSavingsRate.round();
    final ratio = inc > 0 ? (exp / inc).clamp(0.0, 1.0) : 0.0;
    final cats = vm.categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final chips = <Widget>[];
    for (final e in cats.take(2)) {
      chips.add(_catChip(
          vm.getCategoryLabel(e.key), tl0(e.value), finCatById(e.key).color));
    }
    chips.add(_catChip(
        'finance.avg'.tr(),
        '${tl0(vm.dailyAverage)}/${'finance.perDay'.tr()}',
        c.textMuted));
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border.withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('finance.thisMonth'.tr(),
                  style: TextStyle(fontSize: 13, color: c.textMuted)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: const Color(0xFF48BB78).withOpacity(0.14),
                    borderRadius: BorderRadius.circular(10)),
                child: Text('%$rate ${'finance.savings'.tr()}',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2F9E5E))),
              ),
            ],
          ),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(children: [
              TextSpan(
                  text: tl(exp),
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: c.textPrimary)),
              TextSpan(
                  text: '  ${'finance.spent'.tr()}',
                  style: TextStyle(fontSize: 13, color: c.textMuted)),
            ]),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: const Color(0xFF48BB78).withOpacity(0.18),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFFF6894B)),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _dotLabel(
                  const Color(0xFFF6524B), 'finance.expense'.tr(), tl0(exp), c),
              const SizedBox(width: 20),
              _dotLabel(
                  const Color(0xFF48BB78), 'finance.income'.tr(), tl0(inc), c),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(spacing: 8, runSpacing: 8, children: chips),
        ],
      ),
    );
  }

  Widget _dotLabel(Color dot, String label, String value, AppColors c) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text('$label $value',
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: c.textSecondary)),
        ],
      );

  Widget _catChip(String label, String value, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20)),
        child: Text('$label · $value',
            style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: color == const Color(0xFF9AA0A6)
                    ? color
                    : HSLColor.fromColor(color)
                        .withLightness(0.38)
                        .toColor())),
      );

  // ---------- 3 renkli kart: Abonelik/Taksit/Borç ----------
  Widget _coloredStatCards(
      BuildContext context, FinanceViewModel vm, AppColors c) {
    Subscription? topSub;
    for (final s in vm.activeSubscriptions) {
      if (topSub == null || s.amount > topSub.amount) topSub = s;
    }
    final subSub = topSub != null
        ? '${topSub.nextBillingDate.difference(DateTime.now()).inDays.clamp(0, 999)} ${'finance.daysUnit'.tr()}'
        : 'finance.monthly'.tr();
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        Expanded(
          child: _colorStat(
              topSub?.name ?? 'finance.subscriptions'.tr(),
              tl0(topSub?.amount ?? _subsMonthly(vm)),
              subSub,
              const Color(0xFF7C5BD0)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _colorStat(
              'finance.installment.title'.tr(),
              tl0(vm.monthlyInstallmentTotal),
              'finance.monthly'.tr(),
              const Color(0xFF13605C)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _colorStat('finance.debtShort'.tr(), tl0(vm.totalDebt),
              'finance.totalShort'.tr(), const Color(0xFF9B2C2C)),
        ),
        ],
      ),
    );
  }

  Widget _colorStat(String label, String value, String sub, Color bg) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 12.5, color: Colors.white.withOpacity(0.85))),
          const SizedBox(height: 8),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: Colors.white)),
          const SizedBox(height: 3),
          Text(sub,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 11, color: Colors.white.withOpacity(0.7))),
        ],
      ),
    );
  }

  // ---------- Alt ayar listesi (Genel sekmesi) ----------
  Widget _settingsList(BuildContext context, FinanceViewModel vm, AppColors c) {
    final budget = vm.budgetStats?.monthlyBudget ?? 0;
    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border.withOpacity(0.6)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        children: [
          _setRow(c, 'finance.monthlyBudget'.tr(),
              trailing: Text(
                  budget > 0
                      ? '${tl0(budget)} · ${tl0(vm.monthExpensesTotal)} ${'finance.spent'.tr()}'
                      : '${tl0(vm.monthExpensesTotal)} ${'finance.spent'.tr()}',
                  style: TextStyle(fontSize: 12.5, color: c.textSecondary)),
              onTap: () => _showBudgetSettingsDialog(context, vm, c.isDark)),
          _setDivider(c),
          _setRow(c, 'finance.categoryBudgetsLabel'.tr(),
              trailing: Text(
                  'finance.limited'
                      .tr(namedArgs: {'n': '${vm.categoryBudgets.length}'}),
                  style: TextStyle(fontSize: 12.5, color: c.textSecondary)),
              onTap: () => _showCategoryBudgetsDialog(context, vm, c.isDark)),
          _setDivider(c),
          _setRow(c, 'finance.debt.title'.tr(),
              trailing: Text(
                  vm.debts.isEmpty
                      ? 'finance.debt.none'.tr()
                      : 'finance.debt.total'
                          .tr(namedArgs: {'amount': tl0(vm.totalDebt)}),
                  style: TextStyle(fontSize: 12.5, color: c.textSecondary)),
              onTap: () => _showDebtPlannerDialog(context, vm, c.isDark)),
          _setDivider(c),
          _setRow(c, 'finance.installment.title'.tr(),
              trailing: Text(
                  vm.installments.isEmpty
                      ? 'finance.installment.none'.tr()
                      : 'finance.installment.monthly'.tr(
                          namedArgs: {'amount': tl0(vm.monthlyInstallmentTotal)}),
                  style: TextStyle(fontSize: 12.5, color: c.textSecondary)),
              onTap: () => _showInstallmentsDialog(context, vm, c.isDark)),
          _setDivider(c),
          _setRow(c, 'finance.subscriptions'.tr(),
              trailing: Text(
                  '${vm.activeSubscriptions.length} ${'finance.subShort'.tr()}',
                  style: TextStyle(fontSize: 12.5, color: c.textSecondary)),
              onTap: () => _openSubscriptionsManager(context, vm, c.isDark)),
          _setDivider(c),
          _setRow(c, 'finance.financeLock'.tr(),
              trailing: Switch(
                value: vm.financeHasPin,
                activeThumbColor: _fOrange,
                onChanged: (_) =>
                    _showFinanceLockDialog(context, vm, c.isDark),
              )),
          _setDivider(c),
          _setRow(c, 'finance.currency.title'.tr(),
              trailing: Text(AppCurrency.code,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: c.textSecondary)),
              onTap: () => _showCurrencyDialog(context, vm, c.isDark)),
        ],
      ),
    );
  }

  Widget _setRow(AppColors c, String label,
      {Widget? trailing, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary)),
            ),
            if (trailing != null) trailing,
            if (onTap != null) ...[
              const SizedBox(width: 6),
              Icon(Icons.chevron_right_rounded, size: 20, color: c.textMuted),
            ],
          ],
        ),
      ),
    );
  }

  Widget _setDivider(AppColors c) =>
      Divider(height: 1, color: c.border.withOpacity(0.5));

  // ---------- Ortak panel / başlık ----------
  Widget _panel(AppColors c, Widget child) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.border.withOpacity(0.6)),
        ),
        child: child,
      );

  Widget _panelHead(AppColors c, String title, {Widget? trailing}) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(title,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: c.textPrimary)),
            ),
            if (trailing != null) trailing,
          ],
        ),
      );

  // ---------- HARCAMA sekmesi ----------
  Widget _harcamaSummary(FinanceViewModel vm, AppColors c) {
    return _panel(
      c,
      Row(
        children: [
          _hStat(c, tl0(vm.monthExpensesTotal), 'finance.expense'.tr()),
          _vDiv(c),
          _hStat(c, tl0(vm.dailyAverage), 'finance.avg'.tr()),
          _vDiv(c),
          _hStat(c, '${vm.expenses.length}', 'finance.transactions'.tr()),
        ],
      ),
    );
  }

  Widget _hStat(AppColors c, String value, String label) => Expanded(
        child: Column(
          children: [
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: c.textPrimary)),
            const SizedBox(height: 3),
            Text(label,
                style: TextStyle(fontSize: 12, color: c.textMuted)),
          ],
        ),
      );

  Widget _vDiv(AppColors c) =>
      Container(width: 1, height: 34, color: c.border.withOpacity(0.6));

  Widget _categoryBreakdown(FinanceViewModel vm, AppColors c) {
    final total = vm.monthExpensesTotal;
    final cats = vm.categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return _panel(
      c,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _panelHead(c, 'finance.distribution'.tr()),
          if (cats.isEmpty)
            Text('—', style: TextStyle(color: c.textMuted))
          else
            ...cats.map((e) {
              final color = finCatById(e.key).color;
              final pct = total > 0 ? (e.value / total).clamp(0.0, 1.0) : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                                color: color, shape: BoxShape.circle)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(vm.getCategoryLabel(e.key),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: c.textPrimary)),
                        ),
                        Text(tl0(e.value),
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: c.textPrimary)),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 42,
                          child: Text('%${(pct * 100).round()}',
                              textAlign: TextAlign.right,
                              style:
                                  TextStyle(fontSize: 12.5, color: c.textMuted)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 6,
                        backgroundColor: color.withOpacity(0.14),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // ---------- PLAN sekmesi ----------
  Widget _planBudgetCard(
      BuildContext context, FinanceViewModel vm, AppColors c) {
    final budget = vm.budgetStats?.monthlyBudget ?? 0;
    final spent = vm.monthExpensesTotal;
    final rem = budget - spent;
    final pct = budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0.0;
    return _panel(
      c,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _panelHead(c, 'finance.monthlyBudget'.tr(),
              trailing: GestureDetector(
                onTap: () => _showBudgetSettingsDialog(context, vm, c.isDark),
                child: Text('finance.editBudget'.tr(),
                    style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: _fOrange)),
              )),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(tl(spent),
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: c.textPrimary)),
              const SizedBox(width: 6),
              Text('/ ${tl0(budget)}',
                  style: TextStyle(fontSize: 14, color: c.textMuted)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: _fOrange.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(
                  pct >= 1 ? const Color(0xFFF6524B) : _fOrange),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            budget > 0
                ? '${tl0(rem.abs())} ${rem >= 0 ? 'finance.remaining'.tr() : 'finance.spent'.tr()}'
                : '—',
            style: TextStyle(fontSize: 13, color: c.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _planSavingsCard(
      BuildContext context, FinanceViewModel vm, AppColors c) {
    final pct = vm.savingsTarget > 0
        ? (vm.savingsCurrent / vm.savingsTarget).clamp(0.0, 1.0)
        : 0.0;
    final title = vm.savingsTitle.trim().isEmpty
        ? 'finance.savingsFund'.tr()
        : vm.savingsTitle;
    return _panel(
      c,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _panelHead(c, title,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('%${(pct * 100).round()}',
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2F9E5E))),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _addSavingsDialog(context, vm, c),
                    child: Icon(Icons.edit_rounded,
                        size: 17, color: c.textMuted),
                  ),
                ],
              )),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(tl(vm.savingsCurrent),
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: c.textPrimary)),
              const SizedBox(width: 6),
              Text('/ ${tl0(vm.savingsTarget)}',
                  style: TextStyle(fontSize: 14, color: c.textMuted)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: const Color(0xFF48BB78).withOpacity(0.15),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF48BB78)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _planUpcomingCard(
      BuildContext context, FinanceViewModel vm, AppColors c) {
    final rows = <Widget>[];
    for (final s in vm.activeSubscriptions) {
      rows.add(_payRow(c, Icons.sync_rounded, const Color(0xFF9F7AEA), s.name,
          _shortDate(s.nextBillingDate), tl0(s.amount),
          onTap: () => _openEditSubscription(context, vm, s, c.isDark)));
    }
    for (final it in vm.installments.where((i) => !i.isDone)) {
      rows.add(_payRow(c, Icons.credit_card_rounded, const Color(0xFF3B82C4),
          it.name, '${it.paidCount}/${it.installmentCount}',
          tl0(it.monthlyAmount)));
    }
    return _panel(
      c,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _panelHead(c, 'finance.upcoming'.tr()),
          if (rows.isEmpty)
            Text('—', style: TextStyle(color: c.textMuted))
          else
            ...rows,
        ],
      ),
    );
  }

  Widget _payRow(AppColors c, IconData icon, Color col, String name,
      String sub, String amount, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
                color: col.withOpacity(0.14),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 20, color: col),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: c.textPrimary)),
                const SizedBox(height: 2),
                Text(sub, style: TextStyle(fontSize: 12, color: c.textMuted)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(amount,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: c.textPrimary)),
          ],
        ),
      ),
    );
  }

  Widget _planDebtCard(FinanceViewModel vm, AppColors c) {
    return _panel(
      c,
      Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: const Color(0xFF9B2C2C).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.account_balance_wallet_rounded,
                color: Color(0xFF9B2C2C)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('finance.debtShort'.tr(),
                    style: TextStyle(fontSize: 13, color: c.textMuted)),
                const SizedBox(height: 2),
                Text(tl(vm.totalDebt),
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: c.textPrimary)),
              ],
            ),
          ),
          if (vm.totalMinPayment > 0)
            Text(
                'finance.debt.minTotal'
                    .tr(namedArgs: {'amount': tl0(vm.totalMinPayment)}),
                style: TextStyle(fontSize: 12.5, color: c.textSecondary)),
        ],
      ),
    );
  }

  String _shortDate(DateTime d) {
    final months = 'calendar.monthNames'.tr().split(',');
    final mn = d.month <= months.length ? months[d.month - 1] : '';
    final short = mn.length >= 3 ? mn.substring(0, 3) : mn;
    return '${d.day} $short';
  }

  // ---------- Başlık ----------

  // ---------- Ay değiştirici ----------



  // ---------- Bakiye kartı ----------



  // ---------- 3 aksiyon ----------


  // ---------- Aylık bütçe ----------

  // ---------- Bu ayki giderler (çubuk) ----------


  // ---------- Gider dağılımı (halka) ----------

  // ---------- Abonelikler ----------


  // ---------- Yaklaşan ödemeler ----------

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

  /// Tüm işlemleri (gelir + gider) tarihe göre sıralı döner.
  List<_Txn> _allTxns(FinanceViewModel vm) {
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
    return items;
  }

  // ---------- Son işlemler (en fazla 5; fazlası ayrı sayfada) ----------
  Widget _transactionsCard(
      BuildContext context, FinanceViewModel vm, AppColors c) {
    final items = _allTxns(vm);
    final top = items.take(5).toList();
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
          if (items.length > 5) ...[
            Divider(height: 1, color: c.border.withOpacity(0.6)),
            InkWell(
              onTap: () => _openAllTransactions(context, vm, c),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'finance.seeAllTxn'
                          .tr(namedArgs: {'n': '${items.length}'}),
                      style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: _fOrange),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right_rounded,
                        size: 18, color: _fOrange),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------- Tüm işlemler sayfası ----------
  void _openAllTransactions(
      BuildContext context, FinanceViewModel vm, AppColors c) {
    final bg =
        c.isDark ? ColorConstant.bgColorDark : ColorConstant.bgColorLight;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider.value(
        value: vm,
        child: Consumer<FinanceViewModel>(
          builder: (ctx, vm2, _) {
            final items = _allTxns(vm2);
            return Scaffold(
              backgroundColor: bg,
              appBar: AppBar(
                backgroundColor: bg,
                elevation: 0,
                surfaceTintColor: Colors.transparent,
                foregroundColor: c.textPrimary,
                title: Text('finance.allTransactions'.tr(),
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: c.textPrimary)),
              ),
              body: items.isEmpty
                  ? Center(
                      child: Text('finance.noTxn'.tr(),
                          style: TextStyle(color: c.textMuted)))
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: c.card,
                            borderRadius: BorderRadius.circular(20),
                            border:
                                Border.all(color: c.border.withOpacity(0.7)),
                          ),
                          child: Column(
                            children: [
                              for (final t in items) _txnRow(ctx, vm2, t, c),
                            ],
                          ),
                        ),
                      ],
                    ),
            );
          },
        ),
      ),
    ));
  }

  // ---------- Abonelik yöneticisi ----------
  void _openSubscriptionsManager(
      BuildContext context, FinanceViewModel vm, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SubscriptionsManagerSheet(vm: vm, isDark: isDark),
    );
  }

  Widget _txnRow(
      BuildContext context, FinanceViewModel vm, _Txn t, AppColors c) {
    final cat = finCatById(t.category);
    final month = 'calendar.monthNames'.tr().split(',');
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openEditFinance(context, vm, t, c.isDark),
      onLongPress: () => _txnMenu(context, vm, t, c),
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
    viewModel.resetSubscriptionForm();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddSubscriptionBottomSheet(
          viewModel: viewModel, isDarkMode: isDarkMode),
    );
  }

  void _openEditSubscription(BuildContext context, FinanceViewModel vm,
      dynamic s, bool isDarkMode) {
    vm.startEditSubscription(s);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _AddSubscriptionBottomSheet(viewModel: vm, isDarkMode: isDarkMode),
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

// ==================== ABONELİK YÖNETİCİSİ ====================
/// Eklenen tüm abonelikleri listeler: düzenle (dokun), aktif/pasif (anahtar),
/// sil ve yeni ekle. Bütçe Ayarları > Abonelikler ile açılır.
class _SubscriptionsManagerSheet extends StatelessWidget {
  final FinanceViewModel vm;
  final bool isDark;
  const _SubscriptionsManagerSheet({required this.vm, required this.isDark});

  static const _subPurple = Color(0xFF9F7AEA);

  void _openForm(BuildContext ctx, FinanceViewModel vm2) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _AddSubscriptionBottomSheet(viewModel: vm2, isDarkMode: isDark),
    );
  }

  @override
  Widget build(BuildContext context) {
    final txtP =
        isDark ? ColorConstant.textPrimaryDark : ColorConstant.textPrimaryLight;
    final txtS = isDark
        ? ColorConstant.textSecondaryDark
        : ColorConstant.textSecondaryLight;
    final card = isDark ? ColorConstant.cardColorDark : ColorConstant.cardColorLight;
    final fill = isDark ? ColorConstant.bgColorDark : ColorConstant.bgColorLight;
    return ChangeNotifierProvider.value(
      value: vm,
      child: Consumer<FinanceViewModel>(
        builder: (ctx, vm2, _) {
          final subs = vm2.subscriptions;
          return Container(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85),
            decoration: BoxDecoration(
              color: card,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 16,
                    bottom: 16 + MediaQuery.of(context).viewInsets.bottom),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                            color: fill,
                            borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text('finance.subscriptions'.tr(),
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: txtP)),
                        ),
                        InkWell(
                          onTap: () {
                            vm2.resetSubscriptionForm();
                            _openForm(ctx, vm2);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                                color: _fOrange.withOpacity(0.14),
                                borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.add_rounded,
                                    size: 18, color: _fOrange),
                                const SizedBox(width: 4),
                                Text('finance.addSubscription'.tr(),
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: _fOrange)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (subs.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 36),
                        child: Center(
                            child: Text('finance.noSubscriptions'.tr(),
                                style: TextStyle(color: txtS))),
                      )
                    else
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: subs.length,
                          separatorBuilder: (_, __) =>
                              Divider(height: 1, color: fill),
                          itemBuilder: (_, i) {
                            final s = subs[i];
                            final d = s.nextBillingDate;
                            return InkWell(
                              onTap: () {
                                vm2.startEditSubscription(s);
                                _openForm(ctx, vm2);
                              },
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                          color: _subPurple.withOpacity(
                                              s.isActive ? 0.15 : 0.07),
                                          borderRadius:
                                              BorderRadius.circular(11)),
                                      child: Icon(Icons.sync_rounded,
                                          size: 20,
                                          color: _subPurple.withOpacity(
                                              s.isActive ? 1 : 0.5)),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(s.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                  fontSize: 14.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: s.isActive
                                                      ? txtP
                                                      : txtS,
                                                  decoration: s.isActive
                                                      ? null
                                                      : TextDecoration
                                                          .lineThrough)),
                                          const SizedBox(height: 2),
                                          Text(
                                              '${tl0(s.amount)} · ${'finance.nextBilling'.tr(namedArgs: {
                                                    'date':
                                                        '${d.day}.${d.month}.${d.year}'
                                                  })}',
                                              style: TextStyle(
                                                  fontSize: 12, color: txtS)),
                                        ],
                                      ),
                                    ),
                                    Switch(
                                      value: s.isActive,
                                      activeThumbColor: _fOrange,
                                      onChanged: (_) => vm2
                                          .toggleSubscriptionActive(s.id, ctx),
                                    ),
                                    InkWell(
                                      onTap: () =>
                                          _confirmDeleteSub(ctx, vm2, s, isDark),
                                      borderRadius: BorderRadius.circular(20),
                                      child: const Padding(
                                        padding: EdgeInsets.all(6),
                                        child: Icon(Icons.delete_outline_rounded,
                                            size: 20, color: Color(0xFFE53E3E)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

void _confirmDeleteSub(
    BuildContext context, FinanceViewModel vm, dynamic s, bool isDark) {
  showDialog(
    context: context,
    builder: (d) => AlertDialog(
      backgroundColor:
          isDark ? ColorConstant.cardColorDark : ColorConstant.cardColorLight,
      title: Text(s.name,
          style: TextStyle(
              color: isDark
                  ? ColorConstant.textPrimaryDark
                  : ColorConstant.textPrimaryLight)),
      content: Text('finance.deleteSubscriptionConfirm'.tr(),
          style: TextStyle(
              color: isDark
                  ? ColorConstant.textSecondaryDark
                  : ColorConstant.textSecondaryLight)),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(d),
            child: Text('common.cancel'.tr())),
        TextButton(
          onPressed: () {
            Navigator.pop(d);
            vm.deleteSubscription(s.id, context);
          },
          child: Text('common.delete'.tr(),
              style: const TextStyle(color: Color(0xFFE53E3E))),
        ),
      ],
    ),
  );
}

void _txnMenu(
    BuildContext context, FinanceViewModel vm, _Txn t, AppColors c) {
  showModalBottomSheet(
    context: context,
    backgroundColor: c.card,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
    builder: (ctx) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(
          leading: const Icon(Icons.edit_rounded, color: _fOrange),
          title: Text('common.edit'.tr(),
              style: TextStyle(color: c.textPrimary)),
          onTap: () {
            Navigator.pop(ctx);
            _openEditFinance(context, vm, t, c.isDark);
          },
        ),
        ListTile(
          leading:
              const Icon(Icons.delete_outline_rounded, color: Color(0xFFE53E3E)),
          title: Text('common.delete'.tr(),
              style: TextStyle(color: c.textPrimary)),
          onTap: () {
            Navigator.pop(ctx);
            showDialog(
              context: context,
              builder: (d) => AlertDialog(
                backgroundColor: c.card,
                title: Text('finance.deleteExpense'.tr(),
                    style: TextStyle(color: c.textPrimary)),
                content:
                    Text(t.title, style: TextStyle(color: c.textSecondary)),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(d),
                      child: Text('common.cancel'.tr())),
                  TextButton(
                      onPressed: () {
                        Navigator.pop(d);
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
            );
          },
        ),
        const SizedBox(height: 8),
      ]),
    ),
  );
}

void _openEditFinance(
    BuildContext context, FinanceViewModel vm, _Txn t, bool isDark) {
  String? desc;
  if (t.income) {
    final matches = vm.income.where((i) => i.id == t.id);
    if (matches.isNotEmpty) desc = matches.first.description;
  } else {
    final matches = vm.expenses.where((e) => e.id == t.id);
    if (matches.isNotEmpty) desc = matches.first.description;
  }
  vm.startEditFinance(
    id: t.id,
    income: t.income,
    amount: t.amount.abs(),
    category: t.category,
    description: desc,
    date: t.date,
  );
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _FinanceFormSheet(viewModel: vm, isDarkMode: isDark),
  );
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
                  : ColorConstant.cardColorLight,
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
                          vm.isEditingSubscription
                              ? 'finance.editSubscription'.tr()
                              : 'finance.newSubscription'.tr(),
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
                        const SizedBox(height: 8),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: vm.subscriptionReminder,
                          onChanged: vm.setSubscriptionReminder,
                          title: Text(
                            'finance.paymentReminder'.tr(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode
                                  ? ColorConstant.textPrimaryDark
                                  : ColorConstant.textPrimaryLight,
                            ),
                          ),
                          subtitle: Text(
                            'finance.paymentReminderSub'.tr(),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDarkMode
                                  ? ColorConstant.textSecondaryDark
                                  : ColorConstant.textSecondaryLight,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
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
                                onPressed: () => vm.isEditingSubscription
                                    ? vm.updateSubscription(
                                        vm.editingSubscriptionId!, context)
                                    : vm.createSubscription(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: ColorConstant.accentBlue,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  vm.isEditingSubscription
                                      ? 'finance.update'.tr()
                                      : 'finance.add'.tr(),
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
                vm.isEditingTxn
                    ? (income
                        ? 'finance.editIncome'.tr()
                        : 'finance.editExpense'.tr())
                    : (income
                        ? 'finance.newIncome'.tr()
                        : 'finance.newExpense'.tr()),
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
            Text(AppCurrency.symbol,
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
          child: Text('${AppCurrency.code} ${AppCurrency.symbol}',
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
            leading: const Icon(Icons.document_scanner_rounded, color: _fOrange),
            title: Text('finance.ocr.scanCamera'.tr(),
                style: TextStyle(
                    color: c.textPrimary, fontWeight: FontWeight.w700)),
            subtitle: Text('finance.ocr.sub'.tr(),
                style: TextStyle(color: c.textSecondary, fontSize: 12)),
            onTap: () {
              Navigator.pop(ctx);
              vm.scanReceipt(context, ImageSource.camera);
            },
          ),
          ListTile(
            leading: const Icon(Icons.image_search_rounded, color: _fOrange),
            title: Text('finance.ocr.scanGallery'.tr(),
                style: TextStyle(
                    color: c.textPrimary, fontWeight: FontWeight.w700)),
            onTap: () {
              Navigator.pop(ctx);
              vm.scanReceipt(context, ImageSource.gallery);
            },
          ),
          Divider(color: c.border.withOpacity(0.5), height: 1),
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
                  : ColorConstant.cardColorLight,
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
                            prefixText: '${AppCurrency.symbol} ',
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
                        InkWell(
                          onTap: () =>
                              _showFinanceLockDialog(context, vm, isDarkMode),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? ColorConstant.bgColorDark
                                  : ColorConstant.bgColorLight,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  vm.financeHasPin
                                      ? Icons.lock_rounded
                                      : Icons.lock_open_rounded,
                                  color: _fOrange,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'finance.lock.title'.tr(),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: isDarkMode
                                              ? ColorConstant.textPrimaryDark
                                              : ColorConstant.textPrimaryLight,
                                        ),
                                      ),
                                      Text(
                                        vm.financeHasPin
                                            ? 'finance.lock.on'.tr()
                                            : 'finance.lock.off'.tr(),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDarkMode
                                              ? ColorConstant.textSecondaryDark
                                              : ColorConstant
                                                  .textSecondaryLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right,
                                    color: isDarkMode
                                        ? ColorConstant.textSecondaryDark
                                        : ColorConstant.textSecondaryLight),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () => _showCategoryBudgetsDialog(
                              context, vm, isDarkMode),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? ColorConstant.bgColorDark
                                  : ColorConstant.bgColorLight,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.pie_chart_outline_rounded,
                                    color: _fOrange),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'finance.catBudget.title'.tr(),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: isDarkMode
                                              ? ColorConstant.textPrimaryDark
                                              : ColorConstant.textPrimaryLight,
                                        ),
                                      ),
                                      Text(
                                        vm.categoryBudgets.isEmpty
                                            ? 'finance.catBudget.none'.tr()
                                            : 'finance.catBudget.count'.tr(
                                                namedArgs: {
                                                    'count':
                                                        '${vm.categoryBudgets.length}'
                                                  }),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDarkMode
                                              ? ColorConstant.textSecondaryDark
                                              : ColorConstant
                                                  .textSecondaryLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right,
                                    color: isDarkMode
                                        ? ColorConstant.textSecondaryDark
                                        : ColorConstant.textSecondaryLight),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () =>
                              _showDebtPlannerDialog(context, vm, isDarkMode),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? ColorConstant.bgColorDark
                                  : ColorConstant.bgColorLight,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.trending_down_rounded,
                                    color: _fOrange),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'finance.debt.title'.tr(),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: isDarkMode
                                              ? ColorConstant.textPrimaryDark
                                              : ColorConstant.textPrimaryLight,
                                        ),
                                      ),
                                      Text(
                                        vm.debts.isEmpty
                                            ? 'finance.debt.none'.tr()
                                            : 'finance.debt.total'.tr(namedArgs: {
                                                'amount': tl0(vm.totalDebt)
                                              }),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDarkMode
                                              ? ColorConstant.textSecondaryDark
                                              : ColorConstant
                                                  .textSecondaryLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right,
                                    color: isDarkMode
                                        ? ColorConstant.textSecondaryDark
                                        : ColorConstant.textSecondaryLight),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () =>
                              _showInstallmentsDialog(context, vm, isDarkMode),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? ColorConstant.bgColorDark
                                  : ColorConstant.bgColorLight,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.credit_card_rounded, color: _fOrange),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'finance.installment.title'.tr(),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: isDarkMode
                                              ? ColorConstant.textPrimaryDark
                                              : ColorConstant.textPrimaryLight,
                                        ),
                                      ),
                                      Text(
                                        vm.installments.isEmpty
                                            ? 'finance.installment.none'.tr()
                                            : 'finance.installment.monthly'.tr(
                                                namedArgs: {
                                                    'amount': tl0(
                                                        vm.monthlyInstallmentTotal)
                                                  }),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDarkMode
                                              ? ColorConstant.textSecondaryDark
                                              : ColorConstant
                                                  .textSecondaryLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right,
                                    color: isDarkMode
                                        ? ColorConstant.textSecondaryDark
                                        : ColorConstant.textSecondaryLight),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () => _showCurrencyDialog(
                              context, vm, isDarkMode,
                              popParent: true),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? ColorConstant.bgColorDark
                                  : ColorConstant.bgColorLight,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.payments_rounded, color: _fOrange),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'finance.currency.title'.tr(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: isDarkMode
                                          ? ColorConstant.textPrimaryDark
                                          : ColorConstant.textPrimaryLight,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${AppCurrency.code} ${AppCurrency.symbol}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: isDarkMode
                                        ? ColorConstant.textSecondaryDark
                                        : ColorConstant.textSecondaryLight,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(Icons.chevron_right,
                                    color: isDarkMode
                                        ? ColorConstant.textSecondaryDark
                                        : ColorConstant.textSecondaryLight),
                              ],
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
                                  'common.save'.tr(),
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
                    : ColorConstant.cardColorLight,
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
                    : ColorConstant.cardColorLight,
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
                  : ColorConstant.cardColorLight,
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
                          '${AppCurrency.symbol}${totalYearSpending.toStringAsFixed(0)}',
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
                  '${AppCurrency.symbol}${total.toStringAsFixed(2)}',
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
                              '${AppCurrency.symbol}${categoryTotal.toStringAsFixed(0)}',
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
                isDarkMode ? ColorConstant.cardColorDark : ColorConstant.cardColorLight,
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

// ==================== EDIT EXPENSE BOTTOM SHEET ====================

// ==================== FİNANS KİLİDİ ====================

void _showFinanceLockDialog(
    BuildContext context, FinanceViewModel vm, bool isDark) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _FinanceLockSettingsSheet(vm: vm, isDark: isDark),
  );
}

/// Finans ekranı kilitliyken gösterilen PIN giriş kapısı.
class _FinanceLockGate extends StatefulWidget {
  final FinanceViewModel vm;
  final AppColors c;
  const _FinanceLockGate({required this.vm, required this.c});

  @override
  State<_FinanceLockGate> createState() => _FinanceLockGateState();
}

class _FinanceLockGateState extends State<_FinanceLockGate> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final pin = _ctrl.text.trim();
    if (pin.length < 4) return;
    final ok = await widget.vm.verifyFinancePin(pin);
    _ctrl.clear();
    if (ok) {
      await widget.vm.loadAfterUnlock();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final vm = widget.vm;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_rounded, size: 64, color: _fOrange),
            const SizedBox(height: 20),
            Text(
              'finance.lock.enterTitle'.tr(),
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: c.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'finance.lock.enterSub'.tr(),
              style: TextStyle(fontSize: 14, color: c.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: 220,
              child: TextField(
                controller: _ctrl,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 12,
                textAlign: TextAlign.center,
                autofocus: true,
                style: TextStyle(
                    fontSize: 28,
                    letterSpacing: 10,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: c.card,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _submit(),
              ),
            ),
            if (vm.pinError != null) ...[
              const SizedBox(height: 12),
              Text(vm.pinError!,
                  style: const TextStyle(color: Colors.red, fontSize: 13)),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: 220,
              child: ElevatedButton(
                onPressed: vm.pinBusy ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _fOrange,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: vm.pinBusy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text('finance.lock.unlock'.tr(),
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// PIN kurma / değiştirme / kaldırma sheet'i.
class _FinanceLockSettingsSheet extends StatefulWidget {
  final FinanceViewModel vm;
  final bool isDark;
  const _FinanceLockSettingsSheet({required this.vm, required this.isDark});

  @override
  State<_FinanceLockSettingsSheet> createState() =>
      _FinanceLockSettingsSheetState();
}

class _FinanceLockSettingsSheetState extends State<_FinanceLockSettingsSheet> {
  final _current = TextEditingController();
  final _pin = TextEditingController();
  final _confirm = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _pin.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _save() async {
    final vm = widget.vm;
    final hasPin = vm.financeHasPin;
    final pin = _pin.text.trim();
    if (pin.length < 4) {
      setState(() => _error = 'finance.lock.minLen'.tr());
      return;
    }
    if (pin != _confirm.text.trim()) {
      setState(() => _error = 'finance.lock.mismatch'.tr());
      return;
    }
    setState(() => _error = null);
    final ok = await vm.setFinancePin(pin,
        currentPin: hasPin ? _current.text.trim() : null);
    if (ok) {
      if (mounted) Navigator.pop(context);
      _toast('finance.lock.saved'.tr());
    } else {
      setState(() => _error = 'finance.lock.saveFailed'.tr());
    }
  }

  Future<void> _remove() async {
    final ok = await widget.vm.removeFinancePin(_current.text.trim());
    if (ok) {
      if (mounted) Navigator.pop(context);
      _toast('finance.lock.removed'.tr());
    } else {
      setState(() => _error = 'finance.lock.wrongPin'.tr());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final vm = widget.vm;
    final hasPin = vm.financeHasPin;
    final Color txtPrimary = isDark
        ? ColorConstant.textPrimaryDark
        : ColorConstant.textPrimaryLight;
    InputDecoration dec(String label) => InputDecoration(
          labelText: label,
          filled: true,
          fillColor:
              isDark ? ColorConstant.bgColorDark : ColorConstant.bgColorLight,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        );
    return Container(
      decoration: BoxDecoration(
        color: isDark ? ColorConstant.cardColorDark : ColorConstant.cardColorLight,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 20,
            bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                hasPin
                    ? 'finance.lock.changeTitle'.tr()
                    : 'finance.lock.setTitle'.tr(),
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: txtPrimary),
              ),
              const SizedBox(height: 20),
              if (hasPin) ...[
                TextField(
                  controller: _current,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 12,
                  style: TextStyle(color: txtPrimary),
                  decoration: dec('finance.lock.currentPin'.tr())
                      .copyWith(counterText: ''),
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: _pin,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 12,
                style: TextStyle(color: txtPrimary),
                decoration:
                    dec('finance.lock.newPin'.tr()).copyWith(counterText: ''),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _confirm,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 12,
                style: TextStyle(color: txtPrimary),
                decoration: dec('finance.lock.confirmPin'.tr())
                    .copyWith(counterText: ''),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!,
                    style: const TextStyle(color: Colors.red, fontSize: 13)),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: vm.pinBusy ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _fOrange,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text('common.save'.tr(),
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700)),
              ),
              if (hasPin) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: vm.pinBusy ? null : _remove,
                  child: Text('finance.lock.remove'.tr(),
                      style: const TextStyle(color: Colors.red)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== KATEGORİ BÜTÇELERİ ====================

void _showCategoryBudgetsDialog(
    BuildContext context, FinanceViewModel vm, bool isDark) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CategoryBudgetsSheet(vm: vm, isDark: isDark),
  );
}

class _CategoryBudgetsSheet extends StatefulWidget {
  final FinanceViewModel vm;
  final bool isDark;
  const _CategoryBudgetsSheet({required this.vm, required this.isDark});

  @override
  State<_CategoryBudgetsSheet> createState() => _CategoryBudgetsSheetState();
}

class _CategoryBudgetsSheetState extends State<_CategoryBudgetsSheet> {
  late final Map<String, TextEditingController> _ctrls;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _ctrls = {
      for (final c in kFinCats)
        c.id: TextEditingController(
          text: widget.vm.categoryLimit(c.id) > 0
              ? widget.vm.categoryLimit(c.id).toStringAsFixed(0)
              : '',
        )
    };
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    for (final c in kFinCats) {
      final txt = _ctrls[c.id]!.text.trim().replaceAll(',', '.');
      final val = double.tryParse(txt) ?? 0;
      final existing = widget.vm.categoryLimit(c.id);
      if (val > 0 && val != existing) {
        await widget.vm.setCategoryBudget(c.id, val);
      } else if (val <= 0 && existing > 0) {
        await widget.vm.removeCategoryBudget(c.id);
      }
    }
    setState(() => _saving = false);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final vm = widget.vm;
    final totals = vm.categoryTotals;
    final Color txtPrimary = isDark
        ? ColorConstant.textPrimaryDark
        : ColorConstant.textPrimaryLight;
    final Color txtSec = isDark
        ? ColorConstant.textSecondaryDark
        : ColorConstant.textSecondaryLight;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? ColorConstant.cardColorDark : ColorConstant.cardColorLight,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('finance.catBudget.title'.tr(),
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: txtPrimary)),
                const SizedBox(height: 4),
                Text('finance.catBudget.sub'.tr(),
                    style: TextStyle(fontSize: 13, color: txtSec)),
                const SizedBox(height: 16),
                ...kFinCats.map((c) {
                  final spent = totals[c.id] ?? 0;
                  final limit = double.tryParse(
                          _ctrls[c.id]!.text.replaceAll(',', '.')) ??
                      0;
                  final ratio = limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0;
                  final over = limit > 0 && spent > limit;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(c.icon, size: 20, color: c.color),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(c.labelKey.tr(),
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: txtPrimary))),
                            SizedBox(
                              width: 120,
                              child: TextField(
                                controller: _ctrls[c.id],
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.end,
                                style: TextStyle(color: txtPrimary),
                                onChanged: (_) => setState(() {}),
                                decoration: InputDecoration(
                                  isDense: true,
                                  prefixText: '${AppCurrency.symbol} ',
                                  hintText: '0',
                                  filled: true,
                                  fillColor: isDark
                                      ? ColorConstant.bgColorDark
                                      : ColorConstant.bgColorLight,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: ratio,
                            minHeight: 6,
                            backgroundColor: isDark
                                ? ColorConstant.bgColorDark
                                : ColorConstant.bgColorLight,
                            color: over ? Colors.red : c.color,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${tl0(spent)} / ${limit > 0 ? tl0(limit) : '—'}',
                          style: TextStyle(
                              fontSize: 11, color: over ? Colors.red : txtSec),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _fOrange,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text('common.save'.tr(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== BORÇ PLANLAYICI ====================

void _showDebtPlannerDialog(
    BuildContext context, FinanceViewModel vm, bool isDark) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _DebtPlannerSheet(vm: vm, isDark: isDark),
  );
}

class _DebtPlannerSheet extends StatefulWidget {
  final FinanceViewModel vm;
  final bool isDark;
  const _DebtPlannerSheet({required this.vm, required this.isDark});

  @override
  State<_DebtPlannerSheet> createState() => _DebtPlannerSheetState();
}

class _DebtPlannerSheetState extends State<_DebtPlannerSheet> {
  String _strategy = 'avalanche';
  final _extra = TextEditingController();
  bool _adding = false;
  final _name = TextEditingController();
  final _balance = TextEditingController();
  final _rate = TextEditingController();
  final _min = TextEditingController();

  @override
  void dispose() {
    _extra.dispose();
    _name.dispose();
    _balance.dispose();
    _rate.dispose();
    _min.dispose();
    super.dispose();
  }

  double get _extraVal =>
      double.tryParse(_extra.text.trim().replaceAll(',', '.')) ?? 0;

  Future<void> _add() async {
    final name = _name.text.trim();
    final bal = double.tryParse(_balance.text.trim().replaceAll(',', '.')) ?? 0;
    if (name.isEmpty || bal <= 0) return;
    final rate = double.tryParse(_rate.text.trim().replaceAll(',', '.')) ?? 0;
    final min = double.tryParse(_min.text.trim().replaceAll(',', '.')) ?? 0;
    final ok = await widget.vm.addDebt(name, bal, rate, min);
    if (ok) {
      _name.clear();
      _balance.clear();
      _rate.clear();
      _min.clear();
      setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final vm = widget.vm;
    final Color txtPrimary = isDark
        ? ColorConstant.textPrimaryDark
        : ColorConstant.textPrimaryLight;
    final Color txtSec = isDark
        ? ColorConstant.textSecondaryDark
        : ColorConstant.textSecondaryLight;
    final Color bg =
        isDark ? ColorConstant.bgColorDark : ColorConstant.bgColorLight;
    final plan = vm.computeDebtPlan(extra: _extraVal, strategy: _strategy);

    InputDecoration dec(String label) => InputDecoration(
          labelText: label,
          isDense: true,
          filled: true,
          fillColor: bg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        );

    Widget stratChip(String id, String label) {
      final sel = _strategy == id;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _strategy = id),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: sel ? _fOrange : bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: sel ? Colors.white : txtSec)),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? ColorConstant.cardColorDark : ColorConstant.cardColorLight,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('finance.debt.title'.tr(),
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: txtPrimary)),
                const SizedBox(height: 4),
                Text(
                  '${'finance.debt.total'.tr(namedArgs: {
                        'amount': tl0(vm.totalDebt)
                      })} · ${'finance.debt.minTotal'.tr(namedArgs: {
                        'amount': tl0(vm.totalMinPayment)
                      })}',
                  style: TextStyle(fontSize: 13, color: txtSec),
                ),
                const SizedBox(height: 16),
                // Strateji
                Row(children: [
                  stratChip('avalanche', 'finance.debt.avalanche'.tr()),
                  stratChip('snowball', 'finance.debt.snowball'.tr()),
                ]),
                const SizedBox(height: 6),
                Text(
                  _strategy == 'avalanche'
                      ? 'finance.debt.avalancheSub'.tr()
                      : 'finance.debt.snowballSub'.tr(),
                  style: TextStyle(fontSize: 11, color: txtSec),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _extra,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: txtPrimary),
                  onChanged: (_) => setState(() {}),
                  decoration: dec('finance.debt.extra'.tr())
                      .copyWith(prefixText: '${AppCurrency.symbol} '),
                ),
                const SizedBox(height: 16),
                // Plan sonucu
                if (vm.debts.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _fOrange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.unpayable
                              ? 'finance.debt.unpayable'.tr()
                              : 'finance.debt.result'.tr(namedArgs: {
                                  'months': '${plan.months}',
                                  'interest': tl0(plan.totalInterest),
                                }),
                          style: TextStyle(
                              fontWeight: FontWeight.w700, color: txtPrimary),
                        ),
                        if (!plan.unpayable && plan.order.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            '${'finance.debt.order'.tr()}: ${plan.order.join(' → ')}',
                            style: TextStyle(fontSize: 12, color: txtSec),
                          ),
                        ],
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                // Borç listesi
                ...vm.debts.map((d) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(d.name,
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: txtPrimary)),
                                Text(
                                  '${tl0(d.balance)} · %${d.interestRate.toStringAsFixed(d.interestRate.truncateToDouble() == d.interestRate ? 0 : 1)} · ${'finance.debt.min'.tr()} ${tl0(d.minPayment)}',
                                  style:
                                      TextStyle(fontSize: 11, color: txtSec),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red, size: 20),
                            onPressed: () => vm.deleteDebt(d.id),
                          ),
                        ],
                      ),
                    )),
                // Borç ekleme
                if (_adding) ...[
                  TextField(
                      controller: _name,
                      style: TextStyle(color: txtPrimary),
                      decoration: dec('finance.debt.name'.tr())),
                  const SizedBox(height: 8),
                  TextField(
                      controller: _balance,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: txtPrimary),
                      decoration: dec('finance.debt.balance'.tr())
                          .copyWith(prefixText: '${AppCurrency.symbol} ')),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                        child: TextField(
                            controller: _rate,
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: txtPrimary),
                            decoration: dec('finance.debt.rate'.tr())
                                .copyWith(suffixText: '%'))),
                    const SizedBox(width: 8),
                    Expanded(
                        child: TextField(
                            controller: _min,
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: txtPrimary),
                            decoration: dec('finance.debt.min'.tr())
                                .copyWith(prefixText: '${AppCurrency.symbol} '))),
                  ]),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _add,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _fOrange,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    child: Text('common.save'.tr(),
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ] else
                  OutlinedButton.icon(
                    onPressed: () => setState(() => _adding = true),
                    icon: const Icon(Icons.add, color: _fOrange),
                    label: Text('finance.debt.add'.tr(),
                        style: const TextStyle(color: _fOrange)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: _fOrange),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== TAKSİTLER ====================

void _showInstallmentsDialog(
    BuildContext context, FinanceViewModel vm, bool isDark) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _InstallmentsSheet(vm: vm, isDark: isDark),
  );
}

String _fmtDmy(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

class _InstallmentsSheet extends StatefulWidget {
  final FinanceViewModel vm;
  final bool isDark;
  const _InstallmentsSheet({required this.vm, required this.isDark});

  @override
  State<_InstallmentsSheet> createState() => _InstallmentsSheetState();
}

class _InstallmentsSheetState extends State<_InstallmentsSheet> {
  bool _adding = false;
  final _name = TextEditingController();
  final _total = TextEditingController();
  final _count = TextEditingController();
  DateTime _start = DateTime.now();

  @override
  void dispose() {
    _name.dispose();
    _total.dispose();
    _count.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final name = _name.text.trim();
    final total = double.tryParse(_total.text.trim().replaceAll(',', '.')) ?? 0;
    final count = int.tryParse(_count.text.trim()) ?? 0;
    if (name.isEmpty || total <= 0 || count < 1) return;
    final startStr =
        '${_start.year}-${_start.month.toString().padLeft(2, '0')}-${_start.day.toString().padLeft(2, '0')}';
    final ok = await widget.vm.addInstallment(name, total, count, 0, startStr);
    if (ok) {
      _name.clear();
      _total.clear();
      _count.clear();
      setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final vm = widget.vm;
    final Color txtPrimary = isDark
        ? ColorConstant.textPrimaryDark
        : ColorConstant.textPrimaryLight;
    final Color txtSec = isDark
        ? ColorConstant.textSecondaryDark
        : ColorConstant.textSecondaryLight;
    final Color bg =
        isDark ? ColorConstant.bgColorDark : ColorConstant.bgColorLight;

    InputDecoration dec(String label) => InputDecoration(
          labelText: label,
          isDense: true,
          filled: true,
          fillColor: bg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        );

    return Container(
      decoration: BoxDecoration(
        color: isDark ? ColorConstant.cardColorDark : ColorConstant.cardColorLight,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('finance.installment.title'.tr(),
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: txtPrimary)),
                const SizedBox(height: 4),
                Text(
                  'finance.installment.monthly'.tr(
                      namedArgs: {'amount': tl0(vm.monthlyInstallmentTotal)}),
                  style: TextStyle(fontSize: 13, color: txtSec),
                ),
                const SizedBox(height: 16),
                ...vm.installments.map((it) {
                  final ratio = it.installmentCount > 0
                      ? (it.paidCount / it.installmentCount).clamp(0.0, 1.0)
                      : 0.0;
                  final next = it.nextDueDate;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(it.name,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: txtPrimary)),
                            ),
                            Text('${it.paidCount}/${it.installmentCount}',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: txtSec)),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red, size: 20),
                              onPressed: () => vm.deleteInstallment(it.id),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: ratio,
                            minHeight: 6,
                            backgroundColor: isDark
                                ? ColorConstant.cardColorDark
                                : ColorConstant.cardColorLight,
                            color: it.isDone ? Colors.green : _fOrange,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                it.isDone
                                    ? '${tl0(it.monthlyAmount)} · ${'finance.installment.done'.tr()}'
                                    : '${tl0(it.monthlyAmount)}/${'finance.installment.month'.tr()} · ${'finance.installment.remaining'.tr(namedArgs: {
                                            'amount': tl0(it.remainingAmount)
                                          })}${next != null ? ' · ${'finance.installment.next'.tr()} ${_fmtDmy(next)}' : ''}',
                                style:
                                    TextStyle(fontSize: 11, color: txtSec),
                              ),
                            ),
                            if (!it.isDone)
                              TextButton(
                                onPressed: () => vm.markInstallmentPaid(it.id),
                                child: Text('finance.installment.pay'.tr(),
                                    style: const TextStyle(
                                        color: _fOrange,
                                        fontWeight: FontWeight.w700)),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
                if (_adding) ...[
                  TextField(
                      controller: _name,
                      style: TextStyle(color: txtPrimary),
                      decoration: dec('finance.installment.name'.tr())),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                        child: TextField(
                            controller: _total,
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: txtPrimary),
                            decoration: dec('finance.installment.total'.tr())
                                .copyWith(prefixText: '${AppCurrency.symbol} '))),
                    const SizedBox(width: 8),
                    Expanded(
                        child: TextField(
                            controller: _count,
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: txtPrimary),
                            decoration:
                                dec('finance.installment.count'.tr()))),
                  ]),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _start,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );
                      if (picked != null) setState(() => _start = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(12)),
                      child: Row(children: [
                        Icon(Icons.calendar_today_rounded,
                            size: 18, color: txtSec),
                        const SizedBox(width: 10),
                        Text(
                            '${'finance.installment.start'.tr()}: ${_fmtDmy(_start)}',
                            style: TextStyle(color: txtPrimary)),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _add,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _fOrange,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    child: Text('common.save'.tr(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700)),
                  ),
                ] else
                  OutlinedButton.icon(
                    onPressed: () => setState(() => _adding = true),
                    icon: const Icon(Icons.add, color: _fOrange),
                    label: Text('finance.installment.add'.tr(),
                        style: const TextStyle(color: _fOrange)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: _fOrange),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== PARA BİRİMİ ====================

void _showCurrencyDialog(BuildContext context, FinanceViewModel vm, bool isDark,
    {bool popParent = false}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) {
      final Color txtPrimary = isDark
          ? ColorConstant.textPrimaryDark
          : ColorConstant.textPrimaryLight;
      final Color txtSec = isDark
          ? ColorConstant.textSecondaryDark
          : ColorConstant.textSecondaryLight;
      return Container(
        decoration: BoxDecoration(
          color: isDark ? ColorConstant.cardColorDark : ColorConstant.cardColorLight,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('finance.currency.title'.tr(),
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: txtPrimary)),
                const SizedBox(height: 4),
                Text('finance.currency.sub'.tr(),
                    style: TextStyle(fontSize: 13, color: txtSec)),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: AppCurrency.currencies.entries.map((e) {
                      final sel = e.key == AppCurrency.code;
                      return InkWell(
                        onTap: () async {
                          await AppCurrency.setCode(e.key);
                          vm.refreshFormatting();
                          // Para birimi sheet'ini kapat.
                          if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                          // Yalnızca üstteki başka bir sheet'ten açıldıysa onu
                          // da kapat (satır içi ayarlar listesinden açıldığında
                          // bu, tüm Finans sayfasını kapatıp boş ekrana yol
                          // açıyordu).
                          if (popParent && context.mounted) {
                            Navigator.pop(context);
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: sel
                                ? _fOrange.withValues(alpha: 0.14)
                                : (isDark
                                    ? ColorConstant.bgColorDark
                                    : ColorConstant.bgColorLight),
                            borderRadius: BorderRadius.circular(12),
                            border: sel
                                ? Border.all(color: _fOrange, width: 1.5)
                                : null,
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 34,
                                child: Text(e.value[0],
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: txtPrimary)),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text('${e.key} · ${e.value[2]}',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: txtPrimary)),
                              ),
                              if (sel)
                                const Icon(Icons.check_circle,
                                    color: _fOrange, size: 20),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
