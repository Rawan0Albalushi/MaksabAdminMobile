import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../../../core/utils/paginate_response.dart';
import '../domain/shop_model.dart';

final shopsRepositoryProvider = Provider<ShopsRepository>((ref) {
  return ShopsRepository(ref.watch(dioProvider));
});

class ShopsRepository {
  ShopsRepository(this._dio);

  final Dio _dio;

  Future<ShopsPageResult> fetchShops({
    int page = 1,
    int perPage = 15,
    String? status,
    String? search,
    int? zoneId,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'perPage': perPage,
      if (search != null && search.isNotEmpty) 'search': search,
      if (zoneId != null) 'zone_id': zoneId,
    };

    if (status == 'deleted') {
      params['deleted_at'] = 'deleted_at';
    } else if (status != null && status.isNotEmpty && status != 'all') {
      params['status'] = status;
    }

    final json = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.adminShopsPaginate,
      queryParameters: params,
    );

    final body = json.data ?? {};
    if (body['status'] == false) {
      throw Exception(body['message']?.toString() ?? 'Failed to load shops');
    }

    final items = PaginateResponse.extractItems(body);
    final meta = PaginateResponse.extractMap(body['meta']);

    return ShopsPageResult(
      shops: items.map(ShopModel.fromJson).toList(),
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

  Future<ShopModel> fetchShop(String uuid) async {
    final json = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.adminShop(uuid),
    );

    final response = ApiResponse<Map<String, dynamic>>.fromJson(
      json.data ?? {},
      (raw) => raw as Map<String, dynamic>,
    );

    if (!response.status || response.data == null) {
      throw Exception(response.message ?? 'Failed to load shop');
    }

    return ShopModel.fromJson(response.data!);
  }

  Future<void> toggleVerify(String uuid) async {
    final json = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.adminShopVerify(uuid),
    );

    final response = ApiResponse<dynamic>.fromJson(json.data ?? {}, null);
    if (!response.status) {
      throw Exception(response.message ?? 'Failed to update verification');
    }
  }

  Future<void> changeStatus(String uuid, String status) async {
    final json = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.adminShopStatusChange(uuid),
      queryParameters: {'status': status},
    );

    final response = ApiResponse<dynamic>.fromJson(json.data ?? {}, null);
    if (!response.status) {
      throw Exception(response.message ?? 'Failed to update status');
    }
  }

  Future<void> toggleWorkingStatus(String uuid) async {
    final json = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.adminShopWorkingStatus(uuid),
    );

    final response = ApiResponse<dynamic>.fromJson(json.data ?? {}, null);
    if (!response.status) {
      throw Exception(response.message ?? 'Failed to update open status');
    }
  }
}
