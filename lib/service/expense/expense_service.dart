import 'package:flutter/foundation.dart';
import '../../models/budget/buget_models.dart';
import '../base/base_api_service.dart';
import '../response/service_response.dart';

abstract class IExpenseService {
  Future<ServiceResponse<PaginatedResponse<Expense>>> getAllExpenses({
    String? category,
    String? startDate,
    String? endDate,
    int? page,
    int? perPage,
  });
  Future<ServiceResponse<Expense>> getExpense(int id);
  Future<ServiceResponse<Expense>> createExpense(ExpenseRequest request);
  Future<ServiceResponse<Expense>> updateExpense(int id, ExpenseRequest request);
  Future<ServiceResponse<void>> deleteExpense(int id);
  Future<ServiceResponse<Map<String, dynamic>>> getExpenseStats();
  Future<ServiceResponse<Map<String, dynamic>>> getExpensesByCategory({
    int? month,
    int? year,
  });
  Future<ServiceResponse<Map<String, dynamic>>> getMonthlyExpenses({int? year});
  Future<ServiceResponse<Map<String, dynamic>>> getMonthlyStatistics({int? year});
}

class ExpenseService implements IExpenseService {
  @override
  Future<ServiceResponse<PaginatedResponse<Expense>>> getAllExpenses({
    String? category,
    String? startDate,
    String? endDate,
    int? page,
    int? perPage,
  }) async {
    final queryParams = <String, dynamic>{};
    if (category != null) queryParams['category'] = category;
    if (startDate != null) queryParams['start_date'] = startDate;
    if (endDate != null) queryParams['end_date'] = endDate;
    if (page != null) queryParams['page'] = page;
    if (perPage != null) queryParams['per_page'] = perPage;

    return await BaseApiService.getPaginated<Expense>(
      '/expenses',
      queryParameters: queryParams,
      requiresAuth: true,
      fromJson: (json) => Expense.fromJson(json),
    );
  }

  @override
  Future<ServiceResponse<Expense>> getExpense(int id) async {
    return await BaseApiService.get<Expense>(
      '/expenses/$id',
      requiresAuth: true,
      fromJson: (json) => Expense.fromJson(json as Map<String, dynamic>),
    );
  }

  @override
  Future<ServiceResponse<Expense>> createExpense(ExpenseRequest request) async {
    final response = await BaseApiService.post<Map<String, dynamic>>(
      '/expenses',
      body: request.toJson(),
      requiresAuth: true,
    );

    if (response.isSuccess && response.data != null) {
      final expense = Expense.fromJson(response.data!);
      return ServiceResponse.success(
        statusCode: response.statusCode,
        data: expense,
        message: response.message ?? 'Harcama başarıyla eklendi',
      );
    }

    return ServiceResponse.error(
      statusCode: response.statusCode,
      message: response.message ?? 'Harcama oluşturulamadı',
      errors: response.errors,
    );
  }

  @override
  Future<ServiceResponse<Expense>> updateExpense(
      int id,
      ExpenseRequest request,
      ) async {
    return await BaseApiService.put<Expense>(
      '/expenses/$id',
      body: request.toJson(),
      requiresAuth: true,
      fromJson: (json) => Expense.fromJson(json as Map<String, dynamic>),
    );
  }

  @override
  Future<ServiceResponse<void>> deleteExpense(int id) async {
    return await BaseApiService.delete<void>(
      '/expenses/$id',
      requiresAuth: true,
    );
  }

  @override
  Future<ServiceResponse<Map<String, dynamic>>> getExpenseStats() async {
    return await BaseApiService.get<Map<String, dynamic>>(
      '/expenses/stats',
      requiresAuth: true,
    );
  }

  @override
  Future<ServiceResponse<Map<String, dynamic>>> getExpensesByCategory({
    int? month,
    int? year,
  }) async {
    final queryParams = <String, dynamic>{};
    if (month != null) queryParams['month'] = month;
    if (year != null) queryParams['year'] = year;

    return await BaseApiService.get<Map<String, dynamic>>(
      '/expenses/by-category',
      queryParameters: queryParams,
      requiresAuth: true,
    );
  }

  @override
  Future<ServiceResponse<Map<String, dynamic>>> getMonthlyExpenses({
    int? year,
  }) async {
    final queryParams = <String, dynamic>{};
    if (year != null) queryParams['year'] = year;

    return await BaseApiService.get<Map<String, dynamic>>(
      '/expenses/monthly',
      queryParameters: queryParams,
      requiresAuth: true,
    );
  }

  @override
  Future<ServiceResponse<Map<String, dynamic>>> getMonthlyStatistics({
    int? year,
  }) async {
    final queryParams = <String, dynamic>{};
    if (year != null) queryParams['year'] = year;

    debugPrint('🌐 [ExpenseService] GET /expenses/monthly-statistics');
    debugPrint('🌐 [ExpenseService] Query params: $queryParams');

    final response = await BaseApiService.get<Map<String, dynamic>>(
      '/expenses/monthly-statistics',
      queryParameters: queryParams,
      requiresAuth: true,
    );

    debugPrint('🌐 [ExpenseService] Response status: ${response.statusCode}');
    debugPrint('🌐 [ExpenseService] Response success: ${response.isSuccess}');
    if (!response.isSuccess) {
      debugPrint('🌐 [ExpenseService] Error: ${response.message}');
      debugPrint('🌐 [ExpenseService] Errors: ${response.errors}');
    }

    return response;
  }
}