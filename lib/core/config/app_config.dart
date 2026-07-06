/// Runtime configuration — override via `--dart-define=BASE_URL=...`.
class AppConfig {
  AppConfig._();

  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://uatapi.maksab.om/',
  );

  static const String apiPrefix = 'api/v1/';

  static String get apiUrl => '${baseUrl.endsWith('/') ? baseUrl : '$baseUrl/'}$apiPrefix';

  static const List<String> adminRoles = [
    'admin',
    'manager',
    'admin.accountant',
    'admin.support',
  ];

  static const String adminChatRoleId = 'admin';
}
