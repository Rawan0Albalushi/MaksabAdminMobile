import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _tokenKey = 'access_token';
const _userKey = 'user_json';
const _langKey = 'app_language';

final localStorageProvider = Provider<LocalStorage>((ref) {
  throw UnimplementedError('LocalStorage must be overridden in main()');
});

class LocalStorage {
  LocalStorage(this._prefs, this._secure);

  final SharedPreferences _prefs;
  final FlutterSecureStorage _secure;

  static Future<LocalStorage> create() async {
    final prefs = await SharedPreferences.getInstance();
    const secure = FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );
    return LocalStorage(prefs, secure);
  }

  Future<void> saveToken(String token) =>
      _secure.write(key: _tokenKey, value: token);

  Future<String?> getToken() => _secure.read(key: _tokenKey);

  Future<void> clearToken() => _secure.delete(key: _tokenKey);

  Future<void> saveUser(Map<String, dynamic> user) =>
      _prefs.setString(_userKey, jsonEncode(user));

  Map<String, dynamic>? getUser() {
    final raw = _prefs.getString(_userKey);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> clearUser() => _prefs.remove(_userKey);

  Future<void> saveLanguage(String code) =>
      _prefs.setString(_langKey, code);

  Future<String> getLanguage() async =>
      _prefs.getString(_langKey) ?? 'en';

  Future<void> clearAll() async {
    await clearToken();
    await clearUser();
  }
}
