import '../../models/installment/installment_models.dart';
import '../base/base_api_service.dart';

abstract class IInstallmentService {
  Future<List<Installment>> getInstallments();
  Future<Installment?> createInstallment(InstallmentRequest request);
  Future<bool> updatePaidCount(int id, int paidCount);
  Future<bool> deleteInstallment(int id);
}

class InstallmentService implements IInstallmentService {
  @override
  Future<List<Installment>> getInstallments() async {
    final resp = await BaseApiService.get<Map<String, dynamic>>(
      '/installments',
      requiresAuth: true,
    );
    if (resp.isSuccess && resp.data != null) {
      return (resp.data!['installments'] as List? ?? [])
          .map((e) => Installment.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<Installment?> createInstallment(InstallmentRequest request) async {
    final resp = await BaseApiService.post<Map<String, dynamic>>(
      '/installments',
      body: request.toJson(),
      requiresAuth: true,
    );
    if (resp.isSuccess && resp.data != null) {
      return Installment.fromJson(resp.data!);
    }
    return null;
  }

  @override
  Future<bool> updatePaidCount(int id, int paidCount) async {
    final resp = await BaseApiService.put<Map<String, dynamic>>(
      '/installments/$id',
      body: {'paid_count': paidCount},
      requiresAuth: true,
    );
    return resp.isSuccess;
  }

  @override
  Future<bool> deleteInstallment(int id) async {
    final resp = await BaseApiService.delete<void>(
      '/installments/$id',
      requiresAuth: true,
    );
    return resp.isSuccess;
  }
}
