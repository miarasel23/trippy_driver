import 'dart:convert';
import '../../core/network/api_service.dart';
import '../../model/api_key_model.dart';
import '../../utils/app_urls.dart';
import '../../store/app_globals.dart';
import '../../store/user_data_store.dart';

class ApiKeyRepository {
  // In-memory cache: userAgent → ApiKeyModel
  static final Map<String, ApiKeyModel> _cache = {};

  /// Returns all active API keys, keyed by [userAgent].
  /// Uses in-memory cache to avoid repeated network calls.
  static Future<Map<String, ApiKeyModel>> fetchAll({bool forceRefresh = false}) async {
    if (!forceRefresh && _cache.isNotEmpty) return Map.unmodifiable(_cache);

    try {
      final langCode = AppGlobals.countryCode.toLowerCase() == 'bd' ? 'bn' : 'en';
      final uri = Uri.parse(AppUrls.apiKeys).replace(queryParameters: {
        'platform': AppGlobals.platform,
        'language_code': langCode,
        'action_when': 'api_key_list',
      });

      final String? token = UserDataStore.accessToken ?? await UserDataStore.getAccessToken();

      final response = await ApiService().get(
        uri,
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == true && body['data'] is List) {
          _cache.clear();
          for (final item in (body['data'] as List)) {
            final key = ApiKeyModel.fromJson(item as Map<String, dynamic>);
            if (key.isActive) {
              _cache[key.userAgent] = key;
            }
          }
        }
      }
    } catch (_) {
      // Return whatever is in cache (or empty map) on failure
    }

    return Map.unmodifiable(_cache);
  }

  /// Convenience: get a single key value by [userAgent] string, or null.
  static Future<String?> getKeyValue(String userAgent, {bool forceRefresh = false}) async {
    final keys = await fetchAll(forceRefresh: forceRefresh);
    return keys[userAgent]?.apiKey;
  }

  /// Clear the cache (e.g. on logout).
  static void clearCache() => _cache.clear();
}
