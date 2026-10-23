import '../../models/income/income_models.dart';
import '../base/base_api_service.dart';
import '../response/service_response.dart';

abstract class IIncomeService {
  Future<ServiceResponse<PaginatedResponse<ApiIncome>>> getAllIncomes({
    String? startDate,
    String? endDate,
    int? perPage,
  });
  Future<ServiceResponse<ApiIncome>> createIncome(IncomeRequest request);
  Future<ServiceResponse<void>> deleteIncome(int id);
}

class IncomeService implements IIncomeService {
  @override
  Future<ServiceResponse<PaginatedResponse<ApiIncome>>> getAllIncomes({
    String? startDate,
    String? endDate,
    int? perPage,
  }) async {
    final queryParams = <String, dynamic>{};
    if (startDate != null) queryParams['start_date'] = startDate;
    if (endDate != null) queryParams['end_date'] = endDate;
    if (perPage != null) queryParams['per_page'] = perPage;

    return await BaseApiService.getPaginated<ApiIncome>(
      '/incomes',
      queryParameters: queryParams,
      requiresAuth: true,
      fromJson: (json) => ApiIncome.fromJson(json),
    );
  }

  @override
  Future<ServiceResponse<ApiIncome>> createIncome(IncomeRequest request) async {
    final response = await BaseApiService.post<Map<String, dynamic>>(
      '/incomes',
      body: request.toJson(),
      requiresAuth: true,
    );

    if (response.isSuccess && response.data != null) {
      return ServiceResponse.success(
        statusCode: response.statusCode,
        data: ApiIncome.fromJson(response.data!),
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
  Future<ServiceResponse<void>> deleteIncome(int id) async {
    return await BaseApiService.delete<void>(
      '/incomes/$id',
      requiresAuth: true,
    );
  }
}
