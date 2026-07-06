import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../storage/local_storage.dart';
import 'api_response.dart';

final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(localStorageProvider);
  return ApiClient(storage).dio;
});

class ApiClient {
  ApiClient(this._storage) {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          final lang = await _storage.getLanguage();
          options.queryParameters = {'lang': lang, ...options.queryParameters};
          handler.next(options);
        },
        onError: (error, handler) {
          final data = error.response?.data;
          final message = data is Map
              ? data['message']?.toString() ?? error.message
              : error.message ?? 'Network error';
          handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              type: error.type,
              error: ApiException(
                message: message ?? 'Network error',
                statusCode: error.response?.statusCode,
                code: data is Map ? data['statusCode']?.toString() : null,
              ),
            ),
          );
        },
      ),
    );
  }

  final LocalStorage _storage;
  late final Dio _dio;

  Dio get dio => _dio;

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      path,
      queryParameters: queryParameters,
    );
    return response.data ?? {};
  }

  Future<Map<String, dynamic>> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      path,
      data: data,
      queryParameters: queryParameters,
    );
    return response.data ?? {};
  }
}

ApiException parseApiError(Object error) {
  if (error is DioException && error.error is ApiException) {
    return error.error! as ApiException;
  }
  if (error is DioException) {
    final data = error.response?.data;
    return ApiException(
      message: data is Map
          ? data['message']?.toString() ?? error.message ?? 'Error'
          : error.message ?? 'Error',
      statusCode: error.response?.statusCode,
    );
  }
  return ApiException(message: error.toString());
}
