import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../utils/app_urls.dart';
import '../../../store/user_data_store.dart';
import 'dart:io';

class ApiKeyService {
  static const MethodChannel _channel = MethodChannel('com.trippy.rider/maps');

  static Future<void> fetchAndSetApiKeys() async {
    try {
      final String? token = UserDataStore.accessToken ?? await UserDataStore.getAccessToken();
      
      String platform = "web";
      if (Platform.isAndroid) {
        platform = "android";
      } else if (Platform.isIOS) {
        platform = "ios";
      }

      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString('active_language_code') ?? 'en';

      final Map<String, String> queryParams = {
        "platform": platform,
        "language_code": languageCode,
        "action_when": "api_key_list",
      };

      final uri = Uri.parse('${AppUrls.baseUrl}/v1/global-api/api-keys').replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(response.body);
        if (body['status'] == true && body['data'] != null) {
          final List<dynamic> data = body['data'];
          
          for (var keyData in data) {
            if (keyData['user_agent'] == 'GOOGLE_MAP_API' && keyData['status'] == 'ACTIVE') {
              final String apiKey = keyData['api_key'];
              
              // 1. Inject Native API Key
              if (Platform.isAndroid || Platform.isIOS) {
                try {
                  await _channel.invokeMethod('setApiKey', {'apiKey': apiKey});
                } catch (e) {
                  // Ignore native errors, will just fail to load map
                }
              }
              
              // Optionally store it in SharedPreferences if you need it for Google Places API later
              await prefs.setString('GOOGLE_MAP_API_KEY', apiKey);
              break;
            }
          }
        }
      }
    } catch (e) {
      // Fail silently
    }
  }
}
