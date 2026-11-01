import '../local/cache_helper.dart';

/// Tokens live in the Keychain / Keystore, never in shared preferences.
class TokenStore {
  static const String _access = 'accessToken';
  static const String _refresh = 'refreshToken';

  Future<String?> accessToken() => CacheHelper.safeRead(key: _access);

  Future<String?> refreshToken() => CacheHelper.safeRead(key: _refresh);

  Future<void> save({required String accessToken, required String refreshToken}) async {
    await CacheHelper.assignSecureData(key: _access, value: accessToken);
    await CacheHelper.assignSecureData(key: _refresh, value: refreshToken);
  }

  Future<void> clear() async {
    await CacheHelper.clearCache(key: _access);
    await CacheHelper.clearCache(key: _refresh);
  }
}
