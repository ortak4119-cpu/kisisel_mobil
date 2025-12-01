import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/utils/color_constant.dart';
import '../../../core/utils/subscription_icons.dart';
import '../../../core/route/app_router.gr.dart';
import '../viewmodel/finance_viewmodel.dart';

class FinanceView extends StatefulWidget {
  const FinanceView({super.key});

  @override
  State<FinanceView> createState() => _FinanceViewState();
}

class _FinanceViewState extends State<FinanceView> {
  int _getUpcomingCount(FinanceViewModel viewModel) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return viewModel.activeSubscriptions
        .where((sub) {
      final billingDate = DateTime(
        sub.nextBillingDate.year,
        sub.nextBillingDate.month,
        sub.nextBillingDate.day,
      );
      return billingDate.isAtSameMomentAs(today) || billingDate.isAfter(today);
    })
        .length;
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FinanceViewModel()..refreshAll(),
      child: Consumer<FinanceViewModel>(
        builder: (context, viewModel, _) {
          final isDarkMode = Theme.of(context).brightness == Brightness.dark;

          return Scaffold(
            backgroundColor: isDarkMode
                ? ColorConstant.bgColorDark
                : ColorConstant.bgColorLight,
            body: SafeArea(
              child: viewModel.isLoading
                  ? Center(
                child: CircularProgressIndicator(
                  color: ColorConstant.accentBlue,
                ),
              )
                  : RefreshIndicator(
                onRefresh: () => viewModel.refreshAll(),
                color: ColorConstant.accentBlue,
                child: CustomScrollView(
                  slivers: [
                    // App Bar
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'finance.title'.tr(),
                                style: TextStyle(
                                  color: isDarkMode
                                      ? ColorConstant.textPrimaryDark
                                      : ColorConstant.textPrimaryLight,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                // Premium Button
                                Container(
                                  margin: const EdgeInsets.only(right: 4),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        ColorConstant.accentYellow,
                                        ColorConstant.accentOrange,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: ColorConstant.accentYellow.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () => context.router.push(const PaywallRoute()),
                                      borderRadius: BorderRadius.circular(12),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Icon(
                                          Icons.workspace_premium_rounded,
                                          color: ColorConstant.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    viewModel.budgetAmountController.text =
                                        viewModel.budgetStats?.monthlyBudget
                                            .toStringAsFixed(0) ??
                                            '';
                                    _showBudgetSettingsDialog(
                                        context, viewModel, isDarkMode);
                                  },
                                  icon: Icon(
                                    Icons.settings_outlined,
                                    color: isDarkMode
                                        ? ColorConstant.textSecondaryDark
                                        : ColorConstant.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Today Section
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'finance.today'.tr(),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: isDarkMode
                                    ? ColorConstant.textPrimaryDark
                                    : ColorConstant.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildTodayCard(viewModel, isDarkMode),
                          ],
                        ),
                      ),
                    ),

                    // This Month Section
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_month_rounded,
                                      size: 20,
                                      color: isDarkMode
                                          ? ColorConstant.textSecondaryDark
                                          : ColorConstant.textSecondaryLight,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'finance.thisMonth'.tr(),
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: isDarkMode
                                            ? ColorConstant.textPrimaryDark
                                            : ColorConstant.textPrimaryLight,
                                      ),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  onPressed: () => _showMonthlyStatisticsDialog(
                                      context, viewModel, isDarkMode),
                                  icon: Icon(
                                    Icons.bar_chart_rounded,
                                    color: ColorConstant.accentBlue,
                                    size: 24,
                                  ),
                                  tooltip: 'finance.monthlyStats'.tr(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (viewModel.budgetStats != null)
                              _buildMonthlyBudgetCard(
                                  context, viewModel, viewModel.budgetStats!, isDarkMode),
                          ],
                        ),
                      ),
                    ),

                    // Upcoming Payments Section
                    if (viewModel.activeSubscriptions.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.schedule_rounded,
                                        size: 20,
                                        color: isDarkMode
                                            ? ColorConstant.textSecondaryDark
                                            : ColorConstant.textSecondaryLight,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'finance.upcomingPayments'.tr(),
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                          color: isDarkMode
                                              ? ColorConstant.textPrimaryDark
                                              : ColorConstant.textPrimaryLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (viewModel.subscriptionStats != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: ColorConstant.accentBlue
                                            .withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '₺${viewModel.subscriptionStats!.monthlyEquivalent.toStringAsFixed(0)}/ay',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: ColorConstant.accentBlue,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              ..._buildUpcomingSubscriptions(
                                  context, viewModel, isDarkMode),
                              // Show All / Show Less button
                              if (_getUpcomingCount(viewModel) > 3)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: TextButton.icon(
                                    onPressed: () => viewModel.toggleShowAllSubscriptions(),
                                    icon: Icon(
                                      viewModel.showAllSubscriptions
                                          ? Icons.expand_less_rounded
                                          : Icons.expand_more_rounded,
                                      size: 20,
                                    ),
                                    label: Text(
                                      viewModel.showAllSubscriptions
                                          ? 'common.showLess'.tr()
                                          : 'common.showAll'.tr(),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    style: TextButton.styleFrom(
                                      foregroundColor: ColorConstant.accentBlue,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                    // Recent Activities Section
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.history_rounded,
                                  size: 20,
                                  color: isDarkMode
                                      ? ColorConstant.textSecondaryDark
                                      : ColorConstant.textSecondaryLight,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'finance.recentActivities'.tr(),
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: isDarkMode
                                        ? ColorConstant.textPrimaryDark
                                        : ColorConstant.textPrimaryLight,
                                  ),
                                ),
                              ],
                            ),
                            TextButton.icon(
                              onPressed: () => _showExpenseFilterDialog(
                                  context, viewModel, isDarkMode),
                              icon: Icon(
                                Icons.filter_list_rounded,
                                size: 18,
                                color: ColorConstant.accentBlue,
                              ),
                              label: Text(
                                'finance.filter'.tr(),
                                style: TextStyle(
                                  color: ColorConstant.accentBlue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Activities List
                    if (viewModel.expenses.isNotEmpty && viewModel.filteredExpenses.isEmpty)
                      SliverToBoxAdapter(
                        child: _buildEmptyState(
                          icon: Icons.filter_alt_off_rounded,
                          message: 'finance.noExpensesInFilter'.tr(),
                          color: ColorConstant.accentBlue,
                          isDarkMode: isDarkMode,
                        ),
                      )
                    else if (viewModel.filteredExpenses.isNotEmpty)
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                                (context, index) {
                              return _buildExpenseCard(
                                context,
                                viewModel.filteredExpenses[index],
                                viewModel,
                                isDarkMode,
                              );
                            },
                            childCount: viewModel.filteredExpenses.length,
                          ),
                        ),
                      )
                    else
                      SliverToBoxAdapter(
                        child: _buildEmptyState(
                          icon: Icons.receipt_long_rounded,
                          message: 'finance.emptyState'.tr(),
                          color: ColorConstant.accentGreen,
                          isDarkMode: isDarkMode,
                        ),
                      ),

                    // Bottom Padding
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 80),
                    ),
                  ],
                ),
              ),
            ),
            floatingActionButton: _buildSpeedDial(context, viewModel, isDarkMode),
          );
        },
      ),
    );
  }

  Widget _buildTodayCard(FinanceViewModel viewModel, bool isDarkMode) {
    final todaySpent = viewModel.budgetStats?.todaySpent ?? 0.0;

    return Container(
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
            color: ColorConstant.accentBlue.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'finance.todayExpense'.tr(),
            style: TextStyle(
              color: ColorConstant.white.withOpacity(0.9),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₺${todaySpent.toStringAsFixed(2)}',
                style: TextStyle(
                  color: ColorConstant.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ColorConstant.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'finance.dailyAverage'.tr(),
                  style: TextStyle(
                    color: ColorConstant.white.withOpacity(0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '₺${_calculateDailyAverage(viewModel).toStringAsFixed(0)}',
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
    );
  }

  double _calculateDailyAverage(FinanceViewModel viewModel) {
    if (viewModel.budgetStats == null) return 0.0;
    final daysInMonth = DateTime.now().day;
    if (daysInMonth == 0) return 0.0;
    return viewModel.budgetStats!.totalSpent / daysInMonth;
  }

  Widget _buildMonthlyBudgetCard(
      BuildContext context,
      FinanceViewModel viewModel,
      stats,
      bool isDarkMode,
      ) {
    final percentage = stats.usagePercentage.clamp(0.0, 100.0);
    final isOverBudget = percentage > 100;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? ColorConstant.cardColorDark : ColorConstant.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDarkMode
              ? ColorConstant.borderColorDark
              : ColorConstant.borderColorLight,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'finance.monthlyBudget'.tr(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode
                          ? ColorConstant.textSecondaryDark
                          : ColorConstant.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₺${stats.remaining.toStringAsFixed(0)} ${'finance.remaining'.tr()}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: isOverBudget
                          ? ColorConstant.errorRed
                          : (isDarkMode
                          ? ColorConstant.textPrimaryDark
                          : ColorConstant.textPrimaryLight),
                    ),
                  ),
                ],
              ),
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        value: percentage / 100,
                        strokeWidth: 8,
                        backgroundColor: isDarkMode
                            ? ColorConstant.bgColorDark
                            : ColorConstant.bgColorLight,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isOverBudget
                              ? ColorConstant.errorRed
                              : percentage > 80
                              ? ColorConstant.accentYellow
                              : ColorConstant.accentGreen,
                        ),
                      ),
                    ),
                    Text(
                      '${percentage.toInt()}%',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: isDarkMode
                            ? ColorConstant.textPrimaryDark
                            : ColorConstant.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildBudgetDetail(
                  'finance.spent'.tr(),
                  stats.totalSpent,
                  ColorConstant.errorRed,
                  isDarkMode,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBudgetDetail(
                  'finance.monthlyBudget'.tr(),
                  stats.monthlyBudget,
                  ColorConstant.accentBlue,
                  isDarkMode,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetDetail(
      String label, double amount, Color color, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDarkMode
                  ? ColorConstant.textSecondaryDark
                  : ColorConstant.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '₺${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildUpcomingSubscriptions(
      BuildContext context,
      FinanceViewModel viewModel,
      bool isDarkMode,
      ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Sadece bugün ve gelecekteki ödemeleri filtrele
    final upcoming = List<dynamic>.from(viewModel.activeSubscriptions)
        .where((sub) {
      final billingDate = DateTime(
        sub.nextBillingDate.year,
        sub.nextBillingDate.month,
        sub.nextBillingDate.day,
      );
      return billingDate.isAtSameMomentAs(today) || billingDate.isAfter(today);
    })
        .toList()
      ..sort((a, b) => a.nextBillingDate.compareTo(b.nextBillingDate));

    final subscriptionsToShow = viewModel.showAllSubscriptions
        ? upcoming
        : upcoming.take(3);

    return subscriptionsToShow.map((sub) {
      final daysUntil = sub.nextBillingDate.difference(DateTime.now()).inDays;
      final isUrgent = daysUntil <= 5;

      return GestureDetector(
        onTap: () {
          _showEditSubscriptionSheet(context, viewModel, sub, isDarkMode);
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDarkMode ? ColorConstant.cardColorDark : ColorConstant.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isUrgent
                  ? ColorConstant.accentYellow.withOpacity(0.5)
                  : (isDarkMode
                  ? ColorConstant.borderColorDark
                  : ColorConstant.borderColorLight),
              width: isUrgent ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
            Builder(
              builder: (context) {
                final iconData = SubscriptionIcons.getIcon(sub.name) ??
                    SubscriptionIcons.getDefaultIcon();

                return Container(
                  width: 48,
                  height: 48,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDarkMode ? ColorConstant.bgColorDark : ColorConstant.bgColorLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: iconData.color.withOpacity(0.3),
                      width: 1.5,
                    ),
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
                            size: 24,
                          ),
                        )
                      : Icon(
                          iconData.icon,
                          color: iconData.color,
                          size: 24,
                        ),
                );
              },
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sub.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDarkMode
                          ? ColorConstant.textPrimaryDark
                          : ColorConstant.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        isUrgent
                            ? Icons.warning_amber_rounded
                            : Icons.schedule_rounded,
                        size: 14,
                        color: isUrgent
                            ? ColorConstant.accentYellow
                            : (isDarkMode
                            ? ColorConstant.textMutedDark
                            : ColorConstant.textMutedLight),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        daysUntil == 0
                            ? 'common.today'.tr()
                            : daysUntil == 1
                            ? 'finance.tomorrow'.tr()
                            : 'common.daysLater'.tr(namedArgs: {'count': '$daysUntil'}),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isUrgent ? FontWeight.w600 : FontWeight.w500,
                          color: isUrgent
                              ? ColorConstant.accentYellow
                              : (isDarkMode
                              ? ColorConstant.textSecondaryDark
                              : ColorConstant.textSecondaryLight),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Text(
              '₺${sub.amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDarkMode
                    ? ColorConstant.textPrimaryDark
                    : ColorConstant.textPrimaryLight,
              ),
            ),
          ],
        ),
        ),
      );
    }).toList();
  }

  Widget _buildExpenseCard(
      BuildContext context,
      expense,
      FinanceViewModel viewModel,
      bool isDarkMode,
      ) {
    return Dismissible(
      key: Key('expense_${expense.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: ColorConstant.errorRed,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(
          Icons.delete_outline_rounded,
          color: ColorConstant.white,
          size: 28,
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor:
            isDarkMode ? ColorConstant.cardColorDark : ColorConstant.white,
            title: Text(
              'finance.deleteExpense'.tr(),
              style: TextStyle(
                color: isDarkMode
                    ? ColorConstant.textPrimaryDark
                    : ColorConstant.textPrimaryLight,
              ),
            ),
            content: Text(
              'finance.deleteConfirm'.tr(),
              style: TextStyle(
                color: isDarkMode
                    ? ColorConstant.textSecondaryDark
                    : ColorConstant.textSecondaryLight,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('common.cancel'.tr()),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  'common.delete'.tr(),
                  style: TextStyle(color: ColorConstant.errorRed),
                ),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        viewModel.deleteExpense(expense.id, context);
      },
      child: GestureDetector(
        onTap: () {
          _showEditExpenseSheet(context, viewModel, expense, isDarkMode);
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDarkMode ? ColorConstant.cardColorDark : ColorConstant.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDarkMode
                  ? ColorConstant.borderColorDark
                  : ColorConstant.borderColorLight,
              width: 1,
            ),
          ),
          child: Row(
            children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: viewModel.getCategoryColor(expense.category).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  viewModel.getCategoryEmoji(expense.category),
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    viewModel.getCategoryLabel(expense.category),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDarkMode
                          ? ColorConstant.textPrimaryDark
                          : ColorConstant.textPrimaryLight,
                    ),
                  ),
                  if (expense.description != null &&
                      expense.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      expense.description!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDarkMode
                            ? ColorConstant.textSecondaryDark
                            : ColorConstant.textSecondaryLight,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 12,
                        color: isDarkMode
                            ? ColorConstant.textMutedDark
                            : ColorConstant.textMutedLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(expense.expenseDate),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode
                              ? ColorConstant.textMutedDark
                              : ColorConstant.textMutedLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Text(
              '-₺${expense.amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: ColorConstant.errorRed,
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildSpeedDial(
      BuildContext context,
      FinanceViewModel viewModel,
      bool isDarkMode,
      ) {
    return FloatingActionButton(
      heroTag: 'finance_fab',
      onPressed: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (context) => Container(
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? ColorConstant.borderColorDark
                          : ColorConstant.borderColorLight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildActionTile(
                    icon: Icons.shopping_bag_rounded,
                    title: 'finance.addExpense'.tr(),
                    color: ColorConstant.accentGreen,
                    onTap: () {
                      Navigator.pop(context);
                      _showAddExpenseDialog(context, viewModel, isDarkMode);
                    },
                    isDarkMode: isDarkMode,
                  ),
                  _buildActionTile(
                    icon: Icons.subscriptions_rounded,
                    title: 'finance.addSubscription'.tr(),
                    color: ColorConstant.accentBlue,
                    onTap: () {
                      Navigator.pop(context);
                      _showAddSubscriptionDialog(context, viewModel, isDarkMode);
                    },
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ColorConstant.accentBlue,
              const Color(0xFF667EEA),
            ],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: ColorConstant.accentBlue.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          Icons.add_rounded,
          color: ColorConstant.white,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: isDarkMode
              ? ColorConstant.textPrimaryDark
              : ColorConstant.textPrimaryLight,
        ),
      ),
      onTap: onTap,
    );
  }

  String _getPlatformEmoji(String? platform) {
    if (platform == null) return '💳';
    final p = platform.toLowerCase();
    if (p.contains('netflix')) return '🎬';
    if (p.contains('spotify')) return '🎵';
    if (p.contains('youtube')) return '▶️';
    if (p.contains('amazon')) return '📦';
    if (p.contains('apple')) return '🍎';
    if (p.contains('google')) return '🔍';
    if (p.contains('microsoft')) return '💻';
    if (p.contains('disney')) return '🏰';
    return '💳';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) return 'common.today'.tr();
    if (dateOnly == yesterday) return 'common.yesterday'.tr();
    return '${date.day}.${date.month}.${date.year}';
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    required Color color,
    required bool isDarkMode,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Icon(
              icon,
              size: 80,
              color: color.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDarkMode
                    ? ColorConstant.textSecondaryDark
                    : ColorConstant.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddSubscriptionDialog(
      BuildContext context,
      FinanceViewModel viewModel,
      bool isDarkMode,
      ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddSubscriptionBottomSheet(
        viewModel: viewModel,
        isDarkMode: isDarkMode,
      ),
    );
  }

  void _showAddExpenseDialog(
      BuildContext context,
      FinanceViewModel viewModel,
      bool isDarkMode,
      ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddExpenseBottomSheet(
        viewModel: viewModel,
        isDarkMode: isDarkMode,
      ),
    );
  }

  void _showEditSubscriptionSheet(
      BuildContext context,
      FinanceViewModel viewModel,
      dynamic subscription,
      bool isDarkMode,
      ) {
    // Form alanlarını mevcut subscription verileriyle doldur
    viewModel.subscriptionNameController.text = subscription.name;
    viewModel.subscriptionAmountController.text = subscription.amount.toString();
    viewModel.subscriptionBillingDateController.text = subscription.billingDate.toString();
    viewModel.setSubscriptionBillingCycle(subscription.billingCycle);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditSubscriptionBottomSheet(
        viewModel: viewModel,
        subscription: subscription,
        isDarkMode: isDarkMode,
      ),
    );
  }

  void _showEditExpenseSheet(
      BuildContext context,
      FinanceViewModel viewModel,
      dynamic expense,
      bool isDarkMode,
      ) {
    // Form alanlarını mevcut expense verileriyle doldur
    viewModel.expenseAmountController.text = expense.amount.toString();
    viewModel.expenseDescriptionController.text = expense.description ?? '';
    viewModel.setExpenseCategory(expense.category);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditExpenseBottomSheet(
        viewModel: viewModel,
        expense: expense,
        isDarkMode: isDarkMode,
      ),
    );
  }

  void _showBudgetSettingsDialog(
      BuildContext context,
      FinanceViewModel viewModel,
      bool isDarkMode,
      ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BudgetSettingsBottomSheet(
        viewModel: viewModel,
        isDarkMode: isDarkMode,
      ),
    );
  }

  void _showExpenseFilterDialog(
      BuildContext context,
      FinanceViewModel viewModel,
      bool isDarkMode,
      ) {
    showDialog(
      context: context,
      builder: (context) => _ExpenseFilterDialog(
        viewModel: viewModel,
        isDarkMode: isDarkMode,
      ),
    );
  }

  void _showMonthlyStatisticsDialog(
      BuildContext context,
      FinanceViewModel viewModel,
      bool isDarkMode,
      ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MonthlyStatisticsBottomSheet(
        viewModel: viewModel,
        isDarkMode: isDarkMode,
      ),
    );
  }
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
                            final iconData = SubscriptionIcons.getIcon(value.text) ??
                                SubscriptionIcons.getDefaultIcon();

                            return Center(
                              child: Container(
                                width: 80,
                                height: 80,
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: isDarkMode ? ColorConstant.bgColorDark : ColorConstant.bgColorLight,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: iconData.color.withOpacity(0.3),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: iconData.color.withOpacity(0.2),
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
                                  padding: const EdgeInsets.symmetric(vertical: 16),
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
                                  padding: const EdgeInsets.symmetric(vertical: 16),
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
                ? ColorConstant.accentBlue.withOpacity(0.15)
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

class _AddExpenseBottomSheet extends StatelessWidget {
  final FinanceViewModel viewModel;
  final bool isDarkMode;

  const _AddExpenseBottomSheet({
    required this.viewModel,
    required this.isDarkMode,
  });

  List<Map<String, dynamic>> get _categories => [
    {'value': 'food', 'label': 'finance.categories.food'.tr(), 'emoji': '🍔'},
    {'value': 'transportation', 'label': 'finance.categories.transportation'.tr(), 'emoji': '🚗'},
    {'value': 'entertainment', 'label': 'finance.categories.entertainment'.tr(), 'emoji': '🎬'},
    {'value': 'shopping', 'label': 'finance.categories.shopping'.tr(), 'emoji': '🛍️'},
    {'value': 'bills', 'label': 'finance.categories.bills'.tr(), 'emoji': '📄'},
    {'value': 'health', 'label': 'finance.categories.health'.tr(), 'emoji': '💊'},
    {'value': 'education', 'label': 'finance.categories.education'.tr(), 'emoji': '📚'},
    {'value': 'other', 'label': 'finance.categories.other'.tr(), 'emoji': '💰'},
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
                        Text(
                          'finance.newExpense'.tr(),
                          style: TextStyle(
                            color: isDarkMode
                                ? ColorConstant.textPrimaryDark
                                : ColorConstant.textPrimaryLight,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
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
                        SizedBox(
                          height: 80,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _categories.length,
                            itemBuilder: (context, index) {
                              final category = _categories[index];
                              final isSelected = vm.expenseCategory == category['value'];
                              return GestureDetector(
                                onTap: () => vm.setExpenseCategory(category['value']!),
                                child: Container(
                                  width: 70,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? ColorConstant.accentGreen.withOpacity(0.15)
                                        : (isDarkMode
                                        ? ColorConstant.bgColorDark
                                        : ColorConstant.bgColorLight),
                                    border: Border.all(
                                      color: isSelected
                                          ? ColorConstant.accentGreen
                                          : (isDarkMode
                                          ? ColorConstant.borderColorDark
                                          : ColorConstant.borderColorLight),
                                      width: isSelected ? 2 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        category['emoji']!,
                                        style: const TextStyle(fontSize: 28),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        category['label']!,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected
                                              ? ColorConstant.accentGreen
                                              : (isDarkMode
                                              ? ColorConstant.textSecondaryDark
                                              : ColorConstant.textSecondaryLight),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: vm.expenseAmountController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                            color: isDarkMode
                                ? ColorConstant.textPrimaryDark
                                : ColorConstant.textPrimaryLight,
                          ),
                          decoration: InputDecoration(
                            hintText: 'finance.hints.amount'.tr(),
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
                          controller: vm.expenseDescriptionController,
                          maxLines: 2,
                          style: TextStyle(
                            color: isDarkMode
                                ? ColorConstant.textPrimaryDark
                                : ColorConstant.textPrimaryLight,
                          ),
                          decoration: InputDecoration(
                            hintText: 'finance.hints.description'.tr(),
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
                                  vm.resetExpenseForm();
                                  Navigator.pop(context);
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
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
                                onPressed: () => vm.createExpense(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: ColorConstant.accentGreen,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
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
                                  padding: const EdgeInsets.symmetric(vertical: 16),
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
                                  padding: const EdgeInsets.symmetric(vertical: 16),
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
                          color: ColorConstant.accentBlue.withOpacity(0.15),
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
                  color: ColorConstant.accentBlue.withOpacity(0.3),
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
                    color: ColorConstant.white.withOpacity(0.9),
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
                    color: ColorConstant.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'finance.totalExpense'.tr(),
                        style: TextStyle(
                          color: ColorConstant.white.withOpacity(0.9),
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
                                .withOpacity(0.15),
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
            }).toList(),
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
    {'value': 'food', 'label': 'finance.categories.food'.tr(), 'emoji': '🍔'},
    {'value': 'transportation', 'label': 'finance.categories.transportation'.tr(), 'emoji': '🚗'},
    {'value': 'entertainment', 'label': 'finance.categories.entertainment'.tr(), 'emoji': '🎬'},
    {'value': 'shopping', 'label': 'finance.categories.shopping'.tr(), 'emoji': '🛍️'},
    {'value': 'bills', 'label': 'finance.categories.bills'.tr(), 'emoji': '📄'},
    {'value': 'health', 'label': 'finance.categories.health'.tr(), 'emoji': '💊'},
    {'value': 'education', 'label': 'finance.categories.education'.tr(), 'emoji': '📚'},
    {'value': 'other', 'label': 'finance.categories.other'.tr(), 'emoji': '💰'},
  ];

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: viewModel,
      child: Consumer<FinanceViewModel>(
        builder: (context, vm, _) {
          return AlertDialog(
            backgroundColor: isDarkMode
                ? ColorConstant.cardColorDark
                : ColorConstant.white,
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
                        onTap: () => vm.toggleFilterCategory(category['value']!),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? ColorConstant.accentBlue.withOpacity(0.15)
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
                            onPressed: () => vm.updateSubscription(subscription.id, context),
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
              ? ColorConstant.accentBlue.withOpacity(0.1)
              : (isDarkMode ? ColorConstant.bgColorDark : ColorConstant.bgColorLight),
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
    {'value': 'food', 'label': 'finance.categories.food'.tr(), 'emoji': '🍔'},
    {'value': 'transportation', 'label': 'finance.categories.transportation'.tr(), 'emoji': '🚗'},
    {'value': 'entertainment', 'label': 'finance.categories.entertainment'.tr(), 'emoji': '🎬'},
    {'value': 'shopping', 'label': 'finance.categories.shopping'.tr(), 'emoji': '🛍️'},
    {'value': 'bills', 'label': 'finance.categories.bills'.tr(), 'emoji': '📄'},
    {'value': 'health', 'label': 'finance.categories.health'.tr(), 'emoji': '💊'},
    {'value': 'education', 'label': 'finance.categories.education'.tr(), 'emoji': '📚'},
    {'value': 'other', 'label': 'finance.categories.other'.tr(), 'emoji': '💰'},
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
                            final isSelected = vm.expenseCategory == category['value'];
                            return GestureDetector(
                              onTap: () => vm.setExpenseCategory(category['value']),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? ColorConstant.accentBlue.withOpacity(0.1)
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
                            onPressed: () => vm.updateExpense(expense.id, context),
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
