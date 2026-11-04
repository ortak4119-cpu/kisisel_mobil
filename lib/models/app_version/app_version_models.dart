/// Uygulama sürüm kontrolü yanıtı (backend /app-version).
class AppVersionCheck {
  final bool updateAvailable;
  final bool forceUpdate;
  final String? latestVersion;
  final String? storeUrl;
  final String? message;
  final String? releaseNotes; // "güncellemede neler var" — İncele popup'ı

  AppVersionCheck({
    required this.updateAvailable,
    required this.forceUpdate,
    this.latestVersion,
    this.storeUrl,
    this.message,
    this.releaseNotes,
  });

  factory AppVersionCheck.fromJson(Map<String, dynamic> json) {
    return AppVersionCheck(
      updateAvailable: json['update_available'] == true,
      forceUpdate: json['force_update'] == true,
      latestVersion: json['latest_version'] as String?,
      storeUrl: json['store_url'] as String?,
      message: json['message'] as String?,
      releaseNotes: json['release_notes'] as String?,
    );
  }
}
