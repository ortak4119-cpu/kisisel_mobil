import '../base/base_api_service.dart';

class SavingsData {
  final String title;
  final double target;
  final double current;
  SavingsData({required this.title, required this.target, required this.current});

  factory SavingsData.fromJson(Map<String, dynamic> j) {
    double pd(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    return SavingsData(
      title: j['title'] as String? ?? '',
      target: pd(j['target_amount']),
      current: pd(j['current_amount']),
    );
  }
}

abstract class ISavingsService {
  Future<SavingsData?> getSavings();
  Future<bool> updateSavings({String? title, double? target, double? current});
}

class SavingsService implements ISavingsService {
  @override
  Future<SavingsData?> getSavings() async {
    final resp = await BaseApiService.get<Map<String, dynamic>>(
      '/savings',
      requiresAuth: true,
    );
    if (resp.isSuccess && resp.data != null && resp.data!['savings'] != null) {
      return SavingsData.fromJson(resp.data!['savings'] as Map<String, dynamic>);
    }
    return null;
  }

  @override
  Future<bool> updateSavings({String? title, double? target, double? current}) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (target != null) body['target_amount'] = target;
    if (current != null) body['current_amount'] = current;
    final resp = await BaseApiService.put<Map<String, dynamic>>(
      '/savings',
      body: body,
      requiresAuth: true,
    );
    return resp.isSuccess;
  }
}
