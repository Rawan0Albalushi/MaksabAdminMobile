import '../../../core/config/app_config.dart';
import '../../../core/utils/media_url.dart';

class AdminUser {
  const AdminUser({
    required this.id,
    required this.firstname,
    required this.lastname,
    required this.email,
    required this.roles,
    this.uuid,
    this.permissions = const [],
    this.zoneIds = const [],
    this.img,
    this.token,
  });

  final int id;
  final String? uuid;
  final String firstname;
  final String lastname;
  final String email;
  final List<String> roles;
  final List<String> permissions;
  final List<int> zoneIds;
  final String? img;
  final String? token;

  String get fullName => '$firstname $lastname'.trim();

  bool get isFullAdmin => _hasAnyRole([AppConfig.roleAdmin]);

  bool get isZoneAdmin =>
      !isFullAdmin &&
      (_hasAnyRole(AppConfig.zoneAdminRoles) || _hasZoneAssignment);

  bool get _hasZoneAssignment => zoneIds.isNotEmpty;

  /// Only full admins and zone admins may use the mobile admin portal.
  bool get canAccessPortal =>
      isFullAdmin || isZoneAdmin || hasPermission(AppConfig.portalAccessPermission);

  @Deprecated('Use canAccessPortal')
  bool get isAdminPortal => canAccessPortal;

  bool hasPermission(String permission) {
    final key = permission.trim().toLowerCase();
    return permissions
        .map((p) => p.trim().toLowerCase())
        .any((p) => p == key);
  }

  bool hasAnyPermission(List<String> required) {
    return required.any(hasPermission);
  }

  bool canAccessRoles(List<String> allowedRoles) {
    if (isFullAdmin) return true;
    if (isZoneAdmin &&
        allowedRoles.any(AppConfig.zoneAdminRoles.contains)) {
      return true;
    }
    return _hasAnyRole(allowedRoles);
  }

  bool _hasAnyRole(List<String> candidates) {
    final normalizedRoles = roles.map(_normalizeRole).toSet();
    final normalizedCandidates = candidates.map(_normalizeRole).toSet();
    return normalizedRoles.any(normalizedCandidates.contains);
  }

  bool get shouldScopeZones => isZoneAdmin && !isFullAdmin;

  AdminUser copyWith({
    int? id,
    String? uuid,
    String? firstname,
    String? lastname,
    String? email,
    List<String>? roles,
    List<String>? permissions,
    List<int>? zoneIds,
    String? img,
    String? token,
  }) {
    return AdminUser(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      firstname: firstname ?? this.firstname,
      lastname: lastname ?? this.lastname,
      email: email ?? this.email,
      roles: roles ?? this.roles,
      permissions: permissions ?? this.permissions,
      zoneIds: zoneIds ?? this.zoneIds,
      img: img ?? this.img,
      token: token ?? this.token,
    );
  }

  static String _normalizeRole(String role) => role.trim().toLowerCase();

  /// Builds a user profile map from the login `data` envelope.
  static Map<String, dynamic> profileFromLoginData(Map<String, dynamic> data) {
    final userRaw = data['user'];
    final profile = userRaw is Map
        ? Map<String, dynamic>.from(userRaw)
        : Map<String, dynamic>.from(data);

    const sharedKeys = [
      'roles',
      'role',
      'role_names',
      'permissions',
      'abilities',
      'zones',
      'zone',
      'zone_id',
      'zone_ids',
      'managed_zones',
      'manage_zones',
      'delivery_zone_id',
      'invite',
      'invitations',
      'invitation',
      'zone_invite',
      'zone_invites',
      'admin_zones',
      'user_zones',
    ];

    for (final key in sharedKeys) {
      final envelopeValue = data[key];
      if (envelopeValue == null) continue;
      final current = profile[key];
      final missing = current == null ||
          current == '' ||
          (current is List && current.isEmpty);
      if (missing) {
        profile[key] = envelopeValue;
      }
    }

    return profile;
  }

  static String? accessTokenFromLoginData(Map<String, dynamic> data) {
    for (final key in ['access_token', 'token', 'accessToken']) {
      final value = data[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  factory AdminUser.fromJson(Map<String, dynamic> json, {String? token}) {
    final roles = _parseRoles(json);
    var permissions = _parseStringList(json['permissions']) ??
        _parseStringList(json['abilities']) ??
        const <String>[];

    // Match portal legacyDefaults when API omits permissions for known roles.
    if (permissions.isEmpty) {
      permissions = _legacyPermissionsForRoles(roles);
    }

    final uuid = json['uuid']?.toString().trim();

    return AdminUser(
      id: _parseId(json['id']),
      uuid: (uuid != null && uuid.isNotEmpty) ? uuid : null,
      firstname: json['firstname']?.toString() ??
          json['first_name']?.toString() ??
          '',
      lastname: json['lastname']?.toString() ??
          json['last_name']?.toString() ??
          '',
      email: json['email']?.toString() ?? '',
      roles: roles,
      permissions: permissions,
      zoneIds: _parseZoneIds(json),
      img: MediaUrl.resolve(json['img']?.toString()),
      token: token,
    );
  }

  /// Mirrors MaksabPortalFrontend `getLegacyAdminPermissions`.
  static List<String> _legacyPermissionsForRoles(List<String> roles) {
    final normalized = roles.map(_normalizeRole).toSet();
    if (normalized.contains(AppConfig.roleAdmin)) {
      return const [
        AppConfig.portalAccessPermission,
        'admin.users.view',
        'admin.users.manage',
        'admin.orders.view',
        'admin.orders.manage',
        'admin.orders.refund',
        'admin.shops.manage',
        'admin.payouts.manage',
        'admin.transactions.view',
        'admin.settings.manage',
        'admin.reports.view',
        'admin.roles.manage',
        'admin.chat.view',
      ];
    }
    if (normalized.contains(AppConfig.roleZoneManager) ||
        normalized.contains('zone_manager') ||
        normalized.contains('zone-manager')) {
      return const [
        AppConfig.portalAccessPermission,
        'admin.users.view',
        'admin.users.manage',
        'admin.orders.view',
        'admin.orders.manage',
        'admin.shops.manage',
      ];
    }
    if (normalized.contains(AppConfig.roleZoneAdmin)) {
      return const [
        AppConfig.portalAccessPermission,
        'admin.users.view',
        'admin.users.manage',
        'admin.orders.view',
        'admin.orders.manage',
        'admin.orders.refund',
        'admin.shops.manage',
        'admin.payouts.manage',
        'admin.transactions.view',
        'admin.reports.view',
        'admin.chat.view',
      ];
    }
    return const [];
  }

  static int _parseId(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? 0;
    return 0;
  }

  static List<String> _parseRoles(Map<String, dynamic> json) {
    final fromRoles = _parseRoleList(json['roles']);
    if (fromRoles.isNotEmpty) return fromRoles;

    final singleRole = _parseRoleValue(json['role']);
    if (singleRole != null) return [singleRole];

    final roleNames = _parseStringList(json['role_names']);
    if (roleNames != null && roleNames.isNotEmpty) return roleNames;

    return const [];
  }

  static List<String> _parseRoleList(dynamic value) {
    if (value is! List) return const [];
    return value.map(_parseRoleValue).whereType<String>().toList();
  }

  static String? _parseRoleValue(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      final role = value.trim();
      return role.isEmpty ? null : role;
    }
    if (value is Map) {
      for (final key in ['name', 'slug', 'role', 'key', 'code', 'title']) {
        final role = _readLocalizedValue(value[key]);
        if (role != null && role.isNotEmpty) return role;
      }
    }
    return null;
  }

  static String? _readLocalizedValue(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      final text = value.trim();
      return text.isEmpty ? null : text;
    }
    if (value is Map) {
      for (final entry in value.entries) {
        final text = entry.value?.toString().trim();
        if (text != null && text.isNotEmpty) return text;
      }
    }
    return null;
  }

  static List<int> _parseZoneIds(Map<String, dynamic> json) {
    final ids = <int>{};

    void addId(dynamic value) {
      final id = _parseId(value);
      if (id > 0) ids.add(id);
    }

    addId(json['zone_id']);
    addId(json['delivery_zone_id']);

    for (final key in [
      'zones',
      'zone',
      'zone_ids',
      'zoneIds',
      'managed_zones',
      'manage_zones',
      'admin_zones',
      'user_zones',
      'assign_zones',
      'zone_invites',
    ]) {
      final value = json[key];
      if (value is List) {
        for (final item in value) {
          if (item is Map) {
            addId(item['id'] ?? item['zone_id']);
          } else {
            addId(item);
          }
        }
      } else if (value is Map) {
        addId(value['id'] ?? value['zone_id']);
        final nested = value['data'];
        if (nested is List) {
          for (final item in nested) {
            if (item is Map) {
              addId(item['id'] ?? item['zone_id']);
            } else {
              addId(item);
            }
          }
        }
      } else {
        addId(value);
      }
    }

    for (final key in [
      'invite',
      'invitations',
      'invitation',
      'zone_invite',
      'zone_invites',
    ]) {
      final value = json[key];
      if (value is List) {
        for (final item in value) {
          if (item is! Map) continue;
          addId(item['zone_id']);
          final zone = item['zone'];
          if (zone is Map) addId(zone['id'] ?? zone['zone_id']);
        }
      } else if (value is Map) {
        addId(value['zone_id']);
        final zone = value['zone'];
        if (zone is Map) addId(zone['id'] ?? zone['zone_id']);
      }
    }

    return ids.toList();
  }

  static List<String>? _parseStringList(dynamic value) {
    if (value is! List) return null;
    return value
        .map((item) => item?.toString().trim())
        .whereType<String>()
        .where((item) => item.isNotEmpty)
        .toList();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'uuid': uuid,
        'firstname': firstname,
        'lastname': lastname,
        'email': email,
        'roles': roles,
        'permissions': permissions,
        'zoneIds': zoneIds,
        'img': img,
      };
}
