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
        message: response.message ?? 'Bütçe başarıyla güncellendi',
      );
    }

    return ServiceResponse.error(
      statusCode: response.statusCode,
      message: response.message ?? 'Bütçe güncellenemedi',
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
}