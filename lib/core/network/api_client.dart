import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../constants/api_endpoints.dart';
import '../storage/local_storage.dart';
import 'api_response.dart';

/// Bumped when the API returns 401 so [authProvider] can clear in-memory state.
final sessionExpiredSignalProvider = StateProvider<int>((ref) => 0);

final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(localStorageProvider);
  var handlingUnauthorized = false;

  return ApiClient(
    storage,
    onUnauthorized: () async {
      if (handlingUnauthorized) return;
      handlingUnauthorized = true;
      try {
        await storage.clearAll();
        ref.read(sessionExpiredSignalProvider.notifier).state++;
      } finally {
        handlingUnauthorized = false;
      }
    },
  ).dio;
});

class ApiClient {
  ApiClient(this._storage, {Future<void> Function()? onUnauthorized})
      : _onUnauthorized = onUnauthorized {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'app': AppConfig.apiAppHeader,
        },
      ),
    );

    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
        ),
      );
    }

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
        onError: (error, handler) async {
          final statusCode = error.response?.statusCode;
          if (statusCode == 401 && _shouldForceLogout(error.requestOptions)) {
            await _onUnauthorized?.call();
          }

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
                statusCode: statusCode,
                code: data is Map ? data['statusCode']?.toString() : null,
              ),
            ),
          );
        },
      ),
    );
  }

  final LocalStorage _storage;
  final Future<void> Function()? _onUnauthorized;
  late final Dio _dio;

  Dio get dio => _dio;

  bool _shouldForceLogout(RequestOptions options) {
    final path = options.path;
    return !path.contains(ApiEndpoints.authLogin) &&
        !path.contains(ApiEndpoints.authLogout);
  }

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
