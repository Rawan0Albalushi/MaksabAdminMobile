import 'package:dio/dio.dart';
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
      throw Exception('login_failed');
    }

    final token = parsed.data!['access_token']?.toString() ?? '';
    final userJson = parsed.data!['user'] as Map<String, dynamic>;
    final user = AdminUser.fromJson(userJson, token: token);

    if (!user.isAdminPortal) {
      throw Exception('access_denied');
    }

    await _storage.saveToken(token);
    await _storage.saveUser(user.toJson());
    return user;
  }

  Future<AdminUser?> restoreSession() async {
    final token = await _storage.getToken();
    final userJson = _storage.getUser();
    if (token == null || userJson == null) return null;

    final user = AdminUser.fromJson(userJson, token: token);
    if (!user.isAdminPortal) {
      await logout();
      return null;
    }
    return user;
  }

  Future<void> logout() async {
    try {
      await _dio.post(ApiEndpoints.authLogout);
    } catch (_) {}
    await _storage.clearAll();
  }
}

class AuthState {
  const AuthState({this.user, this.loading = false, this.error});

  final AdminUser? user;
  final bool loading;
  final String? error;

  bool get isAuthenticated => user != null;

  AuthState copyWith({AdminUser? user, bool? loading, String? error}) {
    return AuthState(
      user: user ?? this.user,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repo) : super(const AuthState()) {
    _bootstrap();
  }

  final AuthRepository _repo;

  Future<void> _bootstrap() async {
    state = state.copyWith(loading: true);
    try {
      final user = await _repo.restoreSession();
      state = AuthState(user: user, loading: false);
    } catch (_) {
      state = const AuthState(loading: false);
    }
  }

  Future<bool> login(String identifier, String password) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final user = await _repo.login(identifier: identifier, password: password);
      state = AuthState(user: user, loading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState();
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
