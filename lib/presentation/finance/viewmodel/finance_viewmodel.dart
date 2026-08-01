import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/init/locator.dart';
import '../../../service/subscription/subscription_service.dart';
import '../../../service/budget/budget_service.dart';
import '../../../service/expense/expense_service.dart';
import '../../../service/profile/profile_service.dart';
import '../../../models/subscription/subscription_models.dart';
import '../../../models/budget/buget_models.dart';
import '../../../models/auth/auth_models.dart';
import '../../../core/utils/custom_snackbar.dart';
import '../../../core/utils/premium_helper.dart';

/// Gelir kaydı — backend'de gelir modeli yok, cihazda yerel saklanır.
class IncomeEntry {
  final int id;
  final double amount;
  final String? description;
  final String category; // salary | freelance | investment | gift | other
  final String date; // yyyy-MM-dd
  IncomeEntry({
    required this.id,
    required this.amount,
    this.description,
    required this.category,
    required this.date,
  });
  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'description': description,
        'category': category,
        'date': date,
      };
  factory IncomeEntry.fromJson(Map<String, dynamic> j) => IncomeEntry(
        id: j['id'] as int,
        amount: (j['amount'] as num).toDouble(),
        description: j['description'] as String?,
        category: j['category'] as String? ?? 'other',
        date: j['date'] as String,
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
  final IProfileService _profileService = locator.get<IProfileService>();

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

  void setSubscriptionBillingCycle(String cycle) {
    _subscriptionBillingCycle = cycle;
    notifyListeners();
  }

  void resetSubscriptionForm() {
    subscriptionNameController.clear();
    subscriptionAmountController.clear();
    subscriptionBillingDateController.clear();
    _subscriptionBillingCycle = 'monthly';
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
        currency: 'TRY',
        billingCycle: _subscriptionBillingCycle,
        billingDate: billingDate,
        nextBillingDate: nextBilling.toIso8601String().split('T')[0],
        reminderEnabled: false,
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
            response.errorMessage ?? 'errors.unknownError'.tr(),
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
            response.errorMessage ?? 'errors.general'.tr(),
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
            response.errorMessage ?? 'errors.general'.tr(),
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
        currency: 'TRY',
        billingCycle: _subscriptionBillingCycle,
        billingDate: billingDate,
        nextBillingDate: nextBilling.toIso8601String().split('T')[0],
        reminderEnabled: false,
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
            response.errorMessage ?? 'errors.unknownError'.tr(),
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
    } catch (e) {
      debugPrint('Error loading budget stats: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
        currency: 'TRY',
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
            response.errorMessage ?? 'errors.unknownError'.tr(),
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
      final response = await _expenseService.getAllExpenses(
        perPage: 20, // Son 20 harcamayı getir
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
        currency: 'TRY',
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
            response.errorMessage ?? 'errors.unknownError'.tr(),
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
            response.errorMessage ?? 'errors.general'.tr(),
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
        currency: 'TRY',
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
            response.errorMessage ?? 'errors.unknownError'.tr(),
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

  String getCategoryLabel(String category) {
    switch (category) {
      case 'food':
        return 'finance.categories.food'.tr();
      case 'transportation':
        return 'finance.categories.transportation'.tr();
      case 'entertainment':
        return 'finance.categories.entertainment'.tr();
      case 'shopping':
        return 'finance.categories.shopping'.tr();
      case 'bills':
        return 'finance.categories.bills'.tr();
      case 'health':
        return 'finance.categories.health'.tr();
      case 'education':
        return 'finance.categories.education'.tr();
      case 'other':
        return 'finance.categories.other'.tr();
      default:
        return category;
    }
  }

  String getCategoryEmoji(String category) {
    switch (category) {
      case 'food':
        return '🍔';
      case 'transportation':
        return '🚗';
      case 'entertainment':
        return '🎬';
      case 'shopping':
        return '🛍️';
      case 'bills':
        return '📄';
      case 'health':
        return '💊';
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
      case 'food':
        return const Color(0xFFFF6B6B);
      case 'transportation':
        return const Color(0xFF4ECDC4);
      case 'entertainment':
        return const Color(0xFFB794F6);
      case 'shopping':
        return const Color(0xFFFFA07A);
      case 'bills':
        return const Color(0xFF95E1D3);
      case 'health':
        return const Color(0xFFFF5252);
      case 'education':
        return const Color(0xFF667EEA);
      case 'other':
        return const Color(0xFF7EC8F5);
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
    await Future.wait([
      loadSubscriptions(),
      loadBudgetStats(),
      loadIncome(),
      loadSavingsGoal(),
    ]);
    _isInitialLoading = false;
    notifyListeners();
  }

  // ==================== YENİ TASARIM: GELİR + TASARRUF + FORM ====================

  // ---- Gelir (yerel) ----
  static const String _kIncomeKey = 'finance_income_v1';
  List<IncomeEntry> _income = [];
  List<IncomeEntry> get income => _income;

  Future<void> loadIncome() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kIncomeKey);
      _income = [];
      if (raw == null || raw.isEmpty) return;
      final list = jsonDecode(raw) as List;
      _income = list
          .map((e) => IncomeEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {}
  }

  Future<void> _persistIncome() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _kIncomeKey, jsonEncode(_income.map((e) => e.toJson()).toList()));
    } catch (_) {}
  }

  bool _sameMonth(DateTime d) {
    final n = DateTime.now();
    return d.year == n.year && d.month == n.month;
  }

  double get monthIncomeTotal {
    double t = 0;
    for (final i in _income) {
      try {
        if (_sameMonth(DateTime.parse(i.date))) t += i.amount;
      } catch (_) {}
    }
    return t;
  }

  Future<void> addIncome(double amount, String? desc, String category,
      String date, int idSeed) async {
    _income.insert(
        0,
        IncomeEntry(
            id: idSeed,
            amount: amount,
            description: desc,
            category: category,
            date: date));
    await _persistIncome();
    notifyListeners();
  }

  Future<void> deleteIncome(int id) async {
    _income.removeWhere((e) => e.id == id);
    await _persistIncome();
    notifyListeners();
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

  Future<void> loadSavingsGoal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kSavingsKey);
      if (raw == null) return;
      final j = jsonDecode(raw) as Map<String, dynamic>;
      _savingsTarget = (j['target'] as num?)?.toDouble() ?? 25000;
      _savingsCurrent = (j['current'] as num?)?.toDouble() ?? 0;
      _savingsTitle = j['title'] as String? ?? '';
    } catch (_) {}
  }

  Future<void> _persistSavings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _kSavingsKey,
          jsonEncode({
            'target': _savingsTarget,
            'current': _savingsCurrent,
            'title': _savingsTitle,
          }));
    } catch (_) {}
  }

  Future<void> setSavingsGoal(String title, double target) async {
    _savingsTitle = title;
    _savingsTarget = target;
    await _persistSavings();
    notifyListeners();
  }

  Future<void> addToSavings(double amount) async {
    _savingsCurrent += amount;
    await _persistSavings();
    notifyListeners();
  }

  // ---- Aylık toplamlar / grafik verileri ----
  double get monthExpensesTotal {
    double t = 0;
    for (final e in _expenses) {
      if (_sameMonth(e.expenseDate)) t += e.amount;
    }
    return t;
  }

  double get monthSavingsRate {
    final inc = monthIncomeTotal;
    if (inc <= 0) return 0;
    return ((inc - monthExpensesTotal) / inc * 100).clamp(0, 100);
  }

  double get availableBalance => monthIncomeTotal - monthExpensesTotal;

  /// Kategoriye göre bu ayın harcama toplamları (halka grafik).
  Map<String, double> get categoryTotals {
    final m = <String, double>{};
    for (final e in _expenses) {
      if (!_sameMonth(e.expenseDate)) continue;
      m[e.category] = (m[e.category] ?? 0) + e.amount;
    }
    return m;
  }

  /// Son 7 günün günlük harcama toplamları (çubuk grafik).
  List<MapEntry<DateTime, double>> get dailyExpenseSeries {
    final now = DateTime.now();
    final out = <MapEntry<DateTime, double>>[];
    for (int i = 6; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day - i);
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
    final n = DateTime.now();
    final days = n.day;
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

  void removeReceipt() {
    _formReceipt = null;
    notifyListeners();
  }

  void resetFinanceForm({bool income = false}) {
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

    if (_isIncomeForm) {
      final id = DateTime.now().microsecondsSinceEpoch ~/ 1000;
      await addIncome(amount, desc.isEmpty ? null : desc, _formExpCategory,
          _fmtDate(_formExpDate), id);
      if (context.mounted) {
        CustomSnackBar.showSuccess(context, 'success.incomeAdded'.tr());
        Navigator.pop(context);
      }
      return;
    }

    try {
      _isLoading = true;
      notifyListeners();
      final request = ExpenseRequest(
        category: _formExpCategory,
        amount: amount,
        currency: 'TRY',
        description: desc.isEmpty ? null : desc,
        expenseDate: _fmtDate(_formExpDate),
        paymentMethod: null,
        receiptImageUrl: null,
        isRecurring: _formRecurring,
        recurringPattern: null,
        location: _formLocation,
        merchant: null,
      );
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
            context, response.errorMessage ?? 'errors.unknownError'.tr());
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