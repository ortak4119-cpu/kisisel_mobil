import '../../models/debt/debt_models.dart';
import '../base/base_api_service.dart';

abstract class IDebtService {
  Future<List<Debt>> getDebts();
  Future<Debt?> createDebt(DebtRequest request);
  Future<bool> deleteDebt(int id);
}

class DebtService implements IDebtService {
  @override
  Future<List<Debt>> getDebts() async {
    final resp = await BaseApiService.get<Map<String, dynamic>>(
      '/debts',
      requiresAuth: true,
    );
    if (resp.isSuccess && resp.data != null) {
      return (resp.data!['debts'] as List? ?? [])
          .map((e) => Debt.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<Debt?> createDebt(DebtRequest request) async {
    final resp = await BaseApiService.post<Map<String, dynamic>>(
      '/debts',
      body: request.toJson(),
      requiresAuth: true,
    );
    if (resp.isSuccess && resp.data != null) {
      return Debt.fromJson(resp.data!);
    }
    return null;
  }

  @override
  Future<bool> deleteDebt(int id) async {
    final resp = await BaseApiService.delete<void>(
      '/debts/$id',
      requiresAuth: true,
    );
    return resp.isSuccess;
  }
}
