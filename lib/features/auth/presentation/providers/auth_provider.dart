import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/storage/local_storage.dart';
import '../../domain/admin_user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(dioProvider),
    ref.watch(localStorageProvider),
  );
});

class AuthRepository {
  AuthRepository(this._dio, this._storage);

  final Dio _dio;
  final LocalStorage _storage;

  Future<AdminUser> login({
    required String identifier,
    required String password,
  }) async {
    final body = <String, dynamic>{'password': password};
    if (identifier.contains('@')) {
      body['email'] = identifier.trim();
    } else {
      body['phone'] = identifier.replaceAll(RegExp(r'[^0-9+]'), '');
    }

    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.authLogin,
      data: body,
    );
    final json = response.data ?? {};
    final parsed = ApiResponse<Map<String, dynamic>>.fromJson(
      json,
      (raw) => raw as Map<String, dynamic>,
    );

    if (!parsed.status || parsed.data == null) {
      throw Exception(parsed.message ?? 'login_failed');
    }

    final data = parsed.data!;
    final token = AdminUser.accessTokenFromLoginData(data);
    if (token == null || token.isEmpty) {
      throw Exception('login_failed');
    }

    final profile = AdminUser.profileFromLoginData(data);
    var user = AdminUser.fromJson(profile, token: token);

    if (!user.canAccessPortal) {
      if (kDebugMode) {
        debugPrint(
          '[Auth] Portal denied for ${user.email} '
          'roles=${user.roles} zones=${user.zoneIds}',
        );
      }
      throw Exception('access_denied');
    }

    await _storage.saveToken(token);
    user = await enrichZoneAssignments(user);
    await _storage.saveUser(user.toJson());
    return user;
  }

  Future<List<int>> fetchManagedZoneIds(String uuid) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.adminManagerZones(uuid),
    );
    final json = response.data ?? {};
    final parsed = ApiResponse<dynamic>.fromJson(json, null);
    final raw = parsed.data ?? json;

    final ids = <int>{};

    void addId(dynamic value) {
      if (value is int && value > 0) {
        ids.add(value);
      } else if (value is num && value.toInt() > 0) {
        ids.add(value.toInt());
      } else if (value is String) {
        final parsedId = int.tryParse(value.trim());
        if (parsedId != null && parsedId > 0) ids.add(parsedId);
      } else if (value is Map) {
        addId(value['id'] ?? value['zone_id']);
      }
    }

    if (raw is List) {
      for (final item in raw) {
        addId(item);
      }
    } else if (raw is Map) {
      for (final key in ['zones', 'data', 'items', 'managed_zones']) {
        final nested = raw[key];
        if (nested is List) {
          for (final item in nested) {
            addId(item);
          }
        }
      }
      if (ids.isEmpty) addId(raw);
    }

    return ids.toList();
  }

  Future<AdminUser> enrichZoneAssignments(AdminUser user) async {
    if (user.isFullAdmin || !user.isZoneAdmin || user.zoneIds.isNotEmpty) {
      return user;
    }

    final uuid = user.uuid?.trim();
    if (uuid == null || uuid.isEmpty) {
      if (kDebugMode) {
        debugPrint(
          '[Auth] Cannot refresh zone assignments for ${user.email}: missing uuid',
        );
      }
      return user;
    }

    try {
      final zoneIds = await fetchManagedZoneIds(uuid);
      if (zoneIds.isEmpty) {
        if (kDebugMode) {
          debugPrint(
            '[Auth] No zone assignments for ${user.email} '
            'roles=${user.roles}',
          );
        }
        return user;
      }

      final merged = user.copyWith(zoneIds: zoneIds);
      await _storage.saveUser(merged.toJson());
      if (kDebugMode) {
        debugPrint(
          '[Auth] Loaded zone assignments for ${user.email}: ${merged.zoneIds}',
        );
      }
      return merged;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Auth] Failed to refresh zone assignments: $e');
        if (e is DioException) {
          debugPrint('Error: ${parseApiError(e).message}');
        }
      }
      return user;
    }
  }

  Future<AdminUser?> restoreSession() async {
    final token = await _storage.getToken();
    final userJson = _storage.getUser();
    if (token == null || userJson == null) return null;

    var user = AdminUser.fromJson(userJson, token: token);
    if (!user.canAccessPortal) {
      await logout();
      return null;
    }

    return enrichZoneAssignments(user);
  }

  Future<void> logout() async {
    try {
      await _dio.post(ApiEndpoints.authLogout);
    } catch (_) {}
    await _storage.clearAll();
  }
}

class AuthState {
  const AuthState({
    this.user,
    this.initializing = false,
    this.loading = false,
    this.error,
  });

  final AdminUser? user;
  final bool initializing;
  final bool loading;
  final String? error;

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    AdminUser? user,
    bool? initializing,
    bool? loading,
    String? error,
    bool clearUser = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      initializing: initializing ?? this.initializing,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repo) : super(const AuthState(initializing: true)) {
    _bootstrap();
  }

  final AuthRepository _repo;

  Future<void> _bootstrap() async {
    state = state.copyWith(initializing: true);
    try {
      final user = await _repo.restoreSession();
      state = AuthState(user: user, initializing: false);
    } catch (_) {
      state = const AuthState(initializing: false);
    }
  }

  Future<bool> login(String identifier, String password) async {
    state = state.copyWith(loading: true, error: null, clearUser: true);
    try {
      final user = await _repo.login(identifier: identifier, password: password);
      state = AuthState(user: user, loading: false);
      return true;
    } catch (e) {
      state = AuthState(
        loading: false,
        error: _mapLoginError(e),
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState();
  }

  String _mapLoginError(Object error) {
    if (error is DioException) {
      final apiError = parseApiError(error);
      final message = apiError.message.trim();
      if (message.isNotEmpty &&
          message != 'Network error' &&
          message != 'Error') {
        return message;
      }
    }

    final raw = error.toString().replaceAll('Exception: ', '').trim();
    if (raw == 'login_failed' ||
        raw == 'access_denied' ||
        raw.contains('incorrect') ||
        raw.contains('password')) {
      return raw == 'access_denied' ? 'access_denied' : 'login_failed';
    }
    return raw.isEmpty ? 'login_failed' : raw;
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
