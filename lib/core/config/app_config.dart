/// Runtime configuration — override via `--dart-define=BASE_URL=...`.
class AppConfig {
  AppConfig._();

  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://192.168.100.35:8000/',
  );

  static const String apiPrefix = 'api/v1/';

  static String get apiUrl => '${baseUrl.endsWith('/') ? baseUrl : '$baseUrl/'}$apiPrefix';

  /// Roles that may sign in to the admin mobile app.
  static const String roleAdmin = 'admin';
  static const String roleZoneAdmin = 'manager';
  /// Backend role for zone-scoped administrators (see MaksabBackendAPI).
  static const String roleZoneManager = 'zone.manager';
  static const String roleAccountant = 'admin.accountant';
  static const String roleSupport = 'admin.support';

  static const String apiAppHeader = 'admin';

  /// Backend permission that gates admin portal sign-in.
  static const String portalAccessPermission = 'admin.portal.access';

  /// Zone-admin role strings returned by the backend.
  static const List<String> zoneAdminRoles = [
    roleZoneAdmin,
    roleZoneManager,
    'zone.admin',
    'admin.zone',
    'zone_admin',
    'zone-manager',
    'zone_manager',
    'admin.manager',
    'manager.zone',
  ];

  /// Roles allowed to sign in to the admin mobile portal.
  static const List<String> portalRoles = [
    roleAdmin,
    ...zoneAdminRoles,
  ];

  /// Non-admin consumer roles — used to avoid granting portal access by mistake.
  static const List<String> consumerRoles = [
    'user',
    'seller',
    'customer',
    'deliveryman',
    'delivery_man',
    'waiter',
    'cook',
    'moderator',
  ];

  static const List<String> adminRoles = [
    roleAdmin,
    roleZoneAdmin,
    roleZoneManager,
    roleAccountant,
    roleSupport,
    'zone.admin',
    'admin.zone',
    'zone_admin',
  ];

  static const String adminChatRoleId = 'admin';
}
