import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../../../core/utils/paginate_response.dart';
import '../domain/refund_model.dart';

final refundsRepositoryProvider = Provider<RefundsRepository>((ref) {
  return RefundsRepository(ref.watch(dioProvider));
});

class RefundsRepository {
  RefundsRepository(this._dio);

  final Dio _dio;

  Future<RefundsPageResult> fetchRefunds({
    int page = 1,
    int perPage = 15,
    String? status,
    String? search,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'perPage': perPage,
      if (status != null && status.isNotEmpty && status != 'all') 'status': status,
      if (search != null && search.isNotEmpty) 'search': search,
    };

    final json = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.adminRefundsPaginate,
      queryParameters: params,
    );

    final body = json.data ?? {};
    final items = PaginateResponse.extractItems(body);
    final meta = PaginateResponse.extractMap(body['meta']);

    return RefundsPageResult(
      refunds: items.map(RefundModel.fromJson).toList(),
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

  Future<RefundModel> fetchRefund(int id) async {
    final json = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.adminRefund(id),
    );

    final response = ApiResponse<Map<String, dynamic>>.fromJson(
      json.data ?? {},
      (raw) => raw as Map<String, dynamic>,
    );

    if (!response.status || response.data == null) {
      throw Exception(response.message ?? 'Failed to load refund');
    }

    return RefundModel.fromJson(response.data!);
  }

  Future<void> updateStatus({
    required int id,
    required String status,
    String? answer,
  }) async {
    final params = <String, dynamic>{
      'status': status,
      if (answer != null && answer.isNotEmpty) 'answer': answer,
    };

    final json = await _dio.put<Map<String, dynamic>>(
      ApiEndpoints.adminRefund(id),
      queryParameters: params,
    );

    final response = ApiResponse<dynamic>.fromJson(json.data ?? {}, null);
    if (!response.status) {
      throw Exception(response.message ?? 'Failed to update refund');
    }
  }
}
