import 'package:easy_localization/easy_localization.dart';
import '../../models/budget/buget_models.dart';
import '../base/base_api_service.dart';
import '../response/service_response.dart';

abstract class IBudgetService {
  Future<ServiceResponse<Budget>> getBudget();
  Future<ServiceResponse<Budget>> updateBudget(BudgetRequest request);
  Future<ServiceResponse<BudgetStats>> getBudgetStats();
  Future<ServiceResponse<MonthlyReport>> getMonthlyReport({
    int? month,
    int? year,
  });
  Future<ServiceResponse<List<CategoryBudget>>> getCategoryBudgets();
  Future<ServiceResponse<void>> setCategoryBudget(String category, double limit);
  Future<ServiceResponse<void>> deleteCategoryBudget(String category);
  // Ay bazlı bütçe kilitleri
  Future<ServiceResponse<Map<String, double>>> getMonthBudgets();
  Future<ServiceResponse<void>> setMonthBudget(String month, double amount);
  Future<ServiceResponse<void>> deleteMonthBudget(String month);
  // Açılış/mevcut bakiye
  Future<ServiceResponse<void>> setOpeningBalance(double amount, String month);
  Future<ServiceResponse<void>> clearOpeningBalance();
}

class BudgetService implements IBudgetService {
  @override
  Future<ServiceResponse<Budget>> getBudget() async {
    final response = await BaseApiService.get<Map<String, dynamic>>(
      '/budget',
      requiresAuth: true,
    );

    if (response.isSuccess && response.data != null) {
      final budget = Budget.fromJson(
        response.data!['budget'] as Map<String, dynamic>,
      );
      return ServiceResponse.success(
        statusCode: response.statusCode,
        data: budget,
        message: response.message,
      );
    }

    return ServiceResponse.error(
      statusCode: response.statusCode,
      message: response.message,
      errors: response.errors,
    );
  }

  @override
  Future<ServiceResponse<Budget>> updateBudget(BudgetRequest request) async {
    final response = await BaseApiService.put<Map<String, dynamic>>(
      '/budget',
      body: request.toJson(),
      requiresAuth: true,
    );

    if (response.isSuccess && response.data != null) {
      final budget = Budget.fromJson(response.data!);
      return ServiceResponse.success(
        statusCode: response.statusCode,
        data: budget,
        message: response.message ?? 'messages.budgetUpdated'.tr(),
      );
    }

    return ServiceResponse.error(
      statusCode: response.statusCode,
      message: response.message ?? 'messages.budgetUpdateFailed'.tr(),
      errors: response.errors,
    );
  }

  @override
  Future<ServiceResponse<BudgetStats>> getBudgetStats() async {
    return await BaseApiService.get<BudgetStats>(
      '/budget/stats',
      requiresAuth: true,
      fromJson: (json) => BudgetStats.fromJson(json as Map<String, dynamic>),
    );
  }

  @override
  Future<ServiceResponse<MonthlyReport>> getMonthlyReport({
    int? month,
    int? year,
  }) async {
    final queryParams = <String, dynamic>{};
    if (month != null) queryParams['month'] = month;
    if (year != null) queryParams['year'] = year;

    return await BaseApiService.get<MonthlyReport>(
      '/budget/monthly-report',
      queryParameters: queryParams,
      requiresAuth: true,
      fromJson: (json) => MonthlyReport.fromJson(json as Map<String, dynamic>),
    );
  }

  @override
  Future<ServiceResponse<List<CategoryBudget>>> getCategoryBudgets() async {
    final response = await BaseApiService.get<Map<String, dynamic>>(
      '/budget/categories',
      requiresAuth: true,
    );
    if (response.isSuccess && response.data != null) {
      final list = (response.data!['categories'] as List? ?? [])
          .map((e) => CategoryBudget.fromJson(e as Map<String, dynamic>))
          .toList();
      return ServiceResponse.success(
        statusCode: response.statusCode,
        data: list,
        message: response.message,
      );
    }
    return ServiceResponse.error(
      statusCode: response.statusCode,
      message: response.message,
      errors: response.errors,
    );
  }

  @override
  Future<ServiceResponse<void>> setCategoryBudget(
      String category, double limit) async {
    return await BaseApiService.put<void>(
      '/budget/categories',
      body: {'category': category, 'monthly_limit': limit},
      requiresAuth: true,
    );
  }

  @override
  Future<ServiceResponse<void>> deleteCategoryBudget(String category) async {
    return await BaseApiService.delete<void>(
      '/budget/categories/$category',
      requiresAuth: true,
    );
  }

  @override
  Future<ServiceResponse<Map<String, double>>> getMonthBudgets() async {
    final response = await BaseApiService.get<Map<String, dynamic>>(
      '/budget/month-budgets',
      requiresAuth: true,
    );
    if (response.isSuccess && response.data != null) {
      final map = <String, double>{};
      for (final e in (response.data!['month_budgets'] as List? ?? [])) {
        final m = e as Map<String, dynamic>;
        final month = m['month'] as String?;
        if (month == null) continue;
        final amt = m['amount'];
        map[month] = amt is num
            ? amt.toDouble()
            : double.tryParse('$amt') ?? 0;
      }
      return ServiceResponse.success(
        statusCode: response.statusCode,
        data: map,
        message: response.message,
      );
    }
    return ServiceResponse.error(
      statusCode: response.statusCode,
      message: response.message,
      errors: response.errors,
    );
  }

  @override
  Future<ServiceResponse<void>> setMonthBudget(
      String month, double amount) async {
    return await BaseApiService.put<void>(
      '/budget/month-budgets',
      body: {'month': month, 'amount': amount},
      requiresAuth: true,
    );
  }

  @override
  Future<ServiceResponse<void>> deleteMonthBudget(String month) async {
    return await BaseApiService.delete<void>(
      '/budget/month-budgets/$month',
      requiresAuth: true,
    );
  }

  @override
  Future<ServiceResponse<void>> setOpeningBalance(
      double amount, String month) async {
    return await BaseApiService.put<void>(
      '/budget/opening-balance',
      body: {'opening_balance': amount, 'opening_month': month},
      requiresAuth: true,
    );
  }

  @override
  Future<ServiceResponse<void>> clearOpeningBalance() async {
    return await BaseApiService.put<void>(
      '/budget/opening-balance',
      body: {'opening_balance': null},
      requiresAuth: true,
    );
  }
}