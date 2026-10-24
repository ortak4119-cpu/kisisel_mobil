import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:home_widget/home_widget.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/init/locator.dart';
import '../../../service/subscription/subscription_service.dart';
import '../../../service/budget/budget_service.dart';
import '../../../service/expense/expense_service.dart';
import '../../../service/income/income_service.dart';
import '../../../service/debt/debt_service.dart';
import '../../../service/installment/installment_service.dart';
import '../../../service/savings/savings_service.dart';
import '../../../service/security/security_pin_service.dart';
import '../../../service/profile/profile_service.dart';
import '../../../models/debt/debt_models.dart';
import '../../../models/installment/installment_models.dart';
import '../../../models/subscription/subscription_models.dart';
import '../../../models/budget/buget_models.dart';
import '../../../models/income/income_models.dart';
import '../../../models/auth/auth_models.dart';
import '../../../core/utils/custom_snackbar.dart';
import '../../../core/utils/premium_helper.dart';
import '../../../core/utils/currency.dart';

/// Gelir kaydı — backend'de gelir modeli yok, cihazda yerel saklanır.
class IncomeEntry {
  final int id;
  final double amount;
  final String? description;
  final String category; // salary | freelance | investment | gift | other
  final String date; // yyyy-MM-dd
  final String currency;
  IncomeEntry({
    required this.id,
    required this.amount,
    this.description,
    required this.category,
    required this.date,
    this.currency = 'TRY',
  });
  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'description': description,
        'category': category,
        'date': date,
        'currency': currency,
      };
  factory IncomeEntry.fromJson(Map<String, dynamic> j) => IncomeEntry(
        id: j['id'] as int,
        amount: (j['amount'] as num).toDouble(),
        description: j['description'] as String?,
        category: j['category'] as String? ?? 'other',
        date: j['date'] as String,
        currency: j['currency'] as String? ?? 'TRY',
      );
}

/// Harcamanın backend'de tutulmayan ek alanları (yerel).
class ExpenseMeta {
  String? time; // HH:mm
  String? account;
  String? payMethod;
  List<String> tags;
  String? note;
  String? receipt; // yerel dosya yolu
  bool reminder;
  ExpenseMeta({
    this.time,
    this.account,
    this.payMethod,
    List<String>? tags,
    this.note,
    this.receipt,
    this.reminder = false,
  }) : tags = tags ?? [];
  Map<String, dynamic> toJson() => {
        'time': time,
        'account': account,
        'payMethod': payMethod,
        'tags': tags,
        'note': note,
        'receipt': receipt,
        'reminder': reminder,
      };
  factory ExpenseMeta.fromJson(Map<String, dynamic> j) => ExpenseMeta(
        time: j['time'] as String?,
        account: j['account'] as String?,
        payMethod: j['payMethod'] as String?,
        tags: (j['tags'] as List?)?.cast<String>() ?? [],
        note: j['note'] as String?,
        receipt: j['receipt'] as String?,
        reminder: j['reminder'] as bool? ?? false,
      );
}

class FinanceViewModel extends ChangeNotifier {
  final ISubscriptionService _subscriptionService = locator.get<ISubscriptionService>();
  final IBudgetService _budgetService = locator.get<IBudgetService>();
  final IExpenseService _expenseService = locator.get<IExpenseService>();
  final IIncomeService _incomeService = locator.get<IIncomeService>();
  final IDebtService _debtService = locator.get<IDebtService>();
  final IInstallmentService _installmentService =
      locator.get<IInstallmentService>();
  final ISavingsService _savingsService = locator.get<ISavingsService>();
  final ISecurityPinService _pinService = locator.get<ISecurityPinService>();
  final IProfileService _profileService = locator.get<IProfileService>();

  // ---- Finans Kilidi ----
  // Kilit "bu oturumda açıldı" bilgisi static: ekran/viewmodel her
  // yeniden oluştuğunda korunur, uygulama soğuk başlayınca sıfırlanır.
  static bool _financeUnlockedSession = false;
  bool _financeHasPin = false;
  bool get financeHasPin => _financeHasPin;
  bool _financeLocked = false;
  bool get financeLocked => _financeLocked;
  bool _pinBusy = false;
  bool get pinBusy => _pinBusy;
  String? _pinError;
  String? get pinError => _pinError;

  Future<void> _checkFinanceLock() async {
    try {
      final st = await _pinService.getStatus(type: 'finance');
      _financeHasPin = st.hasPin;
      _financeLocked = st.hasPin && !_financeUnlockedSession;
    } catch (_) {
      _financeHasPin = false;
      _financeLocked = false;
    }
  }

  Future<bool> verifyFinancePin(String pin) async {
    _pinBusy = true;
    _pinError = null;
    notifyListeners();
    final res = await _pinService.verifyPin(pin, type: 'finance');
    _pinBusy = false;
    if (res['verified'] == true) {
      _financeUnlockedSession = true;
      _financeLocked = false;
      _pinError = null;
      notifyListeners();
      return true;
    }
    _pinError = res['locked'] == true
        ? 'finance.lock.tooManyAttempts'.tr()
        : 'finance.lock.wrongPin'.tr();
    notifyListeners();
    return false;
  }

  Future<bool> setFinancePin(String pin, {String? currentPin}) async {
    _pinBusy = true;
    notifyListeners();
    final ok = await _pinService.setPin(pin, currentPin: currentPin, type: 'finance');
    _pinBusy = false;
    if (ok) {
      _financeHasPin = true;
      _financeUnlockedSession = true;
      _financeLocked = false;
    }
    notifyListeners();
    return ok;
  }

  Future<bool> removeFinancePin(String pin) async {
    _pinBusy = true;
    notifyListeners();
    final ok = await _pinService.removePin(pin, type: 'finance');
    _pinBusy = false;
    if (ok) {
      _financeHasPin = false;
      _financeLocked = false;
    }
    notifyListeners();
    return ok;
  }

  User? _currentUser;
  User? get currentUser => _currentUser;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isInitialLoading = true;
  bool get isInitialLoading => _isInitialLoading;

  bool _isUserLoaded = false;
  bool get isUserLoaded => _isUserLoaded;

  // Subscriptions
  List<Subscription> _subscriptions = [];
  List<Subscription> get subscriptions => _subscriptions;
  List<Subscription> get activeSubscriptions =>
      _subscriptions.where((s) => s.isActive).toList();
  List<Subscription> get inactiveSubscriptions =>
      _subscriptions.where((s) => !s.isActive).toList();
  SubscriptionStats? _subscriptionStats;
  SubscriptionStats? get subscriptionStats => _subscriptionStats;

  // Budget & Expenses
  BudgetStats? _budgetStats;
  BudgetStats? get budgetStats => _budgetStats;
  List<Expense> _expenses = [];
  List<Expense> get expenses => _expenses;

  // Kategori bazlı bütçeler (category -> aylık limit)
  Map<String, double> _categoryBudgets = {};
  Map<String, double> get categoryBudgets => _categoryBudgets;
  double categoryLimit(String category) => _categoryBudgets[category] ?? 0;

  // Monthly Statistics
  Map<String, dynamic>? _monthlyStatistics;
  Map<String, dynamic>? get monthlyStatistics => _monthlyStatistics;
  bool _isLoadingStatistics = false;
  bool get isLoadingStatistics => _isLoadingStatistics;

  // Subscription Form State
  final TextEditingController subscriptionNameController = TextEditingController();
  final TextEditingController subscriptionAmountController = TextEditingController();
  final TextEditingController subscriptionBillingDateController = TextEditingController();
  String _subscriptionBillingCycle = 'monthly';
  String get subscriptionBillingCycle => _subscriptionBillingCycle;

  // Abonelik hatırlatma: backend reminder_enabled alanını okur ve
  // yaklaşan ödeme için bildirim gönderir.
  bool _subscriptionReminder = true;
  bool get subscriptionReminder => _subscriptionReminder;

  void setSubscriptionReminder(bool v) {
    _subscriptionReminder = v;
    notifyListeners();
  }

  void setSubscriptionBillingCycle(String cycle) {
    _subscriptionBillingCycle = cycle;
    notifyListeners();
  }

  int? _editingSubscriptionId;
  bool get isEditingSubscription => _editingSubscriptionId != null;
  int? get editingSubscriptionId => _editingSubscriptionId;

  void resetSubscriptionForm() {
    _editingSubscriptionId = null;
    subscriptionNameController.clear();
    subscriptionAmountController.clear();
    subscriptionBillingDateController.clear();
    _subscriptionBillingCycle = 'monthly';
    _subscriptionReminder = true;
    notifyListeners();
  }

  /// Düzenleme formunu mevcut abonelik verisiyle doldurur.
  void prefillSubscriptionForm(Subscription s) {
    subscriptionNameController.text = s.name;
    subscriptionAmountController.text =
        s.amount.toStringAsFixed(s.amount.truncateToDouble() == s.amount ? 0 : 2);
    subscriptionBillingDateController.text = s.billingDate.toString();
    _subscriptionBillingCycle = s.billingCycle;
    _subscriptionReminder = s.reminderEnabled;
    notifyListeners();
  }

  /// Aboneliği düzenleme için formu doldurur ve düzenleme kimliğini ayarlar.
  void startEditSubscription(Subscription s) {
    prefillSubscriptionForm(s);
    _editingSubscriptionId = s.id;
    notifyListeners();
  }

  // Expense Form State
  final TextEditingController expenseAmountController = TextEditingController();
  final TextEditingController expenseDescriptionController = TextEditingController();
  String _expenseCategory = 'food';
  String get expenseCategory => _expenseCategory;

  // Budget Form State
  final TextEditingController budgetAmountController = TextEditingController();

  // Filter State - Multi-select
  List<String> _filterCategories = [];
  List<String> get filterCategories => _filterCategories;

  // Legacy single filter support
  String get filterCategory => _filterCategories.isEmpty ? 'all' : _filterCategories.first;

  // Subscription List Expansion State
  bool _showAllSubscriptions = false;
  bool get showAllSubscriptions => _showAllSubscriptions;

  void toggleShowAllSubscriptions() {
    _showAllSubscriptions = !_showAllSubscriptions;
    notifyListeners();
  }

  void setExpenseCategory(String category) {
    _expenseCategory = category;
    notifyListeners();
  }

  void toggleFilterCategory(String category) {
    if (_filterCategories.contains(category)) {
      _filterCategories.remove(category);
    } else {
      _filterCategories.add(category);
    }
    notifyListeners();
  }

  void setFilterCategories(List<String> categories) {
    _filterCategories = categories;
    notifyListeners();
  }

  void clearFilters() {
    _filterCategories.clear();
    notifyListeners();
  }

  bool isFilterActive(String category) {
    return _filterCategories.contains(category);
  }

  void resetExpenseForm() {
    expenseAmountController.clear();
    expenseDescriptionController.clear();
    _expenseCategory = 'food';
    notifyListeners();
  }

  void resetBudgetForm() {
    budgetAmountController.clear();
    notifyListeners();
  }

  void resetFilter() {
    _filterCategories.clear();
    notifyListeners();
  }

  // Filtered expenses - client-side filtering
  List<Expense> get filteredExpenses {
    if (_filterCategories.isEmpty) {
      return _expenses;
    }
    return _expenses.where((expense) => _filterCategories.contains(expense.category)).toList();
  }

  Future<void> applyFilter(BuildContext context) async {
    // Client-side filtering - just notify listeners
    // Filtering is now handled by filteredExpenses getter
    notifyListeners();

    if (context.mounted) {
      CustomSnackBar.showSuccess(context, 'success.filterApplied'.tr());
    }
  }
  @override
  void dispose() {
    subscriptionNameController.dispose();
    subscriptionAmountController.dispose();
    subscriptionBillingDateController.dispose();
    expenseAmountController.dispose();
    expenseDescriptionController.dispose();
    budgetAmountController.dispose();
    super.dispose();
  }

  // ==================== SUBSCRIPTIONS ====================

  Future<void> loadSubscriptions() async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _subscriptionService.getAllSubscriptions();

      if (response.isSuccess && response.data != null) {
        _subscriptions = response.data!;
      }

      // Load stats
      final statsResponse = await _subscriptionService.getSubscriptionStats();
      if (statsResponse.isSuccess && statsResponse.data != null) {
        _subscriptionStats = statsResponse.data!;
      }
    } catch (e) {
      debugPrint('Error loading subscriptions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createSubscription(BuildContext context) async {
    // Premium limit kontrolü
    final canCreate = await PremiumHelper.checkSubscriptionLimit(
      context: context,
      user: _currentUser,
      currentSubscriptionCount: _subscriptions.length,
    );
    if (!canCreate) return;

    if (subscriptionNameController.text.trim().isEmpty) {
      CustomSnackBar.showError(context, 'errors.subscriptionNameEmpty'.tr());
      return;
    }

    if (subscriptionAmountController.text.trim().isEmpty) {
      CustomSnackBar.showError(context, 'errors.amountEmpty'.tr());
      return;
    }

    final amount = double.tryParse(subscriptionAmountController.text.trim());
    if (amount == null || amount <= 0) {
      CustomSnackBar.showError(context, 'errors.invalidAmount'.tr());
      return;
    }

    final billingDate = int.tryParse(subscriptionBillingDateController.text.trim());
    if (billingDate == null || billingDate < 1 || billingDate > 31) {
      CustomSnackBar.showError(context, 'errors.invalidPaymentDay'.tr());
      return;
    }

    try {
      _isLoading = true;
      notifyListeners();

      // Calculate next billing date
      final now = DateTime.now();
      var nextBilling = DateTime(now.year, now.month, billingDate);
      if (nextBilling.isBefore(now)) {
        nextBilling = DateTime(now.year, now.month + 1, billingDate);
      }

      final request = SubscriptionRequest(
        name: subscriptionNameController.text.trim(),
        platform: subscriptionNameController.text.trim(),
        iconUrl: null,
        amount: amount,
        currency: AppCurrency.code,
        billingCycle: _subscriptionBillingCycle,
        billingDate: billingDate,
        nextBillingDate: nextBilling.toIso8601String().split('T')[0],
        reminderEnabled: _subscriptionReminder,
        isActive: true,
        notes: null,
      );

      final response = await _subscriptionService.createSubscription(request);

      if (response.isSuccess && response.data != null) {
        _subscriptions.insert(0, response.data!);
        resetSubscriptionForm();
        await loadSubscriptions(); // Refresh stats
        if (context.mounted) {
          CustomSnackBar.showSuccess(context, 'success.subscriptionAdded'.tr());
          Navigator.pop(context);
        }
      } else {
        if (context.mounted) {
          CustomSnackBar.showError(
            context,
            'errors.unknownError'.tr(),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.showError(context, 'errors.subscriptionAddFailed'.tr());
      }
      debugPrint('Subscription creation exception: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleSubscriptionActive(int id, BuildContext context) async {
    try {
      final response = await _subscriptionService.toggleActiveStatus(id);

      if (response.isSuccess) {
        await loadSubscriptions();
        if (context.mounted) {
          CustomSnackBar.showSuccess(context, 'success.subscriptionUpdated'.tr());
        }
      } else {
        if (context.mounted) {
          CustomSnackBar.showError(
            context,
            'errors.general'.tr(),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.showError(context, 'errors.subscriptionUpdateFailed'.tr());
      }
    }
  }

  Future<void> deleteSubscription(int id, BuildContext context) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _subscriptionService.deleteSubscription(id);

      if (response.isSuccess) {
        _subscriptions.removeWhere((s) => s.id == id);
        await loadSubscriptions(); // Refresh stats
        if (context.mounted) {
          CustomSnackBar.showSuccess(context, 'success.subscriptionDeleted'.tr());
        }
      } else {
        if (context.mounted) {
          CustomSnackBar.showError(
            context,
            'errors.general'.tr(),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.showError(context, 'errors.subscriptionDeleteFailed'.tr());
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateSubscription(int id, BuildContext context) async {
    if (subscriptionNameController.text.trim().isEmpty) {
      CustomSnackBar.showError(context, 'errors.subscriptionNameEmpty'.tr());
      return;
    }

    if (subscriptionAmountController.text.trim().isEmpty) {
      CustomSnackBar.showError(context, 'errors.amountEmpty'.tr());
      return;
    }

    final amount = double.tryParse(subscriptionAmountController.text.trim());
    if (amount == null || amount <= 0) {
      CustomSnackBar.showError(context, 'errors.invalidAmount'.tr());
      return;
    }

    final billingDate = int.tryParse(subscriptionBillingDateController.text.trim());
    if (billingDate == null || billingDate < 1 || billingDate > 31) {
      CustomSnackBar.showError(context, 'errors.invalidPaymentDay'.tr());
      return;
    }

    try {
      _isLoading = true;
      notifyListeners();

      // Calculate next billing date
      final now = DateTime.now();
      var nextBilling = DateTime(now.year, now.month, billingDate);
      if (nextBilling.isBefore(now)) {
        nextBilling = DateTime(now.year, now.month + 1, billingDate);
      }

      final request = SubscriptionRequest(
        name: subscriptionNameController.text.trim(),
        platform: subscriptionNameController.text.trim(),
        iconUrl: null,
        amount: amount,
        currency: AppCurrency.code,
        billingCycle: _subscriptionBillingCycle,
        billingDate: billingDate,
        nextBillingDate: nextBilling.toIso8601String().split('T')[0],
        reminderEnabled: _subscriptionReminder,
        isActive: true,
        notes: null,
      );

      final response = await _subscriptionService.updateSubscription(id, request);

      if (response.isSuccess && response.data != null) {
        final index = _subscriptions.indexWhere((s) => s.id == id);
        if (index != -1) {
          _subscriptions[index] = response.data!;
        }
        resetSubscriptionForm();
        await loadSubscriptions(); // Refresh stats
        if (context.mounted) {
          CustomSnackBar.showSuccess(context, 'success.subscriptionUpdated'.tr());
          Navigator.pop(context);
        }
      } else {
        if (context.mounted) {
          CustomSnackBar.showError(
            context,
            'errors.unknownError'.tr(),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.showError(context, 'errors.subscriptionUpdateFailed'.tr());
      }
      debugPrint('Subscription update exception: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== BUDGET & EXPENSES ====================

  Future<void> loadBudgetStats() async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _budgetService.getBudgetStats();

      if (response.isSuccess && response.data != null) {
        _budgetStats = response.data!;
      }

      // Load recent expenses
      await loadExpenses();
      await loadCategoryBudgets();
    } catch (e) {
      debugPrint('Error loading budget stats: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCategoryBudgets() async {
    try {
      final resp = await _budgetService.getCategoryBudgets();
      if (resp.isSuccess && resp.data != null) {
        _categoryBudgets = {
          for (final c in resp.data!) c.category: c.monthlyLimit
        };
      }
    } catch (e) {
      debugPrint('loadCategoryBudgets error: $e');
    }
  }

  Future<bool> setCategoryBudget(String category, double limit) async {
    final resp = await _budgetService.setCategoryBudget(category, limit);
    if (resp.isSuccess) {
      _categoryBudgets[category] = limit;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> removeCategoryBudget(String category) async {
    final resp = await _budgetService.deleteCategoryBudget(category);
    if (resp.isSuccess) {
      _categoryBudgets.remove(category);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> updateBudget(BuildContext context) async {
    if (budgetAmountController.text.trim().isEmpty) {
      CustomSnackBar.showError(context, 'errors.budgetEmpty'.tr());
      return;
    }

    final amount = double.tryParse(budgetAmountController.text.trim());
    if (amount == null || amount <= 0) {
      CustomSnackBar.showError(context, 'errors.invalidAmount'.tr());
      return;
    }

    try {
      _isLoading = true;
      notifyListeners();

      final request = BudgetRequest(
        monthlyBudget: amount,
        currency: AppCurrency.code,
      );

      final response = await _budgetService.updateBudget(request);

      if (response.isSuccess) {
        await loadBudgetStats();
        resetBudgetForm();
        if (context.mounted) {
          CustomSnackBar.showSuccess(context, 'success.budgetUpdated'.tr());
          Navigator.pop(context);
        }
      } else {
        if (context.mounted) {
          CustomSnackBar.showError(
            context,
            'errors.unknownError'.tr(),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.showError(context, 'errors.budgetUpdateFailed'.tr());
      }
      debugPrint('Budget update exception: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadExpenses() async {
    try {
      // Görüntülenen ayın tamamını çek (grafik için birkaç gün öncesiyle).
      final monthStart = DateTime(_viewMonth.year, _viewMonth.month, 1);
      final monthEnd = DateTime(_viewMonth.year, _viewMonth.month + 1, 0);
      final start = monthStart.subtract(const Duration(days: 7));
      String fmt(DateTime d) =>
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

      final response = await _expenseService.getAllExpenses(
        startDate: fmt(start),
        endDate: fmt(monthEnd),
        perPage: 500,
      );

      if (response.isSuccess && response.data != null) {
        _expenses = response.data!.data; // PaginatedResponse.data
      }
      await loadExpenseMeta();
    } catch (e) {
      debugPrint('Error loading expenses: $e');
    }
  }

  Future<void> createExpense(BuildContext context) async {
    // Premium limit kontrolü
    final canCreate = await PremiumHelper.checkExpenseLimit(
      context: context,
      user: _currentUser,
      currentExpenseCount: _expenses.length,
    );
    if (!canCreate) return;

    if (expenseAmountController.text.trim().isEmpty) {
      CustomSnackBar.showError(context, 'errors.amountEmpty'.tr());
      return;
    }

    final amount = double.tryParse(expenseAmountController.text.trim());
    if (amount == null || amount <= 0) {
      CustomSnackBar.showError(context, 'errors.invalidAmount'.tr());
      return;
    }

    try {
      _isLoading = true;
      notifyListeners();

      final request = ExpenseRequest(
        category: _expenseCategory,
        amount: amount,
        currency: AppCurrency.code,
        description: expenseDescriptionController.text.trim().isEmpty
            ? null
            : expenseDescriptionController.text.trim(),
        expenseDate: DateTime.now().toIso8601String().split('T')[0],
        paymentMethod: null,
        receiptImageUrl: null,
        isRecurring: false,
        recurringPattern: null,
        location: null,
        merchant: null,
      );

      final response = await _expenseService.createExpense(request);

      if (response.isSuccess && response.data != null) {
        _expenses.insert(0, response.data!);
        resetExpenseForm();
        await loadBudgetStats(); // Refresh budget stats
        if (context.mounted) {
          CustomSnackBar.showSuccess(context, 'success.expenseAdded'.tr());
          Navigator.pop(context);
        }
      } else {
        if (context.mounted) {
          CustomSnackBar.showError(
            context,
            'errors.unknownError'.tr(),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.showError(context, 'errors.expenseAddFailed'.tr());
      }
      debugPrint('Expense creation exception: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteExpense(int id, BuildContext context) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _expenseService.deleteExpense(id);

      if (response.isSuccess) {
        _expenses.removeWhere((e) => e.id == id);
        await loadBudgetStats(); // Refresh budget stats
        if (context.mounted) {
          CustomSnackBar.showSuccess(context, 'success.expenseDeleted'.tr());
        }
      } else {
        if (context.mounted) {
          CustomSnackBar.showError(
            context,
            'errors.general'.tr(),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.showError(context, 'errors.expenseDeleteFailed'.tr());
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateExpense(int id, BuildContext context) async {
    if (expenseAmountController.text.trim().isEmpty) {
      CustomSnackBar.showError(context, 'errors.amountEmpty'.tr());
      return;
    }

    final amount = double.tryParse(expenseAmountController.text.trim());
    if (amount == null || amount <= 0) {
      CustomSnackBar.showError(context, 'errors.invalidAmount'.tr());
      return;
    }

    try {
      _isLoading = true;
      notifyListeners();

      final request = ExpenseRequest(
        category: _expenseCategory,
        amount: amount,
        currency: AppCurrency.code,
        description: expenseDescriptionController.text.trim().isEmpty
            ? null
            : expenseDescriptionController.text.trim(),
        expenseDate: DateTime.now().toIso8601String().split('T')[0],
        paymentMethod: null,
        receiptImageUrl: null,
        isRecurring: false,
        recurringPattern: null,
        location: null,
        merchant: null,
      );

      final response = await _expenseService.updateExpense(id, request);

      if (response.isSuccess && response.data != null) {
        final index = _expenses.indexWhere((e) => e.id == id);
        if (index != -1) {
          _expenses[index] = response.data!;
        }
        resetExpenseForm();
        await loadBudgetStats(); // Refresh budget stats
        if (context.mounted) {
          CustomSnackBar.showSuccess(context, 'success.expenseUpdated'.tr());
          Navigator.pop(context);
        }
      } else {
        if (context.mounted) {
          CustomSnackBar.showError(
            context,
            'errors.unknownError'.tr(),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.showError(context, 'errors.expenseUpdateFailed'.tr());
      }
      debugPrint('Expense update exception: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== HELPERS ====================

  // NOT: Gider ekleme formu yeni kategori kümesini kullanıyor
  // (market/bills/transport/health/other + gelir: salary/freelance/...).
  // Liste ve istatistik gösterimi de aynı kümeyi tanımalı; aksi halde
  // 'market' gibi id'ler çevrilmeden ham görünür. Eski id'ler
  // (food/transportation/...) geriye dönük uyum için korunur.
  String getCategoryLabel(String category) {
    switch (category) {
      // Yeni gider kategorileri
      case 'market':
        return 'finance.cat.market'.tr();
      case 'transport':
        return 'finance.cat.transport'.tr();
      // Gelir kategorileri
      case 'salary':
        return 'finance.inc.salary'.tr();
      case 'freelance':
        return 'finance.inc.freelance'.tr();
      case 'investment':
        return 'finance.inc.investment'.tr();
      case 'gift':
        return 'finance.inc.gift'.tr();
      // Ortak + eski kategoriler
      case 'bills':
        return 'finance.cat.bills'.tr();
      case 'health':
        return 'finance.cat.health'.tr();
      case 'other':
        return 'finance.cat.other'.tr();
      case 'food':
        return 'finance.categories.food'.tr();
      case 'transportation':
        return 'finance.categories.transportation'.tr();
      case 'entertainment':
        return 'finance.categories.entertainment'.tr();
      case 'shopping':
        return 'finance.categories.shopping'.tr();
      case 'education':
        return 'finance.categories.education'.tr();
      default:
        return category;
    }
  }

  String getCategoryEmoji(String category) {
    switch (category) {
      case 'market':
        return '🛒';
      case 'transport':
        return '🚌';
      case 'salary':
        return '💼';
      case 'freelance':
        return '💻';
      case 'investment':
        return '📈';
      case 'gift':
        return '🎁';
      case 'bills':
        return '📄';
      case 'health':
        return '❤️';
      case 'food':
        return '🍔';
      case 'transportation':
        return '🚗';
      case 'entertainment':
        return '🎬';
      case 'shopping':
        return '🛍️';
      case 'education':
        return '📚';
      case 'other':
        return '💰';
      default:
        return '💰';
    }
  }

  Color getCategoryColor(String category) {
    switch (category) {
      case 'market':
        return const Color(0xFFF6A821);
      case 'transport':
        return const Color(0xFF48BB78);
      case 'salary':
        return const Color(0xFF48BB78);
      case 'freelance':
        return const Color(0xFF4C9AFF);
      case 'investment':
        return const Color(0xFF9F7AEA);
      case 'gift':
        return const Color(0xFFED64A6);
      case 'bills':
        return const Color(0xFF4C9AFF);
      case 'health':
        return const Color(0xFFF6524B);
      case 'food':
        return const Color(0xFFFF6B6B);
      case 'transportation':
        return const Color(0xFF4ECDC4);
      case 'entertainment':
        return const Color(0xFFB794F6);
      case 'shopping':
        return const Color(0xFFFFA07A);
      case 'education':
        return const Color(0xFF667EEA);
      case 'other':
        return const Color(0xFF9AA0A6);
      default:
        return const Color(0xFF7EC8F5);
    }
  }

  // ==================== MONTHLY STATISTICS ====================

  Future<void> loadMonthlyStatistics({int? year}) async {
    final requestYear = year ?? DateTime.now().year;
    debugPrint('📊 [Finance] Loading monthly statistics for year: $requestYear');

    try {
      _isLoadingStatistics = true;
      notifyListeners();

      debugPrint('📡 [Finance] Sending request to backend...');
      final response = await _expenseService.getMonthlyStatistics(
        year: requestYear,
      );

      debugPrint('📥 [Finance] Response received - Success: ${response.isSuccess}');

      if (response.isSuccess && response.data != null) {
        _monthlyStatistics = response.data!;
        debugPrint('✅ [Finance] Monthly statistics loaded successfully');
        debugPrint('📈 [Finance] Data: ${response.data}');

        // Monthly statistics array'ini de logla
        if (response.data!['monthly_statistics'] != null) {
          final monthlyStats = response.data!['monthly_statistics'] as List;
          debugPrint('📊 [Finance] Total months: ${monthlyStats.length}');
          debugPrint('💰 [Finance] Year total: ${response.data!['total_year_spending']}');
        }
      } else {
        debugPrint('❌ [Finance] Failed to load statistics');
        debugPrint('❌ [Finance] Error message: ${response.message}');
        debugPrint('❌ [Finance] Status code: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [Finance] Exception loading monthly statistics: $e');
      debugPrint('❌ [Finance] Stack trace: $stackTrace');
    } finally {
      _isLoadingStatistics = false;
      notifyListeners();
      debugPrint('🏁 [Finance] Loading completed');
    }
  }

  // ==================== BORÇ PLANLAYICI ====================
  List<Debt> _debts = [];
  List<Debt> get debts => _debts;
  double get totalDebt => _debts.fold(0.0, (s, d) => s + d.balance);
  double get totalMinPayment => _debts.fold(0.0, (s, d) => s + d.minPayment);

  Future<void> loadDebts() async {
    try {
      _debts = await _debtService.getDebts();
      notifyListeners();
    } catch (e) {
      debugPrint('loadDebts error: $e');
    }
  }

  Future<bool> addDebt(
      String name, double balance, double rate, double minPayment) async {
    final d = await _debtService.createDebt(DebtRequest(
      name: name,
      balance: balance,
      interestRate: rate,
      minPayment: minPayment,
    ));
    if (d != null) {
      _debts.insert(0, d);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> deleteDebt(int id) async {
    if (await _debtService.deleteDebt(id)) {
      _debts.removeWhere((d) => d.id == id);
      notifyListeners();
    }
  }

  /// Borç ödeme planını hesaplar.
  /// strategy: 'avalanche' (yüksek faiz önce) | 'snowball' (düşük bakiye önce)
  DebtPlan computeDebtPlan({required double extra, required String strategy}) {
    if (_debts.isEmpty) {
      return DebtPlan(months: 0, totalInterest: 0, unpayable: false, order: []);
    }
    final work = _debts
        .map((d) => <String, dynamic>{
              'name': d.name,
              'bal': d.balance,
              'rate': d.interestRate / 100 / 12,
              'min': d.minPayment,
            })
        .toList();
    final totalBudget =
        work.fold<double>(0, (s, d) => s + (d['min'] as double)) + extra;
    double totalInterest = 0;
    int months = 0;
    final order = <String>[];
    final paid = <int>{};

    while (work.any((d) => (d['bal'] as double) > 0.005) && months < 600) {
      months++;
      // Faiz tahakkuku
      for (final d in work) {
        final bal = d['bal'] as double;
        if (bal > 0) {
          final interest = bal * (d['rate'] as double);
          d['bal'] = bal + interest;
          totalInterest += interest;
        }
      }
      double pool = totalBudget;
      // Önce tüm asgari ödemeler
      for (final d in work) {
        final bal = d['bal'] as double;
        if (bal <= 0) continue;
        final p = (d['min'] as double).clamp(0.0, bal).toDouble();
        d['bal'] = bal - p;
        pool -= p;
      }
      if (pool < 0) pool = 0;
      // Kalan havuz stratejiye göre öncelikli borçlara
      final unpaid = [
        for (int i = 0; i < work.length; i++)
          if ((work[i]['bal'] as double) > 0) i
      ];
      unpaid.sort((a, b) {
        if (strategy == 'snowball') {
          return (work[a]['bal'] as double).compareTo(work[b]['bal'] as double);
        }
        return (work[b]['rate'] as double).compareTo(work[a]['rate'] as double);
      });
      for (final i in unpaid) {
        if (pool <= 0) break;
        final bal = work[i]['bal'] as double;
        final p = pool.clamp(0.0, bal).toDouble();
        work[i]['bal'] = bal - p;
        pool -= p;
      }
      // Yeni biten borçlar
      for (int i = 0; i < work.length; i++) {
        if (!paid.contains(i) && (work[i]['bal'] as double) <= 0.005) {
          paid.add(i);
          order.add(work[i]['name'] as String);
        }
      }
    }
    final unpayable = work.any((d) => (d['bal'] as double) > 0.005);
    return DebtPlan(
      months: months,
      totalInterest: totalInterest,
      unpayable: unpayable,
      order: order,
    );
  }

  // ==================== TAKSİTLER ====================
  List<Installment> _installments = [];
  List<Installment> get installments => _installments;

  /// Bu ay ödenecek aktif taksitlerin aylık toplamı.
  double get monthlyInstallmentTotal => _installments
      .where((i) => !i.isDone)
      .fold(0.0, (s, i) => s + i.monthlyAmount);

  Future<void> loadInstallments() async {
    try {
      _installments = await _installmentService.getInstallments();
      notifyListeners();
    } catch (e) {
      debugPrint('loadInstallments error: $e');
    }
  }

  Future<bool> addInstallment(
      String name, double total, int count, int paid, String startDate) async {
    final item = await _installmentService.createInstallment(InstallmentRequest(
      name: name,
      totalAmount: total,
      installmentCount: count,
      paidCount: paid,
      startDate: startDate,
    ));
    if (item != null) {
      _installments.insert(0, item);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> markInstallmentPaid(int id) async {
    final idx = _installments.indexWhere((i) => i.id == id);
    if (idx == -1) return;
    final cur = _installments[idx];
    if (cur.isDone) return;
    final newPaid = cur.paidCount + 1;
    final ok = await _installmentService.updatePaidCount(id, newPaid);
    if (ok) {
      _installments[idx] = Installment(
        id: cur.id,
        name: cur.name,
        totalAmount: cur.totalAmount,
        installmentCount: cur.installmentCount,
        paidCount: newPaid,
        startDate: cur.startDate,
        currency: cur.currency,
      );
      notifyListeners();
    }
  }

  Future<void> deleteInstallment(int id) async {
    if (await _installmentService.deleteInstallment(id)) {
      _installments.removeWhere((i) => i.id == id);
      notifyListeners();
    }
  }

  // ==================== DIŞA AKTARMA (CSV) ====================

  /// Tüm harcamaları (+ yerel gelirleri) CSV olarak paylaşır.
  Future<void> exportCsv(BuildContext context) async {
    try {
      _isLoading = true;
      notifyListeners();

      String esc(String? s) {
        final v = s ?? '';
        if (v.contains(',') || v.contains('"') || v.contains('\n')) {
          return '"${v.replaceAll('"', '""')}"';
        }
        return v;
      }

      String two(int n) => n.toString().padLeft(2, '0');

      final rows = <String>[];
      // Başlık (lokalize)
      rows.add([
        'finance.export.date'.tr(),
        'finance.export.type'.tr(),
        'finance.export.category'.tr(),
        'finance.export.amount'.tr(),
        'finance.export.currency'.tr(),
        'finance.export.description'.tr(),
      ].map(esc).join(','));

      // Harcamalar — tüm kayıtları çek
      final resp = await _expenseService.getAllExpenses(perPage: 1000);
      final exps = (resp.isSuccess && resp.data != null)
          ? resp.data!.data
          : _expenses;
      for (final e in exps) {
        final d =
            '${e.expenseDate.year}-${two(e.expenseDate.month)}-${two(e.expenseDate.day)}';
        rows.add([
          d,
          'finance.expense'.tr(),
          getCategoryLabel(e.category),
          e.amount.toStringAsFixed(2),
          e.currency,
          e.description ?? '',
        ].map(esc).join(','));
      }

      // Gelirler (yerel)
      for (final i in _income) {
        rows.add([
          i.date,
          'finance.income'.tr(),
          getCategoryLabel(i.category),
          i.amount.toStringAsFixed(2),
          AppCurrency.code,
          i.description ?? '',
        ].map(esc).join(','));
      }

      // Excel'in Türkçe/UTF-8 karakterleri doğru açması için BOM ekle
      final csv = '﻿${rows.join('\r\n')}';
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/lifesync_finance_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(csv, encoding: utf8);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/csv')],
        subject: 'LifeSync Finance Export',
      );
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.showError(context, 'errors.general'.tr());
      }
      debugPrint('CSV export error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== COMMON ====================

  Future<void> loadCurrentUser() async {
    try {
      final response = await _profileService.getProfile();
      if (response.isSuccess && response.data != null) {
        _currentUser = response.data;
      }
    } catch (e) {
      debugPrint('Error loading current user: $e');
    } finally {
      _isUserLoaded = true;
      notifyListeners();
    }
  }

  Future<void> refreshAll() async {
    await loadCurrentUser();
    await _checkFinanceLock();
    // Kilitliyken diğer verileri çekmeye gerek yok.
    if (!_financeLocked) {
      await Future.wait([
        loadSubscriptions(),
        loadBudgetStats(),
        loadIncome(),
        loadSavingsGoal(),
        loadDebts(),
        loadInstallments(),
      ]);
      await _updateHomeWidget();
    }
    _isInitialLoading = false;
    notifyListeners();
  }

  /// Para birimi gibi global ayar değişiminde UI'yı yeniler.
  void refreshFormatting() => notifyListeners();

  /// Ana ekran widget'ına güncel finans özetini yazar.
  Future<void> _updateHomeWidget() async {
    try {
      await HomeWidget.saveWidgetData<String>(
          'balance', AppCurrency.format(availableBalance, decimals: 2));
      await HomeWidget.saveWidgetData<String>(
          'spent', AppCurrency.format(monthExpensesTotal, decimals: 0));
      await HomeWidget.saveWidgetData<String>(
          'income', AppCurrency.format(monthIncomeTotal, decimals: 0));
      await HomeWidget.saveWidgetData<String>(
          'balance_label', 'finance.availableBalance'.tr());
      await HomeWidget.updateWidget(
        androidName: 'FinanceWidgetProvider',
        iOSName: 'FinanceWidget',
      );
    } catch (e) {
      debugPrint('Home widget update error: $e');
    }
  }

  /// Kilit açıldıktan sonra veriyi yükler.
  Future<void> loadAfterUnlock() async {
    await Future.wait([
      loadSubscriptions(),
      loadBudgetStats(),
      loadIncome(),
      loadSavingsGoal(),
      loadDebts(),
      loadInstallments(),
    ]);
    notifyListeners();
  }

  // ==================== YENİ TASARIM: GELİR + TASARRUF + FORM ====================

  // ---- Gelir (backend: /api/incomes) ----
  // Eskiden gelir yalnız cihazda (SharedPreferences) tutuluyordu; artık
  // backend'de. İlk yüklemede eski yerel kayıtlar bir kez sunucuya taşınır.
  static const String _kIncomeKey = 'finance_income_v1';
  static const String _kIncomeMigratedKey = 'finance_income_migrated_v1';
  List<IncomeEntry> _income = [];
  List<IncomeEntry> get income => _income;

  Future<void> loadIncome() async {
    try {
      await _migrateLocalIncomeIfNeeded();
      final now = DateTime.now();
      final start = DateTime(now.year - 1, now.month, 1);
      String fmt(DateTime d) =>
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      final resp = await _incomeService.getAllIncomes(
        startDate: fmt(start),
        endDate: fmt(now),
        perPage: 500,
      );
      if (resp.isSuccess && resp.data != null) {
        _income = resp.data!.data
            .map((e) => IncomeEntry(
                  id: e.id,
                  amount: e.amount,
                  description: e.description,
                  category: e.category,
                  date: e.incomeDate,
                  currency: e.currency,
                ))
            .toList();
      }
    } catch (e) {
      debugPrint('Error loading income: $e');
    }
  }

  /// Eski yerel gelir kayıtlarını bir kez backend'e taşır, sonra siler.
  Future<void> _migrateLocalIncomeIfNeeded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_kIncomeMigratedKey) == true) return;
      final raw = prefs.getString(_kIncomeKey);
      if (raw != null && raw.isNotEmpty) {
        final list = jsonDecode(raw) as List;
        for (final e in list) {
          final m = e as Map<String, dynamic>;
          await _incomeService.createIncome(IncomeRequest(
            amount: (m['amount'] as num).toDouble(),
            currency: AppCurrency.code,
            category: m['category'] as String? ?? 'other',
            description: m['description'] as String?,
            incomeDate: m['date'] as String,
          ));
        }
      }
      await prefs.setBool(_kIncomeMigratedKey, true);
      await prefs.remove(_kIncomeKey);
    } catch (e) {
      debugPrint('Income migration error: $e');
    }
  }

  // ---- Görüntülenen ay (ay değiştirici) ----
  DateTime _viewMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime get viewMonth => _viewMonth;
  bool get isCurrentMonth {
    final n = DateTime.now();
    return _viewMonth.year == n.year && _viewMonth.month == n.month;
  }

  bool get isFutureMonth {
    final n = DateTime(DateTime.now().year, DateTime.now().month);
    return _viewMonth.isAfter(n);
  }

  /// Görüntülenen ayı değiştirir ve o ayın verilerini yükler.
  Future<void> changeMonth(int delta) async {
    _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + delta);
    notifyListeners();
    await Future.wait([loadExpenses(), loadIncome()]);
    notifyListeners();
  }

  Future<void> goToCurrentMonth() async {
    final n = DateTime.now();
    if (isCurrentMonth) return;
    _viewMonth = DateTime(n.year, n.month);
    notifyListeners();
    await Future.wait([loadExpenses(), loadIncome()]);
    notifyListeners();
  }

  bool _sameMonth(DateTime d) {
    return d.year == _viewMonth.year && d.month == _viewMonth.month;
  }

  double get monthIncomeTotal {
    double t = 0;
    for (final i in _income) {
      try {
        if (_sameMonth(DateTime.parse(i.date))) {
          t += i.amount;
        }
      } catch (_) {}
    }
    return t;
  }

  Future<bool> addIncome(double amount, String? desc, String category,
      String date, int idSeed) async {
    final resp = await _incomeService.createIncome(IncomeRequest(
      amount: amount,
      currency: AppCurrency.code,
      category: category,
      description: desc,
      incomeDate: date,
    ));
    if (resp.isSuccess && resp.data != null) {
      final e = resp.data!;
      _income.insert(
          0,
          IncomeEntry(
              id: e.id,
              amount: e.amount,
              description: e.description,
              category: e.category,
              date: e.incomeDate,
              currency: e.currency));
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> deleteIncome(int id) async {
    final resp = await _incomeService.deleteIncome(id);
    if (resp.isSuccess) {
      _income.removeWhere((e) => e.id == id);
      notifyListeners();
    }
  }

  // ---- Tasarruf hedefi (yerel) ----
  static const String _kSavingsKey = 'finance_savings_v1';
  double _savingsTarget = 25000;
  double _savingsCurrent = 0;
  String _savingsTitle = '';
  double get savingsTarget => _savingsTarget;
  double get savingsCurrent => _savingsCurrent;
  String get savingsTitle => _savingsTitle;
  double get savingsPercent =>
      _savingsTarget <= 0 ? 0 : (_savingsCurrent / _savingsTarget * 100);

  static const String _kSavingsMigratedKey = 'finance_savings_migrated_v1';

  Future<void> loadSavingsGoal() async {
    try {
      await _migrateLocalSavingsIfNeeded();
      final data = await _savingsService.getSavings();
      if (data != null) {
        _savingsTitle = data.title;
        _savingsTarget = data.target > 0 ? data.target : _savingsTarget;
        _savingsCurrent = data.current;
      }
    } catch (e) {
      debugPrint('loadSavingsGoal error: $e');
    }
  }

  /// Eski yerel tasarruf hedefini bir kez backend'e taşır.
  Future<void> _migrateLocalSavingsIfNeeded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_kSavingsMigratedKey) == true) return;
      final raw = prefs.getString(_kSavingsKey);
      if (raw != null) {
        final j = jsonDecode(raw) as Map<String, dynamic>;
        await _savingsService.updateSavings(
          title: j['title'] as String? ?? '',
          target: (j['target'] as num?)?.toDouble() ?? 0,
          current: (j['current'] as num?)?.toDouble() ?? 0,
        );
      }
      await prefs.setBool(_kSavingsMigratedKey, true);
      await prefs.remove(_kSavingsKey);
    } catch (e) {
      debugPrint('Savings migration error: $e');
    }
  }

  Future<void> setSavingsGoal(String title, double target) async {
    _savingsTitle = title;
    _savingsTarget = target;
    notifyListeners();
    await _savingsService.updateSavings(title: title, target: target);
  }

  Future<void> addToSavings(double amount) async {
    _savingsCurrent += amount;
    notifyListeners();
    await _savingsService.updateSavings(current: _savingsCurrent);
  }

  // ---- Aylık toplamlar / grafik verileri ----
  double get monthExpensesTotal {
    double t = 0;
    for (final e in _expenses) {
      if (_sameMonth(e.expenseDate)) {
        t += e.amount;
      }
    }
    return t;
  }

  double get monthSavingsRate {
    final inc = monthIncomeTotal;
    if (inc <= 0) return 0;
    return ((inc - monthExpensesTotal) / inc * 100).clamp(0, 100);
  }

  double get availableBalance => monthIncomeTotal - monthExpensesTotal;

  /// Görüntülenen ayın kalan gün sayısı (bugün dahil).
  int get daysRemainingInMonth {
    final lastDay = DateTime(_viewMonth.year, _viewMonth.month + 1, 0).day;
    if (isCurrentMonth) return (lastDay - DateTime.now().day) + 1;
    if (isFutureMonth) return lastDay;
    return 0; // geçmiş ay
  }

  /// "Günlük harcanabilir": kalan bakiyeyi ayın kalan günlerine böler.
  /// Aylık bütçe tanımlıysa bütçeden kalan, değilse gelir-gider bakiyesi
  /// esas alınır. Negatifse 0 döner.
  double get safeToSpendPerDay {
    final days = daysRemainingInMonth;
    if (days <= 0) return 0;
    final budget = _budgetStats?.monthlyBudget ?? 0;
    final base = budget > 0
        ? (budget - monthExpensesTotal)
        : availableBalance;
    final perDay = base / days;
    return perDay < 0 ? 0 : perDay;
  }

  /// Kategoriye göre bu ayın harcama toplamları (halka grafik).
  Map<String, double> get categoryTotals {
    final m = <String, double>{};
    for (final e in _expenses) {
      if (!_sameMonth(e.expenseDate)) continue;
      m[e.category] = (m[e.category] ?? 0) + e.amount;
    }
    return m;
  }

  /// Görüntülenen ayda son 7 günün günlük harcama toplamları (çubuk grafik).
  List<MapEntry<DateTime, double>> get dailyExpenseSeries {
    final lastDay = DateTime(_viewMonth.year, _viewMonth.month + 1, 0).day;
    final anchorDay = isCurrentMonth ? DateTime.now().day : lastDay;
    final out = <MapEntry<DateTime, double>>[];
    for (int i = 6; i >= 0; i--) {
      final day = DateTime(_viewMonth.year, _viewMonth.month, anchorDay - i);
      double t = 0;
      for (final e in _expenses) {
        if (e.expenseDate.year == day.year &&
            e.expenseDate.month == day.month &&
            e.expenseDate.day == day.day) {
          t += e.amount;
        }
      }
      out.add(MapEntry(day, t));
    }
    return out;
  }

  double get dailyAverage {
    final lastDay = DateTime(_viewMonth.year, _viewMonth.month + 1, 0).day;
    final days = isCurrentMonth ? DateTime.now().day : lastDay;
    return days == 0 ? 0 : monthExpensesTotal / days;
  }

  // ---- Harcama meta (yerel) ----
  static const String _kExpMetaKey = 'expense_meta_v1';
  final Map<int, ExpenseMeta> _expMeta = {};
  ExpenseMeta metaForExpense(int id) => _expMeta[id] ?? ExpenseMeta();

  Future<void> loadExpenseMeta() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kExpMetaKey);
      _expMeta.clear();
      if (raw == null || raw.isEmpty) return;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      map.forEach((k, v) {
        final id = int.tryParse(k);
        if (id != null && v is Map<String, dynamic>) {
          _expMeta[id] = ExpenseMeta.fromJson(v);
        }
      });
    } catch (_) {}
  }

  Future<void> _persistExpMeta() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kExpMetaKey,
          jsonEncode(_expMeta.map((k, v) => MapEntry(k.toString(), v.toJson()))));
    } catch (_) {}
  }

  // ==================== YENİ GİDER/GELİR FORMU ====================
  bool _isIncomeForm = false;
  bool get isIncomeForm => _isIncomeForm;
  void setIsIncomeForm(bool v) {
    _isIncomeForm = v;
    notifyListeners();
  }

  String _formExpCategory = 'market';
  String get formExpCategory => _formExpCategory;
  void setFormExpCategory(String c) {
    _formExpCategory = c;
    notifyListeners();
  }

  DateTime _formExpDate = DateTime.now();
  DateTime get formExpDate => _formExpDate;
  TimeOfDay _formExpTime = TimeOfDay.now();
  TimeOfDay get formExpTime => _formExpTime;
  void setFormExpDate(DateTime d) {
    _formExpDate = d;
    notifyListeners();
  }

  void setFormExpTime(TimeOfDay t) {
    _formExpTime = t;
    notifyListeners();
  }

  String _formPayMethod = 'card';
  String get formPayMethod => _formPayMethod;
  void setFormPayMethod(String v) {
    _formPayMethod = v;
    notifyListeners();
  }

  String _formAccount = 'daily';
  String get formAccount => _formAccount;
  void setFormAccount(String v) {
    _formAccount = v;
    notifyListeners();
  }

  bool _formRecurring = false;
  bool get formRecurring => _formRecurring;
  void setFormRecurring(bool v) {
    _formRecurring = v;
    notifyListeners();
  }

  String _formRecurPattern = 'monthly';
  String get formRecurPattern => _formRecurPattern;
  void setFormRecurPattern(String v) {
    _formRecurPattern = v;
    notifyListeners();
  }

  final List<String> _formTags = [];
  List<String> get formTags => _formTags;
  void addFormTag(String t) {
    final v = t.trim();
    if (v.isNotEmpty && !_formTags.contains(v)) {
      _formTags.add(v);
      notifyListeners();
    }
  }

  void removeFormTag(int i) {
    if (i >= 0 && i < _formTags.length) {
      _formTags.removeAt(i);
      notifyListeners();
    }
  }

  String? _formNote;
  String? get formNote => _formNote;
  void setFormNote(String? v) {
    _formNote = (v == null || v.trim().isEmpty) ? null : v.trim();
    notifyListeners();
  }

  String? _formLocation;
  String? get formLocation => _formLocation;
  void setFormLocation(String? v) {
    _formLocation = (v == null || v.trim().isEmpty) ? null : v.trim();
    notifyListeners();
  }

  bool _formReminder = false;
  bool get formReminder => _formReminder;
  void setFormReminder(bool v) {
    _formReminder = v;
    notifyListeners();
  }

  File? _formReceipt;
  File? get formReceipt => _formReceipt;
  final ImagePicker _picker = ImagePicker();
  Future<void> pickReceiptImage(ImageSource src) async {
    try {
      final f = await _picker.pickImage(source: src, imageQuality: 80);
      if (f != null) {
        _formReceipt = File(f.path);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> pickReceiptFile() async {
    try {
      final r = await FilePicker.platform.pickFiles();
      if (r != null && r.files.single.path != null) {
        _formReceipt = File(r.files.single.path!);
        notifyListeners();
      }
    } catch (_) {}
  }

  // ---- Fiş OCR (ML Kit) ----
  bool _ocrBusy = false;
  bool get ocrBusy => _ocrBusy;

  /// Fiş fotoğrafını tarar, toplam tutarı bulup tutar alanına yazar.
  Future<void> scanReceipt(BuildContext context, ImageSource source) async {
    try {
      final f = await _picker.pickImage(source: source, imageQuality: 90);
      if (f == null) return;
      _formReceipt = File(f.path);
      _ocrBusy = true;
      notifyListeners();

      final recognizer =
          TextRecognizer(script: TextRecognitionScript.latin);
      final result =
          await recognizer.processImage(InputImage.fromFilePath(f.path));
      await recognizer.close();

      final amount = _extractReceiptAmount(result.text);
      _ocrBusy = false;
      if (amount != null) {
        expenseAmountController.text =
            amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2);
        notifyListeners();
        if (context.mounted) {
          CustomSnackBar.showSuccess(
              context,
              '${'finance.ocr.found'.tr()}: '
              '${AppCurrency.format(amount, decimals: 2)}');
        }
      } else {
        notifyListeners();
        if (context.mounted) {
          CustomSnackBar.showInfo(context, 'finance.ocr.notFound'.tr());
        }
      }
    } catch (e) {
      _ocrBusy = false;
      notifyListeners();
      if (context.mounted) {
        CustomSnackBar.showError(context, 'finance.ocr.failed'.tr());
      }
      debugPrint('OCR error: $e');
    }
  }

  /// Fiş metninden tutarı çıkarır: önce TOPLAM/TOTAL satırları, yoksa en
  /// büyük para benzeri sayı.
  double? _extractReceiptAmount(String text) {
    final numRe = RegExp(r'\d{1,3}(?:[.,]\d{3})*[.,]\d{2}|\d+[.,]\d{2}');
    List<double> numsIn(String s) {
      final out = <double>[];
      for (final m in numRe.allMatches(s)) {
        final v = _parseMoney(m.group(0)!);
        if (v != null && v > 0 && v < 1000000) out.add(v);
      }
      return out;
    }

    // Toplam içeren satırları öncele
    double? best;
    for (final line in text.split('\n')) {
      final up = line.toUpperCase();
      if (up.contains('TOPLAM') ||
          up.contains('TOTAL') ||
          up.contains('TUTAR') ||
          up.contains('GENEL')) {
        for (final v in numsIn(line)) {
          if (best == null || v > best) best = v;
        }
      }
    }
    if (best != null) return best;

    final all = numsIn(text);
    if (all.isEmpty) return null;
    return all.reduce((a, b) => a > b ? a : b);
  }

  double? _parseMoney(String raw) {
    raw = raw.trim();
    final lastComma = raw.lastIndexOf(',');
    final lastDot = raw.lastIndexOf('.');
    String norm;
    if (lastComma > lastDot) {
      norm = raw.replaceAll('.', '').replaceAll(',', '.');
    } else if (lastDot > lastComma) {
      norm = raw.replaceAll(',', '');
    } else {
      norm = raw.replaceAll(',', '').replaceAll('.', '');
    }
    return double.tryParse(norm);
  }

  void removeReceipt() {
    _formReceipt = null;
    notifyListeners();
  }

  // ---- Düzenleme modu ----
  int? _editTxnId;
  bool get isEditingTxn => _editTxnId != null;

  void resetFinanceForm({bool income = false}) {
    _editTxnId = null;
    expenseAmountController.clear();
    expenseDescriptionController.clear();
    _isIncomeForm = income;
    _formExpCategory = income ? 'salary' : 'market';
    _formExpDate = DateTime.now();
    _formExpTime = TimeOfDay.now();
    _formPayMethod = 'card';
    _formAccount = 'daily';
    _formRecurring = false;
    _formRecurPattern = 'monthly';
    _formTags.clear();
    _formNote = null;
    _formLocation = null;
    _formReminder = false;
    _formReceipt = null;
    notifyListeners();
  }

  /// Finans formunu düzenleme için mevcut işlem verisiyle doldurur.
  void startEditFinance({
    required int id,
    required bool income,
    required double amount,
    required String category,
    String? description,
    required DateTime date,
  }) {
    _editTxnId = id;
    _isIncomeForm = income;
    _formExpCategory = category;
    _formExpDate = date;
    _formExpTime = TimeOfDay.now();
    _formPayMethod = 'card';
    _formAccount = 'daily';
    _formRecurring = false;
    _formRecurPattern = 'monthly';
    _formTags.clear();
    _formNote = null;
    _formLocation = null;
    _formReminder = false;
    _formReceipt = null;
    expenseAmountController.text =
        amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2);
    expenseDescriptionController.text = description ?? '';
    notifyListeners();
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<String?> _copyReceipt(File f) async {
    try {
      final docs = await getApplicationDocumentsDirectory();
      final dir = Directory('${docs.path}/receipts');
      if (!dir.existsSync()) dir.createSync(recursive: true);
      final ext = f.path.contains('.') ? f.path.split('.').last : 'jpg';
      final stamp = DateTime.now().microsecondsSinceEpoch;
      final dest = '${dir.path}/rcpt_$stamp.$ext';
      await f.copy(dest);
      return dest;
    } catch (_) {
      return null;
    }
  }

  /// Yeni gider/gelir formunu kaydeder.
  Future<void> saveFinanceForm(BuildContext context) async {
    final amount = double.tryParse(
        expenseAmountController.text.trim().replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      CustomSnackBar.showError(context, 'errors.invalidAmount'.tr());
      return;
    }
    final desc = expenseDescriptionController.text.trim();

    final editing = _editTxnId != null;

    if (_isIncomeForm) {
      _isLoading = true;
      notifyListeners();
      bool ok;
      final req = IncomeRequest(
        amount: amount,
        currency: AppCurrency.code,
        category: _formExpCategory,
        description: desc.isEmpty ? null : desc,
        incomeDate: _fmtDate(_formExpDate),
      );
      if (editing) {
        final resp = await _incomeService.updateIncome(_editTxnId!, req);
        ok = resp.isSuccess && resp.data != null;
        if (ok) {
          final e = resp.data!;
          final idx = _income.indexWhere((i) => i.id == _editTxnId);
          final entry = IncomeEntry(
              id: e.id,
              amount: e.amount,
              description: e.description,
              category: e.category,
              date: e.incomeDate,
              currency: e.currency);
          if (idx != -1) {
            _income[idx] = entry;
          }
        }
      } else {
        final id = DateTime.now().microsecondsSinceEpoch ~/ 1000;
        ok = await addIncome(amount, desc.isEmpty ? null : desc,
            _formExpCategory, _fmtDate(_formExpDate), id);
      }
      _isLoading = false;
      notifyListeners();
      if (context.mounted) {
        if (ok) {
          CustomSnackBar.showSuccess(
              context,
              editing
                  ? 'success.incomeUpdated'.tr()
                  : 'success.incomeAdded'.tr());
          Navigator.pop(context);
        } else {
          CustomSnackBar.showError(context, 'errors.general'.tr());
        }
      }
      return;
    }

    try {
      _isLoading = true;
      notifyListeners();
      final request = ExpenseRequest(
        category: _formExpCategory,
        amount: amount,
        currency: AppCurrency.code,
        description: desc.isEmpty ? null : desc,
        expenseDate: _fmtDate(_formExpDate),
        paymentMethod: null,
        receiptImageUrl: null,
        isRecurring: _formRecurring,
        recurringPattern: _formRecurring ? _formRecurPattern : null,
        location: _formLocation,
        merchant: null,
      );

      // Düzenleme modu: mevcut gideri güncelle
      if (editing) {
        final resp = await _expenseService.updateExpense(_editTxnId!, request);
        _isLoading = false;
        if (resp.isSuccess && resp.data != null) {
          final idx = _expenses.indexWhere((e) => e.id == _editTxnId);
          if (idx != -1) {
            _expenses[idx] = resp.data!;
          }
          await loadBudgetStats();
          if (context.mounted) {
            CustomSnackBar.showSuccess(context, 'success.expenseUpdated'.tr());
            Navigator.pop(context);
          }
        } else if (context.mounted) {
          CustomSnackBar.showError(
              context, 'errors.unknownError'.tr());
        }
        notifyListeners();
        return;
      }

      final response = await _expenseService.createExpense(request);
      if (response.isSuccess && response.data != null) {
        final exp = response.data!;
        _expenses.insert(0, exp);
        final meta = ExpenseMeta(
          time:
              '${_formExpTime.hour.toString().padLeft(2, '0')}:${_formExpTime.minute.toString().padLeft(2, '0')}',
          account: _formAccount,
          payMethod: _formPayMethod,
          tags: List.from(_formTags),
          note: _formNote,
          reminder: _formReminder,
        );
        if (_formReceipt != null) {
          meta.receipt = await _copyReceipt(_formReceipt!);
        }
        _expMeta[exp.id] = meta;
        await _persistExpMeta();
        await loadBudgetStats();
        if (context.mounted) {
          CustomSnackBar.showSuccess(context, 'success.expenseAdded'.tr());
          Navigator.pop(context);
        }
      } else if (context.mounted) {
        CustomSnackBar.showError(
            context, 'errors.unknownError'.tr());
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.showError(context, 'errors.expenseAddFailed'.tr());
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}