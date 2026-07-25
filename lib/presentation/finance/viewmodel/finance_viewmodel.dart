import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
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
    ]);
    _isInitialLoading = false;
    notifyListeners();
  }
}