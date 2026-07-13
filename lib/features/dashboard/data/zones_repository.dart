import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../../../core/utils/paginate_response.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../auth/domain/admin_user.dart';
import '../domain/zone_model.dart';

final zonesRepositoryProvider = Provider<ZonesRepository>((ref) {
  return ZonesRepository(ref.watch(dioProvider));
});

final zonesListProvider = FutureProvider<List<ZoneModel>>((ref) async {
  final allZones = await ref.read(zonesRepositoryProvider).fetchZones();
  final user = ref.watch(authProvider).user;

  return zonesForUser(allZones, user);
});

List<ZoneModel> zonesForUser(List<ZoneModel> allZones, AdminUser? user) {
  if (user == null || !user.shouldScopeZones) {
    return allZones;
  }

  if (user.zoneIds.isNotEmpty) {
    final allowed = user.zoneIds.toSet();
    return allZones.where((zone) => allowed.contains(zone.id)).toList();
  }

  final managedZones =
      allZones.where((zone) => zone.isManagedBy(user.id)).toList();
  if (managedZones.isNotEmpty) {
    return managedZones;
  }

  // Backend already scopes zone lists for zone managers when zoneIds are
  // missing locally — keep the API result instead of wiping the filter.
  return allZones;
}

class ZonesRepository {
  ZonesRepository(this._dio);

  final Dio _dio;

  Future<List<ZoneModel>> fetchZones() async {
    final json = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.adminZones,
      queryParameters: const {
        'page': 1,
        'perPage': 200,
      },
    );

    final body = json.data ?? {};
    final response = ApiResponse<dynamic>.fromJson(body, null);
    final items = _extractZoneItems(response.data ?? body);

    if (items.isEmpty && !response.status) {
      throw Exception(response.message ?? 'Failed to load zones');
    }

    final zones = items
        .map(ZoneModel.fromJson)
        .where((zone) => zone.id > 0 && zone.name.isNotEmpty)
        .toList();

    zones.sort((a, b) => a.name.compareTo(b.name));
    return zones;
  }

  static List<Map<String, dynamic>> _extractZoneItems(dynamic raw) {
    final direct = PaginateResponse.extractItems(raw);
    if (direct.isNotEmpty) return direct;

    if (raw is! Map) return const [];

    final map = Map<String, dynamic>.from(raw);
    for (final key in ['zones', 'zone', 'items', 'results', 'data']) {
      final items = _coerceToItemList(map[key]);
      if (items.isNotEmpty) return items;
    }

    return const [];
  }

  static List<Map<String, dynamic>> _coerceToItemList(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    if (value is Map) {
      final nested = Map<String, dynamic>.from(value);
      final paginated = PaginateResponse.extractItems(nested);
      if (paginated.isNotEmpty) return paginated;

      for (final key in ['zones', 'zone', 'items', 'results', 'data']) {
        final items = _coerceToItemList(nested[key]);
        if (items.isNotEmpty) return items;
      }
    }

    return const [];
  }
}
