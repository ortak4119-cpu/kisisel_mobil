import '../base/base_api_service.dart';

class SecurityPinStatus {
  final bool hasPin;
  final bool locked;
  SecurityPinStatus({required this.hasPin, required this.locked});
}

abstract class ISecurityPinService {
  Future<SecurityPinStatus> getStatus({String type});
  Future<bool> setPin(String pin, {String? currentPin, String type});
  Future<Map<String, dynamic>> verifyPin(String pin, {String type});
  Future<bool> removePin(String pin, {String type});
}

class SecurityPinService implements ISecurityPinService {
  @override
  Future<SecurityPinStatus> getStatus({String type = 'finance'}) async {
    final resp = await BaseApiService.get<Map<String, dynamic>>(
      '/security-pin/status',
      queryParameters: {'type': type},
      requiresAuth: true,
    );
    final d = resp.data;
    if (resp.isSuccess && d != null) {
      return SecurityPinStatus(
        hasPin: d['has_pin'] == true,
        locked: d['locked'] == true,
      );
    }
    return SecurityPinStatus(hasPin: false, locked: false);
  }

  @override
  Future<bool> setPin(String pin, {String? currentPin, String type = 'finance'}) async {
    final body = <String, dynamic>{'pin': pin, 'pin_type': type};
    if (currentPin != null) body['current_pin'] = currentPin;
    final resp = await BaseApiService.post<Map<String, dynamic>>(
      '/security-pin',
      body: body,
      requiresAuth: true,
    );
    return resp.isSuccess;
  }

  @override
  Future<Map<String, dynamic>> verifyPin(String pin, {String type = 'finance'}) async {
    final resp = await BaseApiService.post<Map<String, dynamic>>(
      '/security-pin/verify',
      body: {'pin': pin, 'pin_type': type},
      requiresAuth: true,
    );
    if (resp.isSuccess && resp.data != null) return resp.data!;
    return {'verified': false};
  }

  @override
  Future<bool> removePin(String pin, {String type = 'finance'}) async {
    final resp = await BaseApiService.delete<Map<String, dynamic>>(
      '/security-pin',
      body: {'pin': pin, 'type': type},
      requiresAuth: true,
    );
    return resp.isSuccess;
  }
}
