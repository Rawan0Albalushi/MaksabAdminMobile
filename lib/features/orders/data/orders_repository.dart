import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../../../core/utils/api_date.dart';
import '../../../core/utils/paginate_response.dart';
import '../domain/order_model.dart';

final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  return OrdersRepository(ref.watch(dioProvider));
});

class OrdersRepository {
  OrdersRepository(this._dio);

  final Dio _dio;

  Future<OrdersPageResult> fetchOrders({
    int page = 1,
    int perPage = 15,
    String? status,
    String? search,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'perPage': perPage,
      if (status != null && status.isNotEmpty && status != 'all') 'status': status,
      if (search != null && search.isNotEmpty) 'search': search,
      if (dateFrom != null && dateTo != null) ...{
        'date_from': ApiDate.format(dateFrom),
        'date_to': ApiDate.format(dateTo),
      },
    };

    final json = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.adminOrdersPaginate,
      queryParameters: params,
    );

    final response = ApiResponse<Map<String, dynamic>>.fromJson(
      json.data ?? {},
      (raw) => PaginateResponse.extractMap(raw),
    );

    if (!response.status || response.data == null) {
      throw Exception(response.message ?? 'Failed to load orders');
    }

    final paginate = PaginateResponse.fromData(response.data!);
    final meta = paginate.meta;

    return OrdersPageResult(
      orders: paginate.items.map(OrderModel.fromJson).toList(),
      statistic: paginate.statistic,
      currentPage: PaginateResponse.parseInt(meta['current_page']) > 0
          ? PaginateResponse.parseInt(meta['current_page'])
          : page,
      lastPage: PaginateResponse.parseInt(meta['last_page']) > 0
          ? PaginateResponse.parseInt(meta['last_page'])
          : 1,
      total: PaginateResponse.parseInt(meta['total']) > 0
          ? PaginateResponse.parseInt(meta['total'])
          : paginate.items.length,
    );
  }

  Future<OrderModel> fetchOrder(int id) async {
    final json = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.adminOrder(id),
    );

    final response = ApiResponse<Map<String, dynamic>>.fromJson(
      json.data ?? {},
      (raw) => raw as Map<String, dynamic>,
    );

    if (!response.status || response.data == null) {
      throw Exception(response.message ?? 'Failed to load order');
    }

    return OrderModel.fromJson(response.data!);
  }

  Future<void> updateStatus(int id, String status) async {
    final json = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.adminOrderStatus(id),
      queryParameters: {'status': status},
    );

    final response = ApiResponse<dynamic>.fromJson(json.data ?? {}, null);
    if (!response.status) {
      throw Exception(response.message ?? 'Failed to update status');
    }
  }
}
