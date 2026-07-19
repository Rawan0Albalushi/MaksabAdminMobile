import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../../../core/utils/paginate_response.dart';
import '../../dashboard/domain/zone_model.dart';
import '../domain/deliveryman_request_model.dart';
import '../domain/driver_model.dart';

final driversRepositoryProvider = Provider<DriversRepository>((ref) {
  return DriversRepository(ref.watch(dioProvider));
});

class DriversRepository {
  DriversRepository(this._dio);

  final Dio _dio;

  Future<DriversPageResult> fetchDrivers({
    int page = 1,
    int perPage = 15,
    String? search,
    int? zoneId,
    bool? active,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'perPage': perPage,
      if (search != null && search.isNotEmpty) 'search': search,
      // Send as strings so active=0 is never dropped by query encoding.
      if (active != null) 'active': active ? '1' : '0',
      // Same as portal /deliveries/list: singular zone_id (not zone_ids[]).
      // Zone managers still get scoped via backend zone_ids overwrite.
      if (zoneId != null) 'zone_id': zoneId,
    };

    final json = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.adminDeliverymansPaginate,
      queryParameters: params,
    );

    final body = json.data ?? {};
    if (body['status'] == false) {
      throw Exception(body['message']?.toString() ?? 'Failed to load drivers');
    }

    final items = PaginateResponse.extractItems(body);
    final meta = PaginateResponse.extractMap(body['meta']);

    return DriversPageResult(
      drivers: items.map(DriverModel.fromJson).toList(),
      currentPage: PaginateResponse.parseInt(meta['current_page']) > 0
          ? PaginateResponse.parseInt(meta['current_page'])
          : page,
      lastPage: PaginateResponse.parseInt(meta['last_page']) > 0
          ? PaginateResponse.parseInt(meta['last_page'])
          : 1,
      total: PaginateResponse.parseInt(meta['total']) > 0
          ? PaginateResponse.parseInt(meta['total'])
          : items.length,
    );
  }

  Future<DriverModel> fetchDriver(String uuid) async {
    final json = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.adminUser(uuid),
    );

    final response = ApiResponse<Map<String, dynamic>>.fromJson(
      json.data ?? {},
      (raw) => raw as Map<String, dynamic>,
    );

    if (!response.status || response.data == null) {
      throw Exception(response.message ?? 'Failed to load driver');
    }

    return DriverModel.fromJson(response.data!);
  }

  Future<DriverModel> toggleActive(String uuid) async {
    final json = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.adminUserActive(uuid),
    );

    final response = ApiResponse<Map<String, dynamic>>.fromJson(
      json.data ?? {},
      (raw) => raw is Map<String, dynamic>
          ? raw
          : Map<String, dynamic>.from(raw as Map),
    );

    if (!response.status) {
      throw Exception(response.message ?? 'Failed to update driver status');
    }

    if (response.data != null) {
      return DriverModel.fromJson(response.data!);
    }

    return fetchDriver(uuid);
  }

  Future<List<ZoneModel>> fetchAssignedZones(String uuid) async {
    final json = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.adminUserZones(uuid),
    );

    final body = json.data ?? {};
    final response = ApiResponse<dynamic>.fromJson(body, null);

    if (!response.status && response.data == null) {
      throw Exception(response.message ?? 'Failed to load assigned zones');
    }

    final raw = response.data ?? body['data'];
    if (raw is! List) return const [];

    return raw
        .whereType<Map>()
        .map((item) => ZoneModel.fromJson(Map<String, dynamic>.from(item)))
        .where((zone) => zone.id > 0)
        .toList();
  }

  Future<void> assignZones({
    required int driverId,
    required List<int> zoneIds,
  }) async {
    final json = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.adminAssignDriverZones,
      data: {
        'driver_id': driverId,
        'zone_ids': zoneIds,
      },
    );

    final response = ApiResponse<dynamic>.fromJson(json.data ?? {}, null);
    if (!response.status) {
      throw Exception(response.message ?? 'Failed to assign zones');
    }
  }

  /// Same as portal `/deliveryman/request` → `request-models?type=user`.
  Future<DeliverymanRequestsPageResult> fetchDeliverymanRequests({
    int page = 1,
    int perPage = 15,
    String? search,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'perPage': perPage,
      'type': 'user',
      if (search != null && search.isNotEmpty) 'search': search,
    };

    final json = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.adminRequestModels,
      queryParameters: params,
    );

    final body = json.data ?? {};
    if (body['status'] == false) {
      throw Exception(
        body['message']?.toString() ?? 'Failed to load deliveryman requests',
      );
    }

    final items = PaginateResponse.extractItems(body);
    final meta = PaginateResponse.extractMap(body['meta']);

    return DeliverymanRequestsPageResult(
      requests: items.map(DeliverymanRequestModel.fromJson).toList(),
      currentPage: PaginateResponse.parseInt(meta['current_page']) > 0
          ? PaginateResponse.parseInt(meta['current_page'])
          : page,
      lastPage: PaginateResponse.parseInt(meta['last_page']) > 0
          ? PaginateResponse.parseInt(meta['last_page'])
          : 1,
      total: PaginateResponse.parseInt(meta['total']) > 0
          ? PaginateResponse.parseInt(meta['total'])
          : items.length,
    );
  }

  Future<void> changeDeliverymanRequestStatus({
    required int id,
    required String status,
    String? statusNote,
  }) async {
    final json = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.adminRequestModelStatus(id),
      data: {
        'status': status,
        if (statusNote != null && statusNote.isNotEmpty)
          'status_note': statusNote,
      },
    );

    final response = ApiResponse<dynamic>.fromJson(json.data ?? {}, null);
    if (!response.status) {
      throw Exception(
        response.message ?? 'Failed to update request status',
      );
    }
  }
}
