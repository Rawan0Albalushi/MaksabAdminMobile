import '../config/app_config.dart';

abstract class MediaUrl {
  MediaUrl._();

  /// Converts API-relative paths (e.g. `restaurant/logo/...`) to absolute URLs.
  static String? resolve(String? path) {
    if (path == null) return null;

    final trimmed = path.trim();
    if (trimmed.isEmpty) return null;

    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.hasScheme && uri.host.isNotEmpty) {
      return trimmed;
    }

    final base = AppConfig.baseUrl.endsWith('/')
        ? AppConfig.baseUrl
        : '${AppConfig.baseUrl}/';
    final normalized = trimmed.startsWith('/') ? trimmed.substring(1) : trimmed;
    return '$base$normalized';
  }
}
