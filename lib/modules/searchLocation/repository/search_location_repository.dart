import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../utils/app_urls.dart';
import '../model/search_location_model.dart';
import '../../../../store/user_data_store.dart';

class SearchLocationRepository {
  Future<SearchLocationResponse> searchLocations(String query, String languageCode) async {
    String platform = "web";
    if (Platform.isAndroid) {
      platform = "android";
    } else if (Platform.isIOS) {
      platform = "ios";
    }

    try {
      final response = await http.post(
        Uri.parse(AppUrls.searchLocation),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          "platform": platform,
          "language_code": languageCode,
          "action_when": "search_locations",
          "search_location": query,
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return SearchLocationResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception("Failed to load locations");
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<Map<String, dynamic>> getCustomerLocations(String customerUuid, String languageCode) async {
    String platform = "web";
    if (Platform.isAndroid) {
      platform = "android";
    } else if (Platform.isIOS) {
      platform = "ios";
    }

    try {
      final url = Uri.parse("${AppUrls.getCustomerLocations}?platform=$platform&language_code=$languageCode&action_when=customer_get_location&customer_uuid=$customerUuid");
      
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      if (UserDataStore.accessToken != null && UserDataStore.accessToken!.isNotEmpty) {
        headers['Authorization'] = 'Bearer ${UserDataStore.accessToken}';
      }
      final response = await http.get(
        url,
        headers: headers,
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed to load customer locations");
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<Map<String, dynamic>> saveCustomerLocation({
    required String customerUuid,
    required String geoLocatUuid,
    required String locationType,
    required String languageCode,
  }) async {
    String platform = "web";
    if (Platform.isAndroid) {
      platform = "android";
    } else if (Platform.isIOS) {
      platform = "ios";
    }

    try {
      final url = Uri.parse(AppUrls.saveCustomerLocation);
      
      final headers = {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
      };
      
      if (UserDataStore.accessToken != null && UserDataStore.accessToken!.isNotEmpty) {
        headers['Authorization'] = 'Bearer ${UserDataStore.accessToken}';
      }

      final body = {
        "platform": platform,
        "language_code": languageCode,
        "action_when": "customer_save_location",
        "customer_uuid": customerUuid,
        "geo_locat_uuid": geoLocatUuid,
        "location_type": locationType,
      };

      final response = await http.post(
        url,
        headers: headers,
        body: body,
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed to save location");
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<Map<String, dynamic>> deleteCustomerLocation({
    required String customerUuid,
    required String locationUuid,
    required String languageCode,
  }) async {
    String platform = "web";
    if (Platform.isAndroid) {
      platform = "android";
    } else if (Platform.isIOS) {
      platform = "ios";
    }

    try {
      final url = Uri.parse(AppUrls.deleteCustomerLocation);
      
      final headers = {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
      };
      
      if (UserDataStore.accessToken != null && UserDataStore.accessToken!.isNotEmpty) {
        headers['Authorization'] = 'Bearer ${UserDataStore.accessToken}';
      }

      final body = {
        "platform": platform,
        "language_code": languageCode,
        "action_when": "customer_delete_location",
        "customer_uuid": customerUuid,
        "location_uuid": locationUuid,
      };

      final response = await http.delete(
        url,
        headers: headers,
        body: body,
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed to delete location");
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
