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
    int? zoneId,
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
      if (zoneId != null) 'zone_id': zoneId,
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

    var order = OrderModel.fromJson(response.data!);
    if (order.shopPhone == null) {
      final phone = await _fetchShopPhone(
        shopId: order.shopId,
        shopUuid: order.shopUuid,
      );
      if (phone != null) {
        order = order.copyWith(shopPhone: phone);
      }
    }

    return order;
  }

  Future<String?> _fetchShopPhone({
    int? shopId,
    String? shopUuid,
  }) async {
    final shopKey = shopUuid ?? shopId?.toString();
    if (shopKey == null || shopKey.isEmpty) return null;

    try {
      final json = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.adminShop(shopKey),
      );

      final response = ApiResponse<Map<String, dynamic>>.fromJson(
        json.data ?? {},
        (raw) => raw as Map<String, dynamic>,
      );

      if (!response.status || response.data == null) return null;

      final shop = response.data!;
      final phone = shop['phone']?.toString().trim();
      if (phone != null && phone.isNotEmpty) return phone;

      final seller = shop['seller'];
      if (seller is Map) {
        final sellerPhone = seller['phone']?.toString().trim();
        if (sellerPhone != null && sellerPhone.isNotEmpty) return sellerPhone;
      }
    } catch (_) {
      return null;
    }

    return null;
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
