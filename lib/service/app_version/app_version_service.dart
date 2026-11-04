import 'dart:io';
import 'package:package_info_plus/package_info_plus.dart';
import '../base/base_api_service.dart';
import '../../models/app_version/app_version_models.dart';

/// Uygulama sürüm kontrolü servisi. Açılışta backend'e kendi sürümünü sorar.
class AppVersionService {
  Future<AppVersionCheck?> check() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final version = info.version; // ör. 3.1.0
      final platform = Platform.isIOS ? 'ios' : 'android';

      final response = await BaseApiService.get<AppVersionCheck>(
        '/app-version',
        queryParameters: {'platform': platform, 'version': version},
        requiresAuth: false,
        fromJson: (json) =>
            AppVersionCheck.fromJson(json as Map<String, dynamic>),
      );

      return response.isSuccess ? response.data : null;
    } catch (_) {
      // Sürüm kontrolü başarısız olursa uygulamayı engelleme.
      return null;
    }
  }
}
